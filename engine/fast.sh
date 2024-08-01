# --opt:none \
# --d: release\
nim compile \
  --checks:on \
  --d: release \
  --profiler:on \
  main.nim \
  && ./main
