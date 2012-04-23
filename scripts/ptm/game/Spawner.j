struct Spawner
  readonly integer waves = 0
  readonly integer runnerPerWave = 0
  readonly Path path
  readonly Round round

  readonly integer wavesLeft = 0

  ////////
  public static method create takes Round round, Path path, integer runnerPerWave, integer waves returns Spawner
    local Spawner h
    
    //try to allocate
    set h = Spawner.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate Spawner struct.")
      return nill
    endif
    
    set h.round = round
    set h.path = path
    set h.waves = waves
    set h.wavesLeft = waves
    set h.runnerPerWave = runnerPerWave
    
    return h
  endmethod
  
  ////////
  public method spawn takes nothing returns nothing
    local integer i
    local integer ut
    local Runner r
  
    set this.wavesLeft = this.wavesLeft - 1
    
    set i = 1
    loop
      exitwhen i > this.runnerPerWave
      
      set ut = this.round.runnertypeRandom()
      set r = Runner.create(this.path, ut)
      call this.round.modify(r)
      
      set i = i + 1
    endloop
  endmethod
  
  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  //////////
  public method isSpawning takes nothing returns boolean
    return this.wavesLeft > 0
  endmethod
  
  public method runnerPerRound takes nothing returns integer
    return this.runnerPerWave * this.waves
  endmethod
  
  public method unspawnedRunner takes nothing returns integer
    return this.wavesLeft * this.runnerPerWave
  endmethod
endstruct