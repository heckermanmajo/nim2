import CONFIG
import battle_types
import camp_types
import menu_types

# engine_types.nim
type 
  
  EngineMode* = enum 
    EM_Menu 
    EM_Camp
    EM_Battle

  Engine* = ref object
    mode*: EngineMode
    file: File

proc construct_engine(): Engine = 
  return Engine(
    mode: EM_Battle,
    file: open("logging.txt", fmWrite)
  )    
# this functions needs to be defined in another file than the engine 
# type, so we dont have circular imports
# this this function we allow methods to get access to engine

var p_engine = construct_engine()

proc load_all_extern_media*(me: Engine) = discard

proc engine*(): Engine  {.inline.} = p_engine   

proc close*(me: Engine) = 
   me.file.close()

template log*(s: string) = 
  when CONFIG.DEBUG:
    p_engine.file.write(s & "\n")

