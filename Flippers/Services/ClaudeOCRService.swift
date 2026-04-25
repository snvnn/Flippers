import Foundation

// MARK: - Decoded card from Claude response

nonisolated struct ParsedCard: Decodable, Sendable, Equatable {
    var kanji: String
    var reading: String
    var meaning: String
}

// MARK: - Internal response models

private nonisolated struct ClaudeResponse: Decodable, Sendable {
    nonisolated struct ContentBlock: Decodable, Sendable {
        var type: String
        var text: String?
    }
    var content: [ContentBlock]
}

private nonisolated struct OCRProxyRequest: Encodable, Sendable {
    var words: [String]
    var imageBase64: String?
    var mimeType: String?
}

private nonisolated struct CardsPayload: Decodable, Sendable {
    var cards: [ParsedCard]
}

// MARK: - Errors

nonisolated enum OCRError: LocalizedError {
    case serviceUnavailable(String)
    case networkError(String)
    case emptyResponse
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable(let reason):
            return reason
        case .networkError(let detail):
            return "네트워크 오류: \(detail)"
        case .emptyResponse:
            return "OCR 프록시 응답에 텍스트가 없습니다."
        case .parseError(let detail):
            return "응답 파싱 실패: \(detail)"
        }
    }
}

// MARK: - Configuration

nonisolated enum OCRCloudEnhancementAvailability: Sendable {
    case available
    case unavailable(String)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }
}

nonisolated enum OCRConfiguration {
    static let proxyBaseURLInfoKey = "OCRProxyBaseURL"
    static let proxyBaseURLEnvironmentVariable = "OCR_PROXY_BASE_URL"

    static func proxyBaseURL(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> URL? {
        if let rawValue = normalizedEnvironmentValue(
            named: proxyBaseURLEnvironmentVariable,
            environment: environment
        ) {
            return URL(string: rawValue)
        }

        if let rawValue = normalizedBundleValue(named: proxyBaseURLInfoKey, bundleInfo: bundleInfo) {
            return URL(string: rawValue)
        }

        return nil
    }

    static func proxyEndpointURL(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> URL? {
        guard let baseURL = proxyBaseURL(environment: environment, bundleInfo: bundleInfo) else {
            return nil
        }

        let normalizedPath = "/" + baseURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if normalizedPath.hasSuffix("/api/ocr") {
            return baseURL
        }

        var endpointURL = baseURL
        endpointURL.append(path: "api")
        endpointURL.append(path: "ocr")
        return endpointURL
    }

    static func cloudEnhancementAvailability(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> OCRCloudEnhancementAvailability {
        if proxyEndpointURL(environment: environment, bundleInfo: bundleInfo) != nil {
            return .available
        }
        return .unavailable(
            "OCR 프록시 엔드포인트가 구성되지 않았습니다. Info.plist의 \(proxyBaseURLInfoKey) 또는 환경 변수 \(proxyBaseURLEnvironmentVariable)를 설정하세요."
        )
    }

    static func unavailabilityReason(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> String? {
        switch cloudEnhancementAvailability(environment: environment, bundleInfo: bundleInfo) {
        case .available:
            return nil
        case .unavailable(let reason):
            return reason
        }
    }

    private static func normalizedEnvironmentValue(
        named name: String,
        environment: [String: String]
    ) -> String? {
        guard let value = environment[name]?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        return value.isEmpty ? nil : value
    }

    private static func normalizedBundleValue(named name: String, bundleInfo: [String: Any]) -> String? {
        guard let value = bundleInfo[name] as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Service

/// Claude는 프록시 서버 뒤에서만 사용한다.
/// 클라이언트는 Vision이 추출한 단어 텍스트만 프록시에 전송한다.
actor ClaudeOCRService {
    static let shared = ClaudeOCRService()

    private let session: URLSession
    private let proxyURL: URL?

    init(
        session: URLSession = .shared,
        proxyURL: URL? = OCRConfiguration.proxyEndpointURL()
    ) {
        self.session = session
        self.proxyURL = proxyURL
    }

    // MARK: - Enhance words

    /// Vision으로 추출한 단어 배열을 받아 서버 프록시 뒤의 Claude로 읽기/뜻을 보완합니다.
    /// - 이미 reading/meaning이 있는 단어는 그대로 유지
    /// - 없는 단어만 Claude가 보완
    func enhanceWords(_ words: [OCRWord]) async throws -> [OCRWord] {
        guard !words.isEmpty else { return words }
        guard let proxyURL else {
            throw OCRError.serviceUnavailable(
                OCRConfiguration.unavailabilityReason() ?? "OCR 프록시를 사용할 수 없습니다."
            )
        }

        // reading 또는 meaning이 비어있는 단어만 보완 요청
        let needsEnhancement = words.filter { $0.reading.isEmpty || $0.meaning.isEmpty }
        guard !needsEnhancement.isEmpty else { return words }

        let requestBody = OCRProxyRequest(
            words: needsEnhancement.map(\.kanji),
            imageBase64: nil,
            mimeType: nil
        )

        var urlRequest = URLRequest(url: proxyURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw OCRError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw OCRError.networkError("응답 형식을 확인할 수 없습니다.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw OCRError.networkError(Self.responseDetail(from: data) ?? "HTTP \(http.statusCode)")
        }

        let claudeResponse: ClaudeResponse
        do {
            claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        } catch {
            throw OCRError.parseError(error.localizedDescription)
        }

        guard let text = claudeResponse.content.first(where: { $0.type == "text" })?.text,
              let jsonData = text.data(using: .utf8) else {
            throw OCRError.emptyResponse
        }

        let payload: CardsPayload
        do {
            payload = try JSONDecoder().decode(CardsPayload.self, from: jsonData)
        } catch {
            throw OCRError.parseError(error.localizedDescription)
        }

        // 보완된 데이터를 원본 words에 병합 (순서 기반 매핑 — kanji 중복 문제 방지)
        var enhanced = words
        for (idx, parsedCard) in payload.cards.enumerated() {
            guard idx < needsEnhancement.count else { break }
            let originalID = needsEnhancement[idx].id
            if let index = enhanced.firstIndex(where: { $0.id == originalID }) {
                if enhanced[index].reading.isEmpty {
                    enhanced[index].reading = parsedCard.reading
                }
                if enhanced[index].meaning.isEmpty {
                    enhanced[index].meaning = parsedCard.meaning
                }
            }
        }
        return enhanced
    }

    private static func responseDetail(from data: Data) -> String? {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = object["error"] as? String {
                return error
            }
            if let message = object["message"] as? String {
                return message
            }
        }

        guard let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }

        return text
    }
}
