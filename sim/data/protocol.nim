include comps

type Protocol* = ref object
  id: uint

proc `id=`*(instance: Protocol, id: uint) =
  echo "setting id"
  instance.id = id

proc id*(instance: Protocol): uint =
  echo "getting id"
  return instance.id