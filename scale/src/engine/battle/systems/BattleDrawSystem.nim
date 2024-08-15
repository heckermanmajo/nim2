import raylib

import ../../Engine
import ../Battle


proc BattleDrawSystem*(battle: Battle) = 
  let e = get_engine()
  clearBackground(BLACK)

  beginMode2D(battle.camera)