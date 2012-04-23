////////////
// general
////////////

//! import "scripts/libs/General.j"
//! import "scripts/libs/Text.j"
//! import "scripts/libs/Effects.j"
//! import "scripts/libs/Game.j"
//! import "scripts/libs/Module.j"

//! import "scripts/structures/Events.j"
//! import "scripts/structures/LWList.j"
//! import "scripts/structures/Menu.j"
//! import "scripts/structures/Timer.j"

////////////
// ptm
////////////

//! import "scripts/ptm/defender/Defender.j"
//! import "scripts/ptm/defender/TowerConstants.j"
//! import "scripts/ptm/defender/Tower.j"
//! import "scripts/ptm/defender/TowerTransfer.j"
//! import "scripts/ptm/defender/OilTanker.j"

//! import "scripts/ptm/runner/Runner.j"
//! import "scripts/ptm/runner/Path.j"

//! import "scripts/ptm/game/Weather.j"
//! import "scripts/ptm/game/Spawner.j"
//! import "scripts/ptm/game/Round.j"
//! import "scripts/ptm/game/Game.j"
//! import "scripts/ptm/game/Multiboard.j"

//! import "scripts/ptm/other/Intro.j"

//! import "scripts/ptm/PTM.j"

struct PTM
  private static method init takes nothing returns nothing
    local trigger t = CreateTrigger()

	call Events.init()
	
    call Round.init()
    call Tower.init()
    call Runner.init()
    call Game.init()
    call Path.init()
	
	call Weather.init()
	
	call OilTanker.init()

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
