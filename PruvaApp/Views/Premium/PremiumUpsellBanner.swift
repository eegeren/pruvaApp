import SwiftUI

struct PremiumUpsellBanner: View {
    let text: String
    let icon: String
    @Binding var showPaywall: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.oceanAccent)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
            Text("Go Pro")
                .font(.caption.bold())
                .foregroundStyle(Color.oceanAccent)
        }
        .padding()
        .background(LinearGradient(colors: [Color.seaBlueMid, Color.seaBlue], startPoint: .leading, endPoint: .trailing))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.oceanAccent.opacity(0.55), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { showPaywall = true }
    }
}
