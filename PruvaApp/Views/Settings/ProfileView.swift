import SwiftUI
import UIKit

@MainActor
struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var storeService: StoreService
    @Environment(\.dismiss) var dismiss
    @State private var profile: UserProfile? = nil
    @State private var isLoading = true
    @State private var isEditing = false

    @State private var editUsername = ""
    @State private var editFullName = ""
    @State private var editPhone = ""
    @State private var editCountry = ""
    @State private var editAge = ""
    @State private var editBio = ""
    @State private var selectedColor = "#0077B6"
    @State private var saveError: String? = nil
    @State private var isSaving = false

    let avatarColors = [
        "#0077B6", "#00B4D8", "#2EC4B6", "#F4A261",
        "#E63946", "#7B2FBE", "#2D6A4F", "#E9C46A"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "03045E").ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(Color(hex: "00B4D8"))
                        Text("Loading profile...")
                            .foregroundColor(Color(hex: "90E0EF"))
                    }
                } else if let profile {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: selectedColor))
                                        .frame(width: 100, height: 100)
                                        .shadow(color: Color(hex: selectedColor).opacity(0.5), radius: 16)
                                    Text(profile.initials)
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                if isEditing {
                                    HStack(spacing: 10) {
                                        ForEach(avatarColors, id: \.self) { color in
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 28, height: 28)
                                                .overlay(
                                                    Circle()
                                                        .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                                )
                                                .onTapGesture { selectedColor = color }
                                        }
                                    }
                                }

                                VStack(spacing: 4) {
                                    Text(profile.displayName)
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    Text("@\(profile.username)")
                                        .font(.subheadline)
                                        .foregroundColor(Color(hex: "90E0EF"))
                                    Text(profile.memberSince)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                }

                                if storeService.isPremium || profile.isPremium {
                                    HStack(spacing: 6) {
                                        Image(systemName: "crown.fill")
                                        Text("Pruva Pro Member")
                                            .font(.caption.bold())
                                    }
                                    .foregroundColor(Color(hex: "F4A261"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "F4A261").opacity(0.15))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(hex: "F4A261").opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.top, 8)

                            ProfileSection(title: "Personal Info", icon: "person.fill") {
                                if isEditing {
                                    ProfileEditRow(
                                        icon: "person.text.rectangle.fill",
                                        iconColor: Color(hex: "00B4D8"),
                                        label: "Full Name",
                                        text: $editFullName,
                                        placeholder: "Your full name"
                                    )
                                    ProfileDivider()
                                    ProfileEditRow(
                                        icon: "at",
                                        iconColor: Color(hex: "90E0EF"),
                                        label: "Username",
                                        text: $editUsername,
                                        placeholder: "username"
                                    )
                                    ProfileDivider()
                                    ProfileEditRow(
                                        icon: "phone.fill",
                                        iconColor: Color(hex: "2EC4B6"),
                                        label: "Phone",
                                        text: $editPhone,
                                        placeholder: "+1 234 567 8900",
                                        keyboardType: .phonePad
                                    )
                                    ProfileDivider()
                                    ProfileEditRow(
                                        icon: "globe",
                                        iconColor: Color(hex: "F4A261"),
                                        label: "Country",
                                        text: $editCountry,
                                        placeholder: "Your country"
                                    )
                                    ProfileDivider()
                                    ProfileEditRow(
                                        icon: "calendar",
                                        iconColor: .purple,
                                        label: "Age",
                                        text: $editAge,
                                        placeholder: "Your age",
                                        keyboardType: .numberPad
                                    )
                                } else {
                                    ProfileInfoRow(
                                        icon: "person.text.rectangle.fill",
                                        iconColor: Color(hex: "00B4D8"),
                                        label: "Full Name",
                                        value: profile.fullName ?? "Not set"
                                    )
                                    ProfileDivider()
                                    ProfileInfoRow(
                                        icon: "at",
                                        iconColor: Color(hex: "90E0EF"),
                                        label: "Username",
                                        value: "@\(profile.username)"
                                    )
                                    ProfileDivider()
                                    ProfileInfoRow(
                                        icon: "envelope.fill",
                                        iconColor: Color(hex: "0077B6"),
                                        label: "Email",
                                        value: profile.email
                                    )
                                    ProfileDivider()
                                    ProfileInfoRow(
                                        icon: "phone.fill",
                                        iconColor: Color(hex: "2EC4B6"),
                                        label: "Phone",
                                        value: profile.phone ?? "Not set"
                                    )
                                    ProfileDivider()
                                    ProfileInfoRow(
                                        icon: "globe",
                                        iconColor: Color(hex: "F4A261"),
                                        label: "Country",
                                        value: profile.country ?? "Not set"
                                    )
                                    ProfileDivider()
                                    ProfileInfoRow(
                                        icon: "calendar",
                                        iconColor: .purple,
                                        label: "Age",
                                        value: profile.age.map { "\($0)" } ?? "Not set"
                                    )
                                }
                            }
                            .padding(.horizontal, 20)

                            ProfileSection(title: "Bio", icon: "text.quote") {
                                if isEditing {
                                    TextField("Tell other sailors about yourself...", text: $editBio, axis: .vertical)
                                        .foregroundColor(.white)
                                        .tint(Color(hex: "00B4D8"))
                                        .lineLimit(3...6)
                                        .padding(16)
                                } else {
                                    Text(profile.bio ?? "No bio yet")
                                        .foregroundColor(profile.bio != nil ? .white : .white.opacity(0.4))
                                        .font(.subheadline)
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 20)

                            ProfileSection(title: "Activity", icon: "chart.bar.fill") {
                                HStack(spacing: 0) {
                                    ProfileStatCell(value: "0", label: "Voyages")
                                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                                    ProfileStatCell(value: "0", label: "Check-ins")
                                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                                    ProfileStatCell(value: "0", label: "Reviews")
                                }
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal, 20)

                            if let saveError {
                                Text(saveError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }

                            if isEditing {
                                Button {
                                    Task { await save() }
                                } label: {
                                    HStack {
                                        if isSaving {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Save Changes")
                                                .font(.headline)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "0077B6"), Color(hex: "00B4D8")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                                .disabled(isSaving)
                                .padding(.horizontal, 20)
                            }

                            Spacer(minLength: 40)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "F4A261"))
                        Text("Could not load profile").foregroundColor(.white)
                        Button("Try Again") { Task { await loadProfile() } }
                            .foregroundColor(Color(hex: "00B4D8"))
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "00B4D8"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Cancel" : "Edit") {
                        if isEditing {
                            isEditing = false
                            if let p = profile { loadEditFields(from: p) }
                        } else {
                            isEditing = true
                        }
                    }
                    .foregroundColor(Color(hex: "00B4D8"))
                }
            }
        }
        .onAppear {
            Task { await loadProfile() }
        }
    }

    func loadProfile() async {
        isLoading = true
        saveError = nil
        do {
            let p = try await APIService.shared.fetchProfile()
            profile = p
            loadEditFields(from: p)
        } catch {
            print("Profile load error:", error)
            saveError = "Profile could not be loaded."
        }
        isLoading = false
    }

    func loadEditFields(from p: UserProfile) {
        editUsername = p.username
        editFullName = p.fullName ?? ""
        editPhone = p.phone ?? ""
        editCountry = p.country ?? ""
        editAge = p.age.map { "\($0)" } ?? ""
        editBio = p.bio ?? ""
        selectedColor = p.avatarColor ?? "#0077B6"
    }

    func save() async {
        isSaving = true
        saveError = nil

        var params: [String: Any] = [
            "username": editUsername,
            "avatar_color": selectedColor
        ]
        if !editFullName.isEmpty { params["full_name"] = editFullName }
        if !editPhone.isEmpty { params["phone"] = editPhone }
        if !editCountry.isEmpty { params["country"] = editCountry }
        if let age = Int(editAge) { params["age"] = age }
        if !editBio.isEmpty { params["bio"] = editBio }

        do {
            let updated = try await APIService.shared.updateProfile(params)
            profile = updated
            loadEditFields(from: updated)
            isEditing = false
        } catch {
            saveError = "Failed to save. Username may already be taken."
        }

        isSaving = false
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "90E0EF"))
                Text(title.uppercased())
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "90E0EF").opacity(0.7))
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(hex: "023E8A"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "0077B6").opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14))
            }
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color(hex: "90E0EF").opacity(0.8))
                .frame(width: 80, alignment: .leading)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ProfileEditRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14))
            }
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "90E0EF").opacity(0.7))
                .frame(width: 70, alignment: .leading)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .font(.subheadline)
                .tint(Color(hex: "00B4D8"))
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ProfileStatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "90E0EF").opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct ProfileDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 64)
    }
}
