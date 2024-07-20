# define lerman -> builds the lerman mod
nim compile \
  --define:lerman \
  --define:debug \
  --checks:on \
  --opt:none \
  main.nim \
  && ./main