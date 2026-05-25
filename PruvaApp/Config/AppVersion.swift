import Foundation

enum AppVersion {
    static let mapPointDetailsRevision = "1.2-gemini"

    static var marketing: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "3"
    }

    static var display: String {
        "\(marketing) (\(build))"
    }
}
