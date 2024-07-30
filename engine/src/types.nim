import std/tables
import std/options

import raylib

import config
import utils


type

  ZoomLevel* = enum
    ## Zoomlevel of the campaign map; The zoom changes the way of displaying
    ## the map and the armies on the map.
    Mini
    VerySmall
    Small
    Default
    Big

  Game* = ref object
    camera*: Camera2D
    logfile*: File
    zoom_factor*: float
    wasd_move_speed*: float
    mouse_middle_drag_speed*:float
    zoom_level*: ZoomLevel
    battle*: Battle
    mouseDragStart*: Option[Vector2]

  Battle* = ref object
    game*: Game
    chunks*: seq[Chunk]
    chunks_on_xy*: Table[int, Table[int, Chunk]]
    units*: seq[Unit]
    currently_selected_units*: seq[Unit]

  Chunk* = ref object
    units*: seq[Unit]
    x*: int
    y*: int

  UnitType = ref object
    texture: Texture2D

  UnitBahaviourMode = enum
    Idle
    MovingToChunk
    Fighting

  Unit* = ref object
    type_data*: UnitType
    shape*: Rectangle
    rotation*: float
    velocity*: Vector2
    attack_target*: Option[Unit]
    move_target*: Option[Vector2]
    chunk_i_am_on*: Chunk
    mode: UnitBahaviourMode

  Projectile* = ref object
    shape*: Rectangle
    velocity*: Vector2

  BadGameState* = object of Defect

