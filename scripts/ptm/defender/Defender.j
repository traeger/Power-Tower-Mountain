///////////////////////////////////////////////////////////////////////////
// This structure represents a player.
//
// USES:
//   - Tower structure
//   - Game structure
//   - Events structure
//   - Multiboard structure
//   - General library
//   - Special library
//
// USED BY:
//   - almost everything
//
// ENFORCES:
//   - uniqueness: one defender structure per player
///////////////////////////////////////////////////////////////////////////
globals
  constant integer NUM_DEFENDERS = 8
  constant integer MAX_TIPS = 8

  constant integer ABIL_TRANSFORM = 'A002'
  constant integer ABIL_TRANSFORM_COMBAT = 'A011'
  constant integer ABIL_TRANSFORM_SUPPORT = 'A010'
  constant integer ABIL_TRANSFORM_SPECIAL = 'A00Z'
  constant real VAL_CAMTICKINTERVAL = 0.5
  constant real VAL_CAMSTDRANGE = 2196.15
  constant real VAL_CAMRANGEMIN = 700
  constant real VAL_CAMRANGEMAX = 4000
  constant real VAL_CAMRANGESTEP = 150
endglobals

struct Defender
  //! runtextmacro StructAlloc_Fixed("Defender", "NUM_DEFENDERS")
  //! runtextmacro StructIterable_Fixed("Defender", "NUM_DEFENDERS")
  readonly static real camStdRange

  readonly player p
  readonly boolean wasKilled = false
  readonly integer lives = 0
  readonly unit builder = null
  readonly real camRange
  
  readonly integer killedRunner = 0

  private integer array skills

  public static method init0 takes nothing returns nothing
    local integer i

    set i = 1
    loop
      exitwhen i > NUM_DEFENDERS
      call Defender.create(i)
      set i = i + 1
    endloop
    
    call Events.registerForPlayerLeft(function Defender.catchLeave)
    call Events.registerForStartingAbility(function Defender.catchStartAbility)
    call Events.registerForCastingAbility(function Defender.catchCastingAbility)
    call Events.registerForDeath(function Defender.catchWoodChange)
    call Events.registerForMaxManaChange(function Defender.catchWoodChange)
    call Events.registerForStartedBuild(function Defender.catchWoodChange)
    call Events.registerForCancelledBuild(function Defender.catchWoodChange)
    call Events.registerForTick(function Defender.catchWoodChange)
    //call Events.registerForEsc(function Defender.catchEsc)
    call Events.registerForItemSell(function Defender.catchItemSell)
  endmethod
  //! runtextmacro Init("Defender")

  ////////////
  //Creates and sets up a defender
  //i = the player index (1 = P1, 2 = P2, ...)
  //return = a defender
  ////////////
  private static method create takes integer i returns Defender
    local location c
    local Defender d
    
	set d = Defender.alloc(i)

    set d.p = Player(i-1)
    set d.camRange = VAL_CAMSTDRANGE
    set d.killedRunner = 0
    //PTM: map prot, killed cause the massage sucks
    //if (prep==false) then //show passwords (bet people remember these? :P)
    //  call showPlayerPassCode(d.p,"vz3333prrrexOKFKDsubEFPuJxMuExPuyBBKuJLAFCFBAtvO")
    //  call showPlayerPassCode(d.p,"vz3333prrrZIBxKuSBOPFLKPuxSxFIxyIBuxQvOuvz33333333PzRJBAFQtKBQvO")
    //endif

    //Setup alliances
    call SetPlayerAllianceStateBJ(d.p, VAL_RUNNERS_OWNER, bj_ALLIANCE_UNALLIED)
    call SetPlayerAllianceStateBJ(VAL_RUNNERS_OWNER, d.p, bj_ALLIANCE_UNALLIED)

    call SetPlayerAllianceStateBJ(d.p, Player(PLAYER_NEUTRAL_AGGRESSIVE), bj_ALLIANCE_ALLIED_UNITS)
    call SetPlayerAllianceStateBJ(Player(PLAYER_NEUTRAL_AGGRESSIVE), d.p, bj_ALLIANCE_ALLIED_UNITS)
    
    call SetPlayerStateBJ(d.p, PLAYER_STATE_RESOURCE_FOOD_CAP, 0)
    call SetPlayerStateBJ(d.p, PLAYER_STATE_FOOD_CAP_CEILING, 0)

    //Create starting stuff
    if (d.isDefending()) then
      call SetPlayerStateBJ(d.p, PLAYER_STATE_RESOURCE_GOLD, 30)
      set c = GetPlayerStartLocationLoc(d.p)
      set d.builder = CreateUnitAtLoc(d.p, 'u000', c, bj_UNIT_FACING) //builder (combat)
      //call UnitAddAbilityBJ('A00L', d.builder) //help
      call RemoveLocation(c)
      set c = null
    endif

    return d
  endmethod

  ////////////
  private method onDestroy takes nothing returns nothing
    call showMessage("Critical Map Error: Defender struct destroyed")
  endmethod

  ////////////
  public static method fromPlayer takes player p returns Defender
    if (p == null) then
      return nill
    endif
	return Defender.fromIndex(GetConvertedPlayerId(p))
  endmethod
  ////////////
  public static method fromUnit takes unit u returns Defender
    if (u == null) then
      return nill
    endif
    return Defender.fromPlayer(GetOwningPlayer(u))
  endmethod
  ////////////
  public static method fromString takes string s returns Defender
    local integer i
    local string array ss

    //colors
    set ss[1] = "red"
    set ss[2] = "blue"
    set ss[3] = "teal"
    set ss[4] = "purple"
    set ss[5] = "yellow"
    set ss[6] = "orange"
    set ss[7] = "green"
    set ss[8] = "pink"
    set ss[9] = "gray"
    set ss[10] = "light blue"
    set ss[11] = "dark green"
    set ss[12] = "brown"

    //check string against number/color/name
	set s = StringCase(s, false)
    //! runtextmacro for("i = 1", "i > NUM_DEFENDERS")
	  if (s == I2S(i) or s == ss[i] or s == StringCase(Defender.fromIndex(i).getName(), false)) then
        return Defender.fromIndex(i)
      endif
	//! runtextmacro endfor("i = i + 1")
	
    return nill
  endmethod

  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  ////////////
  public method isPresent takes nothing returns boolean
    if (this == null) then
      return false
    endif
    return (GetPlayerSlotState(this.p) == PLAYER_SLOT_STATE_PLAYING)
  endmethod
  ////////////
  public method isDefending takes nothing returns boolean
    if (this == null) then
      return false
    endif
    return (this.isPresent() and this.wasKilled == false)
  endmethod
  ////////////
  public static method activDefenderCount takes nothing returns integer
    local integer count = 0
	
	call Defender.iterate()
	loop
	  exitwhen Defender.iterateFinished()
	  if(Defender.next().isDefending()) then
	    set count = count + 1
	  endif
    endloop
	
    return count
  endmethod
  ////////////
  public static method getMainDefender takes nothing returns Defender
    local Defender d
	
	call Defender.iterate()
	loop
	  exitwhen Defender.iterateFinished()
	  set d = Defender.next()
	  if(d.isDefending()) then
	    call Defender.enditerate()
	    return d
	  endif
	endloop
	
    return nill
  endmethod
    ////////////
  public static method countLiveDefenders takes nothing returns integer
    local integer count = 0
	
	call Defender.iterate()
	loop
	  exitwhen Defender.iterateFinished()
	  if(Defender.next().isDefending()) then
	    set count = count + 1
	  endif
    endloop
	
	return count
  endmethod

  ////////////
  public method getColor takes nothing returns string
    local string s
    local integer i = 0
    if (this != null) then
      set i = this.allocIndex
    endif

    if (i == 1) then
      set s = "FF0303" //red
    elseif (i == 2) then
      set s = "0042FF" //blue
    elseif (i == 3) then
      set s = "1CE6B9" //teal
    elseif (i == 4) then
      set s = "540081" //purple
    elseif (i == 5) then
      set s = "FFFC01" //yellow
    elseif (i == 6) then
      set s = "FEBA0E" //orange
    elseif (i == 7) then
      set s = "20C000" //green
    elseif (i == 8) then
      set s = "FF00FF" //pink
    elseif (i == 9) then
      set s = "808080" //grey
    elseif (i == 10) then
      set s = "0080FF" //light blue
    elseif (i == 11) then
      set s = "008000" //dark green
    elseif (i == 12) then
      set s = "800000" //brown
    else
      set s = "FFFFFF" //white
    endif
    return "FF" + s
  endmethod
  ////////////
  public method getName takes nothing returns string
    if (this == null) then
      return ""
    endif
    return GetPlayerName(this.p)
  endmethod
  public method getNameWithColor takes nothing returns string
    if (this == null) then
      return ""
    endif
    return "|c" + this.getColor() + this.getName() + "|r"
  endmethod
  public method getTotalTowerValue takes nothing returns integer
    if (this == null) then
      return 0
    endif
    return GetPlayerState(this.p, PLAYER_STATE_RESOURCE_FOOD_CAP)
  endmethod

  public method getSkillLevel takes integer skill returns integer
    return this.skills[skill]
  endmethod

  public method setSkillLevel takes integer skill, integer mod returns integer
    if(mod < 0) then
      set this.skills[skill] = 0
    else
      set this.skills[skill] = mod
    endif
    return this.skills[skill]
  endmethod

  public method modSkillLevel takes integer skill, integer mod returns integer
    return this.setSkillLevel(this.getSkillLevel(skill) + mod)
  endmethod

  public method incSkillLevel takes integer skill returns integer
    return this.modSkillLevel(skill, 1)
  endmethod

  //=====================================
  //=== MUTATORS ========================
  //=====================================
  //////////
  // Sets the defender's initial amount of lives
  // note: trusts being called
  //////////
  public method setInitialLives takes integer d returns boolean
    if (this == nill) then
      return false
    elseif (Game.state != VAL_GAME_STATE_INTRO) then
      call showMessage("Map Error: Tried to set lives after start.")
      return false
    endif

    set this.lives = d
    call SetPlayerStateBJ(this.p, PLAYER_STATE_RESOURCE_FOOD_USED, this.lives)
    return true
  endmethod

  //////////
  // Causes the defender to lose a life
  // note: trusts being called
  //////////
  public method loseLife takes nothing returns boolean
    if (this == nill or this.lives <= 0) then
      return false
    endif

    set this.lives = this.lives - 1
    call SetPlayerStateBJ(this.p, PLAYER_STATE_RESOURCE_FOOD_USED, this.lives)
    if (this.lives <= 0) then
      call this.kill()
      if (this.isPresent()) then
        call showMessage(this.getNameWithColor() + " has been defeated.")
      endif
    endif
    return true
  endmethod
  //////////
  // NEED TO FIX -> replace items too
  //////////
  public method replaceUnit takes integer ut returns nothing
    local player p
    local boolean b
    if (this == null or ut == nill) then
      return
    endif

    //replace the builder without screwing player selection up
    set p = GetOwningPlayer(this.builder)
    set b = IsUnitSelected(this.builder, p)
    set this.builder = ReplaceUnitWithItems(this.builder, ut, bj_UNIT_STATE_METHOD_ABSOLUTE)
    if (b == true) then
      call SelectUnitAddForPlayer(this.builder, p)
    endif

  endmethod
  
  public method hasKilledRunner takes nothing returns nothing
    set this.killedRunner = this.killedRunner + 1
  endmethod

  ////////////
  //Removes a defender from play
  //USAGE: can only be called once per defender
  ////////////
  public method kill takes nothing returns nothing
    call this.exec_kill.execute()
  endmethod
  private method exec_kill takes nothing returns nothing
    local Defender d
	local group g
    local unit u
    local integer i
    local integer n
    local integer numAllies
    local integer valGold
    if (this == nill or this.wasKilled == true) then
      return
    endif

    //handle player
    call SetPlayerStateBJ(this.p, PLAYER_STATE_RESOURCE_GOLD, 0)
    set this.wasKilled = true
    set valGold = GetPlayerState(this.p, PLAYER_STATE_RESOURCE_GOLD)

    //handle gold
    set numAllies = Game.countDefenderAllies(this)
    if (numAllies > 0) then
      set n = numAllies
      
	  call Defender.iterate()
	  loop
	    exitwhen Defender.iterateFinished()
	    set d = Defender.next()
		if (d.isDefending()) then
          call AdjustPlayerStateBJ(valGold/n, d.p, PLAYER_STATE_RESOURCE_GOLD)
          set valGold = valGold - valGold/n
          set n = n - 1
        endif
	  endloop
    endif

    //handle towers
    set g = GetUnitsOfPlayerAll(this.p)
    set i = -1
    loop
      set u = GroupPickRandomUnit(g)
      exitwhen u == null
      if (numAllies > 0 and GetUnitTypeId(u) != 'u000') then //a tower we should give away
        loop
          set i = ModuloInteger(i + 1, NUM_DEFENDERS)
          exitwhen Defender.fromIndex(i).isDefending()
        endloop
        call SetUnitOwner(u, Defender.fromIndex(i).p, true)
      else
        call KillUnit(u)
      endif
      call GroupRemoveUnit(g, u)
    endloop
    call DestroyGroup(g)
    set g = null

    //handle runners
    if (numAllies == 0) then
      set i = Runner.numAllocated
      loop
        exitwhen i < 1
        call KillUnit(Runner.runners[i].u)
        set i = i - 1
      endloop
    endif

    call doEvents()
    call Multiboard.assignDefenderRows()
    call SetPlayerStateBJ(this.p, PLAYER_STATE_RESOURCE_GOLD, 0) //towers give gold when they die
    
    //Give time for end to sink in
    call DisplayTimedTextToPlayer(this.p, 0, 0, 25, "For |cff00ff00REMAKE|r join channel: |cffff0000POWER|r.")
  endmethod

  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////
  private static method catchLeave takes nothing returns nothing
    local Defender d = Defender.fromPlayer(GetTriggerPlayer())
    if (d != nill) then
      call showMessage(d.getNameWithColor() + " has left the game.")
      call d.kill()
    endif
  endmethod

  //////////
  // update lumber (total value of towers)
  //////////
  private static method catchWoodChange takes nothing returns nothing
    local Defender d
	
	call Defender.iterate()
	loop
	  exitwhen Defender.iterateFinished()
	  set d = Defender.next()
	  call SetPlayerStateBJ(d.p, PLAYER_STATE_RESOURCE_LUMBER, d.getTotalTowerValue())
	endloop
  endmethod

  //////////
  private static method catchStartAbility takes nothing returns nothing
    call Defender.fromUnit(GetTriggerUnit()).exec_catchStartAbility.execute(GetTriggerUnit(), GetSpellAbilityId())
  endmethod
  private method exec_catchStartAbility takes unit u, integer at returns nothing
    local effect e
    if (this == nill or u == null) then
      return
    endif

    if (at == ABIL_TRANSFORM_COMBAT) then
      call this.replaceUnit('u000')
      call createBangTarget(this.builder, "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", "origin")

    elseif (at == ABIL_TRANSFORM_SUPPORT) then
      call this.replaceUnit('u001')
      call createBangTarget(this.builder, "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", "origin")
      
    elseif (at == ABIL_TRANSFORM_SPECIAL) then
      call this.replaceUnit('u002')
      call createBangTarget(this.builder, "Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", "origin")
    
    elseif (at == 'A00X') then
      set this.camRange = this.camRange + VAL_CAMRANGESTEP
      if (this.camRange > VAL_CAMRANGEMAX) then
        set this.camRange = VAL_CAMRANGEMAX
      endif

    elseif (at == 'A00Y') then
      set this.camRange = this.camRange - VAL_CAMRANGESTEP
      if (this.camRange < VAL_CAMRANGEMIN) then
        set this.camRange = VAL_CAMRANGEMIN
      endif
    
    elseif (at == 'A012') then
      call Game.makeDefenderReady(this)
      call AddSpecialEffectScaledWithTimer (GetUnitX(u), GetUnitY(u), 200, 2, "Abilities\\Spells\\Items\\AIam\\AIamTarget.mdl", 1)
    endif

    set u = null
  endmethod
  
  private static method catchCastingAbility takes nothing returns nothing
    call Defender.fromUnit(GetTriggerUnit()).exec_catchCastingAbility.execute(GetTriggerUnit(), GetSpellAbilityId())
  endmethod
  
  private method exec_catchCastingAbility takes unit u, integer at returns nothing
    local integer i
    local Runner r
  
    if (this == nill) then
      return
    endif
    
    //tangelroots
    if(at == 'A017') then
      set r = Runner.fromUnit(GetSpellTargetUnit())
      set r.pacified = true
      call TriggerSleepAction(9)
      
      //resend runner
      set i = 4
      loop
        exitwhen i <= 0
        call TriggerSleepAction(0.5)
        call r.orderToWaypoint()
        set i = i - 1
      endloop
      set r.pacified = false
    endif
  endmethod
  
  //////////
  public static method catchCamRangeTick takes nothing returns nothing
    local Defender d
    
    if (Game.state == VAL_GAME_STATE_INTRO) then
      return
    endif
    
	call Defender.iterate()
	loop
	  exitwhen Defender.iterateFinished()
	  set d = Defender.next()
	  if(d.isPresent()) then
        call SetCameraFieldForPlayer(d.p, CAMERA_FIELD_TARGET_DISTANCE, d.camRange, VAL_CAMTICKINTERVAL) 
      endif
	endloop
  endmethod
  
  /////////
  private static method catchEsc takes nothing returns nothing
    local Defender d = Defender.fromPlayer(GetTriggerPlayer())
    if (d != nill) then
      call SelectUnitForPlayerSingle(d.builder, d.p)
    endif
  endmethod
  
  /////////
  private static method catchItemSell takes nothing returns nothing
    local Defender d1
    local Defender d2
    
    // buy life    
    if(GetItemTypeId(GetSoldItem()) == 'I000') then
      set d1 = Defender.fromUnit(GetBuyingUnit())
      call showMessage(d1.getNameWithColor() + " buy 1 Life.") 
      call RemoveItem(GetSoldItem())
    
	  call Defender.iterate()
	  loop
	    exitwhen Defender.iterateFinished()
		set d2 = Defender.next()
		if(d2.isPresent()) then
          set d2.lives = d2.lives + 1
          call SetPlayerStateBJ(d2.p, PLAYER_STATE_RESOURCE_FOOD_USED, d2.lives)
        endif
	  endloop
    endif
  endmethod
endstruct
