# Capture flow (screenshots + demo GIF)

The README media is captured from the real app on an Android emulator, on GitHub Actions.

## Regenerate

```sh
gh workflow run capture.yml -R nhucsau1995/herdline --ref main
gh run list -R nhucsau1995/herdline --workflow capture.yml -L 1
gh run watch <run-id> -R nhucsau1995/herdline --exit-status
gh run download <run-id> -R nhucsau1995/herdline -n capture -D capture-tmp/artifact
rm -rf screenshots && mv capture-tmp/artifact screenshots
```

## How it works

1. `.github/workflows/capture.yml` (manual dispatch) sets up Java 17 and Flutter 3.35.0, then
   builds two debug APKs before the emulator boots:
   - `integration_test/screenshot_test.dart` walks the key screens and calls
     `binding.takeScreenshot('NN-name')`;
   - `integration_test/demo_test.dart` is the paced walkthrough for the GIF and prints
     `POC_DEMO_START` / `POC_DEMO_END`.
2. `reactivecircus/android-emulator-runner` boots an API 34 Pixel 6 emulator (KVM) and runs
   `.github/scripts/capture-emulator.sh flutter` as one command:
   - `flutter drive --driver test_driver/integration_test.dart` with the screenshot APK; the
     driver writes `screenshots/NN-name.png`;
   - `adb shell screenrecord --time-limit 60` records the demo APK run; the GIF is cut to the
     START/END window from logcat times and converted with an ffmpeg palette pass (12 fps,
     300 px wide).
3. The run uploads the `capture` artifact (PNGs + `demo.gif`) and a `capture-debug` artifact
   (logcat, raw mp4). It never commits to the repo.

Both tests wait until the sign-in footer reads "All data stays on this device" (the first launch
writes the sample farm to SQLite) before they start. The tests use fixed-time pumps (not `pumpAndSettle`) because the first launch shows a spinner
while the sample farm is written to SQLite.

## Local emulator

With an Android SDK and a booted emulator (`emulator-5554`):

```sh
flutter pub get
bash .github/scripts/capture-emulator.sh flutter
```
