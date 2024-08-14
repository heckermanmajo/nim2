import std/options

import raylib

import ../CONFIG
import ../battle_types

# forward definition, it is defined at the end of the file
# since it will not change a lot
proc get_left_mouse_drag_selection_rect_and_draw_it(self: Battle): 
  Option[tuple[screen_relative: Rectangle, world_relative: Rectangle]]

proc get_click_on_the_screen(game: Battle; button: MouseButton): 
  Option[tuple[screen_relative: Vector2, world_relative: Vector2]]



proc handle_mouse_click_and_drag*(me: Battle, dt: float) = 

  block:
    let drag_rect_option = me.get_left_mouse_drag_selection_rect_and_draw_it()
    if drag_rect_option.is_some(): 
      let drag_rect = drag_rect_option.get()
      # todo: use the drag rect here ...

  block:   
    let left_click_on_screen_option = me.get_click_on_the_screen(MouseButton.Left)
    if left_click_on_screen_option.is_some():
      let left_click_on_screen = left_click_on_screen_option.get()
      # todo: use the click here 

  block:
    let right_click_on_screen_option = me.get_click_on_the_screen(MouseButton.Right)
    if right_click_on_screen_option.is_some():
      let right_click_on_screen = right_click_on_screen_option.get()
      # todo: use the click here 



proc get_click_on_the_screen(game: Battle; button: MouseButton): 
  Option[tuple[screen_relative: Vector2, world_relative: Vector2]] =

  if not isMouseButtonPressed(button): 
    return none(tuple[screen_relative: Vector2, world_relative: Vector2])
  return some(( getMousePosition(),
    Vector2(
      x: (getMousePosition().x - game.camera.offset.x) / 
        game.camera.zoom + game.camera.target.x,
      y: (getMousePosition().y - game.camera.offset.y) / 
        game.camera.zoom + game.camera.target.y)))




proc get_left_mouse_drag_selection_rect_and_draw_it(self: Battle): 
  Option[tuple[screen_relative: Rectangle, world_relative: Rectangle]] =
  
  ## This function returns the rectangle of a mouse selection of the left mouse
  ## it also draws the selection rect during dragging
  
  if isMouseButtonDown(MouseButton.Left):
    var mouseStartPosition = Vector2(x: 0, y: 0)
    var mouseCurrentPosition: Vector2
    if self.mouseDragStart.isNone:
      mouseStartPosition = getMousePosition()
      self.mouseDragStart = some(mouseStartPosition)
    else:
      mouseStartPosition = self.mouseDragStart.get
      mouseCurrentPosition = getMousePosition()
      let rect_screen_relative = Rectangle(
        x: min(mouseStartPosition.x, mouseCurrentPosition.x),
        y: min(mouseStartPosition.y, mouseCurrentPosition.y),
        width: abs(mouseCurrentPosition.x - mouseStartPosition.x),
        height: abs(mouseCurrentPosition.y - mouseStartPosition.y))

      var rect_world_relative = Rectangle(
        x: (min(mouseStartPosition.x, mouseCurrentPosition.x) - self.camera.offset.x) / self.camera.zoom + self.camera.target.x,
        y: (min(mouseStartPosition.y, mouseCurrentPosition.y) - self.camera.offset.y) / self.camera.zoom + self.camera.target.y,
        width: abs(mouseCurrentPosition.x - mouseStartPosition.x).float / self.camera.zoom,
        height: abs(mouseCurrentPosition.y - mouseStartPosition.y).float / self.camera.zoom)

      drawRectangleLines(rect_screen_relative, 2, CONFIG.WORLD_COLOR)
      return some((rect_screen_relative, rect_world_relative))
  else:
    self.mouseDragStart = none(Vector2)
  return none(tuple[screen_relative: Rectangle, world_relative: Rectangle])



