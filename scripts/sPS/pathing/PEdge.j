///////////////////////////////////////////////////////////////////////////
// This structure represents a pathing edge with a PNode at the
// goal of the edge
//
// USES:
//   - General library
//   - PNode
//   - PConfig
//
// USED BY:
//
///////////////////////////////////////////////////////////////////////////
function InitTrig_PEdge takes nothing returns nothing
  call PEdge.init()
endfunction

struct PEdge
  readonly static boolean initialized = false
  
  private rect array outer_pathingRects[PConfig_MAX_EDGE_WAYPOINTS]
  private rect array inner_pathingRects[PConfig_MAX_EDGE_WAYPOINTS]
  private integer length
  readonly PNode goal
  private PGraph graph

  public static method init takes nothing returns nothing
    local integer i
    local PEdge h
    
    if (PEdge.initialized == true) then
      call showMessage("Map Error: tried to initialize PEdge more than once.")
      return
    endif
    set PEdge.initialized = true
  endmethod

  ////////////
  // Create a new PEdge
  ////////////
  //! runtextmacro EnforcePermanent("PEdge")
  public static method create takes PGraph graph returns PEdge
    local PEdge h
    
    //try to allocate
    set h =PEdge.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate a PEdge.")
      return nill
    endif
    
    set h.graph = graph
    set h.length = 0
    
    return h
  endmethod
  
  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  public method getInnerPathingRect takes integer index returns rect
    return this.inner_pathingRects[index]
  endmethod
  
  public method getOuterPathingRect takes integer index returns rect
    return this.outer_pathingRects[index]
  endmethod
  
  public method getOrderLoc takes integer index returns location
    return GetRandomPointCloseToCenterInRect(this.getInnerPathingRect(index), PConfig_ORDER_CIRCLE_PERCENT)
  endmethod
  
  // does waypoint 'index' contains the unit?
  public method containsUnit takes integer index, unit u returns boolean
    return RectContainsUnit(this.outer_pathingRects[index], u)
  endmethod
  
  // the size of the edge (count of edgepoints)
  public method size takes nothing returns integer
    return this.length
  endmethod
  
  public method isGoal takes integer index returns boolean
    return index == (this.size() - 1)
  endmethod

  
  //=====================================
  //=== MUTATORS ========================
  //=====================================
  //////////
  
  // the outer-rect have to contain the inner-rect
  // WARNING: dont use _overlapping_ rects on different pathing-points! 
  // (i dont know whats happen)
  public method addWaypoint takes rect inner_r, rect outer_r returns nothing
    if(this.length >= PConfig_MAX_EDGE_WAYPOINTS) then
      call showMessage("Critical Map Error: edgecountout of bounds [PEgde.addWaypoint]")
      return
    endif
    if(inner_r == null or outer_r == null) then
      call showMessage("Critical Map Error: add \"null\"-rect [PEgde.addWaypoint]")
      return
    endif
    
    // inner rect is for pathing triggering
    call this.graph.addPathingEventRect(inner_r)
    
    // outer rect for 'contains'-check
    // so we need to store it
    set this.outer_pathingRects[this.length] = outer_r
    set this.inner_pathingRects[this.length] = inner_r
    set this.length = this.length + 1
  endmethod
  
  // add the goal of this edge (a PNode)
  // the goal will handle incoming runners
  public method addGoal takes PNode goal returns nothing
    set this.goal = goal
  endmethod
  
  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////

endstruct
