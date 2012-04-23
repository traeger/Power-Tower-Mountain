///////////////////////////////////////////////////////////////////////////
// This structure represents a runnerpath
//
// USES:
//   - General library
//
// USED BY:
//   - Runner structure
//   - Game structure
//
///////////////////////////////////////////////////////////////////////////
globals
  constant integer VAL_MAXNUM_WAYPOINTS = 6
endglobals

struct Path
  readonly static boolean initialized = false
  readonly static Path array references
  readonly static integer numAllocated = 0

  private static rect array mainPathingRects
  private static integer mainLength
  
  private rect array pathingRects[VAL_MAXNUM_WAYPOINTS]
  private integer length
  private integer mainPathEnterIndex

  public static method init takes nothing returns nothing
    local integer i
    local Path h
    
    if (Path.initialized == true) then
      call showMessage("Map Error: tried to initialize Path more than once.")
      return
    endif
    set Path.initialized = true
    
    set Path.mainPathingRects[0] = makeSimplePathingRect(gg_rct_Pathing_0)
    set Path.mainPathingRects[1] = makeSimplePathingRect(gg_rct_Pathing_01)
    set Path.mainPathingRects[2] = makeSimplePathingRect(gg_rct_Pathing_02)
    set Path.mainPathingRects[3] = makeSimplePathingRect(gg_rct_Pathing_03)
    set Path.mainPathingRects[4] = makeSimplePathingRect(gg_rct_Pathing_04)
    set Path.mainPathingRects[5] = makeSimplePathingRect(gg_rct_Pathing_05)
    set Path.mainPathingRects[6] = makeSimplePathingRect(gg_rct_Pathing_06)
    set Path.mainPathingRects[7] = makeSimplePathingRect(gg_rct_Pathing_07)
    set Path.mainPathingRects[8] = makeSimplePathingRect(gg_rct_Pathing_08)
    set Path.mainPathingRects[9] = makeSimplePathingRect(gg_rct_Pathing_09)
    set Path.mainPathingRects[10] = makeSimplePathingRect(gg_rct_Pathing_10)
    set Path.mainPathingRects[11] = makeSimplePathingRect(gg_rct_Pathing_11)
    set Path.mainPathingRects[12] = makeSimplePathingRect(gg_rct_Pathing_12)
    set Path.mainPathingRects[13] = makeSimplePathingRect(gg_rct_Pathing_13)
    set Path.mainPathingRects[14] = makeSimplePathingRect(gg_rct_Pathing_14)
    set Path.mainPathingRects[15] = makeSimplePathingRect(gg_rct_Pathing_15)
    set Path.mainPathingRects[16] = makeSimplePathingRect(gg_rct_Pathing_16)
    set Path.mainPathingRects[17] = makeSimplePathingRect(gg_rct_Pathing_17)
    set Path.mainPathingRects[18] = makeSimplePathingRect(gg_rct_Pathing_18)
    set Path.mainPathingRects[19] = makeSimplePathingRect(gg_rct_Pathing_19)
    set Path.mainPathingRects[20] = makeSimplePathingRect(gg_rct_Pathing_20)
    set Path.mainPathingRects[21] = makeSimplePathingRect(gg_rct_Pathing_21)
    set Path.mainPathingRects[22] = makeSimplePathingRect(gg_rct_Pathing_22) 
    set Path.mainPathingRects[23] = makeSimplePathingRect(gg_rct_Pathing_23) 
    set Path.mainPathingRects[24] = makeSimplePathingRect(gg_rct_Pathing_24) 
    set Path.mainPathingRects[25] = makeSimplePathingRect(gg_rct_Pathing_25) 
    set Path.mainPathingRects[26] = makeSimplePathingRect(gg_rct_Pathing_26) 
    set Path.mainPathingRects[27] = makeSimplePathingRect(gg_rct_Pathing_27)
    set Path.mainPathingRects[28] = makeSimplePathingRect(gg_rct_Pathing_28)
    set Path.mainPathingRects[29] = makeSimplePathingRect(gg_rct_Pathing_29)
    set Path.mainPathingRects[30] = makeSimplePathingRect(gg_rct_Pathing_30)
    set Path.mainPathingRects[31] = makeSimplePathingRect(gg_rct_Pathing_31)
    set Path.mainPathingRects[32] = makeSimplePathingRect(gg_rct_Pathing_32)
    set Path.mainPathingRects[33] = makeSimplePathingRect(gg_rct_Pathing_End)
    set Path.mainLength = 34
    
    set h = Path.create(0)
    // SUBWAY 1
    set h = Path.create(3)
    call h.add(gg_rct_Pathing_SUB1_0)
    call h.add(gg_rct_Pathing_SUB1_01)
    // SUBWAY 2    
    set h = Path.create(6)
    call h.add(gg_rct_Pathing_SUB2_0)
    call h.add(gg_rct_Pathing_SUB2_01)
    // SUBWAY 3    
    set h = Path.create(8)
    call h.add(gg_rct_Pathing_SUB3_0)
    call h.add(gg_rct_Pathing_SUB3_01)
    //call h.add(gg_rct_Pathing_0)
    //...
    //call h.add(gg_rct_Pathing_12)
  endmethod

  ////////////
  // Create a new Path
  ////////////
  private static method create takes integer mainPathEnterIndex returns Path
    local Path h
    
    //set d.pathingRects[0] = makeSimplePathingRect(gg_rct_Pathing_0)
    //set d.pathingRects[20] = makeSimplePathingRect(gg_rct_Pathing_End)
    
    set h.length = 0
    set h.mainPathEnterIndex = mainPathEnterIndex

    set Path.numAllocated = Path.numAllocated + 1
    set Path.references[Path.numAllocated] = h
    return h
  endmethod
  
  //=====================================
  //=== FUNCTIONS =======================
  //=====================================
  //////////
  
  public method add takes rect r returns nothing
    if(this.length >= VAL_MAXNUM_WAYPOINTS) then
      call showMessage("Critical Map Error: subpathlength out of bounds")
      return
    endif
    set this.pathingRects[this.length] = r
    set this.length = this.length + 1
  endmethod
  
  public method getWaypoint takes integer index returns rect
    if(index < this.length) then
      return this.pathingRects[index]
    else
      return Path.mainPathingRects[this.mainPathEnterIndex + (index - this.length)]
    endif
  endmethod
  
  public method size takes nothing returns integer
    return this.length + (Path.mainLength - this.mainPathEnterIndex)
  endmethod

  //=====================================
  //=== PROPERTIES ======================
  //=====================================

  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////
  
  ////////////
  private method onDestroy takes nothing returns nothing
    call showMessage("Critical Map Error: Path struct destroyed")
  endmethod

endstruct

