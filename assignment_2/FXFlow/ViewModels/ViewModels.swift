import SwiftUI
import Combine
import Foundation

// MARK: - Auth ViewModel
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var signupStep: SignupStep = .personalInfo
    @Published var personalInfo = PersonalInfo(
        firstName: "",
        lastName: "",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
        nationality: "",
        address: Address(street: "", city: "", state: "", postalCode: "", country: ""),
        phoneNumber: ""
    )
    
    enum SignupStep: Int, CaseIterable {
        case personalInfo = 0
        case kycDocuments = 1
        case amlVerification = 2
        case review = 3
        case processing = 4
        case completed = 5
    }
    
    func signup(email: String, password: String, name: String) {
        // Create a new user with empty wallets and pending KYC/AML
        let newUser = User(
            id: UUID().uuidString,
            email: email,
            name: name,
            wallets: [], // Start with no wallets
            accountNumber: generateAccountNumber(),
            kycStatus: .inProgress,
            amlStatus: .inProgress,
            personalInfo: personalInfo,
            verificationDocuments: createRequiredDocuments()
        )
        
        currentUser = newUser
        isAuthenticated = true
        
        // Load empty wallets into the shared wallet view model
        WalletViewModel.shared.wallets = []
        WalletViewModel.shared.selectedWallet = nil
    }
    
    private func generateAccountNumber() -> String {
        return "FX" + String(Int.random(in: 100000000...999999999))
    }
    
    private func createRequiredDocuments() -> [VerificationDocument] {
        return [
            VerificationDocument(id: UUID().uuidString, type: .passport, status: .notUploaded),
            VerificationDocument(id: UUID().uuidString, type: .proofOfAddress, status: .notUploaded),
            VerificationDocument(id: UUID().uuidString, type: .proofOfIncome, status: .notUploaded)
        ]
    }
    
    func nextSignupStep() {
        if let currentIndex = SignupStep.allCases.firstIndex(of: signupStep),
           currentIndex < SignupStep.allCases.count - 1 {
            signupStep = SignupStep.allCases[currentIndex + 1]
        }
    }
    
    func previousSignupStep() {
        if let currentIndex = SignupStep.allCases.firstIndex(of: signupStep),
           currentIndex > 0 {
            signupStep = SignupStep.allCases[currentIndex - 1]
        }
    }
    
    func simulateKYCProcessing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.currentUser?.kycStatus = .approved
            self.currentUser?.amlStatus = .approved
            
            // Update document statuses
            for i in 0..<(self.currentUser?.verificationDocuments.count ?? 0) {
                self.currentUser?.verificationDocuments[i].status = .approved
                self.currentUser?.verificationDocuments[i].reviewDate = Date()
            }
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        signupStep = .personalInfo
        personalInfo = PersonalInfo(
            firstName: "",
            lastName: "",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
            nationality: "",
            address: Address(street: "", city: "", state: "", postalCode: "", country: ""),
            phoneNumber: ""
        )
    }
}

// MARK: - Wallet ViewModel
class WalletViewModel: ObservableObject {
    static let shared = WalletViewModel()
    
    @Published var wallets: [Wallet] = []
    @Published var selectedWallet: Wallet?
    
    init() {
        // Start with empty wallets - users will add them during signup
        wallets = []
        selectedWallet = nil
    }
    
    func loadWallets(for user: User) {
        wallets = user.wallets
        selectedWallet = wallets.first
    }
    
    func updateWallet(_ wallet: Wallet) {
        if let index = wallets.firstIndex(where: { $0.id == wallet.id }) {
            wallets[index] = wallet
        }
    }
    
    func updateBalance(for walletId: String, newBalance: Double) {
        if let index = wallets.firstIndex(where: { $0.id == walletId }) {
            wallets[index].balance = newBalance
        }
    }
    
    func addTransaction(_ transaction: Transaction, for currency: Currency) {
        if let index = wallets.firstIndex(where: { $0.currency == currency }) {
            wallets[index].transactions.insert(transaction, at: 0)
            // Subtract the full sourceAmount from the balance
            if transaction.type == .send {
                wallets[index].balance -= transaction.amount
            }
        }
    }
    
    func performInternalExchange(from sourceCurrency: Currency, to targetCurrency: Currency, amount: Double, receivedAmount: Double) {
        guard let sourceWalletIndex = wallets.firstIndex(where: { $0.currency == sourceCurrency }),
              let targetWalletIndex = wallets.firstIndex(where: { $0.currency == targetCurrency }) else {
            print("Error: Could not find source or target wallet for internal exchange.")
            return
        }

        // Create transactions before updating balances in case of failure
        let sendTransaction = Transaction(
            id: UUID().uuidString,
            type: .send,
            amount: amount,
            sourceCurrency: sourceCurrency,
            targetCurrency: targetCurrency, // Destination of the exchange
            timestamp: Date(),
            status: .completed,
            matchedTransactionInfo: nil // Internal exchange, no peer match
        )

        let receiveTransaction = Transaction(
            id: UUID().uuidString,
            type: .receive,
            amount: receivedAmount,
            sourceCurrency: targetCurrency, // The currency of the wallet receiving funds
            targetCurrency: sourceCurrency, // The currency the funds came from
            timestamp: Date(),
            status: .completed,
            matchedTransactionInfo: nil
        )

        // Update balances
        wallets[sourceWalletIndex].balance -= amount
        wallets[targetWalletIndex].balance += receivedAmount

        // Add transactions to wallets
        wallets[sourceWalletIndex].transactions.insert(sendTransaction, at: 0)
        wallets[targetWalletIndex].transactions.insert(receiveTransaction, at: 0)
    }
}

// MARK: - Matching Engine
class MatchingEngine: ObservableObject {
    @Published private(set) var pendingRequests: [TransferRequest] = []
    private var timer: Timer?
    private let queue = DispatchQueue(label: "com.fxflow.matching", qos: .userInitiated)
    
    // Market rates (in a real app, these would come from an external API)
    private let marketRates: [String: Double] = [
        "USD-EUR": 0.87,
        "EUR-USD": 1.0 / 0.87,
        "USD-GBP": 0.74,
        "GBP-USD": 1.0 / 0.74,
        "USD-JPY": 145.89,
        "JPY-USD": 1.0 / 145.89,
        "USD-CAD": 1.37,
        "CAD-USD": 1.0 / 1.37,
        "USD-AUD": 1.54,
        "AUD-USD": 1.0 / 1.54,
        "USD-CHF": 0.82,
        "CHF-USD": 1.0 / 0.82,
        "USD-CNY": 7.19,
        "CNY-USD": 1.0 / 7.19,
        "USD-INR": 86.58,
        "INR-USD": 1.0 / 86.58,
        "USD-EGP": 50.61,
        "EGP-USD": 1.0 / 50.61
    ]
    
    // Fee percentage
    private let feePercentage: Double = 0.01 // 1%
    
    init() {
        // No need for demo requests anymore
    }
    
    func addRequest(_ request: TransferRequest, userRecipient: TransferRecipient) {
        print("[MatchingEngine] addRequest called with sourceCurrency: \(request.sourceCurrency), targetCurrency: \(request.targetCurrency)")
        // Special case: EGP to INR - no match found
        if request.sourceCurrency == .egp && request.targetCurrency == .inr {
            print("[MatchingEngine] EGP to INR detected, triggering no match found.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NotificationCenter.default.post(name: NSNotification.Name("NoP2PMatchFound"), object: nil, userInfo: [
                    "userRequest": request,
                    "userRecipient": userRecipient
                ])
            }
            return
        }
        // --- Partial Match Simulation for EGP ---
        if request.sourceCurrency == .egp {
            print("SIMULATION: EGP transfer detected. Simulating aggregation of multiple smaller matches.")
            
            let totalAmount = request.amount
            let chunkPercentages = [0.4, 0.3, 0.3] // Simulate 3 chunks
            
            for (index, percentage) in chunkPercentages.enumerated() {
                let chunkAmount = totalAmount * percentage
                let isLastChunk = index == chunkPercentages.count - 1
                
                // Process each chunk after a delay to simulate finding multiple matches
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index * 2)) {
                    self.createAndProcessPeerMatch(for: request, userRecipient: userRecipient, amount: chunkAmount, isPartial: !isLastChunk)
                }
            }
        } else {
            // For other currencies, create a single, full match instantly
            createAndProcessPeerMatch(for: request, userRecipient: userRecipient, amount: request.amount, isPartial: false)
        }
    }

    private func createAndProcessPeerMatch(for userRequest: TransferRequest, userRecipient: TransferRecipient, amount: Double, isPartial: Bool) {
        let peerCurrency = userRequest.targetCurrency
        let peerTargetCurrency = userRequest.sourceCurrency
        let peerRecipient = TransferRecipient(
            name: "", // No name for peer recipient
            accountNumber: PeerDataGenerator.randomAccountNumber(),
            bankName: nil,
            country: nil
        )
        let expiry = Date().addingTimeInterval(300)

        let peerRequest = TransferRequest(
            id: UUID().uuidString,
            userId: "peer_" + UUID().uuidString.prefix(6),
            amount: amount,
            sourceCurrency: peerCurrency,
            targetCurrency: peerTargetCurrency,
            timestamp: Date(),
            status: .pending,
            matchedRequestId: nil,
            exchangeRate: nil,
            expiryTime: expiry
        )
        
        // The user's request details should reflect the original, full amount in notifications.
        let originalUserRequest = TransferRequest(
            id: userRequest.id,
            userId: userRequest.userId,
            amount: userRequest.amount, // Always use the original full amount
            sourceCurrency: userRequest.sourceCurrency,
            targetCurrency: userRequest.targetCurrency,
            timestamp: userRequest.timestamp,
            status: .pending,
            matchedRequestId: nil,
            exchangeRate: nil,
            expiryTime: expiry
        )

        queue.async { [weak self] in
            // We don't need to keep track of these simulated requests in a pending list
            // self?.pendingRequests.append(userRequest)
            // self?.pendingRequests.append(peerRequest)
        }

        // Process this specific chunk
        self.processMatch(
            userRequest: originalUserRequest, // Pass the original request with full amount
            userRecipient: userRecipient,
            peerRequest: peerRequest,
            peerRecipient: peerRecipient,
            matchedAmount: amount, // The amount for this specific chunk
            isPartial: isPartial
        )
    }
    
    private func processMatch(userRequest: TransferRequest, userRecipient: TransferRecipient, peerRequest: TransferRequest, peerRecipient: TransferRecipient, matchedAmount: Double, isPartial: Bool) {
        let isSameCurrency = userRequest.sourceCurrency == userRequest.targetCurrency
        let exchangeRate = getExchangeRate(from: userRequest.sourceCurrency, to: userRequest.targetCurrency)
        let fee = isSameCurrency ? 0.0 : 0.01
        let feeAmount = matchedAmount * fee // Calculate fee on the matched amount
        let netAmount = matchedAmount - feeAmount
        let recipientGets = isSameCurrency ? matchedAmount : netAmount * exchangeRate
        
        // Create transfer details for both sides
        let userTransferDetails = TransferDetails(
            sourceAccountNumber: "Your Wallet",
            sourceBankName: "FXFlow",
            sourceBankCountry: "",
            destinationAccountNumber: userRecipient.accountNumber,
            destinationBankName: userRecipient.bankName ?? "",
            destinationBankCountry: userRecipient.country ?? "",
            transferId: "TRF\(Int.random(in: 100000...999999))",
            timestamp: Date(),
            estimatedArrival: Date().addingTimeInterval(86400)
        )
        let peerTransferDetails = TransferDetails(
            sourceAccountNumber: PeerDataGenerator.randomAccountNumber(),
            sourceBankName: peerRecipient.bankName ?? "",
            sourceBankCountry: peerRecipient.country ?? "",
            destinationAccountNumber: peerRecipient.accountNumber,
            destinationBankName: peerRecipient.bankName ?? "",
            destinationBankCountry: peerRecipient.country ?? "",
            transferId: "TRF\(Int.random(in: 100000...999999))",
            timestamp: Date(),
            estimatedArrival: Date().addingTimeInterval(86400)
        )
        
        NotificationCenter.default.post(
            name: NSNotification.Name("TransferRequestMatched"),
            object: nil,
            userInfo: [
                "userRequest": userRequest,
                "userRecipient": userRecipient,
                "peerRequest": peerRequest,
                "peerRecipient": peerRecipient,
                "userTransferDetails": userTransferDetails,
                "peerTransferDetails": peerTransferDetails,
                "matchedAmount": matchedAmount, // Pass the actual matched amount
                "fee": feeAmount,
                "netAmount": netAmount,
                "exchangeRate": exchangeRate,
                "recipientGets": recipientGets,
                "isSameCurrency": isSameCurrency,
                "isPartialMatch": isPartial // Pass the flag
            ]
        )
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func getExchangeRate(from: Currency, to: Currency) -> Double {
        if from == to { return 1.0 }
        let directPair = "\(from.rawValue)-\(to.rawValue)"
        if let direct = marketRates[directPair] {
            return direct
        }
        let usd = Currency.usd
        if from == usd, let usdToTarget = marketRates["USD-\(to.rawValue)"] {
            return usdToTarget
        }
        if to == usd, let usdToFrom = marketRates["USD-\(from.rawValue)"] {
            return 1.0 / usdToFrom
        }
        if let usdToFrom = marketRates["USD-\(from.rawValue)"],
           let usdToTo = marketRates["USD-\(to.rawValue)"] {
            return usdToTo / usdToFrom
        }
        return 1.0
    }
}

// MARK: - Exchange ViewModel
class ExchangeViewModel: ObservableObject {
    enum ExchangeType: String, CaseIterable, Identifiable {
        case send = "Send Money"
        case exchange = "Exchange"
        var id: Self { self }
    }
    
    @Published var exchangeType: ExchangeType = .send
    
    @Published var sourceAmount: Double = 0
    @Published var sourceCurrency: Currency = .usd
    @Published var targetCurrency: Currency = .eur
    @Published var recipientName: String = ""
    @Published var recipientAccount: String = ""
    
    @Published var isProcessing = false
    @Published var processingMessage = ""
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var matchStatusMessage: String? // For showing partial match info
    
    // New properties for aggregated matching
    @Published var isAggregatingMatches = false
    @Published var amountMatchedSoFar: Double = 0
    @Published var totalAmountToMatch: Double = 0
    
    @Published var matchedAmount: Double = 0
    @Published var feeAmount: Double = 0
    @Published var netAmount: Double = 0
    @Published var receivedAmount: Double = 0
    
    private let matchingEngine = MatchingEngine()
    private var cancellables = Set<AnyCancellable>()
    @Published var noP2PMatchFound: Bool = false
    @Published var noP2PMatchMessage: String? = nil
    
    init() {
        setupMatchingNotifications()
        setupNoMatchNotifications()
    }
    
    private func setupMatchingNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("TransferRequestMatched"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo else { return }
                self?.handleMatch(userInfo: userInfo)
            }
            .store(in: &cancellables)
    }
    
    private func setupNoMatchNotifications() {
        NotificationCenter.default.publisher(for: NSNotification.Name("NoP2PMatchFound"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleNoMatch(userInfo: notification.userInfo)
            }
            .store(in: &cancellables)
    }

    private func handleMatch(userInfo: [AnyHashable: Any]) {
        guard let userRequest = userInfo["userRequest"] as? TransferRequest,
              let userRecipient = userInfo["userRecipient"] as? TransferRecipient,
              let peerRecipient = userInfo["peerRecipient"] as? TransferRecipient,
              let userTransferDetails = userInfo["userTransferDetails"] as? TransferDetails,
              let peerTransferDetails = userInfo["peerTransferDetails"] as? TransferDetails,
              let finalMatchedAmount = userInfo["matchedAmount"] as? Double,
              let fee = userInfo["fee"] as? Double,
              let netAmount = userInfo["netAmount"] as? Double,
              let exchangeRate = userInfo["exchangeRate"] as? Double,
              let recipientGets = userInfo["recipientGets"] as? Double,
              let isSameCurrency = userInfo["isSameCurrency"] as? Bool,
              let _ = userInfo["isPartialMatch"] as? Bool else {
            errorMessage = "Failed to process match data."
            isProcessing = false
            return
        }

        if userRequest.sourceCurrency == .egp {
            self.amountMatchedSoFar += finalMatchedAmount
            self.processingMessage = "Matched \(String(format: "%.2f", amountMatchedSoFar)) of \(String(format: "%.2f", totalAmountToMatch)) \(userRequest.sourceCurrency.rawValue)..."
            let allChunksMatched = amountMatchedSoFar >= totalAmountToMatch
            if !allChunksMatched {
                self.matchStatusMessage = "Partial match found! Processing..."
            } else {
                self.matchStatusMessage = "All matches found! Finalizing..."
            }
        } else {
            self.processingMessage = "Match found! Finalizing..."
            self.matchStatusMessage = nil
        }

        let matchedInfo = MatchedTransactionInfo(
            id: UUID().uuidString,
            amount: finalMatchedAmount, // Use the final matched amount
            sourceCurrency: userRequest.sourceCurrency,
            targetCurrency: userRequest.targetCurrency,
            timestamp: Date(),
            userRecipient: userRecipient,
            peerRecipient: peerRecipient,
            userTransferDetails: userTransferDetails,
            peerTransferDetails: peerTransferDetails,
            fee: fee,
            netAmount: netAmount,
            exchangeRate: exchangeRate,
            recipientGets: recipientGets,
            isSameCurrency: isSameCurrency
        )

        let transaction = Transaction(
            id: UUID().uuidString,
            type: .send,
            amount: finalMatchedAmount, // Create transaction for the matched amount
            sourceCurrency: userRequest.sourceCurrency,
            targetCurrency: userRequest.targetCurrency,
            timestamp: Date(),
            status: .completed,
            matchedTransactionInfo: matchedInfo
        )

        // Add transaction to the shared wallet view model
        WalletViewModel.shared.addTransaction(transaction, for: userRequest.sourceCurrency)
        
        // Update UI - these might be for the final receipt view
        if userRequest.sourceCurrency == .egp {
            self.matchedAmount = totalAmountToMatch // Show the total amount on the success screen
            self.feeAmount += fee
            self.netAmount += netAmount
            let allChunksMatched = amountMatchedSoFar >= totalAmountToMatch
            if allChunksMatched {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.isProcessing = false
                    self.isAggregatingMatches = false
                    self.showSuccess = true
                    self.processingMessage = "Transfer complete!"
                }
            }
        } else {
            self.matchedAmount = finalMatchedAmount
            self.feeAmount = fee
            self.netAmount = netAmount
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isProcessing = false
                self.showSuccess = true
            }
        }
    }
    
    private func handleNoMatch(userInfo: [AnyHashable: Any]?) {
        print("[ExchangeViewModel] handleNoMatch called!")
        self.isProcessing = false
        self.isAggregatingMatches = false
        self.noP2PMatchFound = true
        self.noP2PMatchMessage = "No peer-to-peer match found for Egyptian Pound to Indian Rupee.\n\nYou can try again later, or use a traditional transfer system (fees: 5-7%)."
    }
    
    private func getUSDAmount(from amount: Double, currency: Currency) -> Double {
        if currency == .usd {
            return amount
        }
        // Assuming matchingEngine is accessible and has getExchangeRate method
        // This is a simplified conversion. A robust implementation would be more complex.
        let rate = matchingEngine.getExchangeRate(from: currency, to: .usd)
        return amount * rate
    }

    func processTransfer() {
        if exchangeType == .send {
            processP2PTransfer()
        } else {
            processInternalExchange()
        }
    }

    private func processInternalExchange() {
        guard let sourceWallet = WalletViewModel.shared.wallets.first(where: { $0.currency == sourceCurrency }) else {
            errorMessage = "Source wallet not found."
            return
        }
        guard WalletViewModel.shared.wallets.contains(where: { $0.currency == targetCurrency }) else {
            errorMessage = "Target wallet not found."
            return
        }

        let minimumUSDAmount = 5.0
        let sourceAmountInUSD = getUSDAmount(from: sourceAmount, currency: sourceCurrency)

        guard sourceAmountInUSD >= minimumUSDAmount else {
            errorMessage = "The minimum exchange amount is 5 USD (or its equivalent)."
            return
        }

        guard sourceAmount <= sourceWallet.balance else {
            errorMessage = "Insufficient funds in your \(sourceCurrency.name) wallet."
            return
        }

        isProcessing = true
        processingMessage = "Exchanging funds..."
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }

            let exchangeRate = self.matchingEngine.getExchangeRate(from: self.sourceCurrency, to: self.targetCurrency)
            let received = self.sourceAmount * exchangeRate
            
            self.receivedAmount = received
            self.matchedAmount = self.sourceAmount

            WalletViewModel.shared.performInternalExchange(
                from: self.sourceCurrency,
                to: self.targetCurrency,
                amount: self.sourceAmount,
                receivedAmount: received
            )
            
            self.processingMessage = "Exchange successful!"

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isProcessing = false
                self.showSuccess = true
            }
        }
    }
    
    private func processP2PTransfer() {
        // Reset state for new transfer
        feeAmount = 0
        netAmount = 0
        amountMatchedSoFar = 0
        matchedAmount = 0
        
        let minimumUSDAmount = 5.0
        let sourceAmountInUSD = getUSDAmount(from: sourceAmount, currency: sourceCurrency)

        guard sourceAmountInUSD >= minimumUSDAmount else {
            errorMessage = "The minimum transfer amount is 5 USD (or its equivalent in other currencies)."
            return
        }

        guard !recipientName.isEmpty else {
            errorMessage = "Please enter recipient name"
            return
        }
        
        guard !recipientAccount.isEmpty else {
            errorMessage = "Please enter recipient account"
            return
        }
        
        isProcessing = true
        processingMessage = "Finding a match..."
        errorMessage = nil

        // If it's an EGP transfer, set up the aggregation state
        if sourceCurrency == .egp {
            isAggregatingMatches = true
            totalAmountToMatch = sourceAmount
            amountMatchedSoFar = 0
            processingMessage = "Looking for matches for \(String(format: "%.2f", sourceAmount)) EGP..."
        }
        
        // Increased delay to simulate a longer search
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.sourceCurrency == self.targetCurrency {
                // Direct same-currency transfer, no fee, no peer
                self.processSameCurrencyTransfer()
            } else {
                // P2P transfer
                self.findP2PMatch()
            }
        }
    }

    private func processSameCurrencyTransfer() {
        let transferDetails = TransferDetails(
            sourceAccountNumber: "Your Wallet",
            sourceBankName: "FXFlow",
            sourceBankCountry: "",
            destinationAccountNumber: recipientAccount,
            destinationBankName: "",
            destinationBankCountry: "",
            transferId: "TRF\(Int.random(in: 100000...999999))",
            timestamp: Date(),
            estimatedArrival: Date().addingTimeInterval(86400)
        )
        let matchedInfo = MatchedTransactionInfo(
            id: UUID().uuidString,
            amount: sourceAmount,
            sourceCurrency: sourceCurrency,
            targetCurrency: targetCurrency,
            timestamp: Date(),
            userRecipient: TransferRecipient(name: recipientName, accountNumber: recipientAccount),
            peerRecipient: TransferRecipient(name: "", accountNumber: ""),
            userTransferDetails: transferDetails,
            peerTransferDetails: transferDetails,
            fee: 0.0,
            netAmount: sourceAmount,
            exchangeRate: 1.0,
            recipientGets: sourceAmount,
            isSameCurrency: true
        )
        let transaction = Transaction(
            id: UUID().uuidString,
            type: .send,
            amount: sourceAmount,
            sourceCurrency: sourceCurrency,
            targetCurrency: targetCurrency,
            timestamp: Date(),
            status: .completed,
            matchedTransactionInfo: matchedInfo
        )
        WalletViewModel.shared.addTransaction(transaction, for: sourceCurrency)
        self.matchedAmount = sourceAmount
        self.feeAmount = 0.0
        self.netAmount = sourceAmount
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isProcessing = false
            self.showSuccess = true
        }
    }

    private func findP2PMatch() {
        let request = TransferRequest(
            id: UUID().uuidString,
            userId: "current_user",
            amount: sourceAmount,
            sourceCurrency: sourceCurrency,
            targetCurrency: targetCurrency,
            timestamp: Date(),
            status: .pending,
            expiryTime: Date().addingTimeInterval(300)
        )
        
        matchingEngine.addRequest(request, userRecipient: TransferRecipient(
            name: recipientName,
            accountNumber: recipientAccount,
            bankName: "",
            country: ""
        ))
        
        checkForMatch(requestId: request.id)
    }
    
    private func checkForMatch(requestId: String) {
        // This is now part of the initial delay in processTransfer.
        // The actual match is found via notification from MatchingEngine.
        // This function could be used for polling if the engine was more complex.
    }
    
    func resetNoMatchState() {
        noP2PMatchFound = false
        noP2PMatchMessage = nil
    }
}

// MARK: - Transaction History ViewModel
class TransactionHistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    init() {
        // Load demo transactions
        loadDemoTransactions()
    }
    
    func loadDemoTransactions() {
        // Add demo transactions here
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
    }
}

// Helper for random names, banks, and countries
struct PeerDataGenerator {
    static let names = ["Anna Müller", "Jean Dupont", "Luca Rossi", "Sofia García", "Emma Johansson", "Marek Nowak", "Isabella Schmidt", "Lucas Martin"]
    static let usBanks = ["Chase", "Bank of America", "Wells Fargo", "CitiBank"]
    static let euBanks = ["Deutsche Bank", "BNP Paribas", "Santander", "ING", "UniCredit"]
    static let gbBanks = ["Barclays", "HSBC", "Lloyds", "NatWest"]
    static let countries: [Currency: [String]] = [
        .usd: ["United States"],
        .eur: ["Germany", "France", "Spain", "Italy", "Netherlands", "Belgium"],
        .gbp: ["United Kingdom"],
        // Add other currencies if needed
    ]
    
    static func randomName() -> String {
        names.randomElement() ?? "Peer User"
    }
    static func randomAccountNumber() -> String {
        "ACCT" + String(Int.random(in: 10000000...99999999))
    }
    static func randomBank(for currency: Currency) -> String {
        switch currency {
        case .usd: return usBanks.randomElement() ?? "Chase"
        case .eur: return euBanks.randomElement() ?? "Deutsche Bank"
        case .gbp: return gbBanks.randomElement() ?? "Barclays"
        default: return "Unknown Bank" // To make it exhaustive
        }
    }
    static func randomCountry(for currency: Currency) -> String {
        countries[currency]?.randomElement() ?? "Unknown"
    }
}

// Extension to add country property to Bank
extension Bank {
    var country: String {
        switch self {
        case .barclays, .hsbc:
            return "United Kingdom"
        case .deutscheBank:
            return "Germany"
        case .citibank, .jpmorgan:
            return "United States"
        }
    }
}

// MARK: - Advanced Matching Engine (Conceptual)
/// This engine is for demonstration purposes and is not currently used by the app's live flow.
/// It shows how a more complex matching system with a liquidity pool and partial fills would work.
struct MatchResult {
    let successfulMatches: [Transaction]
    let remainingRequest: TransferRequest?
}

class AdvancedMatchingEngine {
    // The "liquidity pool" of all pending transfer requests, keyed by currency pair (e.g., "USD-EUR")
    private var pendingRequests: [String: [TransferRequest]] = [:]
    
    // Function to add a request to the pool
    func addRequestToPool(_ request: TransferRequest) {
        let key = "\(request.sourceCurrency.rawValue)-\(request.targetCurrency.rawValue)"
        if pendingRequests[key] == nil {
            pendingRequests[key] = []
        }
        pendingRequests[key]?.append(request)
        print("✅ Added to Pool (\(key)): \(request.amount) \(request.sourceCurrency.rawValue)")
    }
    
    // The core matching algorithm
    func findMatches(for incomingRequest: TransferRequest) -> MatchResult {
        let oppositeKey = "\(incomingRequest.targetCurrency.rawValue)-\(incomingRequest.sourceCurrency.rawValue)"
        
        guard var availableMatches = pendingRequests[oppositeKey], !availableMatches.isEmpty else {
            // No potential matches found, add the incoming request to its own pool
            addRequestToPool(incomingRequest)
            return MatchResult(successfulMatches: [], remainingRequest: incomingRequest)
        }
        
        print("\n--- New Match Attempt ---")
        print("➡️ Incoming Request: \(incomingRequest.amount) \(incomingRequest.sourceCurrency.rawValue) for \(incomingRequest.targetCurrency.rawValue)")
        print("Looking for matches in pool: \(oppositeKey)")

        // --- Stage 1: Look for a perfect, full match first ---
        if let perfectMatchIndex = availableMatches.firstIndex(where: { $0.amount == incomingRequest.amount }) {
            let peerRequest = availableMatches.remove(at: perfectMatchIndex)
            
            print("✅ Found a perfect 1:1 match with user \(peerRequest.userId) for \(peerRequest.amount) \(peerRequest.sourceCurrency.rawValue).")

            // Create transactions for the perfect match
            let userTransaction = Transaction(id: UUID().uuidString, type: .send, amount: incomingRequest.amount, sourceCurrency: incomingRequest.sourceCurrency, targetCurrency: incomingRequest.targetCurrency, timestamp: Date(), status: .completed, matchedTransactionInfo: nil)
            let peerTransaction = Transaction(id: UUID().uuidString, type: .receive, amount: peerRequest.amount, sourceCurrency: peerRequest.sourceCurrency, targetCurrency: peerRequest.targetCurrency, timestamp: Date(), status: .completed, matchedTransactionInfo: nil)
            
            // Update the pool with the remaining requests
            pendingRequests[oppositeKey] = availableMatches
            
            print("--- Match Attempt End ---")
            print("🎉 Incoming request fully filled by perfect match.\n")

            return MatchResult(successfulMatches: [userTransaction, peerTransaction], remainingRequest: nil)
        }

        // --- Stage 2: If no perfect match, proceed to aggregate partial matches (FIFO) ---
        print("ℹ️ No perfect match found. Attempting to aggregate partial matches...")
        var amountToFill = incomingRequest.amount
        var successfulMatches: [Transaction] = []
        var stillPendingRequests: [TransferRequest] = []

        for peerRequest in availableMatches {
            if amountToFill == 0 {
                stillPendingRequests.append(peerRequest)
                continue
            }

            let matchedAmount = min(amountToFill, peerRequest.amount)
            
            print("  - Found potential match: \(peerRequest.amount) \(peerRequest.sourceCurrency.rawValue) from user \(peerRequest.userId)")

            // Create transactions for both sides of the match
            let userTransaction = Transaction(id: UUID().uuidString, type: .send, amount: matchedAmount, sourceCurrency: incomingRequest.sourceCurrency, targetCurrency: incomingRequest.targetCurrency, timestamp: Date(), status: .completed, matchedTransactionInfo: nil)
            let peerTransaction = Transaction(id: UUID().uuidString, type: .receive, amount: matchedAmount, sourceCurrency: peerRequest.sourceCurrency, targetCurrency: peerRequest.targetCurrency, timestamp: Date(), status: .completed, matchedTransactionInfo: nil)

            successfulMatches.append(userTransaction)
            successfulMatches.append(peerTransaction)

            amountToFill -= matchedAmount
            
            if peerRequest.amount > matchedAmount {
                // The peer request was only partially filled, update it and put it back
                var remainingPeerRequest = peerRequest
                remainingPeerRequest.amount -= matchedAmount
                stillPendingRequests.append(remainingPeerRequest)
                print("    - Matched \(matchedAmount). Peer request has \(remainingPeerRequest.amount) remaining.")
            } else {
                // The peer request was fully filled
                 print("    - Matched \(matchedAmount). Peer request fully filled.")
            }
        }
        
        // Update the pool with the requests that are still pending
        pendingRequests[oppositeKey] = stillPendingRequests
        
        var finalRemainingRequest: TransferRequest? = nil
        if amountToFill > 0 {
            // The incoming request was not fully filled
            var remainingIncomingRequest = incomingRequest
            remainingIncomingRequest.amount = amountToFill
            finalRemainingRequest = remainingIncomingRequest
            addRequestToPool(remainingIncomingRequest)
            print("--- Match Attempt End ---")
            print("⚠️ Incoming request partially filled. \(amountToFill) remaining and added to pool.\n")
        } else {
            print("--- Match Attempt End ---")
            print("🎉 Incoming request fully filled.\n")
        }

        return MatchResult(successfulMatches: successfulMatches, remainingRequest: finalRemainingRequest)
    }
} 