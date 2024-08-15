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
import std/hashes

import raylib
import ../lib/astar

import ../CONFIG

type GridPoint* = tuple[x, y: int]

type 

  VisualObject* = ref object

  UnitType* = ref object
    ## The type of a unit; a unit type can be used by multiple instances. 

  UnitTargetType = enum 
    ## This enum describes the type of a target that a unit has
    BTile_target_type, Unit_as_target_type,
    Object_target_type

  UnitTargetAction = enum 
    ## This enum describes what action a unit should perform on a given target
    Follow, Fight, Act

  UnitTarget = object
    ## This type contains a target for a unit. Based on what the target is 
    ## and what action should be performed
    case kind*: UnitTargetType
      of BTile_target_type: target_tile: BTile
      of Object_target_type: target_object: NonMovingObject
      of Unit_as_target_type: target_unit: Unit 
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

  NonMovingObject* = ref object

  BFaction* = ref object 

  Chunk* = ref object
    ## we use chunk to improve performance 
    tiles*: seq[BTile] 
    render_texture*: Option[RenderTexture]
    ## we render the background tiles at the start of a battle into this 
    ## render_texture, so we dont need to loop over all tiles.
    shape*: Rectangle
  
  BTile* = ref object
    num_pos*: tuple[x:int, y: int]
    real_pos*: Vector2
    absolute_postion_as_rect*: Rectangle
    nmob*: Option[NonMovingObject]
  

  BSaveFile* = ref object

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
    units*: seq[Unit]
    chunks*: seq[Chunk]
    visual_objects*: seq[VisualObject]
    tiles*: seq[BTile]
    tile_as_grid*: seq[seq[BTile]]
    camera*: Camera2D
    world_size_in_tiles*: int
    zoom_level*: ZoomLevel
    zoom_factor*: float
    wasd_move_speed*: float
    mouse_middle_drag_speed*:float
    mouseDragStart*: Option[Vector2]
    SCREEN_W_AS_FLOAT*: float
    SCREEN_H_AS_FLOAT*: float
    render_texture_of_tile_grid*: RenderTexture
    world_size_in_chunk*: int

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







