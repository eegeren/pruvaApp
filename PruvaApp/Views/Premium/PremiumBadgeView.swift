import SwiftUI

struct PremiumBadgeView: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(colors: [Color.oceanAccent, Color.oceanAccent], startPoint: .leading, endPoint: .trailing)
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.oceanAccent.opacity(0.6), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
