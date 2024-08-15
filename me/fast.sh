# nimble install naylib
# nimble install binaryheap

# --opt:none \
# --d: release\
nim compile \
  --checks:on \
  --d: release \
  --profiler:on \
  --out:./ \
  src/main.nim \
  && ./main \
  && rm main  #\
  #&& rm log.txt \
  #&& rm profile_results.txt \

