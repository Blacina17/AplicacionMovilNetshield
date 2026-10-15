import SwiftUI
import Charts

struct EstadisticasView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false

    private let refreshSeconds: TimeInterval = 15

    // Paleta: azul claro, amarillo, verde, naranja
    private let palette: [Color] = [
        Color(red: 0.38, green: 0.75, blue: 0.98),  // azul claro
        NSTheme.brandYellow,                         // amarillo
        NSTheme.safeGreen,                           // verde
        Color(red: 1.0, green: 0.58, blue: 0.15)     // naranja
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Tarjetas de resumen
                        summaryCards

                        // Reportes por categoría
                        categoryChart

                        // Reportes por país
                        countryChart
                    }
                    .padding(20)
                }
                .refreshable { await loadStats() }

                if isLoading && appState.stats == nil {
                    ProgressView().tint(.white)
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadStats()
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: UInt64(refreshSeconds * 1_000_000_000))
                    if Task.isCancelled { break }
                    await loadStats()
                }
            }
        }
    }

    // MARK: Carga

    private func loadStats() async {
        isLoading = true
        await appState.loadStats(category: nil, country: nil)
        isLoading = false
    }

    // MARK: Totales y porcentajes

    private var totalCategories: Int {
        appState.stats?.byCategory.reduce(0) { $0 + $1.total } ?? 0
    }

    private var totalCountries: Int {
        appState.stats?.byCountry.reduce(0) { $0 + $1.total } ?? 0
    }

    private func percentageCategories(_ count: Int) -> Double {
        guard totalCategories > 0 else { return 0 }
        return (Double(count) / Double(totalCategories)) * 100
    }

    private func percentageCountries(_ count: Int) -> Double {
        guard totalCountries > 0 else { return 0 }
        return (Double(count) / Double(totalCountries)) * 100
    }

    // MARK: Secciones

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                icon: "shield.lefthalf.filled",
                title: "Sitios reportados",
                value: "\(appState.stats?.summary.sites ?? 0)"
            )
            SummaryCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Esta semana",
                value: "\(appState.stats?.summary.reportsThisWeek ?? 0)"
            )
        }
    }

    // MARK: Reportes por categoría

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reportes por categoría")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                if isLoading {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            if let categories = appState.stats?.byCategory, !categories.isEmpty {
                Chart {
                    ForEach(Array(categories.enumerated()), id: \.element.category) { index, item in
                        BarMark(
                            x: .value("Reportes", item.total),
                            y: .value("Categoría", item.category)
                        )
                        .foregroundStyle(palette[index % palette.count])
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text("\(item.total) (\(percentageCategories(item.total), specifier: "%.1f")%)")
                                .font(.caption2.bold())
                                .foregroundColor(.black)
                        }
                    }
                }
                .frame(height: CGFloat(categories.count) * 44 + 30)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.caption2)
                    }
                }

                // Leyenda
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(categories.enumerated()), id: \.element.category) { index, item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(palette[index % palette.count])
                                .frame(width: 10, height: 10)
                            Text(item.category)
                                .font(.caption)
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(item.total) reportes · \(percentageCategories(item.total), specifier: "%.1f")%")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 8)
            } else {
                emptyText
            }
        }
        .padding(18)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Reportes por país

    private var countryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reportes por país")
                .font(.headline)
                .foregroundColor(.black)

            if let countriesData = appState.stats?.byCountry, !countriesData.isEmpty {
                Chart {
                    ForEach(Array(countriesData.enumerated()), id: \.element.country) { index, item in
                        BarMark(
                            x: .value("Reportes", item.total),
                            y: .value("País", item.country)
                        )
                        .foregroundStyle(palette[index % palette.count])
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text("\(item.total) (\(percentageCountries(item.total), specifier: "%.1f")%)")
                                .font(.caption2.bold())
                                .foregroundColor(.black)
                        }
                    }
                }
                .frame(height: CGFloat(countriesData.count) * 44 + 30)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(.caption2)
                    }
                }

                // Leyenda
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(countriesData.enumerated()), id: \.element.country) { index, item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(palette[index % palette.count])
                                .frame(width: 10, height: 10)
                            Text(item.country)
                                .font(.caption)
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(item.total) reportes · \(percentageCountries(item.total), specifier: "%.1f")%")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 8)
            } else {
                emptyText
            }
        }
        .padding(18)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var emptyText: some View {
        Text("Aún no hay reportes aprobados todavía.")
            .font(.subheadline)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 80)
    }
}

// MARK: - Tarjeta de resumen

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(NSTheme.accent)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    EstadisticasView().environmentObject(AppState())
}
