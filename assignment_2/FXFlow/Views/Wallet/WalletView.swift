import SwiftUI

struct WalletView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @State private var topUpWallet: Wallet? = nil
    @State private var withdrawWallet: Wallet? = nil
    @State private var showAddWallet = false
    @State private var newWalletCurrency: Currency = .usd
    @State private var showConnectBank = false
    @State private var pendingCurrency: Currency? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if walletViewModel.wallets.isEmpty {
                    // Empty state
                    VStack(spacing: 32) {
                        Image(systemName: "wallet.pass")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.purple)
                        
                        VStack(spacing: 16) {
                            Text("No Wallets Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Text("Get started by adding your first wallet to begin exchanging currencies.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To add a wallet:")
                            Text("• Tap the + button in the top right")
                            Text("• Choose your preferred currency")
                            Text("• Connect your bank account")
                            Text("• Start exchanging currencies")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        
                        Spacer()
                        
                        Button(action: { showAddWallet = true }) {
                            Label("Add Your First Wallet", systemImage: "plus.circle.fill")
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
                        }
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
                } else {
                    // Wallets list
                    List {
                        ForEach(walletViewModel.wallets) { wallet in
                            WalletCard(wallet: wallet, onTopUp: { topUpWallet = wallet }, onWithdraw: { withdrawWallet = wallet })
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Wallets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddWallet = true }) {
                        Label("Add Wallet", systemImage: "plus")
                    }
                }
            }
            
            // Shared sheets
            .sheet(item: $topUpWallet) { wallet in
                TopUpWalletView(wallet: wallet) { amount in
                    walletViewModel.updateBalance(for: wallet.id, newBalance: wallet.balance + amount)
                    topUpWallet = nil
                }
            }
            .sheet(item: $withdrawWallet) { wallet in
                WithdrawWalletView(wallet: wallet) { amount in
                    walletViewModel.updateBalance(for: wallet.id, newBalance: wallet.balance - amount)
                    withdrawWallet = nil
                }
            }
            .sheet(isPresented: $showAddWallet) {
                NavigationView {
                    Form {
                        Section(header: Text("Currency")) {
                            Picker("Currency", selection: $newWalletCurrency) {
                                ForEach(Currency.allCases.filter { c in !walletViewModel.wallets.contains(where: { $0.currency == c }) }, id: \.self) { currency in
                                    Text(currency.name).tag(currency)
                                }
                            }
                        }
                        Section {
                            Button("Proceed") {
                                pendingCurrency = newWalletCurrency
                                showAddWallet = false
                                showConnectBank = true
                            }
                            .disabled(walletViewModel.wallets.contains(where: { $0.currency == newWalletCurrency }))
                        }
                    }
                    .navigationTitle("Add Wallet")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAddWallet = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showConnectBank) {
                NavigationView {
                    VStack(spacing: 32) {
                        Image(systemName: "building.columns.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        Text("Connect Bank Account")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("This would take you to a bank connector.")
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Done") {
                            if let currency = pendingCurrency {
                                let newWallet = Wallet(
                                    id: UUID().uuidString,
                                    currency: currency,
                                    balance: 0.0,
                                    transactions: [],
                                    accountNumber: WalletView.generateRandomAccountNumber(for: currency)
                                )
                                walletViewModel.wallets.append(newWallet)
                            }
                            showConnectBank = false
                            pendingCurrency = nil
                        }
                        .font(.headline)
                        .padding()
                    }
                    .padding()
                }
            }
        }
    }
}

extension WalletView {
    static func generateRandomAccountNumber(for currency: Currency) -> String {
        switch currency {
        case .usd: return "US" + String(Int.random(in: 1000000000...9999999999))
        case .eur: return "DE" + String(Int.random(in: 1000000000...9999999999))
        case .gbp: return "GB" + String(Int.random(in: 1000000000...9999999999))
        case .jpy: return "JP" + String(Int.random(in: 1000000000...9999999999))
        case .aud: return "AU" + String(Int.random(in: 1000000000...9999999999))
        case .cad: return "CA" + String(Int.random(in: 1000000000...9999999999))
        case .chf: return "CH" + String(Int.random(in: 1000000000...9999999999))
        case .cny: return "CN" + String(Int.random(in: 1000000000...9999999999))
        case .inr: return "IN" + String(Int.random(in: 1000000000...9999999999))
        case .egp: return "EG" + String(Int.random(in: 1000000000...9999999999))
        }
    }
}

struct WalletCard: View {
    let wallet: Wallet
    var onTopUp: (() -> Void)? = nil
    var onWithdraw: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(wallet.currency.name)
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text(wallet.currency.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(formattedBalance(wallet.balance))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(wallet.accountNumber)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack(spacing: 12) {
                if let onTopUp = onTopUp {
                    Button(action: onTopUp) {
                        Label("Top Up", systemImage: "plus.circle")
                            .font(.body)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
                
                if let onWithdraw = onWithdraw {
                    Button(action: onWithdraw) {
                        Label("Withdraw", systemImage: "minus.circle")
                            .font(.body)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(wallet.balance <= 0)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .listRowInsets(EdgeInsets())
        .padding(.vertical, 8)
    }
}

struct TopUpWalletView: View {
    let wallet: Wallet
    let onTopUp: (Double) -> Void
    
    @State private var amount: String = ""
    @State private var showingError = false
    @State private var isProcessing = false
    @State private var processingStep = 0
    @Environment(\.dismiss) private var dismiss
    
    private let processingSteps = [
        "Connecting to payment system...",
        "Verifying account details...",
        "Processing payment...",
        "Confirming transaction..."
    ]
    
    var body: some View {
        NavigationView {
            if isProcessing {
                VStack(spacing: 32) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    VStack(spacing: 16) {
                        Text(processingSteps[processingStep])
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Please wait while we process your payment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .navigationTitle("Processing Payment")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    simulatePaymentProcess()
                }
            } else {
                Form {
                    Section(header: Text("Current Balance")) {
                        HStack {
                            Text("\(wallet.currency.symbol)\(String(format: "%.2f", wallet.balance))")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text(wallet.currency.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("Top Up Amount")) {
                        HStack {
                            Text(wallet.currency.symbol)
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    Section {
                        Button("Connect to Payment System") {
                            if let topUpAmount = Double(amount), topUpAmount > 0 {
                                isProcessing = true
                            } else {
                                showingError = true
                            }
                        }
                        .disabled(amount.isEmpty || Double(amount) == nil || Double(amount) ?? 0 <= 0)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Payment Process")
                                .font(.headline)
                            Text("• You'll be redirected to your bank's secure payment interface")
                            Text("• Enter your banking credentials to authorize the payment")
                            Text("• Funds will be transferred to your FXFlow wallet")
                            Text("• Transaction completes instantly once authorized")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Top Up \(wallet.currency.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .alert("Invalid Amount", isPresented: $showingError) {
                    Button("OK") { }
                } message: {
                    Text("Please enter a valid amount greater than 0.")
                }
            }
        }
    }
    
    private func simulatePaymentProcess() {
        for step in 0..<processingSteps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 1.5) {
                processingStep = step
                
                if step == processingSteps.count - 1 {
                    // Final step - complete the transaction
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if let topUpAmount = Double(amount) {
                            onTopUp(topUpAmount)
                        }
                    }
                }
            }
        }
    }
}

struct WithdrawWalletView: View {
    let wallet: Wallet
    let onWithdraw: (Double) -> Void
    
    @State private var amount: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var processingStep = 0
    @Environment(\.dismiss) private var dismiss
    
    private let processingSteps = [
        "Initiating withdrawal...",
        "Verifying account details...",
        "Processing transfer...",
        "Confirming withdrawal..."
    ]
    
    private var withdrawAmount: Double? {
        Double(amount)
    }
    
    private var isValidAmount: Bool {
        guard let amount = withdrawAmount else { return false }
        return amount > 0 && amount <= wallet.balance
    }
    
    var body: some View {
        NavigationView {
            if isProcessing {
                VStack(spacing: 32) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    VStack(spacing: 16) {
                        Text(processingSteps[processingStep])
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Please wait while we process your withdrawal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .navigationTitle("Processing Withdrawal")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    simulateWithdrawalProcess()
                }
            } else {
                Form {
                    Section(header: Text("Current Balance")) {
                        HStack {
                            Text("\(wallet.currency.symbol)\(String(format: "%.2f", wallet.balance))")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text(wallet.currency.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section(header: Text("Withdraw Amount")) {
                        HStack {
                            Text(wallet.currency.symbol)
                                .foregroundColor(.secondary)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                        
                        if let withdrawAmount = withdrawAmount, withdrawAmount > wallet.balance {
                            Text("Insufficient funds")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    Section {
                        Button("Process Withdrawal") {
                            if let withdrawAmount = withdrawAmount, withdrawAmount > 0 {
                                if withdrawAmount <= wallet.balance {
                                    isProcessing = true
                                } else {
                                    errorMessage = "Insufficient funds. You can only withdraw up to \(wallet.currency.symbol)\(String(format: "%.2f", wallet.balance))."
                                    showingError = true
                                }
                            } else {
                                errorMessage = "Please enter a valid amount greater than 0."
                                showingError = true
                            }
                        }
                        .disabled(!isValidAmount)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Withdrawal Process")
                                .font(.headline)
                            Text("• Funds will be transferred to your connected bank account")
                            Text("• You'll receive a confirmation email with transaction details")
                            Text("• Standard withdrawal processing time: Instant")
                            Text("• International transfers may take 1-2 business days")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Withdraw \(wallet.currency.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .alert("Invalid Amount", isPresented: $showingError) {
                    Button("OK") { }
                } message: {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func simulateWithdrawalProcess() {
        for step in 0..<processingSteps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 1.5) {
                processingStep = step
                
                if step == processingSteps.count - 1 {
                    // Final step - complete the transaction
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if let withdrawAmount = withdrawAmount {
                            onWithdraw(withdrawAmount)
                        }
                    }
                }
            }
        }
    }
}

struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
            .environmentObject(WalletViewModel.shared)
    }
}

private func formattedBalance(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
} 