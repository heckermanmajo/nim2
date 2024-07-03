import raylib
import strutils

const screenWidth = 800
const screenHeight = 600

# Initialize text buffer
var textBuffer: string = ""
var isActive = true

# Initialize Raylib
initWindow(screenWidth, screenHeight, "Simple Text Editor")
setTargetFPS(60)

while not windowShouldClose():
  beginDrawing()
  clearBackground(RAYWHITE)

  if isActive:
    # Handle key input
    let key = getKeyPressed()
    if key != KeyboardKey.Null:
      if key == KeyboardKey.BackSpace:
        if textBuffer.len > 0:
          textBuffer.setLen(textBuffer.len - 1)
      elif key == KeyboardKey.Enter:
        textBuffer.add("\n")
      elif key.int >= 32 and key.int <= 126:  # Printable characters
        textBuffer.add(char(key))

  # Draw text
  drawText(textBuffer, 10, 10, 20, BLACK)
  drawText("Press ESC to exit, click to toggle text input.", 10, screenHeight - 20, 20, DARKGRAY)

  # Toggle text input
  if isMouseButtonPressed(MouseButton.Left):
    isActive = not isActive

  endDrawing()

closeWindow()
