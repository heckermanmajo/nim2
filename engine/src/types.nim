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

  Game* = ref object
    ## Global game state.
    camera*: Camera2D
    logfile*: File
    zoom_factor*: float
    wasd_move_speed*: float
    mouse_middle_drag_speed*:float
    zoom_level*: ZoomLevel
    battle*: Battle
    mouseDragStart*: Option[Vector2]
    unit_types*: Table[string, UnitType]

  Battle* = ref object
    game*: Game
    chunks*: seq[Chunk]
    chunks_on_xy*: Table[int, Table[int, Chunk]]
    units*: seq[Unit]
    currently_selected_units*: seq[Unit]
    control_groups*: seq[ControlGroup]
    currently_selected_control_groups*: seq[ControlGroup]

  Chunk* = ref object
    units*: seq[Unit]
    x*: int
    y*: int

  UnitType* = ref object
    #texture*: Texture2D
    width*: float
    height*: float

  UnitBahaviourMode* = enum
    Idle
    MovingToChunk
    Fighting
    MovingToEnemyUnit

  Faction* = ref object
    name*: string
    player*: bool

  ControlGroupMode* = enum
    Idle
    Concentrate
    Moving
    Fighting

  ControlGroup* = ref object
    units*: seq[Unit]
    target_chunk*: Option[Chunk]
    center*: Vector2
    current_mode*: ControlGroupMode
    last_group_mode*:ControlGroupMode


  Unit* = ref object
    dead*: bool
    type_data*: UnitType
    shape*: Rectangle
    rotation*: float
    velocity*: Vector2
    collision_velocity*: Vector2
    attack_target*: Option[Unit]
    move_target*: Option[Vector2]
    chunk_i_am_on*: Chunk
    mode*: UnitBahaviourMode
    myControlGroup*: ControlGroup
    last_push*: float

  Projectile* = ref object
    shape*: Rectangle
    velocity*: Vector2

  BadGameState* = object of Defect

