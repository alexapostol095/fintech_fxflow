import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var walletViewModel = WalletViewModel.shared
    
    var body: some View {
        TabView {
            WalletView()
                .tabItem {
                    Image(systemName: "wallet.pass")
                    Text("Wallet")
                }
            
            TransactionsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Transactions")
                }
            
            ExchangeView()
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Exchange")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
        .environmentObject(walletViewModel)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
} 