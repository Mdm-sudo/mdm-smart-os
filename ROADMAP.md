# MDM Smart OS – lista dei lavori

## Fatto
- Sistema senza tracce di Home Assistant: avvio, nome di rete, console, interfaccia, icone, testi, link di aiuto (→ assistenza.mdmsmart.com)
- Cloud Nabu Casa e avvisi esterni disattivati di serie
- Canale aggiornamenti MDM (GitHub Pages) e immagini con marchio MDM
- Logo MDM (casa arcobaleno)

## Da fare
1. **Schermata cliente bloccata**: utente cliente non amministratore, nessuna impostazione, dashboard non modificabile
2. **"Le mie automazioni"**: il cliente crea solo piccole regole sue (orari, "quando succede", "quando esco"); quelle del tecnico visibili col lucchetto
3. **Sfondi animati nell'app**: meteo esterno (pioggia, sole, neve), feste (Natale) e compleanno del cliente
4. **Pagina "Rete Wi-Fi"** (tecnico): IP di MDM Smart e dei dispositivi, mappa di aggancio agli access point (Shelly, Tasmota, ESPHome), indipendente dal router
5. **Dispositivi Wi-Fi in locale**: Shelly, Tasmota, ESPHome, Matter, WLED trovati da soli; Tuya in locale con chiave presa una volta dal cloud (pulsante)
6. **Più coordinatori Zigbee**: una rete Zigbee2MQTT per coordinatore, con nome e mappa propri
7. **Allarme Ajax in locale**
   - Stato in tempo reale tramite protocollo SIA (l'hub manda gli eventi a MDM Smart come a una centrale di vigilanza): inserito, disinserito, allarmi, porte, batterie
   - Inserimento/disinserimento a filo: MultiTransmitter (o modulo relè Ajax) + relè comandato da MDM Smart
   - Pagina "Allarme Ajax" nel menu tecnico per la configurazione
8. **Alexa e Google** gratis e in locale tramite Matter (QR code dalla pagina "Assistenti vocali"); allarme e cancello esclusi di serie
9. **Avvisi AI solo per il tecnico**: controlli fissi (connessione, batterie, dispositivi che non rispondono) + piccola AI che scrive il messaggio; invio su app MDM o Telegram
10. **Collegamento tra più case dello stesso cliente**
    - Spento di serie: si attiva o si disattiva con un interruttore, casa per casa, dal menu tecnico
    - Si sceglie cosa condividere (solo stato, oppure anche comandi e automazioni tra le case)
    - Se si spegne o salta il collegamento, ogni casa continua a funzionare da sola
11. Icone delle integrazioni copiate su server MDM (non più scaricate dal server di Home Assistant)
