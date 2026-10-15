import Foundation

/// Reglas de validación de los formularios de la app, separadas de las vistas para poder probarlas.
/// Cada función regresa el mensaje de error que ve el usuario, o `nil` si los datos son válidos.
enum FormValidation {

    static func login(email: String, password: String) -> String? {
        guard !email.isEmpty, !password.isEmpty else { return "Ingresa tu correo y contraseña." }
        guard email.contains("@") else { return "Ingresa un correo electrónico válido." }
        return nil
    }

    static func register(username: String, email: String, password: String,
                         confirmPassword: String, country: String) -> String? {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty,
              !confirmPassword.isEmpty, !country.isEmpty else { return "Completa todos los campos." }
        guard email.contains("@") else { return "Ingresa un correo electrónico válido." }
        guard password.count >= 8 else { return "La contraseña debe tener al menos 8 caracteres." }
        guard password == confirmPassword else { return "Las contraseñas no coinciden." }
        return nil
    }

    /// Recuperación de contraseña: el endpoint todavía no existe, así que nunca se promete un correo.
    static func recovery(email: String) -> String? {
        guard !email.isEmpty, email.contains("@") else { return "Ingresa un correo electrónico válido." }
        return "Función no disponible por ahora. Contacta al administrador de NetShield."
    }

    static func newReport(url: String, description: String,
                          category: ReportCategory, customCategory: String) -> String? {
        guard !url.trimmingCharacters(in: .whitespaces).isEmpty else { return "Ingresa la URL o sitio sospechoso." }
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return "Describe brevemente qué pasó." }
        let custom = customCategory.trimmingCharacters(in: .whitespaces)
        if category == .otro && !(3...40).contains(custom.count) {
            return "Escribe la categoría (entre 3 y 40 caracteres)."
        }
        return nil
    }

    /// Texto a consultar en "Buscar", sin espacios en los extremos. `nil` si está vacío.
    static func urlQuery(_ raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    static func changePassword(current: String, new: String) -> String? {
        guard !current.isEmpty else { return "Ingresa tu contraseña actual." }
        guard (8...72).contains(new.count) else { return "La contraseña nueva debe tener entre 8 y 72 caracteres." }
        return nil
    }
}
