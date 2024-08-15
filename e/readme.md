# How to write code

## State-Modules
- creates stuff
- keep state to itself
- main file in a game
- game? maybe

## Logic-Modules
- only does work on the passed in parameters
- does not care how the passed in stuff comes to beeing
- is not allowed to access state modules

## Type-Modules
- One type + its enums
- also all methods, that need to update this 
  instance. All writes via methods.
- Think about a data-type as a protocol.   
