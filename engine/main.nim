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
import src/types
import src/game_utils

const DEBUG = true
const LOGFILE_NAME = "log.txt"

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

for chunk in game.battle.chunks:
  if not game.battle.chunks_on_xy.hasKey(chunk.x):
    game.battle.chunks_on_xy[chunk.x] = initTable[int, Chunk]()
  game.battle.chunks_on_xy[chunk.x][chunk.y] = chunk


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
    var selection_rect_or_empty: Option[Rectangle] = game.get_left_mouse_drag_selection_rect_and_draw_it()
    var left_click_on_the_screen: Option[tuple[screen_relative: Vector2, world_relative: Vector2]]
      = game.get_click_on_the_screen(MouseButton.Left)
    var right_click_on_the_screen: Option[tuple[screen_relative: Vector2, world_relative: Vector2]]
      = game.get_click_on_the_screen(MouseButton.Right)
    # --------------------------------------------------------------------------
    # START of game drawing logic
    # --------------------------------------------------------------------------

    beginDrawing()
    clearBackground(RAYWHITE)

    beginMode2D(game.camera);

    when(DEBUG):
      game.draw_chunk_outline_and_units_in_it()

    endMode2D()

    # --------------------------------------------------------------------------
    # end of game drawing logic
    # --------------------------------------------------------------------------

    # --------------------------------------------------------------------------
    # Draw some debug information
    # --------------------------------------------------------------------------

    when(DEBUG):
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