import std/options

import raylib


import BattleFaction

type 

  scale.Chunk = object
  scale.Unit = object

  ControlGroupMode* = enum
    Idle
    Concentrate
    Moving
    Fighting
    
  ControlGroup* {.package.}  = ref object
    faction: BattleFaction
    units: seq[ref Unit]
    target_chunk: Option[ref Chunk]
    center: Vector2
    
    current_mode: ControlGroupMode
    last_group_mode: ControlGroupMode
    
    until_next_idle_check: float
    chunk_i_am_on: ref Chunk