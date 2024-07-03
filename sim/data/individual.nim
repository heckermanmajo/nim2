include comps

type Individual* = ref object
  id: uint
  age: uint

proc `id=`*(instance: Individual, id: uint) = instance.id = id

proc id*(instance: Individual): uint = return instance.id

proc `age=`*(instance: Individual, age: uint) = instance.age = age

proc age*(instance: Individual): uint = return instance.age

proc new_Individual*(id: uint, age: uint): Individual =
  result = Individual(id: id, age: age)