///////////////////////////////////////////////////////////////////////////
// This strategie spawn a unit on every interval-tick
//
// USES:
//   - PSpawn
//
///////////////////////////////////////////////////////////////////////////
struct SimplePSpawnStrategy extends PSpawnStrategy
  private integer ut
  private player owner

  public static method create takes integer ut, player owner returns SimplePSpawnStrategy
    local SimplePSpawnStrategy h
    
    //try to allocate
    set h = SimplePSpawnStrategy.allocate()
    if (h == nill) then
      call showMessage("Critical Map Error: couldn't allocate a SimplePSpawnStrategy.")
      return nill
    endif
    
    set h.ut = ut
    set h.owner = owner
    
    return h
  endmethod

  public method run takes PSpawn spawn returns nothing
    call spawn.createUnit(this.ut, this.owner)
  endmethod
endstruct
