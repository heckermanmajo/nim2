import std/options

import raylib

func collision*(r1, r2: Rectangle): bool =
  return not ((r1.x + r1.width < r2.x) or (r2.x + r2.width < r1.x) or
             (r1.y + r1.height < r2.y) or (r2.y + r2.height < r1.y))

func collision*(p: Vector2, r: Rectangle): bool =
  return (p.x >= r.x) and (p.x <= r.x + r.width) and (p.y >= r.y) and (p.y <= r.y + r.height)

func get_overlap*(r1, r2: Rectangle): Option[Vector2] =
  if not collision(r1, r2): return none(Vector2)
  else:
    var xOverlap = min(r1.x + r1.width, r2.x + r2.width) - max(r1.x, r2.x)
    var yOverlap = min(r1.y + r1.height, r2.y + r2.height) - max(r1.y, r2.y)
    return some(Vector2(x: xOverlap, y: yOverlap))

