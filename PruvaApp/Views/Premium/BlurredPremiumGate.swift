import SwiftUI

struct BlurredPremiumGate: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var showPaywall: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color.seaBlueMid.opacity(0.75), Color.seaBlue.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 200)

            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.oceanAccent)
                Text(title)
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                Button("Upgrade to Pro") {
                    showPaywall = true
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.oceanAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding()
        }
    }
}
