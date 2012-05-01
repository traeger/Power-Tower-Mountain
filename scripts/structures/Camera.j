///////////////////////////////////////////////////////////////////////////
// This structure represents a camera.
//
// CREDITS:
// * THX to "Ijla the Snowman" aka drow_iljusch for helping me with the
//   Camera.changeRotation() method
//
///////////////////////////////////////////////////////////////////////////

globals
  constant integer MAX_NUM_CAMERA = 10

  constant real VAL_CAMTICKINTERVAL = 0.5
  constant real VAL_CAMSTDROTATE = 90
  constant real VAL_CAMSTDRANGE = 1700.00
  constant real VAL_CAMRANGEMIN = 700
  constant real VAL_CAMRANGEMAX = 4000
  
  // changeRotate
  constant real VAL_CAMROTATEVELOCITYMAX = 30
  constant real VAL_CAMROTATEACCELERATION = 20
endglobals

struct Camera 
  //! runtextmacro StructAlloc_Fixed("Camera", "MAX_NUM_CAMERA")
  //! runtextmacro StructIterable_Fixed("Camera", "MAX_NUM_CAMERA")

  private static trigger trgLeftPressed = CreateTrigger()
  private static trigger trgLeftReleased = CreateTrigger()
  private static trigger trgRightPressed = CreateTrigger()
  private static trigger trgRightReleased = CreateTrigger()

  readonly static boolean cameraActiv = false
  
  readonly player p
  
  readonly unit cameraTarget = null
  readonly real camRange
  
  // changeRotate
  readonly real camRotateVelocity = 0
  readonly real camRotateAcceleration = 0
  readonly real camRotateDirection = 0
  readonly real camRotate

  // changeRotate - keys
  readonly boolean keyLeftPressed = false
  readonly boolean keyRightPressed = false
  
  ////////////
  // Creates camera for a player
  // i = the player index (1 = P1, 2 = P2, ...)
  // return = the new camera
  ////////////
  public static method create takes player p returns Camera
    local Camera h
    local integer i = GetConvertedPlayerId(p)
	
	set h = Camera.alloc(i)

    set h.p = p
    set h.camRange = VAL_CAMSTDRANGE
    set h.camRotate = VAL_CAMSTDROTATE
   
    return h
  endmethod
  
  ////////////
  public static method fromPlayer takes player p returns Camera
    return Camera.fromIndex(GetConvertedPlayerId(p))
  endmethod
  ////////////
  public static method fromUnit takes unit u returns Camera
    return Camera.fromPlayer(GetOwningPlayer(u))
  endmethod
  
  private method nop takes nothing returns nothing
    //local trigger t
    //if (c == null) then
    //  return false
    //endif

    //set t = CreateTrigger()
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_LEFT_DOWN)
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_RIGHT_DOWN)
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_DOWN_DOWN)
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_UP_DOWN)
    //call TriggerAddAction(t, c)
    //set t = null
  
    //call Events.registerForKeyReleaseEvents(this.p, Gamer.catchKeyRelease)
    //call Events.registerForKeyReleaseEvents(this.p, Gamer.catchKeyRelease)

    //set t = CreateTrigger()
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_LEFT_UP)
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_RIGHT_UP)
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_DOWN_UP)
    //call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_ARROW_UP_UP)
    //call TriggerAddAction(t, c)
    //set t = null
  
    //  if (at == CAMERA_ABI_RESET) then
    //  set this.camRange = VAL_CAMSTDRANGE
    //  set this.camRotate = VAL_CAMSTDROTATE
      
    // zoom in
    //elseif (at == CAMERA_ABI_ZOOM_IN) then
    //  set this.camRange = this.camRange + VAL_CAMRANGESTEP
    //  if (this.camRange > VAL_CAMRANGEMAX) then
    //    set this.camRange = VAL_CAMRANGEMAX
    //  endif

    // zoom out
    //elseif (at == CAMERA_ABI_ZOOM_OUT) then
    //  set this.camRange = this.camRange - VAL_CAMRANGESTEP
    //  if (this.camRange < VAL_CAMRANGEMIN) then
    //    set this.camRange = VAL_CAMRANGEMIN
    //  endif

    // rotate right
    //elseif (at == CAMERA_ABI_ROTATE_RIGHT) then
    //  set this.camRotate = this.camRotate + VAL_CAMROTATESTEP  
      
    // rotate left
    //elseif (at == CAMERA_ABI_ROTATE_LEFT) then
    //set this.camRotate = this.camRotate - VAL_CAMROTATESTEP
    //endif

    //set u = null
  endmethod
    
  //=====================================
  //=== PROPERTIES ======================
  //=====================================  
    
    
  //=====================================
  //=== MUTATORS ========================
  //=====================================
  
  ////////////
  //Add a cameraTarget, and start the camera
  ////////////
  public method addCameraTarget takes unit cameraTarget returns nothing
    if(cameraTarget == null) then
      call showMessage("Map Error: no camera target [Camera.addCameraTarget].")
      return
    endif
  
    if (Camera.cameraActiv == false) then
      set Camera.cameraActiv = true
      call Events.registerForNewTicker(VAL_CAMTICKINTERVAL, function Camera.catchCamRangeTick)
    endif
  
    set this.cameraTarget = cameraTarget
    call SetCameraTargetControllerNoZForPlayer(this.p, this.cameraTarget, 0, 0, false)
  endmethod
  ////////////
  //Remove a cameraTarget, and stops the camera
  ////////////
  public method removeCameraTarget takes nothing returns nothing
    set this.cameraTarget = null
  endmethod

  // change if u want use the keybord-keys for rotate the camera or not
  public method useKeysForRotate takes boolean use returns nothing
    if(use) then
      call TriggerRegisterPlayerEvent(Camera.trgLeftPressed, this.p, EVENT_PLAYER_ARROW_LEFT_DOWN)
      call TriggerAddAction(Camera.trgLeftPressed, function Camera.catchKeyPress_Left)
    
      call TriggerRegisterPlayerEvent(Camera.trgRightPressed, this.p, EVENT_PLAYER_ARROW_RIGHT_DOWN)
      call TriggerAddAction(Camera.trgRightPressed, function Camera.catchKeyPress_Right)
    
      call TriggerRegisterPlayerEvent(Camera.trgLeftReleased, this.p, EVENT_PLAYER_ARROW_LEFT_UP)
      call TriggerAddAction(Camera.trgLeftReleased, function Camera.catchKeyRelease_Left)
    
      call TriggerRegisterPlayerEvent(Camera.trgRightReleased, this.p, EVENT_PLAYER_ARROW_RIGHT_UP)
      call TriggerAddAction(Camera.trgRightReleased, function Camera.catchKeyRelease_Right)
    else
      call showMessage("Disableing \"useKeysForRotate\" currently not available! (Camera.useKeysForRotate)")
    endif
  endmethod
  
  private method changeRotation takes nothing returns nothing
    // nothing to do
    if(this.camRotateVelocity == 0 and this.camRotateDirection == 0) then
      return
    endif
  
    // slow down
    if(this.camRotateDirection == 0) then
      if(this.camRotateVelocity == 0) then
        set this.camRotateAcceleration = 0
      elseif(this.camRotateVelocity > 0 ) then
        set this.camRotateAcceleration = 2 * -VAL_CAMROTATEACCELERATION
      else
        set this.camRotateAcceleration = 2 * VAL_CAMROTATEACCELERATION
      endif
    // speedup positiv direction
    elseif(this.camRotateDirection > 0) then
      if(this.camRotateVelocity < VAL_CAMROTATEVELOCITYMAX) then
        set this.camRotateAcceleration = VAL_CAMROTATEACCELERATION
      else
        set this.camRotateAcceleration = 0
      endif
    // speedup negativ direction
    else
      if(this.camRotateVelocity > -VAL_CAMROTATEVELOCITYMAX) then
        set this.camRotateAcceleration = -VAL_CAMROTATEACCELERATION
      else
        set this.camRotateAcceleration = 0
      endif
    endif
    
    // trashhold to avoid jumping around if velocity is close to zero
    if(this.camRotateDirection == 0 and RAbsBJ(this.camRotateVelocity) < 1.1 * VAL_CAMTICKINTERVAL * VAL_CAMROTATEACCELERATION) then
      set this.camRotateVelocity = 0
    // set the new velocity
    else
      set this.camRotateVelocity = this.camRotateVelocity + this.camRotateAcceleration * VAL_CAMTICKINTERVAL
    endif
    // set the new rotate angle
    set this.camRotate = this.camRotate + this.camRotateVelocity
  endmethod
  
  //=====================================
  //=== EVENTS ==========================
  //=====================================
  //////////
  public static method catchCamRangeTick takes nothing returns nothing
    local Camera h
    
	call Camera.iterate()
    loop
      exitwhen Camera.iterateFinished()

      set h = Camera.next()
      if(h.cameraTarget != null) then
        call h.changeRotation()
      
        call SetCameraFieldForPlayer(h.p, CAMERA_FIELD_TARGET_DISTANCE, h.camRange, VAL_CAMTICKINTERVAL)
        call SetCameraFieldForPlayer(h.p, CAMERA_FIELD_ROTATION, h.camRotate, VAL_CAMTICKINTERVAL)
      endif
    endloop
  endmethod
  
  public static method catchKeyPress_Right takes nothing returns nothing
    local Camera h = Camera.fromPlayer(GetTriggerPlayer())
    if(h == nill) then
      call showMessage("no camera (Camera.catchKeyPress_Right)")
      return
    endif
  
    set h.keyRightPressed = true
    set h.camRotateDirection = h.camRotateDirection + 1
    //if(h.keyLeftPressed) then
    //  set h.camRotateDirection = 0
    //else
    //  set h.camRotateDirection = 1
    //endif
  endmethod
  
  public static method catchKeyRelease_Right takes nothing returns nothing
    local Camera h = Camera.fromPlayer(GetTriggerPlayer())
    if(h == nill) then
      call showMessage("no camera (Camera.catchKeyRelease_Right)")
      return
    endif

    set h.keyRightPressed = false
    set h.camRotateDirection = h.camRotateDirection - 1
    //if(h.keyLeftPressed) then
    //  set h.camRotateDirection = -1
    //else
    //  set h.camRotateDirection = 0
    //endif
  endmethod
  
  public static method catchKeyPress_Left takes nothing returns nothing
    local Camera h = Camera.fromPlayer(GetTriggerPlayer())
    if(h == nill) then
      call showMessage("no camera (Camera.catchKeyPress_Left)")
      return
    endif
  
    set h.keyLeftPressed = true
    set h.camRotateDirection = h.camRotateDirection - 1
    //if(h.keyRightPressed) then
    //  set h.camRotateDirection = 0
    //else
    //  set h.camRotateDirection = -1
    //endif
  endmethod
  
  public static method catchKeyRelease_Left takes nothing returns nothing
    local Camera h = Camera.fromPlayer(GetTriggerPlayer())
    if(h == nill) then
      call showMessage("no camera (Camera.catchKeyRelease_Left)")
      return
    endif
  
    set h.keyLeftPressed = false
    set h.camRotateDirection = h.camRotateDirection + 1
    //if(h.keyRightPressed) then
    //  set h.camRotateDirection = 1
    //else
    //  set h.camRotateDirection = 0
    //endif
  endmethod
endstruct
