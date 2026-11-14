# NordicRent — Projektplan

**Presentation:** 2026-11-19 (torsdag) · **Inlämning:** 2026-11-22 · **Mål:** VG

> Uppdaterad 2026-11-09 efter lärarens nya version av uppgiften. Den nya versionen har färre API-rutter och fokuserar på databasen: SQL, transaktion, databasprov och MongoDB. Det som inte längre krävs finns under [Sparat till API v2](#sparat-till-api-v2-nästa-kurs).
>
> **Senast uppdaterad 2026-11-14 (lördag kväll):** steg 1–4 klara, inklusive OOP-klassen (utom ER-export). Nästa: steg 5, bokningstransaktionen.

---

## Roadmap (uppgiftens 7 steg)

- [x] **Steg 1 – Planera datamodellen:** ER-diagram, samband, 3NF, vad som ska ligga i MongoDB
  - [ ] Kvar: exportera ER-diagrammet till bild/PDF + skriva den korta texten (3NF, relationer, MongoDB-val, transaktion, backend↔frontend)
- [x] **Steg 2 – Implementera MySQL:** `setup.sql` + `seed.sql`, testa constraints och JOINs, installationen går att köra om (`setup.sql` → `seed.sql` återställer allt)
- [x] **Steg 3 – Visa SQL-kunskaper:** `database/queries.sql` med 4 frågor (JOIN 3 tabeller, GROUP BY, 2 nästlade) + kommentarer om vad varje fråga svarar på
  - [ ] Kvar: fråga läraren hur resultaten ska "visas" (skärmdump, text i README eller kommentar i filen?)
- [x] **Steg 4 – Express-koppling:** servern startar, ansluter med `mysql2` som appanvändaren, alla fyra utrustningsrutterna klara med `?`-parametrar, validering och felhantering (2026-11-14)
  - [x] OOP-klassen `EquipmentRepository` klar 2026-11-14 kväll (all utrustnings-SQL flyttad dit)
- [ ] **Steg 5 – Bokningstransaktionen:** `POST /api/bookings` som riktig transaktion, visa att rollback tar bort alla delresultat ← **NÄSTA (söndag 15/11)**
- [ ] **Steg 6 – MongoDB:** spara och läsa tillståndsrapporter via de två rapportrutterna, motivera varför de passar som dokument
- [ ] **Steg 7 – Kontroll och presentation:** tre databasprov i `DATABASE_TESTS.md`, README med start/stopp och databasinställningar, träna på att förklara SQL- och dataval

---

## Domänen

### Kunder (`customers`)
- [x] Tabell för kunder med id, namn, e-post och telefonnummer
- [x] E-post är unik
- [x] `deleted_at` för anonymiserade kunder (se Öppna frågor)
- [x] Namn i två kolumner: `first_name` + `last_name` (slås ihop med `CONCAT(...) AS name` när de ska visas)
- [x] **Personuppgifter** = `first_name`, `last_name`, `email`, `phone`. De får **inte** vara `NOT NULL`, eftersom alla fyra sätts till `NULL` vid anonymisering.
- [x] Ett `CHECK`: om `deleted_at` är `NULL` (aktiv kund) måste alla fyra personuppgifter vara ifyllda

### Depåer (`depots`)
- [x] Tabell för depåer med id, namn, stad och adress
- [x] Relation depå → utrustning är 1:N
- [x] En artikel tillhör exakt en depå åt gången

### Kategorier (`categories`)
- [x] Egen tabell för kategorier (inte fritext)
- [x] Varje kategori har namn och beskrivning
- [x] `category_id` som PK (inte namnet, så ett namnbyte bara ändrar en rad), namnet `UNIQUE` + `NOT NULL`

### Utrustning (`equipment`)
- [x] Tabell för utrustning med id, kategori, modellnamn, dygnspris och inköpsdatum
- [x] Status som ENUM: `available`, `rented`, `maintenance`, `retired`
- [x] Kopplad till en kategori
- [x] Kopplad till en depå

### Bokningar (`bookings`)
- [x] En kund kan ha flera bokningar
- [x] En bokning gäller ett datumintervall (start och slut)
- [x] En bokning kan innehålla en eller flera artiklar (bokningsrader)
- [x] Status som ENUM: `confirmed`, `active`, `returned`, `cancelled`
- [x] Totalpriset beräknas från bokningsraderna (lagras **inte** som kolumn, räknas fram med en fråga: dygnspris från `booking_lines` × antal dygn)
- [ ] En utrustning som redan är uthyrd får inte bokas igen (krav). Full kontroll av överlappande datum = fördjupning (VG), se Öppna frågor.
- [x] Tidpunkt när bokningen gjordes (sätts automatiskt)
- [x] Kopplad till en kund (1:N)

### Bokningsrader (`booking_lines`)
- [x] Egen tabell, kopplingstabell för N:M mellan bokningar och utrustning
- [x] `booking_line_id` som PK (beslutat 2026-11-13, se Öppna frågor)
- [x] `booking_id` FK → bokningar
- [x] `equipment_id` FK → utrustning
- [x] `UNIQUE KEY (booking_id, equipment_id)`
- [x] Dygnspriset som gällde vid bokningstillfället

### Tillståndsrapporter (MongoDB)
- [ ] Rapporten gäller en **utrustning**: `equipmentId` (inte bokningsraden längre)
- [ ] `equipmentId` är en applikationsreferens, **inte** en främmande nyckel. MongoDB vet inte om att artikeln finns i MySQL, så det är appen som ansvarar för att id:t stämmer.
- [ ] `notes`: fritextanteckningar
- [ ] `checklist`: checklista som skiljer sig per kategori, t.ex.:
  - kajak: skrov, paddlar
  - elcykel: batterihälsa, chassi
  - tält: duk, tältpinnar, allt material inlämnat
- [ ] `damageFlag`: skadeflagga
- [ ] Eventuella foto-URL:er (valfritt, inte krav längre). Bilden sparas inte i databasen, bara en **länk** (URL). Kan vara flera bilder → en lista med URL:er.
- [ ] MySQL och MongoDB behöver **inte** ingå i samma transaktion

**Beslut och insikter (2026-11-11):**
- Rapporterna finns **bara** i MongoDB. Ingen tabell för rapporter i `setup.sql`.
- Checklistan beror på artikelns **kategori** (från `categories` i MySQL), inte på den enskilda artikeln. Cykel och elcykel kan vara samma kategori: en vanlig cykels rapport har då helt enkelt inget fält för batterihälsa.
- Fält som inte behövs **utelämnas helt** i dokumentet. De står inte som `NULL` (som en tom kolumn i MySQL hade gjort).
- Nästlat värde, t.ex. tältpinnar: `pinnar: { skick: "ok", antal: 7 }` (ett objekt inuti ett objekt).
- Ny kategori (t.ex. SUP-brädor; skidor finns redan i seed-datan sedan 2026-11-13): i MySQL hade checklistan krävt en ny tabell eller nya kolumner. I MongoDB ändras ingenting i databasen, bara valideringen i Express.
- **Strukturen ("mallen") finns i Express, inte i MongoDB.** MongoDB sparar det den får. I MySQL ansvarar databasen för strukturen, i MongoDB ansvarar backend.
- Validering vid `POST /api/reports`, i `src/validation.js` (`validReport` finns som utkast, byggs klart i steg 6):
  - **Grund (krav):** `equipmentId` finns i MySQL (backend frågar MySQL först, eftersom det inte finns någon FK), `damageFlag` är true/false, `checklist` är ett objekt. Fel → svara med fel och spara inget.
  - **Fördjupning (VG, om tid finns):** hämta artikelns kategori med JOIN och kontrollera att checklistan har rätt fält för kategorin.

---

## MySQL-delen

### Normalisering (3NF)
- [x] Schemat är i 3NF
- [ ] Kort text om 3NF, relationer, MongoDB-val och transaktion (lämnas in tillsammans med ER-diagrammet)
- [ ] Förklara minst **ett eget normaliseringsval** (kandidater: prissnapshot på bokningsraden, eller totalpriset som beräknas i stället för att lagras)
- [ ] Förklara **ett samband mellan backend och frontend** i texten till ER-diagrammet: JOIN som gör om `category_id`/`depot_id` till namn i JSON-svaret (se Öppna frågor, besvarat av läraren 2026-11-13)

### Tabeller och villkor
- [x] Lämpliga datatyper för varje kolumn
- [x] `PRIMARY KEY` i varje tabell
- [x] `FOREIGN KEY` med genomtänkt `ON DELETE`-beteende (motivera varje)
- [x] `UNIQUE`-villkor där det behövs
- [x] `NOT NULL` där det behövs
- [x] Standardvärden (`DEFAULT`) där det passar
- [x] `CHECK`-villkor: `chk_equipment_daily_price`, `chk_customer_personal_data`, `chk_booking_duration`, `chk_booking_lines_daily_price`

### Främmande nycklar och ON DELETE
| FK | Pekar på | ON DELETE | Motivering |
|---|---|---|---|
| `equipment.depot_id` | `depots` | RESTRICT | En depå med utrustning får inte tas bort. Stänger en depå flyttas utrustningen först (`UPDATE equipment SET depot_id = ...`). |
| `equipment.category_id` | `categories` | RESTRICT | Många artiklar hör till samma kategori. Kategorin kan inte tas bort så länge artiklar använder den. |
| `bookings.customer_id` | `customers` | RESTRICT | En bokning kan inte finnas utan kund, och bokningshistoriken ska skyddas (bokföringslagen, 7 år). Kunder raderas inte, de anonymiseras (se nedan). |
| `booking_lines.booking_id` | `bookings` | CASCADE | En bokningsrad betyder inget utan sin bokning. Tas bokningen bort (t.ex. en gammal avbokning) försvinner raderna med den. |
| `booking_lines.equipment_id` | `equipment` | RESTRICT | Skyddar bokningshistoriken (totalen räknas från raderna). Artiklar raderas inte: `DELETE /api/equipment/:id` sätter status `retired` i stället ("avveckling enligt din FK-policy" i uppgiften). |

### Leverabler
- [x] `database/setup.sql` skapar hela schemat
- [x] `database/seed.sql` med exempeldata:
  - [x] minst 2 depåer (3)
  - [x] minst 3 kategorier (4)
  - [x] minst 8 utrustningsposter (12)
  - [x] minst 3 kunder (8, varav 1 anonymiserad)
  - [x] minst 3 bokningar med bokningsrader (16 bokningar, 22 rader)
- [x] Seed-filen går att **köra om** via återställning: `setup.sql` (gör `DROP DATABASE`) och sedan `seed.sql`. `seed.sql` två gånger i rad utan setup ger dubblett-fel (1062), eftersom id:na skrivs ut. Beskrivs i README (TODO "Setting up and resetting").
- [ ] Seed-datan tas fram med AI-hjälp. Det redovisas i README, och jag ska förstå och kunna förklara datan.

### Säkerhet
- [x] Skapa en applikationsanvändare med minsta möjliga behörighet
  - **Beslut 2026-11-13:** användaren skapas **sist i `setup.sql`** (uppgiften räknar upp tre SQL-filer). `DROP USER IF EXISTS` + `CREATE USER`, eftersom användare ligger utanför databasen och inte försvinner med `DROP DATABASE`.
  - **Rättigheter per tabell** (bara det de 7 rutterna behöver): `equipment` SELECT/INSERT/UPDATE · `categories` + `depots` SELECT · `bookings` + `booking_lines` SELECT/INSERT · `customers` inget (FK:n kontrolleras av MySQL själv). Ingen av rutterna tar bort rader (`DELETE /api/equipment/:id` = `UPDATE` till `retired`), så `DELETE` behövs inte. Inga strukturändringar (`CREATE`, `ALTER`, `DROP`) och ingen `GRANT`.
    - **Insikt 2026-11-14:** hade DELETE-rutten skrivits som `DELETE FROM equipment` hade MySQL nekat (`ER_TABLEACCESS_DENIED_ERROR`, 1142). Minsta rättigheter skyddar alltså även mot fel i min egen kod.
  - Appanvändaren är **appens** konto, inte en anställds eller utvecklarens. Utvecklaren använder root i Database Client.
  - [x] Lösenordet: `12345` är ett övningslösenord (lektionens sätt). Det står i `setup.sql`, `.env.example` och `.env` (bara `.env` är i `.gitignore`). Beslut 2026-11-14: behålls i `.env.example` för enkelhetens skull, README säger att det ska bytas i en riktig installation.
  - **Beslut 2026-11-14: host `'%'` i stället för `'127.0.0.1'`** (`'nordicrent_app_user'@'%'`).
    - **Problemet:** första starten av `server.js` gav `Access denied for user 'nordicrent_app_user'@'<datorns nätverksadress>'`. MySQL körs i en Podman-container, och inifrån containern kommer API:ts anslutning från datorns nätverksadress, inte från 127.0.0.1. För MySQL är `användare@host` en helhet, så `@'127.0.0.1'` och `@'<datorns nätverksadress>'` är två olika användare.
    - **Varför det fungerade i Database Client:** där loggar jag in som root, och root är redan `'%'` i container-imagen.
    - **Varför `'%'`:** fungerar både med container (hos mig) och utan (MySQL installerat direkt, som hos läraren). En fast IP (`@'<datorns nätverksadress>'`) kan ändras när routern delar ut en ny adress.
    - **Avvägning (säkerhet):** `'%'` = från vilken dator som helst, **inte** vem som helst. Lösenordet krävs fortfarande, och användaren har bara rättigheterna ovan. I en riktig installation: starkt lösenord och MySQL-porten bara lokalt (`-p 127.0.0.1:3306:3306`).
    - `127.0.0.1` i `.env` (`DB_HOST`) och i Database Client är fortfarande rätt: det är adressen man ansluter **till**. `@'…'` i `CREATE USER` är varifrån man får komma.
    - Lärarens `school_api` (`'app_user'@'127.0.0.1'`) har samma problem i min miljö.
    - [x] Nämnt i README ("Database settings", 2026-11-14). Kvar: nämna vid redovisningen.
- [x] Appen ansluter aldrig som root (`.env` → `nordicrent_app_user`)
- [x] `?`-parametrar för **alla** SQL-värden som kommer från API-anrop (utrustningsrutterna klara, bokningar och rapporter kvar)

### SQL-frågor (`database/queries.sql`)
Körs i MySQL och resultatet visas. De behöver **inga** egna API-rutter.
- [x] Minst två nästlade SELECT-frågor. Valda frågor (fråga 3 och 4 i filen):
  1. **Flitiga kunder:** vilka kunder har gjort fler bokningar än vad en kund gör i genomsnitt?
  2. **Top earners:** vilka artiklar har dragit in mer i hyresintäkter än genomsnittet per artikel? (Räknar med priset på bokningsraden, så prisändringar påverkar inte gammal intäkt.)
- [x] Minst en JOIN med minst tre tabeller: fråga 1, utrustning + depå + kategori, samma som `GET /api/equipment` (DB-01)
- [x] Minst en sammanställning med `GROUP BY`: fråga 2, antal artiklar i bruk per depå (retired räknas inte)
- [x] En kort förklaring till varje fråga: vilken fråga svarar den på?
- [ ] Extra, om tid finns (VG):
  - genomsnittligt värde för en bokning (totalen räknas fram per bokning först)
  - kunder som bokat i alla städer där NordicRent har depå
  - en kunds bokningshistorik

### Transaktion
- [ ] Skapandet av en bokning sker i en transaktion: bokningen, dess rader och statusuppdateringen av utrustningen lyckas eller misslyckas som en helhet
- [ ] Visa en **COMMIT** (allt sparas)
- [ ] Visa en **avsiktlig ROLLBACK** (ett steg misslyckas, och inga halvfärdiga bokningsrader blir kvar)
- [ ] Förhindra en uppenbar dubbelbokning av en utrustning som redan är uthyrd
- [x] COMMIT + ROLLBACK visade i SQL (DB-03, 2026-11-14). API-delen återstår i steg 5.
- [ ] **Priset till bokningsraden med `INSERT … SELECT`** (från `equipment.daily_price`): priset går MySQL → MySQL och passerar aldrig JavaScript (ingen sträng/Number-omvandling), och klienten kan inte skicka in ett eget pris.
- [ ] **Kolla `affectedRows` efter varje INSERT/UPDATE i transaktionen.** Fälla: `INSERT … SELECT … WHERE equipment_id = 99` för en artikel som inte finns ger **inget fel**. SELECT:en hittar 0 rader, så 0 rader läggs in, och FK:n får aldrig något att stoppa. Om `affectedRows` är 0 måste backend själv köra ROLLBACK, annars blir det en bokning utan rader. Samma idé som `ROW_COUNT()` i SQL (`~/sql-kurs/2026-11-09`, fil 03) och lektionens `WHERE status = 'open'`-vakt.

### Felhantering och databasprov
- [x] Databasspecifik felhantering: `dbFailure(error, res)` i `server.js` (2026-11-14) känner igen MySQL:s `error.code` och svarar med JSON:
  - **400** (klienten skickade fel data): `ER_CHECK_CONSTRAINT_VIOLATED` (3819), `ER_NO_REFERENCED_ROW_2` (1452)
  - **409** (krock med det som redan finns): `ER_DUP_ENTRY` (1062), `ER_ROW_IS_REFERENCED_2` (1451)
  - **500** för allt annat. Klienten får bara ett allmänt meddelande, detaljerna loggas i serverterminalen (`console.error` med rutten först).
- [x] **Validering i två lager** (2026-11-14):
  - **Lager 1, `src/validation.js`:** körs före `try`, stoppar fel data med 400 innan MySQL nås. `positiveId`, `isObject`, `validDate` (egen hjälpfunktion, återanvänds i bokningar), `validEquipment` (id:n positiva heltal, `model_name` 1–80 tecken, pris ett tal 0–99999.99, datum `ÅÅÅÅ-MM-DD`).
  - **Lager 2, constraints i MySQL + `dbFailure`:** reservskydd (defense in depth) om valideringen missar något. Prisregeln i JS är samma som CHECK:en (`>= 0`, gratis artiklar som hjälm tillåts).
- [ ] Tre dokumenterade databasprov i `DATABASE_TESTS.md`, med förväntat och faktiskt resultat:
  1. [x] läsning/JOIN (DB-01, 2026-11-14)
  2. [x] ett constraint-fel (DB-02, SQL 2026-11-13 + API 2026-11-14: negativt pris och okänd kategori → 400)
  3. [ ] rollback utan halvfärdiga bokningsrader (DB-03: SQL-delen klar 2026-11-14, API-delen kvar till steg 5)
  - Extra: DB-04 (anonymisering), DB-05 (bookings-constraints), DB-06 (booking_lines-constraints)

### Objektorienterad problemlösning
- [x] Ett litet kodexempel, t.ex. en klass eller ett objekt för databasåtkomst, och en förklaring av varför det hjälper. Inga särskilda arkitekturlager krävs.
  - **Klart 2026-11-14:** klassen `EquipmentRepository` i `src/repositories/equipmentRepository.js`. All SQL för utrustning är flyttad dit, `server.js` har ingen `pool.execute` kvar för utrustning. Testat: GET oförändrad, POST 201, PUT 200/404, DELETE 200/404.
  - **Konstruktorn** tar emot `pool` och sparar den på `this.pool`. Poolen skapas i `server.js` (`require('./config/db')`) och lämnas över med `new EquipmentRepository(pool)`, en instans. `server.js` behöver alltså fortfarande `pool` (för `new …`, `SELECT 1` vid start och `pool.end()`).
  - **Metoder** (namn efter vad de gör i databasen, inte HTTP-metoden): `findAll()` → raderna · `create(data)` → `insertId` · `update(id, data)` → `affectedRows` · `retire(id)` → `affectedRows`.
  - **Ansvarsfördelning (det jag förklarar på redovisningen):** klassen vet ingenting om HTTP (inget `req`/`res`, inga statuskoder, inget `try/catch`). Den pratar bara med databasen och ger tillbaka vad som hände. Rutten validerar, anropar metoden och översätter resultatet till en statuskod (`affectedRows === 0` → 404). Fel "bubblar upp" till rutternas `catch` och `dbFailure`.
  - **Varför det hjälper:** all SQL för en tabell på ett ställe, kortare rutter, samma metod kan återanvändas (t.ex. av bokningstransaktionen), och vill man byta databas eller testa rutterna behöver bara klassen ändras.
  - **Lärdomar på vägen:** metoder som gör liknande saker ska ge tillbaka samma sorts sak (först gav `update`/`retire` hela `result`, då blev `affectedRows === 0` aldrig sant och 404 kom aldrig, utan något fel). Byter man namn på en variabel måste alla ställen ändras (`result is not defined` → 500, men INSERT:en hade redan sparats).
  - Kvar (valfritt): en `BookingRepository` för transaktionen i steg 5, om det passar.

### Utkast: varför varje tabell finns (till texten om 3NF)
- **customers:** samlar all information om en kund på ett ställe.
- **depots:** information om platserna där NordicRent finns. Handlar bara om depåerna och inget annat.
- **categories:** egen entitet med namn och beskrivning. Flera artiklar hör till samma kategori, så beskrivningen lagras en gång i stället för på varje artikel.
- **equipment:** de fysiska artiklarna och deras status. Kopplas till en depå (varje depå har sin egen utrustning) och till en kategori (flera artiklar kan höra till samma kategori).
- **bookings:** det som gäller hela bokningen: kund, datumintervall, status och när bokningen gjordes. En kund kan ha flera bokningar, en bokning har exakt en kund.
- **booking_lines:** kopplar ihop bokningar och utrustning (N:M). Utan den skulle bokningen behöva innehålla artiklarna, eller artiklarna bokningarna. Nu kan `equipment` handla bara om utrustning och `bookings` bara om bokningen.
- **Tillståndsrapporter:** ligger i MongoDB, inte i MySQL (motiveras i steg 1/6).

---

## API (endast 7 obligatoriska rutter)

| Metod | Rutt | Databaskunskap som visas | Status |
|---|---|---|---|
| GET | `/api/equipment` | SELECT + JOIN (utrustning, kategori, depå) | ✅ 2026-11-14 |
| POST | `/api/equipment` | Parameteriserad INSERT | ✅ 2026-11-14 |
| PUT | `/api/equipment/:id` | Parameteriserad UPDATE | ✅ 2026-11-14 |
| DELETE | `/api/equipment/:id` | Avveckling: sätter status `retired` (enligt FK-policyn) | ✅ 2026-11-14 |
| POST | `/api/bookings` | MySQL-transaktion med booking + booking_lines | steg 5 |
| POST | `/api/reports` | Spara ett MongoDB-dokument | steg 6 |
| GET | `/api/reports/equipment/:id` | Hämta MongoDB-dokument | steg 6 |

- [x] Valfritt: `GET /api/health` (räknas inte till de sju)

**Struktur (beslut 2026-11-14):** förenklad, nära lärarens `school_api`. Kvar i `src/`: `server.js` (alla rutter + `dbFailure`), `config/db.js` (poolen), `config/mongo.js` (steg 6), `validation.js`, `repositories/equipmentRepository.js` (OOP-exemplet). De tomma filerna från den gamla uppgiften (routes/, services/, middleware/, kund-/boknings-/rapport-repositories) är borttagna. Servern startas från rotmappen med `node src/server.js` (så att `.env` hittas).

**Beslut om utrustningsrutterna (2026-11-14):**
- **GET** visar hela lagret, även `retired` (status syns på varje artikel). Priset kommer som text (`"350.00"`) eftersom `decimalNumbers: false`: JavaScript kan inte lagra DECIMAL exakt. JSON-svaret med `city` och `category_name` i stället för id:n är **backend↔frontend-exemplet**, kan visas live med curl.
- **POST** tar emot de fem fälten (`category_id`, `depot_id`, `model_name`, `daily_price`, `purchase_date`). `equipment_id` ges av AUTO_INCREMENT och `status` av `DEFAULT 'available'`. Svarar `201` + `equipment_id` (`result.insertId`).
- **PUT** ändrar samma fem fält, **inte status**. Status ändras på andra ställen: `rented` av bokningstransaktionen, `retired` av DELETE (`maintenance` har ingen rutt, se API v2). `WHERE equipment_id=? AND status <> 'retired'`: en retired artikel kan inte ändras. `affectedRows === 0` → `404` ("not found or retired"). En prisändring påverkar inte gamla bokningar (priset ligger på bokningsraden), testat med artikel 4: 450 → 500, bokning 7 räknas fortfarande med 400.
- **DELETE** = **soft delete**: `UPDATE … SET status='retired' WHERE equipment_id=? AND status <> 'retired' AND status <> 'rented'`. Raden ligger kvar, så gamla bokningsrader pekar fortfarande på något som finns. `available` och `maintenance` får tas ur bruk, men inte en artikel som är ute hos en kund. Svarar `200` + `{ equipment_id, status: 'retired' }`, annars `404`. HTTP-metoden (DELETE) beskriver vad klienten vill, SQL-kommandot (UPDATE) hur backend gör det.
- **Statuskoder:** 200 OK, 201 Created, 400 fel data, 404 hittades inte, 409 krock, 500 oväntat fel.
- [ ] Liten rest: stavfel "renter" → "rented" i DELETE-rutten 404-meddelande.
- [ ] JSON-svar och grundläggande skillnad mellan lyckat och misslyckat anrop räcker
- [ ] Fler rutter ger **inte** automatiskt VG. VG = tekniskt väl genomförd SQL och tabellhantering, och att jag använder MySQL och MongoDB självständigt och ändamålsenligt.

---

## Lämna in

- [ ] Källkoden (vidareutvecklas till API v2 i nästa kurs)
- [ ] `database/setup.sql`, `database/seed.sql`, `database/queries.sql`
- [ ] ER-diagram (bild/PDF) + kort text om 3NF, relationer, MongoDB-val och transaktion
- [x] `.env.example` (finns, med övningslösenordet `12345`, se Säkerhet)
- [ ] `README.md` med installation, start/stopp och databasinställningar ("Database settings" klar 2026-11-14, resten TODO)
- [ ] `DATABASE_TESTS.md` med tre körda databasprov inklusive faktiskt resultat (DB-01 + DB-02 klara, DB-03 API-del kvar)
- [ ] Muntlig redovisning enligt `oral_presentation_guide.md` (**har inte setts än, läs den!**)

---

## Öppna frågor att reda ut

- [x] Behövs en egen tabell för bokningshistorik? **Nej.** Bokningarna ligger kvar i bokningstabellen även när de är `returned`/`cancelled`. Historiken är en fråga på kundens id.
- [x] Defaultvärden för status: utrustning `available`, ny bokning `confirmed`.
- [x] Bokningen behöver två sorters datum: när bokningen gjordes (syns t.ex. på en bokningsbekräftelse) och vilka dagar den gäller (start + slut).
- [ ] **Dubbelbokning (steg 5).** Kravet nu: en utrustning som *redan är uthyrd* får inte bokas. Att fundera på: räcker det att titta på `equipment.status`, eller ska du titta på datumen i bokningarna? Vad händer med en bokning som börjar nästa vecka, ska artikeln vara `rented` redan idag?
  - **Fördjupning (VG):** full kontroll av överlappande datum. `UNIQUE` räcker inte: 1–5 dec och 3–8 dec är olika datum men krockar ändå. Rita två intervall på en tidslinje och formulera villkoret för när de överlappar ("om ... och ..."). Det villkoret blir sedan ett `WHERE` i en SQL-fråga. Tänk också på kantdatum: om en bokning slutar 5 dec, kan nästa börja 5 dec?
  - **Beslut 2026-11-14: datummodell + buffertdag.**
    - **Hotellmodellen** gäller (samma som `chk_booking_duration` och `DATEDIFF` i `queries.sql` fråga 4): `start_date` = utlämningsdag, `end_date` = återlämningsdag, antal dygn = `DATEDIFF(end_date, start_date)`. Fredag 4/12 → söndag 6/12 = 2 dygn. Samma dag är inte tillåtet.
    - **Buffertdag:** en ny bokning av samma artikel får starta tidigast **dagen efter** `end_date` på den förra. Bokad t.o.m. 5/12 → nästa kan starta 6/12, inte 5/12.
    - **Varför:** artikeln ska kontrolleras (tillståndsrapport) efter återlämning innan den lämnas ut igen. Lämnas den in sent på kvällen hinner kontrollen inte göras förrän dagen efter.
    - **Att tänka på i steg 5:** buffertregeln gör att även en bokning som börjar *samma dag* som en annan slutar räknas som krock. Det ska synas i villkoret (`<` eller `<=`?).
- [x] Vad är en bokningsrad? Bokningar ↔ utrustning är **N:M**, kopplingstabellen `booking_lines` (`booking_id` FK, `equipment_id` FK) = bokningsraderna. Kunden hänger på bokningen (1:N), inte på raden.
- [x] **`booking_line_id` som PK, behövs den fortfarande?** Beslut 2026-11-13: **ja, eget id (`booking_line_id`) + `UNIQUE (booking_id, equipment_id)`**. Det ursprungliga skälet (MongoDB-rapporten per bokningsrad) försvann när rapporten kopplades till `equipmentId`, men andra skäl finns kvar:
  - En rad kan pekas ut med **ett** id, t.ex. för att avboka enstaka artiklar i en bokning (se Förbättringsförslag) eller söka på en rad.
  - Samma mönster som alla andra tabeller i schemat (eget `_id`) och som lärarens `demo_loan_lines` från lektionen.
  - Ändras regeln (två av samma artikel i en bokning) räcker det att ta bort `UNIQUE`, PK:n behöver inte bytas.
  - **Att komma ihåg:** `UNIQUE`-paret måste finnas, annars skyddar inget mot dubbletter. Alternativet (paret som PK) hade skyddat med en enda regel, men gjort det krångligare att peka ut en rad.
- [x] `UNIQUE KEY (booking_id, equipment_id)` så samma artikel inte står två gånger i samma bokning.
- [x] Dygnspriset sparas på bokningsraden vid bokningstillfället, så gamla bokningar inte ändras när utrustningens pris ändras. **Motivering till redovisningen (varför det inte är dubbellagring som bryter mot 3NF):** `booking_lines` har priset som *gällde när kunden gjorde bokningen* (historik), `equipment` har *det aktuella priset* för artikeln. Det är två olika uppgifter, inte en kopia av samma, även om de råkar ha samma värde just när bokningen görs.
- [x] Datumintervallet ligger på **bokningen**: uppgiften säger "en eller flera artiklar för ett datumintervall". Olika datum = två bokningar. Ger också bara ett intervall per bokning att kontrollera vid överlapp.
- [x] Totalpriset sparas **inte** i `bookings` (variant B). Det räknas fram vid läsning: `SUM` av dygnspriset i `booking_lines` × antal dygn, med JOIN + `GROUP BY`. **Motivering till redovisningen:** en sparad total är härledd ur andra kolumner och kan hamna ur takt med raderna (t.ex. om enstaka artiklar avbokas i framtiden). Utan totalkolumn kan den aldrig bli fel, och schemat håller sig strikt till 3NF. Samma beräkning (pris × dygn) behövs till top earners i `queries.sql`. **Nytt att lära:** MySQL-funktion för antal dagar mellan två datum.
- [x] MongoDB: vad betyder "schemaflexibel" och "nästlad", och hur ser ett rapportdokument ut? **Schemaflexibel** = varje dokument har bara de fält det behöver. **Nästlad** = ett värde kan vara ett objekt i sig. Checklistan passar dåligt i MySQL eftersom alla rader i en tabell har samma kolumner (många `NULL` eller en tabell per kategori). Se "Beslut och insikter" under Tillståndsrapporter.
- [x] **Texten om MySQL vs MongoDB (steg 1):** skriven 2026-11-11 med mina egna formuleringar, översatt till README ("MySQL vs MongoDB"). Fyra stycken:
  1. Vad rapporten är
  2. Varför dokument (olika fält per kategori, fält utelämnas, exemplet med en ny kategori: SUP-brädor, tidigare skidor)
  3. Varför bokningarna ligger i MySQL (datum för vad som är uthyrt och när, FK till `booking_lines`, transaktion: allt eller inget)
  4. Avvägningen (databasen stoppar inte fel data, backend validerar och kontrollerar `equipmentId` mot MySQL)
- [ ] Att fundera på: artiklar raderas aldrig, de sätts till `retired`. Vad betyder det för rapporter som redan finns om en artikel? Kan de bli "föräldralösa"?
- [x] **Backend ↔ frontend:** ✅ Svar från läraren 2026-11-13:
  - **JOIN-exemplet är rätt.** `equipment` lagrar bara `category_id` och `depot_id` (siffror), men en frontend vill visa "Kajak" och "Umeå". Backend hämtar namnen med JOIN mot `categories` och `depots` och skickar tillbaka JSON som frontend kan visa.
  - **MongoDB-exemplet** (checklistefält per kategori) fungerar också, men behövs inte. Gör det inte mer komplicerat än nödvändigt.
  - **Var:** en kort förklaring i texten som lämnas in med ER-diagrammet, **inte** som kommentar i `setup.sql`.
  - **Ingen frontend** ska byggas. Läraren testar API-anropen i terminalen (curl). Det räcker att visa att backend hämtar rätt information och svarar med JSON.
  - Att fundera på: vilken av de 7 rutterna visar sambandet, och vilka tabeller och kolumner behöver frågan? Kan visas live med curl på redovisningen.
- [x] Vad händer med en kunds gamla bokningar om kunden tas bort? **Beslut: RESTRICT + anonymisering.** ✅ Godkänt av läraren 2026-11-05. Det finns ingen kundrutt i den nya uppgiften, så anonymiseringen byggs **inte** som rutt nu (sparad till API v2, se nedan). Den används fortfarande som **motivering** till `ON DELETE RESTRICT` på `bookings.customer_id` och till kolumnen `deleted_at`. Villkoren från läraren:
  1. Kontrollera först att kunden inte har några aktiva bokningar.
  2. Finns aktiva bokningar nekas borttagningen (`409`).
  3. Finns bara avslutade/avbokade bokningar anonymiseras personuppgifterna och bokningshistoriken bevaras.
  4. Dokumentera tydligt i README varför lösningen valts.
  - **Viktigt enligt läraren:** anonymiseringen måste verkligen ta bort personuppgifterna, så att kunden inte går att identifiera genom det som finns kvar.
  - [x] "Aktiva" bokningar = `confirmed` + `active` (bokningar som inte är avslutade). `returned` + `cancelled` = avslutade, och då får kunden anonymiseras.
  - [x] **Vilka uppgifter tas bort vid anonymisering?** Beslut 2026-11-13: **förnamn, efternamn, e-post och telefon** sätts alla till `NULL`. Samma regel för alla fyra: de krävs bara så länge kunden är aktiv. Därför `NULL` och inte en ersättningstext som `'Deleted'`: e-posten är `UNIQUE`, så två kunder kan inte få samma ersättningstext, och med `NULL` räcker ett enda `CHECK` för alla fyra.
  - [x] Motiveringen ligger i README under "Customer deletion policy". Granskas igen i steg 7.
  - [x] E-post vid anonymisering: sätts till `NULL`. `UNIQUE` ligger kvar, eftersom MySQL tillåter flera `NULL` i en `UNIQUE`-kolumn (NULL är "okänt" och två okända räknas inte som lika). E-posten får alltså inte vara `NOT NULL`. I stället ett `CHECK`-villkor: e-post måste vara ifylld *om inte* kunden är borttagen (`deleted_at`). Testa NULL+UNIQUE i en testtabell först. Telefon: **ja**, samma regel (beslut 2026-11-13).
  - [x] Ny kolumn `deleted_at` i `customers`: tom (`NULL`) = aktiv kund, ett datum = när kunden togs bort.
  - [x] Datatyp för `deleted_at`: **`DATETIME`** (beslut 2026-11-13), samma typ som `created_at` i `bookings`, så att tidpunkterna är konsekventa. Inget `DEFAULT` behövs: en kolumn utan `NOT NULL` blir `NULL` om inget värde anges, och `NULL` = aktiv kund.

---

## Sparat till API v2 (nästa kurs)

Krävs inte i den här kursen. Sparas så att idéerna inte försvinner.

- Kundrutter: `GET /api/customers` (paginerat, `WHERE deleted_at IS NULL`), `GET /api/customers/:id`, `POST`, `PUT`, `GET /api/customers/:id/bookings`
- `DELETE /api/customers/:id` med anonymisering, plus testfallen:
  - **TC-ANON-01:** kund med bara avslutade bokningar → `204`, personuppgifter borta, `deleted_at` satt, syns inte i listan, bokningarna finns kvar och statistiken är oförändrad
  - **TC-ANON-02:** kund med en aktiv bokning → `409`, kundraden oförändrad
- `GET /api/equipment/:id`, filter på kategori/stad/status, `GET /api/equipment/top-earners`
- `GET /api/bookings/:id`, `PATCH /api/bookings/:id/return` (MySQL + MongoDB), `PATCH /api/bookings/:id/cancel`
- `GET /api/reports/damaged`
- En rutt för att ändra en artikels status, t.ex. till `maintenance` (PUT ändrar bara uppgifterna, inte tillståndet)
- Validering som säger **vilket** fält som var fel (`validEquipment` returnerar en lista med fel i stället för true/false)
- Fler MySQL-felkoder i `dbFailure`, t.ex. ogiltigt datum som `2026-13-45` (passerar regexen men stoppas av MySQL) och `ER_TABLEACCESS_DENIED_ERROR`
- Konsekventa HTTP-felsvar (400/404/409/500), gemensam felmodell, validering i middleware, API-testsvit

## Förbättringsförslag (utanför uppgiftens krav)

- [ ] Arkiv-endpoint för personal som visar borttagna kunder (de med `deleted_at`) och deras bokningshistorik.
- [ ] Personal i tillståndsrapporten: vem som gjorde kontrollen (namn/id). Krävs inte i uppgiften.
- [ ] Avboka enstaka artiklar i en bokning (t.ex. en av fyra kajaker): ta bort/markera raden och se till att totalpriset stämmer efteråt.
- [ ] Gallring av gamla bokningar: ska avslutade bokningar ligga kvar för alltid, arkiveras eller anonymiseras efter en viss tid (t.ex. med tanke på GDPR)?
