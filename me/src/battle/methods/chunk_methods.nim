import std/options
import std/math

import raylib

import ../../CONFIG

import ../../engine/engine_types
import ../battle_types
import btile_methods

when false:
  type
    Chunk* = ref object
      ## we use chunk to improve performance 
      tiles*: seq[BTile] 
      render_texture*: RenderTexture
      ## we render the background tiles at the start of a battle into this 
      ## render_texture, so we dont need to loop over all tiles.
      shape*: Rectangle


proc create_render_texture(me: Chunk)
proc populate_chunk_with_tiles(me: Chunk)

proc init*(me: Chunk, x,y: int) =
  me.shape = Rectangle(
    x:      x.float * CONFIG.CHUNK_SIZE_IN_PIXELS,
    y:      y.float * CONFIG.CHUNK_SIZE_IN_PIXELS,
    width:  CONFIG.CHUNK_SIZE_IN_PIXELS.float, 
    height: CONFIG.CHUNK_SIZE_IN_PIXELS.float)  
  me.populate_chunk_with_tiles()
  me.render_texture = loadRenderTexture(CONFIG.CHUNK_SIZE_IN_PIXELS,CONFIG.CHUNK_SIZE_IN_PIXELS).some
  me.create_render_texture()


proc create_render_texture(me: Chunk) = 
  beginTextureMode(me.render_texture.get)
  let e = engine();clearBackground(GREEN)
  for tile in me.tiles: 
    e.draw_gras(
      Vector2( # minus shape, otherwise they will be rendered outside the tmp texture
        x: tile.real_pos.x - me.shape.x, 
        y: tile.real_pos.y - me.shape.y)) 
  endTextureMode()  

proc populate_chunk_with_tiles(me: Chunk) = 
  for x in 0..CONFIG.CHUNK_SIZE_IN_TILES-1:
    for y in 0..CONFIG.CHUNK_SIZE_IN_TILES-1:
      var t = BTile()
      t.init(
        x=(x*CONFIG.TILE_SIZE).float + me.shape.x,
        y=(y*CONFIG.TILE_SIZE).float + me.shape.y
      )
      me.tiles.add(t)

proc clean_raylib_resources_to_prevent_segfault*(me: Chunk) = 
  me.render_texture = none(RenderTexture)

proc get_tile_by_absolute_position*(me: Chunk, pos: Vector2): BTile = 
  # stuff 
  let x = ((pos.x - me.shape.x) / TILE_SIZE).floor
  let y = ((pos.y - me.shape.y) / TILE_SIZE).floor
  let index = (x * CHUNK_SIZE_IN_TILES + y).int
  return me.tiles[index]  