# Flippers Code Review

Date: 2026-04-01

## Findings

- [High] Anthropic API key is committed in plaintext and loaded from the app bundle
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Config.plist:5`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Services/ClaudeOCRService.swift:212`
  - 이유: `CLAUDE_API_KEY` is stored directly in `Config.plist`, and `ClaudeOCRService` reads it from the shipped bundle. Any local archive, shared build artifact, or device extraction exposes the key.
  - 영향: Secret leakage, unauthorized API usage, and inability to rotate or scope credentials cleanly per environment.
  - 수정 방향: Remove the real key from source, rotate the current credential, keep only an example file in git, and inject secrets through build settings or another environment-specific mechanism.

- [High] The Xcode project does not declare the Firebase package products required by the current source files
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/FlippersApp.swift:8`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Data/Remote/FirebaseAuthRepository.swift:5`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Data/Remote/FirebaseSyncService.swift:5`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers.xcodeproj/project.pbxproj:98`
  - 이유: The app imports `FirebaseCore`, `FirebaseAuth`, and `FirebaseFirestore`, but the target's `packageProductDependencies` is empty in the checked-in project file.
  - 영향: A clean checkout cannot reliably build the app. The current repository state is not reproducible for another machine or CI environment.
  - 수정 방향: Add the Firebase SPM package to the project and link the exact products the app imports. Commit the resulting `.xcodeproj` changes.

- [High] Firebase runtime configuration files are not represented in the checked-in project, so launch and OCR configuration are not reproducible
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/FlippersApp.swift:14`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Services/ClaudeOCRService.swift:214`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers.xcodeproj/project.pbxproj:26`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers.xcodeproj/project.pbxproj:210`
  - 이유: `FirebaseApp.configure()` assumes Firebase options are available, and `ClaudeOCRService` assumes `Config.plist` is bundled. The project file contains no checked-in file references or resource build entries for `GoogleService-Info.plist` or `Config.plist`.
  - 영향: On a fresh environment, Firebase initialization and OCR secret loading are likely to fail at runtime even if the code compiles.
  - 수정 방향: Explicitly add required plist resources to the target, or replace implicit bundle lookups with explicit configuration that fails safely and predictably.

- [Medium] SwiftData container creation is tied to `ContentView.body` and crashes the app on configuration failures
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/ContentView.swift:16`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/ContentView.swift:27`
  - 이유: `Self.makeContainer()` is called from the logged-in branch of `body`, so the container is recreated as the view hierarchy refreshes. If SwiftData or CloudKit setup fails, the app terminates via `fatalError`.
  - 영향: Store initialization becomes part of normal view recomputation, and any schema or entitlement issue becomes a hard crash instead of a recoverable error path.
  - 수정 방향: Construct the container once at app startup and inject it from the app/root scene. Replace `fatalError` with a user-visible failure state or diagnostic path.

- [Medium] OCR enhancement failures are silently swallowed, sending users to a review screen with no explanation
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/OCR/OCRViewModel.swift:39`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/OCR/OCRViewModel.swift:50`
  - 이유: `processImage` catches every Claude enhancement error and falls back to raw Vision output without setting `errorMessage`. When Vision extracts little or nothing, the user only sees an empty review state.
  - 영향: Missing API key, network failure, or parsing failure looks like "no words found", which makes the feature hard to debug and undermines user trust.
  - 수정 방향: Surface the fallback explicitly. Preserve the raw Vision fallback, but attach an error banner/message that tells the user enhancement failed and why.

- [Medium] OCR word enhancement merges by `kanji` only, so duplicate entries can be updated incorrectly or left blank
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Services/ClaudeOCRService.swift:147`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Services/ClaudeOCRService.swift:197`
  - 이유: `enhanceWords` uses `firstIndex(where: { $0.kanji == parsedCard.kanji })`. If the same surface form appears multiple times in an OCR result, only the first matching row is updated deterministically.
  - 영향: Review lists can contain partially enhanced duplicates, mismatched meanings, or leftover blank fields for repeated words.
  - 수정 방향: Merge by stable row identity or ordered mapping, not by the kanji string alone.

- [Medium] Core scheduling and OCR flows have no meaningful automated regression coverage
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/FlippersTests/FlippersTests.swift:13`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/card-ace-sync/src/test/example.test.ts:3`
  - 이유: The iOS test target contains only the default empty template test, and the web app contains only a trivial `true === true` test. The highest-risk logic in this repository is `SRSEngine`, OCR parsing, auth state handling, and card editing, but none of it is protected.
  - 영향: Regressions in study scheduling, OCR parsing, or auth behavior will reach users without any automated signal.
  - 수정 방향: Add focused tests around `SRSEngine.calculate`, OCR row parsing/merge behavior, and at least one end-to-end happy-path flow for card creation and study.

- [Low] Card editing persists empty optional fields, which breaks placeholder fallback behavior in study views
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/Cards/CardEditView.swift:185`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/Study/StudyView.swift:406`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/Study/StudyView.swift:431`
  - 이유: `insertFields` always saves `example`, `onyomi`, and `kunyomi` fields even when their trimmed value is empty. The study views check only for field presence, so an empty string suppresses the intended placeholder or renders blank content.
  - 영향: Kanji cards can show empty readings instead of `—`, and word cards can reserve space for an empty example field.
  - 수정 방향: Skip persistence of empty optional fields, or normalize `field(named:)` to treat empty strings as absent.

## Open Questions

- Is Firebase currently configured only in an uncommitted local Xcode state? The checked-in `.xcodeproj` does not show package or resource wiring, but I could not inspect a working Xcode GUI configuration from this environment.
- Is `Config.plist` intentionally excluded from the target and only meant for local development? The current source assumes it is bundled in production code.
- Is repeated-kanji OCR output an expected input shape for the product? If yes, the current merge logic needs a stronger identity model.

## Residual Risks

- I could not run `xcodebuild` in this environment because the active developer directory is Command Line Tools, not a full Xcode installation.
- I could not run meaningful `card-ace-sync` tests because dependencies are not installed locally; `npm test -- --runInBand` failed with `sh: vitest: command not found`.
- I reviewed the checked-in project state and uncommitted files, but I could not validate real iOS runtime behavior on a simulator or device from this environment.
