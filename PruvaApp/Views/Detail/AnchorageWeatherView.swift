import SwiftUI

struct AnchorageWeatherView: View {
    let anchorage: Anchorage
    @StateObject private var weatherVM = WeatherViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Weather")
                .font(.headline)
                .foregroundColor(.white)

            if weatherVM.isLoading {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Loading weather...")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                }
                .padding()
                .background(Color(hex: "023E8A"))
                .cornerRadius(12)
            } else if let current = weatherVM.currentConditions {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(current.safetyColor.opacity(0.3), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0, to: CGFloat(current.safetyScore) / 100)
                            .stroke(current.safetyColor, lineWidth: 6)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        Text("\(current.safetyScore)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(current.safetyLabel)
                            .font(.headline)
                            .foregroundColor(current.safetyColor)
                        Text("Wave: \(String(format: "%.1f", current.waveHeight))m")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("Period: \(String(format: "%.1f", current.wavePeriod))s")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()
                }
                .padding()
                .background(Color(hex: "023E8A"))
                .cornerRadius(12)
            } else {
                Text("Weather data unavailable for this location")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "023E8A"))
                    .cornerRadius(12)
            }
        }
        .onAppear {
            Task {
                await weatherVM.loadWeather(
                    lat: anchorage.latitude,
                    lon: anchorage.longitude
                )
            }
        }
    }
}
