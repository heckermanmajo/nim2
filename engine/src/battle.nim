import std/tables
import std/math
import std/options

import raylib

import config
import types
import utils
import game_utils

# Controllgruppen-Steuerung

proc update_control_group_centers*(self: var Battle, dt: float) =
  for cg in self.control_groups:
    var center_x = 0; center_y = 0
    for u in cg.units: (center_x += u.shape.x.int; center_y +=u.shape.y.int)
    cg.center = Vector2(center_x/cg.units.len, center_y/cg.units.len)

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


proc manage_unit_deaths*() =
  ## check for units with that are dead and remove them
  discard

proc manage_control_group_deaths*() = discard

proc collide_units_with_each_other*(self: Battle, dt: float) = discard

proc think_units*(self: Battle, dt: float) =
  ## if a unit finds an enemy or is attacked, the control-group
  ## moves into the fight
  discard

proc fight_units*(self: Battle, dt: float) = discard

proc fly_and_collide_projectiles*(self: Battle, dt: float) = discard

proc draw_projectiles*(self: Battle, dt: float) = discard

proc draw_all_units*(self: Battle, dt: float) =
  for u in self.units: (if u.dead: continue);
    if self.game.given_pos_in_view(u.shape):
      let center_x = (u.shape.x + u.shape.width / 2).int32
      let center_y = (u.shape.y + u.shape.height / 2).int32
      drawCircleGradient(center_x, center_y, u.shape.width / 2, BLUE, SKYBLUE);

proc draw_rect_around_selected_units*(self: Battle, dt: float) =
  for u in self.currently_selected_units:
    if self.game.given_pos_in_view(u.shape):
      drawRectangleLines(
        Rectangle(
          x:u.shape.x - 4,
          y: u.shape.y - 4,
          width: u.shape.width + 8,
          height: u.shape.height + 8
        ),
        2,
        YELLOW)

proc get_chunk_by_xy_optional*(self: Battle; x, y: int): Option[Chunk] =
  let index_x = floor(x / CHUNK_SIZE_IN_PIXEL).int
  let index_y = floor(y / CHUNK_SIZE_IN_PIXEL).int
  if not self.chunks_on_xy.hasKey(index_x): return none(Chunk)
  if not self.chunks_on_xy[index_x].hasKey(index_y): return none(Chunk)
  return some(self.chunks_on_xy[index_x][index_y])

proc get_chunk_by_xy*(self: Battle; x, y: int ): Chunk =
  let index_x = floor(x / CHUNK_SIZE_IN_PIXEL).int
  let index_y = floor(y / CHUNK_SIZE_IN_PIXEL).int
  when(config.DEBUG):
    if not self.chunks_on_xy.hasKey(index_x):
      raise Defect.newException("Cannot get chunk (x not found): bad params or bad state." & $x & " - " & $y)
    if not self.chunks_on_xy[index_x].hasKey(index_y):
      raise Defect.newException("Cannot get chunk (y not found): bad params or bad state." & $x & " - " & $y)
  return self.chunks_on_xy[index_x][index_y]

proc get_chunk_by_xy*(self: Battle; x, y: float ): Chunk = return self.get_chunk_by_xy(x.int, y.int)

proc get_chunks_around_chunk(self: Battle, x, y: int, also_diagonal: bool = false): seq[Chunk] {.inline.} =
  ## This function returns a list of all neighbour chunks
  var chunks = newSeq[Chunk]()
  let c1 = self.get_chunk_by_xy_optional(x - CHUNK_SIZE_IN_PIXEL, y ); if c1.isSome: chunks.add(c1.get)
  let c2 = self.get_chunk_by_xy_optional(x + CHUNK_SIZE_IN_PIXEL, y ); if c2.isSome: chunks.add(c2.get)
  let c3 = self.get_chunk_by_xy_optional(x , y + CHUNK_SIZE_IN_PIXEL ); if c3.isSome: chunks.add(c3.get)
  let c4 = self.get_chunk_by_xy_optional(x , y - CHUNK_SIZE_IN_PIXEL ); if c4.isSome: chunks.add(c4.get)
  if also_diagonal:
    let c5 = self.get_chunk_by_xy_optional(x - CHUNK_SIZE_IN_PIXEL, y - CHUNK_SIZE_IN_PIXEL); if c5.isSome: chunks.add(c5.get)
    let c6 = self.get_chunk_by_xy_optional(x + CHUNK_SIZE_IN_PIXEL, y - CHUNK_SIZE_IN_PIXEL); if c6.isSome: chunks.add(c6.get)
    let c7 = self.get_chunk_by_xy_optional(x + CHUNK_SIZE_IN_PIXEL, y + CHUNK_SIZE_IN_PIXEL ); if c7.isSome: chunks.add(c7.get)
    let c8 = self.get_chunk_by_xy_optional(x - CHUNK_SIZE_IN_PIXEL, y + CHUNK_SIZE_IN_PIXEL ); if c8.isSome: chunks.add(c8.get)
  return chunks

proc get_chunks_around_chunk(self: Battle, projectile: Projectile, also_diagonal: bool = false): seq[Chunk] {.inline.} =
  ## This function returns a list of all neighbour chunks
  return self.get_chunks_around_chunk(projectile.shape.x.int, projectile.shape.y.int, also_diagonal)

proc get_chunks_around_chunk(self: Battle, unit: Unit, also_diagonal: bool = false): seq[Chunk]  {.inline.} =
  ## This function returns a list of all neighbour chunks
  return self.get_chunks_around_chunk(unit.shape.x.int, unit.shape.y.int, also_diagonal)

proc get_chunks_around_chunk(self: Battle, chunk: Chunk, also_diagonal: bool = false): seq[Chunk]  {.inline.} =
  ## This function returns a list of all neighbour chunks
  return self.get_chunks_around_chunk(chunk.x, chunk.y, also_diagonal)

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
      if distance_x < 0: u.shape.x += SPEED * dt
      if distance_x > 0: u.shape.x -= SPEED * dt
      if distance_y < 0: u.shape.y += SPEED * dt
      if distance_y > 0: u.shape.y -= SPEED * dt
      if abs(distance_x) < 10 and abs(distance_y) < 10:
        u.move_target = none(Vector2)
      if self.get_chunk_by_xy(u.shape.x, u.shape.y) != u.chunk_i_am_on:
        var old_chunk = u.chunk_i_am_on
        var new_chunk = self.get_chunk_by_xy(u.shape.x, u.shape.y)
        old_chunk.units.delete(old_chunk.units.find(u))
        new_chunk.units.add(u)
        u.chunk_i_am_on = new_chunk