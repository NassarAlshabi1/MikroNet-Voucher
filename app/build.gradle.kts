import java.util.Base64

plugins {
    alias(libs.plugins.android.application)
}


android {
    namespace = "com.mikronet.voucher"
    compileSdk {
        version = release(36) {
            minorApiLevel = 1
        }
    }

    defaultConfig {
        applicationId = "com.mikronet.voucher"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            // التوقيع من متغيرات البيئة (GitHub Secrets):
            // KEYSTORE_BASE64 (ملف .jks مُرمّز Base64) أو KEYSTORE_FILE (مسار)
            // + KEYSTORE_PASSWORD و KEY_ALIAS و KEY_PASSWORD
            val b64 = System.getenv("KEYSTORE_BASE64")
            val ksPath = System.getenv("KEYSTORE_FILE")
            val storePass = System.getenv("KEYSTORE_PASSWORD")
            val alias = System.getenv("KEY_ALIAS")
            val keyPass = System.getenv("KEY_PASSWORD")
            when {
                b64 != null && storePass != null && alias != null && keyPass != null -> {
                    val tmp = File.createTempFile("release-keystore", ".jks")
                    tmp.writeBytes(Base64.getDecoder().decode(b64))
                    tmp.deleteOnExit()
                    storeFile = tmp
                    storePassword = storePass
                    keyAlias = alias
                    keyPassword = keyPass
                }
                ksPath != null && storePass != null && alias != null && keyPass != null -> {
                    storeFile = file(ksPath)
                    storePassword = storePass
                    keyAlias = alias
                    keyPassword = keyPass
                }
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // يُوقّع بمفتاح الإصدار إذا توفّر، وإلا بمفتاح debug
            // حتى يخرج الـ APK قابلًا للتثبيت من CI بدون إعداد إضافي
            signingConfig = if (signingConfigs.getByName("release").storeFile != null)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // AndroidX & Material (الأساسيات)
    implementation(libs.androidx.activity.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.androidx.recyclerview)
    implementation(libs.androidx.core.ktx)
    implementation(libs.material)

    // Coroutines (للعمليات غير المتزامنة)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // Lifecycle (ViewModel + LiveData)
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")

    // iText (توليد ملفات PDF للكروت)
    implementation("com.itextpdf:itextg:5.5.10")

    // ZXing (توليد رموز QR)
    implementation("com.google.zxing:core:3.5.3")

    // Testing
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(libs.androidx.junit)
}
