import std/random
import std/options

import raylib
import raymath

import config
import types
import core
import chunk



proc get_position*(self: Unit): Vector2 = Vector2(x: self.shape.x, y: self.shape.y)

proc `$`*(self: Unit): string = 
  return $self.behavior_mode & " - " &
    $self.attack_target.isSome & " - " & 
    $self.move_target.isSome & "-" & 
    $self.shape


proc think_single_unit(self: Battle,u: Unit, dt: float) = 
  ## A single unit of a control group thinks in random intervals.
  ## Thinking means looking for enemy units in its vicinity.
  ## Since this can be costly, we dont do it every frame.
  ## Units think in idle and in moving mode
  ## @see think_all_units
 
  let cg = u.myControlGroup
  # each unit thinks if they are idle or moving 
  if u.behavior_mode == UnitBehaviourMode.Idle or 
     u.behavior_mode == UnitBehaviourMode.MovingToChunk:
    let chunk_i_am_on = u.chunk_i_am_on
    var nearest_enemy_unit = none(Unit)
    var nearest_unit_distance = 9999999.0
    var around_chunks = self.get_chunks_around_chunk(u,also_diagonal= true)
    around_chunks.add(chunk_i_am_on)
    # todo: maybe we need to check even further chunks on long distance units
    for chunk in around_chunks:
      for other_unit in chunk.units:
        if other_unit.my_control_group.faction == u.my_control_group.faction:
          continue # this also handles "self"
        if other_unit.dead: continue
        let distance_between_units = raymath.distance(
          v1=other_unit.get_position, v2= u.get_position)
        if distance_between_units < nearest_unit_distance:
          nearest_unit_distance = distance_between_units
          nearest_enemy_unit = some(other_unit)
      if nearest_enemy_unit.isSome:
        if nearest_unit_distance < u.type_data.aggro_range:
          u.attack_target = nearest_enemy_unit
          # after selecting a target, we set the mode to moving to the enemy
          u.behavior_mode = UnitBehaviourMode.MovingToEnemyUnit

          # if one unit fights, the whole group need to be set to fight-mode
          case cg.current_mode:
            of ControlGroupMode.Moving:
              cg.last_group_mode = ControlGroupMode.Moving
              cg.current_mode = ControlGroupMode.Fighting
            of ControlGroupMode.Idle:
              cg.last_group_mode = ControlGroupMode.Idle
              cg.current_mode = ControlGroupMode.Fighting
            else: discard
          # Fighting is done in "fight_units"



proc think_all_units*(self: Battle, dt: float) =
  ## if a unit finds an enemy or is attacked, the control-group
  ## moves into the fight
  ## Look for enemey units in near vicinity of this unit (chunk based)
  
  for cg in self.control_groups:
    if cg.current_mode == ControlGroupMode.Fighting or 
      cg.current_mode == ControlGroupMode.Idle or
      cg.current_mode == ControlGroupMode.Moving:
      
      for u in cg.units:
        u.next_think = u.next_think - dt
        if u.next_think > 0: continue
        u.next_think = rand(0..config.UNIT_THINK_INTERVAL) / 1000
        think_single_unit(self, u, dt)
        
    

proc join_fight_with_all_units*(self: Battle, dt: float) = 
  ## If a control group is in fighting mode, the control group units that 
  ## have no units in attack range, will join the units of their control 
  ## group that are fighting.
  ## If we find not fighting units of a control group at all 
  ## we will directly call think units on all units, so they look for enemies
  ## if after this there is still no fighting, we will change back to the 
  ## last control group Mode



proc fight_units*(self: Battle, dt: float) =
  ## If this unit has moved to far away from its center, it will try to go 
  ## back some distance and then continue to fight
  
  # move to the unit i need to fight ...
  # if in aggro range start fighting ...
  for cg in self.control_groups:
    if cg.current_mode != ControlGroupMode.Fighting: continue
    for u in cg.units:
      if u.attack_target.isSome:

        if u.attack_target.get.dead: 
          u.attack_target = none(Unit)
          u.behavior_mode = UnitBehaviourMode.Idle
          self.game.log("Killed unit rmeoved from attack target")
          continue
          
        # wait with the attack until cooldown var is bigger than 1
        u.last_attack = u.last_attack + dt
        if u.last_attack < u.type_data.attack_speed: continue
        u.last_attack = 0

        case u.behavior_mode
          of UnitBehaviourMode.Fighting:
            let other = u.attack_target.get
            let distance = raymath.distance(v1=u.get_position, v2=other.get_position)
            if distance < u.type_data.attack_range:
              let damage = u.type_data.attack_damage
              other.hp = other.hp - damage
              if other.hp < 0: 
                other.dead = true
              
              ## If i receive damage. my group will fight the battle 
              ## against the group of the attacker
              if other.my_control_group.current_mode != ControlGroupMode.Fighting:
                other.myControlGroup.last_group_mode = other.my_control_group.current_mode
                other.my_control_group.current_mode = ControlGroupMode.Fighting


              self.game.log("Unit received damage due to fighting")
            else:
              u.behavior_mode = UnitBehaviourMode.MovingToEnemyUnit

            if u.attack_target.isNone: u.behavior_mode = UnitBehaviourMode.Idle  
          # NOTE: The move logic of the unit changes the mode back to 
          #       fighting, if the unit is near to its enemy    
          else: discard



proc manage_unit_deaths*(self: Battle, dt: float) =

  ## check for units with that are dead and remove them
  
  # todo: dont do this all the time
  var to_delete= newSeq[int]()
  for index, u in self.units:
    if u.dead:
      # remove from battle units and from control group
      let dead_unit_index_control_group = u.my_control_group.units.find(u)
      to_delete.insert(index)
      u.my_control_group.units.del(dead_unit_index_control_group)
      u.chunk_i_am_on.units.del(u.chunk_i_am_on.units.find(u))

  for index in to_delete: self.units.del(index)



proc draw_all_units*(self: Battle, dt: float) {.inline.} =

  if self.game.zoom_level == ZoomLevel.VerySmall:

    for cg in self.control_groups:
       if cg.units.len == 0: continue
       let unit_type = cg.units[0].type_data.name
       drawCircle(cg.center.x.int32, cg.center.y.int32,100.float, color= cg.faction.color)
       if unit_type == "distance_soldier":
         drawText(("%").cstring, cg.center.x.int32 - 30,cg.center.y.int32-30, 100, WHITE)

  else:

    let cam_x = self.game.camera.target.x
    let cam_y = self.game.camera.target.y
    let screen_w = getScreenWidth().float / self.game.camera.zoom + cam_x
    let screen_h = getScreenHeight().float / self.game.camera.zoom + cam_y
    for u in self.units:
      if u.dead: continue
      let ux = u.shape.x
      let uy = u.shape.y
      let in_view = ux > cam_x and cam_x < screen_w and uy > cam_y and uy < screen_h
      if in_view:
        let center_x = (ux + u.shape.width / 2).int32
        let center_y = (uy + u.shape.height / 2).int32
        let color = u.myControlGroup.faction.color
        drawCircle(center_x, center_y, u.shape.width / 2, color)
        drawCircleLines(center_x, center_y, u.shape.width / 2, WHITE)
        if u.type_data.name == "distance_soldier":
          #        drawText(($u.my_control_group.units.find(u)).cstring, center_x - 10, center_y-10, 20, WHITE)  
          drawText(("%").cstring, center_x - 8, center_y-10, 20, WHITE)
        if u.type_data.name == "tanky_soldier":
          drawText(("#").cstring, center_x - 8, center_y-10, 20, WHITE)
    
    for u in self.units:
      if u.dead: continue
      let ux = u.shape.x
      let uy = u.shape.y
      let in_view = ux > cam_x and cam_x < screen_w and uy > cam_y and uy < screen_h
      if in_view:
        if u.behavior_mode == UnitBehaviourMode.Fighting:
          if u.last_attack < 0.5:
            if u.attack_target.isSome:
              drawLine(
                startPos=u.get_position + u.shape.width / 2, 
                endPos=u.attack_target.get.get_position + u.attack_target.get.shape.width / 2, 
                thick=4,
                color= YELLOW)



proc draw_rect_around_selected_units*(self: Battle, dt: float) =
  if self.game.zoom_level != ZoomLevel.VerySmall:
    for group in self.currently_selected_control_groups:
      for u in group.units:
        drawRectangleLines(
          Rectangle(
            x: u.shape.x - 4,
            y: u.shape.y - 4,
            width: u.shape.width + 8,
            height: u.shape.height + 8
          ),
          2,
          WHITE)



proc update_chunk_position_of_unit*(self: var Battle, unit: var Unit) =
  let id = unit.chunk_i_am_on.units.find(unit)
  unit.chunk_i_am_on.units.delete(id)
  unit.chunk_i_am_on = self.get_chunk_by_xy(unit.shape.x.int,unit.shape.y.int)
  unit.chunk_i_am_on.units.add(unit)



proc move_unit_torwards_given_target(
  self: Battle, unit: Unit, target: Vector2, dt: float): bool =

  let unit_speed = unit.type_data.speed
  let reach_target_padding = 4.0
  var upos = unit.get_position 
  let distance_x = upos.x - target.x.float
  let distance_y = upos.y - target.y.float
  if distance_x < 0 and abs(distance_x) > 3: upos.x += unit_speed * dt
  if distance_x > 0 and abs(distance_x) > 3: upos.x -= unit_speed * dt
  if distance_y < 0 and abs(distance_y) > 3: upos.y += unit_speed * dt
  if distance_y > 0 and abs(distance_y) > 3: upos.y -= unit_speed * dt

  # Update the chunk of the unit
  if self.get_chunk_by_xy(upos.x, upos.y) != unit.chunk_i_am_on:
    var old_chunk = unit.chunk_i_am_on
    var new_chunk = self.get_chunk_by_xy(upos.x, upos.y)
    old_chunk.units.delete(old_chunk.units.find(unit))
    new_chunk.units.add(unit)
    unit.chunk_i_am_on = new_chunk
  
  var has_reached_target 
    = abs(distance_x) < reach_target_padding and
      abs(distance_y) < reach_target_padding
  if has_reached_target:
    upos.x = target.x
    upos.y = target.y
  unit.shape.x = upos.x
  unit.shape.y = upos.y
  return has_reached_target



proc move_units*(self: Battle, dt: float) =

  for u in self.units:

    case u.behavior_mode:
     
      of UnitBehaviourMode.Idle:
        if u.move_target.isSome:
          let has_reached_target = move_unit_torwards_given_target(
            self, u, u.move_target.get, dt)
          if has_reached_target:
             u.move_target = none(Vector2)
             u.behavior_mode = UnitBehaviourMode.Idle

      of UnitBehaviourMode.MovingToEnemyUnit:
        if u.attack_target.isNone: 
          u.behavior_mode = UnitBehaviourMode.Idle
        else:  
          let distance = raymath.distance(
            u.get_position, u.attack_target.get.get_position)
          let attack_range = u.type_data.attack_range
          let in_attack_range = distance < attack_range
          if in_attack_range: 
            u.behavior_mode = UnitBehaviourMode.Fighting
          else:
            let has_reached_target = move_unit_torwards_given_target(
              self, u, u.attack_target.get.get_position, dt)
            discard has_reached_target
          # if the unit i follow, dies, i dont want to have this 
          # unit as attack target anymore
          if u.attack_target.get.dead: u.attack_target = none(Unit) 

      else: discard



proc apply_unit_collision_velocity*(self: var Battle, dt: float) =
  for _, u in mpairs(self.units):
    if u.my_control_group.current_mode != ControlGroupMode.Fighting: continue
    if u.last_push < 0: 
      u.shape.x += u.collision_velocity.x * 20 
      u.shape.y += u.collision_velocity.y * 20 
      u.shape.x = self.game.world_sanatize_x(u.shape.x) 
      u.shape.y = self.game.world_sanatize_y(u.shape.y) 
      u.last_push = rand(0..UNIT_COLLISION_INTERVAL)/UNIT_COLLISION_INTERVAL
      self.update_chunk_position_of_unit(u)
    u.last_push -= dt     



proc check_for_collision_in_chunk(
  self: var Battle, u: var Unit, chunk: Chunk, dt: float) =

  ## Check a single unit for collisions in chunk

  var counter = 0
  for _, other_u in chunk.units:
    if other_u == u: continue
    counter = counter + 1
    if counter > 200: break #  more than 100 units per chunk make no sense to collide
    # Check for collision between u and other_u
    if not collision(u.shape, other_u.shape): continue 
    # we got a collision
    var x_push_direction = 0; var y_push_direction = 0
    if u.shape.x >= other_u.shape.x: x_push_direction = +1
    if u.shape.x < other_u.shape.x: x_push_direction = -1
    if u.shape.y >= other_u.shape.y: y_push_direction = +1
    if u.shape.y < other_u.shape.y: y_push_direction = -1
    let overlap_x = abs(u.shape.x - other_u.shape.x)
    let overlap_y = abs(u.shape.y - other_u.shape.y)
    if overlap_x == 0 and overlap_y == 0: 
      u.shape.x += rand(0..COLLISION_PUSH_INTERVAL_PIXEL).float
      u.shape.y += rand(0..COLLISION_PUSH_INTERVAL_PIXEL).float
      u.shape.x = self.game.world_sanatize_x(u.shape.x) 
      u.shape.y = self.game.world_sanatize_y(u.shape.y) 
    u.collision_velocity.x = (x_push_direction.float) / 2 
    u.collision_velocity.y = (y_push_direction.float) / 2 



proc collide_units_with_each_other*(self: var Battle, dt: float) {.inline.} =
  for _, u in mpairs(self.units):
    if u.my_control_group.current_mode != ControlGroupMode.Fighting: continue
    if u.next_collsion_check > 0:(u.next_collsion_check -= dt; continue)
    u.collision_velocity.x = 0
    u.collision_velocity.y = 0
    let my_chunk = self.get_chunk_by_xy(u.shape)
    self.check_for_collision_in_chunk(u, my_chunk, dt)
    # check if this unit is near to the border 
    let my_chunk_end_x = (my_chunk.x + CHUNK_SIZE_IN_PIXEL).float
    let my_chunk_end_y = (my_chunk.y + CHUNK_SIZE_IN_PIXEL).float
    if 
        u.shape.x - u.shape.width < my_chunk.x.float or
        u.shape.y - u.shape.height < my_chunk.y.float or 
        u.shape.x + u.shape.width*2 > my_chunk_end_x or 
        u.shape.y + u.shape.height*2 > my_chunk_end_y: 
        for chunk in self.get_chunks_around_chunk(u):
            self.check_for_collision_in_chunk(u, chunk, dt)
    u.next_collsion_check = rand(0..UNIT_COLLISION_INTERVAL)/UNIT_COLLISION_INTERVAL     



  ##[  
                // Circle shapes and lines
            DrawCircle(screenWidth/5, 120, 35, DARKBLUE);
            DrawCircleGradient(screenWidth/5, 220, 60, GREEN, SKYBLUE);
            DrawCircleLines(screenWidth/5, 340, 80, DARKBLUE);

            // Rectangle shapes and lines
            DrawRectangle(screenWidth/4*2 - 60, 100, 120, 60, RED);
            DrawRectangleGradientH(screenWidth/4*2 - 90, 170, 180, 130, MAROON, GOLD);
            DrawRectangleLines(screenWidth/4*2 - 40, 320, 80, 60, ORANGE);  // NOTE: Uses QUADS internally, not lines

            // Triangle shapes and lines
            DrawTriangle((Vector2){ screenWidth/4.0f *3.0f, 80.0f },
                         (Vector2){ screenWidth/4.0f *3.0f - 60.0f, 150.0f },
                         (Vector2){ screenWidth/4.0f *3.0f + 60.0f, 150.0f }, VIOLET);

            DrawTriangleLines((Vector2){ screenWidth/4.0f*3.0f, 160.0f },
                              (Vector2){ screenWidth/4.0f*3.0f - 20.0f, 230.0f },
                              (Vector2){ screenWidth/4.0f*3.0f + 20.0f, 230.0f }, DARKBLUE);

            // Polygon shapes and lines
            DrawPoly((Vector2){ screenWidth/4.0f*3, 330 }, 6, 80, rotation, BROWN);
            DrawPolyLines((Vector2){ screenWidth/4.0f*3, 330 }, 6, 90, rotation, BROWN);
            DrawPolyLinesEx((Vector2){ screenWidth/4.0f*3, 330 }, 6, 85, rotation, 6, BEIGE);
            ]##