import raylib
import ../../CONFIG 
import ../battle_types
import ../methods/battle_methods
import ../methods/chunk_methods
import ../methods/btile_methods

proc init*(me: Battle, chunk_per_side = 20) = 
  ## Initialize the battle based on the given parameters.
  ## Will also clean up all previous initialized battle memory.
  
  me.delete()

  me.world_size_in_tiles = chunk_per_side * CONFIG.CHUNK_SIZE_IN_TILES
  me.world_size_in_chunk = chunk_per_side
  me.tile_as_grid = @[]
  me.SCREEN_W_AS_FLOAT = getScreenWidth().float
  me.SCREEN_H_AS_FLOAT = getScreenHeight().float

  # instanciate the tiles based on chunks

  block initialize_chunks_of_battle_map:
    for x in 0..me.world_size_in_chunk-1:
      for y in 0..me.world_size_in_chunk-1: 
        var c = Chunk()
        c.init(x,y)
        me.chunks.add(c)
