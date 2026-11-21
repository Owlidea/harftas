import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../config/app_info.dart';
import 'crash_reporter.dart';

class StoreProduct {
  const StoreProduct(this.id, this.price);
  final String id;

  /// Localised price string from the store, e.g. "₺49,99".
  final String price;
}

/// Delivered purchase (new or restored). The app grants the content.
class PurchaseGrant {
  const PurchaseGrant(this.productId, {required this.restored});
  final String productId;
  final bool restored;
}

/// In-app purchases behind an interface (spec 12). Restore is mandatory.
abstract interface class PurchaseService {
  Future<void> init();
  Stream<PurchaseGrant> get grants;
  Future<List<StoreProduct>> products();
  Future<bool> buy(String productId);
  Future<void> restore();

  /// False where no store exists (web release): purchase UI is replaced by a
  /// "available in the mobile app" note.
  bool get supported;
}

/// Web / desktop release: nothing can be bought.
class NoPurchaseService implements PurchaseService {
  @override
  Future<void> init() async {}
  @override
  Stream<PurchaseGrant> get grants => const Stream.empty();
  @override
  Future<List<StoreProduct>> products() async => const [];
  @override
  Future<bool> buy(String productId) async => false;
  @override
  Future<void> restore() async {}
  @override
  bool get supported => false;
}

class FakePurchaseService implements PurchaseService {
  final _grants = StreamController<PurchaseGrant>.broadcast();
  final Set<String> _owned = {};

  @override
  Future<void> init() async {}
  @override
  bool get supported => true;
  @override
  Stream<PurchaseGrant> get grants => _grants.stream;

  @override
  Future<List<StoreProduct>> products() async => const [
    StoreProduct(AppInfo.productRemoveAds, '₺49,99'),
    StoreProduct(AppInfo.productPowerupsSmall, '₺19,99'),
    StoreProduct(AppInfo.productPowerupsLarge, '₺49,99'),
  ];

  @override
  Future<bool> buy(String productId) async {
    if (productId == AppInfo.productRemoveAds) _owned.add(productId);
    _grants.add(PurchaseGrant(productId, restored: false));
    return true;
  }

  @override
  Future<void> restore() async {
    for (final id in _owned) {
      _grants.add(PurchaseGrant(id, restored: true));
    }
  }
}

/// RevenueCat (App Store + Google Play). RevenueCat validates receipts on
/// its servers and keeps the "premium" entitlement in sync across devices
/// and reinstalls.
///
/// Dashboard setup (docs/revenuecat.md): one offering marked "current" whose
/// custom packages are named after our product ids (`remove_ads`,
/// `powerups_small`, `powerups_large`), and an entitlement
/// [RevenueCatConfig.premiumEntitlement] attached to the remove-ads product.
/// Store product ids may differ per store: Play uses the bare ids, the App
/// Store uses `harftas.`-prefixed ones (Apple ids are unique per account).
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService({required this.apiKey, required this.crash});
  final String apiKey;
  final CrashReporter crash;
  final _grants = StreamController<PurchaseGrant>.broadcast();
  final Map<String, rc.Package> _packages = {};
  bool _ready = false;

  @override
  bool get supported => true;
  @override
  Stream<PurchaseGrant> get grants => _grants.stream;

  @override
  Future<void> init() async {
    try {
      if (kDebugMode) await rc.Purchases.setLogLevel(rc.LogLevel.debug);
      await rc.Purchases.configure(rc.PurchasesConfiguration(apiKey));
      _ready = true;
      // Premium bought on another device / before a reinstall shows up here.
      rc.Purchases.addCustomerInfoUpdateListener(_syncPremium);
      _syncPremium(await rc.Purchases.getCustomerInfo());
    } on Object catch (e, st) {
      crash.record(e, st, reason: 'revenuecat init');
    }
  }

  void _syncPremium(rc.CustomerInfo info, {bool restored = true}) {
    if (info.entitlements.active.containsKey(RevenueCatConfig.premiumEntitlement)) {
      _grants.add(PurchaseGrant(AppInfo.productRemoveAds, restored: restored));
    }
  }

  /// Our product id for a package: the package identifier if it matches one
  /// (custom packages), otherwise the store product id without the App Store
  /// `harftas.` prefix.
  static String? _ourId(rc.Package p) {
    const ids = {AppInfo.productRemoveAds, AppInfo.productPowerupsSmall, AppInfo.productPowerupsLarge};
    if (ids.contains(p.identifier)) return p.identifier;
    final storeId = p.storeProduct.identifier.split(':').first.replaceFirst('harftas.', '');
    return ids.contains(storeId) ? storeId : null;
  }

  @override
  Future<List<StoreProduct>> products() async {
    if (!_ready) return const [];
    try {
      final offerings = await rc.Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        crash.log('revenuecat: no current offering');
        return const [];
      }
      _packages.clear();
      for (final p in current.availablePackages) {
        final id = _ourId(p);
        if (id != null) _packages[id] = p;
      }
      return [for (final e in _packages.entries) StoreProduct(e.key, e.value.storeProduct.priceString)];
    } on Object catch (e, st) {
      crash.record(e, st, reason: 'revenuecat offerings');
      return const [];
    }
  }

  @override
  Future<bool> buy(String productId) async {
    if (!_ready) return false;
    if (!_packages.containsKey(productId)) await products();
    final pkg = _packages[productId];
    if (pkg == null) return false;
    try {
      final result = await rc.Purchases.purchase(rc.PurchaseParams.package(pkg));
      if (productId == AppInfo.productRemoveAds) {
        // Grant only when the entitlement is really active.
        final active = result.customerInfo.entitlements.active.containsKey(RevenueCatConfig.premiumEntitlement);
        if (!active) return false;
      }
      _grants.add(PurchaseGrant(productId, restored: false));
      return true;
    } on PlatformException catch (e) {
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      if (code != rc.PurchasesErrorCode.purchaseCancelledError) {
        crash.log('revenuecat purchase $productId failed: $code ${e.message}');
      }
      return false;
    }
  }

  @override
  Future<void> restore() async {
    if (!_ready) return;
    try {
      _syncPremium(await rc.Purchases.restorePurchases());
    } on PlatformException catch (e) {
      crash.log('revenuecat restore failed: ${rc.PurchasesErrorHelper.getErrorCode(e)} ${e.message}');
    }
  }
}
