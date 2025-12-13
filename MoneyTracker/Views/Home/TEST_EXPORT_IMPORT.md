# 🧪 Come Testare Export/Import

## Setup Rapido

### 1️⃣ Compila ed esegui l'app
```bash
# In Xcode
⌘ + R
```

### 2️⃣ Aggiungi alcune spese di test
1. Tap il pulsante verde "+" o "Aggiungi Spesa"
2. Aggiungi 2-3 spese (es: Affitto, Luce, Gas)

### 3️⃣ Testa l'Export

**Sul Simulatore:**
1. Tap menu (⋯) in alto a destra
2. Tap "Esporta Dati"
3. Nel share sheet, scegli "Salva su File" o "Salva nell'app File"
4. Scegli una posizione (es: iCloud Drive)
5. Verifica che il file sia stato creato

**Sul Dispositivo Reale:**
1. Tap menu (⋯) in alto a destra
2. Tap "Esporta Dati"
3. Puoi scegliere:
   - AirDrop (invia a un altro dispositivo)
   - Salva su File (Files app)
   - Mail (invia via email)
   - Messaggi
   - Altro...

### 4️⃣ Testa l'Import

#### Opzione A: Usa il file di esempio incluso

1. Trasferisci `test_import_example.json` sul tuo iPhone:
   - Via AirDrop dal Mac
   - Via email
   - Via Files app (trascina su iCloud Drive)

2. Nell'app MoneyTracker:
   - Tap menu (⋯) → "Importa Dati"
   - Seleziona `test_import_example.json`
   - Verifica l'alert: "6 spese aggiunte"

#### Opzione B: Usa un file esportato

1. Esporta i tuoi dati (vedi punto 3)
2. (Opzionale) Tap menu → Debug → "Reset Dati" per svuotare l'app
3. Tap menu → "Importa Dati"
4. Seleziona il file precedentemente esportato
5. Verifica che le spese siano tornate

### 5️⃣ Testa il Merge (No Duplicati)

1. Esporta i dati
2. **NON** eliminare le spese
3. Importa lo stesso file appena esportato
4. Verifica l'alert: "0 spese aggiunte (tutte già presenti)"
5. Verifica che non ci siano duplicati nella lista

### 6️⃣ Testa il Merge (Con Nuove Spese)

**Se hai due dispositivi:**

Dispositivo A:
1. Aggiungi spese: "Affitto", "Luce"
2. Esporta → Invia ad Dispositivo B via AirDrop

Dispositivo B:
1. Aggiungi spese diverse: "Gas", "Acqua"
2. Importa il file da Dispositivo A
3. Verifica che ora hai tutte e 4 le spese: "Affitto", "Luce", "Gas", "Acqua"

**Se hai un solo dispositivo:**
1. Aggiungi "Affitto" + "Luce" → Esporta → Salva come "export1.json"
2. Reset Dati
3. Aggiungi "Gas" + "Acqua" → Esporta → Salva come "export2.json"
4. Importa "export1.json" → 2 spese aggiunte
5. Importa "export2.json" → 2 spese aggiunte
6. Totale: 4 spese senza duplicati

## 🐛 Cosa Controllare nella Console

Apri la console di Xcode (⌘ + ⇧ + C) e cerca:

### Durante l'Export:
```
📤 Export completato: MoneyTracker_Export_2024-12-13_143025.json
📍 Path: /private/var/mobile/Containers/Data/Application/.../tmp/MoneyTracker_Export_2024-12-13_143025.json
📊 Spese esportate: 3
✅ Export preparato, mostro share sheet
```

### Durante l'Import:
```
📁 File selezionato: MoneyTracker_Export_2024-12-13_143025.json
📥 Import completato: MoneyTracker_Export_2024-12-13_143025.json
📊 Spese importate: 3
🔀 Merge completato:
   - Spese esistenti: 0
   - Spese importate: 3
   - Nuove spese aggiunte: 3
   - Duplicati ignorati: 0
📥 Import completato: 3 nuove spese aggiunte
💾 Dati salvati automaticamente
✅ Import completato: 3 spese aggiunte
```

### In caso di errore:
```
❌ Errore export: [descrizione errore]
❌ Errore import: [descrizione errore]
```

## 📋 Checklist Completa

- [ ] L'app compila senza errori
- [ ] Posso aggiungere spese
- [ ] Il menu (⋯) si apre correttamente
- [ ] "Esporta Dati" mostra lo share sheet
- [ ] Posso salvare il file su Files
- [ ] "Importa Dati" mostra il file picker
- [ ] Posso selezionare un file JSON
- [ ] L'import aggiunge le spese correttamente
- [ ] L'import dello stesso file non crea duplicati
- [ ] Gli alert di successo/errore vengono mostrati
- [ ] I log in console sono corretti
- [ ] "Info File" mostra info corrette
- [ ] "Reset Dati" svuota l'app correttamente

## 🎯 Test Avanzati

### Test File Corrotto:
1. Crea un file `test_broken.json` con contenuto:
   ```json
   { "invalid": "json" }
   ```
2. Prova ad importarlo
3. Verifica alert di errore

### Test File Vuoto:
1. Crea un file `test_empty.json` con:
   ```json
   []
   ```
2. Importalo
3. Verifica alert: "0 spese aggiunte"

### Test Spese con Stessi ID:
1. Esporta i dati → `export1.json`
2. Modifica manualmente il file duplicando una spesa (copia/incolla)
3. Importa il file modificato
4. Verifica che non ci siano duplicati (merge corretto)

## 🚨 Troubleshooting

### Il file picker non si apre:
- Verifica che il device/simulator abbia Files app attiva
- Prova su dispositivo reale invece che simulatore

### Lo share sheet è vuoto:
- Normale su simulatore (funzionalità limitate)
- Testa su dispositivo reale

### Import non aggiunge spese:
- Controlla la console per errori
- Verifica che il JSON sia valido (usa JSONLint.com)
- Verifica che le spese abbiano ID univoci

### Duplicati nonostante il merge:
- Controlla che gli ID siano UUID validi
- Verifica i log del merge nella console

## 📧 Debug Info

Per ottenere info dettagliate sul file di persistenza:
Menu → Debug → "Info File"

Output esempio:
```
📄 File: spese.json
📍 Path: /var/mobile/Containers/Data/Application/XXX/Library/Application Support/spese.json
📊 Size: 1234 bytes
✅ Stato: Esiste
```

Buon testing! 🎉
