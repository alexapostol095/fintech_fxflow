import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var wallets: [Wallet]
    let accountNumber: String
    var kycStatus: KYCStatus
    var amlStatus: AMLStatus
    var personalInfo: PersonalInfo
    var verificationDocuments: [VerificationDocument]
}

// MARK: - KYC Status
enum KYCStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case pending = "Pending Review"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "orange"
        case .pending: return "yellow"
        case .approved: return "green"
        case .rejected: return "red"
        }
    }
}

// MARK: - AML Status
enum AMLStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case pending = "Pending Review"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "orange"
        case .pending: return "yellow"
        case .approved: return "green"
        case .rejected: return "red"
        }
    }
}

// MARK: - Personal Information
struct PersonalInfo: Codable {
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var nationality: String
    var address: Address
    var phoneNumber: String
}

// MARK: - Address
struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var postalCode: String
    var country: String
}

// MARK: - Verification Document
struct VerificationDocument: Codable, Identifiable {
    let id: String
    var type: DocumentType
    var status: DocumentStatus
    var uploadDate: Date?
    var reviewDate: Date?
    var reviewerNotes: String?
}

// MARK: - Document Type
enum DocumentType: String, Codable, CaseIterable {
    case passport = "Passport"
    case nationalId = "National ID"
    case driversLicense = "Driver's License"
    case utilityBill = "Utility Bill"
    case bankStatement = "Bank Statement"
    case proofOfAddress = "Proof of Address"
    case proofOfIncome = "Proof of Income"
    
    var description: String {
        switch self {
        case .passport: return "Valid passport with photo and signature"
        case .nationalId: return "Government-issued national identification"
        case .driversLicense: return "Valid driver's license with photo"
        case .utilityBill: return "Recent utility bill (electricity, water, gas)"
        case .bankStatement: return "Recent bank statement showing address"
        case .proofOfAddress: return "Official document proving your address"
        case .proofOfIncome: return "Employment letter or tax documents"
        }
    }
}

// MARK: - Document Status
enum DocumentStatus: String, Codable, CaseIterable {
    case notUploaded = "Not Uploaded"
    case uploaded = "Uploaded"
    case pending = "Pending Review"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var color: String {
        switch self {
        case .notUploaded: return "gray"
        case .uploaded: return "blue"
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        }
    }
}

// MARK: - Wallet Model
struct Wallet: Identifiable, Codable {
    let id: String
    var currency: Currency
    var balance: Double
    var transactions: [Transaction]
    let accountNumber: String
}

// MARK: - Currency Model
enum Currency: String, CaseIterable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case aud = "AUD"
    case cad = "CAD"
    case chf = "CHF"
    case cny = "CNY"
    case inr = "INR"
    case egp = "EGP"
    
    var code: String { rawValue }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .aud: return "A$"
        case .cad: return "C$"
        case .chf: return "Fr"
        case .cny: return "¥"
        case .inr: return "₹"
        case .egp: return "E£"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .aud: return "Australian Dollar"
        case .cad: return "Canadian Dollar"
        case .chf: return "Swiss Franc"
        case .cny: return "Chinese Yuan"
        case .inr: return "Indian Rupee"
        case .egp: return "Egyptian Pound"
        }
    }
}

// MARK: - Transfer Details
struct TransferDetails: Codable {
    let sourceAccountNumber: String
    let sourceBankName: String
    let sourceBankCountry: String
    let destinationAccountNumber: String
    let destinationBankName: String
    let destinationBankCountry: String
    let transferId: String
    let timestamp: Date
    let estimatedArrival: Date
}

// MARK: - Matched Transaction Info
struct MatchedTransactionInfo: Codable {
    let id: String
    let amount: Double
    let sourceCurrency: Currency
    let targetCurrency: Currency
    let timestamp: Date
    let userRecipient: TransferRecipient
    let peerRecipient: TransferRecipient
    let userTransferDetails: TransferDetails
    let peerTransferDetails: TransferDetails
    let fee: Double
    let netAmount: Double
    let exchangeRate: Double
    let recipientGets: Double
    let isSameCurrency: Bool
}

// MARK: - Transaction Model
struct Transaction: Identifiable, Codable {
    let id: String
    let type: TransactionType
    let amount: Double
    let sourceCurrency: Currency
    let targetCurrency: Currency
    let timestamp: Date
    let status: TransactionStatus
    var matchedTransactionInfo: MatchedTransactionInfo?
}

// MARK: - Transaction Status
enum TransactionStatus: String, Codable {
    case pending
    case completed
    case failed
}

// MARK: - Transaction Type
enum TransactionType: String, Codable {
    case send
    case receive
}

// MARK: - Exchange Request
struct ExchangeRequest: Identifiable {
    let id: String
    let amount: Double
    let sourceCurrency: Currency
    let targetCurrency: Currency
    let timestamp: Date
    var status: TransactionStatus
}

// MARK: - Exchange Request Status
enum ExchangeRequestStatus: String {
    case searching
    case matched
    case completed
    case cancelled
}

enum TransferRequestStatus: String, Codable {
    case pending = "Pending"
    case matched = "Matched"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case failed = "Failed"
}

struct TransferRequest: Identifiable, Codable {
    let id: String
    let userId: String
    var amount: Double
    let sourceCurrency: Currency
    let targetCurrency: Currency
    let timestamp: Date
    var status: TransferRequestStatus
    var matchedRequestId: String?
    var exchangeRate: Double?
    let expiryTime: Date
    
    var isValid: Bool {
        return Date() < expiryTime && status == .pending
    }
}

// Add this to make TransferRecipient Codable
struct TransferRecipient: Codable {
    let name: String
    let accountNumber: String
    let bankName: String?
    let country: String?
    
    init(name: String, accountNumber: String, bankName: String? = nil, country: String? = nil) {
        self.name = name
        self.accountNumber = accountNumber
        self.bankName = bankName
        self.country = country
    }
} 