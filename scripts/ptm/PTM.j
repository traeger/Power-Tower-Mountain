struct PTM
  private static method init takes nothing returns nothing
    local trigger t = CreateTrigger()

    call Round.init()
    
	call Weather.init()
    call Tower.init()
    call Runner.init()
    call Game.init()
    call Path.init()

    //Defender must be the last to initialize
    call TriggerRegisterTimerEventSingle(t, 0.00)
    call TriggerAddAction(t, function Defender.init)
  endmethod
  
  private static method onInit takes nothing returns nothing
    local trigger t = CreateTrigger()
    //Defender must be the last to initialize
    call TriggerRegisterTimerEventSingle(t, 0.00)
    call TriggerAddAction(t, function PTM.init)     
  endmethod
endstruct