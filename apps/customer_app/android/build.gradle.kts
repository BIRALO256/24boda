allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force all subprojects (including Flutter plugins) to compile against
// SDK 36. This fixes the geocoding_android compileSdk 33 issue where
// plugin dependencies require compileSdk >= 34.
subprojects {
    afterEvaluate {
        if (hasProperty("android")) {
            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileSdkVersion(36)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
