import raylib

import ControlGroup
import Unit


type
  Chunk* = ref object
    units: seq[Unit]
    control_groups: seq[ControlGroup]
    x: int
    y: int
    unit_idle_positions: seq[Vector2]
    current_groups_that_have_this_as_target: seq[ControlGroup]
    ## List of positions default units will align with in case