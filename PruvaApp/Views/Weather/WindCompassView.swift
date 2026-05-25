import SwiftUI

struct WindCompassView: View {
    let direction: Double
    let waveHeight: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.6), lineWidth: 2)
            ForEach(["N","NE","E","SE","S","SW","W","NW"], id: \.self) { d in Text(d).font(.caption2).offset(y: -55).rotationEffect(.degrees(Double(idx(d))*45)) }
            Image(systemName: "arrowtriangle.up.fill").rotationEffect(.degrees(direction)).foregroundStyle(.orange)
            Text("\(String(format: "%.1f", waveHeight))m").font(.caption).offset(y: 20)
        }.frame(width: 130, height: 130)
    }
    func idx(_ d: String) -> Int { ["N","NE","E","SE","S","SW","W","NW"].firstIndex(of: d) ?? 0 }
}
