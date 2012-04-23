///////////////////////////////////////////////////////////////////////////
// This structure represents the energy transfers between pairs of towers.
// It does most of the energy transfer (towers are responsible for their
// transfer limit, not this structure) and handles all the lightning effects.
//
// USES:
//   * libraries
//   - Tower struct
//
// USED BY:
//   - Tower struct
//
// NOTES:
//   - Uniqueness: one transfer per src/dst Towers
///////////////////////////////////////////////////////////////////////////
struct TowerTransfer
    readonly static integer numAllocated = 0

    readonly Tower src = nill
    readonly Tower dst = nill
    readonly lightning beam = null
    readonly integer lastBeamLevel = 0
    readonly integer lastEnergy = 0

    public static method createlong takes Tower src, Tower dst returns TowerTransfer
      local TowerTransfer tt
      
      //check for common failures
      if (src == null) then
        return nill
      elseif (dst == null or dst == src) then
        call showUnitText(src.u, "Invalid Target", 100, 0, 0)
        return nill
      elseif (src.numTransfersOut > 0) then
        call showUnitText(dst.u, "Already transfering, a long transfer need to be the only transfer!", 100, 80, 0)
        return nill
      elseif (dst.numTransfersIn >= VAL_MAX_TOWER_TRANSFERS) then
        call showUnitText(dst.u, "Max Transfers In", 100, 0, 0)
        return nill 
      elseif (TowerTransfer.fromSrcDst(src, dst) != nill) then
        call showUnitText(dst.u, "Already Transfering", 100, 80, 0)
        return nill
      endif
        
      //try to allocate
      set tt = TowerTransfer.allocate()
      if (tt == nill) then
        call showMessage("Critical Map Error: couldn't allocate TowerTransfer struct. (TowerTransfer.create)")
        return nill
      endif

      //pass values
      set tt.src = src
      set tt.dst = dst
      set tt.beam = null
      set tt.lastBeamLevel = -1
      set tt.lastEnergy = 1

      //insert tt into src and dst
      if (src.insertTransfer(tt) == false or dst.insertTransfer(tt) == false) then
        call showMessage("Critical Map Error: Couldn't insert seemingly fine transfer between towers. (TowerTransfer.create)")
        call tt.destroy()
        return nill
      endif
      // mark this is a long transfer
      set src.isTransferingLong = true

      //output
      call PlaySoundAtPointBJ(gg_snd_PowerTransfer, 100, dst.p, 0)
      call tt.draw()

      set TowerTransfer.numAllocated = TowerTransfer.numAllocated + 1
      return tt
    endmethod
    
    //////////
    // Creates a transfer between two towers
    // NOTE: floating text messages on common failures
    // src = the source tower
    // dst = the destination tower
    // return = the tower transfer
    //////////
    public static method create takes Tower src, Tower dst returns TowerTransfer
        local TowerTransfer tt

        //check for common failures
        if (src == null) then
            return nill
        elseif (dst == null or dst == src) then
            call showUnitText(src.u, "Invalid Target", 100, 0, 0)
            return nill
        elseif (src.numTransfersOut >= VAL_MAX_TOWER_TRANSFERS) then
            call showUnitText(src.u, "Max Transfers Out", 100, 0, 0)
            return nill     
        elseif (dst.numTransfersIn >= VAL_MAX_TOWER_TRANSFERS) then
            call showUnitText(dst.u, "Max Transfers In", 100, 0, 0)
            return nill     
        elseif (TowerTransfer.fromSrcDst(src, dst) != nill) then
            call showUnitText(dst.u, "Already Transfering", 100, 80, 0)
            return nill
        endif

        //try to allocate
        set tt = TowerTransfer.allocate()
        if (tt == nill) then
            call showMessage("Critical Map Error: couldn't allocate TowerTransfer struct. (TowerTransfer.create)")
            return nill
        endif

        //pass values
        set tt.src = src
        set tt.dst = dst
        set tt.beam = null
        set tt.lastBeamLevel = -1
        set tt.lastEnergy = 1

        //insert tt into src and dst
        if (src.insertTransfer(tt) == false or dst.insertTransfer(tt) == false) then
            call showMessage("Critical Map Error: Couldn't insert seemingly fine transfer between towers. (TowerTransfer.create)")
            call tt.destroy()
            return nill
        endif

        //output
        call PlaySoundAtPointBJ(gg_snd_PowerTransfer, 100, dst.p, 0)
        call tt.draw()

        set TowerTransfer.numAllocated = TowerTransfer.numAllocated + 1
        return tt
    endmethod

    ///Cleans up properly
    private method onDestroy takes nothing returns nothing
        local integer i
        if (this == nill) then
            return
        endif

        //Remove reference from endpoints
        call this.src.removeTransfer(this)
        call this.dst.removeTransfer(this)
        set this.src.isTransferingLong = false

        //Remove lightning effect
        call DestroyLightningBJ(this.beam)
        set this.beam = null

        set TowerTransfer.numAllocated = TowerTransfer.numAllocated - 1
    endmethod

    //////////
    // Finds the transfer from src to dst, if it exists
    // src = the source tower
    // dst = the destination tower
    // return = the transfer
    //////////
    public static method fromSrcDst takes Tower src, Tower dst returns TowerTransfer
        local integer i
        if (src == nill or dst == nill) then
            return nill
        endif

        //find in src's transferOuts (ignore dst's transferIns)
        set i = 1
        loop
            exitwhen i > src.numTransfersOut
            if (src.transfersOut[i].dst == dst) then
                return src.transfersOut[i]
            endif
            set i = i + 1
        endloop

        return nill
    endmethod

    //////////
    // Transfers energy from src to dst without exceeding their transfer capacities
    // Note: transfer power is not enforced here, it is enforced by the Tower structure
    // e = the maximum amount of energy to transfer
    // return = the actual amount of energy transfered
    //////////
    public method transferEnergy takes integer e returns integer
        if (this == nill) then
            return 0
        endif

        //don't overflow or underflow energy in src and dst
        if (this.src.getEnergy() < e) then
            set e = this.src.getEnergy()
        endif
        if (this.dst.maxEnergy - this.dst.getEnergy() < e) then
            set e = this.dst.maxEnergy - this.dst.getEnergy()
        endif
        if (this.dst.maxEnergy - this.dst.lastEnergy < e) then
            set e = this.dst.maxEnergy - this.dst.lastEnergy
        endif

        //complete the transfer
        set e = this.dst.receiveEnergy(e)
        call this.src.adjustEnergy(-e)
        set this.lastEnergy = e
        call this.draw()
        return e
    endmethod

    ///Changes the lightning effect to reflect last energy transfered
    private method draw takes nothing returns nothing
        local integer newBeamLevel

        //decide which beam level to use
        if (this.lastEnergy < 1) then
            set newBeamLevel = 0
        elseif (this.lastEnergy < 25) then
            set newBeamLevel = 1
        elseif (this.lastEnergy < 125) then
            set newBeamLevel = 2
        elseif (this.lastEnergy < 625) then
            set newBeamLevel = 3
        else
            set newBeamLevel = 4
        endif

        //replace the lightning effect
        if (newBeamLevel != this.lastBeamLevel) then
            call DestroyLightningBJ(this.beam)
            set this.lastBeamLevel = newBeamLevel

            if (newBeamLevel == 0) then
                set this.beam = AddLightningLoc("LEAS", this.src.p, this.dst.p) //magic leash
            elseif (newBeamLevel == 1) then
                set this.beam = AddLightningLoc("DRAL", this.dst.p, this.src.p) //drain life
            elseif (newBeamLevel == 2) then
                set this.beam = AddLightningLoc("DRAM", this.dst.p, this.src.p) //drain mana
            elseif (newBeamLevel == 3) then
                set this.beam = AddLightningLoc("HWSB", this.src.p, this.dst.p) //healing secondary
            else
                set this.beam = AddLightningLoc("SPLK", this.src.p, this.dst.p) //spirit link
            endif
        endif
    endmethod
endstruct