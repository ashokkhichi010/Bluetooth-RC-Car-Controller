allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android") ?: return@withId
        val namespaceGetter = androidExtension.javaClass.methods.firstOrNull {
            it.name == "getNamespace"
        } ?: return@withId
        val currentNamespace = namespaceGetter.invoke(androidExtension) as? String
        if (!currentNamespace.isNullOrBlank()) {
            return@withId
        }

        val manifestFile = project.file("src/main/AndroidManifest.xml")
        val manifestNamespace = if (manifestFile.exists()) {
            Regex("""package="([^"]+)"""")
                .find(manifestFile.readText())
                ?.groupValues
                ?.getOrNull(1)
        } else {
            null
        }

        val fallbackNamespace =
            manifestNamespace ?: "com.generated.${project.name.replace('-', '_')}"

        androidExtension.javaClass.methods
            .firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }
            ?.invoke(androidExtension, fallbackNamespace)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
