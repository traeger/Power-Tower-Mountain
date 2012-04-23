///////////////////////////////////////////////////////////////////////////
// This structure is a Round
//
// USES:
//   - Game structure
//   - General library
//
// USED BY:
//   - Runner
//   - Game
//   - Multiboard
//
// NOTES:
///////////////////////////////////////////////////////////////////////////
globals
  // runnertypes
  constant integer VAL_RUNNERGEN_TYPE_NORMAL = 0
  constant integer VAL_RUNNERGEN_TYPE_FAST = 1
  constant integer VAL_RUNNERGEN_TYPE_SLOW = 2
  constant integer VAL_RUNNERGEN_TYPE_MAGIC = 3
  constant integer VAL_RUNNERGEN_TYPE_BOSS = 4
  //constant integer VAL_RUNNERGEN_TYPE_FLY = 5
  //constant integer VAL_RUNNERGEN_TYPE_CARRIER = 6
  
  constant integer VAL_RUNNERGEN_TYPE_COUNT = 5

  constant integer VAL_RUNNERGEN_RACES_COUNT = 5
endglobals

struct Round
  //
  readonly static integer numAllocated = 0
  readonly static Round array objects
  readonly integer arrayIndex
  
  private static RaceGenerator array runnertypes[VAL_RUNNERGEN_TYPE_COUNT]
  
  readonly boolean rt_speed = false
  readonly boolean rt_tank = false
  readonly boolean rt_feedback = false
  readonly boolean rt_shield = false
  readonly boolean rt_regen = false
  readonly boolean rt_astral = false
  readonly boolean rt_boss = false
  readonly real rt_runnerCountModifier = 1
  readonly integer runnerCount = 0
  readonly integer roundNr
  readonly integer raceId
  readonly integer runnertype_primary
  readonly integer runnertype_secondary
  readonly string roundname = ""
  readonly string roundtypnames = ""
  
  readonly Spawner spawner
  //readonly integer numSpawnsLeftInRound = 0
  
  public static method init0 takes nothing returns nothing
    local integer i

    // create the runner-runnertypes
    call RaceGenerator.init()
    
    set Round.runnertypes[VAL_RUNNERGEN_TYPE_NORMAL] = RaceGenerator.create(VAL_RUNNERGEN_TYPE_NORMAL, gg_rct_rg_normal)
    set Round.runnertypes[VAL_RUNNERGEN_TYPE_FAST] =   RaceGenerator.create(VAL_RUNNERGEN_TYPE_FAST, gg_rct_rg_fast)
    set Round.runnertypes[VAL_RUNNERGEN_TYPE_SLOW] =   RaceGenerator.create(VAL_RUNNERGEN_TYPE_SLOW, gg_rct_rg_slow)
    set Round.runnertypes[VAL_RUNNERGEN_TYPE_MAGIC] =  RaceGenerator.create(VAL_RUNNERGEN_TYPE_MAGIC, gg_rct_rg_magic)
    set Round.runnertypes[VAL_RUNNERGEN_TYPE_BOSS] =  RaceGenerator.create(VAL_RUNNERGEN_TYPE_BOSS, gg_rct_rg_boss)
  endmethod
  //! runtextmacro Init("Round")
  
  ////////
  public static method create takes integer roundNr returns Round
    local Round h
    
    //try to allocate
    set h = Round.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate Round struct.")
      return nill
    endif
    
    //place in global array
    set Round.numAllocated = Round.numAllocated + 1
    set h.arrayIndex = Round.numAllocated
    set Round.objects[Round.numAllocated] = h
    
    set h.roundNr = roundNr
    
    if(roundNr != 0) then
      // order is important      
      call h.generateRoundtyp()
      call h.generateRunnertype()
      call h.generateRoundName()
      call h.generateRoundTypNames()
      call h.generateRunnerSpawn()
    endif
    
    return h
  endmethod
  
  //////////
  private method onDestroy takes nothing returns nothing
    if (this == nill) then
      return
    endif

    call this.spawner.destroy()
    
    //remove from global array
    set Round.objects[this.arrayIndex] = Round.objects[Round.numAllocated]
    set Round.objects[Round.numAllocated].arrayIndex = this.arrayIndex
    set Round.objects[Round.numAllocated] = nill

    set Round.numAllocated = Round.numAllocated - 1
  endmethod
  
  public method spawn takes nothing returns nothing
    call this.spawner.spawn()
  endmethod

  public static method normalRunnerPerRound takes nothing returns integer
    return Game.runner
  endmethod

  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  //////////
  public method isSpawning takes nothing returns boolean
    if(this.spawner == nill) then
      return false
    endif
  
    return this.spawner.isSpawning()
  endmethod
  
  public method runnerPerSpawn takes nothing returns integer
    if(this.spawner == nill) then
      return 0
    endif
  
    return this.spawner.runnerPerWave
  endmethod
  
  public method runnerPerRound takes nothing returns integer
    if(this.spawner == nill) then
      return 0
    endif
  
    return this.spawner.runnerPerRound()
  endmethod
  
  public method unspawnedRunner takes nothing returns integer
    if(this.spawner == nill) then
      return 0
    endif
    
    return this.spawner.unspawnedRunner()
  endmethod
  
  public method getRoundRunnerBounty takes nothing returns integer
    return R2I (((I2R(this.roundNr)+ 3 ) / 4) * this.rt_runnerCountModifier)
  endmethod
  ////////
  public method getRoundFinishBounty takes nothing returns integer
    return R2I ((I2R(this.roundNr)+ 3 ) / 2) * 10
  endmethod
  
  public method isSpeedRound takes nothing returns boolean
    return this.rt_speed
  endmethod
  //////////
  public method isTankRound takes nothing returns boolean
    return this.rt_tank
  endmethod
  //////////
  public method isFeedbackRound takes nothing returns boolean
    return this.rt_feedback
  endmethod
  //////////
  public method isShieldRound takes nothing returns boolean
    return this.rt_shield
  endmethod
  //////////
  public method isRegenRound takes nothing returns boolean
    return this.rt_regen
  endmethod
  //////////
  public method isAstralRound takes nothing returns boolean
    return this.rt_astral
  endmethod
  //////////
  public method isBossRound takes nothing returns boolean
    return this.rt_boss
  endmethod
  //////////
  public method isMagicRound takes nothing returns boolean
    return (this.isFeedbackRound() or this.isShieldRound())
  endmethod
  
  //////////
  private method abilityProbability takes integer mod, integer abilityCount returns boolean
    local integer prob = ((this.roundNr*mod)/35) / pow_int(2, abilityCount - 1)
    
    return chancePercent(prob)
  endmethod  
  
  ////////// OLD ONE
  //public method generateRoundtyp takes nothing returns nothing
  //  set this.rt_speed = this.abilityProbability(100)
  //  set this.rt_tank = this.abilityProbability(100)
  //  set this.rt_feedback = this.abilityProbability(50)
  //  set this.rt_regen = this.abilityProbability(100)
  //  set this.rt_shield = this.abilityProbability(200)
  //  set this.rt_astral = this.abilityProbability(200)
  //  set this.rt_boss = (GetRandomInt(0, 100) <= 12)
  //endmethod
  
  //////////
  public method generateRoundtyp takes nothing returns nothing
    // the list is not clever to use here cause we do much
    // write accesses but it is very easy and i do not need an
    // global array or gamecache
    // BUT IT NEED TO BE CHANGED MAYBE
    local LWList list = LWList.create()
    local integer i
    local integer n
    local integer c = 1     // the count of the next to anable skill
    local boolean b

    // boss not before round 10
    set b = (imod(this.roundNr, 5) == 0 and (this.roundNr >= 10))
    set this.rt_boss = b
    if(b) then
      set c = c + 2         // the boss just count for 2 skills
    endif

    // create the list
    set i = 1
    loop
      exitwhen i > 6
      call list.push(i)
      set i = i + 1
    endloop
    
    loop
      exitwhen list.isEmpty()
      // get random Element of List
      set i = GetRandomInt(0,list.getSize() - 1)
      set n = list.getElement(i)
      call list.remove(i)
  
      if(n==1) then
        set b = this.abilityProbability(150, c)
        set this.rt_speed = b
      elseif(n==2) then
        if(this.isBossRound()) then
          set b = false
        else
          set b = this.abilityProbability(100, c)
          set this.rt_tank = b
        endif
      elseif(n==3) then
        set b = this.abilityProbability(50, c)
        set this.rt_feedback = b
      elseif(n==4) then
        if(this.isBossRound()) then
          set b = false
        else
          set b = this.abilityProbability(100, c)
          set this.rt_regen = b
        endif
      elseif(n==5) then
        // shield not before round 5
        set b = (this.abilityProbability(100, c) and (this.roundNr >= 5))
        set this.rt_shield = b
      elseif(n==6) then
        set b = this.abilityProbability(200, c)
        set this.rt_astral = b
      else
        call showMessage("Critical Map Error: Round: LWList Error in 'generateRoundtyp'.")
        return
      endif
      
      if(b) then
        set c = c + 1
      endif
    endloop
    call list.destroy()
    
  endmethod
  
  private method generateRunnerSpawn takes nothing returns nothing
    local integer spawnsPerWave = 0
    local integer waves = VAL_SPAWNS_PER_ROUND
    
    if(this.isBossRound()) then
      set this.runnerCount = 1
      set waves = 1
      set spawnsPerWave = 1

    else
      set this.runnerCount = Game.runner
    
      if(this.isTankRound()) then
        set this.runnerCount = this.runnerCount / 2
      endif
    
      // CHANGE THIS STYLE:
      // need to be integer divideable with mod(waves) = 0
      set spawnsPerWave = this.runnerCount / waves
    endif
    
    set this.spawner = Spawner.create(this, Path.references[1], spawnsPerWave, waves)
    
    // reset life based on count
    set this.rt_runnerCountModifier = Game.runner / this.runnerCount
  endmethod
  
  private method generateRoundName takes nothing returns nothing
    local string s
    local unit u = CreateUnit(Player(bj_PLAYER_NEUTRAL_EXTRA), this.runnertypePrimary(), 0, 0, 0)
    set this.roundname = GetUnitName(u)
    
    call RemoveUnit(u)
    set u = null
  endmethod
  
  //////////////////////////
  // generate random runners based on the level
  public method generateRunnertype takes nothing returns nothing
    local integer type_first
    local integer type_second
    
    // set the visible type
    if (this.isBossRound()) then
      set type_first = VAL_RUNNERGEN_TYPE_BOSS
    elseif (this.isSpeedRound()) then
      set type_first = VAL_RUNNERGEN_TYPE_FAST
    elseif (this.isTankRound()) then
      set type_first = VAL_RUNNERGEN_TYPE_SLOW
    elseif (this.isMagicRound()) then
      set type_first = VAL_RUNNERGEN_TYPE_MAGIC
    else
      set type_first = VAL_RUNNERGEN_TYPE_NORMAL
    endif
    
    //manybe change
    set type_second = type_first
    
    // both rases are equal
    set this.raceId = this.randomRace()
    set this.runnertype_primary = Round.runnertypes[type_first].getRandom(this.raceId)
    set this.runnertype_secondary = Round.runnertypes[type_second].getRandom(this.raceId)
  endmethod
  
  //
  private method generateRoundTypNames takes nothing returns nothing
    local string s = ""
    local boolean follow = false
    
    if(this.isBossRound()) then
      if(follow) then
        set s = s + ","
      else
        set follow = true
      endif
      set s = s + "|cffff0000Boss|r"
    endif
    
    if(this.isSpeedRound()) then
      if(follow) then
        set s = s + ","
      else
        set follow = true
      endif
      set s = s + "|cffff0000Speed|r"
    endif
    
    if(this.isTankRound()) then
      if(follow) then
        set s = s + ","
      else
        set follow = true
      endif
      set s = s + "|cffffAA00Tank|r"
    endif
    
    if(this.isFeedbackRound()) then
      if(follow) then
        set s = s + ","
      else
        set follow = true
      endif
      set s = s + "|cff66ddffFeedback|r"
    endif
    
    if(this.isRegenRound()) then
      if(follow) then
        set s = s + ","
      else
        set follow = true
      endif
      set s = s + "|cff00ff00Regen|r"
    endif
    
    if(this.isShieldRound()) then
      if(follow) then
        set s = s + ","
      else
        set follow = true
      endif
      set s = s + "|cffffff00Shield|r"
    endif
    
    if(this.isAstralRound()) then
      if(follow) then
        set s = s + ","
      else
        set follow = true
      endif
      set s = s + "|cffaaaaffAstral"
    endif
  
    set this.roundtypnames = s
    set s = ""
  endmethod
  
  //Gives primary unittyp
  public method runnertypePrimary takes nothing returns integer
    return this.runnertype_primary
  endmethod
  
  //Gives second unittyp
  public method runnertypeSecondary takes nothing returns integer
    return this.runnertype_secondary
  endmethod
  
  public method runnertypeRandom takes nothing returns integer
    local integer i = GetRandomInt(0, 9)
    if(i < 6) then
      return this.runnertypePrimary()
    else
      return this.runnertypeSecondary()
    endif
  endmethod
  
  public method modify takes Runner r returns nothing
    local integer cr = 255
    local integer cg = 255
    local integer cb = 255
    local integer ca = 255
    local real scale = 1
  
    //Give abilities    
    if (this.isFeedbackRound()) then
      call UnitAddAbility(r.u, 'A00C') //feedback
      call IssueImmediateOrder(r.u, "immolation") //activate it
    endif
    if (this.isSpeedRound()) then
      call UnitAddAbility(r.u, 'A00B') //speed boost
      call IssueImmediateOrder(r.u, "berserk") //activate it
    endif
    if (this.isTankRound()) then
      set cr = cr - 100
      set cg = cg - 100
      call UnitAddAbility(r.u, 'S000') //slow speed
    endif
    if (this.isShieldRound()) then
      call UnitAddAbility(r.u, 'A007') //shield
    endif
    if (this.isRegenRound()) then
      call UnitAddAbility(r.u, 'A014') //regen
      call UnitAddAbility(r.u, 'A016') //regenbuff
    endif
    if (this.isAstralRound()) then
      set ca = ca - 150
      set r.removeOnDeath = true
    endif
    if (this.isBossRound()) then
      call UnitAddAbility(r.u, 'A013') //bossbuff
      //set scale = scale * 1.8
    endif
    //call SetUnitScale(u, scale, scale, scale)
    call SetUnitVertexColor(r.u, cr, cg, cb, ca)
  endmethod
  
  ////////
  public method getRoundRunnerHealth takes nothing returns integer
    local real hp
    //if (Game.state == VAL_GAME_STATE_INTRO) then
    //  return 0
    //endif
    
    if (this.roundNr < 1) then
      return 0
    endif

    if (Game.difficulty == VAL_DIFFICULTY_NOOB) then
      set hp = polynom3(this.roundNr, 50, 10, 15, 0)

    elseif (Game.difficulty == VAL_DIFFICULTY_ROOKIE) then
      set hp = polynom3(this.roundNr, 75, 5, 23, 0)

    elseif (Game.difficulty == VAL_DIFFICULTY_HOTSHOT) then
      set hp = polynom3(this.roundNr, 100, 0, 35, 0)

    elseif (Game.difficulty == VAL_DIFFICULTY_VETERAN) then
      set hp = polynom3(this.roundNr, 150, 21, 28, 1)

    elseif (Game.difficulty == VAL_DIFFICULTY_ELITE) then
      set hp = polynom3(this.roundNr, 200, 20, 28, 2)

    elseif (Game.difficulty == VAL_DIFFICULTY_TRAINING) then
      set hp = 1000000
    endif
    
    // adjust at runnerCount
    set hp = hp * this.rt_runnerCountModifier
    
    //readjust life to abilitys 
    if(this.isBossRound()) then
      set hp = hp * 0.5
    endif
    if(this.isTankRound()) then
      set hp = hp * 1.5
    endif
    if(this.isFeedbackRound()) then
      set hp = hp * 0.75
    endif
    if(this.isRegenRound()) then
      set hp = hp * 0.9
    endif
    if(this.isShieldRound()) then
      set hp = hp * 0.8
    endif
    if(this.isSpeedRound()) then
      set hp = hp * 0.9
    endif

    //round down to 25
    return R2I(hp/25.)*25
  endmethod
  
  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  
  private method randomRace takes nothing returns integer
    return GetRandomInt(0, VAL_RUNNERGEN_RACES_COUNT - 1)
  endmethod
endstruct

//////////////
// this is a private struct of Round
// ist generate a random creep for a given type and race
struct RaceGenerator
  readonly static boolean initialized = false
  readonly static integer numAllocated = 0

  // the units per rase of this type
  private LWList array race_unittype[VAL_RUNNERGEN_RACES_COUNT]
  // the runner-type of this object
  
  // not need to init currently
  //////////////////////////
  public static method init0 takes nothing returns nothing
    
  endmethod
  //! runtextmacro Init("RaceGenerator")

  //////////////////////////
  // creates a Round_Race by set the possible unittyps
  // of a runnertype
  //
  // SIDE-EFFECTS: deletes the race set units
  public static method create takes integer typeId, rect rect_runner returns RaceGenerator
    local RaceGenerator r
    local group ug
    local unit u
    local integer i
    
    set r = RaceGenerator.allocate()
    if (r == nill) then
       call showMessage("Critical Map Error: couldn't allocate a Round.Type.")
       return nill
    endif
    set RaceGenerator.numAllocated = RaceGenerator.numAllocated + 1
    
    ////////////////////////////
    // INIT unittype arrays
    ////////////////////////////
    set i = 0
    loop
      exitwhen i >= VAL_RUNNERGEN_RACES_COUNT
      
      set r.race_unittype[i] = LWList.create()
      set i = i + 1
    endloop

    ////////////////////////////
    // FILL unittype arrays
    ////////////////////////////
    set ug = GetUnitsInRectAll(rect_runner)
    if(CountUnitsInGroup(ug) == 0) then
      call showMessage("Map Error: Round, Type: no units of type.")
      return nill
    endif

    loop
      set u = FirstOfGroup(ug)
      exitwhen u == null

      // get the playernumber
      set i = GetConvertedPlayerId(GetOwningPlayer(u)) - 1
      if (i >= VAL_RUNNERGEN_RACES_COUNT) then
        //call showMessage("Map Error: Round, Type: raceId out of bounds.")
        //return nill
        call GroupRemoveUnitSimple(u, ug)
        call RemoveUnit(u)
      endif
      
      // insert the unittype of this unit to the right race
      call r.race_unittype[i].push(GetUnitTypeId(u))   
      call GroupRemoveUnitSimple(u, ug)
      call RemoveUnit(u)
    endloop
    call DestroyGroup(ug)
    
    // clear
    set ug = null
    ////////////////////////////
    // END FILL unittype arrays
    ////////////////////////////
        
    return r
  endmethod
  
  //////////
  public method onDestroy takes nothing returns nothing
    if (this == nill) then
      return
    endif

    //remove
  endmethod
  
  public method getRandom takes integer raceId returns integer
    local integer size
    local integer i
    
    if(raceId < 0 or raceId >= VAL_RUNNERGEN_RACES_COUNT) then
      call showMessage("Map Error: Round, Type: raceId out of bounds.")
      return nill
    endif
    
    set size = this.race_unittype[raceId].getSize()
    set i = GetRandomInt(0, size - 1)
    return this.race_unittype[raceId].getElement(i)
  endmethod
  
  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
endstruct