struct OilTanker
  //! runtextmacro StructAlloc_Unit("OilTanker")
  //! runtextmacro Init("OilTanker")
  
  private integer goldPerHarvest = 1
  private integer manaMultiplier = 100
  private boolean returnsFromHarvest = false
  private Tower harbor
  
  public static method init0 takes nothing returns nothing
    call Events.registerForUnitTargetEvent(function OilTanker.catchUnitTargetEvent)
	call Events.registerForUnitFinishedTraining(function OilTanker.catchUnitFinishedTraining)
  endmethod
  
  public static method create takes unit u returns OilTanker
    return OilTanker.alloc(u)
  endmethod
  
  private method onDestroy takes nothing returns nothing
    if (this == nill) then
      return
    endif
	
	call this.dealloc()
  endmethod
  
  private static method catchUnitFinishedTraining takes nothing returns nothing
    if(GetUnitTypeId(GetTrainedUnit()) == 'u004') then
	  call OilTanker.create(GetTrainedUnit())
	endif
  endmethod
  
  private static method catchUnitTargetEvent takes nothing returns nothing
    local OilTanker t = OilTanker.fromUnit(GetTriggerUnit())
	if(t == nill) then
	  return
	endif
	
	if(GetIssuedOrderIdBJ() == String2OrderIdBJ("resumeharvesting")) then
	  set t.harbor = Tower.fromUnit(GetOrderTargetUnit())
	  if(t.harbor != nill) then
	    set t.returnsFromHarvest = true
	  endif
	elseif(GetIssuedOrderIdBJ() == String2OrderIdBJ("harvest")) then
	  if(t.returnsFromHarvest) then
	    call AdjustPlayerStateBJ( -t.goldPerHarvest, GetOwningPlayer(t.u), PLAYER_STATE_RESOURCE_GOLD )
		call t.harbor.receiveEnergy(t.goldPerHarvest * t.manaMultiplier)
		set t.harbor = nill
	  endif
	  set t.returnsFromHarvest = false
	endif
  endmethod
endstruct 
