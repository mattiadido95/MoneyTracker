import SwiftUI

struct ContentView: View {
    @StateObject private var expenseManager = ExpenseManager()

    var body: some View {
        #if os(macOS)
        NavigationStack {
            HomeView()
                .environmentObject(expenseManager)
        }
        .frame(minWidth: 900, idealWidth: 1200, maxWidth: .infinity,
               minHeight: 700, idealHeight: 800, maxHeight: .infinity)
        #else
        TabView {
            NavigationStack {
                HomeView()
                    .environmentObject(expenseManager)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                ExpenseListView()
                    .environmentObject(expenseManager)
            }
            .tabItem { Label("Lista", systemImage: "list.bullet") }

            NavigationStack {
                StatisticsView()
                    .environmentObject(expenseManager)
            }
            .tabItem { Label("Statistiche", systemImage: "chart.bar.fill") }
        }
        .tint(.indigo)
        #endif
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_PreviewWrapper()
    }
}

private struct ContentView_PreviewWrapper: View {
    @StateObject private var expenseManager = ExpenseManager(mockData: true)

    var body: some View {
        #if os(macOS)
        NavigationStack {
            HomeView()
                .environmentObject(expenseManager)
        }
        .frame(minWidth: 900, idealWidth: 1200, maxWidth: .infinity,
               minHeight: 700, idealHeight: 800, maxHeight: .infinity)
        #else
        TabView {
            NavigationStack {
                HomeView()
                    .environmentObject(expenseManager)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                ExpenseListView()
                    .environmentObject(expenseManager)
            }
            .tabItem { Label("Lista", systemImage: "list.bullet") }

            NavigationStack {
                StatisticsView()
                    .environmentObject(expenseManager)
            }
            .tabItem { Label("Statistiche", systemImage: "chart.bar.fill") }
        }
        .tint(.indigo)
        #endif
    }
}
