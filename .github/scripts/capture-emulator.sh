#!/usr/bin/env bash
# Shared capture script for make-poc-pod. Copied into the POC repo as
# .github/scripts/capture-emulator.sh and run as ONE command by capture.yml
# (reactivecircus/android-emulator-runner runs every line of `script:` in its own shell, so
# background jobs, `wait` and `\` continuations break there) and by scripts/capture-local.sh.
# The repo copy may be patched for one POC; fixes that would help every POC go back here.
#
# Usage: capture-emulator.sh <flutter|expo>
# Expects a booted emulator on emulator-5554 and the app already built:
#   Expo:    android/app/build/outputs/apk/release/app-release.apk (built by capture.yml)
#   Flutter: capture-apks/shots.apk + capture-apks/demo.apk (built by capture.yml before the
#            emulator boots; built here if missing, e.g. by capture-local.sh)
# Output: screenshots/NN-*.png (3+) and screenshots/demo.gif. Exits non-zero if either is
# missing, so a run can never come back green without usable media.
#
# Demo recording:
#   Expo:    .maestro/demo.yaml calls startRecording/stopRecording itself, after the first
#            screen is up. A screenrecord started out here would end during Maestro's ~20 s
#            start-up and the dialog guard (T-7 retest).
#   Flutter: the APK is prebuilt, so only launch + walkthrough are recorded. demo_test.dart
#            prints POC_DEMO_START / POC_DEMO_END with debugPrint; the GIF is cut to that window
#            (from 0.3 s before START to 0.3 s after END) using logcat epoch times.
set -euxo pipefail
STACK=${1:?flutter|expo}
DEVICE=emulator-5554
REC_LIMIT=60          # seconds; screenrecord stops itself and finalizes the mp4 (never kill it)
GIF_MAX=35            # seconds kept in the GIF at most

# Start clean: never ship a PNG/GIF left over from the checkout or an earlier attempt, so the
# ">= 3 PNGs" check cannot pass on old files.
rm -rf maestro-out capture-tmp
mkdir -p screenshots maestro-out capture-tmp
find screenshots -maxdepth 1 -type f \( -name '*.png' -o -name '*.gif' \) -delete

# Emulator system dialogs ("Pixel Launcher isn't responding") can cover the app.
adb shell settings put global hide_error_dialogs 1 || true
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS || true

# Files named like $1 from ONLY the places the capture tools write to: Maestro's
# --test-output-dir, its default ~/.maestro/tests, and the top level of the repo (older Maestro
# writes takeScreenshot/startRecording relative to the cwd). Never a recursive search of the
# checkout, which would pick up design images named 01-*.png.
collect() {
  local pattern=$1 dirs=(maestro-out)
  [ -d "$HOME/.maestro/tests" ] && dirs+=("$HOME/.maestro/tests")
  { find "${dirs[@]}" -type f -name "$pattern" 2>/dev/null || true
    find . -maxdepth 1 -type f -name "$pattern" 2>/dev/null || true; } | sort -u
}

if [ "$STACK" = flutter ]; then
  mkdir -p capture-apks
  build_apk() { # <target> <out>; no-op when capture.yml already built it
    [ -s "$2" ] && return 0
    flutter build apk --debug --target "$1"
    cp build/app/outputs/flutter-apk/app-debug.apk "$2"
  }
  build_apk integration_test/screenshot_test.dart capture-apks/shots.apk
  build_apk integration_test/demo_test.dart capture-apks/demo.apk
fi

# ---------------------------------------------------------------------------
# 1) stills
if [ "$STACK" = expo ]; then
  APP_ID=${APP_ID:-$(node -p "require('./app.json').expo.android.package")}
  adb install -r android/app/build/outputs/apk/release/app-release.apk
  # Warm-up launch so neither flow (nor the recording) starts on a cold JS load.
  adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1
  sleep 15
  adb shell am force-stop "$APP_ID"
  maestro test --test-output-dir maestro-out .maestro/screenshots.yaml
  while IFS= read -r f; do cp -n "$f" screenshots/; done < <(collect '[0-9][0-9]-*.png')
else
  # test_driver/integration_test.dart writes screenshots/NN-name.png
  flutter drive --driver test_driver/integration_test.dart --target integration_test/screenshot_test.dart \
    --use-application-binary capture-apks/shots.apk -d "$DEVICE"
fi

N=$( (find screenshots -maxdepth 1 -type f -name '[0-9][0-9]-*.png' || true) | wc -l)
[ "$N" -ge 3 ] || { echo "capture: only $N PNGs in screenshots/"; exit 1; }

# ---------------------------------------------------------------------------
# 2) demo walkthrough -> capture-tmp/ademo.mp4, plus a trim window
TRIM=(-t "$GIF_MAX")
if [ "$STACK" = expo ]; then
  maestro test --test-output-dir maestro-out .maestro/demo.yaml || true
  MP4=$(collect 'demo.mp4' | head -n 1 || true)
  [ -n "$MP4" ] || { echo "capture: Maestro wrote no demo.mp4 (demo.yaml needs startRecording: demo)"; exit 1; }
  cp "$MP4" capture-tmp/ademo.mp4
else
  # Install first so the recording window holds only launch + walkthrough.
  adb install -r -t capture-apks/demo.apk
  adb logcat -c || true
  REC_T0=$(adb shell date +%s | tr -d '\r')
  adb shell screenrecord --time-limit "$REC_LIMIT" --size 540x1200 /sdcard/ademo.mp4 &
  REC=$!
  sleep 1
  flutter drive --driver test_driver/integration_test.dart --target integration_test/demo_test.dart \
    --use-application-binary capture-apks/demo.apk -d "$DEVICE" || true
  # screenrecord ends on its own at REC_LIMIT; never kill it (a killed mp4 has no moov atom).
  wait "$REC" || true
  adb pull /sdcard/ademo.mp4 capture-tmp/ademo.mp4
  adb logcat -d -v epoch > capture-tmp/logcat.txt || true
  mark() { (grep -m1 "$1" capture-tmp/logcat.txt || true) | awk '{print $1}'; }
  START=$(mark POC_DEMO_START); END=$(mark POC_DEMO_END)
  if [ -n "$START" ] && [ -n "$END" ]; then
    SS=$(awk -v s="$START" -v t="$REC_T0" 'BEGIN{d=s-t-0.3; if(d<0)d=0; printf "%.2f", d}')
    DUR=$(awk -v s="$START" -v e="$END" -v m="$GIF_MAX" 'BEGIN{d=e-s+0.6; if(d>m)d=m; printf "%.2f", d}')
    TRIM=(-ss "$SS" -t "$DUR")
    echo "capture: walkthrough at +${SS}s for ${DUR}s"
  else
    echo "capture: no POC_DEMO markers in logcat, using the first ${GIF_MAX}s"
  fi
fi

ffmpeg -y "${TRIM[@]}" -i capture-tmp/ademo.mp4 -vf "fps=12,scale=300:-1:flags=lanczos,palettegen=stats_mode=diff" capture-tmp/pal.png
ffmpeg -y "${TRIM[@]}" -i capture-tmp/ademo.mp4 -i capture-tmp/pal.png \
  -lavfi "fps=12,scale=300:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" screenshots/demo.gif
[ -s screenshots/demo.gif ] || { echo "capture: no demo.gif"; exit 1; }
SIZE=$(stat -c %s screenshots/demo.gif)
[ "$SIZE" -lt 3145728 ] || echo "capture: warning, demo.gif is $SIZE bytes (> 3 MB)"
ls -la screenshots
