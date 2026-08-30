#===============================================================================
# [MUI] Enhanced Pokemon UI compatibility for [SV] Summary Screen - FIXED
#===============================================================================
if PluginManager.installed?("[MUI] Enhanced Pokemon UI")
  class PokemonSummary_Scene
    #-----------------------------------------------------------------------------
    # Aliased to add shiny leaf display.
    #-----------------------------------------------------------------------------
    alias enhanced_drawPage drawPage
    def drawPage(page)
      enhanced_drawPage(page)
      return if !Settings::SUMMARY_SHINY_LEAF
      overlay = @sprites["overlay"].bitmap
      coords = [195, 244]
      pbDisplayShinyLeaf(@pokemon, overlay, coords[0], coords[1])
    end

    #-----------------------------------------------------------------------------
    # Aliased to add happiness meter display.
    #-----------------------------------------------------------------------------
    alias enhanced_drawPageOne drawPageOne
    def drawPageOne
      enhanced_drawPageOne
      return if !Settings::SUMMARY_HAPPINESS_METER
      overlay = @sprites["overlay"].bitmap
      coords = [230, 352]
      # FIX: Verificar cuántos argumentos acepta la función pbDisplayHappiness
      begin
        # Intentar con 4 argumentos primero (overlay, x, y como argumentos separados)
        pbDisplayHappiness(@pokemon, overlay, coords[0], coords[1])
      rescue ArgumentError => e
        begin
          # Si falla, intentar con 3 argumentos (coords como array)
          pbDisplayHappiness(@pokemon, overlay, coords)
        rescue ArgumentError => e2
          begin
            # Si falla, intentar solo con 2 argumentos
            pbDisplayHappiness(@pokemon, overlay)
          rescue ArgumentError => e3
            # Si ninguno funciona, mostrar el error pero continuar
            puts "Warning: pbDisplayHappiness compatibility issue: #{e3.message}"
          end
        end
      end
      base   = Color.new(246, 198, 6)
      shadow = Color.new(74, 97, 103)
      textpos = [ [_INTL("{1}/{2}", @pokemon.happiness.to_s, Settings::MAX_HAPPINESS), 340, coords[1] + 2, :left, base, shadow] ]
      pbDrawTextPositions(overlay, textpos)
    end

    #-----------------------------------------------------------------------------
    # Aliased to add Legacy data display.
    #-----------------------------------------------------------------------------
    alias enhanced_pbStartScene pbStartScene
    def pbStartScene(*args)
      if defined?(Settings::SUMMARY_LEGACY_DATA) && Settings::SUMMARY_LEGACY_DATA
        UIHandlers.edit_hash(:summary, :page_info, "options", 
          [:item, :nickname, :pokedex, _INTL("Ver Historial"), :mark]
        )
        UIHandlers.edit_hash(:summary, :page_memo, "options", 
          [:item, :nickname, :pokedex, _INTL("Ver Historial"), :mark]
        )
      end

      @statToggle = false
      enhanced_pbStartScene(*args)
      @sprites["legacy_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSystemFont(@sprites["legacy_overlay"].bitmap)
      @sprites["legacyicon"] = PokemonIconSprite.new(@pokemon, @viewport)
      @sprites["legacyicon"].setOffset(PictureOrigin::CENTER)
      @sprites["legacyicon"].visible = false
    end

    # CORRECCIÓN: Solo un método pbPageCustomOption
    def pbPageCustomOption(cmd)
      if cmd == _INTL("Ver Historial")
        pbLegacyMenu
        return true
      end
      return false
    end
    
    #-----------------------------------------------------------------------------
    # Legacy data menu.
    #-----------------------------------------------------------------------------
    TOTAL_LEGACY_PAGES = 3
    
    def pbLegacyMenu    
      base2   = Color.new(246, 198, 6)
      shadow2 = Color.new(74, 97, 103)
      base = Color.new(248, 248, 248)
      shadow = Color.new(74, 112, 175)
      path = defined?(Settings::POKEMON_UI_GRAPHICS_PATH) ? Settings::POKEMON_UI_GRAPHICS_PATH : "Graphics/UI/Summary/"
      legacy_overlay = @sprites["legacy_overlay"].bitmap
      legacy_overlay.clear
      ypos = 62
      index = 0
      @sprites["legacyicon"].x = 64
      @sprites["legacyicon"].y = ypos + 64
      @sprites["legacyicon"].pokemon = @pokemon
      @sprites["legacyicon"].visible = true
      
      # Verificar si el pokemon tiene legacy_data
      data = @pokemon.respond_to?(:legacy_data) ? @pokemon.legacy_data : {}
      # Proporcionar valores por defecto si no existe legacy_data
      data = {
        party_time: 0,
        item_count: 0,
        move_count: 0,
        egg_count: 0,
        trade_count: 0,
        defeated_count: 0,
        fainted_count: 0,
        supereff_count: 0,
        critical_count: 0,
        retreat_count: 0,
        trainer_count: 0,
        leader_count: 0,
        legend_count: 0,
        champion_count: 0,
        loss_count: 0
      }.merge(data)
      
      dorefresh = true
      loop do
        Graphics.update
        Input.update
        pbUpdate
        textpos = []
        imagepos = []
        if Input.trigger?(Input::BACK)
          break
        elsif Input.trigger?(Input::UP) && index > 0
          index -= 1
          pbPlayCursorSE
          dorefresh = true
        elsif Input.trigger?(Input::DOWN) && index < TOTAL_LEGACY_PAGES - 1
          index += 1
          pbPlayCursorSE
          dorefresh = true
        end
        if dorefresh
          case index
          when 0  # General
            name = _INTL("General")
            hour = data[:party_time].to_i / 60 / 60
            min  = data[:party_time].to_i / 60 % 60
            addltext = [
              [_INTL("Tiempo total en el equipo:"),    "#{hour} hrs #{min} min"],
              [_INTL("Objetos consumidos:"),           data[:item_count]],
              [_INTL("Movimientos aprendidos:"),       data[:move_count]],
              [_INTL("Huevos producidos:"),            data[:egg_count]],
              [_INTL("Número de intercambios:"),       data[:trade_count]]
            ]
          when 1  # Battle History
            name = _INTL("Historial Combate")
            addltext = [
              [_INTL("Oponentes derrotados:"),         data[:defeated_count]],
              [_INTL("Veces debilitado:"),             data[:fainted_count]],
              [_INTL("Golpes supereficaces dados:"),   data[:supereff_count]],
              [_INTL("Golpes críticos dados:"),        data[:critical_count]],
              [_INTL("Total de retiradas:"),           data[:retreat_count]]
            ]
          when 2  # Team History
            name = _INTL("Historial de Equipo")
            addltext = [
              [_INTL("Victorias contra Entrenadores:"),     data[:trainer_count]],
              [_INTL("Victorias contra Líderes de Gimnasio:"), data[:leader_count]],
              [_INTL("Victorias contra legendarios salvajes:"), data[:legend_count]],
              [_INTL("Inducciones al Salón de la Fama:"),   data[:champion_count]],
              [_INTL("Total de empates o derrotas:"),       data[:loss_count]]
            ]
          end
          textpos.push([_INTL("HISTORIAL DE {1}", @pokemon.name.upcase), 295, ypos + 38, :center, base2, shadow2],
                      [name, Graphics.width / 2, ypos + 90, :center, base, shadow])
          addltext.each_with_index do |txt, i|
            textY = ypos + 134 + (i * 32)
            textpos.push([txt[0], 38, textY, :left, base, shadow])
            textpos.push([_INTL("{1}", txt[1]), Graphics.width - 38, textY, :right, base, shadow])
          end
          imagepos.push([path + "bg_legacy", 0, ypos])
          if index > 0
            imagepos.push([path + "arrows_legacy", 118, ypos + 84, 0, 0, 32, 32])
          end
          if index < TOTAL_LEGACY_PAGES - 1
            imagepos.push([path + "arrows_legacy", 362, ypos + 84, 32, 0, 32, 32])
          end
          legacy_overlay.clear
          pbDrawImagePositions(legacy_overlay, imagepos)
          pbDrawTextPositions(legacy_overlay, textpos)
          dorefresh = false
        end
      end
      legacy_overlay.clear
      @sprites["legacyicon"].visible = false
    end

    #-----------------------------------------------------------------------------
    # Aliased to add IV ratings.
    #-----------------------------------------------------------------------------
    alias enhanced_drawPageThree drawPageThree
    def drawPageThree
      if @statToggle
        @sprites["background"].setBitmap("Graphics/UI/Summary/bg_skills_eviv")
      else
        @sprites["background"].setBitmap("Graphics/UI/Summary/bg_skills")
      end
      (@statToggle) ? drawEnhancedStats : enhanced_drawPageThree
      return if !defined?(Settings::SUMMARY_IV_RATINGS) || !Settings::SUMMARY_IV_RATINGS
      overlay = @sprites["overlay"].bitmap
      pbDisplayIVRatingsSV(@pokemon, overlay, @statToggle)
    end

    def drawEnhancedStats
      overlay = @sprites["overlay"].bitmap
      base   = Color.new(246, 198, 6)
      shadow = Color.new(74, 97, 103)
      base2 = Color.new(248, 248, 248)
      shadow2 = Color.new(74, 112, 175)
      ev_total = 0
      iv_total = 0
      
      # HEXÁGONO: Mismo orden
      ivs = applyLowerBound([@pokemon.iv[:HP], @pokemon.iv[:SPECIAL_ATTACK], @pokemon.iv[:SPECIAL_DEFENSE], @pokemon.iv[:SPEED], @pokemon.iv[:DEFENSE], @pokemon.iv[:ATTACK]], 3)
      evs = applyLowerBound([@pokemon.ev[:HP], @pokemon.ev[:SPECIAL_ATTACK], @pokemon.ev[:SPECIAL_DEFENSE], @pokemon.ev[:SPEED], @pokemon.ev[:DEFENSE], @pokemon.ev[:ATTACK]], 25)

      @sprites["hexagon_stats"].bitmap.clear unless !@sprites["hexagon_stats"]
      @sprites["hexagon_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(72, 204, 240, 191), 31, ivs, 12, true, false)
      @sprites["hexagon_base_stats"].bitmap.clear unless !@sprites["hexagon_base_stats"]
      @sprites["hexagon_base_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(210, 255, 168, 191), 252, evs, 12, true, false)
      
      textpos = []
      textpos.push([_INTL("EV/IV"), 468, 44, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)])
      
      GameData::Stat.each_main do |s|
        # COORDENADAS: Intercambiar posiciones
        case s.id
        when :HP then xpos, ypos, align = 364, 44, :center
        when :ATTACK then xpos, ypos, align = 310, 102, :right      # CAMBIÓ: era 416, :left
        when :DEFENSE then xpos, ypos, align = 310, 162, :right     # CAMBIÓ: era 416, :left
        when :SPECIAL_ATTACK then xpos, ypos, align = 416, 102, :left    # CAMBIÓ: era 310, :right
        when :SPECIAL_DEFENSE then xpos, ypos, align = 416, 162, :left   # CAMBIÓ: era 310, :right
        when :SPEED then xpos, ypos, align = 364, 220, :center
        end
        name = (s.id == :SPECIAL_ATTACK) ? "At. Esp." : (s.id == :SPECIAL_DEFENSE) ? "Def. Esp." : s.name
        statbase = base
        statshadow = shadow
        if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
          @pokemon.nature_for_stats.stat_changes.each do |change|
            next if s.id != change[0]
            if change[1] > 0
              statbase = Color.new(228, 66, 66)
              statshadow = Color.new(68, 57, 121)
            elsif change[1] < 0
              statbase = Color.new(60, 120, 252) 
              statshadow = Color.new(18, 73, 176)
            end
          end
        end 
        textpos.push([_INTL("{1}", name), xpos, ypos, align, statbase, statshadow])
        
        # POSICIONES EV/IV: Ajustar para nuevas coordenadas
        if (align == :center)
          textpos.push(
            [@pokemon.ev[s.id].to_s, xpos - 8, (ypos + 26), :right, base2, shadow2],
            [@pokemon.iv[s.id].to_s, xpos + 6, ypos + 26, :left, base2, shadow2]
          )
        elsif (align == :left)  # Ahora SPATK y SPDEF (derecha)
          textpos.push(
            [@pokemon.ev[s.id].to_s, xpos, (ypos + 26), align, base2, shadow2],
            [@pokemon.iv[s.id].to_s, xpos + 50, ypos + 26, align, base2, shadow2]
          )
        elsif (align == :right)  # Ahora ATK y DEF (izquierda)
          textpos.push(
            [@pokemon.ev[s.id].to_s, xpos - 36, (ypos + 26), align, base2, shadow2],
            [@pokemon.iv[s.id].to_s, xpos, ypos + 26, align, base2, shadow2]
          )
        end
        ev_total += @pokemon.ev[s.id]
        iv_total += @pokemon.iv[s.id]
      end
      textpos.push(
        [_INTL("EV/IV Total"), 222, 280, :left, base, shadow],
        [sprintf("%d | %d", ev_total, iv_total), 504, 280, :right, base2, shadow2],
        [_INTL("EVs restantes:"), 222, 312, :left, base2, shadow2],
        [sprintf("%d/%d", Pokemon::EV_LIMIT - ev_total, Pokemon::EV_LIMIT), 504, 312, :right, base2, shadow2],
        [_INTL("Poder Oculto:"), 222, 346, :left, base2, shadow2]
      )
      pbDrawTextPositions(overlay, textpos)
      
      # Verificar si pbHiddenPower existe
      if defined?(pbHiddenPower)
        hiddenpower = pbHiddenPower(@pokemon)
        type_number = GameData::Type.get(hiddenpower[0]).icon_position
        type_rect = Rect.new(0, type_number * 28, 64, 28)
        overlay.blt(428, 343, @typebitmap.bitmap, type_rect)
      end
    end

    def pbDisplayIVRatingsSV(pokemon, overlay, evivpage)
      return if !pokemon
      imagepos = []
      path  = defined?(Settings::POKEMON_UI_GRAPHICS_PATH) ? Settings::POKEMON_UI_GRAPHICS_PATH : "Graphics/UI/Summary/"
      style = (defined?(Settings::IV_DISPLAY_STYLE) && Settings::IV_DISPLAY_STYLE == 0) ? 0 : 16
      maxIV = Pokemon::IV_STAT_LIMIT
      xpos = evivpage ? { :HP => 400, :SPECIAL_ATTACK => 496, :SPECIAL_DEFENSE => 496, :ATTACK => 216, :SPATK => 216, :SPE => 400 } : { :HP => 412, :SPECIAL_ATTACK => 458, :SPECIAL_DEFENSE => 458, :ATTACK => 252, :DEFENSE => 252, :SPEED => 388 }
      ypos = { :HP => 72, :SPECIAL_ATTACK => 130, :SPECIAL_DEFENSE => 190, :ATTACK => 130, :DEFENSE => 190, :SPEED => 248 }
      GameData::Stat.each_main do |s|
        stat = pokemon.iv[s.id]
        x_pos = xpos[s.id]
        y_pos = ypos[s.id]
        case stat
        when maxIV     then icon = 5  # 31 IV
        when maxIV - 1 then icon = 4  # 30 IV
        when 0         then icon = 0  #  0 IV
        else
          if stat > (maxIV - (maxIV / 4).floor)
            icon = 3 # 25-29 IV
          elsif stat > (maxIV - (maxIV / 2).floor)
            icon = 2 # 16-24 IV
          else
            icon = 1 #  1-15 IV
          end
        end
        imagepos.push([
          path + "iv_ratings", x_pos, y_pos, icon * 16, style, 16, 16
        ])
      end
      pbDrawImagePositions(overlay, imagepos)
    end
  end
end