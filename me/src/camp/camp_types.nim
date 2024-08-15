# camp_types.nim
type 
  CFaction* = ref object
  Army* = ref object
    tech_level: int
    movment: int
  CTile* = ref object
  CSaveFile* = ref object
  Camp* = ref object

var p_camp = Camp()
proc camp*(): var Camp  {.inline.}  = p_camp
proc init*(me: Camp) = discard