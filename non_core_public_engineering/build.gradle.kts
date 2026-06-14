// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    id("com.diffplug.spotless") version "6.25.0" apply false
}
val defaultTargetSdkVersion by extra(30)


//subprojects {
//    // 每个子模块的 build 目录：D:/androidStudioBuild/工程名/模块名/build
//    layout.buildDirectory.set(
//        file("D:/androidStudioBuild/${rootProject.name}/${project.name}/build")
//    )
//}
