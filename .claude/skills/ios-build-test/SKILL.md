---
name: ios-build-test
description: BusNow の iOS アプリをビルドし、シミュレータで単体テスト・UI テストを実行する(テスト後に xcodebuild が終了しない問題に対処済み)。「iOSのテスト」「ビルドして」「テスト実行」と言われたときに使う。
---

# iOS Build and Test (BusNow)

Run inside `20_Source/BusNow/`. Minimum iOS is 18.6, but this Mac only has iOS 18.2/18.5 and 26.x/27.0 simulator runtimes, so use an iOS 26+ simulator (`iPhone 17`). The `iPhone 16` simulators are iOS 18.x and fail.

## Build

```bash
xcodebuild -scheme BusNow -destination 'generic/platform=iOS Simulator' build -quiet
```

The Stop hook `.claude/hooks/build-on-stop.sh` already builds automatically at the end of a turn when Swift files changed. Build manually only when you need the result mid-turn.

## Unit tests: one class first

Run the class related to the change, not the full suite. `xcodebuild test` can keep running 10+ minutes after the tests finish, so run it in the background, write to a log, and stop as soon as the result line appears:

```bash
L=<scratchpad>/test.log; : > "$L"
xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO -only-testing:BusNowTests/<TestClass> > "$L" 2>&1 &
P=$!; n=0
until grep -qE "Test Suite 'Selected tests' (passed|failed)|BUILD FAILED|Testing cancelled" "$L" || ! kill -0 $P 2>/dev/null || [ $n -ge 900 ]; do sleep 1; n=$((n+1)); done
sleep 2; kill $P 2>/dev/null
grep -E "error:|' failed|Executed [0-9]+ tests" "$L" | sort -u
```

Use Bash `run_in_background: true` for this and wait for the completion notification. Test classes: `BusNowTests`, `StringNormalizationTests`, `StopNameRepositoryTests` (all under `BusNowTests/`).

## Full suite and UI tests: hand to the developer

Per the global rule, long runs are given to the developer as a copy-paste command instead of being run here:

```bash
cd 20_Source/BusNow && xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 17'
```

UI tests (`BusNowUITests`) launch the app and need the local Supabase running (Debug builds connect to it).

## When tests fail

- Compile errors in tests: fix the test code to match the current app API; read the app code first.
- Assertion failures: check `git log` for an intentional behavior change before changing the app. If the app behavior changed on purpose (e.g. `normalizedForSearch()` appends U+E0100 to `辻`), update the test expectation and say so.
- Never raise `IPHONEOS_DEPLOYMENT_TARGET` to make something compile; propose an iOS cut-off to the developer instead.

## Report

Executed / failed counts per class, failing test names with the assertion message, and what was changed to fix them (if anything).
