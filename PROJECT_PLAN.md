# NordicRent — Projektplan

**Presentation:** 2026-11-20 · **Inlämning:** 2026-11-22 · **Mål:** VG

> Uppdaterad 2026-11-09 efter lärarens nya version av uppgiften. Den nya versionen har färre API-rutter och fokuserar på databasen: SQL, transaktion, databasprov och MongoDB. Det som inte längre krävs finns under [Sparat till API v2](#sparat-till-api-v2-nästa-kurs).

---

## Roadmap (uppgiftens 7 steg)

- [ ] **Steg 1 – Planera datamodellen:** ER-diagram, samband, 3NF, vad som ska ligga i MongoDB
- [ ] **Steg 2 – Implementera MySQL:** `setup.sql` + `seed.sql`, testa constraints och JOINs, installationen går att köra om
- [ ] **Steg 3 – Visa SQL-kunskaper:** `database/queries.sql` med nästlade frågor, JOIN och GROUP BY, och en förklaring av vad varje fråga svarar på
- [ ] **Steg 4 – Express-koppling:** starta servern, anslut med `mysql2`, bygg de fyra utrustningsrutterna med `?`-parametrar
- [ ] **Steg 5 – Bokningstransaktionen:** `POST /api/bookings` som riktig transaktion, visa att rollback tar bort alla delresultat
- [ ] **Steg 6 – MongoDB:** spara och läsa tillståndsrapporter via de två rapportrutterna, motivera varför de passar som dokument
- [ ] **Steg 7 – Kontroll och presentation:** tre databasprov i `DATABASE_TESTS.md`, README med start/stopp och databasinställningar, träna på att förklara SQL- och dataval

---

## Domänen

### Kunder (`customers`)
- [ ] Tabell för kunder med id, namn, e-post och telefonnummer
- [ ] E-post är unik
- [ ] `deleted_at` för anonymiserade kunder (se Öppna frågor)
- [ ] Namn i två kolumner: `first_name` + `last_name` (slås ihop med `CONCAT(...) AS name` när de ska visas)
- [ ] **Personuppgifter** = `first_name`, `last_name`, `email`, `phone`. De får **inte** vara `NOT NULL`, eftersom alla fyra sätts till `NULL` vid anonymisering.
- [ ] Ett `CHECK`: om `deleted_at` är `NULL` (aktiv kund) måste alla fyra personuppgifter vara ifyllda

### Depåer (`depots`)
- [ ] Tabell för depåer med id, namn, stad och adress
- [ ] Relation depå → utrustning är 1:N
- [ ] En artikel tillhör exakt en depå åt gången

### Kategorier (`categories`)
- [ ] Egen tabell för kategorier (inte fritext)
- [ ] Varje kategori har namn och beskrivning
- [ ] `category_id` som PK (inte namnet, så ett namnbyte bara ändrar en rad), namnet `UNIQUE` + `NOT NULL`

### Utrustning (`equipment`)
- [ ] Tabell för utrustning med id, kategori, modellnamn, dygnspris och inköpsdatum
- [ ] Status som ENUM: `available`, `rented`, `maintenance`, `retired`
- [ ] Kopplad till en kategori
- [ ] Kopplad till en depå

### Bokningar (`bookings`)
- [ ] En kund kan ha flera bokningar
- [ ] En bokning gäller ett datumintervall (start och slut)
- [ ] En bokning kan innehålla en eller flera artiklar (bokningsrader)
- [ ] Status som ENUM: `confirmed`, `active`, `returned`, `cancelled`
- [ ] Totalpriset beräknas från bokningsraderna (lagras **inte** som kolumn, räknas fram med en fråga: dygnspris från `booking_lines` × antal dygn)
- [ ] En utrustning som redan är uthyrd får inte bokas igen (krav). Full kontroll av överlappande datum = fördjupning (VG), se Öppna frågor.
- [ ] Tidpunkt när bokningen gjordes (sätts automatiskt)
- [ ] Kopplad till en kund (1:N)

### Bokningsrader (`booking_lines`)
- [ ] Egen tabell, kopplingstabell för N:M mellan bokningar och utrustning
- [ ] `booking_line_id` som PK (beslutat 2026-11-13, se Öppna frågor)
- [ ] `booking_id` FK → bokningar
- [ ] `equipment_id` FK → utrustning
- [ ] `UNIQUE KEY (booking_id, equipment_id)`
- [ ] Dygnspriset som gällde vid bokningstillfället

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
- Validering vid `POST /api/reports`, troligen i `src/middleware/validate.js` (byggs i steg 6):
  - **Grund (krav):** `equipmentId` finns i MySQL (backend frågar MySQL först, eftersom det inte finns någon FK), `damageFlag` är true/false, `checklist` är ett objekt. Fel → svara med fel och spara inget.
  - **Fördjupning (VG, om tid finns):** hämta artikelns kategori med JOIN och kontrollera att checklistan har rätt fält för kategorin.

---

## MySQL-delen

### Normalisering (3NF)
- [ ] Schemat är i 3NF
- [ ] Kort text om 3NF, relationer, MongoDB-val och transaktion (lämnas in tillsammans med ER-diagrammet)
- [ ] Förklara minst **ett eget normaliseringsval** (kandidater: prissnapshot på bokningsraden, eller totalpriset som beräknas i stället för att lagras)
- [ ] Förklara **ett samband mellan backend och frontend** i texten till ER-diagrammet: JOIN som gör om `category_id`/`depot_id` till namn i JSON-svaret (se Öppna frågor, besvarat av läraren 2026-11-13)

### Tabeller och villkor
- [ ] Lämpliga datatyper för varje kolumn
- [ ] `PRIMARY KEY` i varje tabell
- [ ] `FOREIGN KEY` med genomtänkt `ON DELETE`-beteende (motivera varje)
- [ ] `UNIQUE`-villkor där det behövs
- [ ] `NOT NULL` där det behövs
- [ ] Standardvärden (`DEFAULT`) där det passar

### Främmande nycklar och ON DELETE
| FK | Pekar på | ON DELETE | Motivering |
|---|---|---|---|
| `equipment.depot_id` | `depots` | RESTRICT | En depå med utrustning får inte tas bort. Stänger en depå flyttas utrustningen först (`UPDATE equipment SET depot_id = ...`). |
| `equipment.category_id` | `categories` | RESTRICT | Många artiklar hör till samma kategori. Kategorin kan inte tas bort så länge artiklar använder den. |
| `bookings.customer_id` | `customers` | RESTRICT | En bokning kan inte finnas utan kund, och bokningshistoriken ska skyddas (bokföringslagen, 7 år). Kunder raderas inte, de anonymiseras (se nedan). |
| `booking_lines.booking_id` | `bookings` | CASCADE | En bokningsrad betyder inget utan sin bokning. Tas bokningen bort (t.ex. en gammal avbokning) försvinner raderna med den. |
| `booking_lines.equipment_id` | `equipment` | RESTRICT | Skyddar bokningshistoriken (totalen räknas från raderna). Artiklar raderas inte: `DELETE /api/equipment/:id` sätter status `retired` i stället ("avveckling enligt din FK-policy" i uppgiften). |

### Leverabler
- [ ] `database/setup.sql` skapar hela schemat
- [ ] `database/seed.sql` med exempeldata:
  - [ ] minst 2 depåer
  - [ ] minst 3 kategorier
  - [ ] minst 8 utrustningsposter
  - [ ] minst 3 kunder
  - [ ] minst 3 bokningar med bokningsrader
- [ ] Seed-filen går att **köra om** (eller så beskrivs tydligt hur databasen återställs). Att fundera på: vad händer om du kör `seed.sql` två gånger i rad idag?
- [ ] Seed-datan tas fram med AI-hjälp. Det redovisas i README, och jag ska förstå och kunna förklara datan.

### Säkerhet
- [ ] Skapa en applikationsanvändare med minsta möjliga behörighet
  - **Beslut 2026-11-13:** användaren skapas **sist i `setup.sql`** (uppgiften räknar upp tre SQL-filer). `CREATE USER IF NOT EXISTS`, eftersom användare ligger utanför databasen och inte försvinner med `DROP DATABASE`.
  - **Rättigheter: bara `SELECT`, `INSERT`, `UPDATE` på `nordicrent_api.*`.** Ingen av de 7 rutterna tar bort rader (`DELETE /api/equipment/:id` = `UPDATE` till `retired`), så `DELETE` behövs inte. Inga strukturändringar (`CREATE`, `ALTER`, `DROP`) och ingen `GRANT`.
  - Appanvändaren är **appens** konto, inte en anställds eller utvecklarens. Utvecklaren använder root i Database Client.
  - Att lösa: lösenordet står i `setup.sql` (hamnar i git) och i `.env` (hamnar inte i git).
- [ ] Appen ansluter aldrig som root
- [ ] `?`-parametrar för **alla** SQL-värden som kommer från API-anrop

### SQL-frågor (`database/queries.sql`)
Körs i MySQL och resultatet visas. De behöver **inga** egna API-rutter.
- [ ] Minst två nästlade SELECT-frågor. Valda frågor:
  1. **Top earners:** vilka artiklar har dragit in mer i hyresintäkter än genomsnittet per artikel?
  2. **Flitiga kunder:** vilka kunder har gjort fler bokningar än vad en kund gör i genomsnitt?
- [ ] Minst en JOIN med minst tre tabeller (t.ex. utrustning + kategori + depå, samma som `GET /api/equipment`, eller en bokning med kund, rader och utrustning)
- [ ] Minst en sammanställning med `GROUP BY` (t.ex. "vilka artiklar hyr vi ut mest?" eller totalpris per bokning)
- [ ] En kort förklaring till varje fråga: vilken fråga svarar den på?
- [ ] Extra, om tid finns (VG):
  - genomsnittligt värde för en bokning (totalen räknas fram per bokning först)
  - kunder som bokat i alla städer där NordicRent har depå
  - en kunds bokningshistorik

### Transaktion
- [ ] Skapandet av en bokning sker i en transaktion: bokningen, dess rader och statusuppdateringen av utrustningen lyckas eller misslyckas som en helhet
- [ ] Visa en **COMMIT** (allt sparas)
- [ ] Visa en **avsiktlig ROLLBACK** (ett steg misslyckas, och inga halvfärdiga bokningsrader blir kvar)
- [ ] Förhindra en uppenbar dubbelbokning av en utrustning som redan är uthyrd

### Felhantering och databasprov
- [ ] Databasspecifik felhantering: känna igen MySQL-fel (t.ex. `1062` dubblett, `1452` FK saknas, se `~/sql-kurs/2026-10-26/relationships_notes.sql`) och svara med JSON som skiljer lyckat från misslyckat anrop
- [ ] Tre dokumenterade databasprov i `DATABASE_TESTS.md`, med förväntat och faktiskt resultat:
  1. läsning/JOIN
  2. ett constraint-fel
  3. rollback utan halvfärdiga bokningsrader

### Objektorienterad problemlösning
- [ ] Ett litet kodexempel, t.ex. en klass eller ett objekt för databasåtkomst, och en förklaring av varför det hjälper. Inga särskilda arkitekturlager krävs.

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

| Metod | Rutt | Databaskunskap som visas |
|---|---|---|
| GET | `/api/equipment` | SELECT + JOIN (utrustning, kategori, depå) |
| POST | `/api/equipment` | Parameteriserad INSERT |
| PUT | `/api/equipment/:id` | Parameteriserad UPDATE |
| DELETE | `/api/equipment/:id` | Avveckling: sätter status `retired` (enligt FK-policyn) |
| POST | `/api/bookings` | MySQL-transaktion med booking + booking_lines |
| POST | `/api/reports` | Spara ett MongoDB-dokument |
| GET | `/api/reports/equipment/:id` | Hämta MongoDB-dokument |

- [ ] Valfritt: `GET /api/health` (räknas inte till de sju)
- [ ] JSON-svar och grundläggande skillnad mellan lyckat och misslyckat anrop räcker
- [ ] Fler rutter ger **inte** automatiskt VG. VG = tekniskt väl genomförd SQL och tabellhantering, och att jag använder MySQL och MongoDB självständigt och ändamålsenligt.

---

## Lämna in

- [ ] Källkoden (vidareutvecklas till API v2 i nästa kurs)
- [ ] `database/setup.sql`, `database/seed.sql`, `database/queries.sql`
- [ ] ER-diagram (bild/PDF) + kort text om 3NF, relationer, MongoDB-val och transaktion
- [ ] `.env.example` med platshållare (aldrig riktiga lösenord)
- [ ] `README.md` med installation, start/stopp och databasinställningar
- [ ] `DATABASE_TESTS.md` med tre körda databasprov inklusive faktiskt resultat
- [ ] Muntlig redovisning enligt `oral_presentation_guide.md` (har inte setts än)

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
- Konsekventa HTTP-felsvar (400/404/409/500), gemensam felmodell, validering i middleware, API-testsvit

## Förbättringsförslag (utanför uppgiftens krav)

- [ ] Arkiv-endpoint för personal som visar borttagna kunder (de med `deleted_at`) och deras bokningshistorik.
- [ ] Personal i tillståndsrapporten: vem som gjorde kontrollen (namn/id). Krävs inte i uppgiften.
- [ ] Avboka enstaka artiklar i en bokning (t.ex. en av fyra kajaker): ta bort/markera raden och se till att totalpriset stämmer efteråt.
- [ ] Gallring av gamla bokningar: ska avslutade bokningar ligga kvar för alltid, arkiveras eller anonymiseras efter en viss tid (t.ex. med tanke på GDPR)?
