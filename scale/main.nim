#[[

  Scale-Engine.


]]#

import std/[random,tables, hashes,options, math]
import std/nimprof
import raylib
import raymath


import engine/Engine
import engine/battle/systems/BattleCollisionSystem
import engine/battle/systems/BattleControlGroupSystem
import engine/battle/systems/BattleDrawSystem
import engine/battle/Battle


setTraceLogLevel(TraceLogLevel.Error)
initWindow(1900, 1080, "ScaleEngine")
setWindowMonitor(0)
setTargetFPS(30);  

var engine = get_engine()

block:

  var running = true

  while running:

    if windowShouldClose(): running = false
    let delta_time = getFrameTime()

    case engine.mode:

      of EngineMode.Battle:
        BattleCollisionSystem(engine.battle)
        BattleControlGroupSystem(engine.battle)

      of EngineMode.Camp:
        discard 

      of EngineMode.Menu:
        discard

    beginDrawing()

    case engine.mode:
    
      of EngineMode.Battle:
        BattleDrawSystem(engine.battle)

      of EngineMode.Camp:
        discard 

      of EngineMode.Menu:
        discard


    endMode2D()

    endDrawing()

closeWindow()    