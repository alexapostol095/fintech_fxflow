import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(walletViewModel.wallets) { wallet in
                    if !wallet.transactions.isEmpty {
                        Section(header: Text(wallet.currency.name)) {
                            ForEach(wallet.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .onTapGesture {
                                        self.selectedTransaction = transaction
                                    }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Transactions")
            .sheet(item: $selectedTransaction) { transaction in
                if let matchedInfo = transaction.matchedTransactionInfo {
                    TransferDetailsView(
                        userRecipient: matchedInfo.userRecipient,
                        peerRecipient: matchedInfo.peerRecipient,
                        userTransferDetails: matchedInfo.userTransferDetails,
                        peerTransferDetails: matchedInfo.peerTransferDetails,
                        fee: matchedInfo.fee,
                        netAmount: matchedInfo.netAmount,
                        exchangeRate: matchedInfo.exchangeRate,
                        sourceCurrency: matchedInfo.sourceCurrency,
                        targetCurrency: matchedInfo.targetCurrency,
                        recipientGets: matchedInfo.recipientGets,
                        isSameCurrency: matchedInfo.isSameCurrency
                    )
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @State private var showingTransferDetails = false
    
    private var statusColor: Color {
        switch transaction.status {
        case .pending:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: transaction.type == .send ? "arrow.up.right" : "arrow.down.left")
                    .foregroundColor(transaction.type == .send ? .red : .green)
                
                VStack(alignment: .leading) {
                    Text(transaction.type == .send ? "Sent" : "Received")
                        .font(.headline)
                    Text(transaction.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(transaction.type == .send ? "-" : "+")\(transaction.amount, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(transaction.type == .send ? .red : .green)
                    Text(transaction.sourceCurrency.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if let matchedInfo = transaction.matchedTransactionInfo {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Matched Transaction")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("\(matchedInfo.amount, specifier: "%.2f")")
                            .font(.subheadline)
                        Text(matchedInfo.targetCurrency.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        showingTransferDetails = true
                    }) {
                        Label("View Transfer Details", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct TransferDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let userRecipient: TransferRecipient
    let peerRecipient: TransferRecipient
    let userTransferDetails: TransferDetails
    let peerTransferDetails: TransferDetails
    let fee: Double
    let netAmount: Double
    let exchangeRate: Double
    let sourceCurrency: Currency
    let targetCurrency: Currency
    let recipientGets: Double
    let isSameCurrency: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if isSameCurrency {
                        Text("You sent \(String(format: "%.2f", netAmount)) \(sourceCurrency.rawValue) to \(userRecipient.name) (\(userRecipient.accountNumber)).")
                            .font(.body)
                            .padding(.bottom, 2)
                    } else {
                        Text("You sent \(String(format: "%.2f", netAmount)) \(sourceCurrency.rawValue) (after 1% fee) to \(peerRecipient.name) (\(peerRecipient.accountNumber)).")
                            .font(.body)
                            .padding(.bottom, 2)
                        Text("Your recipient \(userRecipient.name) (\(userRecipient.accountNumber)) received \(String(format: "%.2f", recipientGets)) \(targetCurrency.rawValue) from \(peerTransferDetails.sourceAccountNumber).")
                            .font(.body)
                            .padding(.bottom, 2)
                        Text("Exchange rate: 1 \(sourceCurrency.rawValue) = \(String(format: "%.4f", exchangeRate)) \(targetCurrency.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Section(header: Text("Your Recipient")) {
                    DetailRow(title: "Name", value: userRecipient.name)
                    DetailRow(title: "Account Number", value: userRecipient.accountNumber)
                }
                if !isSameCurrency {
                    Section(header: Text("Peer's Recipient")) {
                        DetailRow(title: "Name", value: peerRecipient.name)
                        DetailRow(title: "Account Number", value: peerRecipient.accountNumber)
                    }
                }
                Section(header: Text("Transfer Details")) {
                    DetailRow(title: "Your Transfer ID", value: userTransferDetails.transferId)
                    if !isSameCurrency {
                        DetailRow(title: "Peer's Transfer ID", value: peerTransferDetails.transferId)
                        DetailRow(title: "Fee", value: String(format: "%.2f", fee))
                        DetailRow(title: "Net Amount", value: String(format: "%.2f", netAmount))
                        DetailRow(title: "Recipient Gets", value: String(format: "%.2f", recipientGets) + " " + targetCurrency.rawValue)
                        DetailRow(title: "Exchange Rate", value: String(format: "%.4f", exchangeRate))
                    }
                    DetailRow(title: "Estimated Arrival", value: userTransferDetails.estimatedArrival.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .navigationTitle("Transfer Report")
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

#if DEBUG
struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
            .environmentObject(WalletViewModel.shared)
    }
}
#endif 