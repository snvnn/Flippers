import Foundation
import FirebaseCore

enum FirebaseConfigurationStatus: Equatable {
    case configured
    case missingGoogleServiceInfo
    case invalidGoogleServiceInfo

    nonisolated var isConfigured: Bool {
        if case .configured = self {
            return true
        }
        return false
    }

    nonisolated var userMessage: String? {
        switch self {
        case .configured:
            return nil
        case .missingGoogleServiceInfo:
            return "GoogleService-Info.plist가 번들에 없어 로그인과 클라우드 동기화가 비활성화되었습니다. 로컬 학습 기능은 계속 사용할 수 있습니다."
        case .invalidGoogleServiceInfo:
            return "Firebase 설정 파일을 읽을 수 없어 로그인과 클라우드 동기화가 비활성화되었습니다. GoogleService-Info.plist 구성을 확인하세요."
        }
    }
}

enum FirebaseBootstrap {
    @discardableResult
    nonisolated static func configureIfAvailable(bundle: Bundle = .main) -> FirebaseConfigurationStatus {
        if FirebaseApp.app() != nil {
            return .configured
        }

        guard let path = bundle.path(forResource: "GoogleService-Info", ofType: "plist") else {
            return .missingGoogleServiceInfo
        }

        guard let options = FirebaseOptions(contentsOfFile: path) else {
            return .invalidGoogleServiceInfo
        }

        FirebaseApp.configure(options: options)
        return FirebaseApp.app() == nil ? .invalidGoogleServiceInfo : .configured
    }
}
