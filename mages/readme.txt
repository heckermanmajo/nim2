Command-Points

Als erstes einzelne Atlases für panzer und soldaten machen.
-> erstmal keine soldaten animationen, etc.

Sound and Ambiente
- Panzer müssen sich schwerfällig aber mächtig anfühlen
- Realistischer schaden und explosionen
- Teile müssen rumfliegen
- feuer muss rauchen und brennen
- der sound muss sehr sehr geil sein

Style:
- top down wie bei BloodAndMud

Armeen
- haben Tech-Level: Was für Einheiten gekauft werden können im battle
- haben Tranings-Level: Wie gut die Einheiten performen
- haben Material: Kauft Einheiten im RTS-Battle
- Tech kostet geld und zeit
- trainig kostet geld und zeit
- material kostet geld und zeit
--> Weil Tech sehr teuer ist in zeit und geld, können die Waffensysteme 
    von höherem Tech sehr mächtig sein

Logistik-Hub:
- kann gebaut werden auf flachland
- wenn man eine Armee upgraded ist es teurer um so weiter man weg ist von einem hub
- wenn zwischen hub und armee feindesland ist, geht es nicht
- logistik-hubs aufzubauen kostet zeit (mehrere runden)
- klickt man eine armee an wird eine lienie zum nächsten hub angezeigt

Geschosse
- keine Projektile, sondern schüsse treffen den ersten tile im weg
- wenn der tile ein schutz ist, kann er abgefangen werden oder weiterfligene (zb.sandbags)
- manche explodieren in einem radius, wo sie aufkommen

Artillerie-Schläge
- man kann schläge der artillierie oder flugzeuge, etc. von außer der map rufen

Chunks & Tiles 
- chunks helfen bei der ai und commando-gruppen organisation
- tiles ermöglichen schiessen und andere lokalisierungs logiken
- navigation OHNE tiles, aber tiles markieren ziel-position
- größere Vehicle sind dann auf meheren Tiles registriert

Command-Groups & strategic overview (SO)
- Einheiten bilden Commando-Gruppen
- Commando gruppen können im SO gesteuert werden
- man kann einzelne Einheiten aus SOs rauslösen um z.b. eine Verteidigungs postion 
  zu bemannen
- rauslösen mit einheit auswählen und dann "l"
- man kann aber auch einheiten in commando-gruppen zusammen fassen mit "g"  

Objects
- es gibt objekte die Deckung geben
- es gibt geschütze 
- mit speziellen einheiten kann man geschütze und Deckungen plazieren (z.b. Pioniere)

Strategic Chunks
- man hat chunks aus denen verstärkung kommt, die darf man nicht verlieren
- es gibt andere chunks auf der map, die boni bringen, die man erobern will 
--> Das macht das game dynamisch und es verhindert dass der player turtelt
    Außerdem vereinfacht es der AI das game, weil es kleine klare objektives gibt

Battle-AI:
- die battle ai hat unterschiedliche Modi und unterschiedliche taktiken

AI-Charackers 
- die ai im Campaign view hat Persönlichkeiten (crusader)
- es gibt interaktive diplomatie (total war)

Battle-Mechanic
- you can zoom out -> at a certain zoom level you get into the startegic map
- if you click on a chunk you can click on the spawen button
  this button will open the spawn overlay, where you can select a unit to spawn
- spawning in takes some time: you have a queue of not yet spawned units at the top
- you also see if the enemy spawns in stuff, but you dont see what  

Motorised Infantry
- eine infmatrie Controll gruppe kann mit einem transporter assoziiert sein
  dann ausgeladen werden und wenn sie weit weg geschickt wird wieder aufsteigen


- Einheiten stoppen wenn sie beschossen werden, es hägt von der einheit ab, wie stark das geschoss sein muss 
- soldaten stoppen sofort
- leichte fahrzeuge etwas später 
- panzer nur bei sehr schwerem feuer

- alle einheiten bewegen sich: unterschiedliche Geschwindigkeit
- alle einheiten suchen ein ziel: manche haben prios: panzer abwehr auf fahrzeuge usw.


Wie kann man factions zusammen bauen? -> sie entwickelt sich mit der zeit... 


Die Ai factions schließen sich gegen den stärksten zusammen.


Supply-truck
- artellerie hat nur wenig schuss 
- man bruacht einen supply truck zum aufmunitionieren
- der hat kisten drauf 
- eine kiste einmal aufmunitionieren 
- der supply truck kann auch kisten in starke befestigungen verwandeln
- der supply truck kann auch panzer mit einer kiste reparieren


The solution to ai is very good and smart controls
that will be stiched together to create a battle-field ai.

The controls need to be chunk based.

set chunk on defend,

Missions: Ai can assignunits to missions and a mission 
has atarget (a chunk) to hold, to conquer, etc.

The ai plays based on realism. 



STORY
=======
Der Mensch glaubte sich im Paradies...

Doch dann 
- geburtenrate + kybernetischer Sturm


Nun 
- darvinismus
- kommunismus(bio-leniniismus)
- china: bio-faschism
- neu-christentum: Factionwars
- usa: endphase UDSSR
- OstEuropa: free for all
- west europa: inner turmoil
- india china war

If sou go full faschism: Other hate you more but you gain options





Only command points -> no tech level, no training
Camp-map-Logistics
Onle on field movement per turn (if not adding command points)





in battle: only Brigarden: fast-light attack; heavy-slow attack; defense


4 speeds
- slow: defense brigade (geschütze and artellerie, also soldiers on foot)
- very fast: jeeps
- fast: trucks, light-tanks
- normal slow: tanks, tank-transport 

Artellerei: trumps all
Geschütz: je nach tower: anti tank, all tanks, flak: soldiers and trucks/jeeps, granate launcher: light tank
AttackTanks: trumps all vehicles and geschütz.
light-tanks: trumps all trucs and jeeps and artellerie(not geschütz and tank)
Soldiers-sturm: trump light tanks with granates or anti tank gun
Anti tank gun also works against light-attack-tanks
Bazooka trumps all tanks, but soldiers are very soft
All systems trump soldiers.

