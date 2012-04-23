globals
  constant integer WEATHER_EFFECT_LIGHTRAIN = 'RAlr'
  constant integer WEATHER_EFFECT_STRONGRAIN = 'RAhr'
  constant integer WEATHER_EFFECT_LIGHTSNOW = 'SNls'
  constant integer WEATHER_EFFECT_STRONGSNOW = 'SNhs'
  constant integer WEATHER_EFFECT_STRONGWIND = 'WNcw'
  
  constant integer WEATHER_TYPE_NON = 0
  constant integer WEATHER_TYPE_SUN = 1
  constant integer WEATHER_TYPE_LIGHTRAIN = 2
  constant integer WEATHER_TYPE_RAIN = 3
  constant integer WEATHER_TYPE_SNOW = 4
endglobals

struct Weather
  static integer current
  static weathereffect globalWeatherEffect = null
  
  public static method init0 takes nothing returns nothing
    //call Weather.changeGlobalWeather(WEATHER_TYPE_NON)
    
    //Events
    call Events.registerForChat(function Weather.catchChat)
  endmethod
  //! runtextmacro Init("Weather")
  
  public static method changeGlobalWeather takes integer weather returns nothing
    local integer weatherEffect
    
    call showMessage("Weather changed!")
    
    //call Weather.endCurrentWeather()
    
    if(weather == WEATHER_TYPE_NON) then
      
    elseif(weather == WEATHER_TYPE_SUN) then
      
    elseif(weather == WEATHER_TYPE_LIGHTRAIN) then
      call Weather.startLightrain()
    elseif(weather == WEATHER_TYPE_RAIN) then
      call Weather.startStrongrain()
    elseif(weather == WEATHER_TYPE_SNOW) then
      call Weather.startStrongsnow()
    endif
      
    set Weather.current = weather    
  endmethod
  
  private static method setGlobalWeatherEffect takes integer effectID returns nothing
    set Weather.globalWeatherEffect = AddWeatherEffect(GetPlayableMapRect(), effectID)
    call EnableWeatherEffect(Weather.globalWeatherEffect, true)
  endmethod
  
  private static method endCurrentWeather takes nothing returns nothing
    if(Weather.globalWeatherEffect != null) then
      call EnableWeatherEffect(Weather.globalWeatherEffect, false)
      call RemoveWeatherEffect(Weather.globalWeatherEffect)
      set Weather.globalWeatherEffect = null
    endif
  endmethod
  
  //////////////////////////
  // WEATHERTYPES
  //////////////////////////
  
  private static method startLightrain takes nothing returns nothing
    call Weather.setGlobalWeatherEffect(WEATHER_EFFECT_LIGHTRAIN)
  endmethod
  
  private static method startStrongrain takes nothing returns nothing
    call Weather.setGlobalWeatherEffect(WEATHER_EFFECT_STRONGRAIN)
  endmethod
  
  private static method startLightsnow takes nothing returns nothing
    call Weather.setGlobalWeatherEffect(WEATHER_EFFECT_LIGHTSNOW )
  endmethod
  
  private static method startStrongsnow takes nothing returns nothing
    call Weather.setGlobalWeatherEffect(WEATHER_EFFECT_STRONGSNOW)
  endmethod

  private static method startStrongwind takes nothing returns nothing
    call Weather.setGlobalWeatherEffect(WEATHER_EFFECT_STRONGWIND)
  endmethod
  
  ////////////////////
  // EVENTS
  ////////////////////
  
  ////////
  private static method catchChat takes nothing returns nothing
    local string s = StringCase(GetEventPlayerChatString(), false)
    if (s == "-weather 1") then
      call Weather.changeGlobalWeather(1)
    elseif (s == "-weather 2") then
      call Weather.changeGlobalWeather(2)
    elseif (s == "-weather 3") then
      call Weather.changeGlobalWeather(3)
    elseif (s == "-weather 4") then
      call Weather.changeGlobalWeather(4)
    elseif (s == "-weather off") then
      call Weather.endCurrentWeather()
    endif
  endmethod
endstruct
