##[[
nim compile \
  --define:debug \
  --checks:on \
  --opt:none \
  main.nim \
  && ./main
]]##

##[[

Mages-Engine

A 2d-Rts game engine with a round based campaign map and
multiple game modes, f.e. medival, fantasy, sci-fi, etc.

You create or load a scenario, which then can be played
in campaign mode.

Pathfinging-via Threads
https://nim-by-example.github.io/channels/

]]##
#import std/[sequtils, math, random, strutils,tables, hashes,options,oids,os,files,deques]
import std/[random,tables, hashes,options, math]


# Profiling support for Nim. This is an embedded profiler that
# requires --profiler:on. You only need to import this module to
# get a profiling report at program exit.
import std/nimprof

import raylib
import raymath

# engine modules ...
import src/config
import src/types
import src/core
import src/battle
import src/unit
import src/control_group
import src/chunk



var game = Game(
  unit_types: {
    "soldier": UnitType(
      width: 32, 
      height: 32,
      aggro_range: 400,
      attack_range: 36,
      speed: 100
    ),#, texture: loadTexture("./s_blue.png"))
  }.toTable,
  camera: Camera2D(
    target: Vector2(x: 0, y: 0),
    offset: Vector2(x: 0, y: 0),
    rotation: 0,
    zoom: 1),
  logfile: open(LOGFILE_NAME, fmWrite),
  wasd_move_speed: 800,
  zoomFactor: 1,
  mouse_middle_drag_speed: 400,
  zoom_level: ZoomLevel.Default,
  
  battle: Battle(
    factions: {
      "player": Faction(
        name: "SCHMOP",
        player: true,
        color: BLUE
      ),
      "kekkus": Faction(
        name:"kekkus",
        player: false,
        color: RED
      )
    }.toTable,
    chunks: block:
      var chunks = newSeq[Chunk]()
      for x in 0..chunks_per_side:
        for y in 0..chunks_per_side:
          chunks.insert (Chunk(
            units: newSeq[Unit](),
            x: x, y: y ))
      chunks,
    chunks_on_xy:initTable[int, Table[int, Chunk]](),
    units: newSeq[Unit](),
    currently_selected_control_groups: newSeq[ControlGroup]()))

game.battle.game = game

for chunk in game.battle.chunks:
  if not game.battle.chunks_on_xy.hasKey(chunk.x):
    game.battle.chunks_on_xy[chunk.x] = initTable[int, Chunk]()
  game.battle.chunks_on_xy[chunk.x][chunk.y] = chunk

game.battle.create_all_unit_positions_for_chunks()

game.log("Start mages demo ... ")


discard game.battle.create_control_group(
  unity_type = game.unit_types["soldier"], 
  size = 35, 
  start_pos = Vector2(x:100, y: 100),
  faction = game.battle.factions["player"])


discard game.battle.create_control_group(
  unity_type = game.unit_types["soldier"], 
  size = 35, 
  start_pos = Vector2(x:300, y: 100),
  faction = game.battle.factions["player"])


discard game.battle.create_control_group(
  unity_type = game.unit_types["soldier"], 
  size = 35, 
  start_pos = Vector2(x:400, y: 100),
  faction = game.battle.factions["player"])  

discard game.battle.create_control_group(
  unity_type = game.unit_types["soldier"], 
  size = 35, 
  start_pos = Vector2(x:700, y: 700),
  faction = game.battle.factions["kekkus"])

discard game.battle.create_control_group(
  unity_type = game.unit_types["soldier"], 
  size = 35, 
  start_pos = Vector2(x:700, y: 800),
  faction = game.battle.factions["kekkus"])

discard game.battle.create_control_group(
  unity_type = game.unit_types["soldier"], 
  size = 35, 
  start_pos = Vector2(x:700, y: 900),
  faction = game.battle.factions["kekkus"])


#-------------------------------------------------------------------------------
# Init logger and raylib stuff
#-------------------------------------------------------------------------------
setTraceLogLevel(TraceLogLevel.Error)
initWindow(1900, 1080, "Mages - Demo")
setWindowMonitor(0)

setTargetFPS(30);  

#toggleFullscreen();

# load all resources within the block
# otherwise we get segfault at close window call at the end...
block:

  var rotation = 0.0

  var running = true
  while running:

    if windowShouldClose(): running = false
    let delta_time = getFrameTime()

    #--------------------------------------------------------------------------#
    # End of game logic handling ...
    #--------------------------------------------------------------------------#
    
    # move the camera
    game.move_camera_with_wasd(delta_time)
    game.move_world_with_mouse_middle_drag(delta_time)
    game.zoom_in_out(delta_time)
    game.recenter_camera_target_on_map()

    ### RASTER UNIT CONTROL EXPERIMENTS
    #game.battle.draw_rect_raster(get_raster_by_center_and_rotation(
    #  center=getMousePosition(), rotation=rotation,20, numbers=6 
    #), 16) 

    if isKeyPressed(KeyboardKey.Left): rotation = rotation + 0.5
    if isKeyPressed(KeyboardKey.Right): rotation = rotation - 0.5

    # mouse clicks/selections -> mutable Options. Can be set to none by the ui if they are
    # consumed by the ui.
    var selection_rect_or_empty: 
      Option[tuple[screen_relative: Rectangle, world_relative: Rectangle]] 
      = game.get_left_mouse_drag_selection_rect_and_draw_it()
    var left_click_on_the_screen: 
      Option[tuple[screen_relative: Vector2, world_relative: Vector2]]
      = game.get_click_on_the_screen(MouseButton.Left)
    var right_click_on_the_screen: 
      Option[tuple[screen_relative: Vector2, world_relative: Vector2]]
      = game.get_click_on_the_screen(MouseButton.Right)
    
    discard left_click_on_the_screen 


    game.battle.select_control_groups_with_mouse_selection_drag(selection_rect_or_empty)
    game.battle.set_move_target_for_control_groups(delta_time, right_click_on_the_screen)
    
    game.battle.think_all_units(dt=delta_time)
    game.battle.fight_units(dt=delta_time)
    game.battle.join_fight_with_all_units(dt=delta_time)
    game.battle.move_units(dt=delta_time)
    game.battle.manage_unit_deaths(dt=delta_time)
    game.battle.update_control_all_group_centers()
    game.battle.manage_control_group_deaths()

    game.battle.collide_units_with_each_other(dt=delta_time)
    game.battle.apply_unit_collision_velocity(dt=delta_time)

    game.battle.check_i_group_can_reset_mode_to_idle_and_if_so_do_it(dt=delta_time)


    # --------------------------------------------------------------------------
    # START of game drawing logic
    # --------------------------------------------------------------------------

    beginDrawing()
    clearBackground(BLACK)

    beginMode2D(game.camera);

    when(config.DEBUG):
      game.draw_chunk_outline_and_units_in_it()

    game.battle.draw_all_units(delta_time)
    game.battle.draw_rect_around_selected_units(delta_time)


    endMode2D()

    # --------------------------------------------------------------------------
    # end of game drawing logic
    # --------------------------------------------------------------------------

    #  UI

    game.battle.display_selected_group_info()


    # --------------------------------------------------------------------------
    # Draw some debug information
    # --------------------------------------------------------------------------

    when(config.DEBUG):
      let top_bar_height = 40
      let fps = getFPS()
      drawText(("FPS: " & $fps).cstring, 10, (10+top_bar_height).int32, 20, WORLD_COLOR)
      drawText(("Camera: " & $game.camera.target).cstring, 10, (30+top_bar_height).int32, 20, WORLD_COLOR)
      drawText(("Zoom: " & $game.camera.zoom).cstring, 10, (50+top_bar_height).int32, 20, WORLD_COLOR)
      let mouse_pos = getMousePosition()
      drawText(("Mouse: " & $mouse_pos).cstring, 10, (70+top_bar_height).int32, 20, WORLD_COLOR)
      # cam target
      #drawText("Cam target: " & $game.camera.target.x & " - " & $game.camera.target.y, 10, (90+top_bar_height).int32, 20, RED)
    # zoom level
      drawText(("Zoom Level: " & $game.zoom_level).cstring, 10, (90+top_bar_height).int32, 20, WORLD_COLOR)

    endDrawing()
    # --------------------------------------------------------------------------
    # end of the game loop
    # --------------------------------------------------------------------------

closeWindow()