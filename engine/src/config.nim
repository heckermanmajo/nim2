import raylib 

const DEBUG* = true ## Determines if some code is compiled
const LOGFILE_NAME* = "log.txt" ## each execution here will logs be placed
const chunks_per_side* = 10 ## Chunks per side of the world
const CHUNK_SIZE_IN_PIXEL* = 256
const WORLD_MAX_X* = CHUNK_SIZE_IN_PIXEL * chunks_per_side
const WORLD_MAX_Y* = CHUNK_SIZE_IN_PIXEL * chunks_per_side
const UNIT_COLLISION_INTERVAL* = 5
const COLLISION_PUSH_INTERVAL_PIXEL* = 5
const WORLD_COLOR* = WHITE
const UNIT_THINK_INTERVAL* = 500