import std/options

import raylib
import raymath

import types
import std/math
import std/tables

import config

proc get_chunk_by_xy_optional*(self: Battle; x, y: int): Option[Chunk] =
  
  ## Get the chunk by given x and y, can be out of world; if so: returns option

  let index_x = floor(x / CHUNK_SIZE_IN_PIXEL).int
  let index_y = floor(y / CHUNK_SIZE_IN_PIXEL).int
  if not self.chunks_on_xy.hasKey(index_x): return none(Chunk)
  if not self.chunks_on_xy[index_x].hasKey(index_y): return none(Chunk)
  return some(self.chunks_on_xy[index_x][index_y])



proc get_chunk_by_xy*(self: Battle; x, y: int ): Chunk =
  
  ## Get the chunk by given x and y, cant be out of world; if so: crashes

  let index_x = floor(x / CHUNK_SIZE_IN_PIXEL).int
  let index_y = floor(y / CHUNK_SIZE_IN_PIXEL).int
  when(config.DEBUG):
    if not self.chunks_on_xy.hasKey(index_x):
      raise Defect.newException(
        "Cannot get chunk (x not found): bad params or bad state." &
        $x & " - " & $y)
    if not self.chunks_on_xy[index_x].hasKey(index_y):
      raise Defect.newException(
        "Cannot get chunk (y not found): bad params or bad state." &
        $x & " - " & $y)
  return self.chunks_on_xy[index_x][index_y]



proc get_chunk_by_xy*(self: Battle; x, y: float ): Chunk =

  ## Get the chunk by given x and y, cant be out of world; if so: crashes
  
  return self.get_chunk_by_xy(x.int, y.int)



proc get_chunk_by_xy*(self: Battle; pos: Vector2 ): Chunk =
  return self.get_chunk_by_xy(pos.x.int, pos.y.int)



proc get_chunk_by_xy*(self: Battle; pos: Rectangle ): Chunk =
  return self.get_chunk_by_xy(pos.x.int, pos.y.int)



proc get_chunks_around_chunk(
  self: Battle, x, y: int, also_diagonal: bool = false): seq[Chunk] {.inline.} =

  ## This function returns a list of all neighbour chunks
  
  var chunks = newSeq[Chunk]()
  let c1 = self.get_chunk_by_xy_optional(x - CHUNK_SIZE_IN_PIXEL, y )
  if c1.isSome: chunks.add(c1.get)
  let c2 = self.get_chunk_by_xy_optional(x + CHUNK_SIZE_IN_PIXEL, y )
  if c2.isSome: chunks.add(c2.get)
  let c3 = self.get_chunk_by_xy_optional(x , y + CHUNK_SIZE_IN_PIXEL )
  if c3.isSome: chunks.add(c3.get)
  let c4 = self.get_chunk_by_xy_optional(x , y - CHUNK_SIZE_IN_PIXEL )
  if c4.isSome: chunks.add(c4.get)
  if also_diagonal:
    let c5 = self.get_chunk_by_xy_optional(
      x = x - CHUNK_SIZE_IN_PIXEL, 
      y = y - CHUNK_SIZE_IN_PIXEL)
    if c5.isSome: chunks.add(c5.get)
    let c6 = self.get_chunk_by_xy_optional(
      x = x + CHUNK_SIZE_IN_PIXEL, 
      y = y - CHUNK_SIZE_IN_PIXEL)
    if c6.isSome: chunks.add(c6.get)
    let c7 = self.get_chunk_by_xy_optional(
      x = x + CHUNK_SIZE_IN_PIXEL, 
      y = y + CHUNK_SIZE_IN_PIXEL )
    if c7.isSome: chunks.add(c7.get)
    let c8 = self.get_chunk_by_xy_optional(
      x = x - CHUNK_SIZE_IN_PIXEL, 
      y = y + CHUNK_SIZE_IN_PIXEL )
    if c8.isSome: chunks.add(c8.get)
  return chunks



proc get_chunks_around_chunk*(
  self: Battle, projectile: Projectile, also_diagonal: bool = false
  ): seq[Chunk] {.inline.} =

  ## This function returns a list of all neighbour chunks

  return self.get_chunks_around_chunk(
    projectile.shape.x.int, projectile.shape.y.int, also_diagonal)



proc get_chunks_around_chunk*(
  self: Battle, unit: Unit, also_diagonal: bool = false
  ): seq[Chunk]  {.inline.} =

  ## This function returns a list of all neighbour chunks
  
  return self.get_chunks_around_chunk(
    unit.shape.x.int, unit.shape.y.int, also_diagonal)



proc get_chunks_around_chunk*(
  self: Battle, chunk: Chunk, also_diagonal: bool = false
  ): seq[Chunk]  {.inline.} =

  ## This function returns a list of all neighbour chunks

  return self.get_chunks_around_chunk(chunk.x, chunk.y, also_diagonal)



proc rotatePoint(point: var Vector2, center: Vector2, angle: float) {.inline.} =
  let s = sin(angle)
  let c = cos(angle)
  let px = point.x - center.x
  let py = point.y - center.y
  point.x = px * c - py * s + center.x
  point.y = px * s + py * c + center.y



proc get_raster_by_center_and_rotation*(
  center: Vector2, rotation: float, size_of_circle:float, numbers:int 
  ): seq[Vector2] = 

  ## This is a fucntion to get a list of positions ordered in a square 
  ## around the center, also takng a rotation into account for the alignment
  ## 
  ## numbers = 4 ->
  ## 3x3
  ## O O O
  ## O O O
  ## O O O
  ## 
  ## after this shape os created apply rotation to all at once, as if they were 
  ## one element
  var points: seq[Vector2] = @[]
  let halfGrid = (numbers - 1) / 2
  let step = size_of_circle * 2# / numbers.float

  for i in 0..<numbers:
    for j in 0..<numbers:
      let x = center.x + (i.float - halfGrid) * step
      let y = center.y + (j.float - halfGrid) * step
      var p = Vector2(x: x, y: y)
      p.rotatePoint(center=center, angle=rotation)
      points.add(p)

  return points



proc create_all_unit_positions_for_chunks*(self: Battle) = 
  for c in self.chunks:
    let half = CHUNK_SIZE_IN_PIXEL / 2
    let size = CHUNK_SIZE_IN_PIXEL.float
    let center = Vector2(
      x: c.x.float * size + half,
      y: c.y.float * size + half)
    c.unit_idle_positions = get_raster_by_center_and_rotation(
        center          = center, 
        rotation        = 0, 
        size_of_circle  = 20, 
        numbers         = 6)
