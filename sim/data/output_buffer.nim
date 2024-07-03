include comps

import options
import config

type OutputBuffer* = ref object ##\
  ## All output is written into an output buffer, which is written if
  ## the buffer is full or the simulation ends. When a buffer is full
  ## is set in the configuration file.
  name: string
  data: seq[string]
  file: File
  current_step: uint

proc new_OutputBuffer*(name: string, conf: Config): OutputBuffer =
  return OutputBuffer(
    name: name,
    data: @[],
    file: open(conf.output_dir & name & ".csv", fmWrite)
  )
proc `current_step=`*(buffer: var OutputBuffer, value: uint) = buffer.current_step = value
proc `->`*(buffer: var OutputBuffer, line: string) = buffer.data.add($buffer.current_step & ": " & line)
proc write*(buffer: var OutputBuffer, conf: Option[Config]) =
  if conf.isSome:
    if buffer.data.len >= conf.get.buffer_check_steps:
      for line in buffer.data:
        buffer.file.writeLine(line)
      buffer.data.setLen(0)
  else:
    for line in buffer.data:
      buffer.file.writeLine(line)
    buffer.data.setLen(0)
proc close*(buffer: var OutputBuffer) =
  buffer.file.close()
  buffer.file = nil