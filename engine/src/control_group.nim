import std/options
import std/math
import std/tables
import std/random

import raylib
import raymath

import types
import core
import battle
import unit
import chunk


import config



proc check_i_group_can_reset_mode_to_idle_and_if_so_do_it*(self: Battle, dt: float) =
  for cg in self.control_groups:
    cg.until_next_idle_check = cg.until_next_idle_check - dt
    if cg.until_next_idle_check > 0: continue
    cg.until_next_idle_check = rand(0..500)/1000
    case cg.current_mode:
      of ControlGroupMode.Fighting:
        var has_attack_target = false
        for u in cg.units:
          if u.attack_target.isSome: (has_attack_target = true; break)
        if not has_attack_target: 
          cg.current_mode = cg.last_group_mode
          if cg.current_mode == ControlGroupMode.Fighting:
            cg.current_mode = ControlGroupMode.Idle
          cg.last_group_mode = ControlGroupMode.Idle 
          # set all units taht are still in fightng  mode to idle
          # important so we dont have "frozen" units
          # since units freeze if they are in fight mode but group is not
          for u in cg.units: u.behavior_mode = UnitBehaviourMode.Idle
      of ControlGroupMode.Moving:
        var has_move_target = false
        for u in cg.units:
          if u.move_target.isSome: (has_move_target = true; break)
        if not has_move_target: 
          cg.current_mode = cg.last_group_mode
          if cg.current_mode == ControlGroupMode.Moving:
            cg.current_mode = ControlGroupMode.Idle
          cg.last_group_mode = ControlGroupMode.Idle
      else: discard    



func update_control_group_center*(self: var ControlGroup) {.inline.} = 

  ## The control group needs to maintain a center-point in the center of all 
  ## its units.
  
  var center_x = 0; var center_y = 0
  if self.units.len == 0: return 
  for u in self.units: 
    center_x = center_x + u.shape.x.int
    center_y = center_y + u.shape.y.int
  self.center = Vector2(
    x:center_x / self.units.len, 
    y:center_y / self.units.len) 



func update_control_all_group_centers*(self: var Battle) {.inline.} =
  for _, cg in mpairs(self.control_groups): cg.update_control_group_center()

  

func look_for_enemies(self: var Battle, cg: ControlGroup) =
  ## Look for enemies in the near vicinity
  discard


func set_unit_movement_to_conzentrate(self: var Battle, cg: ControlGroup) = 
  discard



proc handle_control_group_logic*(self: var Battle) =
  ## remove if no units left
  ## move the control group
  ## fight enemy
  ## return to default goal if fighting has stopped
  for cg in self.control_groups:
    case cg.current_mode:
      of Idle:
        look_for_enemies(self, cg)
      of Concentrate:
        set_unit_movement_to_conzentrate(self, cg)
      of Moving:
        look_for_enemies(self, cg)
      of Fighting:
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
        hp: unity_type.max_hp,
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



proc manage_control_group_deaths*(self: Battle) = 
    
  ## if a control group has no units left, remove this 
  ## control group from the game itself

  var remove_ids = newSeq[int]()
  for index, cg in self.control_groups:
    if cg.units.len == 0: remove_ids.insert(index)
  for index in remove_ids:
    self.control_groups.del(index)  




proc display_selected_group_info*(self: Battle) = 
  
  ## Display informatiomn about the currently selected contorl group
  
  if self.currently_selected_control_groups.len != 0:
    let screen_w = getScreenWidth().float
    let screen_h = getScreenHeight()
    let start_y = (screen_h - 400).float
    drawRectangle(Rectangle(x:0, y: start_y, width: screen_w, height: 400), color= BLACK)
    drawRectangleLines(Rectangle(x:0, y: start_y, width: screen_w, height: 400), lineThick=3.0, color= WHITE)
    if self.currently_selected_control_groups.len == 1:
      let cg = self.currently_selected_control_groups[0]
      drawText(text=("FACTION: " & cg.faction.name).cstring, 
        posX=20, posY=start_y.int32 + 20, fontSize= 20,
        color=cg.faction.color )
      drawText(text=("Mode: " & $cg.current_mode).cstring, 
        posX=20, posY=start_y.int32 + 50, fontSize= 20,
        color=config.WORLD_COLOR )
      drawText(text=("LastMode: " & $cg.last_group_mode).cstring, 
        posX=20, posY=start_y.int32 + 80, fontSize= 20,
        color=config.WORLD_COLOR )    

      # if we have exactly one group selected
      # list all units on the right
      let x_pos = screen_w - 400
      drawRectangle(Rectangle(x:x_pos, y: 0, width: 400, height: screen_h.float), color= BLACK)
      drawRectangleLines(Rectangle(x:x_pos, y: 0, width: 400, height: screen_h.float), lineThick=3.0, color= WHITE)

      for index, u in cg.units:
        drawText(text=($u.my_control_group.units.find(u) & ":"& $u).cstring, 
          posX=(x_pos+10).int32, posY=(index * 30).int32, fontSize= 20,
          color=config.WORLD_COLOR)  



proc select_control_groups_with_mouse_selection_drag*(
  self: Battle,
  selection_rect_or_empty:Option[
    tuple[screen_relative: Rectangle, world_relative: Rectangle]] ) =

  ## Select all control groups in the selection rect.

  if selection_rect_or_empty.isSome:
    self.currently_selected_units = @[]
    self.currently_selected_control_groups = @[]
    for u in self.units:
      if get_overlap(u.shape, selection_rect_or_empty.get.world_relative).isSome:
        if self.currently_selected_control_groups.find(u.my_control_group) == -1:
          self.currently_selected_control_groups.add(u.my_control_group)        



proc set_move_target_for_control_groups*(
  self: Battle, 
  dt: float,
  right_click_on_the_screen: Option[
    tuple[screen_relative: Vector2, world_relative: Vector2]]) = 

  var cooldown {.global.} = 1.0  
  cooldown = cooldown - dt


  ## If control groups are selected, give them a target, based on the mouse click
  
  if self.currently_selected_control_groups.len != 0 and cooldown < 0:
    if right_click_on_the_screen.isSome:
      let target_chunk = self.get_chunk_by_xy_optional(
        x= right_click_on_the_screen.get.world_relative.x.int,
        y= right_click_on_the_screen.get.world_relative.y.int)
      if target_chunk.isSome:
        for _, selected_control_group in self.currently_selected_control_groups:
          # todo: if more control groups selected occupy neighbour 
          # todo: chunks,except an enemy is on this one
          selected_control_group.last_group_mode = selected_control_group.current_mode
          selected_control_group.current_mode = ControlGroupMode.Moving
          self.game.log("add new place")
          for count, u in selected_control_group.units: 
            let target = target_chunk.get.unit_idle_positions[count]
            u.move_target = some(Vector2(x:ceil(target.x-16), y:ceil(target.y-16)))
      cooldown = 1.0