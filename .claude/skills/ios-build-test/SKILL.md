---
name: ios-build-test
description: BusNow の iOS アプリのビルド結果を確認し、単体テスト・UI テストのコマンドを開発者に提示する(ビルドは Stop hook が自動実行、テストは開発者が実行)。「iOSのテスト」「ビルドして」「テスト実行」と言われたときに使う。
---

# iOS Build and Test (BusNow)

Policy: **builds run automatically via the Stop hook; Claude never runs `xcodebuild` itself.** Tests are handed to the developer as copy-paste commands.

Minimum iOS is 18.6, but this Mac only has iOS 18.2/18.5 and 26.x/27.0 simulator runtimes, so tests use an iOS 26+ simulator (`iPhone 17`). The `iPhone 16` simulators are iOS 18.x and fail.

## Build: the Stop hook does it

`.claude/hooks/build-on-stop.sh` builds at the end of every turn in which Swift files under `20_Source/BusNow/` changed:

```bash
xcodebuild -scheme BusNow -destination 'generic/platform=iOS Simulator' build -quiet
```

- On failure the hook blocks the stop and returns the error lines. Fix them and end the turn again; the hook re-runs on the new diff.
- On success it shows a system message. Report that the build passed.
- Do not run the build manually mid-turn. If the developer asks for a build without Swift changes, give them the command above.

## Unit tests: give the developer a command

Pick the test class related to the change and present the command (run from the repo root). Do not run it.

```bash
cd 20_Source/BusNow && xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -only-testing:BusNowTests/<TestClass>
```

Test classes (all under `BusNowTests/`): `BusNowTests`, `StringNormalizationTests`, `StopNameRepositoryTests`, `DedupRuleTests`.

Tell the developer: `xcodebuild test` can keep running 10+ minutes after the tests finish. The result is the `Test Suite 'Selected tests' passed|failed` line; they can stop the process (Ctrl+C) once it appears.

Python-side checks are fast and may be run here, e.g. after changing the dedup rule: `python3 scripts/test_dedup_rule.py`.

## Full suite and UI tests

```bash
cd 20_Source/BusNow && xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 17'
```

UI tests (`BusNowUITests`) launch the app and need the local Supabase running (Debug builds connect to it).

## When the developer reports failures

- Compile errors in tests: fix the test code to match the current app API; read the app code first.
- Assertion failures: check `git log` for an intentional behavior change before changing the app. If the app behavior changed on purpose (e.g. `normalizedForSearch()` appends U+E0100 to `辻`), update the test expectation and say so.
- Never raise `IPHONEOS_DEPLOYMENT_TARGET` to make something compile; propose an iOS cut-off to the developer instead.
- After fixing, give the same test command again.

## Report

Build result from the hook, the exact test command(s) for the developer, and what was changed (if anything).
