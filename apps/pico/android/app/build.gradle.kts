import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


// Shared AGP/Kotlin/SDK version source of truth — see
// gradle/libs.versions.toml at the workspace root. Only javaVersion is
// consumed here — compileSdk/minSdk/targetSdk/ndkVersion stay on Flutter's
// own dynamic `flutter.*` resolution (see FlutterExtension) so the app
// tracks whichever Flutter SDK builds it.
fun findVersionCatalog(): File {
    var dir: File? = projectDir
    repeat(8) {
        val candidate = File(dir, "gradle/libs.versions.toml")
        if (candidate.exists()) return candidate
        dir = dir?.parentFile
    }
    throw GradleException("Could not find gradle/libs.versions.toml walking up from $projectDir")
}

fun parseVersionCatalog(file: File): Map<String, String> {
    val versionLine = Regex("""^(\w+)\s*=\s*"([^"]*)"""")
    return file.readLines().mapNotNull { line -> versionLine.find(line.trim())?.groupValues }
        .associate { it[1] to it[2] }
}

fun jvmTargetFor(version: String) = when (version) {
    "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    "21" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
    else -> throw GradleException("Unsupported javaVersion '$version' in gradle/libs.versions.toml")
}

val versionCatalog = parseVersionCatalog(findVersionCatalog())
val androidJavaVersion = JavaVersion.toVersion(versionCatalog.getValue("javaVersion"))

android {

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module",
            )
        }
    }
    namespace = "com.banuacoders.pico.app"
    // Floor of 37: permission_handler_android 14.1 (via app_debugger_network's
    // alice) requires it, and Flutter 3.47 still defaults to 36.
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = androidJavaVersion
        targetCompatibility = androidJavaVersion
        // Required by flutter_local_notifications (java.time APIs on API < 26).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget = jvmTargetFor(versionCatalog.getValue("javaVersion"))
        }
    }

    defaultConfig {
        applicationId = "com.banuacoders.pico.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol native setup (https://patrol.leancode.co): the runner lists and
        // runs the Dart tests; clearPackageData isolates every test.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"

    }


    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }


    signingConfigs {
        // Shared, committed debug keystore (see android/keystore/debug.keystore
        // and .well-known/README.md) — every developer and CI runner signs
        // debug builds with the same certificate instead of AGP's implicit,
        // per-machine ~/.android/debug.keystore. Without this, assetlinks.json
        // and any other certificate-bound feature only ever work on whichever
        // machine happened to publish its fingerprint first (Archipelago-a71b).
        getByName("debug") {
            storeFile = file("../keystore/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    signingConfigs {
        // Only register "release" when a real keystore is configured.
        // create("release") used to run unconditionally, so
        // signingConfigs.findByName("release") below always succeeded
        // (with every field null when key.properties was absent) and the
        // documented `?: signingConfigs.getByName("debug")` fallback could
        // never trigger — AGP's bundle signing step then NPEs deep inside
        // FinalizeBundleTask on a fresh scaffold with no keystore yet.
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
    // ─── Split APKs ──────────────────────────────────────────────────
    // Smaller per-architecture downloads. Universal APK kept as a
    // fallback for sideloads / non-Play-Store distribution.
    //
    // isEnable is gated on the invoked task rather than left unconditionally
    // true: AGP refuses to combine `splits.abi` with a `bundle*` task — both
    // produce one shrunk-resources output per ABI during R8 processing, and
    // bundleRelease's own packaging step errors with "Multiple shrunk-
    // resources files found ... disable building multiple APKs when
    // building an Android app bundle" (see
    // https://issuetracker.google.com/402800800). Play already delivers
    // per-ABI splits from the bundle itself, so raw APK splits only matter
    // on the `flutter build apk` path — disabling them for `bundle*` tasks
    // costs nothing there.
    splits {
        abi {
            isEnable = gradle.startParameter.taskNames.none {
                it.contains("bundle", ignoreCase = true)
            }
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
        }
    }

    // ─── App Bundle splits ───────────────────────────────────────────
    // Mandatory for Play Store AAB delivery — Play strips locales,
    // densities, and ABIs the user's device does not need.
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }

    lint {
        checkReleaseBuilds = true
        abortOnError = false
    }
    applicationVariants.all {
        val variant = this
        val versionStr = variant.versionName ?: "unknown"
        val flavor = variant.flavorName.ifEmpty { "default" }
        val baseName = "Pico-v${versionStr}-${flavor}"
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            // ABI-aware naming: `splits { abi { ... isUniversalApk = true } }`
            // above produces FOUR outputs per variant (3 ABI splits +
            // universal). Naming them all identically makes AGP's parallel
            // packaging runnables race on one path and 3 of 4 fail with
            // "IOException: Failed to create" (Archipelago-ae99).
            val abi = output.filters.find { it.filterType == "ABI" }?.identifier
            output.outputFileName = if (abi != null) "${baseName}-${abi}.apk" else "${baseName}.apk"
        }
        val variantNameCap = variant.name.replaceFirstChar { it.uppercase() }
        tasks.matching { it.name == "bundle${variantNameCap}" }.configureEach {
            doLast {
                val outDir = file("${layout.buildDirectory.get()}/outputs/bundle/${variant.name}")
                val original = outDir.listFiles { f -> f.extension == "aab" }?.firstOrNull()
                if (original != null) {
                    val renamed = File(outDir, "${baseName}.aab")
                    if (original.name != renamed.name) {
                        original.renameTo(renamed)
                    }
                }
            }
        }
    }
}

// ─── Release classpath hygiene ─────────────────────────────────────
configurations.named("releaseImplementation") {
    exclude(group = "androidx.test")
    exclude(group = "junit")
}

// ─── Resolve protobuf-java duplicate-class conflicts ────────────────
// Not the test platform's own `_internal-*` configurations: it needs
// protobuf-java to run connected tests (Patrol).
configurations.matching { !it.name.startsWith("_internal") }.configureEach {
    exclude(group = "com.google.protobuf", module = "protobuf-java")
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    androidTestUtil("androidx.test:orchestrator:1.5.1")

}

// Run after a release build: `./gradlew archiveDebugSymbols -Pvariant=release`.
// Copies that variant's R8 mapping.txt and native-debug-symbols.zip into
// build/outputs/debug-artifacts/<variant>/ -- a stable path CI (or a
// developer) can upload to a crash-reporting vendor's deobfuscation API.
tasks.register("archiveDebugSymbols") {
    doLast {
        val variant = (project.findProperty("variant") as? String) ?: "release"
        val buildDir = layout.buildDirectory.get()
        val mapping = file("$buildDir/outputs/mapping/$variant/mapping.txt")
        val symbols = file("$buildDir/outputs/native-debug-symbols/$variant/native-debug-symbols.zip")
        val destDir = file("$buildDir/outputs/debug-artifacts/$variant")
        destDir.mkdirs()

        var copied = 0
        if (mapping.exists()) {
            mapping.copyTo(File(destDir, "mapping.txt"), overwrite = true)
            copied++
        } else {
            println("No mapping.txt for '$variant' at ${mapping.path} -- run a release build for this variant first.")
        }
        if (symbols.exists()) {
            symbols.copyTo(File(destDir, "native-debug-symbols.zip"), overwrite = true)
            copied++
        } else {
            println("No native-debug-symbols.zip for '$variant' at ${symbols.path}.")
        }
        if (copied > 0) {
            println("Archived $copied debug artifact(s) to ${destDir.path}")
        }
    }
}
// ----- BEGIN flavorDimensions (autogenerated by flutter_flavorizr) -----
apply { from("flavorizr.gradle.kts") }
// ----- END flavorDimensions (autogenerated by flutter_flavorizr) -----