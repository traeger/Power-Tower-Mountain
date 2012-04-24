//! textmacro for takes INIT, PREDICATE
set $INIT$
loop
  exitwhen not ($PREDICATE$)
//! endtextmacro

//! textmacro endfor takes STEP
  set $STEP$
endloop
//! endtextmacro

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
// static alloc() : $STRUCT$ - allocates memory for the unit and creates the struct associated struct
// dealloc() : dealloc the struct
// interate() : void - starts an iterator
// hasNext() : boolean - whether their is a next element to interate through
// next() : $STRUCT$ - the next element
//
//! textmacro StructAlloc takes STRUCT
  private static integer numAllocated = 0
  private static $STRUCT$ array allocs
  private integer allocIndex
  
  public static method alloc takes nothing returns $STRUCT$
    //try to allocate
    local $STRUCT$ a = $STRUCT$.allocate()
    if (a == nill) then
      call showMessage("Critical Map Error: couldn't allocate $STRUCT$ struct. Probably because of max array size. Damn you, Blizzard!")
      return nill
    endif
  
    set $STRUCT$.numAllocated = $STRUCT$.numAllocated + 1
    set a.allocIndex = $STRUCT$.numAllocated
    set $STRUCT$.allocs[$STRUCT$.numAllocated] = a
    
	return a
  endmethod
  
  //////////
  private method dealloc takes nothing returns nothing
    if (this == nill) then
      return
    endif

    //remove from global array
    set $STRUCT$.allocs[this.allocIndex] = $STRUCT$.allocs[$STRUCT$.numAllocated]
    set $STRUCT$.allocs[$STRUCT$.numAllocated].allocIndex = this.allocIndex
    set $STRUCT$.allocs[$STRUCT$.numAllocated] = nill

    set $STRUCT$.numAllocated = $STRUCT$.numAllocated - 1
  endmethod
//! endtextmacro



// provides methods
//
// static alloc() : $STRUCT$ - allocates memory for the unit and creates the struct associated struct
// dealloc() : dealloc the struct
// interate() : void - starts an iterator
// hasNext() : boolean - whether their is a next element to interate through
// next() : $STRUCT$ - the next element
//
//! textmacro StructAlloc_Fixed takes STRUCT, SIZE
  private static $STRUCT$ array allocs[$SIZE$]
  private static integer numAllocated = 0
  private integer allocIndex
  
  public static method alloc takes integer i returns $STRUCT$
    local $STRUCT$ a
  
    if (i < 1 or i > $SIZE$ or $STRUCT$.allocs[i] != nill) then
	  call debugMsg("Allready allocated (" + I2S(i) + ") in struct $STRUCT$.", FATAL)
      return nill //enforce one-time creation for player
    endif
	
	//try to allocate
    set a = $STRUCT$.allocate()
    if (a == nill) then
      call debugMsg("Critical Map Error: couldn't allocate $STRUCT$ struct. Probably because of max array size. Damn you, Blizzard!", FATAL)
      return nill
    endif
  
    set $STRUCT$.numAllocated = $STRUCT$.numAllocated + 1
	set a.allocIndex = i
    set $STRUCT$.allocs[i] = a
    
	return a
  endmethod
  
  public static method fromIndex takes integer index returns $STRUCT$
    if (index < 1 or index > $SIZE$) then
      return nill
    endif
    return $STRUCT$.allocs[index]
  endmethod
  
  public method index takes nothing returns integer
    return this.allocIndex
  endmethod
  
  //////////
  private method dealloc takes nothing returns nothing
    if (this == nill) then
      return
    endif
	
    //remove from global array
	set $STRUCT$.allocs[this.allocIndex] = nill
    set $STRUCT$.numAllocated = $STRUCT$.numAllocated - 1
  endmethod
//! endtextmacro



// provides methods
//
// static alloc(u : Unit) : $STRUCT$ - allocates memory for the unit and creates the struct associated struct
// static fromUnit(u : Unit) : $STRUCT$ - $STRUCT$ from unit
// dealloc() : dealloc the struct
// interate() : void - starts an iterator
// hasNext() : boolean - whether their is a next element to interate through
// next() : $STRUCT$ - the next element
//
//! textmacro StructAlloc_Unit takes STRUCT
  private static integer numAllocated = 0
  private static $STRUCT$ array allocs
  private integer allocIndex
  
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

    //custom value should always point to the correct unit
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

////////////////////////
////////////////////////
////////////////////////
//! textmacro StructIterable takes STRUCT
  private static integer ITERATE_NUMBER = 0
  private static integer array ITERATE_IDX
  
  public static method iterate takes nothing returns nothing
    set $STRUCT$.ITERATE_NUMBER = $STRUCT$.ITERATE_NUMBER + 1
    set $STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] = 0
  endmethod
  
  public static method enditerate takes nothing returns nothing
    if($STRUCT$.ITERATE_NUMBER <= 0) then
	  call debugMsg("enditerate while not iterating in $STRUCT$", FATAL)
	  return
	endif
    set $STRUCT$.ITERATE_NUMBER = $STRUCT$.ITERATE_NUMBER - 1
  endmethod
  
  public static method iterateFinished takes nothing returns boolean
    if($STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] >= $STRUCT$.numAllocated) then
	  call $STRUCT$.enditerate()
	  return true
	endif
	return false
  endmethod
  
  public static method next takes nothing returns $STRUCT$
    if($STRUCT$.ITERATE_NUMBER <= 0) then
	  call debugMsg("next while not iterating in $STRUCT$", FATAL)
	  return nill
	endif
	
	if($STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] >= $STRUCT$.numAllocated) then
	  call showMessage("Critical Map Error: Iteration should be finished, check with $STRUCT$.iterateFinished")
	  return nill
	endif
	
	set $STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] = $STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] + 1
	return $STRUCT$.allocs[$STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER]]
  endmethod
//! endtextmacro

////////////////////////
////////////////////////
////////////////////////
//! textmacro StructIterable_Fixed takes STRUCT, SIZE
  private static integer ITERATE_NUMBER = 0
  private static integer array ITERATE_IDX
  
  public static method iterate takes nothing returns nothing
    set $STRUCT$.ITERATE_NUMBER = $STRUCT$.ITERATE_NUMBER + 1
    set $STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] = 0
  endmethod
  
  public static method enditerate takes nothing returns nothing
    if($STRUCT$.ITERATE_NUMBER <= 0) then
	  call debugMsg("enditerate while not iterating in $STRUCT$", FATAL)
	  return
	endif
    set $STRUCT$.ITERATE_NUMBER = $STRUCT$.ITERATE_NUMBER - 1
  endmethod
  
  public static method iterateFinished takes nothing returns boolean
    if($STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] >= $SIZE$) then
	  call $STRUCT$.enditerate()
	  return true
	endif
	return false
  endmethod
  
  public static method next takes nothing returns $STRUCT$
    if($STRUCT$.ITERATE_NUMBER <= 0) then
	  call debugMsg("next while not iterating in $STRUCT$", FATAL)
	  return nill
	endif
	
	if($STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] >= $SIZE$) then
	  call showMessage("Critical Map Error: Iteration should be finished, check with $STRUCT$.iterateFinished")
	  return nill
	endif
	
	set $STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] = $STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER] + 1
	return $STRUCT$.allocs[$STRUCT$.ITERATE_IDX[$STRUCT$.ITERATE_NUMBER]]
  endmethod
//! endtextmacro