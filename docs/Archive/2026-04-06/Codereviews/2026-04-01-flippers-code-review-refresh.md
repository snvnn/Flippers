# Flippers Code Review Refresh

Date: 2026-04-01

## Findings

- [High] Anthropic API key is still committed in plaintext and read from the shipped app bundle
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Config.plist:5`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Services/ClaudeOCRService.swift:214`
  - 이유: `CLAUDE_API_KEY` is stored directly in source-controlled `Config.plist`, and `ClaudeOCRService` loads it from `Bundle.main`. Any archived app, copied build artifact, or extracted app bundle exposes the credential.
  - 영향: Secret leakage, unauthorized API usage, and difficult secret rotation across environments.
  - 수정 방향: Remove the real key from source, rotate the exposed key, keep only a template file in git, and inject secrets via build settings or another environment-specific mechanism.

- [High] The checked-in Xcode project still has no Firebase Swift package references even though the app imports Firebase modules
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers.xcodeproj/project.pbxproj:98`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/FlippersApp.swift:10`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Data/Remote/FirebaseAuthRepository.swift:5`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Data/Remote/FirebaseSyncService.swift:5`
  - 이유: `packageProductDependencies` is empty for the app and test targets, and the project file contains no `XCRemoteSwiftPackageReference` or `XCSwiftPackageProductDependency` entries, while source files import `FirebaseCore`, `FirebaseAuth`, and `FirebaseFirestore`.
  - 영향: A clean checkout is not reproducibly buildable on another machine or in CI, even before runtime configuration is considered.
  - 수정 방향: Add the Firebase iOS SDK via Swift Package Manager, link the exact products used by the app, and commit the resulting project metadata.

- [High] Firebase is configured at launch, but the repository contains no `GoogleService-Info.plist` and no explicit `FirebaseOptions` fallback
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/FlippersApp.swift:18`
  - 이유: The app unconditionally calls `FirebaseApp.configure()`, but a workspace search found no `GoogleService-Info.plist`, and the codebase contains no manual `FirebaseOptions(contentsOfFile:)` or equivalent configuration path.
  - 영향: In the checked-in repository state, Firebase initialization is likely to fail at runtime on a fresh environment, blocking auth and sync flows.
  - 수정 방향: Commit a valid environment-specific Firebase config strategy, or gate Firebase initialization behind an explicit configuration path that fails safely and diagnostically.

- [Medium] Camera capture assumes hardware camera availability and can fail or crash on simulators and camera-less environments
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/OCR/OCRView.swift:361`
  - 이유: `UIImagePickerController.sourceType` is set to `.camera` unconditionally with no `UIImagePickerController.isSourceTypeAvailable(.camera)` guard.
  - 영향: Tapping the camera path in unsupported environments can break the OCR flow before the user can recover.
  - 수정 방향: Check source availability before presenting the camera sheet, and show a user-facing fallback message when the camera is unavailable.

- [Medium] OCR review editing can create empty cards because the save path validates selection only, not required content
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/OCR/OCRView.swift:338`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/OCR/OCRViewModel.swift:145`
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Domain/Models/Card.swift:83`
  - 이유: OCR rows are now editable with `TextField`s, but `saveCards` only filters on `isSelected`. If the user clears `kanji` and leaves the row selected, a `Card` and `SRSState` are still inserted, while all fields may be skipped as empty.
  - 영향: Users can generate blank study cards that show no primary text and are difficult to identify or recover from later.
  - 수정 방향: Reject or auto-deselect OCR rows whose primary field becomes empty, and validate required content again before insertion.

- [Medium] The OCR parser is still hard-coded to one horizontal worksheet layout and silently overwrites values per column bucket
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/OCR/OCRViewModel.swift:119`
  - 이유: Parsing assigns exactly one `kanji`, `reading`, and `meaning` value based on fixed `x` ranges (`0.15..<0.35`, `0.35..<0.55`, `default`). Rows with different layouts or multiple blocks per semantic column lose information because later blocks overwrite earlier ones.
  - 영향: A core user flow, OCR import, will silently generate degraded or wrong cards on many real-world textbook layouts outside the assumed template.
  - 수정 방향: Either constrain the supported layout explicitly in-product, or move to a more robust layout analysis strategy that preserves multiple tokens and validates the parse before save.

- [Medium] Firebase auth message localization is implemented with brittle substring matching on vendor error text
  - 위치: `/Users/yunhyeon/claudecode/nipponbenkyo/Flippers/Flippers/Presentation/Auth/AuthViewModel.swift:111`
  - 이유: `koreanMessage(for:)` dispatches on `error.localizedDescription.contains(...)`. This depends on SDK wording and device locale rather than stable Firebase error codes.
  - 영향: Error translations can regress silently after SDK updates or on localized devices, leaking raw backend text back into the login and signup UX.
  - 수정 방향: Normalize Firebase errors by domain/code and map those stable codes to Korean strings.

## Open Questions

- Is Firebase currently configured only in an uncommitted local Xcode state? The checked-in project file does not show package wiring, and the repository does not include Firebase runtime config.
- Is `Config.plist` intended only for local development, or is it expected to ship in app bundles?
- What exact OCR document format is in-scope for this feature? The current parser is tuned to a very specific left-to-right worksheet layout.

## Residual Risks

- I could not run `xcodebuild` in this environment because the active developer directory points to Command Line Tools instead of a full Xcode installation.
- I could not validate real iOS runtime behavior on a simulator or device from this environment.
- `FlippersTests` now meaningfully cover `SRSEngine`, but OCR, auth, and runtime configuration paths still have little or no automated coverage.
- `card-ace-sync` still has only a trivial placeholder test at `/Users/yunhyeon/claudecode/nipponbenkyo/card-ace-sync/src/test/example.test.ts:3`, and `npm test -- --runInBand` currently fails because `vitest` is not installed locally.
