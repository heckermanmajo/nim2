# menu_types.nim
type Menu* = ref object

var p_menu = Menu()
proc menu*(): var Menu {.inline.} = p_menu
proc init*(me: Menu) = discard