  # define lerman -> builds the lerman mod
nim compile \
  --define:debug \
  --checks:on \
  main.nim \
  && ./main  #--opt:none \
