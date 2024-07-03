##[[

Mages-Engine

A 2d-Rts game engine with a round based campaign map and
multiple game modes, f.e. medival, fantasy, sci-fi, etc.

You create or load a scenario, which then can be played
in campaign mode.

Pathfinging-via Threads
https://nim-by-example.github.io/channels/

TODOS:
- [ ] resources
- [ ] factories
- [ ] movement with arrow keys on enemy and own, also merge
- [ ] astar
- [ ] next-round button
- [ ] prgress to next round
- [ ] Do the movment based on a queue of movement-commands

]]##
import std/[sequtils, math, random, strutils,tables, hashes,options,oids,os,files,deques]
import raylib
import raymath
include ui/Button

const TileSizePixel = 124
const WorldWidth_in_tiles = 100
const WorldHeight_in_tiles = 100
const WorldWidth_in_pixels = WorldWidth_in_tiles * TileSizePixel
const WorldHeight_in_pixels = WorldHeight_in_tiles * TileSizePixel

type

  FactionRelationState = enum
    Peace
    Alliance
    War

  Faction = ref object
    is_player_faction: bool
    name: string
    description: string
    defeated: bool
    index: int ##\
      ## Index in the list of factions within the scenario.
      ## If a faction dies it is set to defeated, but it still continues to exist.
    identification: string
    color: Color

  Scenario = ref object
    ##[[
    You can load a scenario as part of a campaign, but you can also
    create one on the fly in the scenario editor.
    ]]##
    name: string
    description: string
    factions: seq[Faction]
    factions_on_map: Table[string, Faction]
    tiles_map: Table[int, Table[int,Tile]]
    tiles: seq[Tile]
    turn: int
    factions_relations
      : Table[int, tuple[faction_index: int, relation_state: FactionRelationState]]

  GameMode = enum
    Menu
    Camp

  CampDisplayMode = enum
    Default

  ZoomLevel = enum
    Mini
    VerySmall
    Small
    Default
    Big

  Game = ref object
    mode: GameMode
    display_mode: CampDisplayMode
    selected_tile: Option[Tile]
    scenario: Scenario
    zoom_level: ZoomLevel
    ai_army_movment_tasks: Deque[ArmyMovementTask]
    player_movment_task: Option[ArmyMovementTask]

  TileType = enum
    Land
    Water
    Mountain

  Tile = ref object
    pos: Vector2
    category: TileType
    owner: Option[Faction]
    army: Option[Army]
    faction: Option[Faction]

  Army = ref object
    faction: Faction
    tile_i_am_on: Tile
    command_points: int
    level: int
    last_moved_at_turn: int

  ArmyMovementTask = ref object
    army: Army
    target_tile: Tile

  Logger = ref object
    file: File

  MissingDataFromMod = object of Defect

func get_tile(self: var Scenario, x_in_world_pixel: float, y_in_world_pixel: float): Option[Tile] =
  let x_as_num = (x_in_world_pixel / TileSizePixel).floor.int
  let y_as_num = (y_in_world_pixel / TileSizePixel).floor.int
  if self.tiles_map.has_key(x_as_num) and self.tiles_map[x_as_num].has_key(y_as_num):
    return some(self.tiles_map[x_as_num][y_as_num])
  else: return none(Tile)

func is_in_world(self: Scenario, x: int, y: int): bool =
  x >= 0 and x < WorldWidth_in_pixels and y >= 0 and y < WorldHeight_in_pixels

proc create_Faction*(
  name: string,
  is_player_faction: bool,
  description: string,
  color: Color,
  s: Scenario
): Faction =
  var faction = Faction()
  faction.name = name
  faction.is_player_faction = is_player_faction
  faction.description = description
  faction.identification = $genOid() #  uses time -> so non deterministic
  faction.color = color
  s.factions.add(faction)
  s.factions_on_map[name] = faction
  return faction

func delete_Faction( faction: Faction, s: var Scenario) =
  let index = s.factions.find(faction)
  s.factions.del(index)
  s.factions_on_map.del(faction.name)

const logfile_name = "log.txt"
if fileExists(logfile_name): removeFile(logfile_name)
var logger = Logger(file: open(logfile_name, fmAppend))
proc log(self: Logger, msg: string) = self.file.write(msg & "\n")
setTraceLogLevel(TraceLogLevel.Error)
initWindow(1900, 1080, "example")
setWindowMonitor(0)
var camera = Camera2D(
  target: Vector2(x: 0, y: 0),
  offset: Vector2(x: 0, y: 0),
  rotation: 0,
  zoom: 1)
logger.log("Start")

# toggleFullscreen();

# load all resources within the block
# otherwise we get sigfault at close window ...
block:

  when defined(lerman): include mods/lerman/load
  func need(name: string) =
    raise MissingDataFromMod.newException(
     "'" & name & "' not declared in current mod")
  when not declared(ModImages): need("ModImages")

  let background = loadTexture("./img/background.png")
  var game = Game()
  game.mode = GameMode.Menu
  game.scenario = Scenario()
  game.scenario.turn = 1
  var running = true
  while running:

    if windowShouldClose(): running = false
    let delta_time = getFrameTime()

    # update here the game state
    case game.mode:

      of GameMode.Menu:
        discard # no stuff to do in menu ...

      of GameMode.Camp:
        let speed = 400f * delta_time
        let zoom_factor = case (camera.zoom * 10).int:
          of 0..2: game.zoom_level = ZoomLevel.Mini; 16f
          of 3..4: game.zoom_level = ZoomLevel.VerySmall; 16f
          of 5..9: game.zoom_level = ZoomLevel.Small; 8f
          of 10: game.zoom_level = ZoomLevel.Default; 4f
          of 11..19: game.zoom_level = ZoomLevel.Big; 2f
          of 20..40: game.zoom_level = ZoomLevel.Big; 0.5
          else: game.zoom_level = ZoomLevel.Big; 0.1
        if isKeyDown(KeyboardKey.D): camera.target.x += zoom_factor * speed
        if isKeyDown(KeyboardKey.A): camera.target.x -= zoom_factor * speed
        if isKeyDown(KeyboardKey.W): camera.target.y -= zoom_factor * speed
        if isKeyDown(KeyboardKey.S): camera.target.y += zoom_factor * speed
        let moved = getMouseWheelMove()
        if moved != 0:
          let zoom_delta = moved * 0.1
          let old_zoom = camera.zoom
          camera.zoom += zoom_delta
          if camera.zoom < 0.1: camera.zoom = 0.1
          let new_zoom = camera.zoom
          # Adjust the camera target to keep the center position the same
          let screen_center = Vector2(
            x: getScreenWidth().float / 2.0,
            y: getScreenHeight().float / 2.0)
          let world_center_before = Vector2(
            x: (screen_center.x - camera.offset.x) / old_zoom + camera.target.x,
            y: (screen_center.y - camera.offset.y) / old_zoom + camera.target.y)
          let world_center_after = Vector2(
            x: (screen_center.x - camera.offset.x) / new_zoom + camera.target.x,
            y: (screen_center.y - camera.offset.y) / new_zoom + camera.target.y)
          camera.target.x -= world_center_after.x - world_center_before.x
          camera.target.y -= world_center_after.y - world_center_before.y
        let mouse_pos = getMousePosition()
        if isMouseButtonPressed(MouseButton.Left):
          let x = (mouse_pos.x * 1/camera.zoom) + camera.target.x
          let y = (mouse_pos.y * 1/camera.zoom) + camera.target.y
          let tile = game.scenario.get_tile(x, y)
          if tile.isSome: game.selected_tile = tile
          else: game.selected_tile = none(Tile)
        if isMouseButtonPressed(MouseButton.Right):
          game.selected_tile = none(Tile)
        if isMouseButtonDown(MouseButton.Middle):
          let delta = getMouseDelta()
          camera.target.x -= delta.x * zoom_factor
          camera.target.y -= delta.y * zoom_factor
        # here is the place to handle the mouse movment
        if game.selected_tile.is_some:
          let tile = game.selected_tile.get
          if tile.faction.isSome:
            if tile.faction.get.is_player_faction:
              if tile.army.is_some and tile.army.get.last_moved_at_turn != game.scenario.turn:
                var move_to = none(Tile)
                if isKeyPressed(KeyboardKey.Left):
                  let left_one = game.scenario.get_tile(tile.pos.x - TileSizePixel, tile.pos.y)
                  if left_one.is_some: move_to = left_one
                if isKeyPressed(KeyboardKey.Right):
                  let right_one = game.scenario.get_tile(tile.pos.x + TileSizePixel, tile.pos.y)
                  if right_one.is_some: move_to = right_one
                if isKeyPressed(KeyboardKey.Up):
                  let up_one = game.scenario.get_tile(tile.pos.x, tile.pos.y - TileSizePixel)
                  if up_one.is_some: move_to = up_one
                if isKeyPressed(KeyboardKey.Down):
                  let down_one = game.scenario.get_tile(tile.pos.x, tile.pos.y + TileSizePixel)
                  if down_one.is_some: move_to = down_one
                if move_to.is_some() and move_to.get.category == TileType.Land:
                  discard # todo: add task
        let task
          = if game.player_movement_task.some(): game.player_movement_task.get
          elif game.ai_army_movment_tasks.len > 0: game.ai_army_movment_tasks.popFront()
          else: none(ArmyMovementTask)
        if task.is_some:
          let task = task.get
          var movment_success = false
          let army = task.army
          let source_tile = army.tile_i_am_on
          let target_tile = task.target_tile
          if target_tile.faction.isNone: # occupy free tile
            target_tile.army = game.selected_tile.get.army
            source_tile.get.army = none(Army)
            target_tile.army.get.tile_i_am_on = tile
            target_tile.faction = source_tile.get.faction
            movment_success = true
          elif tile.faction.get == source.faction.get:
            if tile.army.is_some:
              discard # merge armies, higher tech level
            else:
              discard # just go there
          else:
             # attack (only on war)
             discard
          if movment_success: tile.army.get.last_moved_at_turn = game.scenario.turn

    beginDrawing()
    clearBackground(RAYWHITE)


    case game.mode:
      of GameMode.Menu:
        block:
          drawTexture(background, 0, 0, WHITE)
          let text = "Lerman".cstring
          drawText(text, 350, 10, 70, WHITE);
          if Button(
            text= "Start",
            pos= Vector2(x: 100, y: 100),
            width= 100,
            height= 50):
            populate_scenario(game.scenario, logger)
            game.mode = GameMode.Camp
          if Button(
            text= "Exit",
            pos= Vector2(x: 100, y: 200),
            width= 100,
            height= 50 ): running = false

      of GameMode.Camp:
        block:
          beginMode2D(camera);
          let screen_w = getScreenWidth()
          let screen_h = getScreenHeight()
          for tile in game.scenario.tiles:
            let in_view = checkCollisionRecs(
              Rectangle(
                x: camera.target.x * camera.zoom,
                y: camera.target.y * camera.zoom,
                width: screen_w.float,
                height: screen_h.float),
              Rectangle(
                x: tile.pos.x * camera.zoom,
                y: tile.pos.y * camera.zoom,
                width: TileSizePixel * camera.zoom,
                height: TileSizePixel * camera.zoom))
            if not in_view: continue
            case tile.category
              of TileType.Land:drawTexture(ModImages.flat[0],tile.pos,WHITE)
              of TileType.Water:drawTexture(ModImages.water[0],tile.pos,WHITE)
              of TileType.Mountain: drawTexture(ModImages.mountain[0],tile.pos,WHITE)

            # draw a faction colored border around the tile
            if tile.faction.isSome:
              let faction = tile.faction.get
              let color = faction.color
              if game.zoom_level == ZoomLevel.Mini:
                drawRectangle(
                  Rectangle(
                    x: tile.pos.x,
                    y: tile.pos.y,
                    width: TileSizePixel,
                    height: TileSizePixel),
                  color)
              else:
                drawRectangleLines(
                  Rectangle(
                    x: tile.pos.x,
                    y: tile.pos.y,
                    width: TileSizePixel,
                    height: TileSizePixel),
                  3,
                  color)
                # draw a rect with some alpha
                drawRectangle(
                  Rectangle(
                    x: tile.pos.x,
                    y: tile.pos.y,
                    width: TileSizePixel,
                    height: TileSizePixel),
                  fade(color, 0.05))

            if tile.army.isSome and game.zoom_level != ZoomLevel.Mini:
              assert tile.faction.isSome
              let army = tile.army.get
              var visibilitiy_blocks = (army.command_points / 100).ceil.int
              echo "blocks:" , visibilitiy_blocks
              let square_numbers = visibilitiy_blocks.float.sqrt().ceil
              echo square_numbers
              let square_size = 4f
              let space_between = 2
              let space_around = 2f
              let witdh = square_numbers * square_size + (square_numbers + 1) * space_between.float + space_around * 2
              let extra_space = (TileSizePixel - witdh) / 2
              var drawn_blocks = 0
              let x_rect_start = tile.pos.x + extra_space
              let y_rext_start = tile.pos.y + extra_space
              block outer_loop:
                for row in 0..square_numbers.int - 1:
                  for col in 0..square_numbers.int - 1:
                    drawn_blocks += 1
                    if drawn_blocks > visibilitiy_blocks: break outer_loop
                    let x = tile.pos.x.int + extra_space.int + col * square_size.int + space_between * (col + 1)
                    let y = tile.pos.y.int + extra_space.int + row * square_size.int + space_between * (row + 1)
                    let rect = Rectangle(x: x.float, y: y.float, width: square_size.float, height: square_size.float)
                    let moved_this_turn = game.scenario.turn == army.last_moved_at_turn
                    let color = if moved_this_turn: fade(tile.faction.get.color, 0.3) else: tile.faction.get.color
                    drawRectangle(rect, color)

              # draw rect directly around the army
              let rect = Rectangle(
                x: x_rect_start - space_around,
                y: y_rext_start - space_around,
                width: witdh,
                height: witdh)

              drawRectangleLines(rect, 2,
                if tile.army.get.last_moved_at_turn == game.scenario.turn: WHITE
                else: tile.faction.get.color
              )








            #running = false
          if game.selected_tile.isSome:
            let selected = game.selected_tile.get
            let rect = Rectangle(
              x: selected.pos.x,
              y: selected.pos.y,
              width: TileSizePixel,
              height: TileSizePixel)
            drawRectangleLines(
              rect,
              2,
              raylib.WHITE)

          endMode2D()

          # end the camera : this means here comes the ui

          let menu_width = 400f
          let menu_start = getScreenWidth().float - menu_width
          let menu_height = getScreenHeight().float
          if game.selected_tile.isSome:
            draw_from_atlas(
              menu_start,
              0,
              menu_width,
              menu_height,
              rotation= 0f,
              src=MENU_BACKGROUND)
            let tile_data = game.selected_tile.get
            drawText(("Tile: " & $tile_data.category).cstring, (menu_start + 10).int32, 10, 20, BLACK)
            drawText(("Pos: " & $tile_data.pos).cstring, (menu_start + 10).int32, 30, 20, BLACK)
            if tile_data.faction.isSome:
              let faction = tile_data.faction.get
              drawText(("Faction-Owner: " & $faction.name).cstring, (menu_start + 10).int32, 50, 20, faction.color)
            else:
              drawText("No Faction".cstring, (menu_start + 10).int32, 50, 20, BLACK)
              drawText(("Type: " & $tile_data.category).cstring, (menu_start + 10).int32, 70, 20, BLACK)
            if tile_data.army.isSome:
              let army = tile_data.army.get
              drawText(("Army - Command Points: " & $army.command_points).cstring, (menu_start + 10).int32, 90, 20, BLACK)
            else:
              drawText("No Army".cstring, (menu_start + 10).int32, 90, 20, BLACK)

          discard
          # update the game here
          # draw game here
          # ...
      else: discard

    # draw ret circlertin the middle of the screen
    # drawCircle(Vector2(x:getScreenWidth() / 2-10, y: getScreenHeight() / 2)-10, 20, RED)

    let fps = getFPS()
    drawText("FPS: " & $fps, 10, 10, 20, RED)
    drawText("Camera: " & $camera.target, 10, 30, 20, RED)
    drawText("Zoom: " & $camera.zoom, 10, 50, 20, RED)
    let mouse_pos = getMousePosition()
    drawText("Mouse: " & $mouse_pos, 10, 70, 20, RED)
    # zoom level
    drawText("Zoom Level: " & $game.zoom_level, 10, 90, 20, RED)
    endDrawing()
    # end of the game loop

closeWindow()