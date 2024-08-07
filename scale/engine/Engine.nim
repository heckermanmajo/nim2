import Core
import battle/Battle

type 
    
  Engine* = ref object
    battle*: Battle
    mode*: EngineMode

  EngineMode* = enum
    Menu
    Battle
    Camp

var e = Engine(battle: newBattle())

proc get_engine*(): Engine = e