import std/tables
import std/options

import raylib

import ../Core
import Unit
import BattleFaction
import UnitType

type Battle* = ref object
  camera: Camera2D
  unit_types: Table[string, UnitType]
  units: seq[Unit]
  factions: Table[string, BattleFaction] 
  mouseDragStart: Option[Vector2]
  zoom_level: ZoomLevel
  zoom_factor*: float
  wasd_move_speed*: float
  mouse_middle_drag_speed*:float


  
proc camera*(self: Battle): Camera2D = self.camera


template for_all_units_in*(self: Battle, code: untyped) =
  for index, unit in battle.units: `code`


template for_all_unit_types_in*(self: Battle, code: untyped) =
  for index, unit_type in battle.unit_types: `code`


proc get_unit_type*(self: Battle, name: string): Option[UnitType] = 
  if self.unit_types.hasKey(name): some(self.unit_types[name]) else: none(UnitType)


proc add_unit_type*(self: Battle, unit_type: UnitType) = 
  self.unit_types[unit_type.name] = unit_type


proc new_Battle*(): Battle = 
  return Battle( camera: Camera2D() )  

 