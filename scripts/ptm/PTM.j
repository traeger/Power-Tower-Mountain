struct PTM
  private static method init takes nothing returns nothing
    local trigger t = CreateTrigger()

    call showMessage("init weather..")
    call Weather.init()

    call showMessage("init tower..")
    call Tower.init()
    call showMessage("init runner..")
    call Runner.init()
    
    call showMessage("init round..")
    call Round.init()
    call showMessage("init game..")
    call Game.init()

    call showMessage("init path..")
    call Path.init()

    call showMessage("init defender..")
    
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