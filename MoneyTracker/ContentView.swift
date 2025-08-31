import SwiftUI

struct ContentView: View {
    // Stati principali dell'app
    @StateObject private var expenseManager = ExpenseManager()
    
    var body: some View {
        NavigationView {
            HomeView()
                .environmentObject(expenseManager)
        }
    }
}

// Preview per ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
