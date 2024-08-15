import std/options
import raylib
import ../battle_types
import ../methods/battle_methods
import ../methods/chunk_methods

proc place_nmob*(me: Battle, pos: Vector2) = 
  if not me.given_pos_in_world(pos): return
  let chunk = me.get_chunk_by_absolute_position(pos)
  let tile = chunk.get_tile_by_absolute_position(pos)
  tile.nmob = some(NonMovingObject())