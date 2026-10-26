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
    if (project.name != "app") {
        afterEvaluate {
            val android = project.extensions.findByName("android")
            if (android != null) {
                val getCompileSdkVersion = android.javaClass.methods.firstOrNull { it.name == "getCompileSdkVersion" }
                val currentSdkStr = getCompileSdkVersion?.invoke(android)?.toString() ?: ""
                val currentSdk = currentSdkStr.filter { it.isDigit() }.toIntOrNull() ?: 0
                if (currentSdk in 1..33) {
                    val setMethod = android.javaClass.methods.firstOrNull {
                        (it.name == "compileSdkVersion" || it.name == "setCompileSdkVersion") &&
                        it.parameterTypes.size == 1 &&
                        (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == java.lang.Integer::class.java)
                    }
                    setMethod?.invoke(android, 35)
                    println("Updated ${project.name} compileSdkVersion from $currentSdk to 35")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
