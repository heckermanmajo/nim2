# define lerman -> builds the lerman mod
nim compile \
  --define:lerman \
  --checks:on \
  --opt:none \
  main.nim \
  && ./main