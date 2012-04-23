///////////////////////////////////////////////////////////////////////////
// This structure represents the runners trying to reach the center.
//
// USES:
//   - Defender structure
//   - Tower structure
//   - Events structure
//   - Game structure
//   - Multiboard structure
//   - General library
//
// USED BY:
//   - Tower structure
//   - Game structure
//
// NOTES:
//   - Uniqueness: one unit can't have two Runner structures
//   - Storage: keeps track of allocated structures
//   - Custom data: assumes unit custom value is not modified elsewhere
///////////////////////////////////////////////////////////////////////////
globals
  constant player VAL_RUNNERS_OWNER = Player(10-1) //light blue
  constant real VAL_REORDER_PERIOD = 5
  constant integer ABIL_RUNNER_SHIELD = 'A007'
  constant integer MAX_FEEDBACK_EFFECTS = 500
  constant integer HIGH_FEEDBACK_EFFECTS = MAX_FEEDBACK_EFFECTS/2
endglobals

struct Runner
  readonly static integer numAllocated = 0
  readonly static Runner array runners
  readonly integer arrayIndex

  private static integer numFeedbackEffects = 0
  private static integer coopDivideIndex = -1

  readonly unit u
  readonly integer waypointIndex
  readonly integer confusedCount = 0
  public boolean removeOnDeath = false
  public boolean pacified = false
  private Path path

  ////////
  public static method init0 takes nothing returns nothing
    call Events.registerForDamage(function Runner.catchDamage)
    call Events.registerForPathing(function Runner.catchWaypoint)
    call Events.registerForDeath(function Runner.catchDeath)
    call Events.registerForCastingAbility(function Runner.catchCasting)
    call Events.registerForNewTicker(VAL_REORDER_PERIOD, function Runner.catchReorderTick)
    //call Events.registerForAttack(function Runner.catchAttack)
    //call Events.registerForTick(function Runner.catchTick)
  endmethod
  //! runtextmacro Init("Runner")  

  //////////
  // Spawns a runner for a given defender
  // SIDE-EFFECTS: registers event to runnerDamageTrig
  //////////
  public static method create takes Path path, integer ut returns Runner
    local Runner r
    local integer i
    local unit u
    local location p
    //local integer ut = Game.getRoundRunnerUnitType()

    //try to allocate
    set r = Runner.allocate()
    if (r == nill) then
       call showMessage("Critical Map Error: couldn't allocate a Runner.")
       return nill
    endif

    //spawn the runner
    set p = GetRectCenter(path.getWaypoint(0))
    set u = CreateUnitAtLoc(VAL_RUNNERS_OWNER, ut, p, bj_UNIT_FACING)
    set r.u = u
    set r.waypointIndex = 0
    set r.path = path
    call RemoveLocation(p)
    set p = null
    call RemoveGuardPosition(r.u)

    set Runner.numAllocated = Runner.numAllocated + 1
    set r.arrayIndex = Runner.numAllocated
    set Runner.runners[Runner.numAllocated] = r
    call SetUnitUserData(u, Runner.numAllocated)
    call Events.addDamageEventUnit(u)

    //Give abilities
    //if (Game.isFeedbackRound() == true) then
    //  call UnitAddAbility(u, 'A00C') //feedback
    //  call IssueImmediateOrder(u, "immolation") //activate it
    //endif
    //if (Game.isSpeedRound() == true) then
    //  call UnitAddAbility(u, 'A00B') //speed boost
    //  call IssueImmediateOrder(u, "berserk") //activate it
    //endif
    //if (Game.isTankRound() == true) then
    //  call UnitAddAbility(u, 'S000') //slow speed
    //endif
    //if (Game.isShieldRound() == true) then
    //  call UnitAddAbility(u, 'A007') //shield
    //endif
    //call round.modify(u)

    //send the runner on its way
    call r.orderToWaypoint()
    return r
  endmethod
  
  //////////
  public method onDestroy takes nothing returns nothing
    if (this == nill) then
      return
    endif

    //remove from runners array
    call SetUnitUserData(Runner.runners[Runner.numAllocated].u, this.arrayIndex)
    call SetUnitUserData(this.u, 0)
    set Runner.runners[this.arrayIndex] = Runner.runners[Runner.numAllocated]
    set Runner.runners[Runner.numAllocated].arrayIndex = this.arrayIndex
    set Runner.runners[Runner.numAllocated] = nill

    set Runner.numAllocated = Runner.numAllocated - 1
    
    if(this.removeOnDeath) then
      call RemoveUnit(this.u)
    endif
  endmethod

  //////////
  // Finds the runner structure representing a given unit
  //////////
  public static method fromUnit takes unit u returns Runner
    local integer i

    //custom value should point to correct runner
    set i = GetUnitUserData(u)
    if (i > 0 or i <= Runner.numAllocated) then
      if (Runner.runners[i].u == u) then
        return Runner.runners[i]
      endif
    endif

    return nill
  endmethod

  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  //////////
  public static method filter_isRunner takes nothing returns boolean
    return (Runner.fromUnit(GetFilterUnit()) != nill)
  endmethod

  //////////
  // Orders the runner to go to its next waypoint
  //////////
  public method orderToWaypoint takes nothing returns nothing
    local location p
    if (this == null) then
      return
    endif

    //update destination if we've reached current waypoint
    if (RectContainsUnit(this.path.getWaypoint(this.waypointIndex), this.u) == true) then
      set this.waypointIndex = this.waypointIndex + 1
    endif

    //order to waypoint
    set p = GetRectCenter(this.path.getWaypoint(this.waypointIndex))
    call IssuePointOrderLocBJ(this.u, "move", p)
    call RemoveLocation(p)
    set p = null
  endmethod

  //////////
  // Moves the runner increasingly longer distances to get around walls
  //////////
  private method exec_blink takes nothing returns nothing
    local location p1
    local location p2
    local location p3
    local real d
    local real x
    local real y
    local real range
    local lightning ltng
    if (this == nill) then
      return
    endif

    //check for pacified
    if (this.pacified == true) then
      set this.pacified = false
      call this.orderToWaypoint()
      return
    endif

    //get blink range
    set this.confusedCount = this.confusedCount + 1
    //call showPlayerMessage(this.owner.p, "|cFFFF8000Warning: You confused a runner by building in its way.")
    if (this.confusedCount <= 1) then
      //call showPlayerMessage(this.owner.p, "|cFFCC0000The runner has blinked a short distance.|r (1st confusion)")
      set range = 100
    elseif (this.confusedCount == 2) then
      //call showPlayerMessage(this.owner.p, "|cFFCC0000The runner has blinked a long distance.|r (2nd confusion)")
      set range = 750
    elseif (this.confusedCount >= 3) then
      //call showPlayerMessage(this.owner.p, "|cFFCC0000The runner has blinked to its destination.|r (3rd+ confusion)")
      set range = 50000
    endif

    //compute destination
    set p1 = GetUnitLoc(this.u)
    set p2 = GetRectCenter(this.path.getWaypoint(this.waypointIndex))
    set d = DistanceBetweenPoints(p1, p2)
    if (d < range) then
      set range = d
    endif
    loop
      set x = GetLocationX(p1) + range/d*(GetLocationX(p2) - GetLocationX(p1))
      set y = GetLocationY(p1) + range/d*(GetLocationY(p2) - GetLocationY(p1))
      set p3 = Location(x, y)
    
      //continue if the point is good
      exitwhen false != IsTerrainPathableBJ(p3, PATHING_TYPE_FLOATABILITY) and true != IsTerrainPathableBJ(p3, PATHING_TYPE_WALKABILITY)

      //increase range to avoid bad points
      set range = range + 100
      call RemoveLocation(p3)
    endloop

    //blink to destination
    set ltng = AddLightningLoc("AFOD", p1, p3)
    call SetUnitPositionLoc(this.u, p3)
    call RemoveLocation(p2)
    set p2 = GetUnitLoc(this.u)
    call createBang(p1, "Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl")
    call createBang(p2, "Abilities\\Spells\\NightElf\\Blink\\BlinkTarget.mdl")
    call RemoveLocation(p1)
    call RemoveLocation(p2)
    call RemoveLocation(p3)
    set p1 = null
    set p2 = null
    set p3 = null

    //continue on your way
    call this.orderToWaypoint()
    call doEvents()
    call this.orderToWaypoint()
    call DestroyLightning(ltng)
    set ltng = null
  endmethod

  //=====================================
  //=== EVENTS ==========================
  //=====================================
  ////////
  private static method catchCasting takes nothing returns nothing
    if (GetSpellAbilityId() == ABIL_RUNNER_SHIELD) then
      //make sure runner keeps walking after casting
      call Runner.fromUnit(GetTriggerUnit()).orderToWaypoint()
    endif
  endmethod

  ////////
  // Runners attack when they get walled, a good signal to blink
  ////////
  //private static method catchAttack takes nothing returns nothing
  //  call Runner.fromUnit(GetAttacker()).exec_blink.execute()
  //endmethod

  ////////
  // Blink runners standing still or heading for an attack
  ////////
  //private static method catchTick takes nothing returns nothing
  //  local integer i = 1
  //  local string s
  //  loop
  //    exitwhen i > Runner.numAllocated
  //
  //    set s = OrderId2StringBJ(GetUnitCurrentOrder(Runner.runners[i].u))
  //    if (s == "" or s == "attack") then
  //      call Runner.runners[i].exec_blink.execute()
  //    endif
  //
  //    set i = i + 1
  //  endloop
  //endmethod

  ////////
  // Makes sure runners keep moving when they reach waypoints
  ////////
  private static method catchWaypoint takes nothing returns nothing
    local Runner r = Runner.fromUnit(GetTriggerUnit())
    local string s
    local integer i
    local integer n
    local integer k
    local Defender d

    //continue to next waypoint
    call r.orderToWaypoint()

    //return if runner hasn't reached the finish
    if (r == nill or r.waypointIndex < r.path.size()-1 or RectContainsUnit(gg_rct_Pathing_End, r.u) == false) then
      return
    endif

    //In training mode, runners don't finish
    if (Game.difficulty == VAL_DIFFICULTY_TRAINING) then
      call KillUnit(r.u)
      return
    endif

    //Display warnings
    if(Game.currentRound.isBossRound()) then
      call showMessage("The |cffff0000BOSS|r made it through!")   
      set k = VAL_SPAWNS_PER_ROUND
    else
      call showMessage("A runner made it through!")
      set k = 1
    endif
    
    //Remove lives from affected defenders
    if (Game.round > 1) then
      call showMessage("Everyone lost " + I2S(k) + " life!")
    
      set i = 1
      loop
        exitwhen i > NUM_DEFENDERS

        set d = Defender.defenders[i]
        if (d.isDefending()) then
          set n = 1
          loop
            exitwhen n > k
            if(d.isPresent()) then
              call d.loseLife()
            endif
            set n = n + 1
          endloop
        endif
        set i = i + 1
      endloop
    else
      call showMessage("Misses are forgiven during the first round.")
    endif

    //Handle Runner
    call ExplodeUnitBJ(r.u)
  endmethod

  ////////
  // Handle runner responses to damage
  ////////
  private static method catchDamage takes nothing returns nothing
    call Runner.fromUnit(GetTriggerUnit()).exec_catchDamage.execute(GetEventDamageSource(), GetEventDamage())
  endmethod
  private method exec_catchDamage takes unit attacker, real damageDealt returns nothing
    local Tower t
    local location p
    local integer n
    local lightning ltng
    if (this == null or attacker == null or damageDealt <= 0) then
      return
    endif

    //shield
    if (Game.currentRound.isShieldRound()) then
      call IssueImmediateOrder(this.u, "divineshield")
    endif

    //feedback
    if (Game.currentRound.isFeedbackRound()) then
      set t = Tower.fromUnit(attacker)
      set n = R2I(damageDealt/10)
      if (t != null and n > 0) then

        // tree-tower is not effected
        if(not(isTreeTower(t.ut))) then      
          call t.adjustEnergy(-n)
          call showUnitText(t.u, I2S(-n), 50, 100, 0)

          //show lightning effect (skips half while there's a bunch, skips all while there's a lot)
          if (Runner.numFeedbackEffects < HIGH_FEEDBACK_EFFECTS or (chance(0.5) and Runner.numFeedbackEffects < MAX_FEEDBACK_EFFECTS)) then
            set Runner.numFeedbackEffects = Runner.numFeedbackEffects + 1
            set p = GetUnitLoc(this.u)
            set ltng = AddLightningLoc("MFPB", p, t.p)
            call PlaySoundAtPointBJ(gg_snd_Feedback, 100, p, 0)

            call TriggerSleepAction(0.2)
            call DestroyLightning(ltng)
            call RemoveLocation(p)
            set ltng = null
            set p = null
            set Runner.numFeedbackEffects = Runner.numFeedbackEffects - 1
          endif
        endif
      endif
    endif
  endmethod

  ////////
  // Give bounty to the killer
  ////////
  private static method catchDeath takes nothing returns nothing
    local Runner r = Runner.fromUnit(GetTriggerUnit())
    local Defender d
    local Defender d2
    if (r == null) then
      return
    endif

    //Credit the killer
    call showUnitText(GetKillingUnitBJ(), "Kill!", 100, 50, 0)
    //Add the kill to the owners killcounter
    set d = Defender.fromUnit(GetKillingUnitBJ())
    call d.hasKilledRunner()

    //Choose who gets the bounty
    if (GetKillingUnitBJ() == null and Game.difficulty != VAL_DIFFICULTY_TRAINING) then
      //no income
      set d = nill
    elseif (Game.currentRound.isBossRound()) then
      // get the nondefending defender with activ stream
      //set gold = ((Game.countDefenderAllies(d) - Game.countDefenderStreamActive()) * Game.getRoundRunnerBounty()) / Game.countDefenderStreamActive()
      loop
        set Runner.coopDivideIndex = imod(Runner.coopDivideIndex, NUM_DEFENDERS) + 1
        set d = Defender.defenders[Runner.coopDivideIndex]
        exitwhen d.isDefending() == true
      endloop
      
    elseif (Game.fairIncome == false) then
      //killer
      set d = Defender.fromUnit(GetKillingUnitBJ())
    elseif (Game.gameType == VAL_GAME_TYPE_COOP or Game.gameType == VAL_GAME_TYPE_COOP_COUNTCHECK) then
      //divided equally
      loop
        set Runner.coopDivideIndex = imod(Runner.coopDivideIndex, NUM_DEFENDERS) + 1
        set d = Defender.defenders[Runner.coopDivideIndex]
        exitwhen d.isDefending() == true
      endloop
    //elseif (Game.gameType == VAL_GAME_TYPE_SOLO) then
    //  //owner
    //  set d = r.owner
    //elseif (Game.gameType == VAL_GAME_TYPE_SIDE_TEAMS or Game.gameType == VAL_GAME_TYPE_CORNER_TEAMS) then
    //  //owner or teammate
    //  set d = r.owner
    //  if (d.isDefending() == false) then
    //    set d2 = Defender.defenders[imod(d.index+1,NUM_DEFENDERS)]
    //    if (Game.isDefenderWorkingWithDefender(d, d2) == false) then
    //      set d2 = Defender.defenders[imod(d.index-1,NUM_DEFENDERS)]
    //    endif
    //    if (Game.isDefenderWorkingWithDefender(d, d2) == false) then
    //      call showMessage("Map Error: income owner couldn't be determined.")
    //    endif
    //    set d = d2
    //  endif
    else
      call showMessage("Map Error: income owner couldn't be determined.")
    endif

    //Give Bounty
    if (d.isDefending()) then
        call showUnitTextPlayer(r.u, "+" + I2S(Game.currentRound.getRoundRunnerBounty()), 100, 80, 0, d.p)
        call AdjustPlayerStateBJ(Game.currentRound.getRoundRunnerBounty(), d.p, PLAYER_STATE_RESOURCE_GOLD)
    endif

    //Finish
    call r.destroy()
    call Multiboard.update()
  endmethod
  
  ///////////
  private static method catchReorderTick takes nothing returns nothing
    local integer i
  
    set i = 1
    loop
      exitwhen i > Runner.numAllocated
      call Runner.runners[i].orderToWaypoint()
      set i = i + 1
    endloop
  endmethod
endstruct
