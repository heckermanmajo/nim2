import std/tables
import std/options

import raylib

const chunks_per_side* = 10
const CHUNK_SIZE_IN_PIXEL* = 128

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
    chunks*: seq[Chunk]
    chunks_on_xy*: Table[int, Table[int, Chunk]]
    units*: seq[Unit]

  Chunk* = ref object
    units*: seq[Unit]
    x*: int
    y*: int

  Unit* = ref object

