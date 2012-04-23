///////////////////////////////////////////////////////////////////////////
// This structure represents Factory to produce Runner
//
///////////////////////////////////////////////////////////////////////////
interface PRunnerFactory
  public method createRunner takes unit u returns PRunner
endinterface

///////////////////////////////////////////////////////////////////////////
// This structure represents a ABSTRACT runner on a path
// A PRunner, follows a PEdge, and use PNode at PEdge-goals
// His current location on the path is indicated by his 
// pathing-objective (pObjective)
//
// USES:
//   - General library
//   - PObjective
//
///////////////////////////////////////////////////////////////////////////
struct PRunner extends ObjectiveUnit
  private PObjective pObjective

  public method getUnit takes nothing returns unit
    call showMessage("Critical Map Error: call DUMMY [PRunner.getUnit]")
    return null
  endmethod
  
  public method runObjective takes Objective o returns nothing
    call showMessage("Critical Map Error: call DUMMY [PRunner.runObjective]")
  endmethod
  
  public method setPObjective takes PObjective o returns nothing
    // clearup, discard the old objective
    if(this.pObjective != nill) then
      call this.pObjective.destroy()
    endif
    set this.pObjective = o
    call this.runObjective(this.pObjective)
  endmethod
  
  public method getPObjective takes nothing returns PObjective
    return this.pObjective
  endmethod
  
  public method updatedPObjective takes nothing returns nothing
    call this.runObjective(this.pObjective)
  endmethod
endstruct
