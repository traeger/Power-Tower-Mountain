//! textmacro Init takes MODULE
readonly static boolean INITIALIZED = false
public static method init takes nothing returns nothing
  call debugMsg("initializing $MODULE$", DEBUG)
  if ($MODULE$.INITIALIZED) then
    call debugMsg("Critical Map Error: Tried to initialize $MODULE$ twice.", WARNING)
    return
  endif
  set $MODULE$.INITIALIZED = true
  call $MODULE$.init0()
  call debugMsg("  ..initialized $MODULE$", DEBUG)
endmethod
//! endtextmacro
