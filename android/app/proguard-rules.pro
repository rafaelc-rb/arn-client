# O motor do Flutter e os plugins (io.flutter.**) já embarcam suas próprias
# regras de consumidor do ProGuard/R8 dentro do .aar — não é necessário (nem
# recomendado) repetir um "-keep" amplo para esses pacotes aqui. Um "-keep"
# genérico como esse mantinha uma fatia enorme do app sem shrink/ofuscação/
# otimização, sem necessidade real, prejudicando as métricas de qualidade
# técnica do R8 no Play Console.

# WebView: preserva a assinatura dos callbacks de WebViewClient, usados por
# algumas implementações via reflexão.
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public void *(android.webkit.WebView, java.lang.String);
    public boolean *(android.webkit.WebView, java.lang.String);
}

# Suprime avisos de providers de TLS opcionais que aparecem como dependência
# transitiva, mas não são usados em tempo de execução por este app.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Preserva metadados úteis para stack traces legíveis em relatórios de erro.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
