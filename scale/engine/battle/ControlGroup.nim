import std/options

import raylib

import Chunk
import BattleFaction
import Unit

type 

  ControlGroupMode* = enum
    Idle
    Concentrate
    Moving
    Fighting
    
  ControlGroup* = ref object
    faction: BattleFaction
    units: seq[Unit]
    target_chunk: Option[Chunk]
    center: Vector2
    
    current_mode: ControlGroupMode
    last_group_mode: ControlGroupMode
    
    until_next_idle_check: float
    chunk_i_am_on: Chunk