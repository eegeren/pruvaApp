import SwiftUI
import MapKit

struct MapPointDetailView: View {
    let mapPoint: MapPoint
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var storeService: StoreService
    @StateObject private var vm = AnchorageDetailViewModel()
    @State private var fallbackAnchorageId: String?
    @State private var detailedMapPoint: MapPoint?
    @State private var pointFacts = MapPointDisplayFacts()
    @State private var linkedAnchorage: Anchorage?
    @State private var isLoadingDetails = false
    @State private var isLoadingGemini = false
    @State private var detailLoadError: String?

    private var enrichesWithGemini: Bool {
        GeminiConfig.enrichableMapPointTypes.contains(displayPoint.type)
    }

    private var displayPoint: MapPoint {
        detailedMapPoint ?? mapPoint
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                infoCard
                if mapPoint.type == "marina" {
                    reviewsSection
                }
                sourceSection
                if displayPoint.phone != nil || displayPoint.website != nil {
                    contactSection
                }
                directionsButton
            }
            .padding()
        }
        .background(Color.seaBlue.opacity(0.05))
        .onAppear {
            if enrichesWithGemini {
                pointFacts = MapPointFactsResolver.basic(mapPoint: mapPoint, comments: [])
            }
        }
        .task(id: mapPoint.id) {
            await reloadMapPointDetails()
        }
        .onChange(of: vm.comments.count) { _, _ in
            Task { await refreshPointFacts() }
        }
    }

    private func reloadMapPointDetails() async {
        if enrichesWithGemini {
            pointFacts = MapPointFactsResolver.basic(mapPoint: mapPoint, comments: vm.comments)
        }

        isLoadingDetails = true
        do {
            detailedMapPoint = try await APIService.shared.fetchMapPoint(id: mapPoint.id)
            detailLoadError = nil
        } catch {
            detailLoadError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingDetails = false

        guard enrichesWithGemini else { return }

        pointFacts = MapPointFactsResolver.basic(mapPoint: displayPoint, comments: vm.comments)

        if displayPoint.type == "marina" {
            fallbackAnchorageId = await vm.resolveAnchorageFallbackId(for: displayPoint)
            if let anchorageId = fallbackAnchorageId {
                linkedAnchorage = try? await APIService.shared.fetchAnchorage(id: anchorageId)
            } else {
                linkedAnchorage = nil
            }
            await vm.loadMapPointComments(
                mapPointId: mapPoint.id,
                fallbackAnchorageId: fallbackAnchorageId
            )
        }

        await refreshPointFacts()
    }

    @MainActor
    private func refreshPointFacts() async {
        guard enrichesWithGemini else { return }
        isLoadingGemini = GeminiConfig.isConfigured
        pointFacts = await MapPointFactsResolver.resolve(
            mapPoint: displayPoint,
            comments: vm.comments,
            linkedAnchorage: linkedAnchorage
        )
        isLoadingGemini = false
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(displayPoint.color).frame(width: 50, height: 50)
                    Image(systemName: displayPoint.icon).foregroundStyle(.white).font(.title3.bold())
                }
                VStack(alignment: .leading) {
                    Text(displayPoint.typeLabel)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(displayPoint.color.opacity(0.2))
                        .clipShape(Capsule())
                    Text(displayPoint.name).font(.title3.bold())
                }
                Spacer()
            }
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { idx in
                    Image(systemName: Double(idx) < displayPoint.rating.rounded() ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
                Text(String(format: "%.1f", displayPoint.rating)).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if displayPoint.type == "marina" {
                marinaOverview
            } else if displayPoint.type == "fuel" {
                fuelOverview
            } else if enrichesWithGemini {
                locationOverview
            } else if let desc = displayPoint.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.92))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var marinaOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            enrichmentStatus

            factRow(icon: "ruler.fill", title: "Entrance Depth", value: pointFacts.entranceDepth)
            factRow(icon: "ferry.fill", title: "Berth Capacity", value: pointFacts.berthCapacity)
            factRow(icon: "dot.radiowaves.left.and.right", title: "VHF Channel", value: pointFacts.vhfChannel)
            factRow(icon: "clock.fill", title: "Opening Hours", value: pointFacts.openingHours, linkURL: websiteLink(for: pointFacts.openingHours))
            if let fuel = pointFacts.fuelTypes {
                factRow(icon: "fuelpump.fill", title: "Fuel at Marina", value: fuel, linkURL: websiteLink(for: fuel))
            }
            if let amenities = pointFacts.amenities {
                factRow(icon: "checkmark.seal.fill", title: "Amenities", value: amenities)
            }
            factRow(icon: "mappin.and.ellipse", title: "Coordinates", value: "\(String(format: "%.5f", displayPoint.latitude)), \(String(format: "%.5f", displayPoint.longitude))")
            factRow(icon: "number", title: "Marina ID", value: displayPoint.id)

            if let summary = pointFacts.summary {
                summaryBlock(summary)
            } else if let desc = displayPoint.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(Color(hex: "023E8A").opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var locationOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            enrichmentStatus

            if displayPoint.type == "diving", pointFacts.entranceDepth != nil {
                factRow(icon: "water.waves", title: "Typical Depth", value: pointFacts.entranceDepth)
            } else if pointFacts.entranceDepth != nil {
                factRow(icon: "ruler.fill", title: "Depth", value: pointFacts.entranceDepth)
            }
            if pointFacts.berthCapacity != nil {
                factRow(icon: "ferry.fill", title: "Capacity", value: pointFacts.berthCapacity)
            }
            if pointFacts.vhfChannel != nil {
                factRow(icon: "dot.radiowaves.left.and.right", title: "VHF Channel", value: pointFacts.vhfChannel)
            }
            factRow(icon: "clock.fill", title: "Opening Hours", value: pointFacts.openingHours, linkURL: websiteLink(for: pointFacts.openingHours))
            if let fuel = pointFacts.fuelTypes {
                factRow(icon: "fuelpump.fill", title: "Fuel", value: fuel, linkURL: websiteLink(for: fuel))
            }
            if let amenities = pointFacts.amenities {
                factRow(icon: "checkmark.seal.fill", title: "Services & Amenities", value: amenities)
            }
            factRow(icon: "mappin.and.ellipse", title: "Coordinates", value: "\(String(format: "%.5f", displayPoint.latitude)), \(String(format: "%.5f", displayPoint.longitude))")
            factRow(icon: "number", title: "Location ID", value: displayPoint.id)

            if let summary = pointFacts.summary {
                summaryBlock(summary)
            } else if let desc = displayPoint.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                summaryBlock(desc)
            }
        }
    }

    private var fuelOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            enrichmentStatus

            factRow(icon: "fuelpump.fill", title: "Fuel Types", value: pointFacts.fuelTypes, linkURL: websiteLink(for: pointFacts.fuelTypes))
            factRow(icon: "clock.fill", title: "Opening Hours", value: pointFacts.openingHours, linkURL: websiteLink(for: pointFacts.openingHours))
            if let amenities = pointFacts.amenities {
                factRow(icon: "checkmark.seal.fill", title: "Services", value: amenities)
            }
            factRow(icon: "mappin.and.ellipse", title: "Coordinates", value: "\(String(format: "%.5f", displayPoint.latitude)), \(String(format: "%.5f", displayPoint.longitude))")
            factRow(icon: "number", title: "Station ID", value: displayPoint.id)

            if let summary = pointFacts.summary {
                summaryBlock(summary)
            }
        }
    }

    @ViewBuilder
    private var enrichmentStatus: some View {
        if isLoadingDetails {
            ProgressView("Loading details...")
                .tint(.white)
                .foregroundColor(.white)
        }
        if isLoadingGemini {
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.85).tint(.white)
                Text("Enriching with Gemini AI...")
                    .font(.caption)
                    .foregroundColor(Color(hex: "90E0EF"))
            }
        }
        if let detailLoadError, !detailLoadError.isEmpty {
            Text("Could not refresh details. Showing last available data.")
                .font(.caption)
                .foregroundColor(.orange.opacity(0.95))
        }
        if !GeminiConfig.isConfigured {
            Text("Add a valid GEMINI_API_KEY (AIza...) in Config/Secrets.xcconfig.")
                .font(.caption2)
                .foregroundColor(.orange.opacity(0.9))
        }
    }

    private func websiteLink(for value: String?) -> URL? {
        guard let value,
              let website = displayPoint.website,
              let url = URL(string: website) else { return nil }
        let linkable = ["See marina website", "See station website", "Listed on marina website"]
        return linkable.contains(value) ? url : nil
    }

    private func summaryBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Overview")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.75))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color(hex: "023E8A").opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func factRow(icon: String, title: String, value: String?, linkURL: URL? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 16)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.68))

            Spacer()

            if let linkURL {
                Link(destination: linkURL) {
                    Text(resolvedFactText(value))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: "90E0EF"))
                        .multilineTextAlignment(.trailing)
                }
            } else {
                Text(resolvedFactText(value))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(10)
        .background(Color(hex: "023E8A").opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func resolvedFactText(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "Not published" }
        return value
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Data Source")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.72))
            VStack(alignment: .leading, spacing: 4) {
                Text("Pruva API, OpenStreetMap, Gemini AI, and community reviews.")
                Text("Map details \(AppVersion.mapPointDetailsRevision) · App \(AppVersion.display)")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "90E0EF").opacity(0.7))
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Reviews", systemImage: "sparkles")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                if vm.isLoadingComments {
                    ProgressView().tint(.white)
                } else {
                    Text("\(vm.comments.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Capsule())
                }
            }

            VStack(spacing: 8) {
                if vm.comments.isEmpty && !vm.isLoadingComments {
                    Text("No reviews yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(hex: "023E8A").opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ForEach(vm.comments.prefix(3)) { c in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(c.username ?? "User")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.76))
                                Spacer()
                                if canDeleteComment(c) {
                                    Button(role: .destructive) {
                                        Task {
                                            await vm.deleteMapPointComment(
                                                commentId: c.id,
                                                mapPointId: mapPoint.id,
                                                fallbackAnchorageId: fallbackAnchorageId
                                            )
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                    }
                                }
                            }
                            Text(c.text)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            if let observed = c.depthObserved {
                                Text("Observed depth: \(String(format: "%.1f", observed))m")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.62))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(hex: "023E8A").opacity(0.62))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            if authVM.isLoggedIn {
                if vm.showAddComment {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Write a review")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.72))

                        TextField("Share your experience...", text: $vm.newCommentText, axis: .vertical)
                            .lineLimit(3...5)
                            .foregroundColor(.white)
                            .tint(.oceanAccent)
                            .padding(12)
                            .background(Color(hex: "023E8A").opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Depth observed (optional)", text: $vm.newCommentDepth)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .tint(.oceanAccent)
                            .padding(12)
                            .background(Color(hex: "023E8A").opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let err = vm.postErrorMessage, !err.isEmpty {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.95))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 10) {
                            Button("Cancel") { vm.showAddComment = false }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button(vm.isPostingComment ? "Posting..." : "Submit Review") {
                                Task {
                                    if fallbackAnchorageId == nil {
                                        fallbackAnchorageId = await vm.resolveAnchorageFallbackId(for: mapPoint)
                                    }
                                    await vm.postMapPointComment(
                                        mapPointId: mapPoint.id,
                                        fallbackAnchorageId: fallbackAnchorageId,
                                        authVM: authVM
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color.oceanAccent, Color(hex: "00D4FF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(vm.isPostingComment || vm.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(vm.isPostingComment || vm.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Button {
                        vm.showAddComment = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Review")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                colors: [Color.oceanAccent, Color(hex: "00D4FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "023E8A").opacity(0.56), Color(hex: "0077B6").opacity(0.32)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contact").font(.headline)
            if let phone = displayPoint.phone, let url = URL(string: "tel://\(phone)") {
                Link(destination: url) { Label(phone, systemImage: "phone.fill") }
            }
            if let website = displayPoint.website, let url = URL(string: website) {
                Link(destination: url) { Label(website, systemImage: "globe") }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var directionsButton: some View {
        Button {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: displayPoint.latitude, longitude: displayPoint.longitude)))
            item.name = displayPoint.name
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } label: {
            Text("Get Directions")
                .frame(maxWidth: .infinity)
                .padding()
                .background(displayPoint.color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func canDeleteComment(_ comment: Comment) -> Bool {
        guard authVM.isLoggedIn, let userId = authVM.user?.id else { return false }
        return comment.userId == userId || comment.userId == "local_user"
    }
}
