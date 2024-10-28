##[[

  Main module.

  This module is designed to be the entry point for understanding of the code 
  base; therefore read this document first and top to bottom.


]]##

#[[

  - campaign card -> like in the prototype before
  - resource based rts battles -> like fertile cresent
  - campaign-command points are used for actions on the 
    campaign map, like movement
  - the tech level and commander is translated into 
    the battle map  
  - neutral mini-factions on each map, that you can win 
    over, enslave, etc.  
  - we start the first engine with a top down, warcraft 2 
    style and in the second version of the game 
    move to isometric
  - tile based fighting and movment system
  - Chunks exist, but only for ai purposes  
  - battle-maps are persistant -> warhammer 40k
  - demo version in abstract: no sprites, just colored shapes

----- CODE STRUCTURE -----

 - We keep the idea of controller, they are functions
   that take in all their state
 - there is a get_game function to get the global state
 - game contains all instances as list and as a 
   map mapped on their index in the array     
 - Also each object has a unique id that is used for loading
   and saving, but is not used during the game
 - Each type has methods -> a method is used to change 
   the state of the object
 - The engine is split in 3 main parts:
   1. Menu, 2. Campaign, 3. Battle  
 - There is a basetype unit and then more
   special instances. They are composed 
 - astar pathfinding is done only n per iteration
   so units dont move all at once, but after each other  
 - predefine functions at the top of a file and 
   order the functions so, that the lesser used functions are at the 
   bottom

--- Engine-inner-workings ---

 - start engine in diffreent modes: direct battle, direct camp, menu
 - based on the passed in params
 - log important state changes -> log file system

]]#

# all imports are always in the following order:
# 1. std-lib imports
import std/tables
import std/options
# Profiling support for Nim. This is an embedded profiler that
# requires --profiler:on. You only need to import this module to
# get a profiling report at program exit.
when not defined(release):
  import std/nimprof
# 2. vendor-lib imports (raylib)
import raylib
# 3. Config file (its nim, but only contains CONSTANTS)
import CONFIG
# 4. Utils and shared game systems
import diplomacy
import ui
import utils
# 5. The 4 "Game-meta-modules"
import camp/camp_types
import menu/menu_types
import engine/engine_types
import battle/battle_types
import battle/fn/init_battle
import battle/fn/get_path
import battle/methods/chunk_methods
import battle/methods/battle_methods
import battle/methods/btile_methods
import battle/systems/draw_battle
import battle/systems/move_battle_cam
import battle/systems/handle_mouse_click_and_drag
import battle/systems/game_mode_change_on_keypress
log("Engine started")

#-------------------------------------------------------------------------------
# Init logger and raylib stuff
#-------------------------------------------------------------------------------
setTraceLogLevel(TraceLogLevel.Error)
initWindow(1900, 1080, "Mages - Demo")
setWindowMonitor(0)
# setTargetFPS(30);  
# toggleFullscreen();

# get the memory needed at the top level
# all 4 main parts of the engine are avilable via their global getter function
# look into the types files; The global getter returns a singleton; there is only 
# always one instance of engine, battle, camp and menu;
let engine = engine()
let battle = battle()
let camp = camp()
let menu = menu()

# load all raylib-dependent resources within the block
# this means all images, sounds, etc.
# otherwise we get segfault at close window call at the end...
block:

  engine.load_all_extern_media()

  # todo: make this dependent on the start mode passed in by params
  battle.init()

  var running = true
  while running:

    if windowShouldClose(): running = false # escape and X in the right corner
    let delta_time = getFrameTime()

    #--------------------------------------------------------------------------#
    # START of game logic handling ...
    #--------------------------------------------------------------------------#
    case engine.mode:
      of EM_Battle:
        # call all battle systems here -> folder: battle_systems
        battle.move_battle_cam(dt=delta_time)
        battle.game_mode_change_on_keypress(dt=delta_time)
      of EM_Camp: discard
      of EM_Menu: discard

    # --------------------------------------------------------------------------
    # START of game drawing logic
    # --------------------------------------------------------------------------

    beginDrawing()
    clearBackground(BLACK)
    
    case engine.mode:
      of EM_Battle: 
        battle.draw()
        battle.handle_mouse_click_and_drag(dt=delta_time)
      of EM_Camp: discard
      of EM_Menu: discard

    endDrawing()
    # --------------------------------------------------------------------------
    # end of the game loop
    # --------------------------------------------------------------------------
  
  for c in battle.chunks: 
    c.clean_raylib_resources_to_prevent_segfault()
  engine.clear_raylib_resources_to_prevent_segvault()


closeWindow()
engine.close()