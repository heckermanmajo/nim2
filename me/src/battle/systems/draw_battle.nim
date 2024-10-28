import std/math
import std/options

import raylib

import CONFIG

import battle/methods/chunk_methods
import engine/engine_types

import battle/battle_types
import battle/methods/battle_methods



proc draw*(me: Battle) =
  ## 
  ## Draw the whole battle
  ## 
  ## 1. Draw the world by drawing the visible chunks -> they are drawn as 
  ##    single texture in which all tiles, visual sprites and non moving objects
  ##    are buffered
  ## 
  ## 2. Draw all units in the view: use the chunk to determine which unist are in 
  ##    view, so we dont need to loop over all units each draw loop.
  ## 
  ## 3. Draw debug information at the top left corner of the screen.
  ## 
  ## TODO: point 2 is not yet done ...
  ## 

  beginMode2D(me.camera);

  let source = Rectangle(x:0,y:0, 
    width  :   CONFIG.CHUNK_SIZE_IN_PIXELS.float,
    height : - CONFIG.CHUNK_SIZE_IN_PIXELS.float)

  let origin = Vector2(x:0,y: 0)
  
  for c in me.chunks:
    if me.given_pos_in_view(c.shape):
      drawTexture(
        texture  = c.render_texture.get.texture,
        source   = source,
        dest     = c.shape,
        origin   = origin,
        rotation = 0, 
        tint     = WHITE);

    when CONFIG.DEBUG:
      drawRectangleLines(rec=c.shape,lineThick=1, color=YELLOW)

  endMode2D()  

  # different uis, based on the user control mode

  case me.user_control_mode:
    of UserControlMode.MAP_EDITOR_MODE: discard
    of UserControlMode.NORMIE_MODE: discard
    of UserControlMode.PATHFINDER_MODE: discard
    of UserControlMode.GOD_PLAYER_MODE: discard

  # debug information here ....
  when CONFIG.DEBUG:
    # draw a gray rect around this
    drawRectangle(Rectangle(x: 0, y:CONFIG.TOP_BAR_HEIGHT.float, width: 300, height: 200), color= CONFIG.WORLD_COLOR_TRANSPARENT)
    let fps = getFPS()
    drawText(("FPS: " & $fps), 10, (10+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Camera: X: " & $me.camera.target.x.floor & "Y: " & $me.camera.target.y.floor), 10, (30+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Zoom: " & $me.camera.zoom), 10, (50+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    let mouse_pos = getMousePosition()
    drawText(("Mouse: " & $mouse_pos), 10, (70+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Zoom Level: " & $me.zoom_level), 10, (90+CONFIG.TOP_BAR_HEIGHT).int32, 20, WORLD_COLOR)
    drawText(($me.user_control_mode), 10, (110+CONFIG.TOP_BAR_HEIGHT).int32, 20, WORLD_COLOR)