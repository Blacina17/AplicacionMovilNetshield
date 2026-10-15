import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var email: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showReset = false
    @State private var showCodeAlert = false

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
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 40))
                                .foregroundStyle(.white, NSTheme.brandYellow)
                        }
                        .padding(.top, 40)

                        Text("Recuperar contraseña")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Ingresa tu correo. El código aparecerá en la consola del servidor (modo desarrollo).")
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

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(NSTheme.dangerRed)
                        }

                        Button(isLoading ? "Enviando..." : "Solicitar código") {
                            attemptRecovery()
                        }
                        .buttonStyle(PrimaryButtonStyle(background: NSTheme.navy, foreground: .white))
                        .disabled(isLoading)

                        HStack {
                            Spacer()
                            Text("¿Ya tienes código?")
                                .foregroundColor(.gray)
                            Button("Ingresar código") { showReset = true }
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .font(.subheadline)
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
        .navigationDestination(isPresented: $showReset) {
            ResetPasswordView(prefillEmail: email)
        }
        .alert("Código solicitado", isPresented: $showCodeAlert) {
            Button("Ingresar código") { showReset = true }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Si el correo existe, se generó un código de 6 dígitos. Míralo en la consola del servidor.")
        }
    }

    private func attemptRecovery() {
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Ingresa un correo electrónico válido."
            return
        }
        errorMessage = nil
        isLoading = true

        Task {
            let ok = await appState.forgotPassword(email: email.trimmingCharacters(in: .whitespaces))
            isLoading = false
            if ok {
                showCodeAlert = true
            } else {
                errorMessage = appState.authError ?? "No se pudo procesar la solicitud."
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
    .environmentObject(AppState())
}
