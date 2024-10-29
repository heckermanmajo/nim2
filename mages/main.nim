##[[

# install the raylib wrapper
nimble install naylib

# then run this:
nim compile \
  --define:debug \
  --checks:on \
  --opt:none \
  main.nim \
  && ./main

Mages-Engine

A 2d-Rts game engine with a round based campaign map and
multiple game modes, f.e. medival, fantasy, sci-fi, etc.

You create or load a scenario, which then can be played
in campaign mode.

Architechture: You got main-menu and campaign in this file. Then wou get another 
file for the real time battles. Also each mod is added at compile-time via 
a mods/<name>/load.nim file. Also we might have a ai file for the campaign, since 
ai is hard...
-> The rule: If it is dumb: merge it very dense into one file 
             If it is complex: give it a own file and do it more sparse with lots 
             of comments

Camp-Game-Play: 
  - You can only move armies: merge, occupy, fight
  - you can upgrade armies tech-wise or recruite new units
  - mineral patches are more valuable


Pathfinging-via Threads
https://nim-by-example.github.io/channels/
Prob not needed, since we can just make a "slow" battle, so the player can 
actually have an impact on the battle itself.

TODOS:
- [ ] First create all campaign ui elements...
- [ ] Add the faction money
- [ ] Move the world with drag and drop -> this would make army movment nice
- [ ] resources
- [ ] factories
- [ ] movement with arrow keys on enemy and own, also merge
- [ ] astar
- [ ] Do the movment based on a queue of movement-commands
- [ ] faction-relation view
- [ ] all buttons/ui mockups
- [ ] save and load
- [ ] basic diplomacy
- [ ] basic enemy army movement

]]##
import std/[sequtils, math, random, strutils,tables, hashes,options,oids,os,files,deques]
import raylib
import raymath

import ui/Button # include my own button function

const TileSizePixel = 124;
const WorldWidth_in_tiles = 20; const WorldHeight_in_tiles = 20
const WorldWidth_in_pixels = WorldWidth_in_tiles * TileSizePixel; const WorldHeight_in_pixels = WorldHeight_in_tiles * TileSizePixel

#region type-definitions
type

  FactionRelationState = enum Peace, Alliance, War
    ## Factions are related to each other. The relation has always a state.

  FactionRelationEvent = ref object
    ## different events on the campaign map can change the relation between
    ## factions. Each such event cretaes an faction relation event.
    ## The effect of the event deminishes over time.
    ## After a certain amount of turns the event is deleted.
    ## The current relation is calculated by the sum of all events between two
    ## factions.
    faction_one: int
    faction_two: int
    relation_change: int
    description: string
    deleted_in_turns: int

  Faction = ref object
    ## This represents a faction on the campaign map.
    is_player_faction: bool
    name: string
    description: string
    defeated: bool
    index: int ##\
      ## Index in the list of factions within the scenario.
      ## If a faction dies it is set to defeated, but it still continues to exist.
      ## So factions are never deleted from memory or from the save files !!!
      ## Ids are persistent.
    color: Color
    money: int

  Scenario = ref object
    ## You can load a scenario as part of a campaign, but you can also
    ## create one on the fly in the scenario editor.
    ## Scenario is a game, that you can also save and load.
    ## it contains only the campaign map data, since all rts battles are
    ## created on demand.
    name: string
    description: string
    factions: seq[Faction]
    factions_on_map: Table[string, Faction]
    tiles_map: Table[int, Table[int,Tile]]
    tiles: seq[Tile]
    turn: int
    factions_relations
      : Table[int, tuple[faction_index: int, relation_state: FactionRelationState]]
    faction_relation_events: seq[FactionRelationEvent]

  GameMode = enum Menu, Camp, Battle ## Battle not yet implemented

  CampDisplayMode = enum Default, Diplomacy

  ZoomLevel = enum Mini, VerySmall, Small, Default, Big
    ## Zoomlevel of the campaign map; The zoom changes the way of displaying
    ## the map and the armies on the map.

  Game = ref object
    ## The global state of the game and its "engine"- Contains also all the state
    ## that is not saved into save file.
    mode: GameMode
    display_mode: CampDisplayMode
    selected_tile: Option[Tile]
    scenario: Scenario
    zoom_level: ZoomLevel
    ai_army_movement_tasks: Deque[ArmyMovementTask]
    player_movement_task: Option[ArmyMovementTask]

  TileType = enum Land, Water, Mountain, Minerals

  Tile = ref object
    ## One tile on the campaign map.
    pos: Vector2
    category: TileType
    owner: Option[Faction]
    army: Option[Army]
    faction: Option[Faction]

  Army = ref object
    ## An army on the campaign map.
    faction: Faction
    tile_i_am_on: Tile
    command_points: int
    level: int
    last_moved_at_turn: int

  ArmyMovementTask = ref object
    ## A task for an army to move to a target tile.
    ## This is needed, since we need to decouple a decision for movement from
    ## the actual execution of the movement, so we can wait between ai movements.
    army: Army
    target_tile: Tile

  Logger = ref object
    ## Logging object provided to functions that need to log.
    file: File


#region FN-Helper
# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

func get_tile(self: var Scenario, x_in_world_pixel: float, y_in_world_pixel: float): Option[Tile] =
  let x_as_num = (x_in_world_pixel / TileSizePixel).floor.int
  let y_as_num = (y_in_world_pixel / TileSizePixel).floor.int
  if self.tiles_map.has_key(x_as_num) and self.tiles_map[x_as_num].has_key(y_as_num):
    return some(self.tiles_map[x_as_num][y_as_num])
  else: return none(Tile)

func is_in_world(self: Scenario, x: int, y: int): bool =
  return x >= 0 and x < WorldWidth_in_pixels and y >= 0 and y < WorldHeight_in_pixels

func create_Faction*(
  name: string, is_player_faction: bool, description: string, color: Color, s: Scenario 
): Faction =
  var faction = Faction()
  faction.name = name
  faction.is_player_faction = is_player_faction
  faction.description = description
  faction.color = color
  s.factions.add(faction)
  s.factions_on_map[name] = faction
  return faction

proc log(self: Logger, msg: string) = self.file.write(msg & "\n")

func get_relation(self: Scenario, faction_one: int, faction_two: int): int =
  ## Calculate the relation-number (not neccessarily the relation state) between
  ## two factions.
  var base_relation = 50; var counter = 0
  for event in self.faction_relation_events:
    if event.faction_one == faction_one and event.faction_two == faction_two or
      event.faction_one == faction_two and event.faction_two == faction_one:
      base_relation += event.relation_change; counter += 1
  return floor(base_relation / counter).int

#region init raylib
#-------------------------------------------------------------------------------
# Init logger and raylib stuff
#-------------------------------------------------------------------------------
const logfile_name = "log.txt"; if fileExists(logfile_name): removeFile(logfile_name)
var logger = Logger(file: open(logfile_name, fmAppend)); logger.log("Start Mages Engine")
setTraceLogLevel(TraceLogLevel.Error);initWindow(1900, 1080, "example"); setWindowMonitor(0)
var camera = Camera2D(target: Vector2(x: 0, y: 0), offset: Vector2(x: 0, y: 0), rotation: 0, zoom: 1)
setTargetFPS(60)
# todo: this makes trouble??
# toggleFullscreen();



# load all resources within the block
# otherwise we get segfault at close window call at the end...
block:
  #region init-mod
  var enter_next_round_cool_down: float = 0

  let ModImages = (
    flat:loadTexture("./mods/lerman/res/flat_0.png"),
    minerals:loadTexture("./mods/lerman/res/minerals_0.png"),
    mountain: loadTexture("./mods/lerman/res/mountain_0.png"),
    water:loadTexture("./mods/lerman/res/water_0.png"),
    menu_background: loadTexture("./mods/lerman/res/background.png")
  )

  let MENU_TEXTURE = loadTexture("./mods/lerman/res/menu.png")
  let MENU_BACKGROUND = (73,81,200,200)

  proc draw_from_menu_atlas(x, y, width, height, rotation: float, src: (int,int,int,int)) =
    let source_x = src[0].float; let source_y = src[1].float
    let source_w = src[2].float - source_x; let source_h = src[3].float - source_y
    let source_rect = Rectangle(x: source_x, y: source_y, width: source_w, height: source_h)
    let dest_rect = Rectangle(x: x, y: y, width: width, height: height)
    let origin = Vector2(x: 0, y: 0)
    drawTexture(MENU_TEXTURE, source_rect, dest_rect, origin, rotation, WHITE)

  proc populate_scenario(self: var Scenario, L: Logger) =
    for data in [
      ("Player", true, "some desc", Color(r:0,g:255,b:0,a:255)),
      ("Dörr", false, "some desc", Color(r:0,g:0,b:255,a:255)),
      ("Wusel", false, "some desc", Color(r:255,g:255,b:0,a:255)),
      ("Woki", false, "some desc", Color(r:64,g:224,b:208,a:255)),
      ("Schnubbel", false, "some desc", Color(r:64,g:44,b:44,a:255)),
      ("Kek", false, "some desc", Color(r:255,g:0,b:0,a:255))]:
      discard create_Faction(
        name=data[0], is_player_faction=data[1], description=data[2],color=data[3],self)
   
    for x in 0..WorldWidth_in_tiles-1: # generate a random scenario
      var tab = initTable[int, Tile](); self.tiles_map[x] = tab
      for y in 0..WorldHeight_in_tiles-1:
        var tile = Tile()
        tile.pos = Vector2(x:x.float * TileSizePixel, y:y.float * TileSizePixel)
        self.tiles_map[x][y] = tile; self.tiles.add(tile)
        tile.category
          = case rand(0..99)
            of 0..65: TileType.Land
            of 66..70: TileType.Minerals
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


  var game = Game()
  game.mode = GameMode.Menu
  game.scenario = Scenario()
  game.scenario.turn = 1
  var running = true
  var button_click_event: string = ""


  # directly start with a rng game to get the basic game loop working, remove this later
  game.scenario.populate_scenario(logger)
  game.mode = GameMode.Camp
  #region game-loop
  while running: 

    let delta_time = getFrameTime(); if windowShouldClose(): running = false
    update_button_cooldown(delta_time) # see ui/Button.nim

    # update here the game state
    case game.mode:
      #region menu
      of GameMode.Menu:
        if button_click_event != "": # handle button clicks ...
          case button_click_event:
            of "start_new_game":
              game.scenario.populate_scenario(logger)
              game.mode = GameMode.Camp
            of "exit": running = false
            of "": discard
            else: logger.log("[IGNORED] unknown menu button event: " & button_click_event)
          button_click_event = ""
      #------------------------------------------------------------------------#
      # Default campaign mode handle code.
      #------------------------------------------------------------------------#
      of GameMode.Camp:
        #region camp

        if button_click_event != "": # handle all button clicks
          #region NEXT-ROUND
          case button_click_event:
            of "next_round":  # handle all the computation if a new round is started
              game.scenario.turn += 1  # update to the next turn (resets the movment of the armies)
              logger.log("next round")
              # todo: apply all the income
              for t in game.scenario.tiles:
                if t.faction.isSome:
                  let f = t.faction.get
                  let income = case t.category:
                    of TileType.Land: 10
                    of TileType.Minerals: 100
                    else: 0
                  f.money += income  
              # todo: call the ai-processing
            of "": discard
            else: logger.log("[IGNORED] unknown camp button event: " & button_click_event)
          button_click_event = ""

        let speed = 400f * delta_time
        # based on the current zoom, we need to scroll faster or slower
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

        # handle the zoom with the mouse wheel
        let moved = getMouseWheelMove()
        if moved != 0:
          let zoom_delta = moved * 0.1; let old_zoom = camera.zoom
          camera.zoom += zoom_delta; if camera.zoom < 0.1: camera.zoom = 0.1
          let new_zoom = camera.zoom
          # Adjust the camera target to keep the center position the same
          let screen_center = Vector2(x: getScreenWidth().float / 2.0, y: getScreenHeight().float / 2.0)
          let world_center_before = Vector2(
            x: (screen_center.x - camera.offset.x) / old_zoom + camera.target.x,
            y: (screen_center.y - camera.offset.y) / old_zoom + camera.target.y)
          let world_center_after = Vector2(
            x: (screen_center.x - camera.offset.x) / new_zoom + camera.target.x,
            y: (screen_center.y - camera.offset.y) / new_zoom + camera.target.y)
          camera.target.x -= world_center_after.x - world_center_before.x
          camera.target.y -= world_center_after.y - world_center_before.y
        let mouse_pos = getMousePosition()
        # select a tile with the mouse ...
        if isMouseButtonPressed(MouseButton.Left):
          let x = (mouse_pos.x * 1/camera.zoom) + camera.target.x
          let y = (mouse_pos.y * 1/camera.zoom) + camera.target.y
          let tile = game.scenario.get_tile(x, y)
          # here is the place to check, that we are actually not behind the ui
          let right_padding = if game.selected_tile.is_some: 400 else: 0
          let top_padding = 60
          if mouse_pos.x.int < getScreenWidth() - right_padding and mouse_pos.y.int > top_padding:
            if tile.isSome: game.selected_tile = tile
            else: game.selected_tile = none(Tile)
          else: discard # dont do anything if we are in the ui, since we want to click ui buttons there ...
        if isMouseButtonPressed(MouseButton.Right): game.selected_tile = none(Tile)
        if isMouseButtonDown(MouseButton.Middle):
          let delta = getMouseDelta();camera.target.x -= delta.x * zoom_factor; camera.target.y -= delta.y * zoom_factor
        #region army-movement  
        #-----------------------------------------------------------------------
        # handle movement of armies by player: Create movement task
        #-----------------------------------------------------------------------
        if game.selected_tile.is_some:
          let tile = game.selected_tile.get
          if tile.faction.isSome:
            if tile.faction.get.is_player_faction:
              if tile.army.is_some and tile.army.get.last_moved_at_turn != game.scenario.turn:
                var move_to = none(Tile)
                if isKeyPressed(KeyboardKey.Left):
                  let left_one = game.scenario.get_tile(tile.pos.x - TileSizePixel, tile.pos.y)
                  if left_one.is_some: move_to = left_one;logger.log("move to left")
                if isKeyPressed(KeyboardKey.Right):
                  let right_one = game.scenario.get_tile(tile.pos.x + TileSizePixel, tile.pos.y)
                  if right_one.is_some: move_to = right_one;logger.log("move to right")
                if isKeyPressed(KeyboardKey.Up):
                  let up_one = game.scenario.get_tile(tile.pos.x, tile.pos.y - TileSizePixel)
                  if up_one.is_some: move_to = up_one;logger.log("move to up")
                if isKeyPressed(KeyboardKey.Down):
                  let down_one = game.scenario.get_tile(tile.pos.x, tile.pos.y + TileSizePixel)
                  if down_one.is_some: move_to = down_one;logger.log("move to down")
                # there could be a valid tile to move an army to ...
                if move_to.is_some() and move_to.get.category == TileType.Land:
                  game.player_movement_task = some(
                    ArmyMovementTask(army: tile.army.get,target_tile: move_to.get))

        # Get the player task or the one task from the list of ai tasks and
        # place this task into a task-option variable to be handled further down
        let task
          = if game.player_movement_task.isSome:
            let ret = game.player_movement_task
            game.player_movement_task = none(ArmyMovementTask)
            ret
          elif game.ai_army_movement_tasks.len > 0: some(game.ai_army_movement_tasks.popFirst())
          else: none(ArmyMovementTask)

        # if a task is to be done, execute the task
        if task.is_some:
          let task = task.get
          var movment_success = false
          let army = task.army
          let source_tile = army.tile_i_am_on
          let target_tile = task.target_tile
          if target_tile.faction.isNone: # occupy free tile
            target_tile.army = game.selected_tile.get.army
            source_tile.army = none(Army)
            target_tile.army.get.tile_i_am_on = target_tile
            target_tile.faction = source_tile.faction
            assert(target_tile.faction.isSome)
            movment_success = true
          elif target_tile.faction.get == source_tile.faction.get:
            if target_tile.army.is_some:
              discard # merge armies, higher tech level
            else:
              discard # just go there
          else:
             # attack (only on war)
             discard
          if movment_success: target_tile.army.get.last_moved_at_turn = game.scenario.turn

      of GameMode.Battle:
        #region battle
        discard # not yet implemented
    #--------------------------------------------------------------------------#
    # End of game logic handling ...
    #--------------------------------------------------------------------------#

    beginDrawing()
    clearBackground(RAYWHITE)

    case game.mode:

      #region Draw Menu
      of GameMode.Menu:
        block:
          drawTexture(ModImages.menu_background, 0, 0, WHITE)
          drawText("Lerman", 350, 10, 70, WHITE);
          if Button(text= "Start", pos= Vector2(x: 100, y: 100), width= 100,height= 50): button_click_event = "start_new_game"
          if Button(text= "Exit",pos= Vector2(x: 100, y: 200),width= 100,height= 50 ): button_click_event = "exit"


      of GameMode.Camp:
        block:
          #region draw camp-world
          beginMode2D(camera); let screen_w = getScreenWidth(); let screen_h = getScreenHeight()
          for tile in game.scenario.tiles:
            let in_view = checkCollisionRecs(
              Rectangle(x: camera.target.x * camera.zoom, y: camera.target.y * camera.zoom, width: screen_w.float, height: screen_h.float),
              Rectangle(x: tile.pos.x * camera.zoom, y: tile.pos.y * camera.zoom, width: TileSizePixel * camera.zoom, height: TileSizePixel * camera.zoom))
            if not in_view: continue
            case tile.category # draw textures of the tiles
              of TileType.Land: drawTexture(ModImages.flat,tile.pos,WHITE)
              of TileType.Water: drawTexture(ModImages.water,tile.pos,WHITE)
              of TileType.Mountain: drawTexture(ModImages.mountain,tile.pos,WHITE)
              of TileType.Minerals: drawTexture(ModImages.minerals,tile.pos,WHITE)

            # draw a faction colored border around the tile
            if tile.faction.isSome:
              let faction = tile.faction.get; let color = faction.color
              if game.zoom_level == ZoomLevel.Mini:
                drawRectangle( Rectangle(x: tile.pos.x,y: tile.pos.y, width: TileSizePixel, height: TileSizePixel), color)
              else:
                # outline in the color of the owning faction
                drawRectangleLines(Rectangle(x: tile.pos.x,y: tile.pos.y,width: TileSizePixel,height: TileSizePixel), 3, color)
                # draw a rect with some alpha in the color of the owning faction
                drawRectangle(Rectangle(x: tile.pos.x,y: tile.pos.y,width: TileSizePixel,height: TileSizePixel),fade(color, 0.15))

            # draw armies on the tile if not zoomed out to far
            if tile.army.isSome and game.zoom_level != ZoomLevel.Mini:
              assert tile.faction.isSome; let army = tile.army.get
              var visibilitiy_blocks = (army.command_points / 100).ceil.int
              let square_numbers = visibilitiy_blocks.float.sqrt().ceil
              let square_size = 4f; let space_between = 2; let space_around = 2f
              let witdh = square_numbers * square_size + (square_numbers + 1) * space_between.float + space_around * 2
              let extra_space = (TileSizePixel - witdh) / 2; var drawn_blocks = 0
              let x_rect_start = tile.pos.x + extra_space; let y_rext_start = tile.pos.y + extra_space
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

              # draw rect directly around the army; 2 lines thick
              drawRectangleLines(
                Rectangle( x: x_rect_start - space_around, y: y_rext_start - space_around, width: witdh, height: witdh), 
                2,
                # if this army is moved this turn, make white border
                if tile.army.get.last_moved_at_turn == game.scenario.turn: WHITE else: tile.faction.get.color)

              # draw the strenght of the army in the top-left tile corner
              let command_points = army.command_points
              let level = army.level
              let display_string = $command_points & " - " & $level
              drawText(display_string, (tile.pos.x + 4).int32, (tile.pos.y + 4).int32, 20, WHITE)


          # --------------------------------------------------------------------
          # end of tile drawing
          # --------------------------------------------------------------------

          # draw outline around selected tile
          if game.selected_tile.isSome:
            let selected = game.selected_tile.get
            drawRectangleLines(
              Rectangle(x: selected.pos.x,y: selected.pos.y,width: TileSizePixel,height: TileSizePixel),
              2, raylib.WHITE)

          endMode2D()
          # end the camera : this means here comes the ui
          # this means all drawing, that is not affected by zooming and scrolling
          #region draw camp UI
          let menu_width = 400f
          let menu_start = getScreenWidth().float - menu_width
          let top_bar_height = 40f
          let menu_height = getScreenHeight().float - top_bar_height
          let top_bar_width = getScreenWidth().float # - menu_width

          # draw the top bar
          draw_from_menu_atlas(x=0, y=0, width=top_bar_width, height=top_bar_height, rotation=0f,src=MENU_BACKGROUND)

          # draw the next round button; handle enter click 
          if Button(text= "Next Round",pos= Vector2(x: 10, y: 10),width= 100,height= 20) or isKeyPressed(KeyboardKey.Enter) and 
            enter_next_round_cool_down < 0: button_click_event = "next_round"; enter_next_round_cool_down = 1.0
          enter_next_round_cool_down = enter_next_round_cool_down - delta_time

          # draw the amount of player money
          for f in game.scenario.factions:
            if f.is_player_faction: 
              drawText(( $f.money & "$"), (130).int32, (10).int32, 20, BLACK)
 
          if game.selected_tile.isSome: # if some tile is selected, draw the data of the tile
            draw_from_menu_atlas(menu_start, top_bar_height, menu_width, menu_height, rotation=0f, src=MENU_BACKGROUND)
            let tile_data = game.selected_tile.get
            drawText(("Tile: " & $tile_data.category), (menu_start + 10).int32, (10+top_bar_height).int32, 20, BLACK)
            drawText(("Pos: " & $tile_data.pos), (menu_start + 10).int32, (30+top_bar_height).int32, 20, BLACK)
            if tile_data.faction.isSome:
              let faction = tile_data.faction.get
              drawText(("Faction-Owner: " & $faction.name), (menu_start + 10).int32, (50+top_bar_height).int32, 20, faction.color)
              if faction.is_player_faction == false:
                # todo: draw the relation state in the color of the relation: enemy: red, ally: green, neutral black
                drawText("RELARTION-STATE XXX", (menu_start + 10).int32, (120+top_bar_height).int32, 20, BLACK)
                # todo: draw the relation number on a color spctrum from green to red
                drawText("RELARTION-NUMBER XXX", (menu_start + 10).int32, (140+top_bar_height).int32, 20, BLACK)
                # todo: display some debug information here about the faction....
            else:
              drawText("No Faction", (menu_start + 10).int32, (50+top_bar_height).int32, 20, BLACK)
              drawText(("Type: " & $tile_data.category), (menu_start + 10).int32, (70+top_bar_height).int32, 20, BLACK)
            if tile_data.army.isSome:
              drawText(("Army - Command Points: " & $tile_data.army.get.command_points), (menu_start + 10).int32, (90+top_bar_height).int32, 20, BLACK)
            else: drawText("No Army", (menu_start + 10).int32, (90+top_bar_height).int32, 20, BLACK)
      
      # end of campaign drawing

      else: discard # no other game mode exists yet

    # --------------------------------------------------------------------------
    # end of game drawing logic
    # --------------------------------------------------------------------------

    # draw ret circlertin the middle of the screen
    # drawCircle(Vector2(x:getScreenWidth() / 2-10, y: getScreenHeight() / 2)-10, 20, RED)

    #region debug info
    # --------------------------------------------------------------------------
    # Draw some debug information
    # --------------------------------------------------------------------------
    when defined(debug):
      if game.mode == GameMode.Camp:
        let top_bar_height = 40; let fps = getFPS(); let mouse_pos = getMousePosition()
        drawText("FPS: " & $fps, 10, (10+top_bar_height).int32, 20, RED)
        drawText("Camera: " & $camera.target, 10, (30+top_bar_height).int32, 20, RED)
        drawText("Zoom: " & $camera.zoom, 10, (50+top_bar_height).int32, 20, RED)
        drawText("Mouse: " & $mouse_pos, 10, (70+top_bar_height).int32, 20, RED)
        drawText("Zoom Level: " & $game.zoom_level, 10, (90+top_bar_height).int32, 20, RED)

    endDrawing()
    # --------------------------------------------------------------------------
    # end of the game loop
    # --------------------------------------------------------------------------

closeWindow()