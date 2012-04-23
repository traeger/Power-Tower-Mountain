///////////////////////////////////////////////////////////////////////////
// This structure represents a dialog
//
// USES:
//   - Timer structure
//   - General library
//
// NOTES:
//   - Correctness: can't create invalid dialogs
//   - Storage: keeps track of allocated structures
///////////////////////////////////////////////////////////////////////////
globals
  constant integer MAX_BUTTONS = 10
  constant integer VAL_FAKE_BUTTON_NONE = 0
  constant integer VAL_FAKE_BUTTON_TIME_OUT = -1
  constant integer VAL_FAKE_BUTTON_VIEWER_LEFT = -2
endglobals

function InitTrig_Menu takes nothing returns nothing
  //nothing to initialize
endfunction

struct Menu
  readonly static integer numAllocated = 0
  private static Menu array menus
  private integer arrayIndex

  private dialog menu = null
  private trigger clickTrigger = null
  private integer clickedButtonIndex = 0
  private integer numButtons = 0
  private button array buttons[MAX_BUTTONS]
  readonly string array buttonCaptions[MAX_BUTTONS]
  readonly player viewer = null
  readonly Timer timeoutTimer = nill

  //////////
  public static method create takes string caption returns Menu
    local Menu m = Menu.allocate()
    if (m == nill) then
      call showMessage("Critical Map Error: Unable to allocate menu.")
    endif

    set m.timeoutTimer = Timer.create("Selection Timeout")
    call m.timeoutTimer.registerForTimeout(function Menu.catchTimeout)
    call m.reset(caption, false)

    set Menu.numAllocated = Menu.numAllocated + 1
    set Menu.menus[Menu.numAllocated] = m
    set m.arrayIndex = Menu.numAllocated
    return m
  endmethod

  //////////
  private method onDestroy takes nothing returns nothing
    if (this == nill) then
      return
    endif

    call DestroyTrigger(this.clickTrigger)
    call DialogDestroy(this.menu)
    call this.timeoutTimer.destroy()
    set this.timeoutTimer = nill
    set this.clickTrigger = null
    set this.menu = null

    set Menu.menus[this.arrayIndex] = Menu.menus[Menu.numAllocated]
    set Menu.menus[Menu.numAllocated].arrayIndex = this.arrayIndex
    set Menu.menus[Menu.numAllocated] = nill
    set Menu.numAllocated = Menu.numAllocated - 1
  endmethod

  //=====================================
  //=== MUTATERS ========================
  //=====================================
  //////////
  public method reset takes string caption, boolean keepTimer returns nothing
    local integer i

    //destroy previous
    if (this.menu != null) then
      call DialogDestroy(this.menu)
      call DestroyTrigger(this.clickTrigger)
      set this.numButtons = 0
      if (keepTimer == false) then
        call this.timeoutTimer.cancel()
      endif
    endif

    //create dialog
    set this.menu = DialogCreate()
    call DialogSetMessage(this.menu, caption)

    //create button trigger
    set this.clickTrigger = CreateTrigger()
    call TriggerAddAction(this.clickTrigger, function Menu.catchClick)
    call TriggerRegisterDialogEvent(this.clickTrigger, this.menu)
  endmethod

  //////////
  public method addButton takes string caption returns boolean
    if (this == nill or this.numButtons >= MAX_BUTTONS) then
      return false
    endif

    set this.numButtons = this.numButtons + 1
    set this.buttons[this.numButtons] = DialogAddButtonBJ(this.menu, caption)
    set this.buttonCaptions[this.numButtons] = caption
    return true
  endmethod

  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  //////////
  // Shows the menu to the main defender and waits
  // Periodically checks for a response or problems
  // return = index of clicked button
  //////////
  public method showToPlayerAndWait takes player p returns integer
    if (this == nill or this.viewer != null) then
      return VAL_FAKE_BUTTON_NONE
    elseif (this.timeoutTimer.isExpired() == true) then
      return VAL_FAKE_BUTTON_TIME_OUT
    endif

    //show to player
    set this.viewer = p
    set this.clickedButtonIndex = VAL_FAKE_BUTTON_NONE
    call DialogDisplay(p, this.menu, true)

    //wait for click
    loop
      call TriggerSleepAction(0.25)
      exitwhen this.viewer == null
      if (GetPlayerSlotState(this.viewer) != PLAYER_SLOT_STATE_PLAYING) then
        set this.viewer = null
        set this.clickedButtonIndex = VAL_FAKE_BUTTON_VIEWER_LEFT
      endif
    endloop

    return this.clickedButtonIndex
  endmethod

  //////////
  // Stops showing the menu
  // return = true if menu was showing
  //////////
  public method stopShowing takes nothing returns boolean
    if (this == null or this.viewer == null) then
      return false
    endif
    call DialogDisplay(this.viewer, this.menu, false) //hide menu
    set this.viewer = null
    return true
  endmethod

  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////
  public static method catchTimeout takes nothing returns nothing
    local dialog d
    local integer i
    local Menu m = nill
    local Timer t = Timer.getExpiredTimer()

    //find triggering Menu
    set d = GetClickedDialog()
    set i = 1
    loop
      exitwhen i > Menu.numAllocated
      if (Menu.menus[i].timeoutTimer == t) then
        set m = Menu.menus[i]
      endif
      set i = i + 1
    endloop
    set d = null
    if (m == nill) then
      return //no matching dialog
    endif

    //hide menu
    set m.clickedButtonIndex = VAL_FAKE_BUTTON_TIME_OUT
    call m.stopShowing()
  endmethod

  //////////
  public static method catchClick takes nothing returns nothing
    local dialog d
    local button b
    local integer i
    local Menu m = nill

    //find triggering Menu
    set d = GetClickedDialog()
    set i = 1
    loop
      exitwhen i > Menu.numAllocated
      if (Menu.menus[i].menu == d) then
        set m = Menu.menus[i]
      endif
      set i = i + 1
    endloop
    set d = null
    if (m == nill) then
      return //no matching dialog
    endif

    //find clicked button
    set m.viewer = null
    set b = GetClickedButton()
    set i = 1
    loop
      exitwhen i > m.numButtons
      if (m.buttons[i] == b) then
        set m.clickedButtonIndex = i
      endif
      set i = i + 1
    endloop
    set b = null
  endmethod
endstruct
