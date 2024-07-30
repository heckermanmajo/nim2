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
import std/[sequtils, math, random, strutils,tables, hashes,options,oids,os,files,deques]


# Profiling support for Nim. This is an embedded profiler that
# requires --profiler:on. You only need to import this module to
# get a profiling report at program exit.
import std/nimprof

import raylib
import raymath

# engine modules ...
import src/config
import src/types
import src/utils
import src/game_utils
import src/battle

var game = Game(
  camera: Camera2D(
    target: Vector2(x: 0, y: 0),
    offset: Vector2(x: 0, y: 0),
    rotation: 0,
    zoom: 1),
  logfile: open(LOGFILE_NAME, fmWrite),
  wasd_move_speed: 800,
  zoomFactor: 1,
  mouse_middle_drag_speed: 7000,
  zoom_level: ZoomLevel.Default,
  battle: Battle(
    chunks: block:
      var chunks = newSeq[Chunk]()
      for x in 0..chunks_per_side:
        for y in 0..chunks_per_side:
          chunks.insert (Chunk(
            units: newSeq[Unit](),
            x: x, y: y ))
      chunks,
    chunks_on_xy:initTable[int, Table[int, Chunk]](),
    units: newSeq[Unit]()))

game.battle.game = game

for chunk in game.battle.chunks:
  if not game.battle.chunks_on_xy.hasKey(chunk.x):
    game.battle.chunks_on_xy[chunk.x] = initTable[int, Chunk]()
  game.battle.chunks_on_xy[chunk.x][chunk.y] = chunk


## create random units
for i in 0..10:
  let x = rand(0..WORLD_MAX_X).float
  let y = rand(0..WORLD_MAX_Y).float
  game.battle.units.add(
    block:
      var chunk = game.battle.get_chunk_by_xy(x.int,y.int)
      let unit = Unit(
        shape:Rectangle(x:x,y:y,width:32,height:32),
        chunk_i_am_on: chunk)
      chunk.units.add(unit)
      unit)


game.log("Start mages demo ... ")

#-------------------------------------------------------------------------------
# Init logger and raylib stuff
#-------------------------------------------------------------------------------
setTraceLogLevel(TraceLogLevel.Error)
initWindow(1900, 1080, "Mages - Demo")
setWindowMonitor(0)

# toggleFullscreen();

#let Images = (
#  unit: [
#    #loadTexture("./mods/lerman/res/flat_0.png"),
#  ]
#)


# load all resources within the block
# otherwise we get segfault at close window call at the end...
block:

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

    # mouse clicks/selections -> mutable Options. Can be set to none by the ui if they are
    # consumed by the ui.
    var selection_rect_or_empty: Option[tuple[screen_relative: Rectangle, world_relative: Rectangle]] = game.get_left_mouse_drag_selection_rect_and_draw_it()
    var left_click_on_the_screen: Option[tuple[screen_relative: Vector2, world_relative: Vector2]]
      = game.get_click_on_the_screen(MouseButton.Left)
    var right_click_on_the_screen: Option[tuple[screen_relative: Vector2, world_relative: Vector2]]
      = game.get_click_on_the_screen(MouseButton.Right)

    if selection_rect_or_empty.isSome:
      game.battle.currently_selected_units = @[]
      for u in game.battle.units:
        if get_overlap(u.shape, selection_rect_or_empty.get.world_relative).isSome:
          game.battle.currently_selected_units.add(u)

    if game.battle.currently_selected_units.len != 0:
      if right_click_on_the_screen.isSome:
        let target = game.battle.get_chunk_by_xy_optional(
          x= right_click_on_the_screen.get.world_relative.x.int,
          y= right_click_on_the_screen.get.world_relative.y.int)
        if target.isSome:
          for u in game.battle.currently_selected_units:
            # todo: improve this into a formation ...
            let delta = game.battle.currently_selected_units.len.float * 32.float
            let target_x = right_click_on_the_screen.get.world_relative.x + game.world_sanatize_x(rand( -delta .. delta ))
            let target_y = right_click_on_the_screen.get.world_relative.y + game.world_sanatize_y(rand( -delta .. delta ))

            u.move_target = some(Vector2(
              x: target_x,
              y: target_y))


    game.battle.move_units(dt=delta_time)


    # --------------------------------------------------------------------------
    # START of game drawing logic
    # --------------------------------------------------------------------------

    beginDrawing()
    clearBackground(LIGHT_GRAY)

    beginMode2D(game.camera);

    when(config.DEBUG):
      game.draw_chunk_outline_and_units_in_it()

    game.battle.draw_all_units(delta_time)
    game.battle.draw_rect_around_selected_units(delta_time)

    endMode2D()

    # --------------------------------------------------------------------------
    # end of game drawing logic
    # --------------------------------------------------------------------------

    # --------------------------------------------------------------------------
    # Draw some debug information
    # --------------------------------------------------------------------------

    when(config.DEBUG):
      let top_bar_height = 40
      let fps = getFPS()
      drawText("FPS: " & $fps, 10, (10+top_bar_height).int32, 20, RED)
      drawText("Camera: " & $game.camera.target, 10, (30+top_bar_height).int32, 20, RED)
      drawText("Zoom: " & $game.camera.zoom, 10, (50+top_bar_height).int32, 20, RED)
      let mouse_pos = getMousePosition()
      drawText("Mouse: " & $mouse_pos, 10, (70+top_bar_height).int32, 20, RED)
      # cam target
      #drawText("Cam target: " & $game.camera.target.x & " - " & $game.camera.target.y, 10, (90+top_bar_height).int32, 20, RED)
    # zoom level
      drawText("Zoom Level: " & $game.zoom_level, 10, (90+top_bar_height).int32, 20, RED)

    endDrawing()
    # --------------------------------------------------------------------------
    # end of the game loop
    # --------------------------------------------------------------------------

closeWindow()