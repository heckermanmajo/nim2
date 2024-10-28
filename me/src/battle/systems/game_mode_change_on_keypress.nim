import raylib
import battle/battle_types

let cool_down_interval = 0.4
var cool_down = cool_down_interval

proc game_mode_change_on_keypress*(me: Battle, dt: float) = 
  cool_down = cool_down - dt
  if isKeyDown(F12) and cool_down < 0:
    cool_down = cool_down_interval
    case me.user_control_mode:
      of UserControlMode.NORMIE_MODE: 
        me.user_control_mode = UserControlMode.GOD_PLAYER_MODE
      of UserControlMode.GOD_PLAYER_MODE: 
        me.user_control_mode = UserControlMode.MAP_EDITOR_MODE
      of UserControlMode.MAP_EDITOR_MODE: 
        me.user_control_mode = UserControlMode.PATHFINDER_MODE
      of UserControlMode.PATHFINDER_MODE: 
        me.user_control_mode = UserControlMode.NORMIE_MODE