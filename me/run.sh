# nimble install naylib
# nimble install binaryheap

# --opt:none \
# --d: release\
nim compile \
  --checks:on \
  --opt:none \
  --profiler:on \
  main.nim \
  && ./main \
  && rm main  #\
  #&& rm log.txt \
  #&& rm profile_results.txt \

