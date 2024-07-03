include comps

type Product* = ref object
  ##[[

  ]]##
  # make the id private in debug mode, so we can log stuff
  when debug:
    id: uint
  else:
    id*: uint

proc `id=`*(instance: Product, id: uint) =
  echo "setting id"
  instance.id = id

proc id*(instance: Product): uint =
  echo "getting id"
  return instance.id

proc new_Product*(id: uint): Product =
  result = Product(id: id)

