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

// provides methods
//
// alloc(u) : $STRUCT$ - allocates memory for the unit and creates the struct assoziated struct
//
//! textmacro StructAlloc takes STRUCT
  readonly static integer numAllocated = 0
  readonly static $STRUCT$ array allocs
  readonly integer allocIndex
  
  readonly unit u
  
  public static method alloc takes unit u returns $STRUCT$
    //try to allocate
    local $STRUCT$ a = $STRUCT$.allocate()
    if (a == nill) then
      call showMessage("Critical Map Error: couldn't allocate $STRUCT$ struct. Probably because of max array size. Damn you, Blizzard!")
      return nill
    endif
  
    set $STRUCT$.numAllocated = $STRUCT$.numAllocated + 1
    set a.allocIndex = $STRUCT$.numAllocated
    set $STRUCT$.allocs[$STRUCT$.numAllocated] = a
    call SetUnitUserData(u, $STRUCT$.numAllocated)
	set a.u = u
	
	return a
  endmethod

  public static method fromUnit takes unit u returns $STRUCT$
    local integer i
    if (u == null) then
      return nill
    endif

    //custom value should always point to the correct tower
    set i = GetUnitUserData(u)
    if (i >= 1 and i <= $STRUCT$.numAllocated) then
      if ($STRUCT$.allocs[i].u == u) then
        return $STRUCT$.allocs[i]
      endif
    endif

    return nill
  endmethod
  
  //////////
  private method dealloc takes nothing returns nothing
    if (this == nill) then
      return
    endif

    //remove from global array
    call SetUnitUserData($STRUCT$.allocs[$STRUCT$.numAllocated].u, this.allocIndex)
    call SetUnitUserData(this.u, 0)
    set $STRUCT$.allocs[this.allocIndex] = $STRUCT$.allocs[$STRUCT$.numAllocated]
    set $STRUCT$.allocs[$STRUCT$.numAllocated].allocIndex = this.allocIndex
    set $STRUCT$.allocs[$STRUCT$.numAllocated] = nill

    set $STRUCT$.numAllocated = $STRUCT$.numAllocated - 1
	
	set this.u = null
  endmethod
//! endtextmacro
