//
//  HomeView.swift
//  MoneyTracker
//
//  Created by Mattia Di Donato on 31/08/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var expenseManager: ExpenseManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Header component
                HeaderCard(
                    totaleMensile: expenseManager.totaleMensile,
                    totaleAnno: expenseManager.totaleAnno
                )
                
                // Add expense button component
                AddExpenseButton {
                    // Navigazione alla schermata di aggiunta
                    print("Navigate to add expense")
                }
                
                // Summary cards component
                SummaryCardsGrid(
                    totaleAnno: expenseManager.totaleAnno,
                    prossimaScadenza: expenseManager.prossimaScadenza,
                    numeroBolletteMese: expenseManager.numeroBolletteMese,
                    mediaMensile: expenseManager.mediaMensile
                )
                
                // Categories section component
                CategoriesSection(
                    categorie: expenseManager.categorieSpese,
                    totaleMensile: expenseManager.totaleMensile
                )
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Dashboard Spese")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}
