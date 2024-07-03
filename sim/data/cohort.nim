include comps

type Cohort* = ref object
  id: uint

proc `id=`*(instance: Cohort, id: uint) =
  echo "setting id"
  instance.id = id

proc id*(instance: Cohort): uint =
  echo "getting id"
  return instance.id

proc new_Cohort*(id: uint): Cohort =
  result = Cohort(id: id)