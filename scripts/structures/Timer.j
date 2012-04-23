///////////////////////////////////////////////////////////////////////////
// This structure represents a timer object. It's only real advantage
// over a normal timer is the timer dialog is handled for you.
//
// USES:
//   - General library
//
// NOTES:
//   - don't confuse with built-in type 'timer'
//   - Correctness: can't make malformed Timers
//   - Storage: keeps track of allocated structures
///////////////////////////////////////////////////////////////////////////
globals
  constant integer VAL_TIMER_STATE_READY = 0
  constant integer VAL_TIMER_STATE_RUNNING = 1
  constant integer VAL_TIMER_STATE_EXPIRED = 2
endglobals

function InitTrig_Timer takes nothing returns nothing
  //nothing to initialize
endfunction

struct Timer
  readonly static integer numAllocated = 0
  private static Timer array timers
  private integer arrayIndex = 0

  private integer state = VAL_TIMER_STATE_READY
  private timer t = null
  private timerdialog d = null
  private trigger trig = null
  private string caption = ""

  //////////
  public static method create takes string caption returns Timer
    local Timer t = Timer.allocate()
    if (t == nill) then
      return nill
    endif

    set t.t = CreateTimer()
    set t.d = CreateTimerDialog(t.t)
    set t.caption = caption
    set t.trig = CreateTrigger()
    call TriggerRegisterTimerExpireEvent(t.trig, t.t)
    call t.registerForTimeout(function Timer.catchTimeout)

    set Timer.numAllocated = Timer.numAllocated + 1
    set Timer.timers[Timer.numAllocated] = t
    set t.arrayIndex = Timer.numAllocated
    return t
  endmethod

  //////////
  private method onDestroy takes nothing returns nothing
    if (this == nill) then
      return
    endif

    call DestroyTrigger(this.trig)
    call DestroyTimer(this.t)
    call DestroyTimerDialog(this.d)
    set this.trig = null
    set this.t = null
    set this.d = null

    set Timer.timers[Timer.numAllocated] = nill
    set Timer.timers[this.arrayIndex] = Timer.timers[Timer.numAllocated]
    set Timer.timers[Timer.numAllocated].arrayIndex = this.arrayIndex
    set Timer.numAllocated = Timer.numAllocated - 1
  endmethod

  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  //////////
  // Returns the Timer structure for the timer which just expired
  //////////
  public static method getExpiredTimer takes nothing returns Timer
    local integer i
    local timer t = GetExpiredTimer()

    set i = 1
    loop
      exitwhen i > Timer.numAllocated
      if (Timer.timers[i].t == t) then
        set t = null
        return Timer.timers[i]
      endif
      set i = i + 1
    endloop

    set t = null
    return nill
  endmethod

  //////////
  public method isRunning takes nothing returns boolean
    return (this != nill and this.state == VAL_TIMER_STATE_RUNNING)
  endmethod

  //////////
  public method isExpired takes nothing returns boolean
    return (this != nill and this.state == VAL_TIMER_STATE_EXPIRED)
  endmethod

  //=====================================
  //=== MUTATERS ========================
  //=====================================
  //////////
  // Starts the timer with a time left of 'time'
  //////////
  public method start takes real time returns boolean
    if (this == nill) then
      return false
    endif
    set this.state = VAL_TIMER_STATE_RUNNING
    call StartTimerBJ(this.t, false, time)
    call TimerDialogSetTitle(this.d, this.caption)
    call TimerDialogDisplay(this.d, true)
    return true
  endmethod

  //////////
  // Stops a running timer
  // note: doesn't fire the timer, and removes 'expired' condition
  //////////
  public method cancel takes nothing returns boolean
    if (this == nill or this.isRunning() == false) then
      return false
    endif
    set this.state = VAL_TIMER_STATE_EXPIRED
    call PauseTimer(this.t)
    call TimerDialogDisplay(this.d, false)
    return true
  endmethod

  //////////
  // Skips a timer to firing time
  //////////
  public method skip takes nothing returns boolean
    if (this == nill or this.isRunning() == false) then
      return false
    endif
    call StartTimerBJ(this.t, false, 0.01)
    return true
  endmethod

  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  //////////
  // Registers a callback for when the timer fires
  //////////
  public method registerForTimeout takes code c returns boolean
    if (this == nill) then
      return false
    endif
    call TriggerAddAction(this.trig, c)
    return true
  endmethod

  //==================================
  //=== EVENTS =======================
  //==================================
  //////////
  // Hides the timer window when the timer expires
  //////////
  private static method catchTimeout takes nothing returns nothing
    local Timer t = Timer.getExpiredTimer()
    if (t != nill) then
      call TimerDialogDisplay(t.d, false)
      set t.state = VAL_TIMER_STATE_EXPIRED
    endif
  endmethod
endstruct
