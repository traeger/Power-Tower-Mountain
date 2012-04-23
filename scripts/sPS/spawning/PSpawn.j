///////////////////////////////////////////////////////////////////////////
// This interface represents a strategie for spawning
//
// USES:
//   - PSpawn
//
///////////////////////////////////////////////////////////////////////////

interface PSpawnStrategy
  public method run takes PSpawn spawn returns nothing
endinterface

///////////////////////////////////////////////////////////////////////////
// A PSpawn
//
// USES:
//   - PSpawnStrategy and alle subclasses
//   - PSimpleRunner
//   - PRunnerControl
//
///////////////////////////////////////////////////////////////////////////

globals
  constant real VAL_SPAWN_TICK = 5
endglobals

struct PSpawn
  readonly static PSpawn array references
  readonly static integer numAllocated = 0
  readonly integer arrayIndex

  private rect spawnRect
  private real spawnInterval
  private real timeSinceLastSpawn
  private PNode ordernode
  private PSpawnStrategy spawnStrategy
  private PRunnerFactory runnerFactory

  public static method init takes nothing returns nothing
    call Events.registerForNewTicker(VAL_SPAWN_TICK, function PSpawn.onSpawnTick)
  endmethod
  
  ////////////
  // Create a new PSpawn
  ////////////
  //! runtextmacro EnforcePermanent("PSpawn")
  public static method create takes PGraph graph, rect spawnRect, PSpawnStrategy spawnStrategy, real spawnInterval, PRunnerFactory runnerFactory returns PSpawn
    local PSpawn h
    
    //try to allocate
    set h = PSpawn.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate a PSpawn.")
      return nill
    endif
    
    set h.spawnRect = spawnRect
    set h.ordernode = graph.getRandomNodeInRect(h.spawnRect)
    set h.spawnStrategy = spawnStrategy
    set h.spawnInterval = spawnInterval
    set h.runnerFactory = runnerFactory
    
    if(spawnInterval < VAL_SPAWN_TICK) then
      call showMessage("Spawninterval is to small, at least: " + R2S(VAL_SPAWN_TICK) + " [PSpawn.create]")
      return nill
    endif
    set h.timeSinceLastSpawn = 0
    
    set PSpawn.numAllocated = PSpawn.numAllocated + 1
    set h.arrayIndex = PSpawn.numAllocated
    set PSpawn.references[PSpawn.numAllocated] = h
    
    return h
  endmethod
  
  //=====================================
  //=== METHODS =========================
  //=====================================
  
  private method run takes nothing returns nothing
    set this.timeSinceLastSpawn = this.timeSinceLastSpawn + VAL_SPAWN_TICK
    if(this.timeSinceLastSpawn > this.spawnInterval) then
      set this.timeSinceLastSpawn = this.timeSinceLastSpawn - this.spawnInterval
      call this.spawnStrategy.run(this)
    endif
  endmethod
  
  public method createUnit takes integer ut, player owner returns nothing
    local location loc = GetRandomLocInRect(this.spawnRect)
    local unit u
    
    if (this == nill) then 
      call showMessage("ERROR: null-pointer [PSpawn.run]")
      return
    endif
    
    set u = CreateUnitAtLoc(owner, ut, loc, 0)
    if (this.ordernode == nill) then 
      call showMessage("ERROR: no order-node [PSpawn.run]")
      return
    endif
    call PRunnerControl.setNodeObjective(this.runnerFactory.createRunner(u), this.ordernode)
    
    call RemoveLocation(loc)
    set loc = null
  endmethod
  
  //=====================================
  //=== MUTATORS ========================
  //=====================================
  //////////
  
  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////
  private static method onSpawnTick takes nothing returns nothing
    local integer i = 1
    
    loop
      exitwhen i > PSpawn.numAllocated
      call PSpawn.references[i].run()
      set i = i + 1
    endloop
  endmethod
endstruct
