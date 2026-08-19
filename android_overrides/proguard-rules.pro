# Flutter's own defaults already keep the engine — this adds what
# flutter_v2ray and JSON reflection typically need. If release build
# crashes only in release (not debug), it's almost always a missing
# keep rule here — check `adb logcat` for the stripped class name.

-keep class com.v2ray.ang.** { *; }
-keep class go.** { *; }
-keep class libv2ray.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Gson/JSON model classes (if the plugin uses reflection-based parsing)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Don't warn about missing optional classes referenced by dependencies
-dontwarn okhttp3.**
-dontwarn okio.**
