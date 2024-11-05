##[[nimble install naylib && nim compile main.nim && ./main 

DONT PUBLISH A BETA: PUBLSIH AN ALPHA and then a SIGMA.

Can we keep the game under 5000 lines to release? - cloc-lines

USE CIRCLE-COLLISIONS FOR UNITS instead of rectangles
-> this way we dont need even tiles ...
-> using chunks for collision is enough

We need to make the engine-part solid and nice before we meddl with features
this means:
  - unit chunk tracking
  - unit tile tracking
  - debug view into the unit on click
  - debug view into chunks on click
  - debug view into tiles on click 
  - comments and cleanup + read marker
  - put clear todos into the code

- CONCEPT-CONTROLS: HOW TO MAKE CONTROLS SUPERB???
  - intuitive controls + Very nice battle-feeling

CONCEPT: HOW TO MAKE GAMEPLAY FEEL RIGHT?
  - Units need to behave (a bit more) like real units 
  - Tanks need to be more effect-ful ... 
  - better shooting Mechanis: taking Cover need to make sense
    - for this we need to track all the stuff on tiles 
      each tile a shot "visits" has a chance of blocking the shot
  - move units in battle out of battle (Fallback-Button)
  - select more "sensible" target: Tank for anit tank, except i am getting shot at, etc.
  - better tile-management, allows for smarted formation
  - also auto-go towards cover (use tanks etc. as cover)
  - SCALE UP TANKS 1.5x? 1.3x? 1.7x? -> Tanks need to be bigger to feel right
  - add simple objects to map for cover (trees, sandbags, etc.)
  - jeeps are to fast
  - smaller unit-spawn-batches (maybe all vehicles should be spawned for themself...)
    Spawning to much at once makes the gameplay to "just throw all units at the enemy"
  - we want to use units to their strenght  and build up for battles
  - we need slow moving projectiles for mortars and artillery, and granates (maybe a granate lanucher-soldier?)
  - replace support soldier with launcher soldier
  - replace support soldier role with support vehicle role

Question:
 - how to make the map work?
 - some spots give boni, so you want to hold them
 - some make units cheaper
 - some deliver units to the battlefield for free
 - some increase the recruitment speed
 - some offer out of map artillery/tactical nuke support  

-> display all infos about the selected unit
-> display all selcted units with icons
-> add unit description

- SPAWN-QUEUE
  - add simple ui with buttons to spawn units and to show the current command points
  - ai: spawn units: add spawn-qeue

- cleanup, comment and strcuture the code

- debug battles

- remove shot-lines; add fire on mussle of gun

- add real camapign-battle-flow

- let the ai spawn units -> need money for that

- add gore if you kill a full transport

- RE-LOAD UNits in the vicinity into transports via "L" - key
   - all units in 300 pixel radius are loaded into the transport until is full

- double click on unit to select all units of the same type in the current view

- Zoomlevel
  - move faster ober the map, based on the zoomlevel

- command points: spawn units based on command points of faction
- end battle-condition
- ownership of chunks; display at a certain zoom-level; track on what chunk a unit is
- render all units and vehicles as dots and rects at a certain zoom-level
- add explosions and hit markers(smoke, etc.)
- add crators
- add dead soldiers(based on what weapon killed them)
- add fire for destroyed vehicles
- fog of war

Perforamnce:
- only draw what is in the view
- only collide with units in same chunk: Chunk tracking...

GAME-DESIGN:
- The campaign map needs to be simple:
  - movement: conquer, attack, merge
  - distance to logistics-tile determines costs of command points

- you deploy small troops in battle
- Some chunks in battle have a special effect (lower costs, faster deployment)

]]##

import std/[sequtils,tables, math, random, strutils,tables, hashes,options,oids,os,files,deques]
import raylib
import raymath

var click_cooldown: float = 0
proc update_button_cooldown(dt: float) = click_cooldown = click_cooldown - dt
proc Button(text: string,pos: Vector2,width: float,height: float,): bool =
  let is_hovered = checkCollisionPointRec(getMousePosition(),Rectangle(x: pos.x,y: pos.y,width: width,height: height))
  let rect_color = if is_hovered: DARKGRAY else: GRAY
  let text_color = if is_hovered: LIGHTGRAY else: WHITE
  draw_rectangle(pos,raylib.Vector2(x: width,y: height),rect_color)
  let witdh_text = measureText(text, 20).float
  let text_pos = Vector2(x: pos.x + (width - witdh_text) / 2,y: pos.y + (height - 20) / 2)
  draw_text(text, text_pos.x.int32, text_pos.y.int32, 20, text_color)
  let clicked = is_hovered and isMouseButtonPressed(MouseButton.Left) and click_cooldown < 0
  if clicked: click_cooldown = 0.2
  return clicked

const TileSizePixel = 124;
const WorldWidth_in_tiles = 20; const WorldHeight_in_tiles = 20
const WorldWidth_in_pixels = WorldWidth_in_tiles * TileSizePixel; const WorldHeight_in_pixels = WorldHeight_in_tiles * TileSizePixel
const CHUNK_SIZE_IN_TILES = 10
const TILE_SIZE = 64
const CHUNK_SIZE_IN_PIXELS = CHUNK_SIZE_IN_TILES * TILE_SIZE
const WORLD_IN_CHUNKS = 10

#region type-definitions
type

  FactionRelationState = enum Peace, Alliance, War
    ## Factions are related to each other. The relation has always a state.

  FactionRelationEvent = ref object
    ## different events on the campaign map can change the relation between
    ## factions. Each such event cretaes an faction relation event.
    ## The effect of the event deminishes over time.
    ## After a certain amount of turns the event is deleted.
    ## The current relation is calculated by the sum of all events between two
    ## factions.
    faction_one: int
    faction_two: int
    relation_change: int
    description: string
    deleted_in_turns: int

  Faction = ref object
    ## This represents a faction on the campaign map.
    is_player_faction: bool
    name: string
    description: string
    defeated: bool
    index: int ##\
      ## Index in the list of factions within the scenario.
      ## If a faction dies it is set to defeated, but it still continues to exist.
      ## So factions are never deleted from memory or from the save files !!!
      ## Ids are persistent.
    color: Color
    money: int
    units: Table[int, seq[Unit]]

  Scenario = ref object
    ## You can load a scenario as part of a campaign, but you can also
    ## create one on the fly in the scenario editor.
    ## Scenario is a game, that you can also save and load.
    ## it contains only the campaign map data, since all rts battles are
    ## created on demand.
    name: string
    description: string
    factions: seq[Faction]
    factions_on_map: Table[string, Faction]
    tiles_map: Table[int, Table[int,Tile]]
    tiles: seq[Tile]
    turn: int
    factions_relations
      : Table[int, tuple[faction_index: int, relation_state: FactionRelationState]]
    faction_relation_events: seq[FactionRelationEvent]

  GameMode = enum Menu, Camp, Battle ## Battle not yet implemented

  CampDisplayMode = enum Default, Diplomacy

  ZoomLevel = enum Mini, VerySmall, Small, Default, Big
    ## Zoomlevel of the campaign map; The zoom changes the way of displaying
    ## the map and the armies on the map.

  Game = ref object
    ## The global state of the game and its "engine"- Contains also all the state
    ## that is not saved into save file.
    mode: GameMode
    display_mode: CampDisplayMode
    selected_tile: Option[Tile]
    scenario: Scenario
    zoom_level: ZoomLevel
    ai_army_movement_tasks: Deque[ArmyMovementTask]
    player_movement_task: Option[ArmyMovementTask]
    current_battle: Option[BattleData]
    battle_graphics: Table[string, tuple[x: int, y: int, w: int, h:int, atlas: string]]
    atlases: Table[string, Texture]
    sounds: Table[string, Sound]

  #region Battle-TYPES
  #################################################################
  # Battle Types
  #################################################################
  BattleObjectType = enum Sandbad, Wall, Tree
  BattleObject = ref object # passive objects: can block projectiles, offer other boni, or hurt like barbed wire
    object_type: string
    pos: Vector2
    waypoints_around_me: tuple[a: Vector2, b: Vector2,c: Vector2, d: Vector2]
  BattleSprite = ref object #  holes of exploisions, blood stains, etc. Stuff that does NOT interact with logic
    sprite_name: string
    rotation: float
    pos: Vector2
    is_vehicle: bool
  ExplosionType = enum Default  
  ExplosionSize = enum Femto, Mini, Small, Medium, Large 
  BattleExplosion = ref object
    explosion_type: ExplosionType 
    pos: Vector2
    size: ExplosionSize
    active_since: float
  BattleParticle = ref object # fire, vehicle-parts, body-parts, dead bodies, etc.; passive stuff that interacts only on the visual side
  UnitCategory = enum Soldier, Pioneer, LightVehicle, MediumVehicle, LightTank, MediumTank, Tank, SlowGun 
  UnitSpeedLevel = enum Slow, Normal, Fast, VeryFast  
  WeaponRange = enum SuperShort, Short, Medium, Long, VeryLong, CrazyLong
  Unit = ref object
    pos: Vector2
    target_unit: Option[Unit]
    move_target: Option[Vector2]
    move_waypoint_list: seq[Vector2] # if a unit encounters an bostacle on the way, it gets waypoints to walk around it; the wayints are in the object
    health: int
    is_soldier: bool
    in_vehicle: bool
    target_chunk: BattleChunk #  the chunk this unit wants to hold
    team: int
    rotation: float
    needed_rotation: float
    rotation_speed_per_second: float
    speed: UnitSpeedLevel
    weapon_range: WeaponRange
    weapon_system: BulletSize
    explosion_radius: int    
    logical_width: float
    logical_height: float
    shoot_cooldown: float
    shoots_per_minute: int
    look_around_check_in: float
    texture_name: string
    texture_w: float
    texture_h: float
    capacity_for_soldiers: int
    cannot_be_hit_by: seq[BulletSize]
    units_on_board: seq[Unit]
    can_fight: bool
    max_health: int
    logical_radius: float
    target_rotation: Option[float]
  CommandGroup = ref object
    units: seq[Unit]  
  BattleTile = ref object
    pos: Vector2
    units: seq[Unit]
    battle_object: Option[BattleObject] 
  BattleChunk = ref object
    pos: Vector2
    units_on_chunk: seq[Unit]
    tiles: seq[BattleTile]
    battle_objects: seq[BattleObject]
    owner: int
  BulletSize = enum Rifle, HeavyRifle, Bazooka, LightTank, 
    MediumTank, HeavyTank, Mortar, Artillery, AntiTankGun
  Shot = ref object 
    start: Vector2
    target: Vector2
    thickness: float
    explosion_radius: int
    damage: int
    bullet_size: BulletSize
    duration: float  
    distance_in_pixel: float
  BattleDisplayMode = enum Tactic, Strategic,     
  BattleData = ref object
    chunks: seq[BattleChunk]
    units: seq[Unit]
    camera: Camera2D
    shots: seq[Shot]
    command_groups: seq[CommandGroup]
    currently_selected_units: seq[Unit]
    currently_selected_command_groups: seq[CommandGroup]
    display_mode: BattleDisplayMode
    display_hire_overlay: bool 
    battlefield_width: int
    battlefield_height: int 
    chunk_size_in_tiles: int
    selected_unit: Option[Unit]
    selected_chunk: Option[BattleChunk]
    sprites: seq[BattleSprite]
    explosions: seq[BattleExplosion]
  ##################################################################

  TileType = enum Land, Water, Mountain, Minerals

  Tile = ref object
    ## One tile on the campaign map.
    pos: Vector2
    category: TileType
    owner: Option[Faction]
    army: Option[Army]
    faction: Option[Faction]

  Army = ref object
    ## An army on the campaign map.
    faction: Faction
    tile_i_am_on: Tile
    command_points: int
    level: int
    last_moved_at_turn: int

  ArmyMovementTask = ref object
    ## A task for an army to move to a target tile.
    ## This is needed, since we need to decouple a decision for movement from
    ## the actual execution of the movement, so we can wait between ai movements.
    army: Army
    target_tile: Tile

  Logger = ref object
    ## Logging object provided to functions that need to log.
    file: File

proc draw_from_atlas(src: (int,int,int,int, string), game: Game,  x: float, y: float, width: float = 0, height: float = 0, rotation: float = 0) =
  let source_x = src[0].float; let source_y = src[1].float
  let source_w = src[2].float; let source_h = src[3].float
  let source_rect = Rectangle(x: source_x, y: source_y, width: source_w, height: source_h)
  let dest_rect = Rectangle(x: x, y: y, width: (if width == 0: source_w else: width), height: (if height == 0: source_h else: height))
  let origin = Vector2(x: width/2, y: height/2)
  drawTexture(game.atlases[src[4]], source_rect, dest_rect, origin, rotation, WHITE)    

#region UNIT-DEFINTIONS

proc init_unit_in_world(g: Game, unit: Unit) = 
  g.current_battle.get.units.add(unit)

proc create_storm_soldier(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit =
    var unit = Unit()
    unit.pos = Vector2(x: x, y: y)
    unit.health = 250
    unit.max_health = unit.health
    unit.is_soldier = true
    unit.team = team
    unit.speed = UnitSpeedLevel.Slow
    unit.weapon_range = WeaponRange.Short 
    unit.weapon_system = BulletSize.HeavyRifle
    unit.explosion_radius = 0    
    unit.logical_radius = 12
    unit.shoots_per_minute = 120
    unit.texture_name = if team == 1: "storm_soldier_gray" else: "storm_soldier_green"
    unit.texture_w = 64
    unit.texture_h = 64
    unit.capacity_for_soldiers = 0
    unit.cannot_be_hit_by = @[]
    unit.target_chunk = target_chunk
    unit.can_fight = true
    g.init_unit_in_world(unit)
    return unit

proc create_support_soldier(g: Game, x: float, y: float,target_chunk: BattleChunk,  team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 100
  unit.max_health = unit.health
  unit.is_soldier = true
  unit.team = team
  unit.speed = UnitSpeedLevel.Slow
  unit.weapon_range = WeaponRange.SuperShort
  unit.weapon_system = BulletSize.Rifle
  unit.explosion_radius = 0
  unit.logical_radius = 12
  unit.shoots_per_minute = 20
  unit.texture_name = if team == 1: "support_soldier_gray" else: "support_soldier_green"
  unit.texture_w = 64
  unit.texture_h = 64
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc create_rifle_soldier(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int) : Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 150
  unit.max_health = unit.health
  unit.is_soldier = true
  unit.team = team
  unit.speed = UnitSpeedLevel.Slow
  unit.weapon_range = WeaponRange.Short
  unit.weapon_system = BulletSize.Rifle
  unit.explosion_radius = 0
  unit.logical_radius = 12
  unit.shoots_per_minute = 40
  unit.texture_name = if team == 1: "rifle_soldier_gray" else: "rifle_soldier_green"
  unit.texture_w = 64
  unit.texture_h = 64
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[]
  unit.target_chunk = target_chunk  
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc create_bazooka_soldier(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 100
  unit.max_health = unit.health
  unit.is_soldier = true
  unit.team = team
  unit.speed = UnitSpeedLevel.Slow
  unit.weapon_range = WeaponRange.Short
  unit.weapon_system = BulletSize.Bazooka
  unit.explosion_radius = 1
  unit.logical_radius = 12
  unit.shoots_per_minute = 10
  unit.texture_name = if team == 1: "bazooka_soldier_gray" else: "bazooka_soldier_green"
  unit.texture_w = 64
  unit.texture_h = 64
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc create_humvee(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 500
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.VeryFast
  unit.weapon_range = WeaponRange.Short
  unit.weapon_system = BulletSize.Rifle
  unit.explosion_radius = 0
  unit.logical_radius = 40
  unit.shoots_per_minute = 120
  unit.texture_name = if team == 1: "humvee_gray" else: "humvee_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 4
  unit.cannot_be_hit_by = @[]
  unit.units_on_board = @[
    create_rifle_soldier(g, x, y, target_chunk, team),
    create_rifle_soldier(g, x, y, target_chunk, team),
    create_bazooka_soldier(g, x, y, target_chunk, team),
    create_support_soldier(g, x, y, target_chunk, team),
  ]
  for u in unit.units_on_board: u.in_vehicle = true    
  unit.target_chunk = target_chunk
  unit.can_fight = true
  # todo: add units on board
  g.init_unit_in_world(unit)
  return unit

proc create_truck(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 500
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Fast
  unit.weapon_range = WeaponRange.Short
  unit.weapon_system = BulletSize.Rifle
  unit.explosion_radius = 0
  unit.logical_radius = 55
  unit.shoots_per_minute = 0
  unit.texture_name = if team == 1: "truck_gray" else: "truck_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 8
  unit.cannot_be_hit_by = @[]
  unit.units_on_board = @[
    create_rifle_soldier(g, x, y, target_chunk, team),    
    create_rifle_soldier(g, x, y, target_chunk, team),
    create_rifle_soldier(g, x, y, target_chunk, team),    
    create_rifle_soldier(g, x, y, target_chunk, team),
    create_rifle_soldier(g, x, y, target_chunk, team),
    create_bazooka_soldier(g, x, y, target_chunk, team),
    create_support_soldier(g, x, y, target_chunk, team),
    create_support_soldier(g, x, y, target_chunk, team),
  ]
  for u in unit.units_on_board: u.in_vehicle = true  
  unit.target_chunk = target_chunk
  unit.can_fight = false
  # todo: add units on board
  g.init_unit_in_world(unit)
  return unit


proc create_heavy_transport(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit =
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 6000
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Normal
  unit.weapon_range = WeaponRange.Medium
  unit.weapon_system = BulletSize.LightTank
  unit.explosion_radius = 0
  unit.logical_radius = 65
  unit.shoots_per_minute = 20
  unit.texture_name = if team == 1: "heavy_transport_gray" else: "heavy_transport_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 16
  unit.cannot_be_hit_by = @[
    BulletSize.Rifle, BulletSize.HeavyRifle, BulletSize.Mortar, LightTank
  ]
  unit.units_on_board = @[
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),

    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),

    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
    create_storm_soldier(g, x, y, target_chunk, team),
  ]
  for u in unit.units_on_board: u.in_vehicle = true
  unit.target_chunk = target_chunk
  # todo: add units on board
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc create_light_tank(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 1500
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Fast
  unit.weapon_range = WeaponRange.Medium
  unit.weapon_system = BulletSize.LightTank
  unit.explosion_radius = 1
  unit.logical_radius = 34
  unit.shoots_per_minute = 20
  unit.texture_name = if team == 1: "light_tank_gray" else: "light_tank_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[BulletSize.Rifle, BulletSize.HeavyRifle]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc create_medium_tank(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 3000
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Normal
  unit.weapon_range = WeaponRange.Medium
  unit.weapon_system = BulletSize.MediumTank
  unit.explosion_radius = 1
  unit.logical_radius = 40
  unit.shoots_per_minute = 10
  unit.texture_name = if team == 1: "medium_tank_gray" else: "medium_tank_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[BulletSize.Rifle, BulletSize.HeavyRifle]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc create_heavy_tank(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 6000
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Normal
  unit.weapon_range = WeaponRange.Long
  unit.weapon_system = BulletSize.HeavyTank
  unit.explosion_radius = 1
  unit.logical_radius = 60
  unit.shoots_per_minute = 5
  unit.texture_name = if team == 1: "heavy_tank_gray" else: "heavy_tank_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[BulletSize.Rifle, BulletSize.HeavyRifle, BulletSize.LightTank]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc mobile_anti_tank_gun(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 3000
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Slow
  unit.weapon_range = WeaponRange.Medium
  unit.weapon_system = BulletSize.AntiTankGun
  unit.explosion_radius = 1
  unit.logical_radius = 38
  unit.shoots_per_minute = 15
  unit.texture_name = if team == 1: "anti_tank_gun_gray" else: "anti_tank_gun_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[BulletSize.Rifle, BulletSize.HeavyRifle, BulletSize.LightTank]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit


proc mobile_mortar(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 500
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Slow
  unit.weapon_range = WeaponRange.VeryLong
  unit.weapon_system = BulletSize.Mortar
  unit.explosion_radius = 1
  unit.logical_radius = 40
  unit.shoots_per_minute = 5
  unit.texture_name = if team == 1: "mortar_gray" else: "mortar_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc mobile_artillery(g: Game, x: float, y: float, target_chunk: BattleChunk, team: int): Unit = 
  var unit = Unit()
  unit.pos = Vector2(x: x, y: y)
  unit.health = 1000
  unit.max_health = unit.health
  unit.is_soldier = false
  unit.team = team
  unit.speed = UnitSpeedLevel.Slow
  unit.weapon_range = WeaponRange.CrazyLong
  unit.weapon_system = BulletSize.Artillery
  unit.explosion_radius = 1
  unit.logical_radius = 50
  unit.shoots_per_minute = 5
  unit.texture_name = if team == 1: "artillery_gray" else: "artillery_green"
  unit.texture_w = 256
  unit.texture_h = 256
  unit.capacity_for_soldiers = 0
  unit.cannot_be_hit_by = @[]
  unit.target_chunk = target_chunk
  unit.can_fight = true
  g.init_unit_in_world(unit)
  return unit

proc can_afford(g: Game, cost: int): bool = g.scenario.factions[0].money >= cost
proc apply_cost(g: Game, cost: int): void = g.scenario.factions[0].money -= cost

# we can spawn 4 types of platoons: scout, control, attack, defense  
proc spawn_scout_platoon(g: Game, target_chunk: BattleChunk, origin_chunk: BattleChunk, team: int) = 
  # 4 humvees, cost 10
  discard create_humvee( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_humvee( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_humvee( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_humvee( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)

proc spawn_map_control_platoon(g: Game, target_chunk: BattleChunk, origin_chunk: BattleChunk, team: int) = 
  # 1 light tank, two(3?) trucks; cost 10
  discard create_light_tank( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_light_tank( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_light_tank( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_truck( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_truck( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_truck( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)

proc spawn_attack_platoon(g: Game, target_chunk: BattleChunk, origin_chunk: BattleChunk, team: int) = 
  # 2 medium tanks, 1 heavy tank, 1 heavy transport; cost 50
  discard create_medium_tank( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_medium_tank( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_heavy_tank( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard create_heavy_transport( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)

proc spawn_defense_platoon(g: Game, target_chunk: BattleChunk, origin_chunk: BattleChunk, team: int) = 
  # 2 anti tank gun, 1 mortar, 1 artillery, rifleman and support-soldiers; cost 35
  discard mobile_anti_tank_gun( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard mobile_anti_tank_gun( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard mobile_mortar( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard mobile_mortar( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)
  discard mobile_artillery( g, rand(origin_chunk.pos.x..origin_chunk.pos.x + CHUNK_SIZE_IN_PIXELS ), rand(origin_chunk.pos.y..origin_chunk.pos.y + CHUNK_SIZE_IN_PIXELS ), target_chunk, team)

#region B- FUNCTIONS

proc unload_units_from_vehicle(g: Game, vehicle: Unit) = 
  for u in vehicle.units_on_board:
    u.pos = Vector2(x: vehicle.pos.x + rand(-50..50).float, y: vehicle.pos.y + rand(-50..50).float)
    u.in_vehicle = false
  vehicle.units_on_board = @[]

proc get_range_in_pixels(range: WeaponRange): float = 
  return case range
    of WeaponRange.SuperShort: 350
    of WeaponRange.Short: 512
    of WeaponRange.Medium: 900
    of WeaponRange.Long: 1300
    of WeaponRange.VeryLong: 1500
    of WeaponRange.CrazyLong: 2300

proc get_damage_in_pixels(damage: BulletSize): int = 
  return case damage
    of BulletSize.Rifle: 10
    of BulletSize.HeavyRifle: 20
    of BulletSize.Bazooka: 50
    of BulletSize.LightTank: 100
    of BulletSize.MediumTank: 200
    of BulletSize.HeavyTank: 400
    of BulletSize.Mortar: 100
    of BulletSize.Artillery: 400
    of BulletSize.AntiTankGun: 200 

proc get_speed_in_pixels(speed: UnitSpeedLevel): float = 
  return case speed
    of UnitSpeedLevel.Slow: 15
    of UnitSpeedLevel.Normal: 45
    of UnitSpeedLevel.Fast: 70
    of UnitSpeedLevel.VeryFast: 115       

proc get_start_chunk_of_player(g: Game): BattleChunk = return g.current_battle.get.chunks[0]
proc get_start_chunk_of_ai(g: Game): BattleChunk = return g.current_battle.get.chunks[g.current_battle.get.chunks.len-1]

proc check_collision(unit: Unit, target: Unit): bool = 
  return checkCollisionRecs(
    Rectangle(x: unit.pos.x-32.0, y: unit.pos.y-32.0, width: 64, height: 64),
    Rectangle(x: target.pos.x-32.0, y: target.pos.y-32.0, width: 64, height:64))

proc apply_battle_outcome(g:var Game #[more args here that describe the battle outcome]#) =
  # couns all the existing units
  g.mode = GameMode.Camp

proc unit_die_and_remove(self: var Unit, battle: var BattleData) = 
  let index = battle.units.find(self)
  battle.units.del(index) 
  for unit in battle.units:
    if unit.target_unit.isSome:
      if unit.target_unit.get == self: unit.target_unit = none(Unit)
    let index_in_currently_selected_units = battle.currently_selected_units.find(self)
    if index_in_currently_selected_units != -1: battle.currently_selected_units.del(index_in_currently_selected_units)     

proc get_center(self: Unit): seq[Vector2] = discard #  the tile on which i stand

proc get_tile_and_chunk_by_vec(self: BattleData, vec: Vector2): tuple[tile:BattleTile,chunk: BattleChunk] =
  let chunk_index_x = (vec.x / CHUNK_SIZE_IN_PIXELS).floor
  let chunk_index_y = (vec.y / CHUNK_SIZE_IN_PIXELS).floor

proc normalize_angle(angle: float): float = 
  let wrapped = angle mod 360.0; return (if wrapped < 0.0: wrapped + 360.0 else: wrapped)  

# Function to calculate the angle between two Vector2 points in degrees (0 - 360)
proc angleBetween(p1, p2: Vector2): float =
  let deltaX = p2.x - p1.x; let deltaY = p2.y - p1.y
  let angleRad = arctan2(deltaY, deltaX)
  let angleDeg = angleRad * (180.0 / PI)
  if angleDeg < 0: return angleDeg + 360 else: return angleDeg

proc update_unit_position_on_chunk_and_tile(unit: Unit, g: Game) = 
  discard

proc get_logical_size_of_unit_as_rect(self: Unit): Rectangle = 
  return Rectangle(x: self.pos.x - self.logical_width/2, y: self.pos.y - self.logical_height/2, width: self.logical_width, height: self.logical_height)

#region BATTLE-START
proc init_battle(g:var Game, #[more args here that describe the battle params]#) =
  g.mode = GameMode.Battle
  g.current_battle = some(BattleData()); var battle = g.current_battle.get
  let tile_size_in_pixels = 64
  battle.chunk_size_in_tiles = 10; let chunk_size_pixel = tile_size_in_pixels*battle.chunk_size_in_tiles
  battle.chunks = @[]
  # create battle field tiles ...
  for x in 0..WORLD_IN_CHUNKS-1: 
    for y in 0..WORLD_IN_CHUNKS-1:
      var chunk = BattleChunk()
      chunk.pos = Vector2(x: (x * chunk_size_pixel).float, y: (y * chunk_size_pixel).float)
      battle.chunks.add(chunk)
      chunk.tiles = @[]
      chunk.units_on_chunk = @[]
      chunk.battle_objects = @[]
      for tile_x in 0..(battle.chunk_size_in_tiles)-1:
        for tile_y in 0..(battle.chunk_size_in_tiles)-1:
          var tile = BattleTile()
          tile.pos = Vector2(x: (x * chunk_size_pixel + tile_x * tile_size_in_pixels).float, y: (y * chunk_size_pixel + tile_y * tile_size_in_pixels).float)
          tile.units = @[]
          tile.battle_object = none(BattleObject)
          chunk.tiles.add(tile)

  # todo; create all chunks here ...
  # todo; create all tiles here ...
  # todo: add the args so we know what to set in the battle -> what game play flags...
  battle.camera = Camera2D(target: Vector2(x: 0, y: 0), offset: Vector2(x: 0, y: 0), rotation: 0, zoom: 1)

proc battle_logic(g:var Game, delta_time: float): void = 
  
  if isKeyPressed(KeyboardKey.L): apply_battle_outcome(g) # todo: this should be another key
  var battle = g.current_battle.get
  
  # todo:update unit-tile, the unit stands on, also update the chunk the unit is on...
  # todo: so this via a function
  var unit_batch_state {.global.} = 0 # this can be used to keep the batch-state between proc calls
  for unit in battle.units: # todo: dont iterate over all units each step ... 
    if unit.in_vehicle: continue
    
    update_unit_position_on_chunk_and_tile(unit, g)

    var can_move = true           
    if unit.target_unit.isSome:

      if unit.target_unit.get.health <= 0: unit.target_unit = none(Unit); continue
      if unit.target_unit.get.in_vehicle: unit.target_unit = none(Unit); continue

      let target_in_reach = distance(unit.pos, unit.target_unit.get.pos) < unit.weapon_range.get_range_in_pixels        
      if target_in_reach: can_move = false
      # todo: units should only be able to shoot if they are facing the target
      # todo: we need to determine the "needed_rotation" to face the target
      # todo: then we move with a "rotation_speed" towards this rotation
      # todo: soldiers have instant rotation, vehicles have a rotation speed that is slower
      unit.rotation = angleBetween(unit.pos, unit.target_unit.get.pos)
    
    if unit.target_unit.isSome and unit.shoot_cooldown < 0 and unit.can_fight: 
      let target_in_reach = distance(unit.pos, unit.target_unit.get.pos) < unit.weapon_range.get_range_in_pixels
      if target_in_reach and unit.shoot_cooldown < 0: # SHOT !
        unit.shoot_cooldown = 60 / unit.shoots_per_minute
        battle.shots.add(
          Shot(
            start: unit.pos, 
            target: unit.target_unit.get.pos, 
            duration: 0.2, 
            damage: unit.weapon_system.get_damage_in_pixels,
            bullet_size: unit.weapon_system))
        battle.sprites.add( # todo: do we need this sprite?
          BattleSprite(pos: Vector2(x: unit.pos.x + rand(-20..20).float, y: unit.pos.y +  rand(-20..20).float), 
          rotation: rand(0..360).float, sprite_name: "bullet_case" ))  
        # todo: invest some thought into sound-design playSound(g.sounds["shot"])

    else: # scan for units in vicinity if i have not target
      if unit.look_around_check_in < 0:
        for other_unit in battle.units: # sort for distance to current unit
          if other_unit == unit: continue
          if other_unit.health <= 0: continue
          if other_unit.in_vehicle: continue
          if (unit.team < 3 and other_unit.team > 2) or (unit.team > 2 and other_unit.team < 3):
            let in_reach = distance(unit.pos, other_unit.pos) < unit.weapon_range.get_range_in_pixels
            if in_reach: unit.target_unit = some(other_unit); break
    
    if unit.move_target.isSome and can_move: # move towards this position, walk around obstacles
      # todo: check here oif i am bnear eniugh to my targte oif i have one
      unit.rotation = angleBetween(unit.pos, unit.move_target.get)
      unit.pos = moveTowards(unit.pos, unit.move_target.get, unit.speed.get_speed_in_pixels * delta_time)
      if abs(distance(unit.pos, unit.move_target.get)) < unit.speed.get_speed_in_pixels * delta_time:
        unit.pos = unit.move_target.get
        unit.move_target = none(Vector2) 
        if unit.target_rotation.isSome:
          unit.rotation = unit.target_rotation.get
          unit.target_rotation = none(float)
    
    unit.shoot_cooldown = unit.shoot_cooldown - delta_time  
    unit.look_around_check_in = unit.look_around_check_in - delta_time
    
    block: discard # check if i am on target chunk, and if not try to move towards

  for chunk in battle.chunks: discard
    # todo check how many unist are in this chunk
    # todo loop over them and check if they collide on a tile  
    # todo collision of units: push out of each other: use tiles for this

  for command_group in battle.command_groups: discard  # ? -> was machen die?
  # todo: we need to think about command groups, since they might enable ai based control of units
  # todo: command groups also should enable easy selection and meta control

  for unit in battle.units: #  todo: optimze via chunks !
    # apply collision with other units, so they dont overlap: push each other out...
    discard#  use raylib collision functions for this ...  

  # handle the zoom with the mouse wheel
  let moved = getMouseWheelMove()
  if moved != 0:
    let zoom_delta = moved * 0.1; let old_zoom = battle.camera.zoom
    battle.camera.zoom += zoom_delta; if battle.camera.zoom < 0.1: battle.camera.zoom = 0.1
    let new_zoom = battle.camera.zoom
    # Adjust the camera target to keep the center position the same
    let screen_center = Vector2(x: getScreenWidth().float / 2.0, y: getScreenHeight().float / 2.0)
    let world_center_before = Vector2(
      x: (screen_center.x - battle.camera.offset.x) / old_zoom + battle.camera.target.x,
      y: (screen_center.y - battle.camera.offset.y) / old_zoom + battle.camera.target.y)
    let world_center_after = Vector2(
      x: (screen_center.x - battle.camera.offset.x) / new_zoom + battle.camera.target.x,
      y: (screen_center.y - battle.camera.offset.y) / new_zoom + battle.camera.target.y)
    battle.camera.target.x -= world_center_after.x - world_center_before.x
    battle.camera.target.y -= world_center_after.y - world_center_before.y

  if isMouseButtonDown(MouseButton.Middle):
    let delta = getMouseDelta();battle.camera.target.x -= delta.x; battle.camera.target.y -= delta.y
  if isKeyDown(KeyboardKey.D): battle.camera.target.x += 10
  if isKeyDown(KeyboardKey.A): battle.camera.target.x -= 10
  if isKeyDown(KeyboardKey.W): battle.camera.target.y -= 10
  if isKeyDown(KeyboardKey.S): battle.camera.target.y += 10

  if isKeyPressed(KeyboardKey.Space): battle.display_mode = if battle.display_mode == BattleDisplayMode.Tactic: BattleDisplayMode.Strategic else: BattleDisplayMode.Tactic

  if isKeyPressed(KeyboardKey.ONE): spawn_scout_platoon(g, get_start_chunk_of_player(g), get_start_chunk_of_player(g), 1)
  if isKeyPressed(KeyboardKey.TWO): spawn_map_control_platoon(g, get_start_chunk_of_player(g), get_start_chunk_of_player(g), 1)
  if isKeyPressed(KeyboardKey.THREE): spawn_attack_platoon(g, get_start_chunk_of_player(g), get_start_chunk_of_player(g), 1)
  if isKeyPressed(KeyboardKey.FOUR): spawn_defense_platoon(g, get_start_chunk_of_player(g), get_start_chunk_of_player(g), 1)

  if isKeyPressed(KeyboardKey.FIVE): spawn_defense_platoon(g, get_start_chunk_of_ai(g), get_start_chunk_of_ai(g), 3)
  if isKeyPressed(KeyboardKey.SIX): spawn_attack_platoon(g, get_start_chunk_of_ai(g), get_start_chunk_of_ai(g), 3)
  if isKeyPressed(KeyboardKey.SEVEN): spawn_map_control_platoon(g, get_start_chunk_of_ai(g), get_start_chunk_of_ai(g), 3)
  if isKeyPressed(KeyboardKey.EIGHT): spawn_scout_platoon(g, get_start_chunk_of_ai(g), get_start_chunk_of_ai(g), 3)


  if isKeyPressed(KeyboardKey.U):
    for unit in battle.currently_selected_units: unload_units_from_vehicle(g, unit)

  var dead_units: seq[Unit] = @[]
  for index, unit in mpairs(battle.units): (if unit.health <= 0:  dead_units.add(unit))
  for _, unit in mpairs(dead_units): unit_die_and_remove(unit, battle)  


proc display_and_progress_explosions(g:var Game, delta_time: float): void =
  var battle = g.current_battle.get
  var explosions_to_remove: seq[BattleExplosion] = newSeq[BattleExplosion]()
  for index, explosion in battle.explosions:
    let size = (case explosion.size
      of ExplosionSize.Femto: 8
      of ExplosionSize.Mini: 16
      of ExplosionSize.Small: 32
      of ExplosionSize.Medium:  64
      of ExplosionSize.Large: 128).float
    explosion.active_since = explosion.active_since + delta_time
    if explosion.active_since < 0.1: 
      draw_from_atlas(g.battle_graphics["explosion_1"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.2:
      draw_from_atlas(g.battle_graphics["explosion_2"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.3:
      draw_from_atlas(g.battle_graphics["explosion_3"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.4:
      draw_from_atlas(g.battle_graphics["explosion_4"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.5:
      draw_from_atlas(g.battle_graphics["explosion_5"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.6:
      draw_from_atlas(g.battle_graphics["explosion_6"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.7:
      draw_from_atlas(g.battle_graphics["explosion_7"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.8:
      draw_from_atlas(g.battle_graphics["explosion_8"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 0.9:
      draw_from_atlas(g.battle_graphics["explosion_9"], g, explosion.pos.x, explosion.pos.y, size, size)
    elif explosion.active_since < 1.0:
      draw_from_atlas(g.battle_graphics["explosion_10"], g, explosion.pos.x, explosion.pos.y, size, size)
    else: explosions_to_remove.add(explosion)
  for explosion in explosions_to_remove: 
    let index = battle.explosions.find(explosion)
    battle.explosions.del index  



#region BATTLE-DISPLAY
proc battle_display(g:var Game, delta_time: float): void = 

  var rotation {.global.} = 0.0

  var battle = g.current_battle.get
  beginMode2D(battle.camera); let screen_w = getScreenWidth(); let screen_h = getScreenHeight()
  let res = g.battle_graphics
  
  # select stuff and draw select-rect

  case battle.display_mode:

    of BattleDisplayMode.Tactic:
      for chunk in battle.chunks:
        for tile in chunk.tiles:
            draw_from_atlas(res["gras"], g, tile.pos.x, tile.pos.y)
      for chunk in battle.chunks:
        drawRectangleLines(Rectangle(x:chunk.pos.x, y:chunk.pos.y, width:10*64, height:10*64), 2, BLUE)

      for sprite in battle.sprites:
        if sprite.is_vehicle:
          draw_from_atlas(g.battle_graphics[sprite.sprite_name], g, sprite.pos.x, sprite.pos.y, 256, 256, rotation=sprite.rotation-90)
        else:
          draw_from_atlas(g.battle_graphics[sprite.sprite_name], g, sprite.pos.x, sprite.pos.y, 0, 0, rotation=sprite.rotation)
      
      for unit in battle.currently_selected_units:
        if battle.currently_selected_units.len < 4: drawCircleLines(Vector2(x:unit.pos.x, y:unit.pos.y), unit.weapon_range.get_range_in_pixels, RED)
        if unit.is_soldier: drawRectangleLines(Rectangle(x:unit.pos.x - 32, y:unit.pos.y-32, width:64, height:64), 2, RED)  
        else : drawRectangleLines(Rectangle(x:unit.pos.x - 64, y:unit.pos.y-64, width:128, height:128), 2, RED)
        if unit.move_target.isSome: drawLine(unit.pos, unit.move_target.get, RED)

      for unit in battle.units:
        if unit.in_vehicle: continue
        if unit.target_unit.isSome: drawLine(unit.pos, unit.target_unit.get.pos, PURPLE)

      for unit in battle.units:
        if unit.in_vehicle: continue         
        draw_from_atlas(g.battle_graphics[unit.texture_name], g, unit.pos.x, unit.pos.y, unit.texture_w, unit.texture_h, rotation=unit.rotation - 90)
        if unit.health < unit.max_health:
          drawRectangle(Rectangle(x:unit.pos.x - 32, y:unit.pos.y - 32, width:64, height:5), BLACK)
          drawRectangle(Rectangle(x:unit.pos.x - 32, y:unit.pos.y - 32, width:64 * unit.health / unit.max_health, height:5), GREEN)


        if not unit.is_soldier and unit.units_on_board.len > 0:
          for index, unit_on_board in unit.units_on_board:
            # draw a small filled circle on the vehicle to indicate that there are units on board
            drawCircle(Vector2(x:(unit.pos.x.int + index * 5).float, y:(unit.pos.y.int).float + 32), 2, YELLOW)

      for shot in battle.shots: 
        drawLine(shot.start, shot.target, WHITE)
        shot.duration = shot.duration - delta_time  

      # debugging
      for unit in battle.units:
        if unit.in_vehicle: continue
        drawCircleLines(Vector2(x:unit.pos.x, y:unit.pos.y), unit.logical_radius, PURPLE)

      display_and_progress_explosions(g, delta_time)
      
      var shot_index  = 0
      while shot_index < battle.shots.len:
        var shot = battle.shots[shot_index]
        drawLine(shot.start, shot.target, WHITE)
        shot.duration = shot.duration - delta_time
        if shot.duration < 0: 
          battle.shots.del shot_index 
          var dead_units: seq[Unit] = newSeq[Unit]()
          for index, unit in battle.units:
            if unit.in_vehicle: continue            
            if checkCollisionPointRec(shot.target, Rectangle(x:unit.pos.x - 16, y: unit.pos.y - 16, width:32, height:32)):
              unit.health -= shot.damage
              # create a explosion here
              battle.explosions.add(BattleExplosion(
                # apply some randomness to the explosion p
                pos: Vector2(x: unit.pos.x + rand(-32..32).float, y: unit.pos.y + rand(-32..32).float),  
                active_since: 0, 
                size: (case shot.bullet_size
                of BulletSize.Rifle: ExplosionSize.Femto
                of BulletSize.HeavyRifle: ExplosionSize.Mini
                of BulletSize.Bazooka: ExplosionSize.Small
                of BulletSize.LightTank: ExplosionSize.Medium
                of BulletSize.MediumTank: ExplosionSize.Large
                of BulletSize.HeavyTank: ExplosionSize.Large
                of BulletSize.Mortar: ExplosionSize.Medium
                of BulletSize.Artillery: ExplosionSize.Large
                of BulletSize.AntiTankGun: ExplosionSize.Large)))
              if unit.health <= 0:
                if unit.is_soldier:          
                  for sprite_type in [ "blood_", "gore_", "bone_"]:# add blood and gore 
                    g.current_battle.get.sprites.add(
                      BattleSprite(
                        pos: Vector2(x: unit.pos.x + (rand(-64..64).float), y: unit.pos.y + (rand(-64..64)).float), 
                        rotation: rand(0..360).float, 
                        is_vehicle: false,
                        sprite_name: sprite_type & $rand(1..6)))
                else:
                    g.current_battle.get.sprites.add(
                      BattleSprite(
                        pos: Vector2(x: unit.pos.x, y: unit.pos.y), 
                        rotation: unit.rotation.float, 
                        sprite_name: "dead_tank_green",
                        is_vehicle: true))                          
                dead_units.add(unit)
                for passenger in unit.units_on_board: dead_units.add(passenger)
              break
          for index, unit in mpairs(dead_units): # todo: move the die uhnit logic out since this is bug heavy
            let dead_unit = unit
            unit_die_and_remove(unit, battle)

        else: shot_index += 1

    of BattleDisplayMode.Strategic:
      discard #  display the minimap, conrtrol command groups, etc.
      for command_group in battle.command_groups: discard # display   

  var is_dragging_position_selection {.global.} = false
  var target_position {.global.} = Vector2(x: 0, y: 0)

  # todo: if enough units in list, create 2, 3,4 rows and not one very long row...
  # todo: sort units by type so we have artillery, tanks, soldiers, etc. in different rows ...
  if isMouseButtonPressed(MouseButton.Right):
    is_dragging_position_selection = true; target_position = getScreenToWorld2D(getMousePosition(), battle.camera)
  
  if is_dragging_position_selection:
    let tpos = getScreenToWorld2D(getMousePosition(), battle.camera)
    let rotation_units_should_have = angleBetween(target_position, tpos) * (PI / 180.0) - PI/2
    var total_line_size: float = 0; let padding: float = 10
    for unit in battle.currently_selected_units: total_line_size = total_line_size + unit.logical_radius * 2 + padding
    let start_point_of_circles = (target_position - Vector2(x: total_line_size / 2, y: 0).rotate(rotation_units_should_have))
    var current_circle_pos = start_point_of_circles; var unit_on_new_position: seq[tuple[unit:Unit,pos:Vector2]] = @[]
    for unit in battle.currently_selected_units:
      drawCircleLines(current_circle_pos + Vector2(x: unit.logical_radius,y:0).rotate(rotation_units_should_have), unit.logical_radius, PURPLE)
      unit_on_new_position.add((unit:unit, pos:current_circle_pos + Vector2(x: unit.logical_radius,y:0).rotate(rotation_units_should_have)))
      current_circle_pos = current_circle_pos + Vector2(x: unit.logical_radius * 2 + padding, y: 0).rotate(rotation_units_should_have)
    drawLine(target_position, tpos,2, RED)
    if isMouseButtonReleased(MouseButton.Right):
      is_dragging_position_selection = false
      for unit in unit_on_new_position:
        unit.unit.move_target = some(unit.pos); unit.unit.target_unit = none(Unit); unit.unit.look_around_check_in = 0.5  
        unit.unit.target_rotation = some(rotation_units_should_have * (180.0 / PI) + 90)

  endMode2D()

  # Select and control units
  var is_dragging {.global.} = false      
  var selection_rect {.global.} = Rectangle()

  if isMouseButtonPressed(MouseButton.Left):
    isDragging = true
    let mousePos = getMousePosition()
    selectionRect.x = mousePos.x
    selectionRect.y = mousePos.y
    selectionRect.width = 0
    selectionRect.height = 0
  if isDragging:
    let currentMousePos = getMousePosition()
    selectionRect.width = currentMousePos.x - selectionRect.x
    selectionRect.height = currentMousePos.y - selectionRect.y
    if selection_rect.width > 0 and selection_rect.height > 0: drawRectangleLines(selectionRect, 2, WHITE)
  if isMouseButtonReleased(MouseButton.Left):
    isDragging = false
    battle.currently_selected_units = @[]
    for unit in battle.units:        
      if unit.in_vehicle: continue
      let point = getScreenToWorld2D(Vector2(x:  selection_rect.x - 32, y: selection_rect.y - 32), battle.camera)
      
      let unit_rect = 
        if unit.is_soldier:Rectangle(x:unit.pos.x-32, y: unit.pos.y-32, width: 64, height:64)
        else: Rectangle(x:unit.pos.x-64, y: unit.pos.y-64, width:128, height:128)

      if checkCollisionRecs(
        Rectangle(x: point.x, y: point.y, width:selection_rect.width / battle.camera.zoom, height:selection_rect.height / battle.camera.zoom), 
        unit_rect
      ):
        battle.currently_selected_units.add(unit)

  
  # todo: display small infocard for selected units

  if battle.display_hire_overlay: discard #  display the "hire units screen"

  #drawText("Unit: needed_rotation: " & $unit.needed_rotation , 10, 30, 20, WHITE)
  drawText("Units selected: " & $battle.currently_selected_units.len , 10, 10, 20, WHITE)
  drawText("Units on map: " & $battle.units.len , 10, 30, 20, WHITE)
  drawText("Zoom: " & $battle.camera.zoom , 10, 50, 20, WHITE)
  #drawText("Units on map: " & $battle.units.len , 10, 30, 20, WHITE)
#region BATTLE-END

#region FN-Helper
# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

func get_tile(self: var Scenario, x_in_world_pixel: float, y_in_world_pixel: float): Option[Tile] =
  let x_as_num = (x_in_world_pixel / TileSizePixel).floor.int
  let y_as_num = (y_in_world_pixel / TileSizePixel).floor.int
  if self.tiles_map.has_key(x_as_num) and self.tiles_map[x_as_num].has_key(y_as_num):
    return some(self.tiles_map[x_as_num][y_as_num])
  else: return none(Tile)

func is_in_world(self: Scenario, x: int, y: int): bool =
  return x >= 0 and x < WorldWidth_in_pixels and y >= 0 and y < WorldHeight_in_pixels

func create_Faction*(
  name: string, is_player_faction: bool, description: string, color: Color, s: Scenario 
): Faction =
  var faction = Faction()
  faction.name = name
  faction.is_player_faction = is_player_faction
  faction.description = description
  faction.color = color
  s.factions.add(faction)
  s.factions_on_map[name] = faction
  return faction

proc log(self: Logger, msg: string) = self.file.write(msg & "\n")

func get_relation(self: Scenario, faction_one: int, faction_two: int): int =
  ## Calculate the relation-number (not neccessarily the relation state) between
  ## two factions.
  var base_relation = 50; var counter = 0
  for event in self.faction_relation_events:
    if event.faction_one == faction_one and event.faction_two == faction_two or
      event.faction_one == faction_two and event.faction_two == faction_one:
      base_relation += event.relation_change; counter += 1
  return floor(base_relation / counter).int

#region init raylib
#-------------------------------------------------------------------------------
# Init logger and raylib stuff
#-------------------------------------------------------------------------------
const logfile_name = "log.txt"; if fileExists(logfile_name): removeFile(logfile_name)
var logger = Logger(file: open(logfile_name, fmAppend)); logger.log("Start Mages Engine")
setTraceLogLevel(TraceLogLevel.Error);initWindow(getScreenHeight(), getScreenWidth(), "example"); setWindowMonitor(0)
initAudioDevice()
var camera = Camera2D(target: Vector2(x: 0, y: 0), offset: Vector2(x: 0, y: 0), rotation: 0, zoom: 1)
setTargetFPS(60)
# todo: this makes trouble??
setWindowMonitor(2)
#toggleFullscreen();



# load all resources within the block
# otherwise we get segfault at close window call at the end...
block:
  #region loadBATTLE-RES
  var game = Game(); var running = true; var button_click_event: string = ""
  game.mode = GameMode.Menu; game.scenario = Scenario(); game.scenario.turn = 1

  game.sounds = initTable[string, Sound]()
  game.sounds["shot"] = loadSound("bim/pistol.wav")

  game.atlases = initTable[string, Texture]()
  game.atlases["BATTLE_TILES"] = loadTexture("./bim/Tileset.png")
  game.atlases["TANK_COLOR_1"] = loadTexture("./bim/tank_atlas_color_1.png")
  #game.atlases["SOLDIERS_COLOR_1"] = loadTexture("./bim/soldiers_color1.png")
  #game.atlases["SIMPLE_SOLDIERS_COLOR_1"] = loadTexture("./bim/simple-soldiers_color1.png")
  #game.atlases["SIMPLE_SOLDIERS_COLOR_2"] = loadTexture("./bim/simple-soldiers_color2.png")
  game.atlases["BULLET_CASE"] = loadTexture("./bim/bullet-case.png")
  game.atlases["TANKS_COLOR_1"] = loadTexture("./bim/tanks_color1.png")
  game.atlases["crator"] = loadTexture("./bim/crator.png")
  game.atlases["blood_and_gore"] = loadTexture("./bim/blood_and_gore.png")

  # actual game assets
  game.atlases["soldiers_gray"] = loadTexture("./bim/soldiers_gray.png")
  game.atlases["soldiers_green"] = loadTexture("./bim/soldiers_green.png")
  game.atlases["tanks_gray"] = loadTexture("./bim/TANKS_GRAY.png")
  game.atlases["tanks_green"] = loadTexture("./bim/TANKS_GREEN.png")


  game.atlases["explosion_1"] = loadTexture("./bim/Explosion_1.png")

  #region load Battle res
  game.battle_graphics = initTable[string, (int, int, int, int, string)]()
  game.battle_graphics["gras"] = (1225,127,64,64, "BATTLE_TILES")
  #game.battle_graphics["tank_1_color_1"] = (0, 0, 124,124, "TANK_COLOR_1") 
  #game.battle_graphics["soldier_1_color_1"] = (6*124, 2*64, 124, 124, "SOLDIERS_COLOR_1")

  #game.battle_graphics["mp_soldier_color_1"] = (0, 0, 64, 64, "SIMPLE_SOLDIERS_COLOR_1")
  #game.battle_graphics["mp_soldier_color_2"] = (0, 0, 64, 64, "SIMPLE_SOLDIERS_COLOR_2")
  game.battle_graphics["bullet_case"] = (0, 0, 5, 5, "BULLET_CASE")

  game.battle_graphics["tank_1_color_1"] = (0, 0, 256,256, "TANKS_COLOR_1")


  game.battle_graphics["support_soldier_green"] = (0, 0, 64, 64, "soldiers_green")
  game.battle_graphics["rifle_soldier_green"] = (64,0, 64, 64, "soldiers_green")
  game.battle_graphics["storm_soldier_green"] = (128,0, 64, 64, "soldiers_green")
  game.battle_graphics["bazooka_soldier_green"] = (192,0, 64, 64, "soldiers_green")
  game.battle_graphics["dead_soldier_green"] = (256,0, 64, 64, "soldiers_green")

  game.battle_graphics["support_soldier_gray"] = (0, 0, 64, 64, "soldiers_gray")
  game.battle_graphics["rifle_soldier_gray"] = (64,0, 64, 64, "soldiers_gray")
  game.battle_graphics["storm_soldier_gray"] = (128,0, 64, 64, "soldiers_gray")
  game.battle_graphics["bazooka_soldier_gray"] = (192,0 , 64, 64, "soldiers_gray")
  game.battle_graphics["dead_soldier_gray"] = (256, 0, 64, 64, "soldiers_gray")


  game.battle_graphics["humvee_green"] = (0, 0, 256, 256, "tanks_green")
  game.battle_graphics["truck_green"] = (256,0, 256, 256, "tanks_green")
  game.battle_graphics["light_tank_green"] = (512, 0, 256, 256, "tanks_green")
  game.battle_graphics["heavy_transport_green"] = (768, 0, 256, 256, "tanks_green")
  game.battle_graphics["medium_tank_green"] = (1024, 0, 256, 256, "tanks_green")
  game.battle_graphics["heavy_tank_green"] = (1280, 0, 256, 256, "tanks_green")
  game.battle_graphics["anti_tank_gun_green"] = (1536, 0, 256, 256, "tanks_green")
  game.battle_graphics["artillery_green"] = (1792, 0, 256, 256, "tanks_green")
  game.battle_graphics["mortar_green"] = (2048, 0, 256, 256, "tanks_green")
  game.battle_graphics["dead_tank_green"] = (2304, 0, 256, 256, "tanks_green")

  game.battle_graphics["humvee_gray"] = (0, 0, 256, 256, "tanks_gray")
  game.battle_graphics["truck_gray"] = (256, 0, 256, 256, "tanks_gray")
  game.battle_graphics["light_tank_gray"] = (512, 0, 256, 256, "tanks_gray")
  game.battle_graphics["heavy_transport_gray"] = (768, 0, 256, 256, "tanks_gray")
  game.battle_graphics["medium_tank_gray"] = (1024, 0, 256, 256, "tanks_gray")
  game.battle_graphics["heavy_tank_gray"] = (1280, 0, 256, 256, "tanks_gray")
  game.battle_graphics["anti_tank_gun_gray"] = (1536, 0, 256, 256, "tanks_gray")
  game.battle_graphics["artillery_gray"] = (1792 ,0 , 256, 256, "tanks_gray")
  game.battle_graphics["mortar_gray"] = (2048 ,0, 256, 256, "tanks_gray")
  game.battle_graphics["dead_tank_gray"] = (2304, 0, 256, 256, "tanks_gray")

  game.battle_graphics["crator"] = (0, 0, 64, 64, "crator")

  game.battle_graphics["bone_1"] = (0, 0, 16, 16, "blood_and_gore")
  game.battle_graphics["bone_2"] = (16, 0, 16, 16, "blood_and_gore")
  game.battle_graphics["bone_3"] = (32, 0, 16, 16, "blood_and_gore")
  game.battle_graphics["bone_4"] = (48, 0, 16, 16, "blood_and_gore")
  game.battle_graphics["bone_5"] = (64, 0, 16, 16, "blood_and_gore")
  game.battle_graphics["bone_6"] = (80, 0, 16, 16, "blood_and_gore") 

  game.battle_graphics["blood_1"] = (0, 16, 16, 16, "blood_and_gore")
  game.battle_graphics["blood_2"] = (16, 16, 16, 16, "blood_and_gore")
  game.battle_graphics["blood_3"] = (32, 16, 16, 16, "blood_and_gore")
  game.battle_graphics["blood_4"] = (48, 16, 16, 16, "blood_and_gore")
  game.battle_graphics["blood_5"] = (64, 16, 16, 16, "blood_and_gore")
  game.battle_graphics["blood_6"] = (80, 16, 16, 16, "blood_and_gore")

  game.battle_graphics["gore_1"] = (0, 32, 16, 16, "blood_and_gore")
  game.battle_graphics["gore_2"] = (16, 32, 16, 16, "blood_and_gore")
  game.battle_graphics["gore_3"] = (32, 32, 16, 16, "blood_and_gore")
  game.battle_graphics["gore_4"] = (48, 32, 16, 16, "blood_and_gore")
  game.battle_graphics["gore_5"] = (64, 32, 16, 16, "blood_and_gore")
  game.battle_graphics["gore_6"] = (80, 32, 16, 16, "blood_and_gore")

  game.battle_graphics["burned_1"] = (0, 48, 16, 16, "blood_and_gore")
  game.battle_graphics["burned_2"] = (16, 48, 16, 16, "blood_and_gore")
  game.battle_graphics["burned_3"] = (32, 48, 16, 16, "blood_and_gore")
  game.battle_graphics["burned_4"] = (48, 48, 16, 16, "blood_and_gore")
  game.battle_graphics["burned_5"] = (64, 48, 16, 16, "blood_and_gore")
  game.battle_graphics["burned_6"] = (80, 48, 16, 16, "blood_and_gore")

  game.battle_graphics["explosion_1"] = (0, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_2"] = (64, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_3"] = (128, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_4"] = (192, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_5"] = (256, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_6"] = (320, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_7"] = (384, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_8"] = (448, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_9"] = (512, 0, 64, 64, "explosion_1")
  game.battle_graphics["explosion_10"] = (576, 0, 64, 64, "explosion_1")

  #region init-mod
  var enter_next_round_cool_down: float = 0

  let ModImages = (
    flat:loadTexture("./mods/lerman/res/flat_0.png"),
    minerals:loadTexture("./mods/lerman/res/minerals_0.png"),
    mountain: loadTexture("./mods/lerman/res/mountain_0.png"),
    water:loadTexture("./mods/lerman/res/water_0.png"),
    menu_background: loadTexture("./mods/lerman/res/background.png")
  )

  let MENU_TEXTURE = loadTexture("./mods/lerman/res/menu.png")
  let MENU_BACKGROUND = (73,81,200,200)

  proc draw_from_menu_atlas(x, y, width, height, rotation: float, src: (int,int,int,int)) =
    let source_x = src[0].float; let source_y = src[1].float
    let source_w = src[2].float - source_x; let source_h = src[3].float - source_y
    let source_rect = Rectangle(x: source_x, y: source_y, width: source_w, height: source_h)
    let dest_rect = Rectangle(x: x, y: y, width: width, height: height)
    let origin = Vector2(x: 0, y: 0)
    drawTexture(MENU_TEXTURE, source_rect, dest_rect, origin, rotation, WHITE)

  proc populate_scenario(self: var Scenario, L: Logger) =
    for data in [
      ("Player", true, "some desc", Color(r:0,g:255,b:0,a:255)),
      ("Dörr", false, "some desc", Color(r:0,g:0,b:255,a:255)),
      ("Wusel", false, "some desc", Color(r:255,g:255,b:0,a:255)),
      ("Woki", false, "some desc", Color(r:64,g:224,b:208,a:255)),
      ("Schnubbel", false, "some desc", Color(r:64,g:44,b:44,a:255)),
      ("Kek", false, "some desc", Color(r:255,g:0,b:0,a:255))]:
      discard create_Faction(
        name=data[0], is_player_faction=data[1], description=data[2],color=data[3],self)
   
    for x in 0..WorldWidth_in_tiles-1: # generate a random scenario
      var tab = initTable[int, Tile](); self.tiles_map[x] = tab
      for y in 0..WorldHeight_in_tiles-1:
        var tile = Tile()
        tile.pos = Vector2(x:x.float * TileSizePixel, y:y.float * TileSizePixel)
        self.tiles_map[x][y] = tile; self.tiles.add(tile)
        tile.category
          = case rand(0..99)
            of 0..65: TileType.Land
            of 66..70: TileType.Minerals
            of 81..90: TileType.Water
            of 91..99: TileType.Mountain
            else: TileType.Land
        if tile.category == TileType.Land:
          tile.faction = case rand(0..20)
            of 0: some(self.factions[0])
            of 1: some(self.factions[1])
            of 2: some(self.factions[2])
            of 3: some(self.factions[3])
            of 4: some(self.factions[4])
            of 5: some(self.factions[5])
            else: none(Faction)
        if tile.faction.is_some:
          tile.army = some(Army(faction:tile.faction.get, tile_i_am_on: tile, command_points: rand(100..3800), level: 1))




  # directly start with a rng game to get the basic game loop working, remove this later
  game.scenario.populate_scenario(logger); game.mode = GameMode.Camp
  #region game-loop
  while running: 

    let delta_time = getFrameTime(); if windowShouldClose(): running = false
    update_button_cooldown(delta_time) # see ui/Button.nim

    # update here the game state
    case game.mode:
      #region menu
      of GameMode.Menu:
        if button_click_event != "": 
          case button_click_event:
            of "start_new_game":
              game.scenario.populate_scenario(logger)
              game.mode = GameMode.Camp
            of "exit": running = false
            of "": discard
            else: logger.log("[IGNORED] unknown menu button event: " & button_click_event)
          button_click_event = ""
      #------------------------------------------------------------------------#
      # Default campaign mode handle code.
      #------------------------------------------------------------------------#
      of GameMode.Camp:
        #region camp
        if button_click_event != "": # handle all button clicks
          #region NEXT-ROUND
          case button_click_event:
            of "next_round":  # handle all the computation if a new round is started
              game.scenario.turn += 1  # update to the next turn (resets the movment of the armies)
              logger.log("next round")
              # todo: apply all the income
              for t in game.scenario.tiles:
                if t.faction.isSome:
                  let f = t.faction.get
                  let income = case t.category:
                    of TileType.Land: 10
                    of TileType.Minerals: 100
                    else: 0
                  f.money += income  
              # todo: call the ai-processing
            of "": discard
            else: logger.log("[IGNORED] unknown camp button event: " & button_click_event)
          button_click_event = ""

        let speed = 400f * delta_time
        # based on the current zoom, we need to scroll faster or slower
        let zoom_factor = case (camera.zoom * 10).int:
          of 0..2: game.zoom_level = ZoomLevel.Mini; 16f
          of 3..4: game.zoom_level = ZoomLevel.VerySmall; 16f
          of 5..9: game.zoom_level = ZoomLevel.Small; 8f
          of 10: game.zoom_level = ZoomLevel.Default; 4f
          of 11..19: game.zoom_level = ZoomLevel.Big; 2f
          of 20..40: game.zoom_level = ZoomLevel.Big; 0.5
          else: game.zoom_level = ZoomLevel.Big; 0.1
        if isKeyDown(KeyboardKey.D): camera.target.x += zoom_factor * speed
        if isKeyDown(KeyboardKey.A): camera.target.x -= zoom_factor * speed
        if isKeyDown(KeyboardKey.W): camera.target.y -= zoom_factor * speed
        if isKeyDown(KeyboardKey.S): camera.target.y += zoom_factor * speed

        # handle the zoom with the mouse wheel
        let moved = getMouseWheelMove()
        if moved != 0:
          let zoom_delta = moved * 0.1; let old_zoom = camera.zoom
          camera.zoom += zoom_delta; if camera.zoom < 0.1: camera.zoom = 0.1
          let new_zoom = camera.zoom
          # Adjust the camera target to keep the center position the same
          let screen_center = Vector2(x: getScreenWidth().float / 2.0, y: getScreenHeight().float / 2.0)
          let world_center_before = Vector2(
            x: (screen_center.x - camera.offset.x) / old_zoom + camera.target.x,
            y: (screen_center.y - camera.offset.y) / old_zoom + camera.target.y)
          let world_center_after = Vector2(
            x: (screen_center.x - camera.offset.x) / new_zoom + camera.target.x,
            y: (screen_center.y - camera.offset.y) / new_zoom + camera.target.y)
          camera.target.x -= world_center_after.x - world_center_before.x
          camera.target.y -= world_center_after.y - world_center_before.y
        let mouse_pos = getMousePosition()
        # select a tile with the mouse ...
        if isMouseButtonPressed(MouseButton.Left):
          let x = (mouse_pos.x * 1/camera.zoom) + camera.target.x
          let y = (mouse_pos.y * 1/camera.zoom) + camera.target.y
          let tile = game.scenario.get_tile(x, y)
          # here is the place to check, that we are actually not behind the ui
          let right_padding = if game.selected_tile.is_some: 400 else: 0
          let top_padding = 60
          if mouse_pos.x.int < getScreenWidth() - right_padding and mouse_pos.y.int > top_padding:
            if tile.isSome: game.selected_tile = tile
            else: game.selected_tile = none(Tile)
          else: discard # dont do anything if we are in the ui, since we want to click ui buttons there ...
        if isMouseButtonPressed(MouseButton.Right): game.selected_tile = none(Tile)
        if isMouseButtonDown(MouseButton.Middle):
          let delta = getMouseDelta();camera.target.x -= delta.x * zoom_factor; camera.target.y -= delta.y * zoom_factor
        #region army-movement  
        #-----------------------------------------------------------------------
        # handle movement of armies by player: Create movement task
        #-----------------------------------------------------------------------
        if game.selected_tile.is_some:
          let tile = game.selected_tile.get
          if tile.faction.isSome:
            if tile.faction.get.is_player_faction:
              if tile.army.is_some and tile.army.get.last_moved_at_turn != game.scenario.turn:
                var move_to = none(Tile)
                if isKeyPressed(KeyboardKey.Left):
                  let left_one = game.scenario.get_tile(tile.pos.x - TileSizePixel, tile.pos.y)
                  if left_one.is_some: move_to = left_one;logger.log("move to left")
                if isKeyPressed(KeyboardKey.Right):
                  let right_one = game.scenario.get_tile(tile.pos.x + TileSizePixel, tile.pos.y)
                  if right_one.is_some: move_to = right_one;logger.log("move to right")
                if isKeyPressed(KeyboardKey.Up):
                  let up_one = game.scenario.get_tile(tile.pos.x, tile.pos.y - TileSizePixel)
                  if up_one.is_some: move_to = up_one;logger.log("move to up")
                if isKeyPressed(KeyboardKey.Down):
                  let down_one = game.scenario.get_tile(tile.pos.x, tile.pos.y + TileSizePixel)
                  if down_one.is_some: move_to = down_one;logger.log("move to down")
                # there could be a valid tile to move an army to ...
                if move_to.is_some() and move_to.get.category == TileType.Land:
                  game.player_movement_task = some(
                    ArmyMovementTask(army: tile.army.get,target_tile: move_to.get))

        # Get the player task or the one task from the list of ai tasks and
        # place this task into a task-option variable to be handled further down
        let task
          = if game.player_movement_task.isSome:
            let ret = game.player_movement_task
            game.player_movement_task = none(ArmyMovementTask)
            ret
          elif game.ai_army_movement_tasks.len > 0: some(game.ai_army_movement_tasks.popFirst())
          else: none(ArmyMovementTask)

        # if a task is to be done, execute the task
        if task.is_some:
          let task = task.get
          var movment_success = false
          let army = task.army
          let source_tile = army.tile_i_am_on
          let target_tile = task.target_tile
          if target_tile.faction.isNone: # occupy free tile
            target_tile.army = game.selected_tile.get.army
            source_tile.army = none(Army)
            target_tile.army.get.tile_i_am_on = target_tile
            target_tile.faction = source_tile.faction
            assert(target_tile.faction.isSome)
            movment_success = true
          elif target_tile.faction.get == source_tile.faction.get:
            if target_tile.army.is_some:
              discard # merge armies, higher tech level
            else:
              discard # just go there
          else:
             # attack (only on war)
             init_battle(game)
          if movment_success: target_tile.army.get.last_moved_at_turn = game.scenario.turn

      of GameMode.Battle: battle_logic(game, delta_time)
        
    #--------------------------------------------------------------------------#
    # End of game logic handling ...
    #--------------------------------------------------------------------------#

    beginDrawing()
    clearBackground(BLACK)

    case game.mode:

      #region Draw Menu
      of GameMode.Menu:
        block:
          drawTexture(ModImages.menu_background, 0, 0, WHITE)
          drawText("Lerman", 350, 10, 70, WHITE);
          if Button(text= "Start", pos= Vector2(x: 100, y: 100), width= 100,height= 50): button_click_event = "start_new_game"
          if Button(text= "Exit",pos= Vector2(x: 100, y: 200),width= 100,height= 50 ): button_click_event = "exit"


      of GameMode.Camp:
        block:
          #region draw camp-world
          beginMode2D(camera); let screen_w = getScreenWidth(); let screen_h = getScreenHeight()
          for tile in game.scenario.tiles:
            let in_view = checkCollisionRecs(
              Rectangle(x: camera.target.x * camera.zoom, y: camera.target.y * camera.zoom, width: screen_w.float, height: screen_h.float),
              Rectangle(x: tile.pos.x * camera.zoom, y: tile.pos.y * camera.zoom, width: TileSizePixel * camera.zoom, height: TileSizePixel * camera.zoom))
            if not in_view: continue
            case tile.category # draw textures of the tiles
              of TileType.Land: drawTexture(ModImages.flat,tile.pos,WHITE)
              of TileType.Water: drawTexture(ModImages.water,tile.pos,WHITE)
              of TileType.Mountain: drawTexture(ModImages.mountain,tile.pos,WHITE)
              of TileType.Minerals: drawTexture(ModImages.minerals,tile.pos,WHITE)

            # draw a faction colored border around the tile
            if tile.faction.isSome:
              let faction = tile.faction.get; let color = faction.color
              if game.zoom_level == ZoomLevel.Mini:
                drawRectangle( Rectangle(x: tile.pos.x,y: tile.pos.y, width: TileSizePixel, height: TileSizePixel), color)
              else:
                # outline in the color of the owning faction
                drawRectangleLines(Rectangle(x: tile.pos.x,y: tile.pos.y,width: TileSizePixel,height: TileSizePixel), 3, color)
                # draw a rect with some alpha in the color of the owning faction
                drawRectangle(Rectangle(x: tile.pos.x,y: tile.pos.y,width: TileSizePixel,height: TileSizePixel),fade(color, 0.15))

            # draw armies on the tile if not zoomed out to far
            if tile.army.isSome and game.zoom_level != ZoomLevel.Mini:
              assert tile.faction.isSome; let army = tile.army.get
              var visibilitiy_blocks = (army.command_points / 100).ceil.int
              let square_numbers = visibilitiy_blocks.float.sqrt().ceil
              let square_size = 4f; let space_between = 2; let space_around = 2f
              let witdh = square_numbers * square_size + (square_numbers + 1) * space_between.float + space_around * 2
              let extra_space = (TileSizePixel - witdh) / 2; var drawn_blocks = 0
              let x_rect_start = tile.pos.x + extra_space; let y_rext_start = tile.pos.y + extra_space
              block outer_loop:
                for row in 0..square_numbers.int - 1:
                  for col in 0..square_numbers.int - 1:
                    drawn_blocks += 1
                    if drawn_blocks > visibilitiy_blocks: break outer_loop
                    let x = tile.pos.x.int + extra_space.int + col * square_size.int + space_between * (col + 1)
                    let y = tile.pos.y.int + extra_space.int + row * square_size.int + space_between * (row + 1)
                    let rect = Rectangle(x: x.float, y: y.float, width: square_size.float, height: square_size.float)
                    let moved_this_turn = game.scenario.turn == army.last_moved_at_turn
                    let color = if moved_this_turn: fade(tile.faction.get.color, 0.3) else: tile.faction.get.color
                    drawRectangle(rect, color)

              # draw rect directly around the army; 2 lines thick
              drawRectangleLines(
                Rectangle( x: x_rect_start - space_around, y: y_rext_start - space_around, width: witdh, height: witdh), 
                2,
                # if this army is moved this turn, make white border
                if tile.army.get.last_moved_at_turn == game.scenario.turn: WHITE else: tile.faction.get.color)

              # draw the strenght of the army in the top-left tile corner
              let command_points = army.command_points
              let level = army.level
              let display_string = $command_points & " - " & $level
              drawText(display_string, (tile.pos.x + 4).int32, (tile.pos.y + 4).int32, 20, WHITE)


          # --------------------------------------------------------------------
          # end of tile drawing
          # --------------------------------------------------------------------

          # draw outline around selected tile
          if game.selected_tile.isSome:
            let selected = game.selected_tile.get
            drawRectangleLines(
              Rectangle(x: selected.pos.x,y: selected.pos.y,width: TileSizePixel,height: TileSizePixel),
              2, raylib.WHITE)

          endMode2D()
          # end the camera : this means here comes the ui
          # this means all drawing, that is not affected by zooming and scrolling
          #region draw camp UI
          let menu_width = 400f
          let menu_start = getScreenWidth().float - menu_width
          let top_bar_height = 40f
          let menu_height = getScreenHeight().float - top_bar_height
          let top_bar_width = getScreenWidth().float # - menu_width

          # draw the top bar
          draw_from_menu_atlas(x=0, y=0, width=top_bar_width, height=top_bar_height, rotation=0f,src=MENU_BACKGROUND)

          # draw the next round button; handle enter click 
          if Button(text= "Next Round",pos= Vector2(x: 10, y: 10),width= 100,height= 20) or isKeyPressed(KeyboardKey.Enter) and 
            enter_next_round_cool_down < 0: button_click_event = "next_round"; enter_next_round_cool_down = 1.0
          enter_next_round_cool_down = enter_next_round_cool_down - delta_time

          # draw the amount of player money
          for f in game.scenario.factions:
            if f.is_player_faction: 
              drawText(( $f.money & "$"), (130).int32, (10).int32, 20, BLACK)
 
          if game.selected_tile.isSome: # if some tile is selected, draw the data of the tile
            draw_from_menu_atlas(menu_start, top_bar_height, menu_width, menu_height, rotation=0f, src=MENU_BACKGROUND)
            let tile_data = game.selected_tile.get
            drawText(("Tile: " & $tile_data.category), (menu_start + 10).int32, (10+top_bar_height).int32, 20, BLACK)
            drawText(("Pos: " & $tile_data.pos), (menu_start + 10).int32, (30+top_bar_height).int32, 20, BLACK)
            if tile_data.faction.isSome:
              let faction = tile_data.faction.get
              drawText(("Faction-Owner: " & $faction.name), (menu_start + 10).int32, (50+top_bar_height).int32, 20, faction.color)
              if faction.is_player_faction == false:
                # todo: draw the relation state in the color of the relation: enemy: red, ally: green, neutral black
                drawText("RELARTION-STATE XXX", (menu_start + 10).int32, (120+top_bar_height).int32, 20, BLACK)
                # todo: draw the relation number on a color spctrum from green to red
                drawText("RELARTION-NUMBER XXX", (menu_start + 10).int32, (140+top_bar_height).int32, 20, BLACK)
                # todo: display some debug information here about the faction....
            else:
              drawText("No Faction", (menu_start + 10).int32, (50+top_bar_height).int32, 20, BLACK)
              drawText(("Type: " & $tile_data.category), (menu_start + 10).int32, (70+top_bar_height).int32, 20, BLACK)
            if tile_data.army.isSome:
              drawText(("Army - Command Points: " & $tile_data.army.get.command_points), (menu_start + 10).int32, (90+top_bar_height).int32, 20, BLACK)
            else: drawText("No Army", (menu_start + 10).int32, (90+top_bar_height).int32, 20, BLACK)
      
      # end of campaign drawing
      of GameMode.Battle: battle_display(game, delta_time)

    # --------------------------------------------------------------------------
    # end of game drawing logic
    # --------------------------------------------------------------------------

    # draw ret circlertin the middle of the screen
    # drawCircle(Vector2(x:getScreenWidth() / 2-10, y: getScreenHeight() / 2)-10, 20, RED)

    #region debug info
    # --------------------------------------------------------------------------
    # Draw some debug information
    # --------------------------------------------------------------------------
    when defined(debug):
      if game.mode == GameMode.Camp:
        let top_bar_height = 40; let fps = getFPS(); let mouse_pos = getMousePosition()
        drawText("FPS: " & $fps, 10, (10+top_bar_height).int32, 20, RED)
        drawText("Camera: " & $camera.target, 10, (30+top_bar_height).int32, 20, RED)
        drawText("Zoom: " & $camera.zoom, 10, (50+top_bar_height).int32, 20, RED)
        drawText("Mouse: " & $mouse_pos, 10, (70+top_bar_height).int32, 20, RED)
        drawText("Zoom Level: " & $game.zoom_level, 10, (90+top_bar_height).int32, 20, RED)

    endDrawing()
    # --------------------------------------------------------------------------
    # end of the game loop
    # --------------------------------------------------------------------------

closeWindow()