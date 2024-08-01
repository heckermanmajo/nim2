import std/options
import std/math
import std/tables

import raylib
import raymath

import types
import core
import battle
import unit
import chunk


import config



func update_control_group_center*(self: var ControlGroup) {.inline.} = 

  ## The control group needs to maintain a center-point in the center of all 
  ## its units.

  var center_x = 0; var center_y = 0
  for u in self.units: 
    center_x = center_x + u.shape.x.int
    center_y = center_y + u.shape.y.int
  self.center = Vector2(
    x:center_x / self.units.len, 
    y:center_y / self.units.len) 



func update_control_all_group_centers*(self: var Battle) {.inline.} =
  for _, cg in mpairs(self.control_groups): cg.update_control_group_center()

  

proc handle_control_group_logic*() =
  ## remove if no units left
  ## move the control group
  ## fight enemy
  ## return to default goal if fighting has stopped
  discard



proc draw_control_group_centers*(self: Battle, dt: float) =
  for cg in self.control_groups:
    discard # todo: draw text of the mode and center point
    #Idle
    #Concentrate
    #Moving
    #Fighting



proc create_control_group*(
  self:         Battle, 
  unity_type:   UnitType, 
  size:         int, 
  start_pos:    Vector2, 
  faction:      Faction
  ): ControlGroup =

  ## Creates a new conrtol-group

  var units = newSeq[Unit]()
  var real_start_pos = Vector2(
    x:self.game.world_sanatize_x(start_pos.x),
    y:self.game.world_sanatize_y(start_pos.y))
  var chunk_all_units_are_on = self.get_chunk_by_xy(real_start_pos)

  for i in 0..size:
    units.add(
      Unit(
        dead: false,
        type_data: unity_type,
        shape: Rectangle(
          x:real_start_pos.x, 
          y: real_start_pos.y, 
          width: unity_type.width, 
          height: unity_type.height),
        attack_target: none(Unit),
        move_target: none(Vector2),
        chunk_i_am_on: chunk_all_units_are_on,
        behavior_mode: UnitBehaviourMode.Idle))

  var cg = ControlGroup(
    units: units,
    target_chunk: none(Chunk),
    current_mode: ControlGroupMode.Idle,
    last_group_mode: ControlGroupMode.Idle,
    faction: faction
  )

  for u in units: 
    chunk_all_units_are_on.units.add(u)
    self.units.add(u) # add the units to the global battle list
    u.my_control_group = cg
  
  cg.update_control_group_center()
  self.control_groups.add(cg)
  
  return cg



proc manage_control_group_deaths*() = 
    
    ## if a control group has no units left, remove this 
    ## control group from the game itself

    discard