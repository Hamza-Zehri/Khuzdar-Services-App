# Application Specific
-keep class com.khuzdar.marketplace.** { *; }

# Firebase & Google Play Services Aggressive Rules
-keep class com.google.firebase.** { *; }
-keep enum com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

-keep class com.google.android.play.tasks.** { *; }
-dontwarn com.google.android.play.tasks.**

# Firestore specific
-keep class com.google.firebase.firestore.** { *; }
-keep enum com.google.firebase.firestore.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Guava (often used by Firebase)
-dontwarn com.google.common.**
-keep class com.google.common.** { *; }

# Protobuf (used by Firestore)
-dontwarn com.google.protobuf.**
-keep class com.google.protobuf.** { *; }

# OkHttp/Okio (used by FCM/Firestore)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Flutter Native
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
