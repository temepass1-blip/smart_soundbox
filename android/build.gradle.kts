import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.gradle.api.JavaVersion
import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin" && requested.name.startsWith("kotlin-stdlib")) {
                useVersion("1.9.24")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
        }
        
        project.tasks.withType(JavaCompile::class.java).configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
        
        if (project.hasProperty("android")) {
            try {
                val androidExt = project.extensions.findByName("android")
                if (androidExt != null) {
                    val compileOptionsMethod = androidExt.javaClass.getMethod("getCompileOptions")
                    val compileOptions = compileOptionsMethod.invoke(androidExt)
                    val setSourceCompat = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                    val setTargetCompat = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                    setSourceCompat.invoke(compileOptions, JavaVersion.VERSION_17)
                    setTargetCompat.invoke(compileOptions, JavaVersion.VERSION_17)
                }
            } catch (e: Exception) {}
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
