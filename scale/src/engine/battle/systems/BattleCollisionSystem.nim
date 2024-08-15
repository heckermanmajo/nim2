import ../../Engine
import ../Battle


# template name(arguments): return type =
  

proc BattleCollisionSystem*(battle: Battle) = 
  let e = get_engine()

  # do the collision stuff here ... 
  for_all_units_in battle: 
    echo "lo"
