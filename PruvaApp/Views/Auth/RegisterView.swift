import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var passwordsMatch: Bool { password == confirmPassword }
    var isValid: Bool {
        !email.isEmpty && !username.isEmpty &&
        password.count >= 6 && passwordsMatch
    }

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
                        Text("Create your account")
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

                        CustomTextField(
                            icon: "person.fill",
                            placeholder: "Username",
                            text: $username
                        )

                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Password (min 6 characters)",
                            text: $password
                        )

                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Confirm Password",
                            text: $confirmPassword
                        )

                        if !confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(passwordsMatch ? .green : .red)
                                Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                                    .font(.caption)
                                    .foregroundColor(passwordsMatch ? .green : .red)
                                Spacer()
                            }
                        }
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
                        Task {
                            await authVM.register(
                                email: email,
                                username: username,
                                password: password
                            )
                        }
                    } label: {
                        HStack {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? Color(hex: "0077B6") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!isValid || authVM.isLoading)
                    .padding(.horizontal)

                    Button { dismiss() } label: {
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Sign In")
                                .foregroundColor(Color(hex: "00B4D8"))
                                .bold()
                        }
                        .font(.subheadline)
                    }

                    Text("By creating an account you agree to our Terms of Service and Privacy Policy")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
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
            .onChange(of: authVM.isLoggedIn) { _, loggedIn in
                if loggedIn { dismiss() }
            }
        }
    }
}
