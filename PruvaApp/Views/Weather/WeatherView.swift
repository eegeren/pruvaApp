import SwiftUI

struct WeatherView: View {
    @EnvironmentObject var mapVM: MapViewModel
    @EnvironmentObject var storeService: StoreService
    @StateObject private var vm = WeatherViewModel()
    @State private var showPaywall = false
    @State private var showRiskOverlay = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(mapVM.anchorages.prefix(20), id: \.id) { a in
                            Button(a.name) {
                                vm.selectedAnchorage = a
                                Task { await vm.loadWeather(lat: a.latitude, lon: a.longitude) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                currentConditionsCard

                if storeService.isPremium {
                    Toggle(isOn: $showRiskOverlay) {
                        Label("Wind / Wave Risk Overlay", systemImage: "aqi.medium")
                            .foregroundStyle(.white)
                    }
                    .tint(.oceanAccent)
                    .padding(12)
                    .background(Color.seaBlueMid)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    riskBreakdownCard
                }

                if let summary = vm.dailySummary {
                    summaryGrid(summary)
                }

                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Hourly Forecast")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if storeService.isPremium {
                        BestAnchorTimeView(data: vm.hourlyData, bestWindow: vm.bestAnchorWindow)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(vm.hourlyData.prefix(168)) { WeatherHourCard(hour: $0) } }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(vm.hourlyData.prefix(24)) { WeatherHourCard(hour: $0) } }
                        }

                        BlurredPremiumGate(
                            icon: "cloud.sun.fill",
                            title: "7-Day Forecast + Risk Analysis",
                            subtitle: "Go Pro for route risk breakdown and advanced overlays",
                            showPaywall: $showPaywall
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color.seaBlue.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(storeService) }
        .task {
            if vm.selectedAnchorage == nil { vm.selectedAnchorage = mapVM.anchorages.first }
            if let a = vm.selectedAnchorage { await vm.loadWeather(lat: a.latitude, lon: a.longitude) }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(vm.selectedAnchorage?.name ?? "Anchorage secin")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            Spacer()
            Button {
                guard let a = vm.selectedAnchorage else { return }
                Task { await vm.loadWeather(lat: a.latitude, lon: a.longitude) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.seaBlueMid)
                    .clipShape(Circle())
            }
            .disabled(vm.isLoading)
        }
    }

    private var currentConditionsCard: some View {
        ZStack {
            WaveAnimationView(waveHeight: vm.currentConditions?.waveHeight ?? 0.6).frame(height: 220)
            if showRiskOverlay && storeService.isPremium, let c = vm.currentConditions {
                LinearGradient(
                    colors: [riskColor(for: c.safetyScore).opacity(0.45), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            if let c = vm.currentConditions {
                VStack(spacing: 12) {
                    Text("Skor: \(c.safetyScore)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        metricChip("Wave", value: "\(String(format: "%.1f", c.waveHeight)) m")
                        metricChip("Periyot", value: "\(String(format: "%.1f", c.wavePeriod)) s")
                        metricChip("Wind", value: "\(Int(c.windSpeed)) kn")
                        metricChip("Temp", value: "\(Int(c.temperature))°C")
                    }
                    if storeService.isPremium {
                        WindCompassView(direction: c.windDirection == 0 ? c.waveDirection : c.windDirection, waveHeight: c.waveHeight)
                    }
                }
            } else {
                ProgressView().tint(.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var riskBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Route Risk Breakdown")
                .font(.headline)
                .foregroundStyle(.white)
            if let c = vm.currentConditions {
                let waveRisk = min(100, c.waveHeight * 35)
                let windRisk = min(100, c.windSpeed * 2.2)
                let rainRisk = min(100, c.precipitation * 18)
                riskRow("Wave", value: waveRisk)
                riskRow("Wind", value: windRisk)
                riskRow("Yagis", value: rainRisk)
                Text("Toplam Risk: \(Int((waveRisk * 0.5) + (windRisk * 0.4) + (rainRisk * 0.1))) / 100")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                Text("Risk verisi bekleniyor...")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color.seaBlueMid)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func riskRow(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("\(Int(value))").font(.caption.bold()).foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(riskColor(for: Int(value))).frame(width: geo.size.width * min(value / 100, 1))
                }
            }
            .frame(height: 8)
        }
    }

    private func riskColor(for score: Int) -> Color {
        switch score {
        case 0..<40: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }

    private func summaryGrid(_ summary: DailyWeatherSummary) -> some View {
        HStack(spacing: 10) {
            summaryCard(title: "Avg Wave", value: "\(String(format: "%.1f", summary.averageWaveHeight)) m", color: .oceanAccent)
            summaryCard(title: "Max", value: "\(String(format: "%.1f", summary.maxWaveHeight)) m", color: .orange)
            summaryCard(title: "Avg Wind", value: "\(Int(summary.averageWindSpeed)) kn", color: .cyan)
            summaryCard(title: "Riskli Saat", value: "\(summary.cautionOrDangerHours)", color: .red)
        }
    }

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.75))
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.seaBlueMid)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.55), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metricChip(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.72))
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}
