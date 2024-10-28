import std/options
import raylib
import ../battle_types
import ../methods/battle_methods
import ../methods/chunk_methods
import ../methods/btile_methods

proc selected_tile*(me: Battle, pos: Vector2) = 
  # This is a debug function to select a tile and 
  # render its contents into the console
  if not me.given_pos_in_world(pos): return
  let chunk = me.get_chunk_by_absolute_position(pos)
  let tile = chunk.get_tile_by_absolute_position(pos)
  echo $tile
