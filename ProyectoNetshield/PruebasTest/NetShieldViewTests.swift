import XCTest
@testable import ProyectoNetshield

// Pruebas unitarias de NetShield: por cada vista, una prueba que debe pasar
// y una prueba "de falla esperada".
//
// Las de falla esperada usan XCTExpectFailure: describen un comportamiento que la app
// todavía NO tiene (limitación conocida). El fallo está previsto, por eso Xcode las marca
// como aprobadas. Si algún día se corrige la app, esa prueba se pondrá en rojo para avisar
// que ya se puede quitar el XCTExpectFailure.

// MARK: - Datos de ayuda

@MainActor
private func nuevoEstado() -> AppState {
    TokenStore.clearAll()          // sin sesión guardada en el Keychain del simulador
    return AppState()
}

private func reporte(_ categoria: ReportCategory = .banco,
                     estado: ReportStatus = .enRevision) -> FraudReport {
    FraudReport(url: "banco-falso.com", category: categoria, description: "Pide datos bancarios", status: estado)
}

private func alerta(_ categoria: ReportCategory) -> FraudAlert {
    FraudAlert(siteId: 1, url: "sitio-\(categoria.rawValue).com", category: categoria, risk: .alto,
               descriptionText: "Reportado por la comunidad", timeAgo: "hace 1 hora")
}

// MARK: - LoginView

@MainActor
final class LoginViewTests: XCTestCase {

    func test_login_datosValidos_noMuestraError() {
        XCTAssertNil(FormValidation.login(email: "ana@correo.com", password: "secreto123"))
    }

    func test_login_correoIncompleto_deberiaRechazarse_FALLA_ESPERADA() {
        XCTExpectFailure("Limitación conocida: solo se valida que el correo tenga '@', así que 'a@' pasa.")
        XCTAssertNotNil(FormValidation.login(email: "a@", password: "secreto123"))
    }
}

// MARK: - RegisterView

@MainActor
final class RegisterViewTests: XCTestCase {

    func test_registro_datosValidos_noMuestraError() {
        let error = FormValidation.register(username: "Ana", email: "ana@correo.com", password: "secreto123",
                                            confirmPassword: "secreto123", country: "México")
        XCTAssertNil(error)
    }

    func test_registro_contrasenaDebil_deberiaRechazarse_FALLA_ESPERADA() {
        XCTExpectFailure("Limitación conocida: solo se pide un mínimo de 8 caracteres; '12345678' se acepta.")
        let error = FormValidation.register(username: "Ana", email: "ana@correo.com", password: "12345678",
                                            confirmPassword: "12345678", country: "México")
        XCTAssertNotNil(error)
    }
}

// MARK: - ForgotPasswordView

@MainActor
final class ForgotPasswordViewTests: XCTestCase {

    func test_recuperar_correoSinArroba_muestraError() {
        XCTAssertEqual(FormValidation.recovery(email: "sin-arroba"), "Ingresa un correo electrónico válido.")
    }

    func test_recuperar_correoValido_deberiaEnviarInstrucciones_FALLA_ESPERADA() {
        XCTExpectFailure("Pendiente: el endpoint de recuperación de contraseña aún no existe en el back.")
        XCTAssertNil(FormValidation.recovery(email: "ana@correo.com"))
    }
}

// MARK: - HomeView

@MainActor
final class HomeViewTests: XCTestCase {

    func test_inicio_contadorDeReportesEnRevision_soloCuentaPendientes() {
        let estado = nuevoEstado()
        estado.reports = [reporte(estado: .enRevision), reporte(estado: .aprobado), reporte(estado: .enRevision)]
        XCTAssertEqual(estado.pendingReportsCount, 2)
    }

    func test_inicio_reporteAprobadoCuentaComoPendiente_FALLA_ESPERADA() {
        XCTExpectFailure("Expectativa incorrecta a propósito: un reporte aprobado ya no está 'en revisión'.")
        let estado = nuevoEstado()
        estado.reports = [reporte(estado: .aprobado)]
        XCTAssertEqual(estado.pendingReportsCount, 1)
    }
}

// MARK: - ConsultarURLView

@MainActor
final class ConsultarURLViewTests: XCTestCase {

    func test_buscar_quitaEspaciosYConvierteElRiesgo() {
        XCTAssertEqual(FormValidation.urlQuery("  banco-falso.com  "), "banco-falso.com")
        XCTAssertEqual(RiskLevel(code: "high"), .alto)
        XCTAssertEqual(RiskLevel(code: "medium"), .medio)
        XCTAssertEqual(RiskLevel(code: "safe"), .seguro)
    }

    func test_buscar_textoQueNoEsUnDominio_deberiaRechazarse_FALLA_ESPERADA() {
        XCTExpectFailure("Limitación conocida: 'hola' se consulta aunque no tenga forma de dominio.")
        XCTAssertNil(FormValidation.urlQuery("hola"))
    }
}

// MARK: - NewReportView

@MainActor
final class NewReportViewTests: XCTestCase {

    func test_nuevoReporte_datosValidos_noMuestraError() {
        let error = FormValidation.newReport(url: "banco-falso.com", description: "Pide mi NIP",
                                             category: .banco, customCategory: "")
        XCTAssertNil(error)
    }

    func test_nuevoReporte_urlSinFormato_deberiaRechazarse_FALLA_ESPERADA() {
        XCTExpectFailure("Limitación conocida: la app solo revisa que la URL no esté vacía, no su formato.")
        let error = FormValidation.newReport(url: "esto no es una url", description: "Pide mi NIP",
                                             category: .banco, customCategory: "")
        XCTAssertNotNil(error)
    }
}

// MARK: - AlertasView

@MainActor
final class AlertasViewTests: XCTestCase {

    func test_alertas_filtroPorCategoria_regresaSoloEsaCategoria() {
        let estado = nuevoEstado()
        estado.alerts = [alerta(.banco), alerta(.compra), alerta(.banco)]
        XCTAssertEqual(estado.alerts(for: .banco).count, 2)
        XCTAssertEqual(estado.alerts(for: nil).count, 3)
    }

    func test_alertas_filtroOtrosIncluyeRedesSociales_FALLA_ESPERADA() {
        XCTExpectFailure("Limitación conocida: 'Red social' es una categoría aparte y no entra en el filtro 'Otros'.")
        let estado = nuevoEstado()
        estado.alerts = [alerta(.redSocial)]
        XCTAssertEqual(estado.alerts(for: .otro).count, 1)
    }
}

// MARK: - MisReportesView

@MainActor
final class MisReportesViewTests: XCTestCase {

    func test_misReportes_reporteNuevoNaceEnRevisionYConNombreDeCategoria() {
        let nuevo = reporte(.escuela)
        XCTAssertEqual(nuevo.status, .enRevision)
        XCTAssertEqual(nuevo.categoryName, "Escuela")
    }

    func test_misReportes_reporteNuevoNaceAprobado_FALLA_ESPERADA() {
        XCTExpectFailure("Expectativa incorrecta a propósito: un reporte nuevo nunca nace aprobado.")
        XCTAssertEqual(reporte().status, .aprobado)
    }
}

// MARK: - PerfilView

@MainActor
final class PerfilViewTests: XCTestCase {

    func test_perfil_cerrarSesion_limpiaLosDatosDelUsuario() {
        let estado = nuevoEstado()
        estado.isLoggedIn = true
        estado.currentUserName = "Ana"
        estado.currentUserEmail = "ana@correo.com"
        estado.reports = [reporte()]

        estado.logout()

        XCTAssertFalse(estado.isLoggedIn)
        XCTAssertEqual(estado.currentUserName, "")
        XCTAssertEqual(estado.currentUserEmail, "")
        XCTAssertTrue(estado.reports.isEmpty)
    }

    func test_perfil_nombreVacioDespuesDeCerrarSesionEsUsuario_FALLA_ESPERADA() {
        XCTExpectFailure("Expectativa incorrecta a propósito: el estado queda vacío; el texto 'Usuario' lo pone la vista.")
        let estado = nuevoEstado()
        estado.currentUserName = "Ana"
        estado.logout()
        XCTAssertEqual(estado.currentUserName, "Usuario")
    }
}

// MARK: - EstadisticasView

@MainActor
final class EstadisticasViewTests: XCTestCase {

    private func estadoConEstadisticas() -> AppState {
        let estado = nuevoEstado()
        estado.stats = StatsDTO(
            summary: .init(sites: 4, reportsThisWeek: 2),
            byCategory: [.init(category: "Bancos", total: 3), .init(category: "Escuela", total: 1)],
            byMonth: [.init(month: "2026-09", category: "Bancos", total: 3)], byCountry: [.init(country: "México", total: 3)],
            countries: ["México"])
        return estado
    }

    func test_estadisticas_totalesPorCategoria_vienenDelBack() {
        let totales = estadoConEstadisticas().totalsByCategory()
        XCTAssertEqual(totales.count, 2)
        XCTAssertEqual(totales.first?.category, "Bancos")
        XCTAssertEqual(totales.first?.count, 3)
    }

    func test_estadisticas_mesSeMuestraSinFormatear_FALLA_ESPERADA() {
        XCTExpectFailure("Expectativa incorrecta a propósito: el mes se convierte a texto legible, no queda como '2026-09'.")
        XCTAssertEqual(estadoConEstadisticas().monthlyStats().first?.month, "2026-09")
    }
}

// MARK: - SettingsView

@MainActor
final class SettingsViewTests: XCTestCase {

    func test_configuracion_contrasenaNuevaValida_noMuestraError() {
        XCTAssertNil(FormValidation.changePassword(current: "actual123", new: "nueva12345"))
        XCTAssertEqual(FormValidation.changePassword(current: "", new: "nueva12345"), "Ingresa tu contraseña actual.")
    }

    func test_configuracion_contrasenaNuevaIgualALaActual_deberiaRechazarse_FALLA_ESPERADA() {
        XCTExpectFailure("Limitación conocida: la app no revisa que la contraseña nueva sea distinta de la actual.")
        XCTAssertNotNil(FormValidation.changePassword(current: "abcd1234", new: "abcd1234"))
    }
}
