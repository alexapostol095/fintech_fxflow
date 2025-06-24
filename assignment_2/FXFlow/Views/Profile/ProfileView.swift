import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Information")) {
                    DetailRow(title: "Account Number", value: authViewModel.currentUser?.accountNumber ?? "")
                    DetailRow(title: "Email", value: authViewModel.currentUser?.email ?? "")
                    DetailRow(title: "Name", value: authViewModel.currentUser?.name ?? "")
                }
                
                Section(header: Text("Personal Information")) {
                    if let user = authViewModel.currentUser {
                        DetailRow(title: "Full Name", value: "\(user.personalInfo.firstName) \(user.personalInfo.lastName)")
                        DetailRow(title: "Date of Birth", value: user.personalInfo.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                        DetailRow(title: "Nationality", value: user.personalInfo.nationality)
                        DetailRow(title: "Phone", value: user.personalInfo.phoneNumber)
                    }
                }
                
                Section(header: Text("Address")) {
                    if let user = authViewModel.currentUser {
                        DetailRow(title: "Street", value: user.personalInfo.address.street)
                        DetailRow(title: "City", value: user.personalInfo.address.city)
                        DetailRow(title: "State/Province", value: user.personalInfo.address.state)
                        DetailRow(title: "Postal Code", value: user.personalInfo.address.postalCode)
                        DetailRow(title: "Country", value: user.personalInfo.address.country)
                    }
                }
                
                Section(header: Text("Verification Status")) {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Text("KYC Status")
                            Spacer()
                            Text(user.kycStatus.rawValue)
                                .foregroundColor(Color(user.kycStatus.color))
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("AML Status")
                            Spacer()
                            Text(user.amlStatus.rawValue)
                                .foregroundColor(Color(user.amlStatus.color))
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Section(header: Text("Verification Documents")) {
                    if let user = authViewModel.currentUser {
                        ForEach(user.verificationDocuments) { document in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(document.type.rawValue)
                                        .font(.subheadline)
                                    if let uploadDate = document.uploadDate {
                                        Text("Uploaded: \(uploadDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(document.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor(Color(document.status.color))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Logout") {
                        authViewModel.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
} 