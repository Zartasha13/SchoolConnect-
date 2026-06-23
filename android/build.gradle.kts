allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    buildscript {
        repositories {
            google()
            mavenCentral()
        }
        val legacyPlugins = setOf(
            "file_picker",
            "cloud_firestore",
            "firebase_auth",
            "firebase_core",
            "firebase_storage",
        )
        val modernPlugins = setOf(
            "flutter_plugin_android_lifecycle",
            "image_picker_android",
        )
        configurations.classpath {
            resolutionStrategy {
                when (project.name) {
                    in legacyPlugins -> {
                        force("com.android.tools.build:gradle:8.3.0")
                        force("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
                        force("org.jetbrains.kotlin:kotlin-stdlib:1.9.20")
                        force("org.jetbrains.kotlin:kotlin-reflect:1.9.20")
                        force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.20")
                        force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.20")
                    }
                    in modernPlugins -> {
                        force("com.android.tools.build:gradle:8.11.1")
                        force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
                        force("org.jetbrains.kotlin:kotlin-stdlib:2.2.20")
                        force("org.jetbrains.kotlin:kotlin-reflect:2.0.21")
                        force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.20")
                        force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.20")
                    }
                }
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
