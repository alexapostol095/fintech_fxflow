import SwiftUI

struct TransferView: View {
    @EnvironmentObject var viewModel: ExchangeViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var walletViewModel: WalletViewModel
    @State private var selectedCountry: String = ""
    
    // Supported regions/countries
    let euRegion = ["European Union"]
    let gbCountries = ["United Kingdom"]
    let usCountries = ["United States"]
    let jpCountries = ["Japan"]
    let caCountries = ["Canada"]
    let auCountries = ["Australia"]
    let chCountries = ["Switzerland"]
    let cnCountries = ["China"]
    let inCountries = ["India"]
    let egCountries = ["Egypt"]
    let countryToCurrency: [String: Currency] = [
        "European Union": .eur,
        "United Kingdom": .gbp,
        "United States": .usd,
        "Japan": .jpy,
        "Canada": .cad,
        "Australia": .aud,
        "Switzerland": .chf,
        "China": .cny,
        "India": .inr,
        "Egypt": .egp
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipient Details")) {
                    TextField("Recipient Name", text: $viewModel.recipientName)
                    TextField("Account Number", text: $viewModel.recipientAccount)
                }
                
                Section(header: Text("Transfer Details")) {
                    HStack {
                        TextField("Amount", value: $viewModel.sourceAmount, formatter: numberFormatter)
                            .keyboardType(.decimalPad)
                        Spacer()
                        Text(viewModel.sourceCurrency.rawValue)
                            .foregroundColor(.gray)
                    }
                    
                    Picker("From", selection: $viewModel.sourceCurrency) {
                        ForEach(walletViewModel.wallets.map { $0.currency }, id: \.self) { currency in
                            Text(currency.name).tag(currency)
                        }
                    }
                    
                    Picker("Recipient Country/Region", selection: $selectedCountry) {
                        ForEach(euRegion, id: \.self) { region in
                            Text("\(region) (Euro)").tag(region)
                        }
                        ForEach(gbCountries, id: \.self) { country in
                            Text("\(country) (British Pound)").tag(country)
                        }
                        ForEach(usCountries, id: \.self) { country in
                            Text("\(country) (US Dollar)").tag(country)
                        }
                        ForEach(jpCountries, id: \.self) { country in
                            Text("\(country) (Japanese Yen)").tag(country)
                        }
                        ForEach(caCountries, id: \.self) { country in
                            Text("\(country) (Canadian Dollar)").tag(country)
                        }
                        ForEach(auCountries, id: \.self) { country in
                            Text("\(country) (Australian Dollar)").tag(country)
                        }
                        ForEach(chCountries, id: \.self) { country in
                            Text("\(country) (Swiss Franc)").tag(country)
                        }
                        ForEach(cnCountries, id: \.self) { country in
                            Text("\(country) (Chinese Yuan)").tag(country)
                        }
                        ForEach(inCountries, id: \.self) { country in
                            Text("\(country) (Indian Rupee)").tag(country)
                        }
                        ForEach(egCountries, id: \.self) { country in
                            Text("\(country) (Egyptian Pound)").tag(country)
                        }
                    }
                    .onChange(of: selectedCountry) {
                        if let currency = countryToCurrency[selectedCountry] {
                            viewModel.targetCurrency = currency
                        }
                    }
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
            .navigationTitle("Send Money")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        viewModel.processTransfer()
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .alert("Transfer Successful", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if viewModel.matchedAmount > 0 {
                    Text("Amount: \(viewModel.matchedAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))\nFee: \(viewModel.feeAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))\nNet Amount: \(viewModel.netAmount, format: .currency(code: viewModel.sourceCurrency.rawValue))")
                }
            }
        }
    }
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
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

struct TransferView_Previews: PreviewProvider {
    static var previews: some View {
        TransferView()
    }
} 