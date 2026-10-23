import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("development") {
            dimension = "flavor-type"
            applicationId = "com.banuacoders.pico.app.dev"
            resValue(type = "string", name = "app_name", value = "Pico [Dev]")
        }
        create("staging") {
            dimension = "flavor-type"
            applicationId = "com.banuacoders.pico.app.stg"
            resValue(type = "string", name = "app_name", value = "Pico [STG]")
        }
        create("production") {
            dimension = "flavor-type"
            applicationId = "com.banuacoders.pico.app"
            resValue(type = "string", name = "app_name", value = "Pico")
        }
    }

    buildFeatures.resValues = true
}