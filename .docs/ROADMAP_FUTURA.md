# MoneyTracker - Roadmap Futura

Roadmap operativa organizzata in sprint. Spunta le voci man mano che vengono completate.

---

## Sprint 1 — Import bancario funzionante

Obiettivo: rendere l'import XLSX utilizzabile end-to-end (da file a spese salvate).

- [ ] Creare mapper `BankTransaction → CategoriaSpesa` (conversione tipo, importo, data, nome)
- [ ] Integrare `CategoryResolver` nella preview di `BankImportView` (sostituire "Non categorizzato")
- [ ] Interfaccia review: l'utente conferma o corregge la categoria suggerita
- [ ] Collegare "Conferma Import" a `ExpenseManager` (salvataggio persistente)
- [ ] Feedback loop: inviare le correzioni utente a `CategoryResolver.provideFeedback()`
- [ ] Installare CoreXLSX e testare con file XLSX reali
- [ ] Test end-to-end: file XLSX → preview → conferma → spese visibili in dashboard

---

## Sprint 2 — Gestione spese completa

Obiettivo: coprire le operazioni CRUD base e migliorare la navigazione.

- [x] Modifica spese esistenti (tap su riga → edit sheet)
- [x] Barra di ricerca nella lista spese (`.searchable()`)
- [x] Raggruppamento spese per mese nella lista
- [ ] Vista dettaglio singola categoria (`CategoryDetailView`) con lista transazioni filtrata
- [ ] Categorie personalizzate dall'utente (aggiungi/rinomina/elimina)

---

## Sprint 3 — UX e onboarding

Obiettivo: migliorare l'esperienza al primo avvio e le impostazioni.

- [ ] Schermata onboarding per primo avvio
- [x] Suggerimenti categorie predefinite (Affitto, Luce, Gas, Internet, Spesa)
- [x] Quick actions nello stato vuoto (collegamento rapido ad "Aggiungi spesa")
- [x] `SettingsView` con dark mode (`@AppStorage`)
- [ ] Notifiche per scadenze bollette
- [ ] Rilevamento spese ricorrenti

---

## Sprint 4 — Export/Import avanzato

Obiettivo: supportare piu formati e dare piu controllo all'utente.

- [ ] Export/import CSV
- [ ] Export report PDF delle statistiche
- [ ] Export filtrato per data/categoria
- [ ] Import parziale con checkbox (selezione spese)
- [ ] Preview spese prima dell'import JSON
- [ ] Import/export in background con indicatore progresso

---

## Sprint 5 — Statistiche avanzate

Obiettivo: rendere i grafici piu utili e interattivi.

- [ ] Confronto periodi (mese corrente vs precedente)
- [ ] Grafici interattivi (tap per selezione, `chartAngleSelection`)
- [ ] Media giornaliera e categoria piu costosa
- [ ] Trend mensile dettagliato
- [ ] Nuovi tipi di grafici: scatter, heat map, stacked bar

---

## Sprint 6 — Pipeline ETL: nuovi formati e testing

Obiettivo: estendere il supporto file e garantire qualita con test.

- [ ] Import da CSV (nuovo extractor)
- [ ] Import da PDF estratti conto
- [ ] Unit test per ogni fase del pipeline (extract, transform, validate)
- [ ] Integration test end-to-end
- [ ] UI test per `BankImportView`
- [ ] Beta testing con file bancari reali di diversi istituti

---

## Sprint 7 — Classificatore AI / Machine Learning

Obiettivo: sostituire il resolver rule-based con un modello intelligente.

- [ ] Sostituire `MockCategoryResolver` con modello ML reale
- [ ] Training su dati utente (on-device con Create ML o Core ML)
- [ ] Apprendimento automatico dalle correzioni utente
- [ ] Supporto multi-valuta nelle transazioni

---

## Sprint 8 — Cloud e architettura

Obiettivo: sincronizzazione e miglioramenti tecnici di fondo.

- [ ] iCloud sync tramite CloudKit
- [ ] Interfaccia risoluzione conflitti
- [ ] Backup automatico su iCloud
- [ ] Migrazione persistenza a Core Data o SwiftData
- [ ] Error handling avanzato
- [ ] Ottimizzazione performance
- [ ] Animazioni e transizioni UI
