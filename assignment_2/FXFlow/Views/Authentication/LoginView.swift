import SwiftUI

struct SignupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Title
                VStack(spacing: 10) {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.purple)
                    
                    Text("FXFlow")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("Peer-to-Peer Currency Exchange")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Signup Form
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.oneTimeCode)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.oneTimeCode)
                    
                    Button(action: {
                        if validateForm() {
                            authViewModel.signup(email: email, password: password, name: "New User")
                        }
                    }) {
                        Text("Create Account")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                
                // Info about KYC/AML
                VStack(spacing: 8) {
                    Text("Account Creation Process")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Personal Information Collection")
                        Text("• KYC (Know Your Customer) Verification")
                        Text("• AML (Anti-Money Laundering) Screening")
                        Text("• Document Upload and Review")
                        Text("• Account Activation")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 30)
            }
            .padding()
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .alert("Signup Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func validateForm() -> Bool {
        if email.isEmpty {
            alertMessage = "Please enter your email address"
            showingAlert = true
            return false
        }
        
        if !email.contains("@") {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return false
        }
        
        if password.isEmpty {
            alertMessage = "Please enter a password"
            showingAlert = true
            return false
        }
        
        if password.count < 6 {
            alertMessage = "Password must be at least 6 characters"
            showingAlert = true
            return false
        }
        
        if password != confirmPassword {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return false
        }
        
        return true
    }
}

struct SignupFlowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(authViewModel.signupStep.rawValue), total: Double(AuthViewModel.SignupStep.allCases.count - 1))
                    .padding()
                
                // Step content
                switch authViewModel.signupStep {
                case .personalInfo:
                    PersonalInfoView()
                case .kycDocuments:
                    KYCDocumentsView()
                case .amlVerification:
                    AMLVerificationView()
                case .review:
                    ReviewView()
                case .processing:
                    ProcessingView()
                case .completed:
                    CompletedView()
                }
            }
            .navigationTitle("Account Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PersonalInfoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAgeError = false
    
    private let countries = [
        "Argentina", "Australia", "Austria", "Belgium", "Brazil", "Canada", 
        "Chile", "China", "Denmark", "Finland", "France", "Germany", 
        "Hong Kong", "India", "Ireland", "Italy", "Japan", "Mexico", 
        "Netherlands", "New Zealand", "Norway", "Portugal", "Russia", 
        "Singapore", "South Korea", "Spain", "Sweden", "Switzerland", 
        "United Kingdom", "United States"
    ]
    
    private var isUserOldEnough: Bool {
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: authViewModel.personalInfo.dateOfBirth, to: Date()).year ?? 0
        return age >= 18
    }
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("First Name", text: $authViewModel.personalInfo.firstName)
                TextField("Last Name", text: $authViewModel.personalInfo.lastName)
                DatePicker("Date of Birth", selection: $authViewModel.personalInfo.dateOfBirth, in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!, displayedComponents: .date)
                    .onChange(of: authViewModel.personalInfo.dateOfBirth) { oldValue, newValue in
                        if !isUserOldEnough {
                            showingAgeError = true
                        }
                    }
                Picker("Nationality", selection: $authViewModel.personalInfo.nationality) {
                    Text("Select Nationality").tag("")
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
            }
            
            Section(header: Text("Contact Information")) {
                TextField("Phone Number", text: $authViewModel.personalInfo.phoneNumber)
                    .keyboardType(.phonePad)
            }
            
            Section(header: Text("Address")) {
                TextField("Street Address", text: $authViewModel.personalInfo.address.street)
                TextField("City", text: $authViewModel.personalInfo.address.city)
                TextField("State/Province", text: $authViewModel.personalInfo.address.state)
                TextField("Postal Code", text: $authViewModel.personalInfo.address.postalCode)
                TextField("Country", text: $authViewModel.personalInfo.address.country)
            }
            
            if !isUserOldEnough {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("You must be 18 or older to create an account")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            
            Section {
                Button("Next: KYC Documents") {
                    if isUserOldEnough {
                        authViewModel.nextSignupStep()
                    } else {
                        showingAgeError = true
                    }
                }
                .disabled(authViewModel.personalInfo.firstName.isEmpty || 
                         authViewModel.personalInfo.lastName.isEmpty ||
                         authViewModel.personalInfo.nationality.isEmpty ||
                         !isUserOldEnough)
            }
        }
        .alert("Age Requirement", isPresented: $showingAgeError) {
            Button("OK") { }
        } message: {
            Text("You must be 18 or older to create an account. Please select a valid date of birth.")
        }
    }
}

struct KYCDocumentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingVerificationPopup = false
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "doc.text.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.purple)
            
            Text("KYC Verification Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Text("To comply with financial regulations, we need to verify your identity. This is a standard requirement for all financial services.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Required Documents:")
                Text("• Government-issued ID (Passport, Driver's License)")
                Text("• Proof of Address (Utility Bill, Bank Statement)")
                Text("• Proof of Income (Employment Letter, Tax Documents)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            
            Spacer()
            
            HStack {
                Button("Back") {
                    authViewModel.previousSignupStep()
                }
                .foregroundColor(.purple)
                
                Spacer()
                
                Button("Continue to Verification") {
                    showingVerificationPopup = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("Verification Process", isPresented: $showingVerificationPopup) {
            Button("Proceed") {
                // Simulate document upload and verification
                simulateDocumentUpload()
                authViewModel.nextSignupStep()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll be redirected to our secure verification portal where you can upload your documents. The verification process typically takes 1-2 business days.")
        }
    }
    
    private func simulateDocumentUpload() {
        // Simulate uploading documents
        for i in 0..<(authViewModel.currentUser?.verificationDocuments.count ?? 0) {
            authViewModel.currentUser?.verificationDocuments[i].status = .uploaded
            authViewModel.currentUser?.verificationDocuments[i].uploadDate = Date()
        }
    }
}

struct AMLVerificationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAMLPopup = false
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "shield.checkered")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.teal)
            
            Text("AML Screening")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Text("We conduct automated Anti-Money Laundering checks to ensure compliance with financial regulations and protect our users.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Checks include:")
                Text("• Identity verification")
                Text("• Sanctions screening")
                Text("• Risk assessment")
                Text("• Compliance review")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            
            Spacer()
            
            HStack {
                Button("Back") {
                    authViewModel.previousSignupStep()
                }
                .foregroundColor(.purple)
                
                Spacer()
                
                Button("Continue") {
                    showingAMLPopup = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
            }
            .padding()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("AML Screening", isPresented: $showingAMLPopup) {
            Button("Proceed") {
                authViewModel.nextSignupStep()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("We'll run automated checks on your information. This process is instant and helps ensure the security of our platform.")
        }
    }
}

struct ReviewView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSubmitPopup = false
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("Review Your Information")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Please review your information before submitting:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Personal Information: \(authViewModel.personalInfo.firstName) \(authViewModel.personalInfo.lastName)")
                    Text("• Email: \(authViewModel.currentUser?.email ?? "")")
                    Text("• Nationality: \(authViewModel.personalInfo.nationality)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            
            Spacer()
            
            HStack {
                Button("Back") {
                    authViewModel.previousSignupStep()
                }
                .foregroundColor(.purple)
                
                Spacer()
                
                Button("Submit Application") {
                    showingSubmitPopup = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("Submit Application", isPresented: $showingSubmitPopup) {
            Button("Submit") {
                authViewModel.nextSignupStep()
                authViewModel.simulateKYCProcessing()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your application will be submitted for review. You'll receive an email confirmation once your account is activated.")
        }
    }
}

struct ProcessingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var processingStep = 0
    
    private let processingSteps = [
        "Submitting application...",
        "Conducting KYC verification...",
        "Running AML screening...",
        "Reviewing documents...",
        "Finalizing account setup..."
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            ProgressView()
                .scaleEffect(1.5)
            
            VStack(spacing: 16) {
                Text(processingSteps[processingStep])
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("Please wait while we process your application")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .onAppear {
            simulateProcessing()
        }
    }
    
    private func simulateProcessing() {
        for step in 0..<processingSteps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 2.0) {
                processingStep = step
                
                if step == processingSteps.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        authViewModel.nextSignupStep()
                    }
                }
            }
        }
    }
}

struct CompletedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("Account Created Successfully!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("Your account has been verified and activated. You can now add wallets and start using FXFlow.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("Next Steps:")
                Text("• Add your first wallet")
                Text("• Connect your bank account")
                Text("• Start exchanging currencies")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Get Started") {
                // Complete the signup flow and show the main app
                authViewModel.signupStep = .completed
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
            .environmentObject(AuthViewModel())
    }
} 