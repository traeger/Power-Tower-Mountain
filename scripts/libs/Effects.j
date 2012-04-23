///////////////////////////////////////////
library effects requires general

  globals
    constant integer SPELLDUMMY = 'h04O'
  endglobals

  //////////
  //Creates special effect with z position
  //////////
  function AddSpecialEffectZ takes string path, real x, real y, real z returns effect
    local destructable d = CreateDestructableZ( 'OTip', x, y, z, 0.00, 1, 0 )
    set bj_lastCreatedEffect = AddSpecialEffect( path, x, y )
    call RemoveDestructable( d )
    set d = null
    return bj_lastCreatedEffect
  endfunction

  //////////
  //Creates a dying special effect, no need for cleanup
  //////////
  function createBang takes location p, string model returns nothing
    call DestroyEffect(AddSpecialEffectLoc(model, p))
  endfunction
  //////////
  //Creates a dying special effect on unit, no need for cleanup
  //////////
  function createBangTarget takes widget targetWidget, string model, string attachPointName returns nothing
    call DestroyEffect(AddSpecialEffectTarget(model, targetWidget, attachPointName))
  endfunction

  //////////
  //Creates a nice circle of dying special effects
  //p = center of circle
  //r = radius of circle
  //effectName = path of special effect model
  //////////
  function createCircleEffect takes location p, real r, string effectName returns nothing
    local location q
    local real angle
    local real delta
    if (r < 10) then
      return
    endif
    set delta = 360/r*25
    if (delta > 45) then
      set delta = 45
    endif
    set angle = 0
    loop
      exitwhen angle >= 360
      set q = PolarProjectionBJ(p, r+50, angle)
      call createBang(q, effectName)
      call RemoveLocation(q)
      set q = null
      set angle = angle + delta
    endloop
  endfunction
  
  //////////
  //Creates a timed selfdestructing effect
  //////////
  //Ignore this function except for making sure it comes first in the script
  function AddSpecialEffectLocWithTimer_Child takes nothing returns nothing
    local effect tempeffect = bj_lastCreatedEffect
    local real duration     = bj_enumDestructableRadius
    call PolledWait( duration )
    call DestroyEffect( tempeffect )
    set tempeffect = null
  endfunction

  //This is the function you actually want to call
  function AddSpecialEffectWithTimer takes real x, real y, real z, string whichEffect, real duration returns nothing
    local real temp = bj_enumDestructableRadius
    if(z == 0) then
      set bj_lastCreatedEffect = AddSpecialEffect(whichEffect, x, y)
    else
      call AddSpecialEffectZ(whichEffect, x, y, z )
    endif
    set bj_enumDestructableRadius = duration
    call ExecuteFunc("AddSpecialEffectLocWithTimer_Child")
    set bj_enumDestructableRadius = temp
  endfunction
  
  //Ignore this function except for making sure it comes first in the script
  function AddSpecialScaledEffectScaledWithTimer_Child takes nothing returns nothing
    local effect e = bj_lastCreatedEffect
    local unit u = bj_lastCreatedUnit
    local real duration     = bj_enumDestructableRadius
    call PolledWait( duration )
    call DestroyEffect( e )
    call KillUnit ( u )
    call RemoveUnit( u )
    set e = null
    set e = null
  endfunction
  
  function AddSpecialEffectScaledWithTimer takes real x, real y, real z, real scale, string whichEffect, real duration returns nothing
    local real temp = bj_enumDestructableRadius
    
    // break
    if(scale == 0) then
      return
    //elseif(scale == 1) then
    //  call AddSpecialEffectWithTimer(x, y, z, whichEffect, duration)
    else
      set bj_lastCreatedUnit = CreateUnit(Player(bj_PLAYER_NEUTRAL_VICTIM), SPELLDUMMY, x, y, 0)
      call SetUnitFlyHeight(bj_lastCreatedUnit, z, 0)
      call SetUnitScale(bj_lastCreatedUnit, scale, scale, scale)
      call SetUnitVertexColor(bj_lastCreatedUnit, 0, 0, 0, 0)
      set bj_lastCreatedEffect = AddSpecialEffectTarget(whichEffect, bj_lastCreatedUnit, "origin")
      
      set bj_enumDestructableRadius = duration
      call ExecuteFunc("AddSpecialScaledEffectScaledWithTimer_Child")
      set bj_enumDestructableRadius = temp
    endif
  endfunction

endlibrary
//===========================================================================
function InitTrig_Effects_Library takes nothing returns nothing
endfunction