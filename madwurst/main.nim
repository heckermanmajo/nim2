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

  let texture = loadTexture("gras.png")
  var rotation = 0.0
  var running = true

  while running:

    if windowShouldClose(): running = false
    let delta_time = getFrameTime()

   
    beginDrawing()

    drawTexture(texture, posX=100, posY=100, tint=WHITE)



    endMode2D()


    endDrawing()
    # --------------------------------------------------------------------------
    # end of the game loop
    # --------------------------------------------------------------------------

closeWindow()