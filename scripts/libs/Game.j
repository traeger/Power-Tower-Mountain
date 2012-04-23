///////////////////////////////////////////
// Contains useful functions just for this map
///////////////////////////////////////////
library game requires general
  globals
    constant real TILE_SIZE = 128.0
    constant integer TILE_GRASSY_DIRT = 'Zdrg'
    constant integer TILE_GRASS = 'Zgrs'
    constant integer TILE_DARK_GRASS = 'Lgrd'   // changed
  endglobals

  //////////
  //Converts integers to a string of length at most 5 (6 for negative)
  //////////
  function cSmallStr takes integer i returns string
    local integer n = 0

    //compute ~order of magnitude
    loop
      exitwhen i < 10000 and i > -10000
      set i = i / 1000
      set n = n + 1
    endloop

    //append order-of-magnitude character
    if (n == 0) then
      return I2S(i)
    elseif (n == 1) then
      return I2S(i) + "K"
    elseif (n == 2) then
      return I2S(i) + "M"
    elseif (n == 3) then
      return I2S(i) + "B"
    else
      return I2S(i) + "?"
    endif
  endfunction

  //////////
  // Adjusts the grass level of the terrain at a given point between grassy, light, and dark
  // tileX, tileY = tile coordinates
  // d = change to grass level (usually +1 or -1)
  // return = true if the tile had to be changed
  //////////
  function adjustGrassLevel takes integer tileX, integer tileY, integer d returns boolean
    local integer level
    local integer tile1
    local integer tile2
    if (d == 0) then
      return false
    endif

    //Get Current Tile Level
    set tile1 = GetTerrainType(tileX*TILE_SIZE, tileY*TILE_SIZE)
    if (tile1 == TILE_GRASSY_DIRT) then
      set level = 1
    elseif (tile1 == TILE_GRASS) then
      set level = 2
    elseif (tile1 == TILE_DARK_GRASS) then
      set level = 3
    else
      return false //the given tile isn't grass
    endif

    //adjust level
    set level = limitRange(level + d, 1, 3)

    //Get tile for new Level
    if (level == 1) then
      set tile2 = TILE_GRASSY_DIRT
    elseif (level == 2) then
      set tile2 = TILE_GRASS
    elseif (level == 3) then
      set tile2 = TILE_DARK_GRASS
    endif
    if (tile1 == tile2) then
      return false
    endif
  
    //Set tile
    call SetTerrainType(tileX*TILE_SIZE, tileY*TILE_SIZE, tile2, -1, 1, 1)
    return true
  endfunction

  //////////
  // Picks a random nearby patch of grass to burn
  // p = the point around which grass should be burned
  // return = true if grass was found and burned
  //////////
  function burnNearbyGrass takes location p returns boolean
    local integer i
    local integer j
    local integer x
    local integer y
    local integer cx
    local integer cy
    local integer dx
    local integer dy
    local integer size = VAL_FURNACE_FUEL_RANGE*2+1
    if (p == null) then
      return false
    endif

    //get center tile
    set cx = R2I(GetLocationX(p) / 128)
    set cy = R2I(GetLocationY(p) / 128)

    //pick random starting tile offset
    set dx = GetRandomInt(1, size)-1
    set dy = GetRandomInt(1, size)-1

    //scan the tiles in range starting from the chosen tile for burnable grass
    set i = 0
    loop
      exitwhen i >= size
      set j = 0
      loop
        exitwhen j >= size
        set x = cx + imod(i+dx, size) - VAL_FURNACE_FUEL_RANGE
        set y = cy + imod(j+dy, size) - VAL_FURNACE_FUEL_RANGE
        if (adjustGrassLevel(x, y, -1) == true) then
          return true
        endif
        set j = j + 1
      endloop
      set i = i + 1
    endloop

    //failed to find grass
    return false
  endfunction

  ////////////
  // Takes a pre-placed pathing region and returns a proper pathing rect
  // SIDE-EFFECTS: rect registered pathing event
  // r = the pre-placed pathing region
  // i = the player index to transform to
  // return = reflected pathing rect
  ////////////
  function makePathingRect takes rect r, integer i returns rect
    local location c
    local real w
    local real h
    local real x
    local real y
    local real t
    if (r == null or i < 1 or i > NUM_DEFENDERS) then
      return null
    endif

    //get properties of pre-placed region
    set c = GetRectCenter(r)
    set x = GetLocationX(c)
    set y = GetLocationY(c)
    set w = GetRectWidthBJ(r)
    set h = GetRectHeightBJ(r)
    call RemoveLocation(c)
    set c = null

    //transform to fit the correct player
    if (imod(i, 4) == 2 or imod(i, 4) == 3) then //reflect along diagonal
      set t = y
      set y = x
      set x = t
      set t = w
      set w = h
      set h = w
    endif
    if (i > 4) then //reflect along vertical
      set x = -x
    endif
    if (i > 2 and i <= 6) then //reflect along horizontal
      set y = -y
    endif

    //create a smaller rect for firing events
    set c = Location(x, y)
    set r = RectFromCenterSizeBJ(c, w/2, h/2)
    call Events.addPathingEventRect(r)

    //create the pathing rect
    set r = RectFromCenterSizeBJ(c, w, h)
    call RemoveLocation(c)
    set c = null

    return r
  endfunction

  
  ////////////
  // Takes a pre-placed pathing region and returns a proper pathing rect
  // SIDE-EFFECTS: rect registered pathing event
  // r = the pre-placed pathing region
  // return = reflected pathing rect
  ////////////
  function makeSimplePathingRect takes rect r returns rect
    local location c
    local real w
    local real h
    local real x
    local real y
    local real t
    if (r == null) then
      return null
    endif
    
    //get properties of pre-placed region
    set c = GetRectCenter(r)
    set x = GetLocationX(c)
    set y = GetLocationY(c)
    set w = GetRectWidthBJ(r)
    set h = GetRectHeightBJ(r)
    call RemoveLocation(c)
    set c = null
    
    //create a smaller rect for firing events
    set c = Location(x, y)
    set r = RectFromCenterSizeBJ(c, w/2, h/2)
    call Events.addPathingEventRect(r)

    //create the pathing rect
    set r = RectFromCenterSizeBJ(c, w, h)
    call RemoveLocation(c)
    set c = null

    return r
  endfunction
  
  function isNight takes nothing returns boolean
    return (GetTimeOfDay() < 6 or GetTimeOfDay() > 18)
  endfunction
  
  // replace a unit this all its items
  // if the unit dose not have itemsslot i dont know what happens
  function ReplaceUnitWithItems takes unit whichUnit, integer newUnitId, integer unitStateMethod returns unit
    local unit    oldUnit = whichUnit
    local unit    newUnit
    local boolean wasHidden
    local integer index
    local item    indexItem
    local real    oldRatio

    // If we have bogus data, don't attempt the replace.
    if (oldUnit == null) then
      set bj_lastReplacedUnit = oldUnit
      return oldUnit
    endif

    // Hide the original unit.
    set wasHidden = IsUnitHidden(oldUnit)
    call ShowUnit(oldUnit, false)

    set newUnit = CreateUnit(GetOwningPlayer(oldUnit), newUnitId, GetUnitX(oldUnit), GetUnitY(oldUnit), GetUnitFacing(oldUnit))

    // Set the unit's life and mana according to the requested method.
    if (unitStateMethod == bj_UNIT_STATE_METHOD_RELATIVE) then
      // Set the replacement's current/max life ratio to that of the old unit.
      // If both units have mana, do the same for mana.
      if (GetUnitState(oldUnit, UNIT_STATE_MAX_LIFE) > 0) then
        set oldRatio = GetUnitState(oldUnit, UNIT_STATE_LIFE) / GetUnitState(oldUnit, UNIT_STATE_MAX_LIFE)
        call SetUnitState(newUnit, UNIT_STATE_LIFE, oldRatio * GetUnitState(newUnit, UNIT_STATE_MAX_LIFE))
      endif

      if (GetUnitState(oldUnit, UNIT_STATE_MAX_MANA) > 0) and (GetUnitState(newUnit, UNIT_STATE_MAX_MANA) > 0) then
        set oldRatio = GetUnitState(oldUnit, UNIT_STATE_MANA) / GetUnitState(oldUnit, UNIT_STATE_MAX_MANA)
          call SetUnitState(newUnit, UNIT_STATE_MANA, oldRatio * GetUnitState(newUnit, UNIT_STATE_MAX_MANA))
      endif
    elseif (unitStateMethod == bj_UNIT_STATE_METHOD_ABSOLUTE) then
      // Set the replacement's current life to that of the old unit.
      // If the new unit has mana, do the same for mana.
      call SetUnitState(newUnit, UNIT_STATE_LIFE, GetUnitState(oldUnit, UNIT_STATE_LIFE))
      if (GetUnitState(newUnit, UNIT_STATE_MAX_MANA) > 0) then
        call SetUnitState(newUnit, UNIT_STATE_MANA, GetUnitState(oldUnit, UNIT_STATE_MANA))
      endif
    elseif (unitStateMethod == bj_UNIT_STATE_METHOD_DEFAULTS) then
      // The newly created unit should already have default life and mana.
    elseif (unitStateMethod == bj_UNIT_STATE_METHOD_MAXIMUM) then
      // Use max life and mana.
      call SetUnitState(newUnit, UNIT_STATE_LIFE, GetUnitState(newUnit, UNIT_STATE_MAX_LIFE))
      call SetUnitState(newUnit, UNIT_STATE_MANA, GetUnitState(newUnit, UNIT_STATE_MAX_MANA))
    else
      // Unrecognized unit state method - ignore the request.
    endif

    // Mirror properties of the old unit onto the new unit.
    //call PauseUnit(newUnit, IsUnitPaused(oldUnit))
    call SetResourceAmount(newUnit, GetResourceAmount(oldUnit))

    // Handel itmes
    set index = 0
    loop
      set indexItem = UnitItemInSlot(oldUnit, index)
      if (indexItem != null) then
        call UnitRemoveItem(oldUnit, indexItem)
        call UnitAddItem(newUnit, indexItem)
      endif

      set index = index + 1
        exitwhen index >= bj_MAX_INVENTORY
    endloop

    // Remove or kill the original unit.  It is sometimes unsafe to remove
    // hidden units, so kill the original unit if it was previously hidden.
    if wasHidden then
      call KillUnit(oldUnit)
      call RemoveUnit(oldUnit)
    else
      call RemoveUnit(oldUnit)
    endif

    set bj_lastReplacedUnit = newUnit
    return newUnit
  endfunction

endlibrary

//===========================================================================
function InitTrig_Game_Library takes nothing returns nothing
endfunction