  # PokemonPauseMenu_Scene is a class that represents the pause menu scene in the Pokemon game.
# It provides methods for starting the scene, drawing the fly shortcut, and other related functionality.
class DP_PauseMenu
  # Constants for shortcut positioning
  SHORTCUT_START_Y = 4
  SHORTCUT_SPACING = 70
  SHORTCUT_X = 4
  ICON_X = 11
  ICON_Y_OFFSET = 6
  TEXT_X = 64
  TEXT_Y_OFFSET = 24
  BG_TOP_HEIGHT = 12
  BG_MID_HEIGHT = 38
  
  # Constants for right-side icon positioning (sun/moon area)
  RIGHT_ICON_START_X = 245
  RIGHT_ICON_SHORT_HEIGHT = 28  # Estimated height of sun/moon icon container
  RIGHT_ICON_SPACING = 60

  ICONS_PATH = File.join("Graphics", "Pictures", "DP Pause Menu")
  
  # Helper method to get the next available Y position for shortcuts
  def get_next_shortcut_y_position
    @current_shortcut_y ||= SHORTCUT_START_Y
    position = @current_shortcut_y
    @current_shortcut_y += SHORTCUT_SPACING
    position
  end
  
  # Helper method to reset shortcut positioning
  def reset_shortcut_positioning
    @current_shortcut_y = SHORTCUT_START_Y
  end
  
  # Helper method to get the next available Y position for right-side icons
  def get_next_right_icon_y_position
    @current_right_icon_y ||= SHORTCUT_START_Y # Start below sun/moon + small gap
    position = @current_right_icon_y
    @current_right_icon_y += RIGHT_ICON_SPACING
    position
  end
  
  # Helper method to reset right-side icon positioning
  def reset_right_icon_positioning
    @current_right_icon_y = SHORTCUT_START_Y
  end

  def draw_fly_shortcut
    # Color base del texto mostrado
    base_color = Color.new(250, 250, 250)
    # Color de sombra del texto mostrado
    shadow_color = Color.new(75, 75, 75)
    
    # Get dynamic position for this shortcut
    y_pos = get_next_shortcut_y_position

    @sprites[:riderTop] = Sprite.new(@viewport2)
    @sprites[:riderTop].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgTop")
    @sprites[:riderTop].y = y_pos
    @sprites[:riderTop].x = SHORTCUT_X
    
    @sprites[:riderMid] = Sprite.new(@viewport2)
    @sprites[:riderMid].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgMid")
    @sprites[:riderMid].y = y_pos + BG_TOP_HEIGHT
    @sprites[:riderMid].x = SHORTCUT_X
    @sprites[:riderMid].zoom_y = BG_MID_HEIGHT
    
    @sprites[:riderBtm] = Sprite.new(@viewport2)
    @sprites[:riderBtm].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgBtm")
    @sprites[:riderBtm].y = y_pos + BG_TOP_HEIGHT + @sprites[:riderMid].zoom_y
    @sprites[:riderBtm].x = SHORTCUT_X

    bitmap = pbBitmap('Graphics/Pictures/DP Pause Menu/rider')
    @sprites[:pokerider_txt] = TextSprite.new(@viewport2)
    @sprites[:pokerider] = Sprite.new(@viewport2)
    @sprites[:pokerider].bitmap = bitmap
    @sprites[:pokerider].x = ICON_X
    @sprites[:pokerider].y = y_pos + ICON_Y_OFFSET
    @sprites[:pokerider_txt].draw([
                          ['[ZL] Volar', TEXT_X, y_pos + TEXT_Y_OFFSET, 0, base_color, shadow_color, true]
                        ])
  end

  def draw_vial_shortcut(refresh = false)
      # Color base del texto mostrado
      base_color = Color.new(250, 250, 250)
      # Color de sombra del texto mostrado
      shadow_color = Color.new(75, 75, 75)

      # Get or calculate position for this shortcut
      if !refresh
        # Store the position for this shortcut if it's the first time drawing
        @vial_y_pos = get_next_shortcut_y_position
        
        @sprites[:vialTop] = Sprite.new(@viewport2)
        @sprites[:vialTop].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgTop")
        @sprites[:vialTop].y = @vial_y_pos
        @sprites[:vialTop].x = SHORTCUT_X

        @sprites[:vialMid] = Sprite.new(@viewport2)
        @sprites[:vialMid].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgMid")
        @sprites[:vialMid].y = @vial_y_pos + BG_TOP_HEIGHT
        @sprites[:vialMid].x = SHORTCUT_X
        @sprites[:vialMid].zoom_y = BG_MID_HEIGHT

        @sprites[:vialBtm] = Sprite.new(@viewport2)
        @sprites[:vialBtm].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgBtm")
        @sprites[:vialBtm].y = @vial_y_pos + BG_TOP_HEIGHT + @sprites[:vialMid].zoom_y
        @sprites[:vialBtm].x = SHORTCUT_X
      else
        @sprites[:vial_txt]&.dispose
        @sprites[:vial]&.dispose
      end 

      $PokemonGlobal.vial_charges ||= INITIAL_CHARGES_POKEVIAL
      $PokemonGlobal.max_vial_charges ||= INITIAL_CHARGES_POKEVIAL
      
      # Gráfico del Vial según la carga que quede
      bitmap = $PokemonGlobal.vial_charges > 0 ? pbBitmap('Graphics/Items/VIAL') : pbBitmap('Graphics/Items/EMPTYVIAL')

      @sprites[:vial_txt] = TextSprite.new(@viewport2)
      @sprites[:vial] = Sprite.new(@viewport2)
      @sprites[:vial].bitmap = bitmap
      @sprites[:vial].x = ICON_X + 1
      @sprites[:vial].y = @vial_y_pos + ICON_Y_OFFSET
      # Escribimos el número de cargas que quedan y el máximo
      @sprites[:vial_txt].draw([
                            ["[Y] Vial (#{$PokemonGlobal.vial_charges}/#{$PokemonGlobal.max_vial_charges})", TEXT_X, @vial_y_pos + TEXT_Y_OFFSET, 0, base_color, shadow_color, true]
                          ])
  end

  def draw_radar_shortcut
    # Color base del texto mostrado
    base_color = Color.new(250, 250, 250)
    # Color de sombra del texto mostrado
    shadow_color = Color.new(75, 75, 75)
    
    # Get dynamic position for this shortcut
    y_pos = get_next_shortcut_y_position
    
    @sprites[:radarTop] = Sprite.new(@viewport2)
    @sprites[:radarTop].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgTop")
    @sprites[:radarTop].y = y_pos
    @sprites[:radarTop].x = SHORTCUT_X
    
    @sprites[:radarMid] = Sprite.new(@viewport2)
    @sprites[:radarMid].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgMid")
    @sprites[:radarMid].y = y_pos + BG_TOP_HEIGHT
    @sprites[:radarMid].x = SHORTCUT_X
    @sprites[:radarMid].zoom_y = BG_MID_HEIGHT
    
    @sprites[:radarBtm] = Sprite.new(@viewport2)
    @sprites[:radarBtm].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgBtm")
    @sprites[:radarBtm].y = y_pos + BG_TOP_HEIGHT + @sprites[:radarMid].zoom_y
    @sprites[:radarBtm].x = SHORTCUT_X

    bitmap = pbBitmap('Graphics/Items/RADAR')
    @sprites[:radar_txt] = TextSprite.new(@viewport2)
    @sprites[:radar] = Sprite.new(@viewport2)
    @sprites[:radar].bitmap = bitmap
    @sprites[:radar].x = ICON_X
    @sprites[:radar].y = y_pos + ICON_Y_OFFSET
    @sprites[:radar_txt].draw([
                          ['[ZR] Radar', TEXT_X, y_pos + TEXT_Y_OFFSET, 0, base_color, shadow_color, true]
                        ])
  end

  def draw_repel_shortcut(refresh = false)
    # Color base del texto mostrado
    base_color = Color.new(250, 250, 250)
    # Color de sombra del texto mostrado
    shadow_color = Color.new(75, 75, 75)

    # Get or calculate position for this shortcut
    if !refresh || @repel_y_pos.nil?
      # Store the position for this shortcut if it's the first time drawing
      @repel_y_pos = get_next_shortcut_y_position if @repel_y_pos.nil?
      
      @sprites[:repelTop] = Sprite.new(@viewport2)
      @sprites[:repelTop].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgTop")
      @sprites[:repelTop].y = @repel_y_pos
      @sprites[:repelTop].x = SHORTCUT_X

      @sprites[:repelMid] = Sprite.new(@viewport2)
      @sprites[:repelMid].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgMid")
      @sprites[:repelMid].y = @repel_y_pos + BG_TOP_HEIGHT
      @sprites[:repelMid].x = SHORTCUT_X
      @sprites[:repelMid].zoom_y = BG_MID_HEIGHT

      @sprites[:repelBtm] = Sprite.new(@viewport2)
      @sprites[:repelBtm].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgBtm")
      @sprites[:repelBtm].y = @repel_y_pos + BG_TOP_HEIGHT + @sprites[:repelMid].zoom_y
      @sprites[:repelBtm].x = SHORTCUT_X
    else
      @sprites[:repel_txt]&.dispose
      @sprites[:repel]&.dispose
    end 

    # Gráfico del repelente según el estado
    bitmap = $PokemonGlobal.infRepel ? pbBitmap('Graphics/Items/INFREPEL') : pbBitmap('Graphics/Items/INFREPELOFF')

    @sprites[:repel_txt] = TextSprite.new(@viewport2)
    @sprites[:repel] = Sprite.new(@viewport2)
    @sprites[:repel].bitmap = bitmap
    @sprites[:repel].x = ICON_X
    @sprites[:repel].y = @repel_y_pos + ICON_Y_OFFSET
    # Escribimos el texto del repelente
    @sprites[:repel_txt].draw([
                          ['[R] Repelente', TEXT_X, @repel_y_pos + TEXT_Y_OFFSET, 0, base_color, shadow_color, true]
                        ])
  end

  def draw_helpful_text
    # Color base del texto mostrado
    base_color = Color.new(250, 250, 250)
    # Color de sombra del texto mostrado
    shadow_color = Color.new(75, 75, 75)

    extra = 0
    extra2 = 0
    if defined?(ChallengeModes) && ChallengeModes.on?(:MODOVIDAS) && $PokemonGlobal.challenge_lives && $PokemonGlobal.challenge_lives >= 0
      extra = 25
      extra2 = 15
    end

    y_pos = Graphics.height - 75 - extra
    
    @sprites[:infoTop] = Sprite.new(@viewport2)
    @sprites[:infoTop].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgTop")
    @sprites[:infoTop].y = y_pos
    @sprites[:infoTop].x = SHORTCUT_X
    @sprites[:infoTop].zoom_x = 1.3
    
    @sprites[:infoMid] = Sprite.new(@viewport2)
    @sprites[:infoMid].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgMid")
    @sprites[:infoMid].y = y_pos + BG_TOP_HEIGHT
    @sprites[:infoMid].x = SHORTCUT_X
    @sprites[:infoMid].zoom_y = BG_MID_HEIGHT + extra
    @sprites[:infoMid].zoom_x = 1.3
    
    @sprites[:infoBtm] = Sprite.new(@viewport2)
    @sprites[:infoBtm].bitmap = pbBitmap("Graphics/Pictures/DP Pause Menu/bgBtm")
    @sprites[:infoBtm].y = y_pos + BG_TOP_HEIGHT + @sprites[:infoMid].zoom_y
    @sprites[:infoBtm].x = SHORTCUT_X
    @sprites[:infoBtm].zoom_x = 1.3

    @sprites[:helpful_text_txt] = TextSprite.new(@viewport2)
    @sprites[:helpful_text_txt].draw([
        [_INTL('Nivel máx. actual: {1}', LevelCapsEX.level_cap), 24, Graphics.height - 45 - extra2, 0, base_color, shadow_color, true]
    ])

    if defined?(ChallengeModes) && ChallengeModes.on?(:MODOVIDAS) && $PokemonGlobal.challenge_lives && $PokemonGlobal.challenge_lives >= 0
        @sprites[:helpful_text_txt].draw([
            [_INTL('Vidas: {1}', $PokemonGlobal.challenge_lives), 24, Graphics.height - 15 - extra2, 0, base_color, shadow_color, true]
        ])
    end

  end

  def draw_sun_moon_icon
    bitmap_path = PBDayNight.isNight? ? File.join(ICONS_PATH, "moon.png") : File.join(ICONS_PATH, "sun.png")
    # Color base del texto mostrado
    base_color = Color.new(250, 250, 250)
    # Color de sombra del texto mostrado
    shadow_color = Color.new(75, 75, 75)
    # Get dynamic position for this right-side icon
    y_pos = get_next_right_icon_y_position
    @sprites[:sunTop] = Sprite.new(@viewport2)
    @sprites[:sunTop].bitmap = pbBitmap(File.join(ICONS_PATH, "bgTop_short"))
    @sprites[:sunTop].y = y_pos
    @sprites[:sunTop].x = RIGHT_ICON_START_X
    
    @sprites[:sunMid] = Sprite.new(@viewport2)
    @sprites[:sunMid].bitmap = pbBitmap(File.join(ICONS_PATH, "bgMid_short"))
    @sprites[:sunMid].y = y_pos + BG_TOP_HEIGHT
    @sprites[:sunMid].x = RIGHT_ICON_START_X
    @sprites[:sunMid].zoom_y = RIGHT_ICON_SHORT_HEIGHT
    
    @sprites[:sunBtm] = Sprite.new(@viewport2)
    @sprites[:sunBtm].bitmap = pbBitmap(File.join(ICONS_PATH, "bgBtm_short"))
    @sprites[:sunBtm].y = y_pos + BG_TOP_HEIGHT + @sprites[:sunMid].zoom_y
    @sprites[:sunBtm].x = RIGHT_ICON_START_X

    bitmap = pbBitmap(bitmap_path)
    @sprites[:sun] = Sprite.new(@viewport2)
    @sprites[:sun].bitmap = bitmap
    @sprites[:sun].x = RIGHT_ICON_START_X + 13
    @sprites[:sun].y = y_pos + 9
  end

  def draw_captured_icon
    return if !ChallengeModes.on?(:ONE_CAPTURE)
    map_id = $game_map.map_id
    return if !$PokemonGlobal&.challenge_encs&.[](map_id)
    y_pos = get_next_right_icon_y_position
    @sprites[:capturedTop] = Sprite.new(@viewport2)
    @sprites[:capturedTop].bitmap = pbBitmap(File.join(ICONS_PATH, "bgTop_short"))
    @sprites[:capturedTop].y = y_pos
    @sprites[:capturedTop].x = RIGHT_ICON_START_X
    
    @sprites[:capturedMid] = Sprite.new(@viewport2)
    @sprites[:capturedMid].bitmap = pbBitmap(File.join(ICONS_PATH, "bgMid_short"))
    @sprites[:capturedMid].y = y_pos + BG_TOP_HEIGHT
    @sprites[:capturedMid].x = RIGHT_ICON_START_X
    @sprites[:capturedMid].zoom_y = RIGHT_ICON_SHORT_HEIGHT
    
    @sprites[:capturedBtm] = Sprite.new(@viewport2)
    @sprites[:capturedBtm].bitmap = pbBitmap(File.join(ICONS_PATH, "bgBtm_short"))
    @sprites[:capturedBtm].y = y_pos + BG_TOP_HEIGHT + @sprites[:capturedMid].zoom_y
    @sprites[:capturedBtm].x = RIGHT_ICON_START_X
    
    bitmap = pbBitmap(File.join(ICONS_PATH, "icon_own"))
    @sprites[:captured] = Sprite.new(@viewport2)
    @sprites[:captured].bitmap = bitmap
    @sprites[:captured].x = RIGHT_ICON_START_X + 16
    @sprites[:captured].y = y_pos + 12
  end
end