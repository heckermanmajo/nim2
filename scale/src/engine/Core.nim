type
    
  ZoomLevel* = enum 

    ## Zoomlevel of the map. If it changes, we might change the way to display stuff 
    ## to keep an acceptable fps-rate.
    
    Mini
    VerySmall
    Small
    Default
    Big

  BadGameState* = object of Defect  