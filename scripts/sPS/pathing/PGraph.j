// this class is a singelton
struct PGraph
  private integer pnodecount
  private PNode array pnodes[PConfig_MAX_PNODES]
  
  private PGraphToolkit toolkit
  
  // this trigger is invoked whenever a unit enters a inner-pathing-rect of an edge
  private trigger trigPathing
  
  // we use a singelton pattern here;
  // cause we need only one pathing graph, 
  // maybe change this if u need multiple pathing graphes 
  // (change 'create' to public and delete the Singelton-macro)
  //! runtextmacro Singelton("PGraph")
  private static method create takes nothing returns PGraph
    local PGraph h
    
    //try to allocate
    set h = PGraph.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate a PGraph.")
      return nill
    endif
      
    set h.toolkit = PGraphToolkit.create(h)
    set h.trigPathing = CreateTrigger()
    
    return h
  endmethod
  
  //=====================================
  //=== PROPERTIES ======================
  //=====================================
  public method getNodeCount takes nothing returns integer
    return this.pnodecount
  endmethod
  
  // get a node of the graph by the node index
  public method getNode takes integer index returns PNode
    return this.pnodes[index]
  endmethod
  
  public method getToolkit takes nothing returns PGraphToolkit
    return this.toolkit
  endmethod
  
  // get a _random_ node in rect
  // _random_ cause we cant return an array or a list here 'easy'
  public method getRandomNodeInRect takes rect r returns PNode
    local group g = CreateGroup()
    local unit u
    local PNode node
    
    // GroupEnumUnitsInRectExPlayer - cause NODE_INDICATORs are maybe locusts ('i hope so :)')
    call GroupEnumUnitsInRectExPlayer(g, r, PGS.getNodeIndicatorFilter(), PConfig_OWNER)
    set u = GroupPickRandomUnit(g)
    set node = PNode.fromUnit(u)
    
    //clearup
    call DestroyGroup(g)
    set g = null
    set u = null
    
    return node
  endmethod
  
  //=====================================
  //=== MUTATORS ========================
  //=====================================
  //////////
  public method addNode takes PNode n returns boolean
    if(this.pnodecount >= PConfig_MAX_PNODES) then
      call showMessage("Critical Map Error: max pathcount in PGraph exceeded. [PGraph.addNode]")
      return false
    endif
    
    set this.pnodes[this.pnodecount] = n
    set this.pnodecount = this.pnodecount + 1
    
    return true
  endmethod
  
  //////////
  // Adds a rect as a source of pathing events
  //////////
  public method addPathingEventRect takes rect r returns nothing
    if (r != null) then
      call TriggerRegisterEnterRectSimple(this.trigPathing, r)
    endif
  endmethod
  
  //////////
  public method registerForPathing takes code c returns nothing
    call TriggerAddAction(this.trigPathing, c)
  endmethod
endstruct
