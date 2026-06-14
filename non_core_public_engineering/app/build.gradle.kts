plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    id("com.diffplug.spotless")
}

android {
    namespace = "com.example.liquid_detect"
    compileSdk = 35

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
        }
    }

    defaultConfig {
        applicationId = "com.example.liquid_detect"
        minSdk = 27
        targetSdk = rootProject.extra["defaultTargetSdkVersion"] as Int
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        externalNativeBuild {
            cmake {
                arguments("-DCMAKE_BUILD_TYPE=Debug")
            }
        }
    }

    ndkVersion = "29.0.14206865"

    buildTypes {
        debug {
            externalNativeBuild {
                cmake {
                    arguments("-DCMAKE_BUILD_TYPE=Debug")
                }
            }
            ndk {
                debugSymbolLevel = "FULL"
            }
        }

        release {
            externalNativeBuild {
                cmake {
                    arguments("-DCMAKE_BUILD_TYPE=Release")
                }
            }
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        viewBinding = true
    }
    packaging {
        jniLibs {
            // 告诉 AGP：别剥离这些 so 的调试符号
            keepDebugSymbols.add("**/*.so")
            // 或者
            // keepDebugSymbols += "**/*.so"
        }
    }
    lint {
        abortOnError = true
        warningsAsErrors = true
        checkReleaseBuilds = true
    }
    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }
}

dependencies {

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.androidx.lifecycle.livedata.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.ktx)
    implementation(libs.androidx.navigation.fragment.ktx)
    implementation(libs.androidx.navigation.ui.ktx)
    implementation(libs.androidx.activity)
    implementation(libs.okhttp)
    implementation(libs.mpandroidchart)
    implementation(libs.androidx.media3.exoplayer)
    implementation(libs.androidx.media3.ui)
    implementation("com.google.code.gson:gson:2.11.0")
    testImplementation(libs.junit)
    testImplementation(libs.androidx.test.core)
    testImplementation("org.mockito:mockito-core:5.14.2")
    testImplementation(libs.robolectric)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(libs.androidx.runner)
    androidTestImplementation(libs.androidx.rules)
}

spotless {
    kotlin {
        target("src/**/*.kt")
        targetExclude("**/build/**/*.kt")
        ktlint("1.3.1").editorConfigOverride(
            mapOf(
                "indent_size" to "4",
                "max_line_length" to "140",
                "insert_final_newline" to "true",
                "disabled_rules" to "no-wildcard-imports"
            )
        )
        trimTrailingWhitespace()
        endWithNewline()
    }
    kotlinGradle {
        target("*.gradle.kts")
        ktlint("1.3.1")
    }
}
