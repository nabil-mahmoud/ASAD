# Flutter Proguard Rules for Production Release

# Keep Flutter Engine and framework classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Custom Flutter Activities
-keep class com.asad.offline.attendance.** { *; }

# Mobile Scanner and ML Kit Barcode
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }

# Sqflite SQLite bindings
-keep class com.tekartik.sqflite.** { *; }

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# Share Plus & File Picker
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Ignore warnings for unused/optional dependencies
-dontwarn io.flutter.**
-dontwarn com.google.android.gms.**
