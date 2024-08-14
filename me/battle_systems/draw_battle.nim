import std/math

import raylib
import ../CONFIG
import ../battle_types


proc draw*(me: Battle) = 

  beginMode2D(me.camera);

  for tile in me.tiles:
    let rect = tile.absolute_postion_as_rect
    if me.given_pos_in_view(rect):
      drawRectangleLines(rec=rect,lineThick=1, color=WHITE)  

  endMode2D()  



  # debug information here ....
  when CONFIG.DEBUG:
    # draw a gray rect around this
    drawRectangle(Rectangle(x: 0, y:CONFIG.TOP_BAR_HEIGHT.float, width: 300, height: 200), color= CONFIG.WORLD_COLOR_TRANSPARENT)
    let fps = getFPS()
    drawText(("FPS: " & $fps).cstring, 10, (10+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Camera: X: " & $me.camera.target.x.floor & "Y: " & $me.camera.target.x.floor).cstring, 10, (30+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Zoom: " & $me.camera.zoom).cstring, 10, (50+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    let mouse_pos = getMousePosition()
    drawText(("Mouse: " & $mouse_pos).cstring, 10, (70+CONFIG.TOP_BAR_HEIGHT).int32, 20, CONFIG.WORLD_COLOR)
    drawText(("Zoom Level: " & $me.zoom_level).cstring, 10, (90+CONFIG.TOP_BAR_HEIGHT).int32, 20, WORLD_COLOR)
