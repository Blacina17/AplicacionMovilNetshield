import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("alertasAltoRiesgo") private var alertasAltoRiesgo = true

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordMessage: String?
    @State private var passwordOK = false
    @State private var isSaving = false

    private var canSubmit: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }

    var body: some View {
        ZStack {
            NSTheme.navy.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Toggles
                    VStack(spacing: 0) {
                        Toggle("Notificaciones", isOn: $notificationsEnabled)
                            .padding(16).foregroundColor(.black)
                        Divider()
                        Toggle("Alertas de alto riesgo", isOn: $alertasAltoRiesgo)
                            .padding(16).foregroundColor(.black)
                    }
                    .tint(NSTheme.brandYellow)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Cuenta
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cuenta").font(.caption).foregroundColor(.gray)
                        Text(appState.currentUserEmail).foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Cambiar contraseña
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cambiar contraseña")
                                .font(.headline)
                                .foregroundColor(.black)
                            Text("Ingresa tu contraseña actual y la nueva.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        // Contraseña actual
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contraseña actual")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            NSTextField(placeholder: "Tu contraseña actual",
                                        text: $currentPassword,
                                        isSecure: true)
                        }

                        // Nueva contraseña
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nueva contraseña")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            NSTextField(placeholder: "Mínimo 8 caracteres",
                                        text: $newPassword,
                                        isSecure: true)
                        }

                        // Confirmar nueva contraseña
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirmar nueva contraseña")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            NSTextField(placeholder: "Repite la nueva contraseña",
                                        text: $confirmPassword,
                                        isSecure: true)
                        }

                        // Mensaje de éxito o error
                        if let passwordMessage {
                            HStack(spacing: 6) {
                                Image(systemName: passwordOK ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                Text(passwordMessage)
                            }
                            .font(.footnote)
                            .foregroundColor(passwordOK ? NSTheme.safeGreen : NSTheme.dangerRed)
                        }

                        // Botón
                        Button(isSaving ? "Guardando..." : "Actualizar contraseña") {
                            changePassword()
                        }
                        .buttonStyle(PrimaryButtonStyle(background: NSTheme.navy, foreground: .white))
                        .disabled(isSaving || !canSubmit)
                        .opacity(canSubmit ? 1 : 0.6)
                    }
                    .padding(16)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }
        }
        .navigationTitle("Configuración")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changePassword() {
        guard !currentPassword.isEmpty else {
            passwordOK = false
            passwordMessage = "Ingresa tu contraseña actual."
            return
        }
        guard newPassword.count >= 8 else {
            passwordOK = false
            passwordMessage = "La contraseña nueva debe tener al menos 8 caracteres."
            return
        }
        guard newPassword == confirmPassword else {
            passwordOK = false
            passwordMessage = "Las contraseñas nuevas no coinciden."
            return
        }

        isSaving = true
        passwordMessage = nil

        Task {
            do {
                try await APIClient.shared.changePassword(current: currentPassword, new: newPassword)
                passwordOK = true
                passwordMessage = "Contraseña actualizada correctamente."
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            } catch {
                passwordOK = false
                passwordMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
