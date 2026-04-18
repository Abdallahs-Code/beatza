allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix for legacy Flutter plugins that don't specify compileSdk
subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            val androidExt = extensions.findByType<com.android.build.gradle.BaseExtension>()
            if (androidExt != null && androidExt.compileSdkVersion == null) {
                androidExt.compileSdkVersion(35)
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
