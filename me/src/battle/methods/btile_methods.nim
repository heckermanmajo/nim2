## Methods for 
##
##
import std/options
import raylib
import CONFIG
import battle/battle_types

proc absolute_postion*(me: BTile): Vector2 = 
  return Vector2(
    x: (me.num_pos.x * CONFIG.TILE_SIZE).float, 
    y: (me.num_pos.y * CONFIG.TILE_SIZE).float)

proc get_movment_cost*(me: BTile): float = 
  return 0.0

proc get_point*(me: BTile): GridPoint = me.num_pos

proc is_passable*(me: BTile): bool = 
  me.nmob.isNone() 

proc init*(me: BTile,x: float,y: float) = 
  me.real_pos =  Vector2(x:x, y:y)
  me.absolute_postion_as_rect = Rectangle(
    x: x, 
    y: y, 
    width: CONFIG.TILE_SIZE, 
    height: CONFIG.TILE_SIZE)

proc `$`*(me: BTile): string = 
  "BTILE: numpos: " & $me.num_pos & "real_pos: " & $me.real_pos