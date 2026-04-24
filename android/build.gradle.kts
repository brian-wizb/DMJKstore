import com.android.build.gradle.LibraryExtension
import org.gradle.api.Project

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.0.2")
        classpath("com.google.gms:google-services:4.4.1") // ✅ Firebase plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        assignNamespaceFromManifestIfMissing()
    }
}

fun Project.assignNamespaceFromManifestIfMissing() {
    val androidExt = extensions.findByName("android") as? LibraryExtension ?: return
    if (!androidExt.namespace.isNullOrBlank()) return

    val manifestFile = file("src/main/AndroidManifest.xml")
    if (!manifestFile.exists()) return

    val pkg = Regex("""package\s*=\s*\"([^\"]+)\"""")
        .find(manifestFile.readText())
        ?.groupValues
        ?.getOrNull(1)
        ?.trim()

    if (!pkg.isNullOrBlank()) {
        androidExt.namespace = pkg
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
