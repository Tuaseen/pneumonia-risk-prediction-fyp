# Verification record

Date: 2026-09-26.

## Completed

- `flutter analyze --no-pub`: no issues found.
- `flutter test --dart-define=RENDER_REVIEW=true`: 7 tests passed, including 6 data/interaction tests and one optional render-review test.
- `python -m unittest discover -s functions -p "test_*.py" -v`: 3 backend fixture tests passed.
- `flutter build web --no-tree-shake-icons --no-wasm-dry-run`: compiled successfully.
- Locally rendered phone screens reviewed: welcome, overview, readings, device, profile, history and doctor. Renders are produced by the Flutter test engine, not an Android device. Material icons are loaded; the local review uses Windows Segoe UI as a stand-in for Roboto.
- Phone interactions tested at 390×844 and 360×800 logical pixels. Checks include adding a measurement, preserving missing values, simulator capture, creating a symptom check-in, history navigation, profile snapshots, doctor preview and local persistence.
- No training records were imported into the app; seeded data are explicitly fictional.

## Environment blockers

The Android APK build failed before project tasks could run. Gradle's Java NIO selector raised:

```text
java.io.IOException: Unable to establish loopback connection
Caused by: java.net.SocketException: Invalid argument: connect
at sun.nio.ch.UnixDomainSockets.connect0
```

The failure persisted with approved elevated execution, IPv4 preference and `--no-daemon`. The Firestore emulator failed with the same Java NIO error, so the supplied rules tests could not execute. These are unverified tests, not passing tests. No APK is included or claimed to have been built.

Run `tools/build-android.ps1` from a normal PowerShell window to retry the APK build. The script uses the Flutter, JDK and Android SDK already downloaded into the sibling `.tools` folder on this machine. On a different machine, install/configure Flutter and the Android SDK first. More SDK/NDK/Gradle downloads may be required by the first successful build.

This failure resembles the public [Windows Java selector issue](https://github.com/openai/codex/issues/40902), but an outside-terminal build was not performed here to establish the exact cause on this machine.

Opening the local browser preview was rejected by automatic approval review because browser access was denied. No alternate browser access was attempted. Browser interaction remains unverified; the browser compilation and headless Flutter rendering are separate successful checks.

## Not verified or not supplied

- Physical Android installation and runtime behavior of native Firebase plugins.
- A deployed Firebase project, live sign-in/password reset, live Firestore synchronization and callable functions. Firebase client options and a project were not supplied.
- Firestore emulator authorization results (blocked as above).
- Actual XGBoost inference, preprocessing parity, medical performance or physical ESP32 connectivity. These are explicitly labelled placeholders, as requested.
- Push notifications and background hardware collection are not implemented.

The app source and demo workflows are usable; Firebase deployment and native Android verification remain integration steps.
