# flutter_local_notifications: scheduled notifications are stored with Gson.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Play Core (deferred components) is referenced by the Flutter engine but not used.
-dontwarn com.google.android.play.core.**
