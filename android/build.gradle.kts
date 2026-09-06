import org.gradle.api.Project

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

// Forzar compileSdk del plugin isar_community_flutter_libs (compileSdkVersion antiguo)
gradle.beforeProject(
    org.gradle.api.Action<Project> {
        if (name != "isar_community_flutter_libs") return@Action

        afterEvaluate {
            val androidExt = extensions.findByName("android") ?: return@afterEvaluate

            fun tryInvokeIntMethod(methodName: String, value: Int): Boolean {
                val m =
                    androidExt.javaClass.methods.firstOrNull { method ->
                        method.name == methodName &&
                            method.parameterTypes.size == 1 &&
                            method.parameterTypes[0] == Int::class.javaPrimitiveType
                    } ?: return false
                m.invoke(androidExt, value)
                return true
            }

            val ok =
                tryInvokeIntMethod("compileSdkVersion", 34) ||
                    tryInvokeIntMethod("setCompileSdkVersion", 34) ||
                    tryInvokeIntMethod("setCompileSdk", 34)

            if (!ok) {
                throw GradleException(
                    "No se pudo forzar compileSdk en ${project.path} (isar_community_flutter_libs). " +
                        "Clase androidExt: ${androidExt.javaClass.name}",
                )
            }
        }
    },
)

// Workaround Isar 3.x "Namespace not specified" (script Groovy para compatibilidad)
apply(from = "isar_namespace_fix.gradle")

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
