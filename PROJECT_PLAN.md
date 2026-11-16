# NordicRent — Projektplan

**Presentation:** 2026-11-19 (torsdag) · **Inlämning:** 2026-11-22 · **Mål:** VG

> Uppdaterad 2026-11-09 efter lärarens nya version av uppgiften. Den nya versionen har färre API-rutter och fokuserar på databasen: SQL, transaktion, databasprov och MongoDB. Det som inte längre krävs finns under [Sparat till API v2](#sparat-till-api-v2-nästa-kurs).
>
> **Senast uppdaterad 2026-11-16 (måndag förmiddag):** **alla 7 rutter klara.** Steg 1–6 klara (utom ER-export). Kvar: dokumentation, kommentarer och förberedelse inför redovisningen, se [Kvar att göra](#kvar-att-göra).

---

## Kvar att göra

**Före redovisningen (torsdag 19/11):**
- [ ] **Manus** utifrån `oral_presentation_guide.md` (se tabellen nedan). Tis–ons.
- [ ] **Öva på lärarens frågor** (se nedan), med egna ord.
- [ ] **Kommentarer i koden: gå igenom tillsammans** (också till API v2, så jag kommer ihåg varför). Förslag på var:
  - `src/server.js`: `dbFailure` (varför 400/409/500), bokningstransaktionen (`getConnection` i stället för `pool.execute`, varför krockfrågan körs före INSERT, `INSERT … SELECT` för priset, `affectedRows === 0` → rollback), `POST /api/reports` (varför MySQL-kollen först: ingen FK mellan databaserna), GET-rapporter (`Number()` eftersom `req.params` alltid är text, 200 med `[]`)
  - `src/validation.js`: en rad per funktion om varför (max 10 artiklar, `Set` mot dubbletter, `length >= 1` före `every` eftersom `every` på `[]` alltid är `true`)
  - `src/repositories/equipmentRepository.js`: vad klassen ansvarar för (bara databasen, ingen HTTP), vad varje metod returnerar, soft delete i `retire`
  - `database/setup.sql`: kort motivering vid varje `ON DELETE` och `CHECK`
  - `database/queries.sql`: rubrik på de två transaktionsexemplen längst ner (ROLLBACK resp. COMMIT)
- [ ] **ER-diagrammet som bild/PDF** (`docs/`), behövs för demopunkt 1.
- [ ] **Testa sorteringen i GET-rapporter:** skicka två rapporter för samma artikel, kolla att den nyaste kommer först.
- [ ] **Bestämma om `SHOW GRANTS` sist i `setup.sql` ska vara kvar** (visar rättigheterna, men är ingen del av schemat).
- [ ] **Bestämma hur resultaten i `queries.sql` ska visas** (fråga läraren: skärmdump, README eller kommentar).
- [ ] **Commit + push** av dagens ändringar (rapportrutterna och formateringen).

**Före inlämning (söndag 22/11):**
- [ ] **Inlämningstexten med ER-diagrammet:** 3NF, relationer, MongoDB-val, transaktion, backend↔frontend (JOIN-exemplet).
- [ ] **README, TODO-sektionerna:** Tech stack, Installation, Environment variables, Starting and stopping, Setting up and resetting, Example requests (curl), 3NF-beroenden, Backend and frontend, SQL queries, Transaction design, Error handling, Object-oriented design, Security.
- [ ] **DATABASE_TESTS.md (valfritt):** ett DB-08 för MongoDB (POST 201/404/400 + GET), resultaten finns från 2026-11-16.
- [ ] **ZIP eller GitHub-länk**, kolla att `.env` och `node_modules/` inte är med.

### Redovisningen enligt `oral_presentation_guide.md` (läst 2026-11-16)

Fokus: databaserna och min egen kod. Inte API-dokumentation, testsvit, middleware, Promises eller deployment (= API v2).

| # | Visa | Vad jag har |
|---|---|---|
| 1 | ER-diagram och 3NF | `docs/er-diagram.md` (PDF kvar), "Utkast: varför varje tabell finns" nedan |
| 2 | En JOIN och två nästlade frågor | `queries.sql` fråga 1, 3 och 4 |
| 3 | Parameteriserad CRUD | utrustningsrutterna + `EquipmentRepository` (`?` överallt) |
| 4 | Bokningstransaktion: COMMIT + avsiktlig ROLLBACK | `POST /api/bookings`, DB-03 (fall A/F/G), DB-07 (H/I/K) |
| 5 | Ett MongoDB-dokument | rapporten för artikel 1 i `condition_reports` (VS Code) |
| 6 | Ett litet Express-anrop mot databasen | `GET /api/equipment` med curl (också backend↔frontend-exemplet) |
| 7 | Ett databastest och varför resultatet är korrekt | DB-01, DB-02 eller DB-03 |

Berätta också: hur backend och frontend hänger ihop (JOIN → JSON med namn i stället för id), och hur en klass används för databasåtkomst (`EquipmentRepository`).

**Frågor att öva på:**
- Varför normaliserade du den här tabellen?
- Vilken constraint skyddar data? Vad skyddar `?` i SQL?
- Vad återställs vid ROLLBACK?
- Varför passar rapporten i MongoDB?
- Kan du förklara och visa din egen kod?

---

## Roadmap (uppgiftens 7 steg)

- [x] **Steg 1 – Planera datamodellen:** ER-diagram, samband, 3NF, vad som ska ligga i MongoDB
  - [ ] Kvar: exportera ER-diagrammet till bild/PDF + skriva den korta texten (3NF, relationer, MongoDB-val, transaktion, backend↔frontend)
- [x] **Steg 2 – Implementera MySQL:** `setup.sql` + `seed.sql`, testa constraints och JOINs, installationen går att köra om (`setup.sql` → `seed.sql` återställer allt)
- [x] **Steg 3 – Visa SQL-kunskaper:** `database/queries.sql` med 4 frågor (JOIN 3 tabeller, GROUP BY, 2 nästlade) + kommentarer om vad varje fråga svarar på
  - [ ] Kvar: fråga läraren hur resultaten ska "visas" (skärmdump, text i README eller kommentar i filen?)
- [x] **Steg 4 – Express-koppling:** servern startar, ansluter med `mysql2` som appanvändaren, alla fyra utrustningsrutterna klara med `?`-parametrar, validering och felhantering (2026-11-14)
  - [x] OOP-klassen `EquipmentRepository` klar 2026-11-14 kväll (all utrustnings-SQL flyttad dit)
- [x] **Steg 5 – Bokningstransaktionen:** `POST /api/bookings` som riktig transaktion, visa att rollback tar bort alla delresultat (2026-11-15)
  - [x] Validering (`validBooking`), bokning + rader med prissnapshot, rollback vid artikel som saknas/inte går att boka (409), dubbelbokning med buffertdag (409). Testat i DB-03 (API-delen) och DB-07.
- [x] **Steg 6 – MongoDB:** spara och läsa tillståndsrapporter via de två rapportrutterna, motivera varför de passar som dokument (klart 2026-11-16)
  - [x] Del 1: `src/config/mongo.js` (en klient, `connectMongo`, `reportsCollection`, `closeMongo`), databas `nordicrent_docs`, collection `condition_reports` (2026-11-15)
  - [x] Del 2: `connectMongo()` i `start()` och `closeMongo()` vid startfel. Testat: med Mongo igång startar servern, med `mongod stop` vägrar den starta (`ECONNREFUSED 127.0.0.1:27017` efter ca 45 s) i stället för att köra halvt
  - [x] Del 3: `POST /api/reports` (2026-11-16). `validReport` → `equipmentRepository.findById(req.body.equipmentId)` (ny metod, `status <> 'retired'`) → 404 om artikeln saknas eller är retired → `insertOne` → `201` + `report_id`. Testat: A 201, B (999) 404, C (12, retired) 404, D (`checklist: {}`) 400, E (`damageFlag: "yes"`) 400.
  - [x] Del 4: `GET /api/reports/equipment/:id` (2026-11-16). `positiveId` → `find({ equipmentId: Number(...) }).sort({ createdAt: -1 }).toArray()`. Testat: 1 → 200 med rapporten, 2 → 200 med `[]`, `abc` → 400.
  - [x] Småfix: bara en `console.error` kvar i `.catch` i `start()`
- [ ] **Steg 7 – Kontroll och presentation:** tre databasprov i `DATABASE_TESTS.md` (klara), README med start/stopp och databasinställningar, träna på att förklara SQL- och dataval ← **NU**
  - [x] Koden formaterad 2026-11-16 (indrag, semikolon, mellanslag), ingen logik ändrad

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
- [x] En utrustning som redan är uthyrd får inte bokas igen (krav). Full kontroll av överlappande datum = fördjupning (VG), gjord 2026-11-15, se Öppna frågor och DB-07.
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
- [x] Rapporten gäller en **utrustning**: `equipmentId` (inte bokningsraden längre)
- [x] `equipmentId` är en applikationsreferens, **inte** en främmande nyckel. MongoDB vet inte om att artikeln finns i MySQL, så det är appen som ansvarar för att id:t stämmer.
- [x] `notes`: fritextanteckningar
- [x] `checklist`: checklista som skiljer sig per kategori, t.ex.:
  - kajak: skrov, paddlar
  - elcykel: batterihälsa, chassi
  - tält: duk, tältpinnar, allt material inlämnat
- [x] `damageFlag`: skadeflagga
- [ ] Eventuella foto-URL:er (valfritt, inte krav längre, inte gjort). Bilden sparas inte i databasen, bara en **länk** (URL). Kan vara flera bilder → en lista med URL:er.
- [x] MySQL och MongoDB behöver **inte** ingå i samma transaktion

**Beslut 2026-11-16 (`validReport`, alla fyra fält obligatoriska):**
- **`equipmentId`** (uppgiftens namn). I MySQL heter kolumnen fortfarande `equipment_id`. Namnen möts i rutten: `findById(req.body.equipmentId)`.
- **`checklist` är ett objekt** med true/false, t.ex. `{ "hull": true, "paddle": false }`. Valt i stället för en lista med texter eftersom objektet visar både *vad* som kontrollerades och *hur det gick* (att paddeln saknas syns). Valideras med `isObject` → `Object.values(...).length >= 1` → `Object.values(...).every(item => typeof item === 'boolean')`. Längdkollen måste ligga före och utanför `every`: `every` på en tom lista blir alltid `true`, så `{}` hade annars godkänts.
- **`damageFlag`** är en boolean (en flagga: ja/nej). *Vilken* skada står i `notes`, *vilken del* i `checklist`. Obligatorisk, eftersom en rapport utan flagga inte säger om artikeln är skadad eller om ingen kollade.
- **Ingen rapport för en `retired` artikel:** den finns inte längre i depån.
- **`createdAt: new Date()`** sätts av backend, används för sortering (nyast först). Sparas i UTC.
- **Felhantering:** `catch` svarar 500 utan `dbFailure`, eftersom en `SELECT` inte kan bryta mot constraints. 400 vore fel: det är inte klientens fel om en databas kraschar.
- **Lärdomar:** fel fältnamn i `find` (`equipment_id`) kraschar inte, Mongo returnerar bara `[]` (schemalöst). `NumberInt` i VS Code är bara hur skalet visar ett heltal, ingen JS-funktion. `req.params` finns bara för `:id` i URL:en, i en POST ligger datan i `req.body`.

**Beslut och insikter (2026-11-11):**
- Rapporterna finns **bara** i MongoDB. Ingen tabell för rapporter i `setup.sql`.
- Checklistan beror på artikelns **kategori** (från `categories` i MySQL), inte på den enskilda artikeln. Cykel och elcykel kan vara samma kategori: en vanlig cykels rapport har då helt enkelt inget fält för batterihälsa.
- Fält som inte behövs **utelämnas helt** i dokumentet. De står inte som `NULL` (som en tom kolumn i MySQL hade gjort).
- Nästlat värde, t.ex. tältpinnar: `pinnar: { skick: "ok", antal: 7 }` (ett objekt inuti ett objekt).
- Ny kategori (t.ex. SUP-brädor; skidor finns redan i seed-datan sedan 2026-11-13): i MySQL hade checklistan krävt en ny tabell eller nya kolumner. I MongoDB ändras ingenting i databasen, bara valideringen i Express.
- **Strukturen ("mallen") finns i Express, inte i MongoDB.** MongoDB sparar det den får. I MySQL ansvarar databasen för strukturen, i MongoDB ansvarar backend.
- Validering vid `POST /api/reports`, i `src/validation.js` (`validReport`, klar 2026-11-16, se beslut ovan):
  - [x] ~~Att reda ut i del 3: `equipment_id` eller `equipmentId`, lista eller objekt~~ → `equipmentId` + objekt.
  - **Grund (krav, klart):** `equipmentId` finns i MySQL (backend frågar MySQL först, eftersom det inte finns någon FK), `damageFlag` är true/false, `checklist` är ett objekt. Fel → svara med fel och spara inget.
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
- [x] `?`-parametrar för **alla** SQL-värden som kommer från API-anrop (alla rutter klara 2026-11-16)

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
- [x] Skapandet av en bokning sker i en transaktion: bokningen och dess rader lyckas eller misslyckas som en helhet (2026-11-15)
  - **Ingen statusuppdatering av utrustningen** vid bokning: tillgänglighet avgörs av datumen (överlappskollen), inte av `equipment.status`. En bokning nästa vecka ska inte göra artikeln `rented` redan idag. Att sätta `rented`/`available` vid utlämning och återlämning hör till API v2 (return-flödet).
- [x] Visa en **COMMIT** (allt sparas): DB-03 + DB-07, fall A och J
- [x] Visa en **avsiktlig ROLLBACK** (ett steg misslyckas, och inga halvfärdiga bokningsrader blir kvar): DB-03 fall F/G, DB-07 fall H/I/K
- [x] Förhindra dubbelbokning: full överlappskontroll med buffertdag (fördjupning), se Öppna frågor och DB-07
- [x] COMMIT + ROLLBACK visade i SQL (DB-03, 2026-11-14) och via API (2026-11-15).
- [x] **En egen anslutning** för hela transaktionen: `pool.getConnection()` före `try`, `beginTransaction()`, alla frågor på `connection.execute`, `commit()` sist i `try`, `rollback()` i `catch`, `release()` i `finally`. **Varför inte `pool.execute`?** Poolen är flera anslutningar ("kassor"). Varje `pool.execute` kan hamna på en annan anslutning, och en transaktion finns bara på den anslutning som startade den. Rollback på anslutning 2 ångrar inte det som hände på anslutning 4.
- [x] **Två sorters fel i rutten:** MySQL-fel (t.ex. kund 999 → 1452) kastas, hamnar i `catch` och översätts av `dbFailure`. Egna kontroller (`affectedRows === 0`, `conflicts.length > 0`) är inga MySQL-fel, så rutten kör `rollback()` och svarar 409 direkt, samma mönster som PUT (`affectedRows === 0` → 404). `finally` släpper anslutningen i alla fall.
- [x] **Priset till bokningsraden med `INSERT … SELECT`** (från `equipment.daily_price`): priset går MySQL → MySQL och passerar aldrig JavaScript (ingen sträng/Number-omvandling), och klienten kan inte skicka in ett eget pris.
- [x] **Kolla `affectedRows` efter varje INSERT/UPDATE i transaktionen.** Fälla: `INSERT … SELECT … WHERE equipment_id = 99` för en artikel som inte finns ger **inget fel**. SELECT:en hittar 0 rader, så 0 rader läggs in, och FK:n får aldrig något att stoppa. Om `affectedRows` är 0 måste backend själv köra ROLLBACK, annars blir det en bokning utan rader. Samma idé som `ROW_COUNT()` i SQL (`~/sql-kurs/2026-11-09`, fil 03) och lektionens `WHERE status = 'open'`-vakt.

### Felhantering och databasprov
- [x] Databasspecifik felhantering: `dbFailure(error, res)` i `server.js` (2026-11-14) känner igen MySQL:s `error.code` och svarar med JSON:
  - **400** (klienten skickade fel data): `ER_CHECK_CONSTRAINT_VIOLATED` (3819), `ER_NO_REFERENCED_ROW_2` (1452)
  - **409** (krock med det som redan finns): `ER_DUP_ENTRY` (1062), `ER_ROW_IS_REFERENCED_2` (1451)
  - **500** för allt annat. Klienten får bara ett allmänt meddelande, detaljerna loggas i serverterminalen (`console.error` med rutten först).
- [x] **Validering i två lager** (2026-11-14):
  - **Lager 1, `src/validation.js`:** körs före `try`, stoppar fel data med 400 innan MySQL nås. `positiveId`, `isObject`, `validDate` (egen hjälpfunktion, återanvänds i bokningar), `validEquipment` (id:n positiva heltal, `model_name` 1–80 tecken, pris ett tal 0–99999.99, datum `ÅÅÅÅ-MM-DD`).
  - **Lager 2, constraints i MySQL + `dbFailure`:** reservskydd (defense in depth) om valideringen missar något. Prisregeln i JS är samma som CHECK:en (`>= 0`, gratis artiklar som hjälm tillåts).
- [x] **`validBooking`** (2026-11-15). Body: `{ "customer_id": 1, "start_date": "2026-11-20", "end_date": "2026-11-22", "equipment_ids": [3, 7] }`
  - `status` och `created_at` skickas inte av klienten, databasen sätter dem med DEFAULT.
  - Inget pris i body:n: priset kopieras från `equipment` i backend (prissnapshot), så klienten kan inte välja ett eget pris.
  - `equipment_ids` är en lista eftersom en bokning kan ha flera artiklar (1:N mellan `bookings` och `booking_lines`).
  - **Max 10 artiklar per bokning, eget val:** realistiskt för en kunds bokning (ingen depå har 10 artiklar i seed-datan) och ett skydd mot överbelastning. En lista med t.ex. 100 000 id:n stoppas med 400 innan servern gör en enda databasfråga.
  - **Dubbletter stoppas:** `new Set(equipment_ids.map(Number)).size === equipment_ids.length`. `map(Number)` behövs för att `3` och `"3"` annars räknas som olika värden. Utan regeln hade `uq_booking_equipment` gett 1062 inne i transaktionen.
  - **`end_date > start_date`** står sist, efter `validDate`, så att båda redan är giltiga strängar. Samma regel som `chk_booking_duration`, med CHECK:en som reservskydd.
- [x] Tre dokumenterade databasprov i `DATABASE_TESTS.md`, med förväntat och faktiskt resultat:
  1. [x] läsning/JOIN (DB-01, 2026-11-14)
  2. [x] ett constraint-fel (DB-02, SQL 2026-11-13 + API 2026-11-14: negativt pris och okänd kategori → 400)
  3. [x] rollback utan halvfärdiga bokningsrader (DB-03: SQL 2026-11-14, API 2026-11-15)
  - Extra: DB-04 (anonymisering), DB-05 (bookings-constraints), DB-06 (booking_lines-constraints), DB-07 (överlapp)
  - Valfritt: DB-08 för MongoDB-rutterna (testerna från 2026-11-16 finns, se steg 6)

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
| POST | `/api/bookings` | MySQL-transaktion med booking + booking_lines | ✅ 2026-11-15 |
| POST | `/api/reports` | Spara ett MongoDB-dokument | ✅ 2026-11-16 |
| GET | `/api/reports/equipment/:id` | Hämta MongoDB-dokument | ✅ 2026-11-16 |

- [x] Valfritt: `GET /api/health` (räknas inte till de sju)

**Struktur (beslut 2026-11-14):** förenklad, nära lärarens `school_api`. Kvar i `src/`: `server.js` (alla rutter + `dbFailure`), `config/db.js` (poolen), `config/mongo.js` (steg 6), `validation.js`, `repositories/equipmentRepository.js` (OOP-exemplet). De tomma filerna från den gamla uppgiften (routes/, services/, middleware/, kund-/boknings-/rapport-repositories) är borttagna. Servern startas från rotmappen med `node src/server.js` (så att `.env` hittas).

**Beslut om utrustningsrutterna (2026-11-14):**
- **GET** visar hela lagret, även `retired` (status syns på varje artikel). Priset kommer som text (`"350.00"`) eftersom `decimalNumbers: false`: JavaScript kan inte lagra DECIMAL exakt. JSON-svaret med `city` och `category_name` i stället för id:n är **backend↔frontend-exemplet**, kan visas live med curl.
- **POST** tar emot de fem fälten (`category_id`, `depot_id`, `model_name`, `daily_price`, `purchase_date`). `equipment_id` ges av AUTO_INCREMENT och `status` av `DEFAULT 'available'`. Svarar `201` + `equipment_id` (`result.insertId`).
- **PUT** ändrar samma fem fält, **inte status**. Status ändras på andra ställen: `rented` av bokningstransaktionen, `retired` av DELETE (`maintenance` har ingen rutt, se API v2). `WHERE equipment_id=? AND status <> 'retired'`: en retired artikel kan inte ändras. `affectedRows === 0` → `404` ("not found or retired"). En prisändring påverkar inte gamla bokningar (priset ligger på bokningsraden), testat med artikel 4: 450 → 500, bokning 7 räknas fortfarande med 400.
- **DELETE** = **soft delete**: `UPDATE … SET status='retired' WHERE equipment_id=? AND status <> 'retired' AND status <> 'rented'`. Raden ligger kvar, så gamla bokningsrader pekar fortfarande på något som finns. `available` och `maintenance` får tas ur bruk, men inte en artikel som är ute hos en kund. Svarar `200` + `{ equipment_id, status: 'retired' }`, annars `404`. HTTP-metoden (DELETE) beskriver vad klienten vill, SQL-kommandot (UPDATE) hur backend gör det.
- **Statuskoder:** 200 OK, 201 Created, 400 fel data, 404 hittades inte, 409 krock, 500 oväntat fel.
- [x] Liten rest: stavfel "renter" → "rented" i DELETE-rutten 404-meddelande (rättat).
- [ ] JSON-svar och grundläggande skillnad mellan lyckat och misslyckat anrop räcker
- [ ] Fler rutter ger **inte** automatiskt VG. VG = tekniskt väl genomförd SQL och tabellhantering, och att jag använder MySQL och MongoDB självständigt och ändamålsenligt.

---

## Lämna in

- [ ] Källkoden (vidareutvecklas till API v2 i nästa kurs)
- [ ] `database/setup.sql`, `database/seed.sql`, `database/queries.sql`
- [ ] ER-diagram (bild/PDF) + kort text om 3NF, relationer, MongoDB-val och transaktion
- [x] `.env.example` (finns, med övningslösenordet `12345`, se Säkerhet)
- [ ] `README.md` med installation, start/stopp och databasinställningar ("Database settings" klar 2026-11-14, resten TODO)
- [x] `DATABASE_TESTS.md` med tre körda databasprov inklusive faktiskt resultat (DB-01–03 klara + extra DB-04–07)
- [ ] Muntlig redovisning enligt `oral_presentation_guide.md` (läst 2026-11-16, se [Kvar att göra](#kvar-att-göra))

---

## Öppna frågor att reda ut

- [x] Behövs en egen tabell för bokningshistorik? **Nej.** Bokningarna ligger kvar i bokningstabellen även när de är `returned`/`cancelled`. Historiken är en fråga på kundens id.
- [x] Defaultvärden för status: utrustning `available`, ny bokning `confirmed`.
- [x] Bokningen behöver två sorters datum: när bokningen gjordes (syns t.ex. på en bokningsbekräftelse) och vilka dagar den gäller (start + slut).
- [x] **Dubbelbokning (steg 5, klart 2026-11-15).** Kravet nu: en utrustning som *redan är uthyrd* får inte bokas. Att fundera på: räcker det att titta på `equipment.status`, eller ska du titta på datumen i bokningarna? Vad händer med en bokning som börjar nästa vecka, ska artikeln vara `rented` redan idag?
  - **Fördjupning (VG):** full kontroll av överlappande datum. `UNIQUE` räcker inte: 1–5 dec och 3–8 dec är olika datum men krockar ändå. Rita två intervall på en tidslinje och formulera villkoret för när de överlappar ("om ... och ..."). Det villkoret blir sedan ett `WHERE` i en SQL-fråga. Tänk också på kantdatum: om en bokning slutar 5 dec, kan nästa börja 5 dec?
  - **Beslut 2026-11-14: datummodell + buffertdag.**
    - **Hotellmodellen** gäller (samma som `chk_booking_duration` och `DATEDIFF` i `queries.sql` fråga 4): `start_date` = utlämningsdag, `end_date` = återlämningsdag, antal dygn = `DATEDIFF(end_date, start_date)`. Fredag 4/12 → söndag 6/12 = 2 dygn. Samma dag är inte tillåtet.
    - **Buffertdag:** en ny bokning av samma artikel får starta tidigast **dagen efter** `end_date` på den förra. Bokad t.o.m. 5/12 → nästa kan starta 6/12, inte 5/12.
    - **Varför:** artikeln ska kontrolleras (tillståndsrapport) efter återlämning innan den lämnas ut igen. Lämnas den in sent på kvällen hinner kontrollen inte göras förrän dagen efter.
    - **Att tänka på i steg 5:** buffertregeln gör att även en bokning som börjar *samma dag* som en annan slutar räknas som krock. Det ska synas i villkoret (`<` eller `<=`?).
  - **Härlett 2026-11-15: överlappsvillkoret** (mitt eget resonemang, till manuset)
    - **Vad är det som inte får hända?** Att en **artikel** är utlånad två gånger samtidigt. En kund får ha flera bokningar med samma datum (t.ex. kajak på förmiddagen, tält på eftermiddagen). Därför räcker inte `bookings` ensam: artikeln står i `booking_lines`, datumen och statusen i `bookings` → JOIN på `booking_id`.
    - **Vilka bokningar blockerar?** Bara `confirmed` och `active`. `returned` är redan tillbaka, `cancelled` blev aldrig av.
    - **Tidslinje** (befintlig bokning 20–22 nov):

      | Ny bokning | Resultat | Varför |
      |---|---|---|
      | 18–19 | ok | helt före |
      | 18–20 | krock | slutar samma dag som den befintliga börjar |
      | 20–22 | krock | samma datum |
      | 22–24 | krock | börjar samma dag som den befintliga slutar (buffertdag) |
      | 23–25 | ok | helt efter |
      | 18–25 | krock | omsluter den befintliga |

    - **Ok** = helt före **eller** helt efter: `ny end_date < b.start_date` **OR** `ny start_date > b.end_date`. `<` och `>` (inte `<=`/`>=`) ger buffertdagen: samma dag räknas som krock.
    - **Krock** = motsatsen, varken helt före eller helt efter. När villkoret vänds blir `<` till `>=`, `>` till `<=` och `OR` till `AND`: `ny end_date >= b.start_date` **AND** `ny start_date <= b.end_date`.
    - I SQL skrivs det med kolumnen först: `b.start_date <= ny end_date AND b.end_date >= ny start_date`.
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
