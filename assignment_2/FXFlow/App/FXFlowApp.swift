import SwiftUI

@main
struct FXFlowApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var walletViewModel = WalletViewModel.shared
    @StateObject private var exchangeViewModel = ExchangeViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                if authViewModel.signupStep == .completed {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .environmentObject(walletViewModel)
                        .environmentObject(exchangeViewModel)
                        .preferredColorScheme(.light)
                        .accentColor(.purple)
                } else {
                    SignupFlowView()
                        .environmentObject(authViewModel)
                        .preferredColorScheme(.light)
                        .accentColor(.purple)
                }
            } else {
                SignupView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(.light)
                    .accentColor(.purple)
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        // This ContentView is a router, but the main logic is in FXFlowApp
        Text("Loading...")
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var exchangeViewModel: ExchangeViewModel
    
    var body: some View {
        TabView {
            WalletView()
                .environmentObject(walletViewModel)
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass")
                }
            
            ExchangeView()
                .environmentObject(walletViewModel)
                .environmentObject(exchangeViewModel)
                .tabItem {
                    Label("Exchange", systemImage: "arrow.left.arrow.right")
                }
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
} 