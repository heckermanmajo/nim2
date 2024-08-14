import battle_types
import camp_types
import menu_types
import engine_types

# make the serializer its own file, since we dont 
# need to see this code very often
# and otherwise it clutters the more "hot" files
proc to_csv*(me: Battle): string = discard
proc to_csv*(me: Camp): string = discard
proc to_csv*(me: BTile): string = discard
# ...