import SwiftUI

extension Color {
    static let seaBlue = Color(hex: "0096C7")
    static let seaBlueMid = Color(hex: "0077B6")
    static let seaBlueDeep = Color(hex: "0077B6")
    static let oceanAccent = Color(hex: "00B4D8")
    static let seafoam = Color(hex: "ADE8F4")

    // Backward-compatible aliases
    static let navyDeep = seaBlue
    static let navyMid = seaBlueMid
    static let navyLight = seaBlueDeep
    static let oceanBlue = oceanAccent
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
