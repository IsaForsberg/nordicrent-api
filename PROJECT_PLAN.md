# NordicRent — Projektplan

**Presentation:** 2026-11-20 · **Inlämning:** 2026-11-22 · **Mål:** VG

---

## 3.1 Domänen

### Kunder
- [ ] Tabell för kunder med id, namn, e-post och telefonnummer
- [ ] E-post är unik
- [ ] Kunden kan se sin egen bokningshistorik

### Depåer
- [ ] Tabell för depåer med id, namn, stad och adress
- [ ] Relation depå → utrustning är 1:N
- [ ] En artikel tillhör exakt en depå åt gången

### Kategorier
- [ ] Egen tabell för kategorier (inte fritext)
- [ ] Varje kategori har namn och beskrivning

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
- [ ] Totalpriset beräknas från bokningsraderna
- [ ] Samma artikel får aldrig dubbelbokas för överlappande datum

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

## Öppna frågor att reda ut

- [x] Behövs en egen tabell för bokningshistorik? **Nej.** Bokningarna ligger kvar i bokningstabellen även när de är `returned`/`cancelled`. Historiken är en fråga på kundens id.
- [x] Defaultvärden för status: utrustning `available`, ny bokning `confirmed`.
- [x] Bokningen behöver två sorters datum: när bokningen gjordes (syns t.ex. på en bokningsbekräftelse) och vilka dagar den gäller (start + slut).
- [ ] **Steg 5, överlappskontroll:** `UNIQUE` räcker inte. 1–5 dec och 3–8 dec är olika datum men krockar ändå. Rita två intervall på en tidslinje och formulera villkoret för när de överlappar ("om ... och ..."). Det villkoret blir sedan ett `WHERE` i en SQL-fråga. Tänk också på kantdatum: om en bokning slutar 5 dec, kan nästa börja 5 dec? Gås igenom efter lektionen om underfrågor/transaktioner.
- [x] Vad är en bokningsrad? Bokningar ↔ utrustning är **N:M**, kopplingstabellen `booking_items` (`booking_id` FK, `equipment_id` FK) = bokningsraderna. Kunden hänger på bokningen (1:N), inte på raden.
- [x] `booking_items` får ett eget id som PK (MongoDB-rapporten kopplas till det id:t) + `UNIQUE KEY (booking_id, equipment_id)` så samma artikel inte står två gånger i samma bokning.
- [x] Dygnspriset sparas på bokningsraden vid bokningstillfället, så gamla bokningar inte ändras när utrustningens pris ändras. **Förbered motivering till redovisningen:** varför är det inte dubbellagring som bryter mot 3NF?
- [x] Datumintervallet ligger på **bokningen**: uppgiften säger "en eller flera artiklar för ett datumintervall". Olika datum = två bokningar. Ger också bara ett intervall per bokning att kontrollera vid överlapp.
- [x] PK i `booking_items` heter `booking_item_id` (`booking_id` är redan FK-kolumnen och PK i `bookings`).
- [x] Svar till redovisningen om priset: `booking_items` har priset som *gällde vid bokningen* (historik), `equipment` har *aktuellt* pris. Två olika uppgifter, inte en kopia → bryter inte mot 3NF.
- [ ] Hur ska regeln om dubbelbokning kontrolleras? Räcker ett villkor i tabellen?
- [ ] MongoDB: vad betyder "schemaflexibel" och "nästlad", och hur ser ett rapportdokument ut?
- [ ] Vad händer med en kunds gamla bokningar (returned/cancelled) om kunden tas bort? Vilket ON DELETE-beteende passar?

---

## Förbättringsförslag (utanför uppgiftens krav)

- [ ] Gallring av gamla bokningar: ska avslutade bokningar ligga kvar för alltid, arkiveras eller anonymiseras efter en viss tid (t.ex. med tanke på GDPR)?
