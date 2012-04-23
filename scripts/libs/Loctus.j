library Locust initializer init
  globals
    group udg_enumGrp = CreateGroup()
    private boolexpr FILTER_LOCTUSTENUM
  endglobals
  
  private function LocustEnumerators_AntiLeak takes nothing returns boolean
    return true
  endfunction
  
  private function init takes nothing returns nothing
    set FILTER_LOCTUSTENUM = Filter( function LocustEnumerators_AntiLeak )
  endfunction

  function GroupEnumLocustsInRangePlayer takes group g, real x, real y, real radius, boolexpr filter, player owner returns nothing
    local unit u
    if filter == null then
      set filter = FILTER_LOCTUSTENUM
    endif

    call GroupEnumUnitsOfPlayer( udg_enumGrp, owner, filter )
    loop
      set u = FirstOfGroup(udg_enumGrp)
      exitwhen u == null
      if IsUnitInRangeXY( u, x, y, radius ) and GetUnitAbilityLevel(u,'Aloc') > 0 then
        call GroupAddUnit( g, u )
      endif
      call GroupRemoveUnit(udg_enumGrp,u)
    endloop
  endfunction
  
  function GroupEnumLocustsInRangeOfLocPlayer takes group g, location loc, real radius, boolexpr filter, player owner returns nothing
    call GroupEnumLocustsInRangePlayer(g, GetLocationX(loc), GetLocationY(loc), radius, filter, owner)
  endfunction

  function GroupEnumUnitsInRangeExPlayer takes group g, real x, real y, real radius, boolexpr filter, player owner returns nothing
    local unit u
    if filter == null then
      set filter = FILTER_LOCTUSTENUM
    endif
    call GroupEnumUnitsOfPlayer( udg_enumGrp, owner, filter )
    loop
      set u = FirstOfGroup(udg_enumGrp)
      exitwhen u == null
      if IsUnitInRangeXY( u, x, y, radius ) then
        call GroupAddUnit( g, u )
      endif
      call GroupRemoveUnit(udg_enumGrp,u)
    endloop
  endfunction
  
  function GroupEnumUnitsInRangeOfLocExPlayer takes group g, location loc, real radius, boolexpr filter, player owner returns nothing
    call GroupEnumUnitsInRangeExPlayer(g, GetLocationX(loc), GetLocationY(loc), radius, filter, owner)
  endfunction

  function GroupEnumLocustsInRectPlayer takes group g, rect r, boolexpr filter, player owner returns nothing
    local unit u
    local region re = CreateRegion()
    call RegionAddRect( re, r )
    if filter == null then
      set filter = FILTER_LOCTUSTENUM
    endif
    call GroupEnumUnitsOfPlayer( udg_enumGrp, owner, filter )
    loop
      set u = FirstOfGroup(udg_enumGrp)
      exitwhen u == null
      if GetUnitAbilityLevel( u, 'Aloc' ) > 0 and IsUnitInRegion( re, u ) then
        call GroupAddUnit( g, u )
      endif
      call GroupRemoveUnit(udg_enumGrp,u)
    endloop

    call RegionClearRect( re, r )
    call RemoveRegion( re )
    set re = null
  endfunction

  function GroupEnumUnitsInRectExPlayer takes group g, rect r, boolexpr filter, player owner returns nothing
    local unit u
    local region re = CreateRegion()
    call RegionAddRect( re, r )
    if filter == null then
      set filter = FILTER_LOCTUSTENUM
    endif
    
    call GroupEnumUnitsOfPlayer( udg_enumGrp, owner, filter )
    loop
      set u = FirstOfGroup(udg_enumGrp)
      exitwhen u == null
      if IsUnitInRegion( re, u ) then
        call GroupAddUnit( g, u )
      endif
      call GroupRemoveUnit(udg_enumGrp,u)
    endloop
    call RegionClearRect( re, r )
    call RemoveRegion( re )
    set re = null
  endfunction

  function GroupEnumNormalUnitsOfPlayer takes group g, player p, boolexpr filter returns nothing
    local unit u
    if filter == null then
      set filter = FILTER_LOCTUSTENUM
    endif
    call GroupEnumUnitsOfPlayer( udg_enumGrp, p, filter )
    loop
      set u = FirstOfGroup( udg_enumGrp )
      exitwhen u == null
      if GetUnitAbilityLevel( u, 'Aloc' ) == 0 then
        call GroupAddUnit( g, u )
      endif
      call GroupRemoveUnit( udg_enumGrp, u )
    endloop
  endfunction

  function GroupEnumNormalUnitsOfType takes group g, string unitName, boolexpr filter returns nothing
    local unit u
    if filter == null then
      set filter = FILTER_LOCTUSTENUM
    endif
    call GroupEnumUnitsOfType( udg_enumGrp, unitName, filter )
    loop
      set u = FirstOfGroup( udg_enumGrp )
      exitwhen u == null
      if GetUnitAbilityLevel( u, 'Aloc' ) == 0 then
        call GroupAddUnit( g, u )
      endif
      call GroupRemoveUnit( udg_enumGrp, u )
    endloop
  endfunction
endlibrary