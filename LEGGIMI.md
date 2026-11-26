# MDM Smart OS

Il tuo sistema operativo per i NUC dei clienti: stesso motore di Home Assistant,
ma **con il marchio MDM ovunque si veda**. GitHub compila tutto da solo.

## Cosa cambia

| Dove | Prima | Dopo |
|---|---|---|
| Nome del sistema (Impostazioni → Informazioni, os-release) | Home Assistant OS | MDM Smart OS |
| Nome di rete al primo avvio | `homeassistant.local` | `mdm-smart.local` |
| Console sul monitor del NUC | logo e scritte Home Assistant | banner MDM, "console tecnica" |
| Messaggi all'avvio dei servizi | Home Assistant … | MDM Smart Home … |
| Pagina "preparazione" al primo avvio | Home Assistant | MDM Smart Home |
| Login, primo avvio, titolo scheda, tutta l'interfaccia | Home Assistant | MDM Smart Home |
| Icone (browser, telefono, app installata) | logo Home Assistant | logo MDM |
| Comandi `ha` e aiuto | Home Assistant CLI | MDM Smart Home CLI |
| Aggiornamenti | da Home Assistant | dal **tuo canale**, già col marchio |

Restano solo cose che nessuno vede usando il sistema: nomi interni dei
programmi, link alla documentazione, e il file `NOTICE` con la licenza
(obbligatorio per legge).

## Come funziona

```
Ogni notte (automatico)                     Quando vuoi un nuovo file OS (a mano)
─────────────────────────                   ─────────────────────────────────────
GitHub controlla se è uscita                GitHub prende l'OS ufficiale,
una nuova versione ufficiale                ci mette il marchio MDM e lo compila
        │                                            │
        ▼                                            ▼
crea le immagini con marchio MDM            Release: MDM-Smart-OS_X.Y.img.xz
e aggiorna il tuo canale aggiornamenti      (il file da scrivere sul NUC)
        │
        ▼
i NUC dei clienti vedono l'aggiornamento
"MDM Smart Home" e lo installano
```

---

## Preparazione (una volta sola, circa 30 minuti)

### 1. Repository su GitHub
1. Crea un account su github.com, se non ce l'hai.
2. Crea un repository nuovo chiamato **`mdm-smart-os`**, **pubblico**
   (serve pubblico per GitHub Pages e le compilazioni gratuite lunghe).
3. Carica tutti i file di questa cartella (Add file → Upload files,
   trascinando anche la cartella `.github`).

### 2. Il tuo logo
Sostituisci `branding/logo.png` con il tuo logo (la casa arcobaleno):
**quadrato, almeno 1024×1024 pixel**, meglio con sfondo trasparente.
Quello che c'è adesso è solo un segnaposto.

### 3. Canale aggiornamenti (GitHub Pages)
Repository → **Settings → Pages** → Source: **GitHub Actions**.

### 4. Certificato per gli aggiornamenti dell'OS
Sul tuo PC (Git Bash):
```
bash scripts/genera-certificato.sh
```
Poi su GitHub: **Settings → Secrets and variables → Actions → New repository secret**
- `MDM_OTA_CERT` → incolla tutto il contenuto di `mdm-ota-cert.pem`
- `MDM_OTA_KEY` → incolla tutto il contenuto di `mdm-ota-key.pem`

Conserva i due file in un posto sicuro e **non caricarli nel repository**.

### 5. Prima creazione delle immagini
**Actions → "Immagini e canale aggiornamenti MDM" → Run workflow**
(circa 15-20 minuti).

### 6. Rendi pubbliche le immagini (solo la prima volta)
Sul tuo profilo GitHub → **Packages**: per ognuno dei pacchetti creati
(`generic-x86-64-homeassistant`, `amd64-hassio-supervisor`, `amd64-hassio-cli`,
`amd64-hassio-observer`, `amd64-hassio-dns`, `amd64-hassio-audio`,
`amd64-hassio-multicast`) → **Package settings → Change visibility → Public**.

Senza questo passaggio i NUC non possono scaricarle.

### 7. Crea il file del sistema operativo
**Actions → "Crea MDM Smart OS" → Run workflow** (2-4 ore).
Alla fine: pagina **Releases** → **`MDM-Smart-OS_X.Y.img.xz`**.

---

## Da ogni cliente

1. Scarica `MDM-Smart-OS_X.Y.img.xz` dalle Releases.
2. **Balena Etcher** → scrivi il file sul disco del NUC (o su chiavetta e poi sul disco).
3. Accendi il NUC collegato in rete e apri **http://mdm-smart.local:8123**
4. Ripristina il tuo backup MDM (dashboard, Node-RED, card) oppure configura da zero.
5. Attiva l'accesso remoto con lo script Cloudflare (`mdm-attiva-remoto.sh`).

## Aggiornamenti

- **Motore e interfaccia**: automatici. Ogni notte GitHub prepara la nuova
  versione con il marchio e i NUC la propongono in Impostazioni.
- **Sistema operativo**: quando esce una nuova versione dell'OS ufficiale,
  esegui di nuovo "Crea MDM Smart OS". I NUC la ricevono come aggiornamento
  (serve il certificato del punto 4).

## Cambiare nome o logo
Modifica `branding/brand.env` o `branding/logo.png` e carica il file:
le immagini si ricreano da sole. Per l'OS riesegui "Crea MDM Smart OS".

> `BRAND_NAME` deve restare di **14 caratteri** (come "Home Assistant"),
> perché viene sostituito anche dentro programmi già compilati.

## Se qualcosa non va
- **Il workflow OS si ferma subito con "Prima esegui il workflow Immagini"** →
  passi 5 e 6 non fatti, o immagini non pubbliche.
- **Il NUC resta su "preparazione" per sempre** → immagini non pubbliche (passo 6).
- **Errore "No space left on device" nella compilazione OS** → riesegui:
  la seconda volta usa la cache ed è più veloce.
- I dettagli di ogni errore sono in **Actions** → clic sull'esecuzione rossa.
