import std/options

import raylib

import Chunk
import BattleFaction
import UnitType
import ControlGroup

type 
  
  UnitBehaviourMode* = enum
    Idle
    MovingToChunk
    Fighting
    MovingToEnemyUnit

  Unit* = ref object
    dead: bool                  ## this marks the unit a dead; Dead units can be re-used
    type_data: UnitType         ## Reference to the type
    shape: Rectangle            ## the position AND size of the unit
    rotation: float             ## no use yet ...
    collision_velocity: Vector2 ## used to carry over collision into movement
    attack_target: Option[Unit] 
    move_target: Option[Vector2]
    chunk_i_am_on: Chunk        ## this need to be set all the time; the chunk this unit is on
    behavior_mode: UnitBehaviourMode
    my_control_group: ControlGroup
    last_push: float
    next_collsion_check: float
    next_think: float
    last_attack: float  ## seconds since last attack 
    hp: float  