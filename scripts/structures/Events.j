///////////////////////////////////////////////////////////////////////////
// This structure is used for registering common events easily.
// It's a bit superfluous in some places, but it removes the need
// to store and initialize triggers in the other structures.
// Also, it handles the issues with "UnitTakesDamage" transparently.
//
// USES:
//   - General library
//
// NOTES:
//   - Automatically recreates damage event trigger when all damage units have died
//   - Static: can't be instanciated
//   - Trust: this structure is trusted to call-back other structures correctly (private methods may be passed here)
///////////////////////////////////////////////////////////////////////////
globals
endglobals

function InitTrig_Events takes nothing returns nothing
  call Events.init()
endfunction

struct Events
  readonly static boolean initialized = false
  private static group damageUnits = CreateGroup()
  private static trigger trigTick = CreateTrigger()
  private static trigger trigAttack = CreateTrigger()
  private static trigger trigDeath = CreateTrigger()
  private static trigger trigUpgradeStarted = CreateTrigger()
  private static trigger trigUpgradeFinished = CreateTrigger()
  private static trigger trigUpgradeCancelled = CreateTrigger()
  private static trigger trigHeroLevel = CreateTrigger()
  private static trigger trigBuildStarted = CreateTrigger()
  private static trigger trigBuildCancelled = CreateTrigger()
  private static trigger trigBuildFinished = CreateTrigger()
  private static trigger trigDamageActions = CreateTrigger()
  private static trigger trigDamageEvents = CreateTrigger()
  private static trigger trigPathing = CreateTrigger()
  private static trigger trigAbilEffect = CreateTrigger()
  private static trigger trigAbilBegin = CreateTrigger()
  private static trigger trigAbilChannel = CreateTrigger()
  private static trigger trigAbilFinish = CreateTrigger()
  private static trigger trigAbilLearn = CreateTrigger()
  private static trigger trigLeave = CreateTrigger()
  private static trigger trigChat = CreateTrigger()
  private static trigger trigEsc = CreateTrigger()
  private static trigger trigItemSell = CreateTrigger()
  
  //////////
  public static method init takes nothing returns nothing
    local integer i
    if (Events.initialized == true) then
      call showMessage("Map Error: attempted to initialize Events structure twice.")
      return
    endif
    set Events.initialized = true

    call TriggerRegisterTimerEventPeriodic(Events.trigTick, 1.0)
    call TriggerRegisterAnyUnitEventBJ(Events.trigAttack, EVENT_PLAYER_UNIT_ATTACKED)
    call TriggerRegisterAnyUnitEventBJ(Events.trigDeath, EVENT_PLAYER_UNIT_DEATH)
    call TriggerRegisterAnyUnitEventBJ(Events.trigUpgradeStarted, EVENT_PLAYER_UNIT_UPGRADE_START)
    call TriggerRegisterAnyUnitEventBJ(Events.trigUpgradeCancelled, EVENT_PLAYER_UNIT_UPGRADE_CANCEL)
    call TriggerRegisterAnyUnitEventBJ(Events.trigUpgradeFinished, EVENT_PLAYER_UNIT_UPGRADE_FINISH)
    call TriggerRegisterAnyUnitEventBJ(Events.trigHeroLevel, EVENT_PLAYER_HERO_LEVEL)
    call TriggerRegisterAnyUnitEventBJ(Events.trigBuildStarted, EVENT_PLAYER_UNIT_CONSTRUCT_START)
    call TriggerRegisterAnyUnitEventBJ(Events.trigBuildCancelled, EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL)
    call TriggerRegisterAnyUnitEventBJ(Events.trigBuildFinished, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH)
    call TriggerRegisterAnyUnitEventBJ(Events.trigAbilChannel, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    call TriggerRegisterAnyUnitEventBJ(Events.trigAbilBegin, EVENT_PLAYER_UNIT_SPELL_CAST)
    call TriggerRegisterAnyUnitEventBJ(Events.trigAbilEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call TriggerRegisterAnyUnitEventBJ(Events.trigAbilFinish, EVENT_PLAYER_UNIT_SPELL_FINISH)
    call TriggerRegisterAnyUnitEventBJ(Events.trigAbilLearn, EVENT_PLAYER_HERO_SKILL)
    call TriggerRegisterAnyUnitEventBJ(Events.trigItemSell, EVENT_PLAYER_UNIT_SELL_ITEM )
        
    set i = 1
    loop
      exitwhen i > 12
      call TriggerRegisterPlayerEventLeave(Events.trigLeave, Player(i-1))
      call TriggerRegisterPlayerChatEvent(Events.trigChat, Player(i-1), "", false)
      call TriggerRegisterPlayerEvent(Events.trigEsc, Player(i-1), EVENT_PLAYER_END_CINEMATIC)
      set i = i + 1
    endloop

    call TriggerAddAction(Events.trigDeath, function Events.catchDeath)
    call TriggerAddAction(Events.trigDamageEvents, function Events.catchDamage)
  endmethod

  //////////
  private static method create takes nothing returns Events
    call showMessage("Map Error: Attempted to create static class 'Events'")
    return nill
  endmethod

  //////////
  // Adds a rect as a source of pathing events
  //////////
  public static method addPathingEventRect takes rect r returns nothing
    if (r != null) then
      call TriggerRegisterEnterRectSimple(Events.trigPathing, r)
    endif
  endmethod

  //////////
  // Adds a unit as a source of takes damage events
  // Note: records the unit to allow cleaning the damage trigger periodically
  //////////
  public static method addDamageEventUnit takes unit u returns nothing
    if (u != null and IsUnitInGroup(u, Events.damageUnits) == false) then
      call GroupAddUnit(Events.damageUnits, u)
      call TriggerRegisterUnitEvent(Events.trigDamageEvents, u, EVENT_UNIT_DAMAGED)
    endif
  endmethod

  //////////
  // Checks if a dying unit was among the damage sources, and cleans the trigger if there are no sources
  //////////
  private static method catchDeath takes nothing returns nothing
    local unit u = GetTriggerUnit()

    if (IsUnitInGroup(u, Events.damageUnits) == true) then
      call GroupRemoveUnit(Events.damageUnits, u)

      if (CountUnitsInGroup(Events.damageUnits) == 0) then
        call DestroyTrigger(Events.trigDamageEvents)
        set Events.trigDamageEvents = CreateTrigger()
        call TriggerAddAction(Events.trigDamageEvents, function Events.catchDamage)
      endif
    endif
  endmethod
  //////////
  // Passes damage events along
  //////////
  private static method catchDamage takes nothing returns nothing
    call ConditionalTriggerExecute(Events.trigDamageActions)
  endmethod

  //////////
  public static method registerForTick takes code c returns nothing
    call TriggerAddAction(Events.trigTick, c)
  endmethod
  //////////
  public static method registerForAttack takes code c returns nothing
    call TriggerAddAction(Events.trigAttack, c)
  endmethod
  //////////
  public static method registerForDeath takes code c returns nothing
    call TriggerAddAction(Events.trigDeath, c)
  endmethod
  //////////
  public static method registerForImproved takes code c returns nothing
    call TriggerAddAction(Events.trigUpgradeFinished, c)
    call TriggerAddAction(Events.trigHeroLevel, c)
  endmethod
  //////////
  public static method registerForMaxManaChange takes code c returns nothing
    call TriggerAddAction(Events.trigUpgradeStarted, c)
    call TriggerAddAction(Events.trigUpgradeCancelled, c)
    call TriggerAddAction(Events.trigUpgradeFinished, c)
    call TriggerAddAction(Events.trigBuildFinished, c)
    call TriggerAddAction(Events.trigHeroLevel, c)
  endmethod
  //////////
  public static method registerForFinishedBuild takes code c returns nothing
    call TriggerAddAction(Events.trigBuildFinished, c)
  endmethod
  //////////
  public static method registerForCancelledBuild takes code c returns nothing
    call TriggerAddAction(Events.trigBuildCancelled, c)
  endmethod
  //////////
  public static method registerForStartedBuild takes code c returns nothing
    call TriggerAddAction(Events.trigBuildStarted, c)
  endmethod
  //////////
  public static method registerForPathing takes code c returns nothing
    call TriggerAddAction(Events.trigPathing, c)
  endmethod
  //////////
  public static method registerForChannelingAbility takes code c returns nothing
    call TriggerAddAction(Events.trigAbilChannel, c)
  endmethod
  //////////
  public static method registerForStartingAbility takes code c returns nothing
    call TriggerAddAction(Events.trigAbilBegin, c)
  endmethod
  //////////
  public static method registerForCastingAbility takes code c returns nothing
    call TriggerAddAction(Events.trigAbilEffect, c)
  endmethod
  //////////
  public static method registerForFinishedAbility takes code c returns nothing
    call TriggerAddAction(Events.trigAbilFinish, c)
  endmethod
  //////////
  public static method registerForPlayerLeft takes code c returns nothing
    call TriggerAddAction(Events.trigLeave, c)
  endmethod
  //////////
  public static method registerForChat takes code c returns nothing
    call TriggerAddAction(Events.trigChat, c)
  endmethod
  //////////
  public static method registerForDamage takes code c returns nothing
    call TriggerAddAction(Events.trigDamageActions, c)
  endmethod
  //////////
  public static method registerForLearnAbility takes code c returns nothing
    call TriggerAddAction(Events.trigAbilLearn, c)
  endmethod
  //////////
  public static method registerForEsc takes code c returns nothing
    call TriggerAddAction(Events.trigEsc, c)
  endmethod
 //////////
  public static method registerForItemSell takes code c returns nothing
    call TriggerAddAction(Events.trigItemSell, c)
  endmethod

  //////////
  // Creates a permanent periodic call-back
  //////////
  public static method registerForNewTicker takes real period, code c returns boolean
    local trigger t
    if (period <= 0 or c == null) then
      return false
    endif

    set t = CreateTrigger()
    call TriggerRegisterTimerEventPeriodic(t, period)
    call TriggerAddAction(t, c)
    set t = null
    return true
  endmethod
endstruct
