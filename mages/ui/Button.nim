import raylib

proc Button*(
  text: string,
  pos: Vector2,
  width: float,
  height: float,
): bool =

  let is_hovered = checkCollisionPointRec(
    getMousePosition(),
    Rectangle(x: pos.x,y: pos.y,width: width,height: height))

  let rect_color = if is_hovered: DARKGRAY else: GRAY
  let text_color = if is_hovered: LIGHTGRAY else: WHITE

  draw_rectangle(pos,raylib.Vector2(x: width,y: height),rect_color)

  let witdh_text = measureText(text, 20).float
  let text_pos = Vector2(x: pos.x + (width - witdh_text) / 2,y: pos.y + (height - 20) / 2)
  draw_text(text, text_pos.x.int32, text_pos.y.int32, 20, text_color)

  return is_hovered and isMouseButtonPressed(MouseButton.Left)