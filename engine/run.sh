# --opt:none \
# --d: release\
nim compile \
  --checks:on \
  --opt:none \
  --profiler:on\
  main.nim \
  && ./main
