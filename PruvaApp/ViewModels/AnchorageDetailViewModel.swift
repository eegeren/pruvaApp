import Foundation
import Combine
import CoreLocation

@MainActor
final class AnchorageDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoadingComments = false
    @Published var newCommentText = ""
    @Published var newCommentDepth: String = ""
    @Published var showAddComment = false
    @Published var isPostingComment = false
    @Published var postErrorMessage: String?
    private let localMarinaCommentsKeyPrefix = "local_marina_comments_"

    func loadComments(anchorageId: String) async {
        isLoadingComments = true
        postErrorMessage = nil
        defer { isLoadingComments = false }
        do {
            comments = try await APIService.shared.fetchComments(anchorageId: anchorageId)
        } catch {
            print("Comments error:", error)
            comments = []
            postErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func postComment(anchorageId: String, authVM: AuthViewModel) async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isPostingComment = true
        postErrorMessage = nil
        defer { isPostingComment = false }
        do {
            let depth = Double(newCommentDepth)
            let comment = try await APIService.shared.postComment(
                anchorageId: anchorageId,
                text: newCommentText,
                depthObserved: depth
            )
            comments.insert(comment, at: 0)
            newCommentText = ""
            newCommentDepth = ""
            showAddComment = false
        } catch {
            print("Post comment error:", error)
            postErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func deleteComment(commentId: String, anchorageId: String) async {
        do {
            try await APIService.shared.deleteComment(anchorageId: anchorageId, commentId: commentId)
            comments.removeAll { $0.id == commentId }
            postErrorMessage = nil
        } catch {
            postErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Map point comments (e.g. marinas)
    func loadMapPointComments(mapPointId: String) async {
        isLoadingComments = true
        postErrorMessage = nil
        defer { isLoadingComments = false }
        do {
            comments = try await APIService.shared.fetchMapPointComments(mapPointId: mapPointId)
        } catch {
            print("Map point comments error:", error)
            comments = []
            postErrorMessage = cleanedCommentError(error)
        }
    }

    func postMapPointComment(mapPointId: String, authVM: AuthViewModel) async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isPostingComment = true
        postErrorMessage = nil
        defer { isPostingComment = false }
        do {
            let depth = Double(newCommentDepth)
            let comment = try await APIService.shared.postMapPointComment(
                mapPointId: mapPointId,
                text: newCommentText,
                depthObserved: depth
            )
            comments.insert(comment, at: 0)
            newCommentText = ""
            newCommentDepth = ""
            showAddComment = false
        } catch {
            print("Post map point comment error:", error)
            postErrorMessage = cleanedCommentError(error)
        }
    }

    func loadMapPointComments(mapPointId: String, fallbackAnchorageId: String?) async {
        isLoadingComments = true
        postErrorMessage = nil
        defer { isLoadingComments = false }
        guard let fallbackAnchorageId else {
            comments = loadLocalMarinaComments(mapPointId: mapPointId)
            postErrorMessage = nil
            return
        }
        do {
            comments = try await APIService.shared.fetchComments(anchorageId: fallbackAnchorageId)
        } catch {
            comments = []
            postErrorMessage = cleanedCommentError(error)
        }
    }

    func postMapPointComment(mapPointId: String, fallbackAnchorageId: String?, authVM: AuthViewModel) async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isPostingComment = true
        postErrorMessage = nil
        defer { isPostingComment = false }

        let depth = Double(newCommentDepth)
        guard let fallbackAnchorageId else {
            let localComment = Comment(
                id: UUID().uuidString,
                anchorageId: nil,
                mapPointId: mapPointId,
                userId: authVM.user?.id ?? "local_user",
                username: authVM.user?.username ?? "You",
                text: newCommentText,
                depthObserved: depth,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            comments.insert(localComment, at: 0)
            persistLocalMarinaComments(comments, mapPointId: mapPointId)
            newCommentText = ""
            newCommentDepth = ""
            showAddComment = false
            return
        }
        do {
            let comment = try await APIService.shared.postComment(
                anchorageId: fallbackAnchorageId,
                text: newCommentText,
                depthObserved: depth
            )
            comments.insert(comment, at: 0)
            newCommentText = ""
            newCommentDepth = ""
            showAddComment = false
        } catch {
            postErrorMessage = cleanedCommentError(error)
        }
    }

    func deleteMapPointComment(commentId: String, mapPointId: String, fallbackAnchorageId: String?) async {
        if let fallbackAnchorageId {
            do {
                try await APIService.shared.deleteComment(anchorageId: fallbackAnchorageId, commentId: commentId)
                comments.removeAll { $0.id == commentId }
                postErrorMessage = nil
            } catch {
                postErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            return
        }

        comments.removeAll { $0.id == commentId }
        persistLocalMarinaComments(comments, mapPointId: mapPointId)
        postErrorMessage = nil
    }

    func resolveAnchorageFallbackId(for mapPoint: MapPoint) async -> String? {
        if let anchorageId = mapPoint.anchorageId, !anchorageId.isEmpty {
            return anchorageId
        }

        let mapLocation = CLLocation(latitude: mapPoint.latitude, longitude: mapPoint.longitude)

        // First try a coordinate-based search window around the marina.
        do {
            let latPad = 0.12
            let lonPad = 0.12
            let nearby = try await APIService.shared.fetchAnchoragesByBounds(
                minLat: mapPoint.latitude - latPad,
                maxLat: mapPoint.latitude + latPad,
                minLon: mapPoint.longitude - lonPad,
                maxLon: mapPoint.longitude + lonPad
            )
            if let nearest = nearestAnchorage(in: nearby, to: mapLocation, maxDistanceMeters: 15000) {
                return nearest.id
            }
        } catch {}

        // Then try a name search fallback.
        do {
            let matches = try await APIService.shared.searchAnchorages(query: mapPoint.name)
            return nearestAnchorage(in: matches, to: mapLocation, maxDistanceMeters: 20000)?.id
        } catch {
            return nil
        }
    }

    private func nearestAnchorage(in anchorages: [Anchorage], to location: CLLocation, maxDistanceMeters: Double) -> Anchorage? {
        let sorted = anchorages.sorted { a, b in
            let da = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: location)
            let db = CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: location)
            return da < db
        }
        guard let best = sorted.first else { return nil }
        let bestDistance = CLLocation(latitude: best.latitude, longitude: best.longitude).distance(from: location)
        return bestDistance <= maxDistanceMeters ? best : nil
    }

    private func cleanedCommentError(_ error: Error) -> String {
        if let apiError = error as? APIService.APIError {
            let body = apiError.body
            if body.contains("<!DOCTYPE html>") || body.contains("<html") {
                return "Comments are not available for this location yet."
            }
            return apiError.errorDescription ?? "Could not post your review."
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private func loadLocalMarinaComments(mapPointId: String) -> [Comment] {
        let key = localMarinaCommentsKeyPrefix + mapPointId
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Comment].self, from: data) else {
            return []
        }
        return decoded
    }

    private func persistLocalMarinaComments(_ comments: [Comment], mapPointId: String) {
        let key = localMarinaCommentsKeyPrefix + mapPointId
        if let data = try? JSONEncoder().encode(comments) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
