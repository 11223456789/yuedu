# Flutter 混淆规则
-keep class io.flutter.** { *; }
-keep class com.peiyu.bookhouse.** { *; }

# Drift
-keep class ** extends androidx.room.RoomDatabase { *; }

# just_audio
-keep class com.google.android.exoplayer2.** { *; }

# 保留注解
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
