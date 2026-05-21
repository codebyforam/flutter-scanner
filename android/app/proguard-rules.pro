# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit Rules
-keep class com.google.android.gms.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.libraries.vision.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.libraries.vision.**

# Keep generic types that might be lost during shrinking
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Keep specific ML Kit components
-keep class com.google.android.gms.internal.** { *; }
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.mlkit.vision.** { *; }
