///////////////////////////////////////////////////////////////////////////
// This structure represents the overall game state and environment
//
// USES:
//   - Defender structure
//   - Events structure
//   - Runner structure
//   - Multiboard structure
//   - General library
//   - Special library
//
// USED BY:
//   - almost everything
//
// NOTES:
//   - static: can't be instanciated
///////////////////////////////////////////////////////////////////////////
globals
  constant integer  VAL_MAP_SIZE = 96
  constant integer  VAL_SPAWNS_PER_ROUND = 10
  constant real     VAL_WAIT_TIME = 30.0
  constant real     VAL_GRASS_REGROW_PERIOD = 3
  constant real     VAL_SPAWN_PERIOD = 5
  
  constant integer  VAL_GAME_STATE_INTRO = 0
  constant integer  VAL_GAME_STATE_WAITING = 1
  constant integer  VAL_GAME_STATE_DEFENDING = 2
  constant integer  VAL_GAME_STATE_OVER = 3
  constant integer  VAL_GAME_STATE_STONEWIN = 4

  constant integer  VAL_GAME_TYPE_COOP_COUNTCHECK = 1
  constant integer  VAL_GAME_TYPE_COOP = 2
  constant integer  VAL_GAME_TYPE_SIDE_TEAMS = 4
  constant integer  VAL_GAME_TYPE_CORNER_TEAMS = 5
  constant integer  VAL_GAME_LENGTH_LAST_MAN = -1
  
  constant boolean  VAL_GAME_STYLE_NORMAL = FALSE
  constant boolean  VAL_GAME_STYLE_STONE_OF_WIN = TRUE

  constant integer  VAL_DIFFICULTY_NOOB = 1
  constant integer  VAL_DIFFICULTY_ROOKIE = 2
  constant integer  VAL_DIFFICULTY_HOTSHOT = 3
  constant integer  VAL_DIFFICULTY_VETERAN = 4
  constant integer  VAL_DIFFICULTY_ELITE = 5
  constant integer  VAL_DIFFICULTY_TRAINING = 6
  
  constant real     VAL_GAME_SELL_PERCENT = 1

  boolean prep = true
endglobals

struct Game
  //state
  readonly static boolean initialized = false
  public static integer state = VAL_GAME_STATE_INTRO
  readonly static integer time = 0
  private static integer grassRegrowingCol = 0
  //type
  readonly static integer gameType = 0
  readonly static integer difficulty = 0
  readonly static boolean fairIncome = false
  readonly static integer numRounds = 0
  readonly static boolean gameStyle = VAL_GAME_STYLE_NORMAL
  readonly static integer runner
  //round
  private static integer array defendersReadyRound[NUM_DEFENDERS]
  private static Timer roundTimer = nill
  readonly static integer round = 0
  //readonly static integer numSpawnsLeftInRound = 0
  readonly static integer array runnerTypes
  
  readonly static Round currentRound
  readonly static Round nextRound
  
  ////////
  public static method init takes nothing returns boolean
    if (Game.initialized == true) then
      call showMessage("Critical Map Error: Tried to initialize game twice.")
      return false
    endif
    set Game.initialized = true

    //initialize values
    set Game.roundTimer = Timer.create("Spawning In")
    call Game.roundTimer.registerForTimeout(function Game.catchRoundTimer)
        
    call SetPlayerAllianceStateBJ(Player(PLAYER_NEUTRAL_AGGRESSIVE), VAL_RUNNERS_OWNER, bj_ALLIANCE_ALLIED_UNITS)
    call SetPlayerAllianceStateBJ(VAL_RUNNERS_OWNER, Player(PLAYER_NEUTRAL_AGGRESSIVE), bj_ALLIANCE_ALLIED_UNITS)

    //Events
    call Events.registerForChat(function Game.catchChat)
    call Events.registerForTick(function Game.catchTimeTick)
    call Events.registerForNewTicker(VAL_SPAWN_PERIOD, function Game.catchSpawn)
    call Events.registerForNewTicker(VAL_GRASS_REGROW_PERIOD, function Game.catchGrassTick)
    call Events.registerForTick(function Game.catchTryEndRound)
    call Events.registerForDeath(function Game.catchTryEndRound)

    return true
  endmethod

  ////////
  private static method create takes nothing returns Game
    call showMessage("Map Error: attempted to create instance of static structure: Game.")
    return nill
  endmethod

  //=====================================
  //=== RUNNER PROPERTIES ===============
  //=====================================

  //////////
  // Returns the number of runners left, include unspawned runners
  //////////
  public static method getNumRunnersLeft takes nothing returns integer
    local integer n
    local integer i
    if (Game.state != VAL_GAME_STATE_DEFENDING) then
      return 0
    endif      

    return Runner.numAllocated + Game.currentRound.unspawnedRunner()
  endmethod

  //=====================================
  //=== DEFENDER PROPERTIES =============
  //=====================================
  public static method isDefenderStreamActive takes Defender d returns boolean
    local integer i
    local Defender d2
    if (d == nill) then
      return false
    endif
    
    if (d.isDefending()) then
      return true
    endif

    if (Game.gameType != VAL_GAME_TYPE_COOP_COUNTCHECK) then
      set i = 1
      loop
        exitwhen i > NUM_DEFENDERS
        set d2 = Defender.defenders[i]
        if d2.isDefending() then
          return true
        endif
        set i = i + 1
      endloop
    endif

    return false
  endmethod
  
  public static method countDefenderStreamActive takes nothing returns integer
    local integer i = 1
    local integer n = 0
    loop
      exitwhen i > NUM_DEFENDERS
      if (Game.isDefenderStreamActive(Defender.defenders[i])) then
        set n = n + 1
      endif
      set i = i + 1
    endloop
    return n
  endmethod
  
  public static method countDefenderAllies takes Defender d returns integer
    local integer i
    local integer n = 0
    local Defender d2
    if (d == nill) then
      return 0
    endif
  
    set i = 1
    loop
      exitwhen i > NUM_DEFENDERS
      set d2 = Defender.defenders[i]
      if (d2.isDefending()) then
        set n = n + 1
      endif
      set i = i + 1
    endloop
  
    return n
  endmethod
  
  public static method StoneOfWin_current takes nothing returns integer
    return R2I( GetUnitState(StoneOfWin(), UNIT_STATE_MANA) )
  endmethod
  
  public static method StoneOfWin_max takes nothing returns integer
    return 144000
  endmethod

  //=====================================
  //=== PROPERTIES ======================
  //=====================================

  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  ////////
  public static method startGame takes string caption, integer difficulty, integer gameType, integer runner, integer numRounds, integer numLives, boolean fairIncome, boolean gameStyle returns boolean
    local integer i
    local group ug
    local unit u
    if (Game.state != VAL_GAME_STATE_INTRO) then
      return false
    endif

    //pass values
    set Game.difficulty = difficulty
    set Game.gameType = gameType
    set Game.fairIncome = fairIncome
    set Game.numRounds = numRounds
    set Game.gameStyle = gameStyle
    set Game.runner = runner
    set i = 1
    loop
      exitwhen i > NUM_DEFENDERS
      call Defender.defenders[i].setInitialLives(numLives)
      set i = i + 1
    endloop
    
    //start
    //call SetTimeOfDay(12)
    set Game.state = VAL_GAME_STATE_WAITING
    // create the first Round
    set Game.currentRound = Round.create(0)
    set Game.nextRound = Round.create(1)
    call Game.roundTimer.start(150)

    call Multiboard.init(caption, true, difficulty == VAL_DIFFICULTY_TRAINING)
    call Multiboard.roundUpdate()
    
    //cam
    call Events.registerForNewTicker(VAL_CAMTICKINTERVAL, function Defender.catchCamRangeTick)

    return true
  endmethod

  ////////
  // Sets a defender's status to ready, and skips the round timer ahead if all are ready
  ////////
  public static method makeDefenderReady takes Defender d returns nothing
    local integer i
    local integer n
    local string s
    if (Game.state != VAL_GAME_STATE_WAITING or d == nill or d.isDefending() == false) then
      return
    endif

    //Place the Vote
    set Game.defendersReadyRound[d.index] = Game.round + 1
    call showMessage(d.getNameWithColor() + " is ready")

    //Enumerate un-ready players
    set i = 1
    set n = 0
    set s = ""
    loop
      exitwhen i > NUM_DEFENDERS
      if (Game.defendersReadyRound[i] <= Game.round and Defender.defenders[i].isDefending()) then
        if (n > 0) then
          set s = s + ", "
        endif
        set s = s + Defender.defenders[i].getNameWithColor()
        set n = n + 1
      endif
      set i = i + 1
    endloop
    if (n > 0) then
      call showMessage(I2S(n) + " still not ready. (" + s + ")")
      return
    endif

    //All players ready, jump the timer
    call showMessage("All Players Ready.")
    call Game.roundTimer.skip()
  endmethod

  ////////
  public static method registerForStartOfRound takes code c returns boolean
    return Game.roundTimer.registerForTimeout(c)
  endmethod

  //////////
  // Returns true if the game is over
  //////////
  public static method exec_checkForGameOver takes nothing returns nothing
    local Defender d
    local boolean b = false
    local integer i
    // win with full man at stone of win
    if (Game.state == VAL_GAME_STATE_STONEWIN) then
      set b = true
    elseif (Game.state == VAL_GAME_STATE_INTRO) then
      set b = false
    elseif (Game.state == VAL_GAME_STATE_OVER) then
      return //already ending
    elseif (Game.gameStyle == VAL_GAME_STYLE_STONE_OF_WIN) then
      set b = false
    elseif (Defender.countLiveDefenders() == 0) then
      set b = true
    elseif (Game.gameStyle != VAL_GAME_STYLE_STONE_OF_WIN and Game.numRounds > 0 and Game.round >= Game.numRounds and Runner.numAllocated == 0 and not(Game.currentRound.isSpawning())) then
      set b = true
    else
      set b = false
    endif

    if (b == true) then
      set Game.state = VAL_GAME_STATE_OVER

      //Show "You Win!" messages
      set i = 1
      loop
        exitwhen i > NUM_DEFENDERS
        set d = Defender.defenders[i]
        if (d.isDefending()) then
          call showPlayerMessage(d.p, "|cFFFFCC00Congratulations! You have survived!")
        endif
        set i = i + 1
      endloop

      //Give time for end to sink in
      call DisplayTimedTextToForce(GetPlayersAll(), 40, "For |cff00ff00REMAKE|r join channel: |cffff0000POWER|r.")
      call TriggerSleepAction(50.0)

      //End the game
      set i = 1
      loop
        exitwhen i > NUM_DEFENDERS
        set d = Defender.defenders[i]
        if (d.isDefending()) then
          call CustomVictoryBJ(d.p, true, true)
        elseif (d.isPresent()) then
          call CustomDefeatBJ(d.p, "Defeated!")
        endif
        set i = i + 1
      endloop
    endif
  endmethod
  
  //=====================================
  //=== EVENTS ==========================
  //=====================================
  ////////
  private static method catchTimeTick takes nothing returns nothing
    set Game.time = Game.time + 1
    call Game.exec_checkForGameOver.execute()
  endmethod

  ////////
  private static method catchRoundTimer takes nothing returns nothing
    local integer i
    if (Game.state != VAL_GAME_STATE_WAITING) then
      call showMessage("Critical Map Error: round timer fired during non-waiting phase")
      return
    endif

    //start the next round
    set Game.round = Game.round + 1
    call Game.currentRound.destroy()
    set Game.currentRound = Game.nextRound
    set Game.nextRound = Round.create(Game.round + 1)
    
    set Game.state = VAL_GAME_STATE_DEFENDING

    //set handicap to 100*realHP/baseHP
    //note: if runner hp is changed in object editor, this screws up
    if(Game.currentRound.isBossRound()) then 
      call SetPlayerHandicapBJ(VAL_RUNNERS_OWNER, Game.currentRound.getRoundRunnerHealth()/1000.)
    else
      call SetPlayerHandicapBJ(VAL_RUNNERS_OWNER, Game.currentRound.getRoundRunnerHealth()/100.)
    endif
    
    //display alerts
    call showMessage("Round |cFFFFFF00" + I2S(Game.round) + "|r : " + Game.currentRound.roundname)
    if(Game.currentRound.roundtypnames != "") then
      call showMessage("Runner Abilitys: " + Game.currentRound.roundtypnames)
    endif

    call Multiboard.roundUpdate()
  endmethod

  ////////
  private static method catchChat takes nothing returns nothing
    local string s = StringCase(GetEventPlayerChatString(), false)
    if (s == "-ready") then
      call Game.makeDefenderReady(Defender.fromPlayer(GetTriggerPlayer()))
    endif
  endmethod

  ////////
  private static method catchSpawn takes nothing returns boolean
    local integer i
    local Defender d
    if (Game.state != VAL_GAME_STATE_DEFENDING or not(Game.currentRound.isSpawning())) then
      return false
    endif

    call Game.currentRound.spawn()
    
    return true
  endmethod

  ////////
  // Attempts to end the current round
  // return = true if the round was ended
  ////////
  private static method catchTryEndRound takes nothing returns boolean
    local integer i
    local integer roundTech = 0
    local Defender d
    
    if (Game.state != VAL_GAME_STATE_DEFENDING or Game.currentRound.isSpawning() or Runner.numAllocated > 0) then
      return false
    endif

    //Get Tech Level for Completed Round
    if (Game.round == 1) then
      set roundTech = 'R002' //Completed Round 1
    elseif (Game.round == 2) then
      set roundTech = 'R001' //Completed Round 2
    elseif (Game.round == 3) then
      set roundTech = 'R003' //Completed Round 3
    elseif (Game.round == 4) then
      set roundTech = 'R004' //Completed Round 4
    endif

    //Message, Money, and Tech for Defenders
    call showMessage("Round " + I2S(Game.round) + " Finished!")
    set i = 1
    loop
      exitwhen i > NUM_DEFENDERS
      set d = Defender.defenders[i]
      if (d.isDefending()) then
        call showPlayerMessage(d.p, "|cFFFFCC00+" + I2S(Game.currentRound.getRoundFinishBounty()) + " Bonus Gold|r")
        call AdjustPlayerStateBJ(Game.currentRound.getRoundFinishBounty(), d.p, PLAYER_STATE_RESOURCE_GOLD)
        if (roundTech != 0) then
          call SetPlayerTechResearchedSwap(roundTech, 1, d.p)
        endif
      endif
      set i = i + 1
    endloop

    // seams the import is missing - resulting in a fatal error
    //call CinematicFadeBJ( bj_CINEFADETYPE_FADEOUT, 2, "war3mapImported\\roundc.blp", 100.00, 80, 0, 0 )
    
    //Start timer for next round
    call Game.currentRound.destroy()
    set Game.state = VAL_GAME_STATE_WAITING
    call Game.roundTimer.start(VAL_WAIT_TIME)
    return true
  endmethod

  ////////
  // Regrows the grass row on row, that mark our place; and in the sky; The larks, still bravely singing, fly;
  ////////
  public static method catchGrassTick takes nothing returns nothing
    local integer i

    //Go to next column
    set Game.grassRegrowingCol = Game.grassRegrowingCol + 1
    if (Game.grassRegrowingCol > VAL_MAP_SIZE/2) then
      set Game.grassRegrowingCol = VAL_MAP_SIZE / -2
    endif

    //regrow the column
    set i = VAL_MAP_SIZE / -2
    loop
      exitwhen i > VAL_MAP_SIZE/2
      call adjustGrassLevel(Game.grassRegrowingCol, i, 1)
      set i = i + 1
    endloop
  endmethod
endstruct
