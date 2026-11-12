#!/usr/bin/env bash
# Build the actual arm64 Android translator and launcher; no host x86 fallback.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NDK="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
if [[ -z "$NDK" ]]; then
  SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [[ -n "$SDK" && -d "$SDK/ndk" ]]; then
    while IFS= read -r candidate; do
      if [[ -f "$candidate/build/cmake/android.toolchain.cmake" ]]; then NDK="$candidate"; break; fi
    done < <(find "$SDK/ndk" -mindepth 1 -maxdepth 1 -type d | sort -Vr)
  fi
fi
if [[ -z "$NDK" || ! -f "$NDK/build/cmake/android.toolchain.cmake" ]]; then
  echo 'Android NDK required: set ANDROID_NDK_HOME to an installed NDK directory' >&2; exit 2
fi
if [[ ! -d "$ROOT/third_party/dynarmic/src" ]]; then echo 'Dynarmic sources missing' >&2; exit 2; fi
HOST_TAG="$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
case "$HOST_TAG" in
  linux-x86_64|linux-aarch64|darwin-x86_64|darwin-arm64) ;;
  *) echo "Unsupported NDK host: $HOST_TAG" >&2; exit 2 ;;
esac
if [[ "$HOST_TAG" == linux-aarch64 ]]; then HOST_TAG=linux-arm64; fi
if [[ ! -x "$NDK/toolchains/llvm/prebuilt/$HOST_TAG/bin/armv7a-linux-androideabi21-clang" ]]; then
  echo "NDK arm32 compiler missing for $HOST_TAG" >&2; exit 2
fi
if [[ ! -d "$ROOT/sysroot/system/lib" ]]; then
  echo '32-bit Android guest sysroot missing: populate sysroot/ before building' >&2; exit 2
fi
if [[ ! -x "$ROOT/android/launcher/gradlew" ]]; then echo 'Gradle wrapper missing' >&2; exit 2; fi
export NDK="$NDK" NDK_HOST="$HOST_TAG"
cmake -S "$ROOT" -B "$ROOT/build/android-arm64" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 \
  -DCMAKE_BUILD_TYPE=Release -DZB_BUILD_TESTS=OFF \
  -DBoost_INCLUDE_DIR=/usr/include
cmake --build "$ROOT/build/android-arm64" --target zbridge zbproxy -j "${JOBS:-2}"
"$ROOT/tools/build_guest.sh"
"$ROOT/tools/make_launcher_bundle.sh"
(cd "$ROOT/android/launcher" && ./gradlew assembleDebug)
echo "APK: $ROOT/android/launcher/app/build/outputs/apk/debug/app-debug.apk"
