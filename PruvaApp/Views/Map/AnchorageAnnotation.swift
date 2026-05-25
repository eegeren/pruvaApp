import SwiftUI

struct AnchorageAnnotation: View {
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            Circle().fill(Color.seaBlueDeep).frame(width: 38, height: 38)
            Circle()
                .stroke(.white, lineWidth: isSelected ? 2 : 0)
                .frame(width: 42, height: 42)
            Image(systemName: "sailboat.fill").foregroundStyle(.white)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
