//
//  FlippersTests.swift
//  FlippersTests
//
//  Created by 윤현 on 3/30/26.
//

import Foundation
import Testing
import SwiftData
import AuthenticationServices
import FirebaseAuth
@testable import Flippers

// MARK: - SRSEngine Tests

struct SRSEngineTests {

    // MARK: - Helpers

    private func input(
        status: SRSStatus = .new,
        interval: Int = 0,
        ease: Double = 2.5,
        step: Int = 0,
        lapses: Int = 0
    ) -> SRSInput {
        SRSInput(interval: interval, ease: ease, learningStep: step, lapseCount: lapses, status: status)
    }

    // MARK: - New / Learning

    @Test func newCard_again_staysLearningStep0() {
        let out = SRSEngine.calculate(input: input(status: .new), rating: .again)
        #expect(out.nextStatus == .learning)
        #expect(out.nextLearningStep == 0)
        #expect(out.requeueDelay != nil)
    }

    @Test func newCard_hard_staysAtStep0() {
        let out = SRSEngine.calculate(input: input(status: .new), rating: .hard)
        #expect(out.nextStatus == .learning)
        #expect(out.nextLearningStep == 0)
        #expect(out.requeueDelay != nil)
    }

    @Test func newCard_good_advancesToStep1() {
        let out = SRSEngine.calculate(input: input(status: .new), rating: .good)
        #expect(out.nextStatus == .learning)
        #expect(out.nextLearningStep == 1)
        #expect(out.requeueDelay != nil)
    }

    @Test func learningCard_good_atLastStep_graduates() {
        // learningSteps = [60, 600] — step index 1 is the last step
        let out = SRSEngine.calculate(input: input(status: .learning, step: 1), rating: .good)
        #expect(out.nextStatus == .review)
        #expect(out.nextInterval == SchedulingPolicy.default.graduatingInterval)
        #expect(out.requeueDelay == nil)
    }

    @Test func newCard_easy_graduatesImmediately() {
        let policy = SchedulingPolicy.default
        let out = SRSEngine.calculate(input: input(status: .new), rating: .easy)
        #expect(out.nextStatus == .review)
        #expect(out.nextInterval == policy.easyInterval)
        #expect(out.nextEase > 2.5)
        #expect(out.requeueDelay == nil)
    }

    // MARK: - Review

    @Test func reviewCard_good_intervalScalesByEase() {
        let policy = SchedulingPolicy.default
        let inp = input(status: .review, interval: 10, ease: 2.5)
        let out = SRSEngine.calculate(input: inp, rating: .good)
        let expected = max(policy.minimumInterval, Int((10.0 * 2.5).rounded()))
        #expect(out.nextInterval == expected)
        #expect(out.nextStatus == .review)
        #expect(out.nextEase == 2.5)
        #expect(out.requeueDelay == nil)
    }

    @Test func reviewCard_again_causesLapse() {
        let inp = input(status: .review, interval: 10, ease: 2.5, lapses: 0)
        let out = SRSEngine.calculate(input: inp, rating: .again)
        #expect(out.nextStatus == .relearning)
        #expect(out.nextLapseCount == 1)
        #expect(out.nextEase < 2.5)
        #expect(out.requeueDelay != nil)
    }

    @Test func reviewCard_hard_decreasesEase() {
        let policy = SchedulingPolicy.default
        let inp = input(status: .review, interval: 10, ease: 2.5)
        let out = SRSEngine.calculate(input: inp, rating: .hard)
        let expectedEase = max(policy.minimumEase, 2.5 - policy.easeDecrementHard)
        #expect(out.nextEase == expectedEase)
        #expect(out.nextStatus == .review)
    }

    @Test func reviewCard_easy_boostsEaseAndInterval() {
        let policy = SchedulingPolicy.default
        let inp = input(status: .review, interval: 10, ease: 2.5)
        let out = SRSEngine.calculate(input: inp, rating: .easy)
        let expectedEase = min(policy.maximumEase, 2.5 + policy.easeIncrement)
        #expect(out.nextEase == expectedEase)
        #expect(out.nextInterval > 10)
        #expect(out.nextStatus == .review)
    }

    // MARK: - Boundary

    @Test func ease_neverDropsBelowMinimum() {
        let policy = SchedulingPolicy.default
        let inp = input(status: .review, interval: 1, ease: policy.minimumEase)
        let out = SRSEngine.calculate(input: inp, rating: .again)
        #expect(out.nextEase >= policy.minimumEase)
    }

    @Test func ease_neverExceedsMaximum() {
        let policy = SchedulingPolicy.default
        let inp = input(status: .review, interval: 1, ease: policy.maximumEase)
        let out = SRSEngine.calculate(input: inp, rating: .easy)
        #expect(out.nextEase <= policy.maximumEase)
    }

    // MARK: - Relearning

    @Test func relearningCard_good_atLastStep_returnsToReview() {
        // relearningSteps = [600] — step 0 is the only step
        let inp = input(status: .relearning, interval: 5, step: 0)
        let out = SRSEngine.calculate(input: inp, rating: .good)
        #expect(out.nextStatus == .review)
        #expect(out.requeueDelay == nil)
    }

    @Test func relearningCard_again_requeuesSameStep() {
        let inp = input(status: .relearning, interval: 5, step: 0)
        let out = SRSEngine.calculate(input: inp, rating: .again)
        #expect(out.nextStatus == .relearning)
        #expect(out.nextLearningStep == 0)
        #expect(out.requeueDelay != nil)
    }
}

struct OCRConfigurationTests {

    @Test func proxyBaseURL_prefersEnvironmentValue() {
        let url = OCRConfiguration.proxyBaseURL(
            environment: [OCRConfiguration.proxyBaseURLEnvironmentVariable: " https://proxy.example "],
            bundleInfo: [OCRConfiguration.proxyBaseURLInfoKey: "https://bundle.example"]
        )

        #expect(url?.absoluteString == "https://proxy.example")
    }

    @Test func cloudEnhancementAvailability_withoutProxy_isUnavailable() {
        let availability = OCRConfiguration.cloudEnhancementAvailability(
            environment: [:],
            bundleInfo: [:]
        )

        guard case .unavailable(let reason) = availability else {
            Issue.record("Expected unavailable cloud enhancement without a proxy endpoint")
            return
        }

        #expect(reason.contains(OCRConfiguration.proxyBaseURLEnvironmentVariable))
        #expect(reason.contains(OCRConfiguration.proxyBaseURLInfoKey))
    }

    @Test func cloudEnhancementAvailability_withProxy_isAvailable() {
        let availability = OCRConfiguration.cloudEnhancementAvailability(
            environment: [:],
            bundleInfo: [OCRConfiguration.proxyBaseURLInfoKey: "https://proxy.example"]
        )

        guard case .available = availability else {
            Issue.record("Expected available cloud enhancement when a proxy endpoint is configured")
            return
        }
    }
}

final class MockOCRProxyURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            Issue.record("MockOCRProxyURLProtocol.requestHandler was not set")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class RecordedRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var request: URLRequest?

    func store(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        self.request = request
    }

    func load() -> URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return request
    }
}

private enum RequestCaptureError: Error {
    case missingBody
}

private func requestBodyData(for request: URLRequest) throws -> Data {
    if let body = request.httpBody {
        return body
    }

    guard let stream = request.httpBodyStream else {
        throw RequestCaptureError.missingBody
    }

    stream.open()
    defer { stream.close() }

    var collected = Data()
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
        let readCount = stream.read(buffer, maxLength: bufferSize)
        if readCount < 0 {
            throw stream.streamError ?? RequestCaptureError.missingBody
        }
        if readCount == 0 {
            break
        }
        collected.append(buffer, count: readCount)
    }

    guard !collected.isEmpty else {
        throw RequestCaptureError.missingBody
    }

    return collected
}

struct ClaudeOCRServiceTests {

    @Test func enhanceWords_postsToProxyAndMergesOnlyMissingFields() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockOCRProxyURLProtocol.self]

        let session = URLSession(configuration: configuration)
        let recordedRequest = RecordedRequestBox()
        MockOCRProxyURLProtocol.requestHandler = { request in
            recordedRequest.store(request)

            let responseBody = [
                "content": [
                    [
                        "type": "text",
                        "text": #"{"cards":[{"kanji":"腕","reading":"うで","meaning":"팔"},{"kanji":"機会","reading":"きかい","meaning":"기회"}]}"#,
                    ],
                ],
            ]

            let data = try JSONSerialization.data(withJSONObject: responseBody)
            let response = try #require(
                HTTPURLResponse(
                    url: request.url ?? URL(string: "https://proxy.example/api/ocr")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )
            )

            return (response, data)
        }
        defer { MockOCRProxyURLProtocol.requestHandler = nil }

        let service = ClaudeOCRService(
            session: session,
            proxyURL: URL(string: "https://proxy.example/api/ocr")
        )
        let input = [
            OCRWord(kanji: "腕", reading: "", meaning: ""),
            OCRWord(kanji: "機会", reading: "きかい", meaning: ""),
        ]

        let enhanced = try await service.enhanceWords(input)
        let request = try #require(recordedRequest.load())
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://proxy.example/api/ocr")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try requestBodyData(for: request)
        let jsonObject = try #require(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        let words = try #require(jsonObject["words"] as? [String])

        #expect(words == ["腕", "機会"])

        #expect(enhanced[0].reading == "うで")
        #expect(enhanced[0].meaning == "팔")
        #expect(enhanced[1].reading == "きかい")
        #expect(enhanced[1].meaning == "기회")
    }
}

final class MockAuthRepository: AuthRepository {
    var currentUser: AuthUser?
    var signInCallCount = 0
    var signUpCallCount = 0
    var appleSignInCallCount = 0
    var signOutCallCount = 0
    var signOutError: Error?

    func signInWithEmail(email: String, password: String) async throws -> AuthUser {
        signInCallCount += 1
        return AuthUser(uid: "mock-user", email: email)
    }

    func signUpWithEmail(email: String, password: String) async throws -> AuthUser {
        signUpCallCount += 1
        return AuthUser(uid: "mock-user", email: email)
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> AuthUser {
        appleSignInCallCount += 1
        return AuthUser(uid: "mock-apple-user", email: nil)
    }

    func signOut() throws {
        signOutCallCount += 1
        if let signOutError {
            throw signOutError
        }
    }

    func addAuthStateListener(_ listener: @escaping (AuthUser?) -> Void) -> Any {
        listener(currentUser)
        return UUID()
    }
}

private final class TestBundleMarker {}

@MainActor
struct AuthViewModelTests {

    @Test func submitEmail_whenAuthenticationUnavailable_setsConfigurationMessageWithoutCallingRepository() async {
        let repository = MockAuthRepository()
        let viewModel = AuthViewModel(
            authRepository: repository,
            configurationMessage: "Firebase 설정이 없어 로그인을 사용할 수 없습니다."
        )
        viewModel.email = "user@example.com"
        viewModel.password = "password123"

        await viewModel.submitEmail()

        #expect(viewModel.errorMessage == "Firebase 설정이 없어 로그인을 사용할 수 없습니다.")
        #expect(!viewModel.isLoading)
        #expect(repository.signInCallCount == 0)
        #expect(repository.signUpCallCount == 0)
    }

    @Test func handleAppleSignIn_whenAuthenticationUnavailable_setsConfigurationMessageWithoutCallingRepository() async {
        let repository = MockAuthRepository()
        let viewModel = AuthViewModel(
            authRepository: repository,
            configurationMessage: "Apple 로그인을 사용하려면 Firebase 구성이 필요합니다."
        )

        await viewModel.handleAppleSignIn(.failure(NSError(domain: ASAuthorizationError.errorDomain, code: ASAuthorizationError.failed.rawValue)))

        #expect(viewModel.errorMessage == "Apple 로그인을 사용하려면 Firebase 구성이 필요합니다.")
        #expect(repository.appleSignInCallCount == 0)
    }

    @Test func signOut_usesLocalizedAuthMessage() {
        let repository = MockAuthRepository()
        repository.currentUser = AuthUser(uid: "logged-in-user", email: "user@example.com")
        repository.signOutError = AuthError.network
        let viewModel = AuthViewModel(authRepository: repository)

        viewModel.signOut()

        #expect(viewModel.errorMessage == AuthError.network.errorDescription)
        #expect(repository.signOutCallCount == 1)
    }
}

struct FirebaseBootstrapTests {

    @Test func missingGoogleServiceInfo_statusHasStableUserMessage() {
        #expect(
            FirebaseConfigurationStatus.missingGoogleServiceInfo.userMessage ==
            "GoogleService-Info.plist가 번들에 없어 로그인과 클라우드 동기화가 비활성화되었습니다. 로컬 학습 기능은 계속 사용할 수 있습니다."
        )
    }

    @Test func invalidGoogleServiceInfo_statusHasStableUserMessage() {
        #expect(
            FirebaseConfigurationStatus.invalidGoogleServiceInfo.userMessage ==
            "Firebase 설정 파일을 읽을 수 없어 로그인과 클라우드 동기화가 비활성화되었습니다. GoogleService-Info.plist 구성을 확인하세요."
        )
    }

    @Test func configureIfAvailable_withoutGoogleServiceInfo_returnsMissingStatus() {
        let bundle = Bundle(for: TestBundleMarker.self)
        let status = FirebaseBootstrap.configureIfAvailable(bundle: bundle)

        #expect(status == .missingGoogleServiceInfo)
    }
}

struct FirebaseAuthErrorMappingTests {

    @Test func invalidEmail_mapsToStableAuthError() {
        let error = NSError(domain: AuthErrorDomain, code: AuthErrorCode.invalidEmail.rawValue)
        let mapped = FirebaseAuthRepository.mapFirebaseError(error)

        #expect(mapped as? AuthError == .invalidEmail)
    }

    @Test func wrongPassword_mapsToStableAuthError() {
        let error = NSError(domain: AuthErrorDomain, code: AuthErrorCode.wrongPassword.rawValue)
        let mapped = FirebaseAuthRepository.mapFirebaseError(error)

        #expect(mapped as? AuthError == .invalidCredentials)
    }

    @Test func unknownDomain_returnsOriginalError() {
        let error = NSError(domain: "OtherDomain", code: 999)
        let mapped = FirebaseAuthRepository.mapFirebaseError(error) as NSError

        #expect(mapped.domain == "OtherDomain")
        #expect(mapped.code == 999)
    }
}

@MainActor
struct PresetImportServiceTests {

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([
            User.self,
            Deck.self,
            DeckSection.self,
            Card.self,
            CardField.self,
            SRSState.self,
            ReviewLog.self,
            OCRSource.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test func defaultVocabularyPreset_hasRequiredFrontHintAndBackFields() {
        let preset = try! BundlePresetCatalog.decodePreset(Self.basicVocabularyPresetData).definition

        #expect(preset.cards.count == 10)
        #expect(preset.expectedCardCount == 10)
        #expect(preset.sourceLabel == "Flippers authored content")

        for card in preset.cards {
            #expect(card.type == .word)
            #expect(card.sourceLabel == "Flippers authored content")
            #expect(card.fields.contains { $0.name == "word" && !$0.value.isEmpty })
            #expect(card.fields.contains { $0.name == "reading" && !$0.value.isEmpty })
            #expect(card.fields.contains { $0.name == "meaning" && !$0.value.isEmpty })
            #expect(card.fields.contains { $0.name == "example" && !$0.value.isEmpty })
        }
    }

    @Test func importPreset_createsDeckCardsSRSAndSkipsDuplicates() throws {
        let context = try makeModelContext()
        let preset = try BundlePresetCatalog.decodePreset(Self.basicVocabularyPresetData).definition

        let firstResult = PresetImportService.importPreset(
            preset,
            into: context,
            existingCards: []
        )

        var cards = try context.fetch(FetchDescriptor<Card>())
        var decks = try context.fetch(FetchDescriptor<Deck>())
        #expect(firstResult.createdCount == preset.cards.count)
        #expect(firstResult.skippedCount == 0)
        #expect(cards.count == preset.cards.count)
        #expect(decks.count == 1)
        #expect(cards.allSatisfy { $0.createdSource == .imported })
        #expect(cards.allSatisfy { $0.presetVersion == preset.version })
        #expect(cards.allSatisfy { $0.sourceLabel == "Flippers authored content" })
        #expect(cards.allSatisfy { $0.srsState != nil })

        let secondResult = PresetImportService.importPreset(
            preset,
            into: context,
            existingCards: cards
        )

        cards = try context.fetch(FetchDescriptor<Card>())
        decks = try context.fetch(FetchDescriptor<Deck>())
        #expect(secondResult.createdCount == 0)
        #expect(secondResult.skippedCount == preset.cards.count)
        #expect(cards.count == preset.cards.count)
        #expect(decks.count == 1)
    }

    private static let basicVocabularyPresetData = """
    {
      "cards": [
        {
          "example": "学校に行きます。 / 학교에 갑니다.",
          "meaning": "학교",
          "presetID": "basic-vocabulary-v1-0001",
          "presetVersion": 1,
          "reading": "がっこう",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "学校"
        },
        {
          "example": "先生に質問します。 / 선생님께 질문합니다.",
          "meaning": "선생님",
          "presetID": "basic-vocabulary-v1-0002",
          "presetVersion": 1,
          "reading": "せんせい",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "先生"
        },
        {
          "example": "日本語を勉強します。 / 일본어를 공부합니다.",
          "meaning": "공부",
          "presetID": "basic-vocabulary-v1-0003",
          "presetVersion": 1,
          "reading": "べんきょう",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "勉強"
        },
        {
          "example": "時間があります。 / 시간이 있습니다.",
          "meaning": "시간",
          "presetID": "basic-vocabulary-v1-0004",
          "presetVersion": 1,
          "reading": "じかん",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "時間"
        },
        {
          "example": "今日は忙しいです。 / 오늘은 바쁩니다.",
          "meaning": "오늘",
          "presetID": "basic-vocabulary-v1-0005",
          "presetVersion": 1,
          "reading": "きょう",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "今日"
        },
        {
          "example": "明日また来ます。 / 내일 다시 옵니다.",
          "meaning": "내일",
          "presetID": "basic-vocabulary-v1-0006",
          "presetVersion": 1,
          "reading": "あした",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "明日"
        },
        {
          "example": "友達と話します。 / 친구와 이야기합니다.",
          "meaning": "친구",
          "presetID": "basic-vocabulary-v1-0007",
          "presetVersion": 1,
          "reading": "ともだち",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "友達"
        },
        {
          "example": "電車に乗ります。 / 전철을 탑니다.",
          "meaning": "전철, 기차",
          "presetID": "basic-vocabulary-v1-0008",
          "presetVersion": 1,
          "reading": "でんしゃ",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "電車"
        },
        {
          "example": "朝ご飯を食べます。 / 아침밥을 먹습니다.",
          "meaning": "먹다",
          "presetID": "basic-vocabulary-v1-0009",
          "presetVersion": 1,
          "reading": "たべる",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "食べる"
        },
        {
          "example": "映画を見ます。 / 영화를 봅니다.",
          "meaning": "보다",
          "presetID": "basic-vocabulary-v1-0010",
          "presetVersion": 1,
          "reading": "みる",
          "sourceLabel": "Flippers authored content",
          "type": "word",
          "word": "見る"
        }
      ],
      "expectedCardCount": 10,
      "exportMode": "production",
      "id": "basic-vocabulary-v1",
      "sourceLabel": "Flippers authored content",
      "subtitle": "초기 학습용 일본어 기본 단어 세트",
      "title": "기본 단어",
      "version": 1
    }
    """.data(using: .utf8)!
}

struct OCRRowParserTests {

    @Test func parser_handlesShiftedColumnsUsingScriptHints() {
        let words = OCRRowParser.parse(blocks: [
            OCRTextBlock(text: "腕", x: 0.22, y: 0.90),
            OCRTextBlock(text: "うで", x: 0.33, y: 0.90),
            OCRTextBlock(text: "팔", x: 0.44, y: 0.90)
        ])

        #expect(words.count == 1)
        #expect(words.first?.kanji == "腕")
        #expect(words.first?.reading == "うで")
        #expect(words.first?.meaning == "팔")
    }

    @Test func parser_joinsSplitMeaningBlocks() {
        let words = OCRRowParser.parse(blocks: [
            OCRTextBlock(text: "機会", x: 0.20, y: 0.85),
            OCRTextBlock(text: "きかい", x: 0.38, y: 0.85),
            OCRTextBlock(text: "기회", x: 0.62, y: 0.85),
            OCRTextBlock(text: "chance", x: 0.74, y: 0.85)
        ])

        #expect(words.count == 1)
        #expect(words.first?.meaning == "기회 chance")
    }

    @Test func parser_dropsCheckboxOnlyNoise() {
        let words = OCRRowParser.parse(blocks: [
            OCRTextBlock(text: "□", x: 0.05, y: 0.80),
            OCRTextBlock(text: "勉強", x: 0.22, y: 0.80),
            OCRTextBlock(text: "べんきょう", x: 0.40, y: 0.80),
            OCRTextBlock(text: "공부", x: 0.62, y: 0.80)
        ])

        #expect(words.count == 1)
        #expect(words.first?.kanji == "勉強")
    }

    @Test func parser_dropsUnsupportedJapaneseOnlyRows() {
        let words = OCRRowParser.parse(blocks: [
            OCRTextBlock(text: "単語", x: 0.18, y: 0.76),
            OCRTextBlock(text: "漢字", x: 0.34, y: 0.76),
            OCRTextBlock(text: "例文", x: 0.52, y: 0.76)
        ])

        #expect(words.isEmpty)
    }
}

@MainActor
struct OCRViewModelTests {

    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([
            User.self,
            Deck.self,
            DeckSection.self,
            Card.self,
            CardField.self,
            SRSState.self,
            ReviewLog.self,
            OCRSource.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test func invalidSelectedWords_areNotSavable() {
        let viewModel = OCRViewModel()
        viewModel.extractedWords = [
            OCRWord(kanji: "漢字", reading: "かんじ", meaning: "한자"),
            OCRWord(kanji: "   ", reading: "ひらがな", meaning: "뜻")
        ]

        #expect(viewModel.selectedWordCount == 2)
        #expect(viewModel.savableSelectedWordCount == 1)
        #expect(viewModel.hasInvalidSelectedWords)
    }

    @Test func deselectedInvalidWord_doesNotBlockSaveState() {
        let viewModel = OCRViewModel()
        viewModel.extractedWords = [
            OCRWord(kanji: "단어", reading: "たんご", meaning: "단어"),
            OCRWord(kanji: "", reading: "", meaning: "", isSelected: false)
        ]

        #expect(viewModel.selectedWordCount == 1)
        #expect(viewModel.savableSelectedWordCount == 1)
        #expect(!viewModel.hasInvalidSelectedWords)
    }

    @Test func incompleteSelectedWords_raiseReviewNotice() {
        let viewModel = OCRViewModel()
        viewModel.extractedWords = [
            OCRWord(kanji: "漢字", reading: "かんじ", meaning: ""),
            OCRWord(kanji: "腕", reading: "うで", meaning: "팔")
        ]

        #expect(viewModel.hasIncompleteSelectedWords)
        #expect(viewModel.hasInvalidSelectedWords)
        #expect(viewModel.savableSelectedWordCount == 1)
        #expect(viewModel.reviewNoticeMessage?.contains("읽기 또는 뜻") == true)
    }

    @Test func emptyOCRResults_surfaceUnsupportedLayoutNotice() {
        let viewModel = OCRViewModel()
        viewModel.extractedWords = []

        #expect(viewModel.reviewNoticeMessage?.contains("가로형") == true)
    }

    @Test func saveCards_blocksInvalidRowsAndSetsErrorMessage() throws {
        let viewModel = OCRViewModel()
        let context = try makeModelContext()
        viewModel.extractedWords = [
            OCRWord(kanji: "腕", reading: "", meaning: "팔")
        ]

        viewModel.saveCards(context: context)

        let savedCards = try context.fetch(FetchDescriptor<Card>())
        #expect(savedCards.isEmpty)
        #expect(viewModel.errorMessage?.contains("저장할 수 없는 값") == true)
    }
}
