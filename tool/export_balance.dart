import 'dart:convert';
import 'dart:io';

import 'package:harfblok/core/config/balance_config.dart';

void main() {
  File('assets/config/balance.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(BalanceConfig.defaults.toJson()));
}
