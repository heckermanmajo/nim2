import raylib

import ../battle_types
import ../methods/battle_methods

proc move_battle_cam*(me: Battle,dt: float) =

  block move_camera_with_wasd_block:
    let speed = me.zoom_factor * me.wasd_move_speed * dt
    if isKeyDown(KeyboardKey.D): me.camera.target.x += speed
    if isKeyDown(KeyboardKey.A): me.camera.target.x -= speed
    if isKeyDown(KeyboardKey.W): me.camera.target.y -= speed
    if isKeyDown(KeyboardKey.S): me.camera.target.y += speed
  

  block move_world_with_mouse_middle_drag:
    if isMouseButtonDown(MouseButton.Middle):
      let mouseDelta = getMouseDelta()
      me.camera.target.x += 
        mouseDelta.x * dt * me.mouse_middle_drag_speed * me.camera.zoom 
      me.camera.target.y += 
        mouseDelta.y * dt * me.mouse_middle_drag_speed + me.camera.zoom
      
      let padding = 1200.0 
      if me.camera.target.x < - padding: me.camera.target.x = - padding
      if me.camera.target.y < - padding: me.camera.target.y = - padding


  block zoom_in_zoom_out_block: 
    let MIN_ZOOM = 0.3
    let MAX_ZOOM = 4.0
    let moved = getMouseWheelMove()
    if moved != 0:
      let zoom_delta = moved * 0.2
      let old_zoom = me.camera.zoom
      me.camera.zoom += zoom_delta
      if me.camera.zoom < MIN_ZOOM: me.camera.zoom = MIN_ZOOM
      if me.camera.zoom > MAX_ZOOM: me.camera.zoom = MAX_ZOOM
      let new_zoom = me.camera.zoom
      # Adjust the camera target to keep the center position the same
      let screen_center = Vector2(
        x: getScreenWidth().float / 2.0,
        y: getScreenHeight().float / 2.0)
      let world_center_before = Vector2(
        x: (screen_center.x - me.camera.offset.x) / old_zoom + me.camera.target.x,
        y: (screen_center.y - me.camera.offset.y) / old_zoom + me.camera.target.y)
      let world_center_after = Vector2(
        x: (screen_center.x - me.camera.offset.x) / new_zoom + me.camera.target.x,
        y: (screen_center.y - me.camera.offset.y) / new_zoom + me.camera.target.y)
      me.camera.target.x -= world_center_after.x - world_center_before.x
      me.camera.target.y -= world_center_after.y - world_center_before.y

      # The zoom factor allows us to change the way to display the game 
      # based on how far we have zoomed out
      me.zoom_factor = case (me.camera.zoom * 10).int:
        of 0..2:   me.zoom_level = ZoomLevel.Mini;      16f
        of 3..4:   me.zoom_level = ZoomLevel.VerySmall; 16f
        of 5..9:   me.zoom_level = ZoomLevel.Small;     8f
        of 10:     me.zoom_level = ZoomLevel.Default;   4f
        of 11..19: me.zoom_level = ZoomLevel.Big;       2f
        of 20..40: me.zoom_level = ZoomLevel.Big;       0.5
        else:      me.zoom_level = ZoomLevel.Big;       0.1

  block recenter_camera_target_on_map:   
    let padding = 400.0 
    let WORLD_MAX = me.world_size_in_pixel_f()
    let zoom = me.camera.zoom
    if me.camera.target.x > WORLD_MAX - getScreenWidth().float / zoom + padding: 
      me.camera.target.x = WORLD_MAX - getScreenWidth().float / zoom + padding
    if me.camera.target.y > WORLD_MAX - getScreenHeight().float / zoom + padding: 
      me.camera.target.y = WORLD_MAX - getScreenHeight().float / zoom + padding
    if me.camera.target.x < - padding: me.camera.target.x = - padding
    if me.camera.target.y < - padding: me.camera.target.y = - padding      