import std/math
import std/options

import raylib

import ../../CONFIG

import ../battle_types
import ../methods/battle_methods
import ../../engine/engine_types


proc draw*(me: Battle) = 

  beginMode2D(me.camera);

  let e = engine()
  # todo;: to improve performance 
  # use renderTexture to pre-render a chunk of tiles to such a texture 
  # at the start of the battle (battle.init) and then use these 
  # we can draw effect after this
  # we can also only render effects based on chunks, so we have a fast loop
  # we can extend this concept of chunks to all kinds of visual systems
  # https://github.com/raysan5/raylib/issues/1179

  for c in me.chunks:
    
    if me.given_pos_in_view(c.shape):
      drawTexture(c.render_texture.get.texture, c.shape.x.int32, c.shape.y.int32, WHITE)

      for t in c.tiles:
        if t.nmob.is_some:
          e.draw_wall(t.real_pos)
      #for tile in c.tiles:
      #  e.draw_gras(tile.real_pos) 
      #  when CONFIG.TILE_GRID:
      #    drawRectangleLines(rec=tile.absolute_postion_as_rect,lineThick=1, color=WHITE)
    drawRectangleLines(rec=c.shape,lineThick=3, color=YELLOW)
  
  #for tile in me.tiles:
  #  let rect = tile.absolute_postion_as_rect
  #  if me.given_pos_in_view(rect):
  #    #drawRectangleLines(rec=rect,lineThick=1, color=WHITE)
  #    #drawTexture(e.atlas1.get,GRAS_QUAD, Vector2(x: (tile.num_pos.x*CONFIG.TILE_SIZE).float, y: (tile.num_pos.y*CONFIG.TILE_SIZE).float), WHITE)
  #    e.draw_gras(tile.real_pos) 
  #    when CONFIG.TILE_GRID:
  #      drawRectangleLines(rec=rect,lineThick=1, color=WHITE)

  endMode2D()  



  # debug information here ....
  when CONFIG.DEBUG:
    # draw a gray rect around this
    drawRectangle(Rectangle(x: 0, y:CONFIG.TOP_BAR_HEIGHT.float, width: 300, height: 200), color= CONFIG.WORLD_COLOR_TRANSPARENT)
    let fps = getFPS()
    drawText(("FPS: " & $fps).cstring, 10, (10+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Camera: X: " & $me.camera.target.x.floor & "Y: " & $me.camera.target.y.floor).cstring, 10, (30+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Zoom: " & $me.camera.zoom).cstring, 10, (50+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    let mouse_pos = getMousePosition()
    drawText(("Mouse: " & $mouse_pos).cstring, 10, (70+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Zoom Level: " & $me.zoom_level).cstring, 10, (90+CONFIG.TOP_BAR_HEIGHT).int32, 20, WORLD_COLOR)
    #drawText(("X: " & $start_x & " - " & $end_x & " - " & $(end_x - start_x)).cstring, 10, (110+CONFIG.TOP_BAR_HEIGHT).int32, 20, WORLD_COLOR)
    #drawText(("Y: " & $start_y & " - " & $end_y & " - " & $(end_y - start_y)).cstring, 10, (130+CONFIG.TOP_BAR_HEIGHT).int32, 20, WORLD_COLOR)
