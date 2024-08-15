import os
import std/options

import raylib

import ../CONFIG

import ../battle/battle_types
import ../camp/camp_types
import ../menu/menu_types

# engine_types.nim
type 
  
  EngineMode* = enum 
    EM_Menu 
    EM_Camp
    EM_Battle

  Engine* = ref object
    mode*: EngineMode
    file: File
    atlas1*: Option[Texture]
    building_atlas*: Option[Texture]

proc construct_engine(): Engine = 
  return Engine(
    mode: EM_Battle,
    file: open("logging.txt", fmWrite)
  )    
# this functions needs to be defined in another file than the engine 
# type, so we dont have circular imports
# this this function we allow methods to get access to engine

var p_engine = construct_engine()

proc load_all_extern_media*(me: Engine) = 
  if fileExists("img/img.png"):me.atlas1 = loadTexture("img/img.png").some
  else: echo "did not find img/img.png"
  if fileExists("img/b1.png"): me.building_atlas = loadTexture("img/b1.png").some
  else: echo "did not find img/b1.png"

proc clear_raylib_resources_to_prevent_segvault*(me: Engine) = 
  me.atlas1 = none(Texture)
  me.building_atlas = none(Texture)

proc engine*(): Engine  {.inline.} = p_engine   

proc close*(me: Engine) = 
   me.file.close()

const GRAS_QUAD* = Rectangle(x: 32, y: (32*11).float, width:32,height:32)

const B_WALL_QUAD* = Rectangle(x: 127, y:96,  width:32,height:32)

proc draw_gras*(me: Engine, pos: Vector2) = 
  drawTexture(me.atlas1.get,GRAS_QUAD, pos, WHITE)

proc draw_wall*(me: Engine, pos: Vector2) = 
  drawTexture(me.building_atlas.get,B_WALL_QUAD, pos, WHITE)

template log*(s: string) = 
  when CONFIG.DEBUG:
    p_engine.file.write(s & "\n")

