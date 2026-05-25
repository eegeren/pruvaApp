import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "sailboat.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "00B4D8"))
                        Text("PRUVA")
                            .font(.system(size: 32, weight: .black))
                            .tracking(6)
                            .foregroundColor(.white)
                        Text("Sign in to your account")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "90E0EF"))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    VStack(spacing: 16) {
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password
                        )
                    }
                    .padding(.horizontal)

                    if let error = authVM.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        Task { await authVM.login(email: email, password: password) }
                    } label: {
                        HStack {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "0077B6"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal)

                    Button {
                        showRegister = true
                    } label: {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Sign Up")
                                .foregroundColor(Color(hex: "00B4D8"))
                                .bold()
                        }
                        .font(.subheadline)
                    }
                }
            }
            .background(Color(hex: "0096C7").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "00B4D8"))
                }
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
                    .environmentObject(authVM)
            }
            .onChange(of: authVM.isLoggedIn) { _, loggedIn in
                if loggedIn { dismiss() }
            }
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "90E0EF"))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(14)
        .background(Color(hex: "0077B6"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "90E0EF"))
                .frame(width: 20)
            if isVisible {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(Color(hex: "90E0EF"))
            }
        }
        .padding(14)
        .background(Color(hex: "0077B6"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
