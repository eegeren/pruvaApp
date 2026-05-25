import Foundation

final class APIService {
    static let shared = APIService()
    let baseURL = "https://pruva-backend-production.up.railway.app/api"

    private init() {}

    struct APIError: LocalizedError {
        let statusCode: Int
        let body: String

        var errorDescription: String? {
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "Server error (\(statusCode))." }
            return trimmed
        }
    }

    private func makeRequest(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        if let raw = String(data: data, encoding: .utf8) {
            print("[\(method)] \(path) -> \(raw.prefix(200))")
        }
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw APIError(statusCode: http.statusCode, body: raw)
        }
        return data
    }

    func fetchAnchoragesByBounds(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) async throws -> [Anchorage] {
        let p = "/anchorages?min_lat=\(minLat)&max_lat=\(maxLat)&min_lon=\(minLon)&max_lon=\(maxLon)"
        return try JSONDecoder().decode([Anchorage].self, from: try await makeRequest(p))
    }

    func fetchAnchorage(id: String) async throws -> Anchorage {
        try JSONDecoder().decode(Anchorage.self, from: try await makeRequest("/anchorages/\(id)"))
    }

    func searchAnchorages(query: String) async throws -> [Anchorage] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try JSONDecoder().decode([Anchorage].self, from: try await makeRequest("/anchorages?search=\(q)"))
    }

    func fetchMapPoints(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double, type: String? = nil) async throws -> [MapPoint] {
        var path = "/map-points/bounds?minLat=\(minLat)&maxLat=\(maxLat)&minLon=\(minLon)&maxLon=\(maxLon)"
        if let type {
            path += "&type=\(type)"
        }
        let data = try await makeRequest(path)
        return try JSONDecoder().decode([MapPoint].self, from: data)
    }

    func fetchMapPoint(id: String) async throws -> MapPoint {
        try JSONDecoder().decode(MapPoint.self, from: try await makeRequest("/map-points/\(id)"))
    }

    func fetchComments(anchorageId: String) async throws -> [Comment] {
        try JSONDecoder().decode([Comment].self, from: try await makeRequest("/anchorages/\(anchorageId)/comments"))
    }

    func postComment(anchorageId: String, text: String, depthObserved: Double?) async throws -> Comment {
        var payload: [String: Any] = ["text": text]
        if let depthObserved { payload["depth_observed"] = depthObserved }
        return try JSONDecoder().decode(Comment.self, from: try await makeRequest("/anchorages/\(anchorageId)/comments", method: "POST", body: payload))
    }

    func deleteComment(anchorageId: String, commentId: String) async throws {
        _ = try await makeRequest("/anchorages/\(anchorageId)/comments/\(commentId)", method: "DELETE")
    }

    // MARK: - Map Point Comments (e.g. marinas)
    func fetchMapPointComments(mapPointId: String) async throws -> [Comment] {
        try JSONDecoder().decode([Comment].self, from: try await makeRequest("/map-points/\(mapPointId)/comments"))
    }

    func postMapPointComment(mapPointId: String, text: String, depthObserved: Double?) async throws -> Comment {
        var payload: [String: Any] = ["text": text]
        if let depthObserved { payload["depth_observed"] = depthObserved }
        return try JSONDecoder().decode(Comment.self, from: try await makeRequest("/map-points/\(mapPointId)/comments", method: "POST", body: payload))
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        return try JSONDecoder().decode(AuthResponse.self, from: try await makeRequest("/auth/login", method: "POST", body: body))
    }

    func register(email: String, username: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "username": username, "password": password]
        return try JSONDecoder().decode(AuthResponse.self, from: try await makeRequest("/auth/register", method: "POST", body: body))
    }

    func fetchProfile() async throws -> UserProfile {
        let data = try await makeRequest("/auth/profile")
        if let raw = String(data: data, encoding: .utf8) { print("Profile:", raw) }
        let decoder = JSONDecoder()
        return try decoder.decode(UserProfile.self, from: data)
    }

    func updateProfile(_ params: [String: Any]) async throws -> UserProfile {
        let data = try await makeRequest("/auth/profile", method: "PUT", body: params)
        let decoder = JSONDecoder()
        return try decoder.decode(UserProfile.self, from: data)
    }

    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        let data = try await makeRequest("/weather?lat=\(lat)&lon=\(lon)")
        let decoder = JSONDecoder()
        return try decoder.decode(WeatherResponse.self, from: data)
    }

    func fetchCheckins(anchorageId: String) async throws -> [Checkin] {
        let data = try await makeRequest("/anchorages/\(anchorageId)/checkins")
        return try JSONDecoder().decode([Checkin].self, from: data)
    }

    func fetchCurrentCheckins(anchorageId: String) async throws -> [Checkin] {
        let data = try await makeRequest("/anchorages/\(anchorageId)/checkins/current")
        return try JSONDecoder().decode([Checkin].self, from: data)
    }

    func createCheckin(_ params: [String: Any], anchorageId: String) async throws -> Checkin {
        let data = try await makeRequest(
            "/anchorages/\(anchorageId)/checkins",
            method: "POST",
            body: params
        )
        return try JSONDecoder().decode(Checkin.self, from: data)
    }

    func checkout(checkinId: String, anchorageId: String) async throws {
        _ = try await makeRequest(
            "/anchorages/\(anchorageId)/checkins/\(checkinId)",
            method: "PUT",
            body: ["departed": true]
        )
    }

    func fetchBoats() async throws -> [Boat] { try JSONDecoder().decode([Boat].self, from: try await makeRequest("/boats")) }
    func createBoat(_ params: [String: Any]) async throws -> Boat { try JSONDecoder().decode(Boat.self, from: try await makeRequest("/boats", method: "POST", body: params)) }
    func deleteBoat(boatId: String) async throws { _ = try await makeRequest("/boats/\(boatId)", method: "DELETE") }
    func fetchFuelLogs(boatId: String) async throws -> [FuelLog] { try JSONDecoder().decode([FuelLog].self, from: try await makeRequest("/boats/\(boatId)/fuel-logs")) }
    func createFuelLog(_ params: [String: Any], boatId: String) async throws -> FuelLog { try JSONDecoder().decode(FuelLog.self, from: try await makeRequest("/boats/\(boatId)/fuel-logs", method: "POST", body: params)) }
    func fetchMoorings(boatId: String) async throws -> [Mooring] { try JSONDecoder().decode([Mooring].self, from: try await makeRequest("/boats/\(boatId)/moorings")) }
    func createMooring(_ params: [String: Any], boatId: String) async throws -> Mooring { try JSONDecoder().decode(Mooring.self, from: try await makeRequest("/boats/\(boatId)/moorings", method: "POST", body: params)) }
    func fetchMaintenance(boatId: String) async throws -> [MaintenanceLog] { try JSONDecoder().decode([MaintenanceLog].self, from: try await makeRequest("/boats/\(boatId)/maintenance")) }
    func createMaintenance(_ params: [String: Any], boatId: String) async throws -> MaintenanceLog { try JSONDecoder().decode(MaintenanceLog.self, from: try await makeRequest("/boats/\(boatId)/maintenance", method: "POST", body: params)) }
    func fetchVoyages(boatId: String) async throws -> [VoyageLog] { try JSONDecoder().decode([VoyageLog].self, from: try await makeRequest("/boats/\(boatId)/voyages")) }
    func createVoyage(_ params: [String: Any], boatId: String) async throws -> VoyageLog { try JSONDecoder().decode(VoyageLog.self, from: try await makeRequest("/boats/\(boatId)/voyages", method: "POST", body: params)) }
}
