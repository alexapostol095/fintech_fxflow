import SwiftUI

struct ExchangeView: View {
    @EnvironmentObject var viewModel: ExchangeViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var walletViewModel: WalletViewModel
    @State private var selectedCountry: String = ""
    @State private var showRates = false
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Action", selection: $viewModel.exchangeType.animation()) {
                    ForEach(ExchangeViewModel.ExchangeType.allCases) { type in
                        Text(type.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.exchangeType == .send {
                    SendMoneyView(viewModel: viewModel, walletViewModel: walletViewModel, selectedCountry: $selectedCountry)
                } else {
                    ExchangeWalletsView(viewModel: viewModel, walletViewModel: walletViewModel)
                }
                
                if viewModel.isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                                .padding(.trailing)
                            Text(viewModel.processingMessage)
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Exchange")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showRates = true }) {
                        Image(systemName: "chart.bar")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.exchangeType == .send ? "Send" : "Exchange") {
                        viewModel.processTransfer()
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .sheet(isPresented: $showRates) {
                ExchangeRatesView()
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.exchangeType == .send {
                        Text("Amount: \(viewModel.matchedAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))\nFee: \(viewModel.feeAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))\nNet Amount: \(viewModel.netAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))")
                        
                        if let statusMessage = viewModel.matchStatusMessage {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        
                    } else {
                        Text("You exchanged \(viewModel.matchedAmount, specifier: "%.2f") \(viewModel.sourceCurrency.rawValue) for \(viewModel.receivedAmount, specifier: "%.2f") \(viewModel.targetCurrency.rawValue).")
                    }
                }
            }
            .alert("No P2P Match Found", isPresented: $viewModel.noP2PMatchFound) {
                Button("Try Again Later") {
                    viewModel.resetNoMatchState()
                }
                Button("Use Traditional Transfer") {
                    viewModel.resetNoMatchState()
                    dismiss()
                }
            } message: {
                Text(viewModel.noP2PMatchMessage ?? "No peer-to-peer match found for Egyptian Pound to Indian Rupee.\n\nYou can try again later, or use a traditional transfer system (fees: 5-7%).")
            }
        }
    }
}

// MARK: - Subviews for Exchange and Send
private struct SendMoneyView: View {
    @ObservedObject var viewModel: ExchangeViewModel
    @ObservedObject var walletViewModel: WalletViewModel
    @Binding var selectedCountry: String

    private let countryToCurrency: [String: Currency] = Currency.allCases.reduce(into: [:]) { result, currency in
        result[currency.name.replacingOccurrences(of: " Dollar", with: "").replacingOccurrences(of: " Pound", with: "").replacingOccurrences(of: " Rupee", with: "")] = currency
    }

    private var sortedCountries: [String] {
        countryToCurrency.keys.sorted()
    }

    var body: some View {
        Group {
            Section(header: Text("Recipient Details")) {
                TextField("Recipient Name", text: $viewModel.recipientName)
                TextField("Account Number", text: $viewModel.recipientAccount)
            }
            
            Section(header: Text("Transfer Details")) {
                TextField("Amount", value: $viewModel.sourceAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))
                    .keyboardType(.decimalPad)
                
                Picker("From", selection: $viewModel.sourceCurrency) {
                    ForEach(walletViewModel.wallets.map { $0.currency }, id: \.self) { currency in
                        Text(currency.name).tag(currency)
                    }
                }
                
                Picker("Recipient Country", selection: $selectedCountry) {
                    ForEach(sortedCountries, id: \.self) { country in
                        if let currency = countryToCurrency[country] {
                            Text("\(country) (\(currency.name))").tag(country)
                        }
                    }
                }
                .onChange(of: selectedCountry) {
                    if let currency = countryToCurrency[selectedCountry] {
                        viewModel.targetCurrency = currency
                    }
                }
            }
        }
    }
}

private struct ExchangeWalletsView: View {
    @ObservedObject var viewModel: ExchangeViewModel
    @ObservedObject var walletViewModel: WalletViewModel

    var body: some View {
        Group {
            Section(header: Text("Exchange Details")) {
                TextField("Amount to Exchange", value: $viewModel.sourceAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))
                    .keyboardType(.decimalPad)

                Picker("From Wallet", selection: $viewModel.sourceCurrency) {
                    ForEach(walletViewModel.wallets, id: \.currency) { wallet in
                        Text("\(wallet.currency.name) (\(wallet.balance, specifier: "%.2f"))").tag(wallet.currency)
                    }
                }

                Picker("To Wallet", selection: $viewModel.targetCurrency) {
                    ForEach(walletViewModel.wallets.filter { $0.currency != viewModel.sourceCurrency }, id: \.currency) { wallet in
                        Text(wallet.currency.name).tag(wallet.currency)
                    }
                }
            }
        }
        .onChange(of: viewModel.sourceCurrency) { newSource in
            let availableTargets = walletViewModel.wallets
                .map { $0.currency }
                .filter { $0 != newSource }
            if !availableTargets.contains(viewModel.targetCurrency), let first = availableTargets.first {
                viewModel.targetCurrency = first
            }
        }
    }
}

enum Bank: String, CaseIterable {
    case barclays = "Barclays"
    case deutscheBank = "Deutsche Bank"
    case hsbc = "HSBC"
    case citibank = "Citibank"
    case jpmorgan = "JPMorgan Chase"
    
    var name: String { rawValue }
}

struct ExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeView()
    }
}

// MARK: - Exchange Rates View
import Foundation

struct ExchangeRatesView: View {
    // For demo, we use the same rates as MatchingEngine
    private let rates: [String: Double] = [
        "USD-EUR": 0.87,
        "USD-GBP": 0.74,
        "USD-JPY": 145.89,
        "USD-CAD": 1.37,
        "USD-AUD": 1.54,
        "USD-CHF": 0.82,
        "USD-CNY": 7.19,
        "USD-INR": 86.58,
        "USD-EGP": 50.61
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(rates.sorted(by: { $0.key < $1.key }), id: \ .key) { pair, rate in
                    HStack {
                        Text(pair.replacingOccurrences(of: "-", with: " → "))
                            .font(.body)
                        Spacer()
                        Text(String(format: "%.4f", rate))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Exchange Rates")
        }
    }
}

struct ExchangeRatesView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeRatesView()
    }
} 