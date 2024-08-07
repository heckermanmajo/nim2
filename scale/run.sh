# --opt:none \
# --d: release\
nim compile \
  --checks:on \
  --opt:none \
  --profiler:on \
  main.nim \
  && ./main \
  && rm main  \
  && rm -f log.txt \
  && rm -f profile_results.txt

