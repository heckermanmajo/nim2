# nimble install naylib
# nimble install binaryheap

# --opt:none \
# --d: release\
nim compile \
  --checks:on \
  --opt:none \
  --profiler:on \
  --threads:off \
  --out:./ \
  src/main.nim \
  && ./main \
  && rm main  #\
  #&& rm log.txt \
  #&& rm profile_results.txt \

