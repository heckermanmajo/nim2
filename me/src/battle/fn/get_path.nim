# Pathfinding -> astar lib usage
# todo; we can mostly use straight lines, chunk based approximations, etc.
# todo; apply astar on chunks and then within the chunk

import ../battle_types
import ../methods/btile_methods
import ../methods/battle_methods
import ../../lib/astar


#proc get_path_finding_path*(me: Battle, start: Vector2, goal: Vector2): seq[] = 





type BattleGrid = seq[seq[BTile]]

template yieldIfExists( grid: BattleGrid, point: GridPoint ) =
  let exists = point.y >= 0 and point.y < grid.len and point.x >= 0 and point.x < grid[point.y].len
  if exists: yield point

iterator neighbors*( grid: BattleGrid, point: GridPoint ): GridPoint =
  yieldIfExists( grid, (x: point.x - 1, y: point.y) )
  yieldIfExists( grid, (x: point.x + 1, y: point.y) )
  yieldIfExists( grid, (x: point.x, y: point.y - 1) )
  yieldIfExists( grid, (x: point.x, y: point.y + 1) )

proc cost*(grid: BattleGrid, a, b: GridPoint): float = grid[a.y][a.x].get_movment_cost()
proc heuristic*( grid: BattleGrid, node, goal: GridPoint ): float = asTheCrowFlies(node, goal)

when false:
  let battle_grid = battle().tile_as_grid
  let battle_start: GridPoint = (x: 0, y: 3)
  let battle_goal: GridPoint = (x: 4, y: 3)

  # Pass in the start and end points and iterate over the results.
  for point in path[BattleGrid, GridPoint, float](battle_grid, battle_start, battle_goal):
    echo point

proc get_path*(me: Battle, start: BTile, goal: BTile): seq[BTile] = 
  var l = newSeq[BTile]()
  for point in path[BattleGrid, GridPoint, float](me.tile_as_grid, start.num_pos, goal.num_pos):
    l.add(get_tile_from_pos(me, point))
