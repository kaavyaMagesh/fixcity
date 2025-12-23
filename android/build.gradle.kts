// 👇 1. THIS BLOCK MUST BE FIRST (For plugins)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        
        // Google Services (Firebase)
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// 👇 2. THIS BLOCK IS FOR YOUR PROJECT CODE
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 👇 3. FLUTTER BUILD CONFIG
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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