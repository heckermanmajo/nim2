type
  UnitTypeEquipment* = enum 
    SimpleShield
    Spear
    Bow

  UnitType* = ref object
    name: string
    
proc name*(self: UnitType): string = self.name