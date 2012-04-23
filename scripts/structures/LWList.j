///////////////////////////////////////////////////////////////////////////
// LRList - Less Write - (Integer)List
//
// a list data-structur for uses with the following
// characteristics:
//   * often read
//   * less write
//   * write most over push and pop
// best type of init the list:
//   * use the push operation
//
///////////////////////////////////////////////////////////////////////////
//
// Elementtype: Integer
//   Minbound: -2.147.483.648
//   Maxbound: 2.147.483.647 
//
///////////////////////////////////////////////////////////////////////////

globals
  //the maximum size of an Integer as a String
  //   Minbound: -2.147.483.648
  //   Maxbound: 2.147.483.647 
  constant integer VAL_LWLIST_ELEM_SIZE = 11
  constant string VAL_LWLIST_FILLCHAR = "x"
endglobals

function InitTrig_LWList takes nothing returns nothing
  //nothing to initialize
endfunction

struct LWList
  readonly static integer numAllocated = 0
  private static LWList array lists
  private integer arrayIndex = 0

  private integer size = 0
  private string data = ""

  //////////
  public static method create takes nothing returns LWList
    local LWList list = LWList.allocate()
    
    set LWList.numAllocated = LWList.numAllocated + 1
    set LWList.lists[LWList.numAllocated] = list
    set list.arrayIndex = LWList.numAllocated
    
    return list
  endmethod
  
  //////////
  private method onDestroy takes nothing returns nothing
    set LWList.lists[this.arrayIndex] = LWList.lists[LWList.numAllocated]
    set LWList.lists[LWList.numAllocated].arrayIndex = this.arrayIndex
    set LWList.lists[LWList.numAllocated] = nill

    set LWList.numAllocated = LWList.numAllocated - 1
  endmethod
  
  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  // Stringrepresentation:
  //   the integer as String, fixxed size (maxSize)
  //   the integers:
  //     -12345,154389642,-1364817329
  //   are convert into:
  //     xxxxx-12345xx154389642-1364817329
  //
  // not great but it works, need to impove, cause of speed i
  // dont convert the integer into an number with an other base
  // (then i would need a char table to convert them, i thinks this would
  //  be slower, but i need to test it)
  
  // integer to string representation
  // fixxed length; filled with 'x'
  // @param:    integer
  // @return:   the corrosponding string representation
  private static method I2Srep takes integer i returns string
    local string s = I2S(i)
    local integer n = StringLength(s)
    return StringRepeat(VAL_LWLIST_FILLCHAR,(VAL_LWLIST_ELEM_SIZE - n)) + s
  endmethod
  
  // string representation to integer
  // @param:    string representation
  // @return:   the corrosponding integer
  private static method Srep2I takes string s returns integer
    local integer i = 0
    local string c
    if s == null or s == "" then
      call showMessage("Critical Map Error: Unknown LWList Element Rep.")
      return -1
    endif
    
    // delete 'x' infront
    loop
      set c = SubString( s, i, i + 1 )
      exitwhen c != VAL_LWLIST_FILLCHAR
      set i = i + 1
    endloop

    return S2I(SubString( s, i, VAL_LWLIST_ELEM_SIZE ))
  endmethod
  
  // get the offset in the string by the given index
  // @param:    index
  // @return:   string-offset
  private static method offset takes integer n returns integer
    return (n * VAL_LWLIST_ELEM_SIZE)
  endmethod
  
  //=====================================
  //=== METHODES ========================
  //=====================================
  
  public method getSize takes nothing returns integer
    return this.size
  endmethod
  
  public method isEmpty takes nothing returns boolean
    return this.getSize() <= 0
  endmethod
  
  // pushs an element to the end of the list
  // @param:    e, the element to be pushed at the end of the list
  // @return:   index, the new index of the element that was pushed
  public method push takes integer e returns nothing
    set this.data = this.data + LWList.I2Srep(e)
    set this.size = this.size + 1
  endmethod

  // pops(delete and return them) the element of the end of the list
  // @param:    nothing
  // @return:   the element that was poped
  public method pop takes nothing returns integer
    local integer n
    local integer i
    if (this.size <= 0) then
      call showMessage("Critical Map Error: LWList empty.")
      return -1
    endif
    
    // get the element
    set i = this.getElement(this.size)
    
    // delete the last element
    set n = LWList.offset(this.size)
    set this.data = SubString( this.data, 0, n - 1 )
    set this.size = this.size - 1
    return i
  endmethod
  
  // returns the element at the given position
  // @parem:    the index of the element
  // @return:   the element
  public method getElement takes integer index returns integer
    local integer n
  
    if (this.size <= 0) then
      call showMessage("Critical Map Error: LWList empty.")
      return -1
    elseif (index < 0 or index > this.size) then
      call showMessage("Critical Map Error: LWList out of bounds.")
      return -1
    endif
  
    set n = LWList.offset(index)
    return LWList.Srep2I(SubString(this.data, n, n + VAL_LWLIST_ELEM_SIZE ))
  endmethod
  
  public method remove takes integer index returns nothing
    local integer beg
    local integer end
    local integer eos
  
    if (this.size <= 0) then
      call showMessage("Critical Map Error: LWList empty.")
      return
    elseif (index < 0 or index > this.size) then
      call showMessage("Critical Map Error: LWList out of bounds.")
      return
    endif

    if(this.getSize() == 1) then
      set this.data = ""
      set this.size = this.size - 1
      return
    endif
    
    set beg = LWList.offset(index)
    set end = LWList.offset(index + 1)
    set eos = LWList.offset(this.getSize())
    
    if(index == 0) then
      set this.data = SubString(this.data, end, eos+VAL_LWLIST_ELEM_SIZE)
      set this.size = this.size - 1
      return
    endif
    if(index == this.getSize() - 1) then
      set this.data = SubString(this.data, 0, beg)
      set this.size = this.size - 1
      return
    endif

    set this.data = SubString(this.data, 0, beg) + SubString(this.data, end, eos+VAL_LWLIST_ELEM_SIZE)
    set this.size = this.size - 1
  endmethod
  
  public method print takes nothing returns nothing
    call showMessage(this.data)
  endmethod
  
endstruct