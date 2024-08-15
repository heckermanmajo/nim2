# --opt:none \
# --d: release\
nim compile \
  --checks:on \
  --opt:none \
  --profiler:on \
  --experimental \
  ./src/main.nim \
  && ./main \
  && rm main  \
  && rm -f log.txt \
  && rm -f profile_results.txt

