allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force all subprojects to use SDK 36 and JVM 17 via toolchain.
// The JVM Toolchain approach is the recommended fix for
// "Inconsistent JVM-target compatibility" errors — it sets both
// Java and Kotlin to the same JVM at the toolchain level so they
// can never diverge regardless of plugin or AGP version.
subprojects {
    // Apply toolchain to Kotlin tasks
    plugins.withType<org.jetbrains.kotlin.gradle.plugin.KotlinBasePlugin> {
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinProjectExtension> {
            jvmToolchain(17)
        }
    }

    afterEvaluate {
        // Fix compileSdk for all Android library plugins
        extensions.findByType<com.android.build.api.dsl.LibraryExtension>()?.apply {
            compileSdk = 36
        }
        extensions.findByType<com.android.build.api.dsl.ApplicationExtension>()?.apply {
            compileSdk = 36
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
