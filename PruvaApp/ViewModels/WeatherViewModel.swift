import SwiftUI
import Combine

struct WeatherHour: Identifiable {
    let id = UUID()
    let time: String
    let waveHeight: Double
    let waveDirection: Double
    let wavePeriod: Double
    let windWaveHeight: Double
    let windSpeed: Double
    let windDirection: Double
    let temperature: Double
    let apparentTemperature: Double
    let precipitation: Double
    var safetyScore: Int
    var safetyLabel: String
    var safetyColor: Color
}

struct DailyWeatherSummary {
    let averageWaveHeight: Double
    let maxWaveHeight: Double
    let averageWindSpeed: Double
    let cautionOrDangerHours: Int
}

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var hourlyData: [WeatherHour] = []
    @Published var isLoading = false
    @Published var selectedAnchorage: Anchorage? = nil
    @Published var errorMessage: String? = nil

    var currentConditions: WeatherHour? { hourlyData.first }

    var bestAnchorWindow: (start: String, end: String)? {
        let top = Array(hourlyData.prefix(24))
        var best: (Int, Int, Int)?
        var i = 0
        while i < top.count {
            if top[i].safetyScore > 80 {
                let start = i
                var end = i
                var total = 0
                while end < top.count && top[end].safetyScore > 80 { total += top[end].safetyScore; end += 1 }
                if end - start >= 3, best == nil || total > best!.2 { best = (start, end - 1, total) }
                i = end
            } else { i += 1 }
        }
        guard let best else { return nil }
        return (top[best.0].time, top[best.1].time)
    }

    var dailySummary: DailyWeatherSummary? {
        let today = Array(hourlyData.prefix(24))
        guard !today.isEmpty else { return nil }

        let heights = today.map(\.waveHeight)
        let average = heights.reduce(0, +) / Double(heights.count)
        let cautionOrDanger = today.filter { $0.safetyScore < 80 }.count

        return DailyWeatherSummary(
            averageWaveHeight: average,
            maxWaveHeight: heights.max() ?? 0,
            averageWindSpeed: today.map(\.windSpeed).reduce(0, +) / Double(today.count),
            cautionOrDangerHours: cautionOrDanger
        )
    }

    func loadWeather(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await APIService.shared.fetchWeather(lat: lat, lon: lon)
            let times = data.hourly.time
            let heights = data.hourly.waveHeight
            let directions = data.hourly.waveDirection
            let periods = data.hourly.wavePeriod
            let windWaveHeights = data.hourly.windWaveHeight
            let windSpeeds = data.hourly.windSpeed10m
            let windDirections = data.hourly.windDirection10m
            let temperatures = data.hourly.temperature2m
            let apparentTemperatures = data.hourly.apparentTemperature
            let precipitations = data.hourly.precipitation

            let maxCount = max(
                times.count,
                heights.count,
                directions.count,
                periods.count,
                windSpeeds.count,
                temperatures.count
            )

            var mapped: [WeatherHour] = []
            mapped.reserveCapacity(maxCount)

            for i in 0..<maxCount {
                let time = i < times.count ? times[i] : "Hour \(i)"
                let height = value(in: heights, at: i)
                let direction = value(in: directions, at: i)
                let period = value(in: periods, at: i)
                let windWaveHeight = value(in: windWaveHeights, at: i)
                let windSpeed = value(in: windSpeeds, at: i)
                let windDirection = value(in: windDirections, at: i)
                let temperature = value(in: temperatures, at: i)
                let apparentTemperature = value(in: apparentTemperatures, at: i)
                let precipitation = value(in: precipitations, at: i)
                let safety = safetyScore(waveHeight: height, windSpeed: windSpeed)

                mapped.append(
                    WeatherHour(
                        time: formatTime(time),
                        waveHeight: height,
                        waveDirection: direction,
                        wavePeriod: period,
                        windWaveHeight: windWaveHeight,
                        windSpeed: windSpeed,
                        windDirection: windDirection,
                        temperature: temperature,
                        apparentTemperature: apparentTemperature,
                        precipitation: precipitation,
                        safetyScore: safety.score,
                        safetyLabel: safety.label,
                        safetyColor: safety.color
                    )
                )
            }

            guard !mapped.isEmpty else {
                hourlyData = []
                errorMessage = "Weather data not found."
                isLoading = false
                return
            }

            // Rotate list so current hour appears first.
            if let currentIndex = currentHourIndex(in: mapped) {
                hourlyData = Array(mapped[currentIndex...]) + Array(mapped[..<currentIndex])
            } else {
                hourlyData = mapped
            }
        } catch {
            print("Weather error: \(error)")
            hourlyData = []
            errorMessage = "Weather data is unavailable right now."
        }
        isLoading = false
    }

    private func safetyScore(waveHeight: Double, windSpeed: Double) -> (score: Int, label: String, color: Color) {
        let waveRisk = min(max((waveHeight / 2.5) * 100, 0), 100)
        let windRisk = min(max((windSpeed / 40.0) * 100, 0), 100)
        let risk = (waveRisk * 0.65) + (windRisk * 0.35)
        let score = max(0, Int(100 - risk))

        switch score {
        case 81...100: return (score, "Safe", .green)
        case 51...80: return (score, "Caution", .orange)
        default: return (score, "Dangerous", .red)
        }
    }

    private func formatTime(_ isoString: String) -> String {
        let parts = isoString.split(separator: "T")
        return parts.count > 1 ? String(parts[1]) : isoString
    }

    private func currentHourIndex(in data: [WeatherHour]) -> Int? {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return data.firstIndex { hour in
            guard let parsedHour = Int(hour.time.prefix(2)) else { return false }
            return parsedHour == currentHour
        }
    }

    private func value(in array: [Double], at index: Int) -> Double {
        index < array.count ? array[index] : 0
    }
}
