import SwiftUI

struct AlertasView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: ReportCategory?

    private let filters: [(label: String, category: ReportCategory?)] = [
        ("Todos", nil),
        ("Bancos", .banco),
        ("Compras", .compra),
        ("Escuelas", .escuela),
        ("Red social", .redSocial),
        ("Otros", .otro)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                NSTheme.navy.ignoresSafeArea()

                VStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(filters, id: \.label) { filter in
                                FilterChip(title: filter.label, isSelected: selectedFilter == filter.category) {
                                    selectedFilter = filter.category
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 14) {
                            let filtered = appState.alerts(for: selectedFilter)
                            if filtered.isEmpty {
                                Text("No hay alertas en esta categoría todavía.")
                                    .foregroundColor(NSTheme.textMuted)
                                    .padding(.top, 60)
                            } else {
                                ForEach(filtered) { alert in
                                    AlertDetailCard(alert: alert)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .refreshable { await appState.loadAlerts() }
                }
            }
            .navigationTitle("Alertas")
            .navigationBarTitleDisplayMode(.inline)
            .task { await appState.loadAlerts() }
        }
    }
}

// MARK: - Tarjeta de alerta

struct AlertDetailCard: View {
    @EnvironmentObject var appState: AppState
    let alert: FraudAlert
    @State private var showReport = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header clickeable → lleva al detalle
            NavigationLink {
                AlertDetailView(alert: alert)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    CategoryIcon(category: alert.category, size: 52)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(alert.categoryName)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(alert.category.tintColor.opacity(0.15))
                                .foregroundColor(alert.category.tintColor)
                                .clipShape(Capsule())

                            Text(alert.risk.rawValue)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(alert.risk.color.opacity(0.15))
                                .foregroundColor(alert.risk.color)
                                .clipShape(Capsule())
                        }
                        Text(alert.url.withHttps)
                            .font(.headline)
                            .foregroundColor(.black)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(NSTheme.brandYellow)
                        .padding(.top, 4)
                }
            }
            .buttonStyle(.plain)

            Text(alert.descriptionText)
                .font(.subheadline)
                .foregroundColor(.gray)

            // Botón "Reportar también"
            Button {
                showReport = true
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Reportar también")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(NSTheme.navy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(NSTheme.brandYellow)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .sheet(isPresented: $showReport) {
                NewReportView(prefillURL: alert.url, prefillCategory: alert.category)
            }

            // Footer
            HStack(spacing: 4) {
                Text(alert.verified ? "Aprobado y verificado por el" : "Reportado por la comunidad ·")
                    .foregroundColor(.gray)
                if alert.verified {
                    Text("equipo de NetShield").fontWeight(.semibold)
                } else {
                    Text("en revisión").fontWeight(.semibold)
                }
            }
            .font(.caption)
            .foregroundColor(alert.verified ? NSTheme.safeGreen : NSTheme.warning)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Pantalla antigua (por compatibilidad)

struct AlertDetailScreen: View {
    let alert: FraudAlert

    var body: some View {
        AlertDetailView(alert: alert)
    }
}

#Preview {
    AlertasView().environmentObject(AppState())
}
