# Add project-specific ProGuard rules here.
# By default, the flags in this file are appended to the R8/ProGuard rules
# set included from the flutter_gradle_plugin.
#
# For more details, see:
#   https://developer.android.com/studio/build/shrink-code

# Respect any class/member explicitly annotated @Keep, wherever a plugin
# uses it instead of shipping its own consumer rule for the same intent.
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep readable stack traces regardless of which crash-reporting vendor
# eventually consumes the mapping file -- deobfuscation needs the original
# source file/line info retained, not just the mapping's class/method names.
-keepattributes SourceFile,LineNumberTable,Exceptions,InnerClasses,EnclosingMethod
-renamesourcefileattribute SourceFile

# Capability bricks (webview, biometric_auth, ...) append their own keep
# rules here at generation time, conditional on being selected. Do not
# remove these markers.
# archipelago:proguard:keep-rules:start
# archipelago:proguard:keep-rules:end
