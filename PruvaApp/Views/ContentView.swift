import SwiftUI
import UIKit

struct ContentView: View {
    init() {
        let a = UITabBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = UIColor(Color.seaBlue)
        let compactFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        let appearances = [a.stackedLayoutAppearance, a.inlineLayoutAppearance, a.compactInlineLayoutAppearance]
        for itemAppearance in appearances {
            itemAppearance.selected.iconColor = UIColor(Color.oceanAccent)
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color.oceanAccent),
                .font: compactFont
            ]
            itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.4),
                .font: compactFont
            ]
            itemAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)
            itemAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)
        }

        UITabBar.appearance().itemPositioning = .centered
        UITabBar.appearance().itemWidth = 92
        UITabBar.appearance().itemSpacing = 8
        UITabBar.appearance().standardAppearance = a
        UITabBar.appearance().scrollEdgeAppearance = a
    }

    var body: some View {
        TabView {
            MapView().tabItem {
                Label("Map", systemImage: "map.fill")
                    .imageScale(.large)
            }
            BoatTabView().tabItem {
                Label("My Boat", systemImage: "sailboat.fill")
                    .imageScale(.large)
            }
        }
        .tint(.oceanAccent)
    }
}
