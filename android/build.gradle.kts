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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            // Mengambil versi Java target dari task JavaCompile pada masing-masing sub-proyek secara dinamis
            val javaCompileTask = project.tasks.withType<JavaCompile>().firstOrNull()
            if (javaCompileTask != null) {
                val targetVersion = javaCompileTask.targetCompatibility
                if (targetVersion == "11" || targetVersion == "1.11") {
                    jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                } else if (targetVersion == "17" || targetVersion == "1.17") {
                    jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                }
            } else {
                // Fallback default jika tidak terdeteksi
                jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
        }
    }
}
