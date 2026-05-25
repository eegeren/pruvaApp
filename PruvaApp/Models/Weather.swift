import Foundation

struct WeatherResponse: Codable {
    let hourly: WeatherHourly
}

struct WeatherHourly: Codable {
    let time: [String]
    let waveHeight: [Double]
    let waveDirection: [Double]
    let wavePeriod: [Double]
    let windWaveHeight: [Double]
    let windSpeed10m: [Double]
    let windDirection10m: [Double]
    let temperature2m: [Double]
    let apparentTemperature: [Double]
    let precipitation: [Double]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexibleCodingKey.self)

        time = Self.decodeArray([String].self, from: container, keys: ["time"]) ?? []
        waveHeight = Self.decodeArray([Double].self, from: container, keys: ["wave_height"]) ?? []
        waveDirection = Self.decodeArray([Double].self, from: container, keys: ["wave_direction"]) ?? []
        wavePeriod = Self.decodeArray([Double].self, from: container, keys: ["wave_period"]) ?? []
        windWaveHeight = Self.decodeArray([Double].self, from: container, keys: ["wind_wave_height"]) ?? []
        windSpeed10m = Self.decodeArray([Double].self, from: container, keys: ["wind_speed_10m", "windspeed_10m"]) ?? []
        windDirection10m = Self.decodeArray([Double].self, from: container, keys: ["wind_direction_10m", "winddirection_10m"]) ?? []
        temperature2m = Self.decodeArray([Double].self, from: container, keys: ["temperature_2m"]) ?? []
        apparentTemperature = Self.decodeArray([Double].self, from: container, keys: ["apparent_temperature"]) ?? []
        precipitation = Self.decodeArray([Double].self, from: container, keys: ["precipitation", "rain"]) ?? []
    }

    private static func decodeArray<T: Decodable>(_ type: T.Type, from container: KeyedDecodingContainer<FlexibleCodingKey>, keys: [String]) -> T? {
        for key in keys {
            if let value = try? container.decodeIfPresent(T.self, forKey: FlexibleCodingKey(stringValue: key)) {
                return value
            }
        }
        return nil
    }
}

struct FlexibleCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}
