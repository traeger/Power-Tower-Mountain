///////////////////////////////////////////////////////////////////////////
// This structure represents the main multiboard
//
// USES:
//   - Defender struct
//   - Game struct
//   - Tower struct
//   - General library
//   - Events structure
//
// USED BY:
//   - Tower structure
//   - Game structure
//   - Defender structure
//
// NOTES:
//   - don't confuse with the built-in type, 'multiboard'
//   - static: can't be instanciated
///////////////////////////////////////////////////////////////////////////
globals
  constant integer NUM_MULTIBOARD_HEADER_ROWS = 8
endglobals

struct Multiboard
  readonly static boolean initialized = false
  readonly static multiboard board = null
  //defender stats
  readonly static integer array defenderRows[NUM_DEFENDERS]
  readonly static integer array defenderStatsProduc[NUM_DEFENDERS]
  readonly static integer array defenderStatsDrain[NUM_DEFENDERS]
  readonly static integer array defenderStatsAvail[NUM_DEFENDERS]
  readonly static real array defenderStatsDamage[NUM_DEFENDERS]

  //////////
  // Initializes the main multiboard
  // note: actions in this method are very order sensitive
  //////////
  public static method init takes string caption, boolean isVisible, boolean includeDamageColumn returns boolean
    if (Multiboard.initialized == true) then
      call showMessage("Map Error: Multiboard tried to initialize more than once.")
      return false
    endif
    set Multiboard.initialized = true

    //Create
    set Multiboard.board = CreateMultiboardBJ(1, 1, caption)
    call MultiboardSetColumnCount(Multiboard.board, 4)
    call Multiboard.assignDefenderRows()
    call MultiboardSetItemStyleBJ(Multiboard.board, 0, 0, true, false)
  
    //Player Rows
    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 0, 8.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 0, 4.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 0, 4.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 0, 4.0)
    //call MultiboardSetItemWidthBJ(Multiboard.board, 5, 0, 0)

    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 8, 8.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 8, 4.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 8, 4.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 8, 4.0)
    
    //Column Name Row
    call MultiboardSetItemValueBJ(Multiboard.board, 1, 8, "--Players--------------")
    call MultiboardSetItemValueBJ(Multiboard.board, 2, 8, "Avail---------")
    call MultiboardSetItemValueBJ(Multiboard.board, 3, 8, "Produc---------")
    call MultiboardSetItemValueBJ(Multiboard.board, 4, 8, "Drain---------")
    call MultiboardSetItemColorBJ(Multiboard.board, 0, 8, 75.00, 80, 100.00, 0) //light blue

    //Stone of Win cells
    if(Game.gameStyle == VAL_GAME_STYLE_STONE_OF_WIN) then
      call MultiboardSetItemWidthBJ(Multiboard.board, 1, 1, 10.0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 2, 1, 10.0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 3, 1, 0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 4, 1, 0)
      call MultiboardSetItemValueBJ(Multiboard.board, 1, 1, "Stone of Win:")
    else
      call MultiboardSetItemWidthBJ(Multiboard.board, 1, 1, 10.0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 2, 1, 10.0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 3, 1, 0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 4, 1, 0)
    endif
    
    //line
    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 2, 20)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 2, 0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 2, 0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 2, 0)
    call MultiboardSetItemColorBJ(Multiboard.board, 0, 2, 75.00, 80, 100.00, 0) //light blue
    call MultiboardSetItemValueBJ(Multiboard.board, 1, 2, "--Next-Round--------------------------------------")

    // next round 1
    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 3, 10)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 3, 10)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 3, 0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 3, 0)
    
    // next round 2
    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 4, 4.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 4, 16.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 4, 0.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 4, 0.0)
    
    //line
    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 5, 20)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 5, 0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 5, 0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 5, 0)
    call MultiboardSetItemColorBJ(Multiboard.board, 0, 5, 75.00, 80, 100.00, 0) //light blue
    call MultiboardSetItemValueBJ(Multiboard.board, 1, 5, "--Current-Round------------------------------------")
    
    // current round 1
    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 6, 10.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 6, 10.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 6, 0.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 6, 0.0)
    // current round 2
    call MultiboardSetItemWidthBJ(Multiboard.board, 1, 7, 4.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 2, 7, 16.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 3, 7, 0.0)
    call MultiboardSetItemWidthBJ(Multiboard.board, 4, 7, 0.0)
    
    //Events
    //call Events.registerForDamage(function Multiboard.catchDamage)
    //call Game.registerForStartOfRound(function Multiboard.catchRoundStart)

    //Show
    call Multiboard.assignDefenderRows()
    call Multiboard.setVisible(isVisible)
    return true
  endmethod

  //////////
  private static method create takes nothing returns Multiboard
    call showMessage("Map Error: Attempted to create static class 'Multiboard'")
    return nill
  endmethod

  //////////
  // Shows/Hides the board
  //////////
  public static method setVisible takes boolean isVisible returns boolean
    if (Multiboard.board == null) then
      return false
    endif
    call MultiboardDisplayBJ(isVisible, Multiboard.board)
    return true
  endmethod

  //////////
  // Assigns defenders their rows in the multiboard and resizes the board
  //////////
  public static method assignDefenderRows takes nothing returns boolean
    local integer i
    local integer row
    if (Multiboard.board == null) then
      return false
    endif

    //assign rows in order
    set i = 1
    set row = NUM_MULTIBOARD_HEADER_ROWS+1
    loop
      exitwhen i > NUM_DEFENDERS
      if (Defender.defenders[i].isPresent()) then
        set Multiboard.defenderRows[i] = row
        set row = row + 1
      else
        set Multiboard.defenderRows[i] = 0
      endif
      set i = i + 1
    endloop

    //resize board
    call MultiboardSetRowCount(Multiboard.board, row-1)
    
    set i = NUM_MULTIBOARD_HEADER_ROWS + 1
    loop
      exitwhen i > row
      call MultiboardSetItemWidthBJ(Multiboard.board, 1, i, 8.0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 2, i, 4.0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 3, i, 4.0)
      call MultiboardSetItemWidthBJ(Multiboard.board, 4, i, 4.0)
      set i = i + 1
    endloop
    call Multiboard.update()
    return true
  endmethod

  public static method roundUpdate takes nothing returns nothing 
    // nextround Head
    call MultiboardSetItemValueBJ(Multiboard.board, 1, 3, "|cFFFFCC00" + I2S(Game.nextRound.getRoundRunnerHealth()) + "|r Life/Creep")
    call MultiboardSetItemValueBJ(Multiboard.board, 2, 3, "Runners: |cFFFFCC00" + I2S(Game.nextRound.runnerPerRound()) + "|r")
    call MultiboardSetItemValueBJ(Multiboard.board, 1, 4, Game.nextRound.roundname)
    call MultiboardSetItemValueBJ(Multiboard.board, 2, 4, Game.nextRound.roundtypnames)

    // current round
    call MultiboardSetItemValueBJ(Multiboard.board, 1, 6, "|cFFFFCC00" + I2S(Game.currentRound.getRoundRunnerHealth()) + "|r Life/Creep")
    call MultiboardSetItemValueBJ(Multiboard.board, 1, 7, Game.currentRound.roundname)
    call MultiboardSetItemValueBJ(Multiboard.board, 2, 7, Game.currentRound.roundtypnames)
    
    call Multiboard.update()
  endmethod
  
  //////////
  // Updates the board to current values
  // Note: trusts that it will be called when needed
  //////////
  public static method update takes nothing returns boolean
    local integer i
    local integer n
    local Tower t
    local Defender d
    local integer i_sowC
    local integer i_sowM
    local string s_sowM
    local string s_sowC
    local string s
    if (Multiboard.board == null) then
      return false
    endif

    //reset defender stats
    set i = 1
    loop
      exitwhen i > NUM_DEFENDERS
      set Multiboard.defenderStatsProduc[i] = 0
      set Multiboard.defenderStatsDrain[i] = 0
      set Multiboard.defenderStatsAvail[i] = 0
      set i = i + 1
    endloop

    //calculate defender stats
    set i = 1
    loop
      exitwhen i > Tower.numAllocated
      set t = Tower.allocs[i]
      set d = Defender.fromUnit(t.u)
      if (d != nill) then
        set n = d.index
        set Multiboard.defenderStatsProduc[n] = Multiboard.defenderStatsProduc[n] + t.getEstimatedProduction()
        set Multiboard.defenderStatsDrain[n] = Multiboard.defenderStatsDrain[n] + t.getEstimatedDrain()
        set Multiboard.defenderStatsAvail[n] = Multiboard.defenderStatsAvail[n] + t.getEnergy()
      endif
      set i = i + 1
    endloop
    
    //Stone of Win cells
    if(Game.gameStyle == VAL_GAME_STYLE_STONE_OF_WIN) then
      set i_sowC = Game.StoneOfWin_current()
      set i_sowM = Game.StoneOfWin_max()
      set s_sowC = percent2ColorString((i_sowC*100)/i_sowM) + I2S(i_sowC)
      set s_sowM = "|cFF00FF00" + I2S(i_sowM)
    
      call MultiboardSetItemValueBJ(Multiboard.board, 2, 1, s_sowC + " |r/ " + s_sowM + "|r")
      set s_sowC = ""
      set s_sowM = ""
    else
      call MultiboardSetItemValueBJ(Multiboard.board, 2, 1, "Rounds Left: |cFFFFCC00" + I2S(Game.numRounds - Game.round) + "|r")
    endif
    
    //update game cells
    call MultiboardSetItemValueBJ(Multiboard.board, 2, 6, "Runners: |cFFFFCC00" + I2S(Game.getNumRunnersLeft()) + "|r")

    //update defender cells
    set i = 1
    loop
      exitwhen i > NUM_DEFENDERS
      set d = Defender.defenders[i]
      set n = Multiboard.defenderRows[i]
      if (n > NUM_MULTIBOARD_HEADER_ROWS) then
        call MultiboardSetItemValueBJ(Multiboard.board, 1, n, d.getNameWithColor())
        if (d.isDefending()) then
          call MultiboardSetItemValueBJ(Multiboard.board, 2, n, cSmallStr(Multiboard.defenderStatsAvail[i]))
          call MultiboardSetItemValueBJ(Multiboard.board, 3, n, cSmallStr(Multiboard.defenderStatsProduc[i]))
          call MultiboardSetItemValueBJ(Multiboard.board, 4, n, cSmallStr(Multiboard.defenderStatsDrain[i]))
          //call MultiboardSetItemValueBJ(Multiboard.board, 5, n, cSmallStr(R2I(Multiboard.defenderStatsDamage[i])))
        else
          call MultiboardSetItemValueBJ(Multiboard.board, 2, n, "-")
          call MultiboardSetItemValueBJ(Multiboard.board, 3, n, "-")
          call MultiboardSetItemValueBJ(Multiboard.board, 4, n, "-")
          //call MultiboardSetItemValueBJ(Multiboard.board, 5, n, "-")
        endif
      endif

      set i = i + 1
    endloop

    return true
  endmethod

  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////
  // Accumulates damage dealt stats
  //////////
  private static method catchDamage takes nothing returns nothing
    local Defender d = Defender.fromUnit(GetEventDamageSource())
    if (d != nill) then
      set Multiboard.defenderStatsDamage[d.index] = Multiboard.defenderStatsDamage[d.index] + GetEventDamage()
    endif
  endmethod

  //////////
  // Resets the damage stats
  //////////
  private static method catchRoundStart takes nothing returns nothing
    local integer i = 1
    loop
      exitwhen i > NUM_DEFENDERS
      set Multiboard.defenderStatsDamage[i] = 0
      set i = i + 1
    endloop
  endmethod
endstruct
