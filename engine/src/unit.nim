import std/random
import std/options

import raylib
import raymath

import config
import types
import core
import battle
import chunk



proc think_units*(self: Battle, dt: float) =
  ## if a unit finds an enemy or is attacked, the control-group
  ## moves into the fight
  discard



proc fight_units*(self: Battle, dt: float) = discard



proc draw_all_units*(self: Battle, dt: float) {.inline.} =
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
      drawCircle(center_x, center_y, u.shape.width / 2, color);



proc draw_rect_around_selected_units*(self: Battle, dt: float) =
 
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



proc move_units*(self: var Battle, dt: float) =
  let SPEED = 100.0
  for _, u in mpairs(self.units):
    if u.move_target.isSome:
      let target_x = u.move_target.get.x
      let target_y = u.move_target.get.y
      let distance_x = u.shape.x - target_x.float
      let distance_y = u.shape.y - target_y.float
      if distance_x < 0 and abs(distance_x) > 3: u.shape.x += SPEED * dt
      if distance_x > 0 and abs(distance_x) > 3: u.shape.x -= SPEED * dt
      if distance_y < 0 and abs(distance_y) > 3: u.shape.y += SPEED * dt
      if distance_y > 0 and abs(distance_y) > 3: u.shape.y -= SPEED * dt
      if abs(distance_x) < 4 and abs(distance_y) < 4:
        u.shape.x = u.move_target.get.x
        u.shape.y = u.move_target.get.y
        u.move_target = none(Vector2)
      if self.get_chunk_by_xy(u.shape.x, u.shape.y) != u.chunk_i_am_on:
        var old_chunk = u.chunk_i_am_on
        var new_chunk = self.get_chunk_by_xy(u.shape.x, u.shape.y)
        old_chunk.units.delete(old_chunk.units.find(u))
        new_chunk.units.add(u)
        u.chunk_i_am_on = new_chunk



proc apply_unit_collision_velocity*(self: var Battle, dt: float) =
  for _, u in mpairs(self.units):
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



proc manage_unit_deaths*() =
  ## check for units with that are dead and remove them
  discard