///////////////////////////////////////////////////////////////////////////
// This structure represents a pathing-objective
//
// USES:
//   - General library
//   - PEdge
//
///////////////////////////////////////////////////////////////////////////
struct PObjective extends Objective
  public PEdge edge
  public integer egdeOffset

  public static method createEdgeObjectiv takes PEdge edge, integer egdeOffset returns PObjective
    local PObjective h
    
    //try to allocate
    set h = PObjective.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate a PObjective.")
      return nill
    endif
    
    set h.edge = edge
    set h.egdeOffset = egdeOffset
    
    return h
  endmethod
endstruct
