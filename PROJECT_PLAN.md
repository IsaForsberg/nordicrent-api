# NordicRent — Projektplan

**Presentation:** 2026-11-20 · **Inlämning:** 2026-11-22 · **Mål:** VG

---

## 3.1 Domänen

### Kunder
- [ ] Tabell för kunder med id, namn, e-post och telefonnummer
- [ ] E-post är unik
- [ ] Kunden kan se sin egen bokningshistorik
- [ ] `deleted_at` för anonymiserade kunder (se Öppna frågor)

### Depåer
- [ ] Tabell för depåer med id, namn, stad och adress
- [ ] Relation depå → utrustning är 1:N
- [ ] En artikel tillhör exakt en depå åt gången

### Kategorier
- [ ] Egen tabell för kategorier (inte fritext)
- [ ] Varje kategori har namn och beskrivning
- [ ] `category_id` som PK (inte namnet, så ett namnbyte bara ändrar en rad), namnet `UNIQUE` + `NOT NULL`

### Utrustning
- [ ] Tabell för utrustning med id, kategori, modellnamn, dygnspris och inköpsdatum
- [ ] Status som ENUM: `available`, `rented`, `maintenance`, `retired`
- [ ] Kopplad till en kategori
- [ ] Kopplad till en depå

### Bokningar
- [ ] En kund kan ha flera bokningar
- [ ] En bokning gäller ett datumintervall (start och slut)
- [ ] En bokning kan innehålla en eller flera artiklar (bokningsrader)
- [ ] Status som ENUM: `confirmed`, `active`, `returned`, `cancelled`
- [ ] Totalpriset beräknas från bokningsraderna (lagras **inte** som kolumn, räknas fram med en fråga: dygnspris från `booking_items` × antal dygn)
- [ ] Samma artikel får aldrig dubbelbokas för överlappande datum
- [ ] Tidpunkt när bokningen gjordes (sätts automatiskt)
- [ ] Kopplad till en kund (1:N)

### Bokningsrader (`booking_items`)
- [ ] Egen tabell, kopplingstabell för N:M mellan bokningar och utrustning
- [ ] `booking_item_id` som PK
- [ ] `booking_id` FK → bokningar
- [ ] `equipment_id` FK → utrustning
- [ ] `UNIQUE KEY (booking_id, equipment_id)`
- [ ] Dygnspriset som gällde vid bokningstillfället

### Tillståndsrapporter (MongoDB)
- [ ] Skapas när personalen registrerar en återlämning
- [ ] Fritextanteckningar
- [ ] Checklista som skiljer sig per kategori, t.ex.:
  - kajak: skrov, paddlar
  - elcykel: batterihälsa, chassi
  - tält: duk, tältpinnar, allt material inlämnat
- [ ] Eventuella foto-URL:er
- [ ] Skadeflagga
- [ ] Kopplad till bokningsraden i MySQL via ID

---

## 3.2 Krav på MySQL-delen

### Normalisering (3NF)
- [ ] Schemat är i 3NF
- [ ] Rapporten förklarar kort normaliseringen: vilka beroenden som eliminerades och varför varje tabell finns (utkast nedan)

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
| `booking_items.booking_id` | `bookings` | CASCADE | En bokningsrad betyder inget utan sin bokning. Tas bokningen bort (t.ex. en gammal avbokning) försvinner raderna med den. |
| `booking_items.equipment_id` | `equipment` | RESTRICT | Skyddar bokningshistoriken (totalen räknas från raderna). Artiklar raderas inte: `DELETE /api/equipment/:id` sätter status `retired` i stället. |

### Leverabler
- [ ] `database/setup.sql` skapar hela schemat
- [ ] `database/seed.sql` med realistisk exempeldata:
  - [ ] minst 3 depåer
  - [ ] minst 5 kategorier
  - [ ] minst 15 artiklar
  - [ ] minst 5 kunder
  - [ ] minst 8 bokningar med rader
- [ ] Seed-datan tas fram med AI-hjälp. Det redovisas i README, och jag ska förstå och kunna förklara datan.

### Säkerhet
- [ ] Skapa en applikationsanvändare med minsta möjliga behörighet
- [ ] API:t ansluter aldrig som root

### Nästlade underfrågor
- [ ] Minst två frågor med nästlade underfrågor som gör verklig nytta. Valda frågor (löses i steg 6):
  1. **Top earners:** vilka artiklar har dragit in mer i hyresintäkter än genomsnittet per artikel? (Krävs ändå för `GET /api/equipment/top-earners`.)
  2. **Flitiga kunder:** vilka kunder har gjort fler bokningar än vad en kund gör i genomsnitt?
- [ ] Extra, om tid finns (VG):
  - genomsnittligt värde för en bokning (totalen räknas fram per bokning först)
  - kunder som bokat i alla städer där NordicRent har depå
- [ ] Ingen underfråga behövs: "vilka artiklar hyr vi ut mest?" (`GROUP BY` + `ORDER BY` + `LIMIT`)

### Transaktion
- [ ] Skapandet av en bokning sker i en transaktion: bokningen, dess rader och statusuppdateringen av utrustningen lyckas eller misslyckas som en helhet

### Utkast: varför varje tabell finns (till rapporten)
- **customers:** samlar all information om en kund på ett ställe.
- **depots:** information om platserna där NordicRent finns. Handlar bara om depåerna och inget annat.
- **categories:** egen entitet med namn och beskrivning. Flera artiklar hör till samma kategori, så beskrivningen lagras en gång i stället för på varje artikel.
- **equipment:** de fysiska artiklarna och deras status. Kopplas till en depå (varje depå har sin egen utrustning) och till en kategori (flera artiklar kan höra till samma kategori).
- **bookings:** det som gäller hela bokningen: kund, datumintervall, status och när bokningen gjordes. En kund kan ha flera bokningar, en bokning har exakt en kund.
- **booking_items:** kopplar ihop bokningar och utrustning (N:M). Utan den skulle bokningen behöva innehålla artiklarna, eller artiklarna bokningarna. Nu kan `equipment` handla bara om utrustning och `bookings` bara om bokningen.
- **Tillståndsrapporter:** ligger i MongoDB, inte i MySQL (motiveras i steg 1/7).

---

## Öppna frågor att reda ut

- [x] Behövs en egen tabell för bokningshistorik? **Nej.** Bokningarna ligger kvar i bokningstabellen även när de är `returned`/`cancelled`. Historiken är en fråga på kundens id.
- [x] Defaultvärden för status: utrustning `available`, ny bokning `confirmed`.
- [x] Bokningen behöver två sorters datum: när bokningen gjordes (syns t.ex. på en bokningsbekräftelse) och vilka dagar den gäller (start + slut).
- [ ] **Steg 5, överlappskontroll:** `UNIQUE` räcker inte. 1–5 dec och 3–8 dec är olika datum men krockar ändå. Rita två intervall på en tidslinje och formulera villkoret för när de överlappar ("om ... och ..."). Det villkoret blir sedan ett `WHERE` i en SQL-fråga. Tänk också på kantdatum: om en bokning slutar 5 dec, kan nästa börja 5 dec? Gås igenom efter lektionen om underfrågor/transaktioner.
- [x] Vad är en bokningsrad? Bokningar ↔ utrustning är **N:M**, kopplingstabellen `booking_items` (`booking_id` FK, `equipment_id` FK) = bokningsraderna. Kunden hänger på bokningen (1:N), inte på raden.
- [x] `booking_items` får ett eget id som PK (MongoDB-rapporten kopplas till det id:t) + `UNIQUE KEY (booking_id, equipment_id)` så samma artikel inte står två gånger i samma bokning.
- [x] Dygnspriset sparas på bokningsraden vid bokningstillfället, så gamla bokningar inte ändras när utrustningens pris ändras. **Motivering till redovisningen (varför det inte är dubbellagring som bryter mot 3NF):** `booking_items` har priset som *gällde när kunden gjorde bokningen* (historik), `equipment` har *det aktuella priset* för artikeln. Det är två olika uppgifter, inte en kopia av samma, även om de råkar ha samma värde just när bokningen görs.
- [x] Datumintervallet ligger på **bokningen**: uppgiften säger "en eller flera artiklar för ett datumintervall". Olika datum = två bokningar. Ger också bara ett intervall per bokning att kontrollera vid överlapp.
- [x] Totalpriset sparas **inte** i `bookings` (variant B). Det räknas fram vid läsning: `SUM` av dygnspriset i `booking_items` × antal dygn, med JOIN + `GROUP BY`. **Motivering till redovisningen:** en sparad total är härledd ur andra kolumner och kan hamna ur takt med raderna (t.ex. om enstaka artiklar avbokas i framtiden). Utan totalkolumn kan den aldrig bli fel, och schemat håller sig strikt till 3NF. Samma beräkning (pris × dygn) behövs ändå till `top-earners` i steg 6. **Nytt att lära:** MySQL-funktion för antal dagar mellan två datum.
- [x] PK i `booking_items` heter `booking_item_id` (`booking_id` är redan FK-kolumnen och PK i `bookings`).
- [ ] MongoDB: vad betyder "schemaflexibel" och "nästlad", och hur ser ett rapportdokument ut?
- [x] Vad händer med en kunds gamla bokningar om kunden tas bort? **Beslut: RESTRICT + anonymisering.** `DELETE /api/customers/:id` kollar först aktiva bokningar (finns det → `409`). Annars skrivs namn, e-post och telefon över, och raden och de gamla bokningarna ligger kvar. Motivering: personuppgifterna försvinner (GDPR) men historik och statistik (top-earners) stämmer (bokföringslagen). Dokumenteras i README och motiveras i rapporten. **✅ Godkänt av läraren 2026-11-05.** Villkor:
  1. Kontrollera först att kunden inte har några aktiva bokningar.
  2. Finns aktiva bokningar nekas borttagningen (`409`).
  3. Finns bara avslutade/avbokade bokningar anonymiseras personuppgifterna och bokningshistoriken bevaras.
  4. Dokumentera tydligt i README varför lösningen valts.
  - **Viktigt enligt läraren:** anonymiseringen måste verkligen ta bort personuppgifterna, så att kunden inte går att identifiera genom det som finns kvar. Han vill se att jag kan motivera valet och visa att det fungerar (lägg in ett testfall i TESTPLAN.md).
  - [x] "Aktiva" bokningar = `confirmed` + `active` (bokningar som inte är avslutade). `returned` + `cancelled` = avslutade, och då får kunden anonymiseras.
  - [ ] Att fundera på: finns det något mer än namn, e-post och telefon som kan identifiera kunden efter anonymiseringen?
  - [x] Motiveringen ligger i README under "Customer deletion (anonymization)". Granskas igen i steg 9.
  - [x] E-post vid anonymisering: sätts till `NULL`. `UNIQUE` ligger kvar, eftersom MySQL tillåter flera `NULL` i en `UNIQUE`-kolumn (NULL är "okänt" och två okända räknas inte som lika). E-posten får alltså inte vara `NOT NULL`. I stället ett `CHECK`-villkor: e-post måste vara ifylld *om inte* kunden är borttagen (`deleted_at`). Testa NULL+UNIQUE i en testtabell först. Samma resonemang för telefon?
  - [x] Anonymiserade kunder syns **inte** i `GET /api/customers`. Ny kolumn `deleted_at` i `customers`: tom (`NULL`) = aktiv kund, ett datum = när kunden togs bort. Raden och bokningarna ligger kvar som ett arkiv, men personuppgifterna är borta.
  - [ ] Att fundera på: vilken datatyp och vilket standardvärde ska `deleted_at` ha?
  - [x] `GET /api/customers` visar bara aktiva kunder: `WHERE deleted_at IS NULL`.

---

## Förbättringsförslag (utanför uppgiftens krav)

- [ ] Arkiv-endpoint för personal som visar borttagna kunder (de med `deleted_at`) och deras bokningshistorik.
- [ ] Personal i tillståndsrapporten: vem som gjorde kontrollen (namn/id). Krävs inte i uppgiften.
- [ ] Avboka enstaka artiklar i en bokning (t.ex. en av fyra kajaker): ta bort/markera raden och se till att totalpriset stämmer efteråt. Finns inte bland uppgiftens endpoints (`cancel` avbokar hela bokningen).
- [ ] Gallring av gamla bokningar: ska avslutade bokningar ligga kvar för alltid, arkiveras eller anonymiseras efter en viss tid (t.ex. med tanke på GDPR)?
