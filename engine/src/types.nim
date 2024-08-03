import std/tables
import std/options

import raylib


type

  ZoomLevel* = enum 

    ## Zoomlevel of the map. If it changes, we might change the way to display stuff 
    ## to keep an acceptable fps-rate.
    
    Mini
    VerySmall
    Small
    Default
    Big

  Game* = ref object       ## Global game state.
    camera*: Camera2D
    logfile*: File
    zoom_factor*: float
    wasd_move_speed*: float
    mouse_middle_drag_speed*:float
    zoom_level*: ZoomLevel
    battle*: Battle
    mouseDragStart*: Option[Vector2]
    ## This is state; needed to keep track of the mouse if 
    ## the mouse is dragged over the screen to create a selection rect
    #TODO: Maybe move into battle ...

    unit_types*: Table[string, UnitType]


  Battle* = ref object     ## Container for the battle data. Battle is the rts mode
    game*: Game           ## simple back.ref to game, since game is needed everywhere
    chunks*: seq[Chunk]     ## List of the chunks todo: could be a static array 
    chunks_on_xy*: Table[int, Table[int, Chunk]]    ## table of chunks, so we can access them fast
    units*: seq[Unit]                       ## List of ALL units
    control_groups*: seq[ControlGroup]  ## List of all control-groups
    currently_selected_units*: seq[Unit]   ## @deprecated -> since we replace single unit control with control groups
    currently_selected_control_groups*: seq[ControlGroup]  ## List of currently selected control groups 
    factions*: Table[string, Faction] 

  Chunk* = ref object
    units*: seq[Unit]
    x*: int
    y*: int
    unit_idle_positions*: seq[Vector2]
    current_groups_that_have_this_as_target*: seq[ControlGroup]
    ## List of positions default units will align with in case
    ## of idle situations.

  UnitType* = ref object
    texture*: Texture2D
    width*: float
    height*: float
    attack_range*: float
    aggro_range*: float
    speed*:float
    max_hp*:float

  UnitBehaviourMode* = enum
    Idle
    MovingToChunk
    Fighting
    MovingToEnemyUnit

  Unit* = ref object             ## Represents a simple unit.
    dead*: bool                  ## this marks the unit a dead; Dead units can be re-used
    type_data*: UnitType         ## Reference to the type
    shape*: Rectangle            ## the position AND size of the unit
    rotation*: float             ## no use yet ...
    collision_velocity*: Vector2 ## used to carry over collision into movement
    attack_target*: Option[Unit] 
    move_target*: Option[Vector2]
    chunk_i_am_on*: Chunk        ## this need to be set all the time; the chunk this unit is on
    behavior_mode*: UnitBehaviourMode
    my_control_group*: ControlGroup
    last_push*: float
    next_collsion_check*: float
    next_think*: float
    last_attack*: float  ## seconds since last attack 
    hp*: float
    

  Faction* = ref object
    name*: string
    player*: bool
    color*: Color

  ControlGroupMode* = enum
    Idle
    Concentrate
    Moving
    Fighting

  ControlGroup* = ref object
    faction*: Faction
    units*: seq[Unit]
    target_chunk*: Option[Chunk]
    center*: Vector2
    
    current_mode*: ControlGroupMode
    last_group_mode*:ControlGroupMode
    until_next_idle_check*: float
    

  Projectile* = ref object
    shape*: Rectangle
    velocity*: Vector2

  BadGameState* = object of Defect

