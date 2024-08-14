##[[

This module contains all types needed for the rts-battle mode of the engine.

It also contains methods - which means procs/templates that allow access to the 
fields of the types. We dont want anybody outside this fike to change the fields 
of the types. -> Only methods can change object state.

This file also contains the battle-proc, which allows to access the gloabal
battle variable, which contains the only battle instance of the whole engine.

]]##


# for the big comments
# https://fsymbols.com/generators/carty/



import std/tables
import std/options

import raylib

import CONFIG


type 

  #[[███████████████████████████████████████████████████████████████████████████
  ██╗░░░██╗██╗░██████╗██╗░░░██╗░█████╗░██╗░░░░░
  ██║░░░██║██║██╔════╝██║░░░██║██╔══██╗██║░░░░░
  ╚██╗░██╔╝██║╚█████╗░██║░░░██║███████║██║░░░░░
  ░╚████╔╝░██║░╚═══██╗██║░░░██║██╔══██║██║░░░░░
  ░░╚██╔╝░░██║██████╔╝╚██████╔╝██║░░██║███████╗
  ░░░╚═╝░░░╚═╝╚═════╝░░╚═════╝░╚═╝░░╚═╝╚══════╝
  ░█████╗░██████╗░░░░░░██╗███████╗░█████╗░████████╗
  ██╔══██╗██╔══██╗░░░░░██║██╔════╝██╔══██╗╚══██╔══╝
  ██║░░██║██████╦╝░░░░░██║█████╗░░██║░░╚═╝░░░██║░░░
  ██║░░██║██╔══██╗██╗░░██║██╔══╝░░██║░░██╗░░░██║░░░
  ╚█████╔╝██████╦╝╚█████╔╝███████╗╚█████╔╝░░░██║░░░
  ░╚════╝░╚═════╝░░╚════╝░╚══════╝░╚════╝░░░░╚═╝░░░
  ███████████████████████████████████████████████████████████████████████████]]#
  VisualObject* = ref object



  #[[███████████████████████████████████████████████████████████████████████████
  ██╗░░░██╗███╗░░██╗██╗████████╗
  ██║░░░██║████╗░██║██║╚══██╔══╝
  ██║░░░██║██╔██╗██║██║░░░██║░░░
  ██║░░░██║██║╚████║██║░░░██║░░░
  ╚██████╔╝██║░╚███║██║░░░██║░░░
  ░╚═════╝░╚═╝░░╚══╝╚═╝░░░╚═╝░░░
  ███████████████████████████████████████████████████████████████████████████]]#
  UnitType* = ref object
    ## The type of a unit; a unit type can be used by multiple instances. 

  UnitTargetType = enum 
    ## This enum describes the type of a target that a unit has
    BTile_target_type, Building_target_type, Unit_as_target_type,
    Resource_target_type

  UnitTargetAction = enum 
    ## This enum describes what action a unit should perform on a given target
    Follow, Fight, Act

  UnitTarget = object
    ## This type contains a target for a unit. Based on what the target is 
    ## and what action should be performed
    case kind*: UnitTargetType
      of BTile_target_type: target_tile: BTile
      of Building_target_type: target_building: Building
      of Unit_as_target_type: target_unit: Unit 
      of Resource_target_type: target_reosurce: Resource
    target_action: UnitTargetAction


  UnitMode = enum 
    ## This enum descibes the current unit state: means what a unit currently 
    ## does; this value influences what logic is called on the unit, like 
    ## moving, thinking fighting, gathering, etc.
    Idle, Gathering, Fighting  
  

  Unit* = ref object ##\
    ## Single moving object, that can fight, build and gather resources.
    ## The abilities, behaviour-pattern and looks are defined in the 
    ## unit type. 
    
    tile_i_am_on: BTile ##\
    ## The tile this unit stands on. Each unit occupies one tile. There can 
    ## never be two units on one tile. 
    
    unit_type: UnitType ##\
    ## The type of this unit.
   
    current_mode: UnitMode  ##\
    ## the current state of this unit, that decides what logic to call 
    ## in the systems
   
    targets: seq[UnitTarget] ##\
    ## list of targets the unit has; does one after another
   
    path_to_target: Option[seq[BTile]] ##\
    ## The path is set by the pathfinder system.
    ## The pathfinder system reads each frame units and 
    ## pathfinds the ones which need a path


  #[[███████████████████████████████████████████████████████████████████████████
  ██████╗░███████╗░██████╗░█████╗░██╗░░░██╗██████╗░░█████╗░███████╗
  ██╔══██╗██╔════╝██╔════╝██╔══██╗██║░░░██║██╔══██╗██╔══██╗██╔════╝
  ██████╔╝█████╗░░╚█████╗░██║░░██║██║░░░██║██████╔╝██║░░╚═╝█████╗░░
  ██╔══██╗██╔══╝░░░╚═══██╗██║░░██║██║░░░██║██╔══██╗██║░░██╗██╔══╝░░
  ██║░░██║███████╗██████╔╝╚█████╔╝╚██████╔╝██║░░██║╚█████╔╝███████╗
  ╚═╝░░╚═╝╚══════╝╚═════╝░░╚════╝░░╚═════╝░╚═╝░░╚═╝░╚════╝░╚══════╝
  ███████████████████████████████████████████████████████████████████████████]]#
  Resource* = ref object




  #[[███████████████████████████████████████████████████████████████████████████
  ██████╗░██╗░░░██╗██╗██╗░░░░░██████╗░██╗███╗░░██╗░██████╗░
  ██╔══██╗██║░░░██║██║██║░░░░░██╔══██╗██║████╗░██║██╔════╝░
  ██████╦╝██║░░░██║██║██║░░░░░██║░░██║██║██╔██╗██║██║░░██╗░
  ██╔══██╗██║░░░██║██║██║░░░░░██║░░██║██║██║╚████║██║░░╚██╗
  ██████╦╝╚██████╔╝██║███████╗██████╔╝██║██║░╚███║╚██████╔╝
  ╚═════╝░░╚═════╝░╚═╝╚══════╝╚═════╝░╚═╝╚═╝░░╚══╝░╚═════╝░
  ███████████████████████████████████████████████████████████████████████████]]#
  Building* = ref object





  #[[███████████████████████████████████████████████████████████████████████████
  ██████╗░░░░░░░███████╗░█████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
  ██╔══██╗░░░░░░██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
  ██████╦╝█████╗█████╗░░███████║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║
  ██╔══██╗╚════╝██╔══╝░░██╔══██║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║
  ██████╦╝░░░░░░██║░░░░░██║░░██║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
  ╚═════╝░░░░░░░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝
  ███████████████████████████████████████████████████████████████████████████]]#
  BFaction* = ref object 


  
  
  
  
  
  
  #[[███████████████████████████████████████████████████████████████████████████
  ██████╗░░░░░░░████████╗██╗██╗░░░░░███████╗
  ██╔══██╗░░░░░░╚══██╔══╝██║██║░░░░░██╔════╝
  ██████╦╝█████╗░░░██║░░░██║██║░░░░░█████╗░░
  ██╔══██╗╚════╝░░░██║░░░██║██║░░░░░██╔══╝░░
  ██████╦╝░░░░░░░░░██║░░░██║███████╗███████╗
  ╚═════╝░░░░░░░░░░╚═╝░░░╚═╝╚══════╝╚══════╝
  ███████████████████████████████████████████████████████████████████████████]]#
  BTile* = ref object
    num_pos: tuple[x:int, y: int] 
  
  
  
  
  
  #[[███████████████████████████████████████████████████████████████████████████
  ██████╗░░░░░░░░██████╗░█████╗░██╗░░░██╗███████╗███████╗██╗██╗░░░░░███████╗
  ██╔══██╗░░░░░░██╔════╝██╔══██╗██║░░░██║██╔════╝██╔════╝██║██║░░░░░██╔════╝
  ██████╦╝█████╗╚█████╗░███████║╚██╗░██╔╝█████╗░░█████╗░░██║██║░░░░░█████╗░░
  ██╔══██╗╚════╝░╚═══██╗██╔══██║░╚████╔╝░██╔══╝░░██╔══╝░░██║██║░░░░░██╔══╝░░
  ██████╦╝░░░░░░██████╔╝██║░░██║░░╚██╔╝░░███████╗██║░░░░░██║███████╗███████╗
  ╚═════╝░░░░░░░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝╚══════╝╚══════╝
  ███████████████████████████████████████████████████████████████████████████]]#
  BSaveFile* = ref object






  #[[███████████████████████████████████████████████████████████████████████████
  ██████╗░░█████╗░████████╗████████╗██╗░░░░░███████╗
  ██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║░░░░░██╔════╝
  ██████╦╝███████║░░░██║░░░░░░██║░░░██║░░░░░█████╗░░
  ██╔══██╗██╔══██║░░░██║░░░░░░██║░░░██║░░░░░██╔══╝░░
  ██████╦╝██║░░██║░░░██║░░░░░░██║░░░███████╗███████╗
  ╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░╚══════╝╚══════╝
  ███████████████████████████████████████████████████████████████████████████]]#

  ZoomLevel* = enum 

    ## Zoomlevel of the map. If it changes, we might change the way to display stuff 
    ## to keep an acceptable fps-rate.
    
    Mini
    VerySmall
    Small
    Default
    Big

  Battle* = ref object
    # battle has also battle-ui-state
    units: seq[Unit]
    visual_objects: seq[VisualObject]
    tiles*: seq[BTile]
    tile_as_grid: seq[seq[BTile]]
    camera*: Camera2D
    world_size_in_tiles*: int
    zoom_level*: ZoomLevel
    zoom_factor*: float
    wasd_move_speed*: float
    mouse_middle_drag_speed*:float
    mouseDragStart*: Option[Vector2]


#[[██████████████████████████████████████████████████████████████████████████]]#
#[[██████████████████████████████████████████████████████████████████████████]]#
#[[█████████████████████████████████████████████████████████████████████████████

░██████╗░██╗░░░░░░█████╗░██████╗░░█████╗░██╗░░░░░
██╔════╝░██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██║░░██╗░██║░░░░░██║░░██║██████╦╝███████║██║░░░░░
██║░░╚██╗██║░░░░░██║░░██║██╔══██╗██╔══██║██║░░░░░
╚██████╔╝███████╗╚█████╔╝██████╦╝██║░░██║███████╗
░╚═════╝░╚══════╝░╚════╝░╚═════╝░╚═╝░░╚═╝╚══════╝

██████╗░░█████╗░████████╗████████╗██╗░░░░░███████╗
██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║░░░░░██╔════╝
██████╦╝███████║░░░██║░░░░░░██║░░░██║░░░░░█████╗░░
██╔══██╗██╔══██║░░░██║░░░░░░██║░░░██║░░░░░██╔══╝░░
██████╦╝██║░░██║░░░██║░░░░░░██║░░░███████╗███████╗
╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░╚══════╝╚══════╝

██╗███╗░░██╗░██████╗████████╗░█████╗░███╗░░██╗░█████╗░███████╗
██║████╗░██║██╔════╝╚══██╔══╝██╔══██╗████╗░██║██╔══██╗██╔════╝
██║██╔██╗██║╚█████╗░░░░██║░░░███████║██╔██╗██║██║░░╚═╝█████╗░░
██║██║╚████║░╚═══██╗░░░██║░░░██╔══██║██║╚████║██║░░██╗██╔══╝░░
██║██║░╚███║██████╔╝░░░██║░░░██║░░██║██║░╚███║╚█████╔╝███████╗
╚═╝╚═╝░░╚══╝╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
█████████████████████████████████████████████████████████████████████████████]]#
#[[██████████████████████████████████████████████████████████████████████████]]#
#[[██████████████████████████████████████████████████████████████████████████]]#

var p_battle = Battle(
  units: new_seq[Unit](),
  visual_objects: new_seq[VisualObject](),
  tiles: new_seq[BTile](),
  tile_as_grid: newSeq[seq[BTile]](),
  zoom_level: ZoomLevel.Default,
  zoom_factor: 1.0,
  wasd_move_speed: 700,
  mouse_middle_drag_speed: -10,
  camera: Camera2D(
    target: Vector2(x: 0, y: 0),
    offset: Vector2(x: 0, y: 0),
    rotation: 0,
    zoom: 1))

    
proc battle*(): var Battle {.inline.} = p_battle





#[[██████████████████████████████████████████████████████████████████████████]]#
#[[██████████████████████████████████████████████████████████████████████████]]#
#[[█████████████████████████████████████████████████████████████████████████████

███╗░░░███╗███████╗████████╗██╗░░██╗░█████╗░██████╗░░██████╗
████╗░████║██╔════╝╚══██╔══╝██║░░██║██╔══██╗██╔══██╗██╔════╝
██╔████╔██║█████╗░░░░░██║░░░███████║██║░░██║██║░░██║╚█████╗░
██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██║░░██║██║░░██║░╚═══██╗
██║░╚═╝░██║███████╗░░░██║░░░██║░░██║╚█████╔╝██████╔╝██████╔╝
╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═════╝░╚═════╝░

█████████████████████████████████████████████████████████████████████████████]]#
#[[██████████████████████████████████████████████████████████████████████████]]#
#[[██████████████████████████████████████████████████████████████████████████]]#








#[[█████████████████████████████████████████████████████████████████████████████
██╗░░░██╗███╗░░██╗██╗████████╗
██║░░░██║████╗░██║██║╚══██╔══╝
██║░░░██║██╔██╗██║██║░░░██║░░░
██║░░░██║██║╚████║██║░░░██║░░░
╚██████╔╝██║░╚███║██║░░░██║░░░
░╚═════╝░╚═╝░░╚══╝╚═╝░░░╚═╝░░░

METHODS 

█████████████████████████████████████████████████████████████████████████████]]#


proc delete(me: Unit) = 
  ## Deletes the unit
  discard







#[[█████████████████████████████████████████████████████████████████████████████
██████╗░░█████╗░████████╗████████╗██╗░░░░░███████╗
██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║░░░░░██╔════╝
██████╦╝███████║░░░██║░░░░░░██║░░░██║░░░░░█████╗░░
██╔══██╗██╔══██║░░░██║░░░░░░██║░░░██║░░░░░██╔══╝░░
██████╦╝██║░░██║░░░██║░░░░░░██║░░░███████╗███████╗
╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░╚══════╝╚══════╝

METHODS 

█████████████████████████████████████████████████████████████████████████████]]#

proc world_size_in_pixel*(me: Battle): int = me.world_size_in_tiles * CONFIG.TILE_SIZE
proc world_size_in_pixel_f*(me: Battle): float = (me.world_size_in_tiles * CONFIG.TILE_SIZE).float

proc delete(me: Battle) = 
  ## Deletes all battle memory.
  discard 


proc init*(me: Battle, tiles_per_side = 300) = 
  ## Initialize the battle based on the given parameters.
  ## Will also clean up all previous initialized battle memory.
  
  me.delete()

  me.world_size_in_tiles = tiles_per_side

  block initialize_Tiles_of_battle_map:
    for x in 0..me.world_size_in_tiles:
      for y in 0..me.world_size_in_tiles:
        var t = BTile(
          num_pos: (x:x,y:y)
        )
        if me.tile_as_grid.len < x: me.tile_as_grid[x] = @[t]
        else: me.tile_as_grid[x].add(t)
        me.tiles.add(t)


proc given_pos_in_view*(me: Battle; x, y, width, height: float): bool {.inline.} =
  
  ## Check if a given rect is in view of the camera

  let viewTopLeftX = me.camera.target.x
  let viewTopLeftY = me.camera.target.y
  let viewBottomRightX = (
    me.camera.target.x + (getScreenWidth().float) / me.camera.zoom)
  let viewBottomRightY = (
    me.camera.target.y + (getScreenHeight().float ) / me.camera.zoom)
  return not (x > viewBottomRightX or
              x + width < viewTopLeftX or
              y > viewBottomRightY or
              y + height < viewTopLeftY)


proc given_pos_in_view*(me: Battle; rect: Rectangle): bool {.inline.} =
  return me.given_pos_in_view( rect.x, rect.y, rect.width, rect.height)

proc world_sanatize_value*(me: Battle, x_or_y: int): int  
  = (if x_or_y < 0: return 0; if x_or_y > me.world_size_in_pixel(): return me.world_size_in_pixel(); return x_or_y)

proc world_sanatize_value*(me: Battle, x_or_y: float): float 
  = (if x_or_y < 0: return 0; if x_or_y > me.world_size_in_pixel_f(): return me.world_size_in_pixel_f(); return x_or_y)

proc given_pos_in_world(me: Battle, pos: Vector2): bool = 
  if pos.x < 0: return false
  if pos.y < 0: return false
  if pos.x > me.world_size_in_pixel().float: return false
  if pos.y > me.world_size_in_pixel().float: return false
  return true

proc get_tile_from_pos(me: Battle, pos: Vector2): Option[BTile] = 
  if not me.given_pos_in_world(pos): return none(BTile)
  let x = (pos.x / CONFIG.TILE_SIZE).int
  let y = (pos.y / CONFIG.TILE_SIZE).int
  return some(me.tile_as_grid[x][y])


#[[███████████████████████████████████████████████████████████████████████████
██████╗░░░░░░░████████╗██╗██╗░░░░░███████╗
██╔══██╗░░░░░░╚══██╔══╝██║██║░░░░░██╔════╝
██████╦╝█████╗░░░██║░░░██║██║░░░░░█████╗░░
██╔══██╗╚════╝░░░██║░░░██║██║░░░░░██╔══╝░░
██████╦╝░░░░░░░░░██║░░░██║███████╗███████╗
╚═════╝░░░░░░░░░░╚═╝░░░╚═╝╚══════╝╚══════╝

METHODS

███████████████████████████████████████████████████████████████████████████]]#

proc absolute_postion*(me: BTile): Vector2 = 
  return Vector2(
    x: (me.num_pos.x * CONFIG.TILE_SIZE).float, 
    y: (me.num_pos.y * CONFIG.TILE_SIZE).float)

proc absolute_postion_as_rect*(me: BTile): Rectangle = 
  let v = absolute_postion(me)
  return Rectangle(
    x: v.x, 
    y: v.y, 
    width: CONFIG.TILE_SIZE, 
    height: CONFIG.TILE_SIZE)
