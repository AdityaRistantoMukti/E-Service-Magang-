# TODO: Fix Flutter Build Warnings by Updating Java Version

- [x] Update `android/app/build.gradle.kts` to set Java version to 17:
  - Change `sourceCompatibility` from `JavaVersion.VERSION_11` to `JavaVersion.VERSION_17`
  - Change `targetCompatibility` from `JavaVersion.VERSION_11` to `JavaVersion.VERSION_17`
  - Change `jvmTarget` from `JavaVersion.VERSION_11.toString()` to `"17"`
- [x] Advise user to enable Developer Mode in Windows settings for symlink support (run `start ms-settings:developers`)
- [x] Test the build by running `flutter run` to verify warnings are resolved
