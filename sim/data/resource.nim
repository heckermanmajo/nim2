include comps
import strutils

type Resource* = ref object
  id: uint

var ResourceTypeInformation = (
  name: "Resource"
)

proc `id=`*(instance: Resource, id: uint) =
  echo "setting id"
  instance.id = id

proc id*(instance: Resource): uint =
  echo "getting id"
  return instance.id

proc new_Resource(line: string): Resource =
  let fields = line.split(',')
  var resource = Resource(
    id: fields[0].parseInt.uint
  )
  return resource