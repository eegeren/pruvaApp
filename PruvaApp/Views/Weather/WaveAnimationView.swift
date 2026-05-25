import SwiftUI

struct WaveAnimationView: View {
    let waveHeight: Double
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                func path(phase: Double, amp: Double) -> Path {
                    var p = Path(); p.move(to: .init(x: 0, y: size.height/2))
                    for x in stride(from: 0, through: size.width, by: 2) {
                        let y = size.height/2 + sin((x/size.width*8)+phase)*amp
                        p.addLine(to: .init(x: x, y: y))
                    }
                    p.addLine(to: .init(x: size.width, y: size.height)); p.addLine(to: .init(x: 0, y: size.height)); p.closeSubpath(); return p
                }
                ctx.fill(path(phase: t, amp: 10 + waveHeight*10), with: .color(.oceanAccent.opacity(0.45)))
                ctx.fill(path(phase: t*1.4, amp: 8 + waveHeight*8), with: .color(.seafoam.opacity(0.35)))
            }
        }
    }
}
