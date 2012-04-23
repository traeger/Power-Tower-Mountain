///////////////////////////////////////////
// The miscellanious library
// Contains a lot of functions I use in most maps
///////////////////////////////////////////
library general
  globals
    constant integer nill = 0
    constant string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890:. |'"
    constant string hexMap= "0123456789ABCDEF"
    constant integer numChars = StringLength(chars)
	
	constant integer DEBUG = 1
	constant integer WARNING = 2
	constant integer FATAL = 3
  endglobals

  //===============================================================
  //= MATH ========================================================
  //===============================================================
  //////////
  // Returns the value of a 3rd degree polynomial
  //////////
  function polynom3 takes real x, integer coef0, integer coef1, integer coef2, integer coef3 returns real
    return coef0 + x*(coef1 + x*(coef2 + x*coef3))
  endfunction
  
  /////////
  // fast pow function based on integer
  function pow_int takes integer a, integer n returns integer
    local integer b = 1
    local integer i = n
    loop
      exitwhen (i <= 0)
      if (ModuloInteger(i, 2) != 0) then
        set b = b * a
      endif
      set a = a*a
      set i = i / 2
    endloop
    return b
  endfunction
  
  ///Returns true with probability p in percent
  function chancePercent takes integer p returns boolean
    if(p >= 100) then
      return true
    endif
    
    return (GetRandomInt(0, 99) < p)
  endfunction
  
  ///Returns true with probability p
  function chance takes real p returns boolean
    if(p >= 1) then
      return true
    endif
    
    return (GetRandomReal(0, 1) < p)
  endfunction

  //////////
  // Returns the value within the given range closest to x
  //////////
  function limitRange takes integer x, integer low, integer high returns integer
    if (low > high) then
      return limitRange(x, high, low)
    endif
    if (x < low) then
      return low
    elseif (x > high) then
      return high
    endif
    return x
  endfunction

  //////////
  // Returns the lower integer argument
  //////////
  function imin takes integer i1, integer i2 returns integer
    if (i1 < i2) then
      return i1
    else
      return i2
    endif
  endfunction

  //////////
  // Returns the larger integer argument
  //////////
  function imax takes integer i1, integer i2 returns integer
    if (i1 > i2) then
      return i1
    else
      return i2
    endif
  endfunction

  //////////
  // Returns the modulus of two integers
  //////////
  function imod takes integer n, integer d returns integer
    return ModuloInteger(n, d)
  endfunction

  //=================================================================
  //= VISUALS =======================================================
  //=================================================================

  //////////
  // Plays a sound, but for one player instead of all of them
  //////////
  function playSoundForPlayer takes sound s, player p returns nothing
    if (GetLocalPlayer() == p) then
      call PlaySoundBJ(s)
    endif
  endfunction

  //=================================================================
  //= CONVERSIONS ===================================================
  //=================================================================
  //////////
  // Returns the address of a handle
  //////////
  function H2I takes handle h returns integer
    return GetHandleId(h)
  endfunction

  //////////
  // Converts a character to an integer
  //////////
  function Char2I takes string s returns integer
    local integer i = 1
    loop
      exitwhen i > numChars
      if (s == SubStringBJ(chars, i, i)) then
        return i-1
      endif
      set i = i + 1
    endloop
    return -1
  endfunction

  //////////
  // Converts an integer to a character
  //////////
  function I2Char takes integer i returns string
    if (i < 0 or i >= numChars) then
      return " "
    endif
    return SubStringBJ(chars, i+1, i+1)
  endfunction
  
  //////////
  // Converts an dec. integer to its hex-representation as a string
  //////////
  function Dec2Hex takes integer i returns string
    local string hex
    if i>255 then
        return "|cffff0000This function is NOT designed to convert values above 255!|r"
    elseif i<0 then
        return "|cffff0000 The value is to small!|r"
    endif
    if i<16 then
        return "0"+SubString(hexMap, i, i+1)
    else
        set hex=SubString(hexMap, i/16, i/16+1)
        set i=ModuloInteger(i, 16)
        set hex=hex+SubString(hexMap, i, i+1)
        return hex
    endif
  endfunction

  //////////
  // Converts a string to an offset string
  //////////
  function S2OS takes string s, integer o returns string
    local string ret = ""
    local integer i = 1
    local integer n = StringLength(s)
    loop
      exitwhen i > n
      set ret = ret + I2Char(imod(Char2I(SubStringBJ(s, i, i)) + o, numChars))
      set i = i + 1
    endloop
    return ret
  endfunction

  //=================================================================
  //= MISC ==========================================================
  //=================================================================
  //////////
  // Waits a small amount of time, allowing many things in-game to happen before the script continues
  // SIDE EFFECTS: there are so many possible side-effects to doing this I can't even list them all
  //                 - other triggers may run
  //                 - event stuff like GetTriggerUnit() may become invalid
  //                 - stuff moves
  //                 - screws up some function calls if used inside the called functions
  //                 - etc
  //////////
  function doEvents takes nothing returns nothing
    call PolledWait(0.01)
  endfunction
  
  function debugMsg takes string s, integer id returns nothing
    call DisplayTextToForce(GetPlayersAll(), "> " + s)
  endfunction

endlibrary

//===========================================================================
function InitTrig_General_Library takes nothing returns nothing
endfunction