import SwiftUI

struct TransferDetailsView: View {
    let transferDetails: TransferDetails
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Transfer Information")) {
                    DetailRowWithDate(title: "Transfer ID", value: transferDetails.transferId)
                    DetailRowWithDate(title: "Initiated", value: transferDetails.timestamp, isDate: true)
                    DetailRowWithDate(title: "Estimated Arrival", value: transferDetails.estimatedArrival, isDate: true)
                }
                
                Section(header: Text("Source Account")) {
                    DetailRowWithDate(title: "Account Number", value: transferDetails.sourceAccountNumber)
                    DetailRowWithDate(title: "Bank", value: transferDetails.sourceBankName)
                    DetailRowWithDate(title: "Country", value: transferDetails.sourceBankCountry)
                }
                
                Section(header: Text("Destination Account")) {
                    DetailRowWithDate(title: "Account Number", value: transferDetails.destinationAccountNumber)
                    DetailRowWithDate(title: "Bank", value: transferDetails.destinationBankName)
                    DetailRowWithDate(title: "Country", value: transferDetails.destinationBankCountry)
                }
            }
            .navigationTitle("Transfer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TransferDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TransferDetailsView(transferDetails: TransferDetails(
            sourceAccountNumber: "GB29NWBK60161331926819",
            sourceBankName: "Barclays",
            sourceBankCountry: "United Kingdom",
            destinationAccountNumber: "DE89370400440532013000",
            destinationBankName: "Deutsche Bank",
            destinationBankCountry: "Germany",
            transferId: "TRF123456789",
            timestamp: Date(),
            estimatedArrival: Date().addingTimeInterval(86400)
        ))
    }
} 