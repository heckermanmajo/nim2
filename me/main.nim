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

# 2. vendor-lib imports (raylib)
import raylib

# 3. Config file (its nim, but only contains CONSTANTS)
import CONFIG

# 4. Needed types; contain all types and type-centered procs (methods)
import battle_types
import camp_types
import menu_types
import engine_types

# 5. Utils and shared game systems
import diplomacy
import serializer
import ui
import utils

# 6. The systems: battle_systems, camp_systems, menu_systems 
import battle_systems/draw_battle
import battle_systems/move_battle_cam
import battle_systems/handle_mouse_click_and_drag


log("Engine started")

###########################################
#############################################
############################################

###########################################
#############################################
############################################

# todo; for optimization, we can use a bigger grid for less fine grained navigation
# how to use astar in our system:
# the cost of walking is determined by how many other want to walk this tile
# a negative cost determines if it is passable or not  


import lib/astar, hashes

type
    Grid = seq[seq[int]]
        ## A matrix of nodes. Each cell is the cost of moving to that node

    Point = tuple[x, y: int]
        ## A point within that grid

template yieldIfExists( grid: Grid, point: Point ) =
    ## Checks if a point exists within a grid, then calls yield it if it does
    let exists =
        point.y >= 0 and point.y < grid.len and
        point.x >= 0 and point.x < grid[point.y].len
    if exists:
        yield point

iterator neighbors*( grid: Grid, point: Point ): Point =
    ## An iterator that yields the neighbors of a given point
    yieldIfExists( grid, (x: point.x - 1, y: point.y) )
    yieldIfExists( grid, (x: point.x + 1, y: point.y) )
    yieldIfExists( grid, (x: point.x, y: point.y - 1) )
    yieldIfExists( grid, (x: point.x, y: point.y + 1) )

proc cost*(grid: Grid, a, b: Point): float =
    ## Returns the cost of moving from point `a` to point `b`
    float(grid[a.y][a.x])

proc heuristic*( grid: Grid, node, goal: Point ): float =
    ## Returns the priority of inspecting the given node
    asTheCrowFlies(node, goal)

# A sample grid. Each number represents the cost of moving to that space
let grid = @[
    @[ 0, 0, 0, 0, 0 ],
    @[ 0, 3, 3, 3, 0 ],
    @[ 0, 3, 5, 3, 0 ],
    @[ 0, 3, 3, 3, 0 ],
    @[ 0, 0, 0, 0, 0 ]
]

let start: Point = (x: 0, y: 3)
let goal: Point = (x: 4, y: 3)

# Pass in the start and end points and iterate over the results.
for point in path[Grid, Point, float](grid, start, goal):
    echo point


###########################################
#############################################
############################################

###########################################
#############################################
############################################


proc draw_battle*() = 
  #beginMode2D(game.camera);
  #endMode2D()
  discard
proc debug_information*() = discard
proc select_units*() = discard
proc move_units*() = discard
proc do_needed_pathfinding*() = discard
proc ai_thinking*() = discard
proc unit_thinking*() = discard
proc fight_units*() = discard
proc work_units*() = discard
proc produce_buildings*() = discard
proc draw_camp*() = discard


# get the memory needed at the top level
# all 4 main parts of the engine are avilable via their global getter function
# look into the types files; The global getter returns a singleton; there is only 
# always one instance of engine, battle, camp and menu;
let engine = engine()
let battle = battle()
let camp = camp()
let menu = menu()


# todo: make this dependent on the start mode passed in by params
battle.init()
  

#-------------------------------------------------------------------------------
# Init logger and raylib stuff
#-------------------------------------------------------------------------------
setTraceLogLevel(TraceLogLevel.Error)
initWindow(1900, 1080, "Mages - Demo")
setWindowMonitor(0)
setTargetFPS(30);  
#toggleFullscreen();


# load all raylib-dependent resources within the block
# this means all images, sounds, etc.
# otherwise we get segfault at close window call at the end...
block:

  engine.load_all_extern_media()

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
        battle.handle_mouse_click_and_drag(dt=delta_time)
      of EM_Camp: discard
      of EM_Menu: discard

    # --------------------------------------------------------------------------
    # START of game drawing logic
    # --------------------------------------------------------------------------

    beginDrawing()
    clearBackground(BLACK)

    case engine.mode:
      of EM_Battle: battle.draw()
      of EM_Camp: discard
      of EM_Menu: discard

    endDrawing()
    # --------------------------------------------------------------------------
    # end of the game loop
    # --------------------------------------------------------------------------

closeWindow()


engine.close()