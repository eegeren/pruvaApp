import SwiftUI

struct AnchorageDetailView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var boatVM: BoatViewModel
    @EnvironmentObject var storeService: StoreService
    @StateObject private var vm = AnchorageDetailViewModel()
    @State private var showCheckinSheet = false

    let anchorage: Anchorage
    var onAddToRoute: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            if anchorage.id.isEmpty || anchorage.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Data not available")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "023E8A"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding()
            } else {
                VStack(spacing: 14) {
                    header
                    quickStats

                    if authVM.isLoggedIn {
                        Button {
                            showCheckinSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Check In Here")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "00B4D8"))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                    }

                    CurrentVisitorsView(anchorageId: anchorage.id)
                    RecentVisitsView(anchorageId: anchorage.id)
                        .environmentObject(storeService)

                    AnchorageWeatherView(anchorage: anchorage)
                    DepthGaugeView(depth: anchorage.depth)
                    approachNotesCard
                    reviewsSection

                    if let onAddToRoute {
                        Button {
                            onAddToRoute()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Route")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "0077B6"))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.seaBlue.opacity(0.03))
        .task {
            guard !anchorage.id.isEmpty else { return }
            await vm.loadComments(anchorageId: anchorage.id)
        }
        .sheet(isPresented: $showCheckinSheet) {
            CheckinView(anchorage: anchorage, authVM: authVM, boatVM: boatVM)
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.seaBlueMid, .oceanAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack {
                Text(anchorage.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "bookmark")
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }

    private var quickStats: some View {
        HStack(spacing: 10) {
            statCard("Depth", anchorage.depth.map { String(format: "%.1fm", $0) } ?? "-")
            statCard("Bottom Type", bottomTypeLabel(anchorage.bottomType))
            statCard("Rating", String(format: "%.1f", anchorage.rating))
            statCard("Reviews", "\(anchorage.ratingCount)")
        }
    }

    private var approachNotesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Approach Notes")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(approachNotes, id: \.text) { note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: note.icon)
                        .foregroundColor(Color(hex: "90E0EF"))
                        .frame(width: 18)
                    Text(note.text)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.subheadline)
                    Spacer()
                }
            }

            Text("Coordinates: \(String(format: "%.4f", anchorage.latitude)), \(String(format: "%.4f", anchorage.longitude))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(hex: "023E8A"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Reviews")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if vm.isLoadingComments {
                    ProgressView().tint(.white)
                }
            }

            if vm.comments.isEmpty && !vm.isLoadingComments {
                Text("No reviews yet")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "023E8A"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(vm.comments) { c in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(c.username ?? "User")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if canDeleteComment(c) {
                                Button(role: .destructive) {
                                    Task { await vm.deleteComment(commentId: c.id, anchorageId: anchorage.id) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                            }
                        }
                        Text(c.text)
                            .foregroundColor(.white)
                        if let observed = c.depthObserved {
                            Text("Observed depth: \(String(format: "%.1f", observed))m")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(hex: "023E8A"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if authVM.isLoggedIn {
                if vm.showAddComment {
                    VStack(spacing: 8) {
                        TextField("Write your review...", text: $vm.newCommentText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        TextField("Depth observed (optional)", text: $vm.newCommentDepth)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button("Cancel") { vm.showAddComment = false }
                                .buttonStyle(.bordered)
                            Spacer()
                            Button(vm.isPostingComment ? "Posting..." : "Submit Review") {
                                Task { await vm.postComment(anchorageId: anchorage.id, authVM: authVM) }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.isPostingComment)
                        }
                    }
                } else {
                    Button("Add Review") { vm.showAddComment = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func statCard(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(hex: "023E8A"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bottomTypeLabel(_ type: String?) -> String {
        switch (type ?? "").lowercased() {
        case "sand": return "Sand"
        case "rock": return "Rock"
        case "mud": return "Mud"
        case "weed": return "Weed"
        default: return "-"
        }
    }

    private var approachNotes: [(icon: String, text: String)] {
        var notes: [(String, String)] = []
        notes.append(("speedometer", "Max recommended speed: 5 knots"))
        notes.append(("dot.radiowaves.left.and.right", "VHF Channel 16 for emergencies"))

        if let depth = anchorage.depth, depth < 3 {
            notes.append(("exclamationmark.triangle.fill", "Shallow — check depth carefully"))
        }
        switch (anchorage.bottomType ?? "").lowercased() {
        case "rock":
            notes.append(("exclamationmark.triangle", "Rocky bottom — anchor carefully"))
        case "mud":
            notes.append(("checkmark.circle", "Mud bottom — good holding"))
        case "sand":
            notes.append(("checkmark.circle", "Sand bottom — good holding"))
        default:
            break
        }
        return notes
    }

    private func canDeleteComment(_ comment: Comment) -> Bool {
        guard authVM.isLoggedIn, let userId = authVM.user?.id else { return false }
        return comment.userId == userId || comment.userId == "local_user"
    }
}
