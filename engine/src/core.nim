##
## Game Utils 
## Functions that are related to the game state 
## so are needed in all modes.
##


import std/options

import raylib

import config
import types



func collision*(r1, r2: Rectangle): bool =
  return not ((r1.x + r1.width < r2.x) or (r2.x + r2.width < r1.x) or
             (r1.y + r1.height < r2.y) or (r2.y + r2.height < r1.y))



func collision*(p: Vector2, r: Rectangle): bool =
  return (p.x >= r.x) and (p.x <= r.x + r.width) and (p.y >= r.y) and (p.y <= r.y + r.height)



func get_overlap*(r1, r2: Rectangle): Option[Vector2] =
  if not collision(r1, r2): return none(Vector2)
  else:
    var xOverlap = min(r1.x + r1.width, r2.x + r2.width) - max(r1.x, r2.x)
    var yOverlap = min(r1.y + r1.height, r2.y + r2.height) - max(r1.y, r2.y)
    return some(Vector2(x: xOverlap, y: yOverlap))



proc log*(self: Game; msg: string) = 
  
  ## if we ae not in debug mode, produce not logging data
  
  when (config.DEBUG):
    self.logfile.write(msg & "\n")
  else: discard



proc move_camera_with_wasd*(self: var Game; dt: float) =
  let speed = self.zoom_factor * self.wasd_move_speed * dt
  if isKeyDown(KeyboardKey.D): self.camera.target.x += speed
  if isKeyDown(KeyboardKey.A): self.camera.target.x -= speed
  if isKeyDown(KeyboardKey.W): self.camera.target.y -= speed
  if isKeyDown(KeyboardKey.S): self.camera.target.y += speed



proc move_world_with_mouse_middle_drag*(self: var Game, dt: float) =
  
  ## Move the world by moving the mouse while holding middle moouse down
  
  if isMouseButtonDown(MouseButton.Middle):
    let mouseDelta = getMouseDelta()
    self.camera.target.x += 
      mouseDelta.x * dt * self.mouse_middle_drag_speed * self.camera.zoom 
    self.camera.target.y += 
      mouseDelta.y * dt * self.mouse_middle_drag_speed + self.camera.zoom
    
    let padding = 1200.0 
    if self.camera.target.x < - padding: self.camera.target.x = - padding
    if self.camera.target.y < - padding: self.camera.target.y = - padding


proc zoom_in_out*(self: var Game, dt: float) =
  let MIN_ZOOM = 0.3
  let MAX_ZOOM = 4.0
  let moved = getMouseWheelMove()
  if moved != 0:
    let zoom_delta = moved * 0.2
    let old_zoom = self.camera.zoom
    self.camera.zoom += zoom_delta
    if self.camera.zoom < MIN_ZOOM: self.camera.zoom = MIN_ZOOM
    if self.camera.zoom > MAX_ZOOM: self.camera.zoom = MAX_ZOOM
    let new_zoom = self.camera.zoom
    # Adjust the camera target to keep the center position the same
    let screen_center = Vector2(
      x: getScreenWidth().float / 2.0,
      y: getScreenHeight().float / 2.0)
    let world_center_before = Vector2(
      x: (screen_center.x - self.camera.offset.x) / old_zoom + self.camera.target.x,
      y: (screen_center.y - self.camera.offset.y) / old_zoom + self.camera.target.y)
    let world_center_after = Vector2(
      x: (screen_center.x - self.camera.offset.x) / new_zoom + self.camera.target.x,
      y: (screen_center.y - self.camera.offset.y) / new_zoom + self.camera.target.y)
    self.camera.target.x -= world_center_after.x - world_center_before.x
    self.camera.target.y -= world_center_after.y - world_center_before.y

    # The zoom factor allows us to change the way to display the game 
    # based on how far we have zoomed out
    self.zoom_factor = case (self.camera.zoom * 10).int:
      of 0..2:   self.zoom_level = ZoomLevel.Mini;      16f
      of 3..4:   self.zoom_level = ZoomLevel.VerySmall; 16f
      of 5..9:   self.zoom_level = ZoomLevel.Small;     8f
      of 10:     self.zoom_level = ZoomLevel.Default;   4f
      of 11..19: self.zoom_level = ZoomLevel.Big;       2f
      of 20..40: self.zoom_level = ZoomLevel.Big;       0.5
      else:      self.zoom_level = ZoomLevel.Big;       0.1



proc given_pos_in_view*(self: Game; x, y, width, height: float): bool {.inline.} =
  
  ## Check if a given rect is in view of the camera

  let viewTopLeftX = self.camera.target.x
  let viewTopLeftY = self.camera.target.y
  let viewBottomRightX = (
    self.camera.target.x + (getScreenWidth().float) / self.camera.zoom)
  let viewBottomRightY = (
    self.camera.target.y + (getScreenHeight().float ) / self.camera.zoom)
  return not (x > viewBottomRightX or
              x + width < viewTopLeftX or
              y > viewBottomRightY or
              y + height < viewTopLeftY)



proc given_pos_in_view*(self: Game; rect: Rectangle): bool {.inline.} =
  return self.given_pos_in_view( rect.x, rect.y, rect.width, rect.height)



proc draw_chunk_outline_and_units_in_it*(self: Game) =
  for chunk in self.battle.chunks:
    let real_chunk_x = (chunk.x*CHUNK_SIZE_IN_PIXEL).float
    let real_chunk_y = (chunk.y*CHUNK_SIZE_IN_PIXEL).float
    let not_in_view
      = not self.given_pos_in_view(real_chunk_x, real_chunk_y, CHUNK_SIZE_IN_PIXEL.float,CHUNK_SIZE_IN_PIXEL.float)
    if not_in_view: continue
    drawRectangleLines(
      Rectangle(
        x: real_chunk_x,
        y: real_chunk_y,
        width: CHUNK_SIZE_IN_PIXEL.float,
        height: CHUNK_SIZE_IN_PIXEL.float),
      2.float,
    WORLD_COLOR)
    if self.zoom_level == ZoomLevel.VerySmall or self.zoom_level == ZoomLevel.Small:continue
    let number_of_units_in_chunk = chunk.units.len
    let top_left_chunk_corner_x = real_chunk_x + 10
    let top_left_chunk_corner_y = real_chunk_y + 10
    drawText(($number_of_units_in_chunk).cstring, top_left_chunk_corner_x.int32, top_left_chunk_corner_y.int32, 20, WORLD_COLOR)



proc get_left_mouse_drag_selection_rect_and_draw_it*(self: Game): 
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

      drawRectangleLines(rect_screen_relative, 2, WORLD_COLOR)
      return some((rect_screen_relative, rect_world_relative))
  else:
    self.mouseDragStart = none(Vector2)
  return none(tuple[screen_relative: Rectangle, world_relative: Rectangle])



proc get_click_on_the_screen*(game: Game; button: MouseButton): Option[tuple[screen_relative: Vector2, world_relative: Vector2]] =
  if not isMouseButtonPressed(button): return none(tuple[screen_relative: Vector2, world_relative: Vector2])
  return some(( getMousePosition(),
    Vector2(
      x: (getMousePosition().x - game.camera.offset.x) / game.camera.zoom + game.camera.target.x,
      y: (getMousePosition().y - game.camera.offset.y) / game.camera.zoom + game.camera.target.y)))



func world_sanatize_x*(self: Game, x: int): int  
  = (if x < 0: return 0; if x > WORLD_MAX_X: return WORLD_MAX_X; return x)



func world_sanatize_x*(self: Game, x: float): float 
  = return self.world_sanatize_x(x.int).float



func world_sanatize_y*(self: Game, y: int): int 
  = (if y < 0: return 0; if y > WORLD_MAX_Y: return WORLD_MAX_Y; return y)



func world_sanatize_y*(self: Game, y: float): float 
  = return self.world_sanatize_y(y.int).float



func recenter_camera_target_on_map*(self: Game) {.inline.} =
  let padding = 1200.0 
  if self.camera.target.x > WORLD_MAX_X.float + padding: self.camera.target.x = WORLD_MAX_X + padding
  if self.camera.target.y > WORLD_MAX_Y.float + padding: self.camera.target.y = WORLD_MAX_Y + padding
  if self.camera.target.x < - padding: self.camera.target.x = - padding
  if self.camera.target.y < - padding: self.camera.target.y = - padding
