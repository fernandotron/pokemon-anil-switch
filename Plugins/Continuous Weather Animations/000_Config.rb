#===============================================================================
# Settings (optional customization)
#===============================================================================

module ContinuousWeatherSettings
  ENABLED = true
  # How often to restart weather animations (in frames, 60 = 1 second)
  ANIMATION_RESTART_INTERVAL = 600  # 10 seconds
  
  # Weather types that should NOT use continuous animation (keep original end-of-turn behavior)
  EXCLUDED_WEATHER_TYPES = []
end