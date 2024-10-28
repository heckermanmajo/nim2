import std/options
import std/math

import raylib

import CONFIG

import engine/engine_types
import battle/battle_types
import battle/methods/btile_methods


proc update_render_texture*(me: Chunk)
proc populate_chunk_with_tiles(me: Chunk)

proc init*(me: Chunk, x,y: int) =
  me.shape = Rectangle(
    x:      x.float * CONFIG.CHUNK_SIZE_IN_PIXELS,
    y:      y.float * CONFIG.CHUNK_SIZE_IN_PIXELS,
    width:  CONFIG.CHUNK_SIZE_IN_PIXELS.float, 
    height: CONFIG.CHUNK_SIZE_IN_PIXELS.float)  
  me.populate_chunk_with_tiles()
  me.render_texture = loadRenderTexture(CONFIG.CHUNK_SIZE_IN_PIXELS,CONFIG.CHUNK_SIZE_IN_PIXELS).some
  me.update_render_texture()


proc update_render_texture*(me: Chunk) = 
  beginTextureMode(me.render_texture.get)
  let e = engine();clearBackground(GREEN)
  for tile in me.tiles:
    let pos = Vector2( # minus shape, otherwise they will be rendered outside the tmp texture
      x: tile.real_pos.x - me.shape.x, 
      y: tile.real_pos.y - me.shape.y) 
    e.draw_gras(pos) 
    if tile.nmob.isSome: e.draw_wall(pos)
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

proc `$`*(me: Chunk): string = 
  "CHUNK: shape: " & $me.shape