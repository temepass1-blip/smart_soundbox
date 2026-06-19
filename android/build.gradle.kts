import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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
    afterEvaluate {
        if (project.hasProperty("android")) {
            try {
                // Use reflection to bypass strict typing and deprecation errors
                val androidExt = project.extensions.findByName("android")
                if (androidExt != null) {
                    val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                    if (getNamespace.invoke(androidExt) == null) {
                        val manifestFile = project.file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            val content = manifestFile.readText()
                            val matcher = java.util.regex.Pattern.compile("package=\"([^\"]+)\"").matcher(content)
                            if (matcher.find()) {
                                val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                                setNamespace.invoke(androidExt, matcher.group(1))
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
    }
    project.tasks.withType(JavaCompile::class.java).configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
