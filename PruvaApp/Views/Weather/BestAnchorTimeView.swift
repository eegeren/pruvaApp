import SwiftUI

struct BestAnchorTimeView: View {
    let data: [WeatherHour]
    let bestWindow: (start: String, end: String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Anchor Window").font(.headline)
            Text(bestWindow.map { "\($0.start) - \($0.end)" } ?? "No safe window today")
            HStack(spacing: 4) {
                ForEach(Array(data.prefix(24).enumerated()), id: \.offset) { _, h in
                    RoundedRectangle(cornerRadius: 2).fill(h.safetyColor).frame(height: 10)
                }
            }
        }.padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
