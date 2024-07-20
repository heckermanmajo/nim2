include data/comps

# we can use echo as the default debug logging system and pipe the logs into a file
import sequtils
import tables
import strutils
import std/hashes
import os
import options

import data/product
import data/cohort
import data/resource
import data/protocol
import data/individual

import data/output_buffer

import data/config


type TypeInformation = tuple ##\
  ## We use the type information to keep track of the fields of each type
  ## and its usages/ progression strategies.
  name: string

type Simulation = tuple
  cohorts: Table[uint, Cohort]
  resources: Table[uint, Resource]
  products: Table[uint, Product]
  protocols: Table[uint, Protocol]
  individuals: Table[uint, Individual]

proc `|>`[T](container: Table[uint, T], id: uint): T =
  when debug:
    if id in container: return container[id]
    else: raise newException(ValueError, "Instance not found")
  else: return container[id]

var simulation: Simulation = (
  cohorts: initTable[uint, Cohort](),
  resources: initTable[uint, Resource](),
  products: initTable[uint, Product](),
  protocols: initTable[uint, Protocol](),
  individuals: initTable[uint, Individual]()
)

# read the configuration file ...
# todo: for the development keep tzhe cinfuig in code
let conf = Config(
  end_step: 20,
  write_buffers_all_x_entries: 5,
  buffer_check_steps: 10,
  output_dir: "output/"
)

# clean the output directory
# if the directory does not exist, create it
if not dirExists(conf.output_dir):
  createDir(conf.output_dir)
else:
  for file in walkDir(conf.output_dir):
    removeFile(file.path)


simulation.cohorts[1] = new_Cohort(id=1, individuals= @[1, 2, 3], members= initTable[int, int]())
simulation.cohorts[2] = new_Cohort(id=2, individuals= @[4, 5, 6], members= initTable[int, int]())

# add 4 individuals
simulation.individuals[1] = new_Individual(id= 1, age= 0)
simulation.individuals[2] = new_Individual(id= 2, age= 0)
simulation.individuals[3] = new_Individual(id= 3, age= 0)
simulation.individuals[4] = new_Individual(id= 4, age= 0)

var p = new_Product(1)
discard p.id
p.id = 1

let c = simulation.cohorts|>1

# create the output buffers
var log = new_OutputBuffer("debug_logging", conf)

var all_loggers = @[log]

block:
  # read the simulation data from the cmd ...
  for current_step in 0 .. conf.end_step:
    # for buffer in all_loggers: buffer.current_step = current_step.uint
    # all strategies here
    # write the results in buffers and write the buffers once
    # enough data is collected
    # just write csv files
    # startegies are just included as files, so all buffer and other
    # global variables are available to the strategy
    # some strategies are only executed all x steps
    # this can be done by the modulo operator
    block: # only all 10 steps
      if current_step mod 10 == 0:
        for individual in simulation.individuals.values:
          let s = "individual: " & $individual.id & " age: " & $individual.age
          log -> s

    block: # test startegy
      for individual in simulation.individuals.values:
        individual.age = individual.age + 1

    block: #write
      if current_step mod conf.buffer_check_steps == 0:
        for _, buffer in all_loggers.mpairs: buffer.write(some(conf))


# write the remaining data from the buffers
for _, buffer in all_loggers.mpairs: buffer.write(none(Config))