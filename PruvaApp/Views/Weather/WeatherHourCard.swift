import SwiftUI

struct WeatherHourCard: View {
    let hour: WeatherHour
    var body: some View {
        VStack(spacing: 5) {
            Text(hour.time).font(.caption2)
            Text("\(String(format: "%.1f", hour.waveHeight))m").fontWeight(.bold).foregroundStyle(.white)
            Text("\(Int(hour.windSpeed)) kn").font(.caption2).foregroundStyle(.white.opacity(0.85))
            Text("\(Int(hour.temperature))°C").font(.caption2).foregroundStyle(.white.opacity(0.85))
            Text(hour.safetyLabel).font(.caption2).foregroundStyle(hour.safetyColor)
        }
        .padding(8)
        .frame(width: 100)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
