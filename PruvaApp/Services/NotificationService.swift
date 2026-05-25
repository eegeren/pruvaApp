import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermissions() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }
}
