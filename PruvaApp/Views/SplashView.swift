import SwiftUI

struct SplashView: View {
    @State private var showMain = false
    @State private var scale: CGFloat = 0.6
    @AppStorage("didRequestInitialPermissions") private var didRequestInitialPermissions = false
    @ObservedObject private var locationService = LocationService.shared

    var body: some View {
        Group {
            if showMain { ContentView() }
            else {
                ZStack {
                    Color.seaBlue.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "ferry.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(Color.seafoam)
                            .scaleEffect(scale)
                        Text("PRUVA")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .tracking(8)
                            .foregroundStyle(.white)
                        Text("Your global nautical companion")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .task {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { scale = 1.0 }
                    if !didRequestInitialPermissions {
                        await NotificationService.shared.requestPermissions()
                        locationService.requestPermission()
                        didRequestInitialPermissions = true
                    }
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { showMain = true }
                }
            }
        }
    }
}
