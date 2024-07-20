
echo "load lerman resources"

let ModImages = (
  flat: [
    loadTexture("./mods/lerman/res/flat_0.png"),
    loadTexture("./mods/lerman/res/flat_1.png"),
    loadTexture("./mods/lerman/res/flat_2.png"),
    loadTexture("./mods/lerman/res/flat_3.png"),
  ],
  factory: [
    loadTexture("./mods/lerman/res/factory_0.png"),
    loadTexture("./mods/lerman/res/factory_1.png"),
    loadTexture("./mods/lerman/res/factory_2.png"),
    loadTexture("./mods/lerman/res/factory_3.png"),
  ],
  minerals: [
    loadTexture("./mods/lerman/res/minerals_0.png"),
    loadTexture("./mods/lerman/res/minerals_1.png"),
    loadTexture("./mods/lerman/res/minerals_2.png"),
    loadTexture("./mods/lerman/res/minerals_3.png"),
  ],
  mountain: [
    loadTexture("./mods/lerman/res/mountain_0.png"),
    loadTexture("./mods/lerman/res/mountain_1.png"),
    loadTexture("./mods/lerman/res/mountain_2.png"),
    loadTexture("./mods/lerman/res/mountain_3.png"),
  ],
  water: [
    loadTexture("./mods/lerman/res/water_0.png"),
    loadTexture("./mods/lerman/res/water_1.png"),
    loadTexture("./mods/lerman/res/water_2.png"),
    loadTexture("./mods/lerman/res/water_3.png"),
  ],
  menu_background: loadTexture("./mods/lerman/res/background.png")
)


# DrawTexturePro(scarfy, sourceRec, destRec, origin, (float)rotation, WHITE);
let MENU_TEXTURE = loadTexture("./mods/lerman/res/menu.png")

proc draw_from_atlas(x, y, width, height, rotation: float, src: (int,int,int,int)) =
  let source_x = src[0].float
  let source_y = src[1].float
  let source_w = src[2].float - source_x
  let source_h = src[3].float - source_y
  let source_rect = Rectangle(x: source_x, y: source_y, width: source_w, height: source_h)
  let dest_rect = Rectangle(x: x, y: y, width: width, height: height)
  let origin = Vector2(x: 0, y: 0)
  drawTexture(MENU_TEXTURE, source_rect, dest_rect, origin, rotation, WHITE)

let MENU_BACKGROUND = (73,81,200,200)

proc populate_scenario(self: var Scenario, L: Logger) =

  discard create_Faction(
    name="Player",
    is_player_faction=true,
    description="some desc",
    color=Color(r:0,g:255,b:0,a:255),
    self
  )

  discard create_Faction(
    name="Kicki",
    is_player_faction=false,
    description="some desc",
    color=Color(r:255,g:0,b:0,a:255),
    self
  )

  discard create_Faction(
    name="Wummpen",
    is_player_faction=false,
    description="some desc",
    color=Color(r:0,g:0,b:255,a:255),
    self
  )

  discard create_Faction(
    name="Wummpen2",
    is_player_faction=false,
    description="some desc",
    color=Color(r:255,g:255,b:0,a:255),
    self
  )

  discard create_Faction(
    name="Wummpen3",
    is_player_faction=false,
    description="some desc",
    color=Color(r:64,g:224,b:208,a:255),
    self
  )

  discard create_Faction(
    name="Wummpen3",
    is_player_faction=false,
    description="some desc",
    color=Color(r:160,g:32,b:240,a:255),
    self
  )

  for x in 0..WorldWidth_in_tiles-1:
    var tab = initTable[int, Tile]()
    self.tiles_map[x] = tab
    #L.log("x: " & $x & " -> " & $self.tiles_map[x].len)
    for y in 0..WorldHeight_in_tiles-1:
      var tile = Tile()
      tile.pos = Vector2(x:x.float * TileSizePixel, y:y.float * TileSizePixel)
      self.tiles_map[x][y] = tile
      self.tiles.add(tile)
      tile.category
        = case rand(0..99)
          of 0..70: TileType.Land
          of 81..90: TileType.Water
          of 91..99: TileType.Mountain
          else: TileType.Land
      if tile.category == TileType.Land:
        tile.faction = case rand(0..20)
          of 0: some(self.factions[0])
          of 1: some(self.factions[1])
          of 2: some(self.factions[2])
          of 3: some(self.factions[3])
          of 4: some(self.factions[4])
          of 5: some(self.factions[5])
          else: none(Faction)
      if tile.faction.is_some:
        tile.army = some(
          Army(
            faction:tile.faction.get,
            tile_i_am_on: tile,
            command_points: rand(100..3800),
            level: 1))

