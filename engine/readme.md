- if a control group gets a chunk as target
  do not allow this if one of the same faction is there
  if so, chose a border chunk as target position
  EXCEPT: Enemies are in this chunk

so we need factions, group control and then we can implement fighting.

Fighting in free mode.

Disable collision if group is not on fight mode.

Only select groups if you have collected more than 20 % or only this group.

# Software Structure in nim

## Stuff to be factored into strcutre
- how often to change the content of the file
- utils-file -> few changes ...



## Use tuples instead of objects if the case is simple 

Specifically for structuring data, I have one advice: you use tuples instead of objects whenever you don't need the extra features that objects provide.
