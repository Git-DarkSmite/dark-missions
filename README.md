
# dark-missions

Ett lättanvänt FiveM-resource för att skapa uppdrag (missions) med NPC-interaktioner, markörer, fordonsspawn, belöningar och anpassade triggers. Den här README:n beskriver hur scriptet fungerar, vilka inställningar som finns i `config.lua`, samt alla fält du kan använda när du skapar ett uppdrag — baserat på `missions/example.md`.

**Innehåll**
- **Beskrivning:** Vad scriptet gör
- **Krav:** Nödvändiga och rekommenderade resurser
- **Konfiguration:** Viktiga inställningar i `config.lua`
- **Skapa ett mission:** Alla fält (mission-level)
- **Tasks:** Alla fält för varje steg i ett mission
- **Exempel:** Referens till `missions/example.md`
- **Felsökning & tips**

**Beskrivning**
- **dark-missions:** Låter serverkonstruktörer definiera uppdrag via Lua-tabeller som laddas in i `Config.Missions`. Ett uppdrag kan:
	- Spawna en ped som spelaren interagerar med
	- Sätta upp uppgiftssteg (travel, interact, spawn vehicle, delete vehicle, belöningar)
	- Ge belöningar: items, cash, bank, custom rewards
	- Köra custom triggers och kommandon

**Krav & rekommendationer**
- **FiveM server** med stöd för resource-loading.
- Rekommenderade resurser (beroende på vilka features du använder): `qb-target`, `ox_lib` eller `okok` eller `qbcore` (notify), `InteractSound` (om du använder ped-ljud), inventory/resource som innehåller items du ger ut, ett belöningsscript som t.ex. `dark-reward` (valfritt).
- Placera dina uppdragsfiler i mappen `missions/` och se till att varje fil lägger till missioner till `Config.Missions` (ex: `table.insert(Config.Missions, mission)`).

**Konfiguration (från `config.lua`)**
- **`TextState`**: Intern flagga för visning av text UI.
- **`CurrentLabel`**: Internt label för aktuell text.
- **`DefaultTypeDelay`**: Standard delay (ms) för textvisning.
- **`NotifyType`**: Vilket notificeringssystem som används. Stödda värden: `"ox_lib"`, `"okok"`, `"qbcore"` — välj det system du har installerat.
- **`Missions`**: Tabell som fylls av dina mission-definitioner.
- **`LeaveMissionCommand`**: Sträng för kommandot att lämna ett mission. Standard: `"leave_mission"` — använd i spel: `/leave_mission`.
- **`UsePedMarker`**: `true/false` — om ped-markeringar ska visas.
- `ShowText(label, state, options)` används för att visa/hide text UI och kör en snygg `ox_lib`-notify första gången med tips om scroll-hjul.

**Skapa ett mission — fält (mission-level)**
Följande fält kommer från `missions/example.md`. Alla fält är valfria om ej annat anges, men vissa behövs för specifika funktioner (t.ex. `tasks` behövs för uppgifter).
- **`name`**: : Ett unikt namn för missionen (används internt och i DB).
- **`pedInteractLabel`**: : Text för interaktionsknapp vid ped (t.ex. "E").
- **`done`**: : `true/false`. Om `true` kan missionen bara fullföljas en gång per spelare.
- **`cooldownTime`**: : Tid i minuter innan missionen kan upprepas.
- **`missionsRequire`**: : (string) Namn på ett annat mission som måste vara `done` innan detta blir tillgängligt.

- **Ped-konfiguration:**
	- **`pedModel`**: : Ped-modell (t.ex. `"a_m_m_business_01"`).
	- **`pedCoords`**: : `vector4(x, y, z, heading)` där peden spawnar.
	- **`icon`**: : Ikon för `qb-target`, t.ex. Font Awesome klass `"fas fa-briefcase"`.
	- **`label`**: : Label som visas i `qb-target`.

- **Ped-interaktion och dialog:**
	- **`pedSpeech`**: : Text peden säger när spelaren interagerar.
	- **`pedtitle`**: : Titel i interaktionsmenyn.
	- **`pedLabelAccept`** / **`pedLabelDeny`**: : Text för accept/deny-knappar.
	- **`pedAcceptReaction`** / **`pedDenyReaction`**: : Ped-animation/reaktion (exempel `"GENERIC_THANKS"`).
	- **`description`**: : Startsbeskrivning av missionen som spelaren ser.

- **Ped-ljud (valfritt):** (kräver `InteractSound` eller motsvarande)
	- **`pedAcceptSound`** / **`pedDenySound`** / **`pedGreetingSound`**: : Namn på ljudfil i InteractSound.
	- **`pedAcceptSoundDistance`** / **`pedDenySoundDistance`**: : Hörbarhetsradie.
	- **`pedAcceptSoundVolume`** / **`pedDenySoundVolume`**: : Volym (0.0–1.0).

- **Restriktioner (valfritt):**
	- **`BannedJobsAndGangs`**: : Tabell med `jobs` och `gangs` som inte kan starta missionen.

- **Tasks (lista):** : En tabell med steg (se sektionen "Tasks" nedan).

- **Övrigt (mission-level):**
	- **`accessToblackmarket`**: : Exempel på bool som kan trigga access till annat script.
	- **Belöningar på missionsnivå:** (kan även sättas per task eller i sista task)
		- **`addItem`** / **`addItemAmount`**: : Item och mängd som ges.
		- **`addCash`** / **`addBank`**: : Pengabelöning i cash respektive bank.
		- **`rewards`**: : Custom reward-id (t.ex. för `dark-reward`).

**Tasks — fält för varje steg**
Varje uppgift i `tasks` representerar ett steg spelaren måste genomföra. Här är fälden från `example.md` och deras användning:
- **`description`**: : Text som visas för spelaren (kan innehålla färgkoder som `~b~`).
- **`coords`**: : `vector3(x, y, z)` plats spelaren ska befinna sig på.
- **`waitTime`**: : Sekunder att vänta efter uppgiften innan nästa steg aktiveras.
- **`playSound`**: : Ljudspelning när uppgiften nås.
- **`distance`**: : Avstånd för ljudet att höras.
- **`volume`**: : Volym för ljudet.
- **`ExecuteCommand`**: : Text/kommando som körs när spelaren interagerar (ex: `"e salute"`).

- **Fordon-relaterade:**
	- **`spawnVehicle`**: : Modellnamn på fordon som ska spawnas.
	- **`scpawnVehileCoords`**: : `vector4(x,y,z,heading)` för fordonsspawn.
	- **`deleteVehicle`**: : `true/false` — om fordonet ska tas bort när steget är klart.

- **Marker-inställningar (visuella interaktionsmarkörer):**
	- **`MarkerTitel`**: : Text ovanför markören (ex: `~w~[~b~E~w~] Drop Off`).
	- **`markerRadius`**: : Radius där markören syns.
	- **`interactKeyRadius`**: : Radius för interaktionsknapp (t.ex. tryck E).
	- **`MarkertType`**: : Numerisk typ för markören (FiveM marker-typ).
	- **`MarkertBob`** / **`MarkertRotate`**: : `true/false` för bob/rotation.
	- **`MarkertR`** / **`MarkertG`** / **`MarkertB`**: : RGB-färgvärden (0–255).
	- **`MarkertSize`**: : `vector3(x,y,z)` för markörstorlek.
	- **`rotX`** / **`rotY`** / **`rotZ`**: : Rotation i grader.

- **Custom triggers / events:**
	- **`customtrigger`**: : Namn på en client-event att trigga (ex: `"setfire"` som finns i `client/customtriggers.lua`).

**Exempel**
- Se `missions/example.md` för ett komplett, kommenterat exempel. Filen visar:
	- En mission-tabell med ped, tasks och rewards.
	- Hur man lägger till missionet i `Config.Missions` med `table.insert(Config.Missions, mission)`.

**Konfigurera kommandon**
- I `config.lua` finns inställningen **`LeaveMissionCommand = "leave_mission"`**.
	- Förväntad användning i spelet: skriv `/leave_mission` i chatten för att lämna ett aktivt mission (förutsatt att kommandot registreras i servern av scriptet).

**Tips & felsökning**
- Kontrollera att `Config.Missions` fylls korrekt: varje mission måste läggas till i tabellen för att laddas.
- Om ljud inte spelas, verifiera att `InteractSound` eller motsvarande ljudresource är installerad och att ljudnamnen matchar.
- Om `qb-target`-ikoner eller interaktioner inte fungerar, kontrollera att `qb-target` är installerat och att `icon`/`label` är korrekt satta.
- För belöningar: säkerställ att item-namn finns i din inventory/resource, och att cash/bank-logik matchar din serverplattform (ex: QB-Core wallet API).

**Vanliga frågor**
- Var ska jag lägga mina missions? : Placera filerna i `missions/` och se till att de körs eller inkluderas av resource (exempel: en `.lua`-fil som kör `table.insert(Config.Missions, mission)`).
- Kan jag ha flera tasks? : Ja — `tasks` är en array och kommer köras i ordning.
- Hur begränsar jag vem som kan starta ett mission? : Använd `BannedJobsAndGangs` eller bygg en custom check i din serverlogik.

---
Om du vill kan jag: generera en mall `missions/new_mission.lua` utifrån `example.md`, lägga till fler förklarande kommentarer i koden, eller skapa en kort checklista för att publicera missioner på servern. Vill du att jag gör något av detta nu?
