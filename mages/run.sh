  # define lerman -> builds the lerman mod
nim compile \
  --define:debug \
  --checks:on \
  --define:release \
  main.nim \
  && ./main  #--opt:none \
