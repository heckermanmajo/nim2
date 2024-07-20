import tables, sequtils, strutils, json, os, math, times, sets, options
include comps

type Cohort* = ref object
  ##[[
  A cohort represents a number of people who act as one unit in a social network.
  They are usually bound by some common place.
  Most members are not computed as individuals, since they dont display individual behavior.
  ]]##
  id: uint
  individuals:seq[int] ## Ids of the individuals in the cohort
  births_on_year: Table[int, int] ##\
  ## Number of births on a given year. Also needed to calculate the number
  ## of individuals in the cohort.

proc `id=`*(instance: Cohort, id: uint) =
  echo "setting id"
  instance.id = id

proc id*(instance: Cohort): uint =
  echo "getting id"
  return instance.id

proc new_Cohort*(id: uint, individuals: seq[int], members: Table[int, int]): Cohort =
  result = Cohort(
    id: id,
    individuals: individuals,
    births_on_year: members
  )

proc number_of_members*(instance: Cohort): int =
  let all_birts = block: (var sum = 0; (for _, a in instance.births_on_year: sum += a); sum)
  return instance.individuals.len + all_birts
