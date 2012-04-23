///////////////////////////////////////////////////////////////////////////
// This structure represents a power tower.
//
// USES:
//   - Defender structure
//   - Runner structure
//   - Multiboard structure
//   - General library
//   - Special library
//   - TowerTransfer Structure
//
// USED BY:
//   - Multiboard structure
//   - Defender structure
//   - Remorse structure
//   - Help structure
//   - Runner structure
//   - TowerTransfer Structure
//
// NOTES:
//   - Correctness: can't create malformed towers
//   - Storage: keeps track of allocated structures
//   - Uniqueness: one structure per real tower
//   - Custom data: assumes unit custom value is not modified elsewhere
///////////////////////////////////////////////////////////////////////////
globals
  constant real VAL_TRANSFER_RANGE = 400 //note: must also be set in transfer ability properties
  constant real VAL_TRANSFER_LONGRANGE = 1200 //note: must also be set in transfer ability properties
  constant integer VAL_MAX_TOWER_TRANSFERS = 8 //note: must also be set in transfer ability tool tips
  constant real VAL_FURNACE_FUEL_PERIOD = 7.5
  constant integer VAL_FURNACE_FUEL_RANGE = 2
  constant real VAL_WATER_BURST_RANGE = 360
  constant real MAX_WATER_BURST_TARGETS = 5
endglobals

struct Tower
  //! runtextmacro StructAlloc("Tower")

  //properties
  readonly location p
  readonly integer ut //unit type
  readonly integer at //ability type
  readonly integer maxEnergy
  readonly integer transferPower
  readonly integer level
  readonly boolean generating = false
  readonly integer skillRecord = 0
  private real tintingRed = 1.0
  private real tintingBlue = 1.0
  private real tintingGreen = 1.0

  //transfering
  public boolean isTransferingLong = false
  readonly integer numTransfersOut = 0
  readonly integer numTransfersIn = 0
  readonly TowerTransfer array transfersOut[VAL_MAX_TOWER_TRANSFERS]
  readonly TowerTransfer array transfersIn[VAL_MAX_TOWER_TRANSFERS]
  readonly integer lastEnergy = 0
  private integer totalReceived = 0
  private integer totalLastReceived = 0

  ////////
  public static method init0 takes nothing returns boolean
    call Events.registerForDeath(function Tower.catchDeath)
    call Events.registerForTick(function Tower.catchTick)
    call Events.registerForAttack(function Tower.catchAttack)
    call Events.registerForFinishedBuild(function Tower.catchFinishBuild)
    call Events.registerForStartedBuild(function Tower.catchStartBuild)
    call Events.registerForMaxManaChange(function Tower.catchMaxManaChange)
    call Events.registerForImproved(function Tower.catchUpgrade)
    call Events.registerForStartingAbility(function Tower.catchStartingAbility)
    call Events.registerForCastingAbility(function Tower.catchCastingAbility)
    call Events.registerForLearnAbility(function Tower.catchLearn)
    call Events.registerForChannelingAbility(function Tower.catchChannelingAbility)
    call Events.registerForNewTicker(VAL_FURNACE_FUEL_PERIOD, function Tower.catchFurnaceTick)

    return true
  endmethod
  //! runtextmacro Init("Tower")

  //////////
  // Creates a tower structure for a given unit
  // u = the tower unit
  // return = the tower structure
  //////////
  public static method create takes unit u, integer startingLevel returns Tower
    local Tower t
    local integer abilId
    // for furnacetest
    local real x
    local real y
    local integer tile
	
	call debugMsg("creating tower object", DEBUG)
    
    if (u == null) then
      return nill
    elseif (GetUnitTypeId(u) == 'h006') then
      return nill //don't bother with arrow towers; they don't need it
    elseif (Tower.fromUnit(u) != nill) then
      call showMessage("Map Error: tried to wrap a tower unit with a Tower structure twice")
      return nill
    elseif (startingLevel < 1) then
      call showMessage("Map Error: tried to wrap a tower with non-positive level")
      return nill
    endif
    
    // protections for noobs, furnace only can build on
    // grass and highgrass
    if(isFurnace(GetUnitTypeId(u))) then
      set x = GetUnitX(u)
      set y = GetUnitY(u)
      set tile = GetTerrainType(x, y)
    
      if(tile != TILE_GRASSY_DIRT and tile != TILE_GRASS and tile != TILE_DARK_GRASS) then
        call AdjustPlayerStateBJ(GetUnitFoodMade(u), GetOwningPlayer(u), PLAYER_STATE_RESOURCE_GOLD)
        call showUnitText(u, "Build on grass!", 100, 80, 0)
        call RemoveUnit(u)
        return nill
      endif
    // u can build moonwell only at the hill
    elseif(isMoonwell(GetUnitTypeId(u))) then
      set x = GetUnitX(u)
      set y = GetUnitY(u)
      
      if(GetTerrainCliffLevel(x, y) < 4) then
        call AdjustPlayerStateBJ(GetUnitFoodMade(u), GetOwningPlayer(u), PLAYER_STATE_RESOURCE_GOLD)
        call showUnitText(u, "Need to build higher!", 100, 80, 0)
        call RemoveUnit(u)
        return nill
      endif
    // waterwheel dont buildable on bridge
    elseif(isWaterWheel(GetUnitTypeId(u))) then
      if(RectContainsUnit(gg_rct_Water_Wheel, u)) then
        call showUnitText(u, "Build at beach!", 100, 80, 0)
        call RemoveUnit(u)
        return nill
      endif
    endif

	set t = Tower.alloc(u)

    //set values
    set t.p = GetUnitLoc(u)
    set t.level = startingLevel
    call t.updateProperties()
    if (isGenerator(t.ut)) then
      set t.generating = true
    endif

    //per tower stuff
    //if (t.isArrowTowerFire()) then
    //  set t.tintingBlue = 0.2
    //  set t.tintingGreen = 0.2
    //elseif (t.isArrowTowerWater()) then
    //  set t.tintingRed = 0.2
    //  set t.tintingGreen = 0.2
    //elseif (t.isArrowTowerNature()) then
    //  set t.tintingRed = 0.2
    //  set t.tintingBlue = 0.2
    //endif

    //place in global array
    
    call t.draw()
    return t
  endmethod

  public method removeAllConnections takes nothing returns nothing
    //destroy incoming and outgoing transfers
    loop
      exitwhen this.numTransfersIn <= 0
      call this.transfersIn[this.numTransfersIn].destroy()
    endloop
    loop
      exitwhen this.numTransfersOut <= 0
      call this.transfersOut[this.numTransfersOut].destroy()
    endloop
  endmethod
  
  //////////
  private method onDestroy takes nothing returns nothing
    if (this == nill) then
      return
    endif

	call this.removeAllConnections()

    //destroy other stuff
    call RemoveLocation(this.p)
    set this.p = null
   
    //remove from global array
	call this.dealloc()
  endmethod

  //////////
  public method upgrade takes nothing returns nothing
    if (this == nill) then
      return
    endif

    set this.level = this.level + 1
    call this.updateProperties()
  endmethod
  //////////
  // Reads unit properties and stores them
  //////////
  public method updateProperties takes nothing returns boolean
    if (this == nill) then
      return false
    endif

    set this.ut = GetUnitTypeId(this.u)
    set this.maxEnergy = R2I(GetUnitStateSwap(UNIT_STATE_MAX_MANA, this.u))
    set this.transferPower = GetUnitPointValue(this.u)
    if (isRockLauncher(this.ut)) then
      set this.at = 'A004' //boost
    elseif (isChemicalTower(this.ut)) then
      set this.at = 'A00A' //chemicals
    elseif (isDemonTower(this.ut)) then
      set this.at = 'A009' //flame
    elseif (isLichTower(this.ut)) then
      set this.at = 'A00D' //frost
    elseif (isTeslaCoil(this.ut)) then
      set this.at = 'A001' //lightning
    elseif (isSwarmTower(this.ut)) then
      set this.at = 'A008' //spawn
    elseif (isVineTrap(this.ut)) then
      set this.at = 'A00E' //entangle
    elseif (isPyroTrap(this.ut)) then
      set this.at = ABIL_BLAZE
    elseif (isDarkTower(this.ut)) then
      set this.at = 'A00G' //despair
    elseif (isHolyTower(this.ut)) then
      set this.at = 'A00K' //lightwave
    elseif (isClockTower(this.ut)) then
      set this.at = 'A00J' //Time Distortion
    elseif (isPhilosopherTower(this.ut)) then
      set this.at = ABIL_TRANSMUTE
    elseif (isTreeTower(this.ut)) then
      set this.at = 'A00W'
    elseif (isDevourTower(this.ut)) then
      set this.at = 'A015'
    elseif (isTsunamiTower(this.ut)) then
      set this.at = ABIL_WATER_BURST
    //elseif (this.isArrowTowerFire()) then
    //  set this.at = ABIL_ELEMENTAL_FIRE
    //elseif (this.isArrowTowerNature()) then
    //  set this.at = ABIL_ELEMENTAL_NATURE
    //elseif (this.isArrowTowerWater()) then
    //  set this.at = ABIL_ELEMENTAL_WATER
    else
      set this.at = nill
    endif
    if (this.at != nill) then
      call SetUnitAbilityLevelSwapped(this.at, this.u, this.level)
    endif

    return true
  endmethod

  //////////
  // Records or learns skills
  // at = skill to record having learned
  // skillRecord = record of skills to learn
  //////////
  public method recordSkillLearning takes integer at, integer skillRecord returns nothing
    if (this == nill) then
      return
    endif

    //record
    if (at == 'A00M') then //blizzard
      set this.skillRecord = this.skillRecord + 16
    elseif (at == 'A00H') then //storm bolt
      set this.skillRecord = this.skillRecord + 4
    elseif (at == 'A00O') then //crit strike
      set this.skillRecord = this.skillRecord + 1
    endif

    //learn
    loop
      exitwhen skillRecord <= 0
      if (skillRecord >= 64) then //none
        set at = 0
        set skillRecord = skillRecord - 64

      elseif (skillRecord >= 16) then
        set at = 'A00M' //blizzard
        set skillRecord = skillRecord - 16

      elseif (skillRecord >= 4) then
        set at = 'A00H' //storm bolt
        set skillRecord = skillRecord - 4

      elseif (skillRecord >= 1) then
        set at = 'A00O' //crit strike
        set skillRecord = skillRecord - 1

      endif
      if (at > 0) then
        call SelectHeroSkill(this.u, at)
      endif
    endloop
  endmethod

  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  //////////
  public method hasLongTransfer takes nothing returns boolean
    return this.isTransferingLong
  endmethod
  
  public method getEnergy takes nothing returns integer
    if (this == nill) then
      return 0
    endif
    return R2I(GetUnitStateSwap(UNIT_STATE_MANA, this.u))
  endmethod
  //////////
  public method getNeededEnergy takes nothing returns integer
    if (this == nill) then
      return 0
    endif
    return imin(this.maxEnergy-this.getEnergy(), this.transferPower-this.totalReceived)
  endmethod  
    
  //////////
  private method checkMoonwell takes nothing returns nothing
    if(isNight()) then
      if(not(this.generating)) then
        set this.generating = true
      endif
    else
      if(this.generating) then
        set this.generating = false
      endif
    endif
  endmethod
  //////////
  public method getGeneratedPower takes nothing returns integer
    //local integer p
    if (this == nill) then
      return 0
    endif
    
    if (isMagicStone(this.ut)) then
      return 1 + R2I(I2R(this.totalLastReceived) * 0.1)
    endif
    
    if (isMoonwell(this.ut)) then
      call this.checkMoonwell()
    endif
    
    if (isGraveyard(this.ut)) then
      return 0
    endif
    
    if(not(this.generating)) then
      return 0
    endif
    
    return this.transferPower/2
  endmethod
  //////////
  public method getEstimatedDrain takes nothing returns integer
    if (this == nill or isCombatTower(this.ut) == false) then
      return 0
    endif
    return this.transferPower/2
  endmethod
  //////////
  public method getEstimatedProduction takes nothing returns integer
    if (this == nill) then
      return 0
    endif
    return this.getGeneratedPower()
  endmethod

  //=====================================
  //=== MUTATERS ========================
  //=====================================
  //////////
  // Inserts a TowerTransfer into the correct transfer list
  //////////
  public method insertTransfer takes TowerTransfer tt returns boolean
    local integer i
    if (tt == nill) then
      return false
    endif

    //add to out transfers if this is the source
    if (tt.src == this) then
      //check if already in list
      set i = 1
      loop
        exitwhen i > this.numTransfersOut
        if (this.transfersOut[i] == tt) then
          return false
        endif
        set i = i + 1
      endloop
      //add to list
      set this.numTransfersOut = this.numTransfersOut + 1
      set this.transfersOut[this.numTransfersOut] = tt
      return true
    endif

    //add to in transfers if this is the destination
    if (tt.dst == this) then
      //check if already in list
      set i = 1
      loop
        exitwhen i > this.numTransfersIn
        if (this.transfersIn[i] == tt) then
          return false
        endif
        set i = i + 1
      endloop
      //add to list
      set this.numTransfersIn = this.numTransfersIn + 1
      set this.transfersIn[this.numTransfersIn] = tt
      return true
    endif

    return false
  endmethod
  //////////
  // Removes a TowerTransfer from the correct transfer list
  //////////
  public method removeTransfer takes TowerTransfer tt returns boolean
    local integer i
    if (tt == nill) then
      return false
    endif

    //Remove from out transfers if this is the source
    if (this == tt.src) then
      set i = 1
      loop
        exitwhen i > this.numTransfersOut
        if (this.transfersOut[i] == tt) then
          set this.transfersOut[i] = this.transfersOut[this.numTransfersOut]
          set this.transfersOut[this.numTransfersOut] = nill
          set this.numTransfersOut = this.numTransfersOut - 1
          return true
        endif
        set i = i + 1
      endloop
    endif

    //Remove from in transfers if this is the destination
    if (this == tt.dst) then
      set i = 1
      loop
        exitwhen i > this.numTransfersIn
        if (this.transfersIn[i] == tt) then
          set this.transfersIn[i] = this.transfersIn[this.numTransfersIn]
          set this.transfersIn[this.numTransfersIn] = nill
          set this.numTransfersIn = this.numTransfersIn - 1
          return true
        endif
        set i = i + 1
      endloop
    endif

    return false
  endmethod

  //////////
  public method setEnergy takes integer e returns nothing
    if (this == null) then
      return
    endif
    
    if (e > this.maxEnergy) then
      set e = this.maxEnergy
    endif
    call SetUnitManaBJ(this.u, e)
  endmethod
  //////////
  public method adjustEnergy takes integer de returns nothing
    if (this == null) then
      return
    endif
    call this.setEnergy(this.getEnergy() + de)
  endmethod
  //////////
  // Receive energy from another tower
  // Guarantees receiving transfer power is not exceeded
  //////////
  public method receiveEnergy takes integer e returns integer
    if (e < 0 or this == null) then
      return 0
    endif

    if (this.transferPower - this.totalReceived < e) then
      set e = this.transferPower - this.totalReceived
    endif
    set this.totalReceived = this.totalReceived + e
    call this.adjustEnergy(e)

    return e
  endmethod
  //////////
  public method replaceUnit takes integer ut, boolean holdEnergie returns nothing
    local player p
    local boolean b
    if (this == null or ut == nill) then
      return
    endif

    //replace the tower without screwing player selection up
    set p = GetOwningPlayer(this.u)
    set b = IsUnitSelected(this.u, p)
    set this.u = ReplaceUnitBJ(this.u, ut, bj_UNIT_STATE_METHOD_ABSOLUTE)
    call SetUnitUserData(this.u, this.allocIndex)
    if(holdEnergie) then
      call this.setEnergy(this.lastEnergy)
    else
      call this.setEnergy(0)
    endif
    if (b == true) then
      call SelectUnitAddForPlayer(this.u, p)
    endif

    call this.updateProperties()
  endmethod
  
  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  //////////
  // Transfers energy to other towers
  // SIDE-EFFECTS: modifies "totalReceived" of targets
  //////////
  public method transferEnergy takes nothing returns nothing
    local integer i
    local integer e
    local integer n
    local TowerTransfer tt
    if (this == null) then
      return
    endif

    //iteratively sort the transfer list to favor needy towers
    set i = 1
    loop
      exitwhen i > this.numTransfersOut-1
      if (this.transfersOut[i].dst.getNeededEnergy() >= this.transfersOut[i+1].dst.getNeededEnergy()) then
        //swap
        set tt = this.transfersOut[i]
        set this.transfersOut[i] = this.transfersOut[i+1]
        set this.transfersOut[i+1] = tt
      endif
      set i = i + 1
    endloop

    //transfer energy out
    set i = 1
    set n = this.numTransfersOut
    set e = imin(this.transferPower, this.lastEnergy)
    loop
      exitwhen i > this.numTransfersOut
      set e = e - this.transfersOut[i].transferEnergy(e / n)
      set n = n - 1
      set i = i + 1
    endloop
  endmethod

  //////////
  // Displays information about state
  //////////
  public method draw takes nothing returns nothing
    local real r
    local Defender d
    local force f
    local integer de
    local integer i
    if (this == null) then
      return
    endif

    //get change in mana and reset values
    set de = this.getEnergy() - this.lastEnergy
    set this.lastEnergy = this.getEnergy()

    //show floating text
    if(isTreeTower(this.ut) or isStoneOfWin(this.u)) then
      //show for tower with negativ mana regeneration
      if(isStoneOfWin(this.u)) then
        set f = GetPlayersAll()        
      else
        set f = GetForceOfPlayer(GetOwningPlayer(this.u))
      endif
      
      if (de > 0) then
        call showUnitTextForce(this.u, I2S(this.totalReceived), 0, 100, 0, f)
      elseif(this.totalReceived != 0) then
        call showUnitTextForce(this.u, I2S(this.totalReceived), 100, 0, 0, f)
      elseif(this.lastEnergy != 0) then
        call showUnitTextForce(this.u, I2S(de), 80, 0, 100, f)
      endif
      
      if(not isStoneOfWin(this.u)) then
        call DestroyForce(f)
      endif
      set f = null

    else
      //show for normal tower
      if (de > 0) then
        call showUnitText(this.u, "+" + I2S(de), 0, 0, 100)
      elseif (de < 0) then
        call showUnitText(this.u, I2S(de), 80, 0, 100)
      elseif (this.lastEnergy == 0 and isCombatTower(this.ut)) then
        call showUnitText(this.u, "0", 100, 0, 0)
      endif
    endif
    
    set this.totalLastReceived = this.totalReceived
    set this.totalReceived = 0
    
    // check for full energie
    if((this.maxEnergy * 0.98) <= this.getEnergy()) then
    
      // trigger wild tree groth
      if(isTreeTower(this.ut) and this.level < 6) then
        set this.level = this.level + 1
        if(this.level == 2) then
          call this.replaceUnit(TOWER_TYPE_TREE_2, false)
        elseif(this.level == 3) then
          call this.replaceUnit(TOWER_TYPE_TREE_3, false)
        elseif(this.level == 4) then
          call this.replaceUnit(TOWER_TYPE_TREE_4, false)
        elseif(this.level == 5) then
          call this.replaceUnit(TOWER_TYPE_TREE_5, false)
        else
          call this.replaceUnit(TOWER_TYPE_TREE_6, false)
        endif
        call createBang(this.p, "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl")
        call createBang(this.p, "Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl")

      /////////////////////////////////
      // handel the wincondition of StoneOfWin!
      /////////////////////////////////
      elseif (isStoneOfWin(this.u)) then
        if(Game.gameStyle == VAL_GAME_STYLE_STONE_OF_WIN and Game.state != VAL_GAME_STATE_OVER) then
          set Game.state = VAL_GAME_STATE_STONEWIN
          call Game.exec_checkForGameOver()
        endif
      endif
      /////////////////////////////////
      /////////////////////////////////
    endif

    //darken/brighting the tower based on energy level
    if(not(isTreeTower(this.ut)) and not(isGenerator(this.ut)) and not(isPhilosopherTower(this.ut)) and not isStoneOfWin(this.u)) then
      if (this.maxEnergy > 0) then
        set r = I2R(this.getEnergy()) / this.maxEnergy
        set r = r*75 + 25
        call SetUnitVertexColorBJ(this.u, r*this.tintingRed, r*this.tintingGreen, r*this.tintingBlue, 0)
      endif
    endif
  endmethod

  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////
  private static method catchStartBuild takes nothing returns nothing
    call Tower.create(GetTriggerUnit(), 1) //level 1
  endmethod

  //////////
  private static method catchUpgrade takes nothing returns nothing
    local Tower t = Tower.fromUnit(GetTriggerUnit())
    local integer ut = GetUnitTypeId(GetTriggerUnit())
    if (t == nill) then
      //if (ut == 'h00B' or ut == 'h03W' or ut == 'h03R') then //arrow tower elements level 2
      //  set t = Tower.create(GetTriggerUnit(), 1)
      //endif
    endif
    call t.upgrade()
    call IssueImmediateOrderBJ(t.u, "stop") //avoid lock-up
  endmethod

  //////////
  // When max mana changes, it scales mana: this function undoes that scaling.
  //////////
  private static method catchMaxManaChange takes nothing returns nothing
    local Tower t = Tower.fromUnit(GetTriggerUnit())
    if (t != null) then
      call t.setEnergy(t.lastEnergy)
    endif
  endmethod

  //////////
  // Causes furnaces to burn nearby grass for fuel
  //////////
  private static method catchFurnaceTick takes nothing returns nothing
    local Tower t
    local integer i = 1
    loop
      exitwhen i > Tower.numAllocated
      set t = Tower.allocs[i]
      if (isFurnace(t.ut)) then
        // the furnace should not burn grass if full of energy
        if((t.maxEnergy * 0.98) > t.getEnergy()) then
          set t.generating = burnNearbyGrass(t.p)
          if (t.generating == false) then
            call showUnitText(t.u, "No Grass", 100, 0, 0)
          endif
        endif
      endif
      set i = i + 1
    endloop
  endmethod

  //////////
  // Generators only start producing when they have finished building
  //////////
  private static method catchFinishBuild takes nothing returns nothing
    local Tower t = Tower.fromUnit(GetTriggerUnit())
    if (isGenerator(t.ut)) then
      set t.generating = true
      call SetPlayerTechResearchedSwap('R000', 1, GetOwningPlayer(t.u)) //Built a Generator
    elseif (isHeroTower(t.ut)) then
      call t.replaceUnit('H03J', true) //replace hero tower (building) with real hero tower
      call CreateUnitAtLoc(GetOwningPlayer(t.u), 'h03Q', t.p, bj_UNIT_FACING) //add pathing tower
    endif
  endmethod

  //////////
  // Handle tower deaths
  //////////
  private static method catchDeath takes nothing returns nothing
    local unit u
    local group g
    local integer costReturned
    local boolean hasNoDeathAnimation
    local Tower t

    //refund cost
    set u = GetTriggerUnit()
    set costReturned = R2I(GetUnitFoodMade(u) * VAL_GAME_SELL_PERCENT)
    if (costReturned > 0) then
      call AdjustPlayerStateBJ(costReturned, GetOwningPlayer(u), PLAYER_STATE_RESOURCE_GOLD)
      call showUnitText(u, "+" + I2S(costReturned), 100, 80, 0)
    endif
    set u = null

    set t = Tower.fromUnit(GetTriggerUnit())
    if (t != null) then
      //Remove 'fake' towers
      set g = GetUnitsInRangeOfLocAll(50.00, t.p)
      loop
        set u = FirstOfGroup(g)
        exitwhen u == null
        call GroupRemoveUnit(g, u)
        if (GetUnitTypeId(u) == 'h03Q') then //hero tower (pathing)
          call RemoveUnit(u)
        endif
      endloop
      call DestroyGroup(g)
      set g = null

      //create death animation for towers with none
      set hasNoDeathAnimation = false
      if (t.ut == 'h003' or t.ut == 'h007'or t.ut == 'h008' or t.ut == 'h03I' or t.ut == 'h03E') then
        //bridging towers 1-3, tsunami 1, clock 3
        set hasNoDeathAnimation = true
      elseif (isVineTrap(t.ut) or isPyroTrap(t.ut)) then
        set hasNoDeathAnimation = true
      endif
      if (hasNoDeathAnimation == true) then
        call createBang(t.p, "Abilities\\Weapons\\Mortar\\MortarMissile.mdl")
        call RemoveUnit(t.u)
      endif

      call t.destroy()
    endif
  endmethod

  //////////
  // Updates all towers by one second
  //////////
  private static method catchTick takes nothing returns nothing
    local integer i
    local Tower t

    //generate
    set i = 1
    loop
      exitwhen i > Tower.numAllocated
      set t = Tower.allocs[i]
      
      if (t.generating == true) then
        call t.adjustEnergy(t.getGeneratedPower())
      endif
      set i = i + 1
    endloop

    //transfer energy
    set i = 1
    loop
      exitwhen i > Tower.numAllocated
      call Tower.allocs[i].transferEnergy()
      set i = i + 1
    endloop

    //draw (calculates defender stats and resets for next tick)
    set i = 1
    loop
      exitwhen i > Tower.numAllocated
      call Tower.allocs[i].draw()
      set i = i + 1
    endloop

    //finish
    call Multiboard.update()
  endmethod

  //////////
  // Automates the casting of tower abilities
  //////////
  private static method catchAttack takes nothing returns nothing
    call Tower.fromUnit(GetAttacker()).exec_catchAttack.execute(Runner.fromUnit(GetAttackedUnitBJ()))
  endmethod
  private method exec_catchAttack takes Runner r returns nothing
    local integer i
    local Tower t
    if (this == nill or r == nill) then
      return
    endif

    if (isTeslaCoil(this.ut)) then
      set i = 1
      loop
        exitwhen i > Tower.numAllocated
        set t = Tower.allocs[i]
        if (isTeslaCoil(t.ut)) then
          call IssueTargetOrderBJ(t.u, "chainlightning", r.u)
          call IssueTargetOrderBJ(t.u, "chainlightning", this.u)
        endif
        set i = i + 1
      endloop
      
    elseif (isDevourTower(this.ut)) then
      call IssueTargetOrderBJ(this.u, "chainlightning", r.u)
    elseif (isLichTower(this.ut)) then
      call IssueTargetOrderBJ(this.u, "frostnova", r.u)
    elseif (isChemicalTower(this.ut)) then
      call IssueTargetOrderBJ(this.u, "shadowstrike", r.u)
    elseif (isVineTrap(this.ut)) then
      call IssueTargetOrderBJ(this.u, "entanglingroots", r.u)
      //pacify runner to avoid attacks due to stun
      set r.pacified = true
      set i = 8
      loop
        exitwhen i <= 0
        call TriggerSleepAction(0.5)
        call r.orderToWaypoint()
        set i = i - 1
      endloop
      set r.pacified = false
    elseif (isSwarmTower(this.ut)) then
      call IssueImmediateOrderBJ(this.u, "waterelemental")
    elseif (isRockLauncher(this.ut)) then
      if (UnitHasBuffBJ(this.u, BUFF_BOOSTED) == false) then
        call TriggerSleepAction(0.3) //don't interrupt attack
        call IssueImmediateOrderBJ(this.u, "berserk") //boost
        call doEvents()
        call IssueImmediateOrderBJ(this.u, "stop") //avoid lock-up
      endif
    elseif (isDarkTower(this.ut)) then
      call IssueTargetOrderBJ(this.u, "innerfire", r.u)
    //elseif (isArrowTowerFire(this.u) or this.isArrowTowerNature() or this.isArrowTowerWater()) then
    //  call IssueTargetOrderBJ(this.u, "cripple", r.u)
    elseif (isPyroTrap(this.ut)) then
      call IssuePointOrder(this.u, "flamestrike", GetUnitX(this.u), GetUnitY(this.u))
    elseif (isHolyTower(this.ut)) then
      call IssuePointOrder(this.u, "carrionswarm", GetUnitX(r.u), GetUnitY(r.u))
    elseif (isTsunamiTower(this.ut)) then
      call IssueImmediateOrderBJ(this.u, "thunderclap")
    endif
  endmethod

  //////////
  // Abilities
  //////////
  
  private static method catchStartingAbility takes nothing returns nothing
    call Tower.fromUnit(GetTriggerUnit()).exec_catchStartingAbility.execute(GetTriggerUnit(), GetSpellAbilityId())
  endmethod
  
  private static method catchChannelingAbility takes nothing returns nothing
    call Tower.fromUnit(GetTriggerUnit()).exec_catchChannelingAbility.execute(GetTriggerUnit(), GetSpellAbilityId())
  endmethod
  
  private method exec_catchStartingAbility takes unit u, integer at returns nothing
    local location p
    local integer gold

    if (at == ABIL_SELL) then
      call doEvents() //needed for death animation
      call KillUnit(u)
      set u = null

    elseif (at == ABIL_ADD_TRANSFER) then
      call TowerTransfer.create(this, Tower.fromUnit(GetSpellTargetUnit()))
      
    elseif (at == ABIL_ADD_LONGTRANSFER) then
      call TowerTransfer.createlong(this, Tower.fromUnit(GetSpellTargetUnit()))

    elseif (at == ABIL_REMOVE_TRANSFER) then
      call TowerTransfer.fromSrcDst(this, Tower.fromUnit(GetSpellTargetUnit())).destroy()

    elseif (at == ABIL_SHOW_RANGES) then
      set p = GetUnitLoc(u)

      //Attack Range
      call createCircleEffect(p, GetUnitDefaultAcquireRange(u), "Doodads\\Cinematic\\GlowingRunes\\GlowingRunes0.mdl")

      //Transfer Range
      if (isBridgingTower(this.ut) or isGenerator(this.ut)) then
	    if (isBridgingTower(this.ut)) then
		  call createCircleEffect(p, VAL_TRANSFER_LONGRANGE, "Doodads\\Cinematic\\GlowingRunes\\GlowingRunes6.mdl")
		endif
        call createCircleEffect(p, VAL_TRANSFER_RANGE, "Doodads\\Cinematic\\GlowingRunes\\GlowingRunes6.mdl")
	  endif
	  
      call RemoveLocation(p)
      set p = null
    endif
  endmethod
  
  private static method catchCastingAbility takes nothing returns nothing
    local integer at = GetSpellAbilityId()
    local location p
    local group g
    local unit u
    local integer n
    local Tower t
    local real d
    local string s
    local integer gold

    if (at == ABIL_WATER_BURST) then
      //get targets
      set t = Tower.fromUnit(GetTriggerUnit())
      if (t == nill) then
        call showMessage("Map Error: tsunami cast by non-wrapped unit.")
        return
      endif
      set g = GetUnitsInRangeOfLocMatching(VAL_WATER_BURST_RANGE, t.p, Condition(function Runner.filter_isRunner))
      set n = CountUnitsInGroup(g)

      //get damage
      if (t.level == 1) then
        set d = 60
      elseif (t.level == 2) then
        set d = 171.8
      elseif (t.level == 3) then
        set d = 385.0
      elseif (t.level == 4) then
        set d = 796.2
      elseif (t.level == 5) then
        set d = 1594.3
      elseif (t.level == 6) then
        set d = 3150.0
      else
        set d = 0
        call showMessage("Map Error: invalid tsunami level")
      endif
      if (n > MAX_WATER_BURST_TARGETS) then
        set d = d*MAX_WATER_BURST_TARGETS/n
      endif

      //deal damage
      loop
        set u = FirstOfGroup(g)
        call GroupRemoveUnit(g, u)
        exitwhen u == null
        call UnitDamageTargetBJ(t.u, u, d, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_UNIVERSAL)
      endloop
      call DestroyGroup(g)
      set g = null
      set u = null

      //show more effects to make the spell look better
      set p = OffsetLocation(t.p, -100, -100)
      call createBang(p, "Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl")
      call RemoveLocation(p)
      set p = OffsetLocation(t.p, 100, -90)
      call createBang(p, "Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl")
      call RemoveLocation(p)
      set p = OffsetLocation(t.p, -100, 100)
      call createBang(p, "Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl")
      call RemoveLocation(p)
      set p = OffsetLocation(t.p, 100, 100)
      call createBang(p, "Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl")
      call RemoveLocation(p)
      set p = null

    elseif (at == ABIL_ELEMENTAL_FIRE or at == ABIL_ELEMENTAL_WATER or at == ABIL_ELEMENTAL_NATURE) then
      //get stats
      set t = Tower.fromUnit(GetSpellAbilityUnit())
      if (t == nill) then
        call showMessage("Map Error: element cast by non-wrapped unit.")
        return
      endif
      set u = GetSpellTargetUnit()
      set n = R2I(10*(Pow(2, t.level)-1))
      set s = I2S(n)

      //get modifiers and show text
      if (at == ABIL_ELEMENTAL_WATER) then
        if (UnitHasBuffBJ(u, BUFF_ELEMENTAL_FIRE) == true) then
          set s = "DOUBLE " + s
          set n = n*2
        elseif (UnitHasBuffBJ(u, BUFF_ELEMENTAL_NATURE) == true) then
          set s = "HALF " + s
          set n = n/2
        endif
        call showUnitTextPlayer(u, s, 20, 20, 100, GetOwningPlayer(t.u))
      elseif (at == ABIL_ELEMENTAL_FIRE) then
        if (UnitHasBuffBJ(u, BUFF_ELEMENTAL_NATURE) == true) then
          set s = "DOUBLE " + s
          set n = n*2
        elseif (UnitHasBuffBJ(u, BUFF_ELEMENTAL_WATER) == true) then
          set s = "HALF " + s
          set n = n/2
        endif
        call showUnitTextPlayer(u, s, 100, 20, 20, GetOwningPlayer(t.u))
      elseif (at == ABIL_ELEMENTAL_NATURE) then
        if (UnitHasBuffBJ(u, BUFF_ELEMENTAL_WATER) == true) then
          set s = "DOUBLE " + s
          set n = n*2
        elseif (UnitHasBuffBJ(u, BUFF_ELEMENTAL_FIRE) == true) then
          set s = "HALF " + s
          set n = n/2
        endif
        call showUnitTextPlayer(u, s, 20, 100, 20, GetOwningPlayer(t.u))
      endif
      
      //apply
      call UnitRemoveBuffBJ(BUFF_ELEMENTAL_WATER, u)
      call UnitRemoveBuffBJ(BUFF_ELEMENTAL_FIRE, u)
      call UnitRemoveBuffBJ(BUFF_ELEMENTAL_NATURE, u)
      call UnitDamageTargetBJ(t.u, u, n, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL)
    
    elseif (at == ABIL_TRANSMUTE) then
      set t = Tower.fromUnit(GetTriggerUnit())
      if (t != null) then
        set gold = R2I(Pow(2, I2R(t.level - 1)))
        call AdjustPlayerStateBJ(gold, GetOwningPlayer(t.u), PLAYER_STATE_RESOURCE_GOLD)
        call showUnitTextPlayer(t.u, "+" + I2S(gold), 100, 80, 0, GetOwningPlayer(t.u))
        call AddSpecialEffectScaledWithTimer (GetUnitX(t.u), GetUnitY(t.u), 100, 2, "Abilities\\Spells\\Undead\\ReplenishHealth\\ReplenishHealthCasterOverhead.mdl", 1)
      endif
    
    elseif (at == ABIL_CONSUME_RUNNER) then
      set t = Tower.fromUnit(GetTriggerUnit())
      if (t != null) then
        call t.adjustEnergy(t.getGeneratedPower()*10*t.level)
        call createBang(t.p, "Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl")
      endif
      
    endif
  endmethod
  
  private method exec_catchChannelingAbility takes unit u, integer at returns nothing
    local location p
    local effect e

    if (at == ABIL_BLAZE) then
      //start the fire effect before spell is actually cast, to make initial damage point seem more sane
      set p = GetSpellTargetLoc()
      set e = AddSpecialEffectLocBJ(p, "Abilities\\Spells\\Human\\FlameStrike\\FlameStrike1.mdl")
      call PolledWait(5.00)
      call DestroyEffect(e)
      call RemoveLocation(p)
      set e = null
      set p = null
    endif
  endmethod

  //////////
  private static method catchLearn takes nothing returns nothing
    call Tower.fromUnit(GetTriggerUnit()).recordSkillLearning(GetLearnedSkillBJ(), 0)
  endmethod
endstruct
