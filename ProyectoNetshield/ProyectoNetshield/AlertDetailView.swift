import SwiftUI

struct AlertDetailView: View {
    @EnvironmentObject var appState: AppState
    let alert: FraudAlert

    @State private var detail: AlertDetail?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var showReport = false

    var body: some View {
        ZStack {
            NSTheme.navy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    if isLoading {
                        ProgressView().tint(.white).padding(.top, 40)
                    } else if let detail {
                        descriptionSection(detail)
                        evidenceSection(detail)
                        reportsCountSection(detail)

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
                            .padding(.vertical, 14)
                            .background(NSTheme.brandYellow)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(NSTheme.dangerRed)
                            .padding(.top, 40)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Detalle de alerta")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
        .sheet(isPresented: $showReport) {
            NewReportView(prefillURL: alert.url, prefillCategory: alert.category)
        }
    }

    // MARK: Carga

    private func loadDetail() async {
        isLoading = true
        detail = await appState.loadSiteDetail(id: alert.siteId)
        isLoading = false
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CategoryIcon(category: alert.category, size: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.categoryName)
                        .font(.headline)
                        .foregroundColor(.black)

                    HStack(spacing: 6) {
                        Image(systemName: alert.risk.icon)
                        Text(alert.risk.rawValue)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(alert.verified ? NSTheme.safeGreen : NSTheme.warning)
                }
                Spacer()
            }

            Text(alert.url.withHttps)
                .font(.title3.weight(.semibold))
                .foregroundColor(.black)
                .lineLimit(2)

            HStack(spacing: 6) {
                            Image(systemName: alert.verified ? "checkmark.seal.fill" : "clock.fill")
                            Text(alert.verified ? "Aprobado y verificado por el equipo de NetShield" : "Reportado por la comunidad · en revisión")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(alert.verified ? NSTheme.safeGreen : NSTheme.warning)
        }
        .padding(18)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Descripción

    private func descriptionSection(_ detail: AlertDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Descripción")
                .font(.headline)
                .foregroundColor(.black)
            Text(detail.description)
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Evidencias

    private func evidenceSection(_ detail: AlertDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Evidencias (\(detail.evidence.count))")
                .font(.headline)
                .foregroundColor(.black)

            if detail.evidence.isEmpty {
                Text("Este sitio no tiene evidencias.")
                    .font(.subheadline)
                    .foregroundColor(.black)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(detail.evidence) { ev in
                        AsyncImage(url: URL(string: ev.url, relativeTo: APIConfig.baseURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(NSTheme.accent)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Cantidad de reportes (simplificado)

    private func reportsCountSection(_ detail: AlertDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(NSTheme.brandYellow)
                Text("\(detail.reports.count) reporte\(detail.reports.count == 1 ? "" : "s")")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.black)
                Text("de este sitio")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(NSTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Icono por categoría

struct CategoryIcon: View {
    let category: ReportCategory
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(category.tintColor.opacity(0.25))
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(category.tintColor.opacity(0.4), lineWidth: 1)
                )
            Image(systemName: category.icon)
                .font(.system(size: size * 0.5))
                .foregroundColor(category.tintColor)
        }
    }
}

#Preview {
    NavigationStack {
        AlertDetailView(alert: FraudAlert(
            siteId: 1,
            url: "sitio-sospechoso.com",
            category: .banco,
            risk: .alto,
            descriptionText: "Solicita datos bancarios.",
            timeAgo: "hace 1 hora"
        ))
    }
    .environmentObject(AppState())
}
