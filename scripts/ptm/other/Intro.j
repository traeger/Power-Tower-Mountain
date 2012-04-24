///////////////////////////////////////////////////////////////////////////
//
// In production, i need to design a camera-system to script a nice, smooth
// intro, im currenty working on this system.
//
// It will be 100% stuct system, based on newton-interpolations for each
// camera path.
//
///////////////////////////////////////////////////////////////////////////

struct Intro
  public static method start takes nothing returns nothing
    call Intro.exec_start.execute()
  endmethod
  
  private static method exec_start takes nothing returns nothing
    local Defender d
	
	call Defender.iterate()
    loop
      exitwhen Defender.iterateFinished()
      set d = Defender.next()
      if(d != Defender.getMainDefender()) then
        call CameraSetupApplyForPlayer( true, gg_cam_Tutorial_OverviewStart, d.p, 0 )
        call CameraSetupApplyForPlayer( true, gg_cam_Tutorial_Overview1, d.p, 10 )
      endif
    endloop
    call TriggerSleepAction(9)
    call showMessage("bla")
    
	call Defender.iterate()
	loop
      exitwhen Defender.iterateFinished()
      set d = Defender.next()
      if(d != Defender.getMainDefender()) then
        call CameraSetupApplyForPlayer( true, gg_cam_Tutorial_Overview2, d.p, 10 )
      endif
    endloop
  endmethod
endstruct

function Trig_Intro_Actions takes nothing returns nothing
endfunction