library Pathfinding requires General
  function MakeSimplePathingRectByUnit takes unit u, integer rectsize returns rect
    local location c = GetUnitLoc(u)
    local rect r
    
    set r = RectFromCenterSizeBJ(c, rectsize/2, rectsize/2)
    call RemoveLocation(c)
    set c = null
    
    // error we have constructed a wrong pathing rect
    if (r == null or RectContainsUnit(r, u) == false) then
      call showMessage("ERROR: gen. rect doesn't contains the param. unit (Pathfinding.makeSimplePathingRectByUnit)")
      return null
    endif
    
    return r
  endfunction
  
  ////////////
  // http://www.wc3jass.com/viewtopic.php?t=240
  // AIAndy
  ////////////
  private function GetRandomLocInCircle takes real centerx, real centery, real radius returns location
    local real dist = SquareRoot(GetRandomReal(0,1))*radius
    local real angle = GetRandomReal(0,2*bj_PI)
    return Location(centerx+dist*Cos(angle), centery+dist*Sin(angle))
  endfunction
  
  // return a location in r with maxrange radius*closeness from the center of the rect.
  function GetRandomPointCloseToCenterInRect takes rect r, real closeness returns location
    local real radius = RMinBJ(GetRectWidthBJ(r), GetRectHeightBJ(r)) * 0.5 * closeness
    return GetRandomLocInCircle(GetRectCenterX(r), GetRectCenterY(r), radius)
  endfunction
  
  ////////////
  ////////////
  // get closest unit in angle of sight
  ////////////
  ////////////
  
  ////////////
  // Author: Grater
  // http://www.wc3jass.com/viewtopic.php?t=236
  ////////////
  private function DoesQuadContainOrigin takes real x1, real y1, real x2, real y2, real x3, real y3, real x4, real y4 returns boolean
    local integer counter = 0

    if (x1-x2)*y1 < x1 * (y1-y2) then
        set counter = counter + 1
    endif

    if (x2-x3)*y2 < x2 * (y2-y3) then
        set counter = counter + 1
    endif

    if (x3-x4)*y3 < x3 * (y3-y4) then
        set counter = counter + 1
    endif

    if (x4-x1)*y4 < x4 * (y4-y1) then
        set counter = counter + 1
    endif

    return ((counter == 4) or (counter == 0))
  endfunction

  ////////////
  // Author: Grater
  // http://www.wc3jass.com/viewtopic.php?t=236
  ////////////
  private function IsPointInQuadFast takes real x, real y, real x1, real y1, real x2, real y2, real x3, real y3, real x4, real y4 returns boolean
    return DoesQuadContainOrigin(x1-x,y1-y,x2-x,y2-y,x3-x,y3-y,x4-x,y4-y)
  endfunction

  /////////
  // Author: Grater
  // http://www.wc3jass.com/viewtopic.php?t=238
  /////////
  private function GroupEnumUnitsInCone takes group g, location loc, real length, real angle, real width1, real width2, boolexpr filter returns nothing
    local group tempGroup = CreateGroup()
    local real array x
    local real array y
    local real minX
    local real minY
    local real maxX
    local real maxY
    local rect tempRect
    local location tempLoc
    local unit u
    set x[1] = GetLocationX(loc) + CosBJ(angle-90.0) * width1
    set y[1] = GetLocationY(loc) + SinBJ(angle-90.0) * width1
    set x[2] = GetLocationX(loc) + CosBJ(angle+90.0) * width1
    set y[2] = GetLocationY(loc) + SinBJ(angle+90.0) * width1
    set tempLoc = PolarProjectionBJ(loc, length,angle)
    set x[3] = GetLocationX(tempLoc) + CosBJ(angle+90.0) * width2
    set y[3] = GetLocationY(tempLoc) + SinBJ(angle+90.0) * width2
    set x[4] = GetLocationX(tempLoc) + CosBJ(angle-90.0) * width2
    set y[4] = GetLocationY(tempLoc) + SinBJ(angle-90.0) * width2

    // Now we have a quad, define the rect that encloses it.
    set minX = RMinBJ(x[1],RMinBJ(x[2],RMinBJ(x[3],x[4])))
    set minY = RMinBJ(y[1],RMinBJ(y[2],RMinBJ(y[3],y[4])))
    set maxX = RMaxBJ(x[1],RMaxBJ(x[2],RMaxBJ(x[3],x[4])))
    set maxY = RMaxBJ(y[1],RMaxBJ(y[2],RMaxBJ(y[3],y[4])))
    set tempRect = Rect(minX,minY,maxX,maxY)
    call GroupEnumUnitsInRect(tempGroup,tempRect,filter)
    //Now we filter the ins and outs
    loop
        set u = FirstOfGroup(tempGroup)
        exitwhen u == null
        if IsPointInQuadFast(GetUnitX(u),GetUnitY(u),x[1],y[1],x[2],y[2],x[3],y[3],x[4],y[4]) then
            call GroupAddUnit(g,u)
        endif
        call GroupRemoveUnit(tempGroup,u)
    endloop

    call RemoveLocation(tempLoc)
    call DestroyGroup(tempGroup)
    call RemoveRect(tempRect)
    set tempGroup = null
    set tempLoc = null
    set tempRect = null
  endfunction
  
  /////////
  // Author: Grater
  // Modification: Siggylein (added minDist)
  // http://www.wc3jass.com/viewtopic.php?t=100
  // !add minDist
  /////////
  private function FindClosestUnit takes group g, real x, real y, real minDist returns unit
    local real dx
    local real dy
    local group tempGroup
    local real maxDist=999999.0
    local real dist
    local unit u = null
    local unit closest = null

    if (bj_wantDestroyGroup == true) then
        set tempGroup = g
    else
        set tempGroup = CreateGroup()
        call GroupAddGroup(g, tempGroup)
    endif
    set bj_wantDestroyGroup = false

    loop
        set u = FirstOfGroup(tempGroup)
        call GroupRemoveUnit(tempGroup, u)
        exitwhen (u == null)
        set dx = GetUnitX(u) - x
        set dy = GetUnitY(u) - y
        set dist = SquareRoot(dx*dx+dy*dy)
        if (dist < maxDist and dist >= minDist) then
            set closest = u
            set maxDist = dist
        endif
    endloop
    call DestroyGroup(tempGroup)
    set tempGroup = null
    return closest
  endfunction

  /////////
  // Author: Grater
  // Modification: Siggylein (added minDist)
  // http://www.wc3jass.com/viewtopic.php?t=100
  // !add minDist
  /////////
  private function FindClosestUnitLoc takes group g, location loc, real minDist returns unit
    return FindClosestUnit(g,GetLocationX(loc),GetLocationY(loc), minDist)
  endfunction
  
  /////////
  // get closest unit in angle of sight
  /////////
  function ClosestUnitInAngleofsight takes unit source, real angle, real mindist, real maxdist, boolexpr filter returns unit
    local real dist = maxdist
    local real width 
    local group candidates = CreateGroup()
    local location loc = GetUnitLoc(source)
    local real unitsightangle = GetUnitFacing(source)
    local unit result
    // store bj_wantDestroyGroup status
    local boolean tmpDestroy = bj_wantDestroyGroup
    
    set width = TanBJ(angle) * dist
    call GroupEnumUnitsInCone(candidates, loc, dist, unitsightangle, width, width, filter)
    
    // destroy candidates
    set bj_wantDestroyGroup = true
    set result = FindClosestUnitLoc(candidates, loc, mindist)

    // clearup
    call RemoveLocation(loc)
    set loc = null
    set bj_wantDestroyGroup = tmpDestroy
    
    return result
  endfunction
  
  ////////////
  ////////////
  // Given a unit group, finds the center, like the center of gravity.
  // Author: Grater
  // http://www.wc3jass.com/viewtopic.php?t=222
  ////////////
  ////////////
  function GroupFindCenterXEnum takes nothing returns nothing
    set bj_randomSubGroupChance = bj_randomSubGroupChance + GetUnitX(GetEnumUnit())
    set bj_randomSubGroupTotal = bj_randomSubGroupTotal + 1
  endfunction

  function GroupFindCenterYEnum takes nothing returns nothing
    set bj_randomSubGroupChance = bj_randomSubGroupChance + GetUnitY(GetEnumUnit())
    set bj_randomSubGroupTotal = bj_randomSubGroupTotal + 1
  endfunction

  function GroupFindCenterLoc takes group whichGroup returns location
    local real oldReal = bj_randomSubGroupChance
    local integer oldInt = bj_randomSubGroupTotal
    local real x
    local real y
    //Determine average x
    if (whichGroup == null) or (FirstOfGroup(whichGroup) == null) then
        return null
    endif
    set bj_randomSubGroupChance = 0.0
    set bj_randomSubGroupTotal = 0
    call ForGroup(whichGroup, function GroupFindCenterXEnum)
    set x = bj_randomSubGroupChance / (bj_randomSubGroupTotal)

    //Determine average y
    set bj_randomSubGroupChance = 0.0
    set bj_randomSubGroupTotal = 0
    call ForGroup(whichGroup, function GroupFindCenterYEnum)
    set y = bj_randomSubGroupChance / (bj_randomSubGroupTotal)

    set bj_randomSubGroupChance = oldReal
    set bj_randomSubGroupTotal = oldInt

    return Location(x,y)
  endfunction
endlibrary
