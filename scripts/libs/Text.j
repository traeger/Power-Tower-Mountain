library text requires general
  //////////
  //Repeats a String i times
  //////////  
  function StringRepeat takes string s, integer n returns string
    local string o = ""
    if n < 0 then
      return null
    endif
    loop
      if n / 2 * 2 != n then
        set o = o + s
      endif
      set n = n / 2
      exitwhen n == 0
      set s = s + s
    endloop
    return o
  endfunction

  //////////
  //Displays a text message to all players
  //////////
  function showMessage takes string s returns nothing
    call DisplayTextToForce(GetPlayersAll(), s)
  endfunction

  //////////
  //Displays a text message to a player
  //////////
  function showPlayerMessage takes player p, string s returns nothing
    local force f = GetForceOfPlayer(p)
    call DisplayTextToForce(f, s)
    call DestroyForce(f)
    set f = null
  endfunction

  //////////
  // Shows fading floating-text above a unit for a single player
  //////////
  function showUnitTextForce takes unit u, string s, real valRed, real valGreen, real valBlue, force f returns nothing
    local texttag t
    local location p
    local location p2
    if (u == null or f == null) then
      return
    endif

    //creation
    set p = GetUnitLoc(u)
    set p2 = OffsetLocation(p, GetRandomInt(-25, 25), GetRandomInt(-25, 25))
    set t = CreateTextTagLocBJ(s, p2, 0, 10, valRed, valGreen, valBlue, 0)

    //setup
    call SetTextTagLifespanBJ(t, 3)
    call SetTextTagPermanentBJ(t, false)
    call SetTextTagFadepointBJ(t, 1)
    call SetTextTagVelocityBJ(t, 40, 90)
    call ShowTextTagForceBJ(false, t, GetPlayersAll())
    call ShowTextTagForceBJ(true, t, f)

    //cleanup
    call RemoveLocation(p2)
    call RemoveLocation(p)
    set t = null
    set p = null
    set p2 = null
  endfunction
  
  //////////
  // Shows fading floating-text above a unit for a force
  //////////
  function showUnitTextPlayer takes unit u, string s, real valRed, real valGreen, real valBlue, player pl returns nothing
    local force f
    
    if (pl == null) then
      return
    endif

    set f = GetForceOfPlayer(pl)
    
    call showUnitTextForce(u, s, valRed, valGreen, valBlue, f)

    //cleanup
    call DestroyForce(f)
    set f = null
  endfunction

  //////////
  //Shows fading floating-text above a unit for the owner of the unit
  //////////
  function showUnitText takes unit u, string s, real valRed, real valGreen, real valBlue returns nothing
    call showUnitTextPlayer(u, s, valRed, valGreen, valBlue, GetOwningPlayer(u))
  endfunction
  
  //////////
  //Shows fading floating-text above a unit for all
  //////////
  function showUnitTextAll takes unit u, string s, real valRed, real valGreen, real valBlue returns nothing
    call showUnitTextForce(u, s, valRed, valGreen, valBlue, GetPlayersAll())
  endfunction

  function generateColorString takes integer r, integer g, integer b returns string
    return "|cff" +Dec2Hex(r)+Dec2Hex(g)+Dec2Hex(b)
  endfunction
  
  function percent2ColorString takes integer p returns string
    local integer r
    local integer g
    
    if(p < 50) then
      set r = 255
      set g = (p * 255) / 50
    else
      set r = ((100 - p) * 255) / 50
      set g = 255
    endif
    
    return generateColorString(r, g, 0)
  endfunction
  
  //////////
  // Erstellt einen "gradient Text", also einen Text, der von einer Farbe in die andere übergeht.
  // Autor: Skater
  // http://forum.ingame.de/warcraft/showthread.php?s=&threadid=155480
  //////////
  function makeGradientText takes string toColor, integer r1, integer g1, integer b1, integer r2, integer g2, integer b2 returns string
    local integer length=StringLength(toColor)
    local integer rDif=(r1-r2)/length
    local integer gDif=(g1-g2)/length
    local integer bDif=(b1-b2)/length
    local integer rN=r1
    local integer gN=g1
    local integer bN=b1
    local integer i=0
    local string rS=""
    loop
    exitwhen i>length
      set rS=rS+generateColorString(rN,gN,bN)+SubString(toColor, i, i+1)
      set rN=rN-rDif
      set gN=gN-gDif
      set bN=bN-bDif
      set i=i+1
    endloop
    return rS+"|r"
  endfunction
  
  //////////
  // Displays a pass-code for writing down
  //////////
  function showPlayerPassCode takes player p, string s returns nothing
    set s = S2OS(s, -23)
    call showPlayerMessage(p, s)
  endfunction
endlibrary
//===========================================================================
function InitTrig_Text_Library takes nothing returns nothing
endfunction