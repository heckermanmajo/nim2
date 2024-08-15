import std/options
import std/math

import raylib

import ../../lib/astar

import ../../CONFIG

import ../battle_types
import chunk_methods
import btile_methods


proc world_size_in_pixel*(me: Battle): int = me.world_size_in_tiles * CONFIG.TILE_SIZE
proc world_size_in_pixel_f*(me: Battle): float = (me.world_size_in_tiles * CONFIG.TILE_SIZE).float

proc delete*(me: Battle) = 
  ## Deletes all battle memory.
  discard 

proc given_pos_in_view*(me: Battle; x, y, width, height: float): bool =
  
  ## Check if a given rect is in view of the camera

  let viewTopLeftX = me.camera.target.x
  let viewTopLeftY = me.camera.target.y
  let viewBottomRightX = (
    me.camera.target.x + (me.SCREEN_W_AS_FLOAT) / me.camera.zoom)
  let viewBottomRightY = (
    me.camera.target.y + (me.SCREEN_H_AS_FLOAT) / me.camera.zoom)
  return not (x > viewBottomRightX or
              x + width < viewTopLeftX or
              y > viewBottomRightY or
              y + height < viewTopLeftY)


template given_pos_in_view*(me: Battle; rect: Rectangle): bool  =
  me.given_pos_in_view( rect.x, rect.y, rect.width, rect.height)

proc world_sanatize_value*(me: Battle, x_or_y: int): int  
  = (if x_or_y < 0: return 0; if x_or_y > me.world_size_in_pixel(): return me.world_size_in_pixel(); return x_or_y)

proc world_sanatize_value*(me: Battle, x_or_y: float): float 
  = (if x_or_y < 0: return 0; if x_or_y > me.world_size_in_pixel_f(): return me.world_size_in_pixel_f(); return x_or_y)

proc given_pos_in_world*(me: Battle, pos: Vector2): bool = 
  if pos.x < 0: return false
  if pos.y < 0: return false
  if pos.x > me.world_size_in_pixel().float: return false
  if pos.y > me.world_size_in_pixel().float: return false
  return true

proc get_tile_from_pos*(me: Battle, pos: Vector2): Option[BTile] = 
  if not me.given_pos_in_world(pos): return none(BTile)
  let x = (pos.x / CONFIG.TILE_SIZE).int
  let y = (pos.y / CONFIG.TILE_SIZE).int
  return some(me.tile_as_grid[x][y])

proc get_tile_from_pos*(me: Battle, pos: GridPoint): BTile = me.tile_as_grid[pos.x][pos.y]


proc get_chunk_by_absolute_position*(me: Battle, pos: Vector2): Chunk = 
  # stuff 
  let x = (pos.x / CHUNK_SIZE_IN_PIXELS).floor
  let y = (pos.y / CHUNK_SIZE_IN_PIXELS).floor
  let index = (x * me.world_size_in_chunk.float + y).int
  return me.chunks[index]