# Suppress Play Core warnings for Flutter deferred components
-dontwarn com.google.android.play.core.**

# Disable aggressive bytecode optimization which causes NoSuchMethodError / ClassNotFoundException in Flutter plugins
-dontoptimize

# Flutter Embedding and Core
-keep class io.flutter.** { *; }
-keep interface io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads SDK (AdMob)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-keep interface com.google.ads.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep interface io.flutter.plugins.googlemobileads.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.ads.**
-dontwarn io.flutter.plugins.googlemobileads.**

# Shared Preferences & Kotlin Coroutines
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }

# Audio Service and Just Audio
-keep class com.ryanheise.** { *; }
-keep interface com.ryanheise.** { *; }
