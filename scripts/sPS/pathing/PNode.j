///////////////////////////////////////////////////////////////////////////
// This interface represents a strategie on PNodes for all
// runners who enters this node
//
// USES:
//   - General library
//   - Path
//   - PRunner
//
// USED BY:
//   - PNode
//   - PGraphGenerator
//
///////////////////////////////////////////////////////////////////////////
interface PNodeStrategy
  // p - the node who is entered
  // r - the entering runner
  public method run takes PNode p, PRunner r returns nothing
endinterface

///////////////////////////////////////////////////////////////////////////
// This structure represents a pathing-node with a PNodeStrategy
//
// USES:
//   - General library
//   - PEdge
//   - PConfig
//   - PNodeStrategy and all sub-classes
//
///////////////////////////////////////////////////////////////////////////

struct PNode
  // to find this node by its nodeIndicator
  readonly static PNode array references
  readonly static integer numAllocated = 0
  readonly integer arrayIndex
  readonly unit nodeIndicator
  private rect inner_pathingRect
  private rect outer_pathingRect

  private PNodeStrategy strategy
  
  readonly integer edgecount = 0
  readonly PEdge array edges[PConfig_MAX_NODE_EDGES]
  
  ////////////
  // PNode
  ////////////
  //! runtextmacro EnforcePermanent("PNode")
  public static method create takes PNodeStrategy strategy, unit nodeIndicator, rect inner_pathingRect, rect outer_pathingRect returns PNode
    local PNode h
    
    // try to allocate
    set h = PNode.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate a PNode.")
      return nill
    endif
    
    set h.strategy = strategy
    set h.inner_pathingRect = inner_pathingRect
    set h.outer_pathingRect = outer_pathingRect
    set h.nodeIndicator = nodeIndicator
    
    if(h.strategy == nill) then
      call showMessage("Critical Map Error: no strategy [PNode.create]")
      return nill
    endif
    
    // to find this node by its nodeIndicator
    set PNode.numAllocated = PNode.numAllocated + 1
    set h.arrayIndex = PNode.numAllocated
    set PNode.references[PNode.numAllocated] = h
    call SetUnitUserData(h.nodeIndicator, PNode.numAllocated)
    
    return h
  endmethod
  
  // Returns the node structure by its nodeIndicator
  public static method fromUnit takes unit u returns PNode
    local integer i

    //custom value should point to correct index
    set i = GetUnitUserData(u)
    if (i > 0 and i <= PNode.numAllocated and PNode.references[i].nodeIndicator == u) then
      return PNode.references[i]
    endif

    return nill
  endmethod

  // what to do with runners, who reaching the node?
  // !! this method have the answer :D !!
  public method handelRunner takes PRunner r returns nothing
    if(this.strategy == nill) then
      call showMessage("Critical Map Error: no strategy [PNode.handelRunner]")
      return
    endif
  
    call this.strategy.run(this, r)
  endmethod
  
  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  ////////////
  // the inner pathing rect of the node, (for 'triggering')
  public method getPathingRect_Inner takes nothing returns rect
    return this.inner_pathingRect
  endmethod
  
  ////////////
  // the outer pathing rect of the node, (for 'contains')
  public method getPathingRect_Outer takes nothing returns rect
    return this.outer_pathingRect
  endmethod
  
  ////////////
  // get count of edges thas begins at this node
  public method getIncidentEdgeCount takes nothing returns integer
    return this.edgecount
  endmethod
  
  public method getEdge takes integer index returns PEdge
    return this.edges[index]
  endmethod
  
  //=====================================
  //=== MUTATORS ========================
  //=====================================
  //////////
  // add an incident edge to the node
  // a edge _from_ this node to an other
  public method addEdge takes PEdge e returns boolean
    if(this.edgecount >= PConfig_MAX_NODE_EDGES) then
      call showMessage("Critical Map Error: max edgecount in RandomPathPNodeStrategy exceeded. [PNode.addEdge]")
      return false
    endif
    
    set this.edges[this.edgecount] = e
    set this.edgecount = this.edgecount + 1
    
    return true
  endmethod
endstruct
