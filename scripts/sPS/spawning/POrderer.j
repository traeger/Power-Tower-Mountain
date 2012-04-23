struct POrderer
  //! runtextmacro EnforceStatic("POrderer")
  
  // pick all units of player "owner" in "spawnRect", 
  // create PRunners for each of them by using "runnerFactory"
  // change their owner to "newowner"
  // and order them through the graph.
  public static method order takes PGraph graph, rect spawnRect, PRunnerFactory runnerFactory, player owner, player newowner returns nothing
    local group g = GetUnitsInRectOfPlayer(spawnRect, owner)
    local unit u
    local PNode ordernode = graph.getRandomNodeInRect(spawnRect)
    
    if(ordernode == nill) then
      call showMessage("ERROR: no order-node [POrderer.order]")
      return
    endif
    
    loop
      set u = FirstOfGroup(g)
      exitwhen u == null
      call GroupRemoveUnit(g,u)
      
      // set the new owner, and change color
      call SetUnitOwner(u, newowner, true)
      // create the runner
      call PRunnerControl.setNodeObjective(runnerFactory.createRunner(u), ordernode)
    endloop
    
    // clearup
    call DestroyGroup(g)
    set g = null
    set u = null
  endmethod
endstruct
