import SwiftUI

struct DepthGaugeView: View {
    let depth: Double?
    @State private var animatedDepth: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Depth")
                .font(.headline)
                .foregroundColor(.white)

            if let depth = depth, depth > 0 {
                HStack(spacing: 20) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "023E8A"))
                            .frame(width: 40, height: 120)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "00B4D8"), Color(hex: "0077B6")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: min(CGFloat(animatedDepth / 20.0) * 120, 120))
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedDepth)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f m", depth))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("average depth")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Text(depthLabel(depth))
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(depthColor(depth).opacity(0.3))
                            .foregroundColor(depthColor(depth))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach([5.0, 10.0, 15.0, 20.0], id: \.self) { mark in
                                HStack(spacing: 4) {
                                    Rectangle()
                                        .fill(depth >= mark ? Color(hex: "00B4D8") : Color.white.opacity(0.2))
                                        .frame(width: 20, height: 1)
                                    Text("\(Int(mark))m")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.white.opacity(0.4))
                    Text("Depth data not available")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                }
                .padding()
                .background(Color(hex: "023E8A"))
                .cornerRadius(12)
            }
        }
        .onAppear {
            animatedDepth = depth ?? 0
        }
    }

    func depthLabel(_ d: Double) -> String {
        if d < 3 { return "Shallow" }
        if d < 8 { return "Normal" }
        return "Deep"
    }

    func depthColor(_ d: Double) -> Color {
        if d < 3 { return .orange }
        if d < 8 { return .green }
        return Color(hex: "00B4D8")
    }
}
