# Flutter 和插件的 ProGuard 規則

# 保留 Flutter 引擎
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保留 SharedPreferences
-keep class androidx.datastore.** { *; }
-keepclassmembers class * implements android.content.SharedPreferences { *; }

# 保留 just_audio 插件
-keep class com.ryanheise.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# 保留 NFC Manager
-keep class io.flutter.plugins.nfc_manager.** { *; }

# 保留 Vibration 插件
-keep class com.benjaminabel.vibration.** { *; }

# 保留 device_info_plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# 保留 Kotlin 相關
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# 保留 AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# 禁止優化和混淆會導致問題的類
-dontoptimize
-dontobfuscate

# 保留原生方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留 Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# 保留 Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
