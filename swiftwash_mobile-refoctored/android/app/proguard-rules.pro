-keepclasseswithmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface

-keepattributes *Annotation*

-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }

-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
