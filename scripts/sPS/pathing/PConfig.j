scope PConfig initializer init
  globals
    ////////////////////
    // Generator
    ////////////////////
    public constant player OWNER = ConvertedPlayer(10)
  
    public constant integer UT_EGDEPOINT_1 = 'm000'
    public constant integer UT_EGDEPOINT_2 = 'm002'
    public constant integer UT_NODE_DIR = 'm001'
    public constant integer UT_NODE_SINK = 'm003'
    public constant integer UT_NODE_INDICATOR = 'm004'
    
    // the size of the inner rect of a graph-point
    // (used for 'on pathing'-triggers)
    public constant integer RECTSIZE_INNER = 512
    
    // the size of the order circle
    // if a unit is ordered to a inner-rect, a circle of dimiter
    // RECTSIZE_INNER * ORDER_CIRCLE_PERCENT is created
    // to avoid some order errors (of 1 or greater is choosen here
    // the unit maybe never reach the inner-rect)
    public constant real ORDER_CIRCLE_PERCENT = 0.8
    
    // the size of the outer rect of a graph-point
    // (used for 'contains loc')
    public constant integer RECTSIZE_OUTER = 800
    
    // the maximum range for the next edge point.
    // if ur path are not found.. maybe the distances of points of ur edges
    // are greater than this value.
    // NOTE: a big value slows down the system
    public constant integer MAXPOINTRANGE = 5000
    
    // the maximum sightangle-tolerance for the next edge point.
    // if ur path are not found.. check the orientation of ur pathingpoints.
    // this value is in degree for both sites of the sightdirection
    // NOTE: a big value maybe creates errors on pathlinking
    // NOTE: a big value slows down the system
    public constant integer MAXPOINTANGLE = 2
    
    // the radius of a node.
    // all pathing-units in this area are one node.
    // NOTE: a big value maybe creates errors in nodedetection
    public constant real NODERADIUS = 128
    
    // maximum number of nodes in the graph
    public constant integer MAX_PNODES = 200
    
    // maxium number of incident-edges of one node
    public constant integer MAX_NODE_EDGES = 3
    
    // maxium number of waypoints of one edge
    public constant integer MAX_EDGE_WAYPOINTS = 10
    
    ////////////////////
    // Runner Control
    ////////////////////
    
    // a time interval, whenever this interval-time is gone
    // reorder the runner
    // NOTE: only for testcases, this lags like hell.
    public constant boolean USE_RUNNER_REORDER_TICK = false
    public constant integer RUNNER_REORDER_TICK = 3
    
    ////////////////////
    // Toolkit
    ////////////////////
    
    // maximum count of lightnings drawn by the PGraphToolkit
    public constant integer DRAW_MAX_LIGHTNINGS = 4000
    
    ////////////////////
    // PRIVATE
    ////////////////////
    
    // 'true' if matching unit is a point of the graph
    //public conditionfunc FILTER_POINT
    // 'true' if matching unit is the start of a edge
    //public conditionfunc FILTER_PATHSTART
    // 'true' if matching unit is a node indcator
    // (an identifier for a node in the graph)
    //public conditionfunc FILTER_NODE_INDICATOR
  endglobals
  
  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  
  public function isIndicatorTypeNode takes unit u returns boolean
    return PGS.isNodeType(GetUnitTypeId(u))
  endfunction
  
  public function isIndicatorTypeEdge takes unit u returns boolean
    return PGS.isEdgeType(GetUnitTypeId(u))
  endfunction
  
  //returns a strategy in dependence to the node type
  public function getPNodeStrategy takes unit u returns PNodeStrategy
    return PGS.getNodeStrategy(GetUnitTypeId(u))
  endfunction
  
  //=====================================
  //=== FILTER ==========================
  //=====================================
  
  //private function p_filter_point takes nothing returns boolean
  //  local unit u = GetFilterUnit()
  //  return isIndicatorTypeNode(u) or isIndicatorTypeEdge(u) or (GetUnitTypeId(u) == UT_NODE_INDICATOR)
  //endfunction
  
  //private function p_filter_pathstart takes nothing returns boolean
  //  return GetUnitTypeId(GetFilterUnit()) == UT_NODE_DIR
  //endfunction
  
  //private function p_filter_node_indicator takes nothing returns boolean
  //  return GetUnitTypeId(GetFilterUnit()) == UT_NODE_INDICATOR
  //endfunction
  
  private function init takes nothing returns nothing
    //set FILTER_POINT = Condition(function p_filter_point)
    //set FILTER_PATHSTART = Condition(function p_filter_pathstart)
    //set FILTER_NODE_INDICATOR = Condition(function p_filter_node_indicator)
    
    call PGS.initFilters()
    call PGS.addEdgeType(UT_EGDEPOINT_1)
    call PGS.addEdgeType(UT_EGDEPOINT_2)
    call PGS.addNodeStrategy(UT_NODE_DIR, RandomPNodeStrategy.getSingelton())
    call PGS.addNodeStrategy(UT_NODE_SINK, GoalPNodeStrategy.getSingelton())
  endfunction
endscope
