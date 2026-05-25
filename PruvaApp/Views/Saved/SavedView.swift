import SwiftUI
import CoreData

struct SavedView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SavedAnchorage.savedAt, ascending: false)]) private var saved: FetchedResults<SavedAnchorage>

    var body: some View {
        NavigationStack {
            Group {
                if saved.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "ferry.fill").font(.largeTitle).foregroundStyle(.white)
                        Text("No saved anchorages").foregroundStyle(.white)
                    }
                } else {
                    List(saved, id: \.objectID) { s in
                        VStack(alignment: .leading) { Text(s.name ?? "-"); Text("\(s.latitude), \(s.longitude)").font(.caption).foregroundStyle(.secondary) }
                    }
                    .scrollContentBackground(.hidden)
                    .listRowBackground(Color.seaBlueMid)
                }
            }
            .background(Color.seaBlue.ignoresSafeArea())
            .navigationTitle("Saved")
        }
    }
}
