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

import org.gradle.api.tasks.compile.JavaCompile

subprojects {
    afterEvaluate {
        val javaCompileTask = project.tasks.findByName("compileReleaseJavaWithJavac") as? JavaCompile
        val targetCompat = javaCompileTask?.targetCompatibility ?: "11"
        
        val resolvedTarget = when {
            targetCompat.contains("17") -> JvmTarget.JVM_17
            targetCompat.contains("1.8") || targetCompat.contains("8") -> JvmTarget.JVM_1_8
            else -> JvmTarget.JVM_11
        }

        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions.jvmTarget.set(resolvedTarget)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
