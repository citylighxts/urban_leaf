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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    // 1. Sinkronisasi target bytecode Kotlin ke JVM 17 untuk semua modul
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }

    // 2. PEMAKSAAN MUTLAK SDK 36: Memaksa aplikasi utama (:app) DAN seluruh library
    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val androidExt = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // INDIKASI SAKTI: Memaksa semuanya kompilasi ke SDK 36 tanpa pengecualian
            androidExt.compileSdkVersion(36)
            
            // Suntikkan namespace otomatis jika identitasnya kosong (aman untuk tflite_v2)
            if (androidExt.namespace == null) {
                androidExt.namespace = "io.flutter.plugins." + project.name.replace(Regex("[^a-zA-Z0-9]"), "")
            }

            // Samakan kepatuhan Java Compiler
            try {
                androidExt.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            } catch (e: Exception) {
                // Lewati jika properti Java sudah terkunci secara internal
            }
        }
    }
}