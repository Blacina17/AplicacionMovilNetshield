import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var email: String
    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSuccess = false

    init(prefillEmail: String = "") {
        _email = State(initialValue: prefillEmail)
    }

    var body: some View {
        ZStack {
            NSTheme.navy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(NSTheme.brandYellow, lineWidth: 3)
                                .frame(width: 90, height: 90)
                            Image(systemName: "key.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white, NSTheme.brandYellow)
                        }
                        .padding(.top, 40)

                        Text("Ingresar código")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Ingresa el código de 6 dígitos que aparece en la consola del servidor.")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correo electrónico")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            NSTextField(placeholder: "tucorreo@ejemplo.com",
                                        text: $email,
                                        keyboardType: .emailAddress)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Código de 6 dígitos")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            NSTextField(placeholder: "483921", text: $code)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nueva contraseña")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            NSTextField(placeholder: "••••••••", text: $newPassword, isSecure: true)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmar contraseña")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            NSTextField(placeholder: "••••••••", text: $confirmPassword, isSecure: true)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(NSTheme.dangerRed)
                        }

                        Button(isLoading ? "Actualizando..." : "Restablecer contraseña") {
                            attemptReset()
                        }
                        .buttonStyle(PrimaryButtonStyle(background: NSTheme.navy, foreground: .white))
                        .disabled(isLoading)
                    }
                    .padding(24)
                    .background(NSTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Contraseña actualizada", isPresented: $showSuccess) {
            Button("Ir al login") { dismiss() }
        } message: {
            Text("Ya puedes iniciar sesión con tu nueva contraseña.")
        }
    }

    private func attemptReset() {
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Ingresa un correo electrónico válido."
            return
        }
        guard code.count == 6, code.allSatisfy({ $0.isNumber }) else {
            errorMessage = "El código debe tener 6 dígitos."
            return
        }
        guard newPassword.count >= 8 else {
            errorMessage = "La contraseña debe tener al menos 8 caracteres."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden."
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            let ok = await appState.resetPassword(
                email: email.trimmingCharacters(in: .whitespaces),
                code: code,
                newPassword: newPassword
            )
            isLoading = false
            if ok {
                showSuccess = true
            } else {
                errorMessage = appState.authError ?? "Código inválido o expirado."
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordView(prefillEmail: "test@test.com")
    }
    .environmentObject(AppState())
}
