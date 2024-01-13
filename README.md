<p align="center">
  <img src="https://banuacoders.com/app/pico/logo.png" width="100" height="100" alt="PICO"/>
</p>

<p align="center">
<img src="https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos"/>
<img src="https://img.shields.io/github/stars/ryanaidilp/PICO_SULTENG_FLUTTER?style=plastic&color=yellow"/>
<img src="https://img.shields.io/github/downloads/ryanaidilp/PICO_SULTENG_FLUTTER/total?color=blue&style=plastic"/>
<img src="https://img.shields.io/github/forks/ryanaidilp/PICO_SULTENG_FLUTTER?color=green&style=plastic"/>
<img src="https://img.shields.io/github/v/release/ryanaidilp/PICO_SULTENG_FLUTTER?color=red&style=plastic"/>
</p>

<h1 align="center">PICO SulTeng Flutter</h1>

![PICO](https://banuacoders.com/app/pico/PICO.png)

PICO SulTeng (_Pusat Informasi COVID-19 Sulawesi Tengah_/COVID-19 Information Center of Central Sulawesi) is an application developed to facilitate the people of Central Sulawesi in obtaining current information about COVID-19. The project has been updated to utilize modern development practices for better performance and maintainability.

## General Information

- **Landing page PICO**

  Click the image below to visit the **landing page** of the PICO SulTeng App.

  [![PICO SulTeng](https://i.ibb.co/s6v2Ff9/picoflutter.png)](https://banuacoders.com/app/pico)

- **Updated Technical Stack**

  The app now uses:

  - **BLoC** for state management
  - **Auto Route** for advanced routing
  - **Injectable & Get It** for dependency injection
  - **Slang** for translations and internationalization
  - The project structure follows a monorepo pattern, organized using **Melos**

- **Data Source**

  This application uses data from [**PICO API**](https://banuacoders.com/api/pico). To view the **PICO API** documentation, please click [here](https://github.com/ryanaidilp/PICO_SULTENG_API).

- **Minimum OS version**

  - **Android Lolipop (5.0)**

- **To import into Android Studio :**
  - Use the latest version of Android Studio - Android Studio Arctic Fox | 2020.3.1 Patch 3

## Project Structure

The codebase is structured as follows:

```ascii
root/
├── android
├── core/
│   ├── lib/
│   │   ├── di //dependency injection
│   │   ├── exceptions
│   │   ├── failures
│   │   ├── helpers
│   │   ├── log
│   │   ├── models
│   │   ├── network
│   │   ├── router
│   │   ├── typedef
│   │   ├── usecase
│   │   └── core.dart
│   ├── test
│   └── pubspec.yaml
├── feature/ //micromodule of feature/
│   ├── article
│   ├── home
│   ├── news
│   └── statistic
├── ios
├── launcher //launcher icons related file
├── lib/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── main_dev.dart
│   ├── main_stag.dart
│   └── main.dart
├── packages/
│   └── pico_ui_kit
├── shared/
│   ├── config
│   ├── dependencies
│   └── i10n
├── test
├── melos.yaml
└── pubspec.yaml
```

## Getting Started

> [!IMPORTANT]
> Notes on Environment Configuration:
>
> **BASE_UR**L: By default, this is set to the PICO SulTeng API endpoint. If you wish to use your own API, replace this endpoint and ensure you update the corresponding endpoints in >core/network/api_endpoint.dart to match your API's structure.
>
> **ONESIGNAL_APP_ID**: This ID is necessary for enabling push notifications within the app. Make sure to replace it with your own OneSignal App ID.
>
> **NEWSAPI_API_KEY**: This key is used to fetch articles related to COVID-19 from the News API service. Use your own API key to ensure that the news feature operates without interruption.
>
> After configuring the environment variables as per your requirements, you can proceed with building and running the app.

To set up and run the PICO SulTeng Flutter project, follow these steps:

1. **Clone the Repository**:
   Clone the project to your local machine using the following command:

   ```sh
   git clone https://github.com/ryanaidilp/PICO_SULTENG_FLUTTER.git
   ```

2. **Activate Melos**:
   Install Melos globally on your system with Dart's package manager:

   ```sh
   dart pub global activate melos
   ```

3. **Bootstrap the Project with Melos**:
   Change into the project directory and use Melos to bootstrap and fetch dependencies:

   ```sh
   cd PICO_SULTENG_FLUTTER
   melos bootstrap && melos get
   ```

4. **Environment Configuration**:
   Inside the `shared/config` directory, duplicate the `.env.example` file to create environment-specific configurations:

   - For production, create a `.env` file.
   - For development, create a `.env.dev` file.
   - For staging, create a `.env.stg` file.

   Make sure to configure the necessary variables within these files.

5. **Build the Project**:
   Execute the Melos build command to generate all required files:

   ```sh
   melos build
   ```

6. **Running the App**:
   Now, you should be able to run the app on your device or emulator.

   ```sh
   flutter run
   ```

After these steps, the PICO SulTeng Flutter app should be up and running on your development environment.

## Contact

Created by [@ryanaidilp\_](https://linkedin.com/in/ryanaidilp) - feel free to contact me!

## Activities

![Alt](https://repobeats.axiom.co/api/embed/65970a0cf11692500a081f76b821ffd81dd45c89.svg "Repobeats analytics image")
