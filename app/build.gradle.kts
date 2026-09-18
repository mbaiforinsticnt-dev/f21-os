plugins { id("com.android.application") }

android {
    namespace = "dev.mbaiforinstinct.f21os"
    compileSdk = 35
    defaultConfig {
        applicationId = "dev.mbaiforinstinct.f21os"
        minSdk = 30
        targetSdk = 30
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
}

dependencies {
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test:rules:1.6.1")
}
