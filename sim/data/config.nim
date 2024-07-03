include comps

type Config* = ref object
  end_step*:int
  write_buffers_all_x_entries*: int
  buffer_check_steps*: int
  output_dir*: string

