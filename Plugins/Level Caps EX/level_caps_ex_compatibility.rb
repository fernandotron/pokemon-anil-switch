module LevelCapsEX
  LEVEL_CAP_VARIABLE = 40 # Beispiel-Variable für Level-Cap

  def self.current_level_cap
    return $game_variables[LEVEL_CAP_VARIABLE] || 0
  end

  def self.voltseons_pause_menu_exists?
    return defined?(VoltseonsPauseMenu_Scene)
  end
end

if LevelCapsEX.voltseons_pause_menu_exists?
  #-------------------------------------------------------------------------------
  # Level Cap Hud component for LevelCapsEX
  #-------------------------------------------------------------------------------
  class VPM_LevelCapHud < Component
    def start_component(viewport, menu)
      super(viewport, menu)
      @sprites["overlay"] = BitmapSprite.new(Graphics.width / 2, 32, viewport)
      @sprites["overlay"].ox = @sprites["overlay"].bitmap.width
      @sprites["overlay"].x = Graphics.width
      # Y-Position des Textes etwas höher setzen (z.B. auf 90)
      @sprites["overlay"].y = 90
      @base_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTCOLOR, Color.new(248, 248, 248))
      @shdw_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTOUTLINE, Color.new(48, 48, 48))
    end

    def should_draw?; return true; end

    def refresh
      level_cap = LevelCapsEX.current_level_cap
      text = _INTL("Current Lvl Cap: {1}", level_cap)
      @sprites["overlay"].bitmap.clear
      pbSetSystemFont(@sprites["overlay"].bitmap)
      pbDrawTextPositions(@sprites["overlay"].bitmap, [
        [text, (Graphics.width / 2) - 8, 12, 1, @base_color, @shdw_color]
      ])
    end
  end

  # Füge die neue Komponente zur Liste der Menükomponenten hinzu
  MENU_COMPONENTS << :VPM_LevelCapHud if defined?(MENU_COMPONENTS)
end