library towerconstants
  
  globals
    constant integer ABIL_SELL = 'A003'
    constant integer ABIL_CONSUME_RUNNER = 'A00I'
    constant integer ABIL_TRANSMUTE = 'A00V'
    constant integer ABIL_ADD_TRANSFER = 'A000'
    constant integer ABIL_ADD_LONGTRANSFER = 'A019'
    constant integer ABIL_REMOVE_TRANSFER = 'A006'
    constant integer ABIL_SHOW_RANGES = 'A005'
    constant integer ABIL_WATER_BURST = 'A00N'
    constant integer ABIL_BLAZE = 'A00F'
    constant integer ABIL_ELEMENTAL_FIRE = 'A00S'
    constant integer ABIL_ELEMENTAL_WATER = 'A00T'
    constant integer ABIL_ELEMENTAL_NATURE = 'A00U'
    constant integer BUFF_ELEMENTAL_FIRE = 'B001'
    constant integer BUFF_ELEMENTAL_NATURE = 'B003'
    constant integer BUFF_ELEMENTAL_WATER = 'B002'
    constant integer BUFF_BOOSTED = 'B000'
      
    constant integer TOWER_TYPE_TREE_1 = 'h04E'
    constant integer TOWER_TYPE_TREE_2 = 'h04F'
    constant integer TOWER_TYPE_TREE_3 = 'h04G'
    constant integer TOWER_TYPE_TREE_4 = 'h04H'
    constant integer TOWER_TYPE_TREE_5 = 'h04I'
    constant integer TOWER_TYPE_TREE_6 = 'h04J'
    constant integer TOWER_TYPE_FURNACE_1 = 'h000'
    constant integer TOWER_TYPE_MOONWELL_1 = 'h04K'
    constant integer TOWER_TYPE_WATERWHEEL_1 = 'h004'
    constant integer TOWER_TYPE_MAGICSTONE = 'h04Q'
  endglobals
  
  //////////
  constant function isBridgingTower takes integer ut returns boolean
    return (ut == 'h003' or ut == 'h007' or ut == 'h008' or ut == 'h01P' or ut == 'h01Q' or ut == 'h01R' or ut == 'h042')
  endfunction
  //////////
  constant function isMagicStone takes integer ut returns boolean
    return (ut == TOWER_TYPE_MAGICSTONE)
  endfunction
  //////////
  constant function isWaterWheel takes integer ut returns boolean
    return (ut == 'h004' or ut == 'h01K' or ut == 'h01L' or ut == 'h01M' or ut == 'h01N' or ut == 'h01O')
  endfunction
  //////////
  constant function isFurnace takes integer ut returns boolean
    return (ut == 'h000' or ut == 'h011' or ut == 'h012' or ut == 'h013' or ut == 'h014' or ut == 'h015')
  endfunction
  //////////
  constant function isGraveyard takes integer ut returns boolean
    return (ut == 'h036' or ut == 'h037' or ut == 'h038' or ut == 'h039' or ut == 'h03A' or ut == 'h03B')
  endfunction
  //////////
  constant function isMoonwell takes integer ut returns boolean
    return (ut == 'h04K' or ut == 'h04L' or ut == 'h04M' or ut == 'h04N')
  endfunction  

  //////////
  constant function isRockLauncher takes integer ut returns boolean
    return (ut == 'h005' or ut == 'h00W' or ut == 'h00X' or ut == 'h00Y' or ut == 'h00Z' or ut == 'h010')
  endfunction
  //////////
  constant function isLichTower takes integer ut returns boolean
    return (ut == 'h00J' or ut == 'h01B' or ut == 'h01C' or ut == 'h01D' or ut == 'h01E' or ut == 'h01F')
  endfunction
  //////////
  constant function isClockTower takes integer ut returns boolean
    return (ut == 'h03C' or ut == 'h03D' or ut == 'h03E' or ut == 'h03F' or ut == 'h03G' or ut == 'h03H')
  endfunction
  //////////
  constant function isDemonTower takes integer ut returns boolean
    return (ut == 'h009' or ut == 'h016' or ut == 'h017' or ut == 'h018' or ut == 'h019' or ut == 'h01A')
  endfunction
  //////////
  constant function isChemicalTower takes integer ut returns boolean
    return (ut == 'h001' or ut == 'h00R' or ut == 'h00S' or ut == 'h00T' or ut == 'h00U' or ut == 'h00V')
  endfunction
  //////////
  constant function isSwarmTower takes integer ut returns boolean
    return (ut == 'h00D' or ut == 'h00H' or ut == 'h01G' or ut == 'h01H' or ut == 'h01J' or ut == 'h01I')
  endfunction
  //////////
  constant function isTeslaCoil takes integer ut returns boolean
    return (ut == 'h002' or ut == 'h00A' or ut == 'h00N' or ut == 'h00O' or ut == 'h00P' or ut == 'h00Q')
  endfunction
  //////////
  constant function isVineTrap takes integer ut returns boolean
    return (ut == 'h01S' or ut == 'h01T' or ut == 'h01U' or ut == 'h01V' or ut == 'h01W' or ut == 'h01X')
  endfunction
  //////////
  constant function isDarkTower takes integer ut returns boolean
    return (ut == 'h00F' or ut == 'h02V' or ut == 'h02W' or ut == 'h02X' or ut == 'h02Y' or ut == 'h02Z')
  endfunction
  //////////
  constant function isPyroTrap takes integer ut returns boolean
    return (ut == 'h00G' or ut == 'h00I' or ut == 'h02R' or ut == 'h02S' or ut == 'h02T' or ut == 'h02U')
  endfunction
  //////////
  constant function isHolyTower takes integer ut returns boolean
    return (ut == 'h030' or ut == 'h031' or ut == 'h032' or ut == 'h033' or ut == 'h034' or ut == 'h035')
  endfunction
  //////////
  constant function isHeroTower takes integer ut returns boolean
    return (ut == 'H03J' or ut == 'h03K') //'H' and 'h' is on purpose
  endfunction
  //////////
  constant function isTsunamiTower takes integer ut returns boolean
    return (ut == 'h03I' or ut == 'h03L' or ut == 'h03M' or ut == 'h03N' or ut == 'h03O' or ut == 'h03P')
  endfunction
  //////////
  constant function isArrowTowerFire takes integer ut returns boolean
    return (ut == 'h00B' or ut == 'h00E' or ut == 'h00K' or ut == 'h00L' or ut == 'h00M')
  endfunction
  //////////
  constant function isArrowTowerNature takes integer ut returns boolean
    return (ut == 'h03R' or ut == 'h03S' or ut == 'h03T' or ut == 'h03U' or ut == 'h03V')
  endfunction
  //////////
  constant function isArrowTowerWater takes integer ut returns boolean
    return (ut == 'h03W' or ut == 'h03X' or ut == 'h03Y' or ut == 'h03Z' or ut == 'h040')
  endfunction
  //////////
  constant function isPhilosopherTower takes integer ut returns boolean
    return (ut == 'h048' or ut == 'h049' or ut == 'h04A' or ut == 'h04B' or ut == 'h04C' or ut == 'h04D')
  endfunction
  //////////
  constant function isTreeTower takes integer ut returns boolean
    return (ut == TOWER_TYPE_TREE_1 or ut == TOWER_TYPE_TREE_2 or ut == TOWER_TYPE_TREE_3 or ut == TOWER_TYPE_TREE_4 or ut == TOWER_TYPE_TREE_5 or ut == TOWER_TYPE_TREE_6)
  endfunction
  //////////
  constant function isDevourTower takes integer ut returns boolean
    return (ut == 'h04P')
  endfunction
  
  //////////
  //////////
  //////////
  constant function isGenerator takes integer ut returns boolean
    return (isWaterWheel(ut) or isFurnace(ut) or isGraveyard(ut) or isMoonwell(ut) or isMagicStone(ut))
  endfunction
  //////////
  constant function isCombatTower takes integer ut returns boolean
    return (not isBridgingTower(ut) and not isGenerator(ut))
  endfunction
  
  
  constant function StoneOfWin takes nothing returns unit
    return gg_unit_h042_0041
  endfunction
  //////////
  constant function isStoneOfWin takes unit u returns boolean
    return u == StoneOfWin()
  endfunction

endlibrary
