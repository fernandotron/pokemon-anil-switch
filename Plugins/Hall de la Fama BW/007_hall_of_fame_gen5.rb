#===============================================================================
#
#-------------------------------------------------------------------------------
#                   Generación 5 del Salón de la Fama
#                             por JessWishes
#                      Porteado a v21 por Skyflyer
#               Versión Corregida - COLOREADO ARREGLADO
#-------------------------------------------------------------------------------
#
# Este archivo contiene la implementación de la animación
# de la Generación 5 del Salón de la Fama (Black/White)
#
#===============================================================================

class HallDeLaFama
  
  #=============================================================================
  # Generación 5 - Estilo Black/White
  #=============================================================================
  def jsGen5
    # FADE INICIAL A NEGRO
    initial_fade_in
    
    setup_gen5_background
    setup_gen5_ui_elements
    
    pbWait(0.5)  # Era 20 frames = ~0.5 segundos
    
    # Animación principal de Pokémon
    animate_gen5_pokemon_sequence
    
    # Secuencia final del entrenador
    show_gen5_trainer_sequence
    
    fade(true)
    dispose
  end
  
  private
  
  #=============================================================================
  # Fade inicial para empezar suavemente
  #=============================================================================
  def initial_fade_in
    # Crear overlay negro
    @s["fade_overlay"] = Sprite.new(@vista)
    @s["fade_overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["fade_overlay"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    @s["fade_overlay"].z = 99998  # Z alto pero no máximo
    @s["fade_overlay"].opacity = 255
    
    # Fade gradual de negro a transparente (más lento)
    60.times do |i|
      @s["fade_overlay"].opacity = 255 - (255 * i / 60)
      Graphics.update
      Input.update
    end
    
    # Eliminar overlay
    @s["fade_overlay"].dispose
    @s.delete("fade_overlay")
  end
  
  #=============================================================================
  # Configuración inicial Gen 5
  #=============================================================================
  def setup_gen5_background
    # Fondo negro inicial
    @s["bg"] = Sprite.new(@vista)
    @s["bg"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["bg"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(-255, -255, -255))
    
    pokes_info
    
    # Fondos de tipo dinámicos
    @s["fondo"] = Sprite.new(@vista)
    @s["fondo"].bitmap = Bitmap.new(1, 1)
    @s["fondo2"] = Sprite.new(@vista)
    @s["fondo2"].bitmap = Bitmap.new(1, 1)
  end
  
  def setup_gen5_ui_elements
    # Barras superiores
    create_gen5_bars("b1", "b1_2", true)
    
    # Título principal
    @s["t1"] = create_text_window(
      "<ac>¡Salón de la Fama!</ac>",
      @s["b1"].x - 120, 6, Graphics.width, 64
    )
    
    # Barras inferiores
    create_gen5_bars("b2", "b2_2", false)
  end
  
  def create_gen5_bars(bar1_name, bar2_name, is_top)
    # Barra principal
    @s[bar1_name] = Sprite.new(@vista)
    begin
      @s[bar1_name].bitmap = HallOfFameResources.get_bitmap("hallfameBWbars")
      src_y = is_top ? 0 : @s[bar1_name].bitmap.height / 2
      @s[bar1_name].src_rect.set(0, src_y, @s[bar1_name].bitmap.width, @s[bar1_name].bitmap.height / 2)
    rescue
      @s[bar1_name].bitmap = Bitmap.new(Graphics.width, 100)
      @s[bar1_name].bitmap.fill_rect(0, 0, Graphics.width, 100, Color.new(100, 100, 150))
    end
    
    # Barra secundaria
    @s[bar2_name] = Sprite.new(@vista)
    begin
      @s[bar2_name].bitmap = HallOfFameResources.get_bitmap("hallfameBWbars2")
      src_y = is_top ? 0 : @s[bar2_name].bitmap.height / 2
      @s[bar2_name].src_rect.set(0, src_y, @s[bar2_name].bitmap.width, @s[bar2_name].bitmap.height / 2)
    rescue
      @s[bar2_name].bitmap = Bitmap.new(Graphics.width, 100)
      @s[bar2_name].bitmap.fill_rect(0, 0, Graphics.width, 100, Color.new(150, 150, 200))
    end
    
    # Posiciones
    if is_top
      @s[bar1_name].x = -(@s[bar1_name].bitmap.width + 17)
      @s[bar1_name].y = 20
    else
      @s[bar1_name].x = Graphics.width + 17
      @s[bar1_name].y = (Graphics.height - (@s[bar1_name].bitmap.height / 2)) - 20
    end
    
    @s[bar2_name].x = @s[bar1_name].x
    @s[bar2_name].y = @s[bar1_name].y
  end
  
  #=============================================================================
  # Crear sprites de Pokémon con animación - POSICIONES CORREGIDAS
  #=============================================================================
  
  def pokes_info
    party_index = 0
    
    $player.party.each_with_index do |pokemon, i|
      next if pokemon.egg?
      
      # Sprite frontal ANIMADO - usando PokemonSprite estándar
      @s["poke#{party_index}"] = PokemonSprite.new(@vista)
      @s["poke#{party_index}"].setPokemonBitmap(pokemon)
      
      # POSICIÓN INICIAL: Empezará completamente fuera de pantalla por la izquierda
      sprite_width = @s["poke#{party_index}"].bitmap.width
      sprite_height = @s["poke#{party_index}"].bitmap.height
      
      # Configurar ox/oy para centrado correcto
      @s["poke#{party_index}"].ox = sprite_width / 2
      @s["poke#{party_index}"].oy = sprite_height / 2
      
      # Posición inicial: completamente fuera de pantalla por la izquierda
      @s["poke#{party_index}"].x = -sprite_width
      @s["poke#{party_index}"].y = Graphics.height / 2  # Ya centrado verticalmente
      
      # Sprite trasero ANIMADO - usando PokemonSprite estándar
      @s["poke#{party_index}_2"] = PokemonSprite.new(@vista)
      @s["poke#{party_index}_2"].setPokemonBitmap(pokemon, true)
      
      # CORREGIDO: Posición inicial completamente fuera de pantalla por la derecha
      back_sprite_width = @s["poke#{party_index}_2"].bitmap.width
      back_sprite_height = @s["poke#{party_index}_2"].bitmap.height
      
      # Configurar ox/oy del sprite trasero
      @s["poke#{party_index}_2"].ox = back_sprite_width / 2
      @s["poke#{party_index}_2"].oy = back_sprite_height / 2
      
      # Posición inicial: completamente fuera de pantalla por la derecha
      @s["poke#{party_index}_2"].x = Graphics.width + back_sprite_width
      @s["poke#{party_index}_2"].y = (Graphics.height - back_sprite_height) + 79
      
      party_index += 1
    end
  end
  
  #=============================================================================
  # Animación principal de Pokémon Gen 5 - CENTRADO CORREGIDO
  #=============================================================================
  def animate_gen5_pokemon_sequence
    party_index = 0
    party_pokemon = get_non_egg_pokemon
    
    party_pokemon.each_with_index do |pokemon, index|
      # CORREGIDO: Resetear posiciones de barras para cada Pokémon
      reset_bars_positions
      
      # NO TOCAR LA POSICIÓN AQUÍ - ya está configurada correctamente en pokes_info
      # Solo ajustar el Z
      @s["poke#{party_index}"].z += 5
      
      # APLICAR COLORES CORREGIDOS - PUNTO CLAVE
      gen5_apply_type_colors_corrected(pokemon)
      
      # Crear ventana de información
      gen5_pokemon_info(pokemon, party_index)
      
      # Animación de entrada del sprite trasero - CORREGIDA para que salga completamente
      # Calcular cuánto necesita moverse para salir completamente de pantalla por la izquierda
      back_sprite_width = @s["poke#{party_index}_2"].bitmap.width
      current_back_x = @s["poke#{party_index}_2"].x
      target_back_x = -back_sprite_width  # Completamente fuera por la izquierda
      
      # Calcular la distancia total y frames necesarios
      total_back_distance = current_back_x - target_back_x
      frames_needed_back = [total_back_distance / 35, 25].max  # Mínimo 25 frames, velocidad de 35 pixels/frame
      
      frames_needed_back.to_i.times do |frame|
        # Mover sprite trasero hacia la izquierda hasta que salga completamente
        if @s["poke#{party_index}_2"].x > target_back_x
          @s["poke#{party_index}_2"].x -= 35
        end
        
        # ACTUALIZAR ANIMACIÓN DEL SPRITE TRASERO
        if @s["poke#{party_index}_2"] && @s["poke#{party_index}_2"].respond_to?(:update)
          @s["poke#{party_index}_2"].update
        end
        
        Graphics.update
        Input.update
      end
      
      # Asegurar que el sprite trasero esté completamente fuera de pantalla
      @s["poke#{party_index}_2"].x = target_back_x
      
      pbWait(0.25)
      
      # Configurar fondos de tipo
      gen5_setup_type_backgrounds(pokemon)
      
      # Animación principal de barras y sprites - CENTRADO CORREGIDO
      animate_gen5_main_sequence_fixed(party_index)
      
      gen5_sparkle_effect_fixed(party_index)
      
      wait_frames = (1 * Graphics.frame_rate).to_i
      wait_frames.times do
        if @s["poke#{party_index}"] && @s["poke#{party_index}"].respond_to?(:update)
          @s["poke#{party_index}"].update
        end
        if @s["poke#{party_index}_2"] && @s["poke#{party_index}_2"].respond_to?(:update)
          @s["poke#{party_index}_2"].update
        end
        Graphics.update
        Input.update
      end
      
      # Animación de salida
      animate_gen5_exit_sequence(party_index)
      
      # Limpiar sprites de este Pokémon para el siguiente
      cleanup_pokemon_sprites(party_index)
      
      party_index += 1
    end
  end
  
  def animate_gen5_main_sequence_fixed(party_index)
    # CORREGIDO: Calcular exactamente el centro de la pantalla para el Pokémon
    sprite_width = @s["poke#{party_index}"].bitmap.width
    sprite_height = @s["poke#{party_index}"].bitmap.height
    
    # Centro exacto de la pantalla (el sprite ya tiene ox configurado correctamente)
    target_center_x = Graphics.width / 2
    target_center_y = Graphics.height / 2
    
    25.times do |k|
      # Mover barras Y TEXTOS (SIN CAMBIOS - ya funcionan correctamente)
      if k < 20
        @s["b1"].x += 18
        @s["b2"].x -= 18
        # CORREGIDO: También mover las barras secundarias
        @s["b1_2"].x += 18
        @s["b2_2"].x -= 18
        @s["t1"].x += 18
        # MOVER TEXTOS DE POKÉMON - AJUSTES DE POSICIÓN (SIN CAMBIOS)
        if @s["t1_pokemon"]
          @s["t1_pokemon"].x += 28
        end
        if @s["t2"]
          @s["t2"].x -= 23
        end
      end
      
      # CORREGIDO: Mover Pokémon hacia el centro exacto de la pantalla
      current_x = @s["poke#{party_index}"].x
      current_y = @s["poke#{party_index}"].y
      
      # Movimiento horizontal hacia el centro (más agresivo para asegurar llegada)
      if current_x < target_center_x - 10  # Margen más amplio para movimiento continuo
        @s["poke#{party_index}"].x += 20  # Movimiento más rápido
      elsif current_x > target_center_x + 10
        @s["poke#{party_index}"].x -= 20
      end
      
      # Movimiento vertical hacia el centro
      if current_y < target_center_y - 10
        @s["poke#{party_index}"].y += 15
      elsif current_y > target_center_y + 10
        @s["poke#{party_index}"].y -= 15
      end
      
      # ACTUALIZAR ANIMACIÓN DEL POKÉMON ACTUAL
      if @s["poke#{party_index}"] && @s["poke#{party_index}"].respond_to?(:update)
        @s["poke#{party_index}"].update
      end
      if @s["poke#{party_index}_2"] && @s["poke#{party_index}_2"].respond_to?(:update)
        @s["poke#{party_index}_2"].update
      end
      
      # Efectos de fondo
      @s["fondo"].opacity += 10 if @s["fondo"].opacity < 90
      @s["fondo2"].opacity += 10 if @s["fondo2"].opacity < 160
      @s["fondo"].x -= 10 if @s["fondo"].x > -80
      @s["fondo2"].x -= 10 if @s["fondo2"].x > -1
      
      Graphics.update
      Input.update
    end
    
    # ASEGURAR POSICIÓN FINAL EXACTA
    @s["poke#{party_index}"].x = target_center_x
    @s["poke#{party_index}"].y = target_center_y
  end
  
  def animate_gen5_exit_sequence(party_index)
    # CORREGIDO: Calcular cuánto necesita moverse para salir completamente de pantalla
    sprite_width = @s["poke#{party_index}"].bitmap.width
    current_x = @s["poke#{party_index}"].x
    
    # Calcular la distancia total que necesita recorrer para salir completamente
    # Desde su posición actual hasta completamente fuera por la izquierda
    target_x = -sprite_width
    total_distance = current_x - target_x
    
    # Calcular cuántos frames necesitamos (mantener velocidad similar a antes)
    frames_needed = [total_distance / 10, 20].max  # Mínimo 20 frames, velocidad de 10 pixels/frame
    
    frames_needed.to_i.times do |frame|
      # Mover Pokémon hacia la izquierda hasta que salga completamente
      if @s["poke#{party_index}"].x > target_x
        @s["poke#{party_index}"].x -= 10
      end
      
      # Mover barras y textos (SIN CAMBIOS - mantener sincronización)
      @s["b1"].x -= 18
      # CORREGIDO: También mover las barras secundarias en la salida
      @s["b1_2"].x -= 18
      @s["t1"].x -= 18
      @s["b2"].x += 18
      @s["b2_2"].x += 18
      
      # MOVER TEXTOS DE POKÉMON EN LA SALIDA - AJUSTES DE POSICIÓN (SIN CAMBIOS)
      if @s["t1_pokemon"]
        @s["t1_pokemon"].x -= 28  # Texto superior se mueve más rápido
      end
      if @s["t2"]
        @s["t2"].x += 23  # Texto inferior se mueve más lento
      end
      
      # Efectos de fondo
      @s["fondo2"].opacity -= 15
      
      # ACTUALIZAR ANIMACIÓN DEL POKÉMON DURANTE LA SALIDA
      if @s["poke#{party_index}"] && @s["poke#{party_index}"].respond_to?(:update)
        @s["poke#{party_index}"].update
      end
      if @s["poke#{party_index}_2"] && @s["poke#{party_index}_2"].respond_to?(:update)
        @s["poke#{party_index}_2"].update
      end
      
      Graphics.update
      Input.update
    end
    
    # AHORA SÍ: Asegurar que el Pokémon esté completamente fuera de pantalla
    @s["poke#{party_index}"].x = target_x
  end
  
  def cleanup_pokemon_sprites(party_index)
    # CORREGIDO: Solo limpiar ventanas de texto y ocultar sprites DESPUÉS de que hayan salido
    ["t2", "t1_pokemon"].each do |sprite_name|
      if @s[sprite_name]
        @s[sprite_name].dispose
        @s.delete(sprite_name)
      end
    end
    
    # AHORA SÍ: Ocultar los Pokémon después de que hayan salido completamente de pantalla
    @s["poke#{party_index}"].visible = false
    @s["poke#{party_index}_2"].visible = false
    
    # Resetear fondos para el siguiente Pokémon
    @s["fondo"].opacity = 0
    @s["fondo2"].opacity = 0
    @s["fondo"].x = 100
    @s["fondo2"].x = 100
  end
  
  #=============================================================================
  # NUEVO: Método para resetear posiciones de barras
  #=============================================================================
  def reset_bars_positions
    # Resetear barras superiores a sus posiciones iniciales
    if @s["b1"] && @s["b1_2"]
      @s["b1"].x = -(@s["b1"].bitmap.width + 17)
      @s["b1"].y = 20
      @s["b1_2"].x = @s["b1"].x
      @s["b1_2"].y = @s["b1"].y
    end
    
    # Resetear barras inferiores a sus posiciones iniciales  
    if @s["b2"] && @s["b2_2"]
      @s["b2"].x = Graphics.width + 17
      @s["b2"].y = (Graphics.height - (@s["b2"].bitmap.height / 2)) - 20
      @s["b2_2"].x = @s["b2"].x
      @s["b2_2"].y = @s["b2"].y
    end
    
    # Resetear título principal
    if @s["t1"]
      @s["t1"].x = @s["b1"].x - 120
      @s["t1"].y = 6
    end
  end
  
  #=============================================================================
  # MÉTODO CORREGIDO: Aplicar colores por tipo en Gen 5
  #=============================================================================
  def gen5_apply_type_colors_corrected(pokemon)
    # PASO 1: Obtener el color correcto del tipo usando el módulo corregido
    type_color = HallOfFameTypes.get_type_color(pokemon)
    
    # PASO 2: APLICAR EL TONE A TODOS LOS SPRITES CORRECTOS
    sprites_to_color = ["b1", "b2", "b1_2", "b2_2"]
    
    sprites_to_color.each do |sprite_name|
      if @s[sprite_name] && !@s[sprite_name].disposed?
        @s[sprite_name].tone = type_color
      end
    end
    
    # PASO 3: También aplicar a los fondos si existen
    if @s["fondo"] && !@s["fondo"].disposed?
      @s["fondo"].tone = type_color
    end
    if @s["fondo2"] && !@s["fondo2"].disposed?
      @s["fondo2"].tone = type_color
    end
  end
  
  def gen5_sparkle_effect_fixed(party_index)
    begin
      sparkle_bitmap = HallOfFameResources.get_bitmap("hallfameBWstars")
    rescue
      # Fallback: crear estrella simple
      sparkle_bitmap = Bitmap.new(32, 32)
      sparkle_bitmap.fill_rect(0, 0, 32, 32, Color.new(255, 255, 100))
    end
    
    # Crear sprites de chispas
    create_gen5_sparkle_sprites(sparkle_bitmap)
    
    # Animar chispas - CORREGIDO: Mantener animación del Pokémon ESPECÍFICO
    animate_gen5_sparkles_fixed(sparkle_bitmap, party_index)
    
    # Limpiar sprites de chispas
    ["chispas", "chispas2", "chispas3"].each { |name| safe_dispose_sprite(name) }
  end
  
  def create_gen5_sparkle_sprites(sparkle_bitmap)
    # CORREGIDO: Obtener posición actual del Pokémon para centrar las chispas
    current_pokemon_x = Graphics.width / 2  # Centro exacto horizontal
    
    # Chispas principales - centradas sobre el Pokémon - MÁS ALTAS
    @s["chispas"] = Sprite.new(@vista)
    @s["chispas"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["chispas"].bitmap.blt(0, 0, sparkle_bitmap, Rect.new(0, 0, sparkle_bitmap.width, sparkle_bitmap.height))
    @s["chispas"].x = current_pokemon_x - 20  # Centrado sobre el Pokémon
    @s["chispas"].y = 0  # CAMBIADO: Era 20, ahora 0 (más arriba)
    
    @s["chispas2"] = Sprite.new(@vista)
    @s["chispas2"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["chispas2"].bitmap.blt(0, 0, sparkle_bitmap, Rect.new(0, 0, sparkle_bitmap.width, sparkle_bitmap.height))
    @s["chispas2"].x = current_pokemon_x + 20  # Centrado sobre el Pokémon  
    @s["chispas2"].y = Graphics.height - 80  # CAMBIADO: Era Graphics.height - 60, ahora -80 (más arriba)
    
    @s["chispas3"] = Sprite.new(@vista)
    @s["chispas3"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["chispas3"].y = 0  # CAMBIADO: Era 20, ahora 0 (más arriba)
    @s["chispas3"].z = @vista.z + 6
  end
  
  def animate_gen5_sparkles_fixed(sparkle_bitmap, party_index)
    alternate = true
    sparkle_counter = 0
    
    41.times do |i|
      # Reducir opacidad del fondo
      if sparkle_counter < 20
        @s["fondo"].x -= 5
        @s["fondo"].opacity -= 10
      end
      sparkle_counter += 1
      
      # Mover chispas principales
      if alternate
        @s["chispas"].x += 1
        @s["chispas2"].x -= 1
      end
      
      @s["chispas"].opacity -= 12
      @s["chispas2"].opacity -= 12
      
      # Crear nuevas chispas - MÁS ALTAS
      if alternate && i < 20
        # CAMBIADO: Positions Y más bajas para que las chispas aparezcan más arriba
        @s["chispas"].bitmap.blt(i * 10 + rand(10), rand(2) == 1 ? -10 : 2, 
                                sparkle_bitmap, Rect.new(0, 0, sparkle_bitmap.width, sparkle_bitmap.height), 200)
        @s["chispas2"].bitmap.blt(150 - (i * 10 + rand(10)), rand(2) == 1 ? -10 : 2, 
                                 sparkle_bitmap, Rect.new(0, 0, sparkle_bitmap.width, sparkle_bitmap.height), 200)
      end
      
      # CRÍTICO: MANTENER ANIMACIÓN DEL POKÉMON ACTUAL durante las chispas
      if @s["poke#{party_index}"] && @s["poke#{party_index}"].respond_to?(:update)
        @s["poke#{party_index}"].update
      end
      if @s["poke#{party_index}_2"] && @s["poke#{party_index}_2"].respond_to?(:update)
        @s["poke#{party_index}_2"].update
      end
      
      alternate = !alternate
      Graphics.update
      Input.update
    end
    
    # CRÍTICO: Chispas finales - MANTENER ANIMACIÓN sin interrupción - MÁS ALTAS
    current_pokemon_x = Graphics.width / 2  # Centro exacto
    positions = [
      [current_pokemon_x - 50, 180],  # CAMBIADO: Era 220, ahora 180 (40px más alto)
      [current_pokemon_x - 20, 230],  # CAMBIADO: Era 270, ahora 230 (40px más alto)  
      [current_pokemon_x + 20, 130],  # CAMBIADO: Era 170, ahora 130 (40px más alto)
      [current_pokemon_x + 50, 230]   # CAMBIADO: Era 270, ahora 230 (40px más alto)
    ]
    position_index = 0
    
    50.times do |j|
      position_index += 1 if [10, 20, 30].include?(j)
      
      if [0, 10, 20, 30].include?(j)
        pos = positions[[position_index, 3].min]  # Evitar índice fuera de rango
        @s["chispas3"].bitmap.blt(pos[0], pos[1], sparkle_bitmap, 
                                 Rect.new(0, 0, sparkle_bitmap.width, sparkle_bitmap.height), 255)
      end
      
      @s["chispas3"].opacity -= 4
      
      # CRÍTICO: MANTENER ANIMACIÓN DEL POKÉMON ACTUAL durante chispas finales
      if @s["poke#{party_index}"] && @s["poke#{party_index}"].respond_to?(:update)
        @s["poke#{party_index}"].update
      end
      if @s["poke#{party_index}_2"] && @s["poke#{party_index}_2"].respond_to?(:update)
        @s["poke#{party_index}_2"].update
      end
      
      Graphics.update
      Input.update
    end
  end
  
  #=============================================================================
  # Configuración de fondos por tipo
  #=============================================================================
  def gen5_setup_type_backgrounds(pokemon)
    # Configurar fondos basados en el tipo del Pokémon
    setup_gen5_type_background(@s["fondo"], pokemon)
    setup_gen5_type_background(@s["fondo2"], pokemon)
  end
  
  def setup_gen5_type_background(sprite, pokemon)
    sprite.bitmap.dispose if sprite.bitmap && !sprite.bitmap.disposed?
    
    begin
      sprite.bitmap = HallOfFameResources.get_bitmap("hallfameBWtype")
      
      # VOLVER AL MÉTODO ORIGINAL - NO usar el índice corregido aquí
      # Usar el método original que funcionaba antes
      type_index = get_type_index_for_color_array(pokemon.types[0])
      
      sprite.src_rect.set(type_index * 512, 0, Graphics.width, Graphics.height)
    rescue MKXPError
      fallback_when_error(sprite, pokemon)
    rescue
      fallback_when_error(sprite, pokemon)
    end
    
    sprite.opacity = 0
    sprite.x = 100
  end

  def fallback_when_error(sprite, pokemon)
    # Fallback: color sólido basado en tipo
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    
    # Usar el módulo corregido para obtener el color
    type_color_tone = HallOfFameTypes.get_type_color(pokemon)
    
    # Convertir Tone a Color para el fallback
    base_red = [0, [255, 128 + type_color_tone.red].min].max
    base_green = [0, [255, 128 + type_color_tone.green].min].max
    base_blue = [0, [255, 128 + type_color_tone.blue].min].max
    
    base_color = Color.new(base_red, base_green, base_blue)
    sprite.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, base_color)
  end

  def get_type_index_for_color_array(type_symbol)
      # Mapeo de tipos según el orden del código original y HallDeLaFama_BW_COLOR
      type_order = [
          :NORMAL,    # 0
          :FIGHTING,  # 1
          :FLYING,    # 2
          :POISON,    # 3
          :GROUND,    # 4
          :ROCK,      # 5
          :BUG,       # 6
          :GHOST,     # 7
          :STEEL,     # 8
          :QMARKS,    # 9 - Tipo ??? (ya no existe en v21)
          :FIRE,      # 10
          :WATER,     # 11
          :GRASS,     # 12
          :ELECTRIC,  # 13
          :PSYCHIC,   # 14
          :ICE,       # 15
          :DRAGON,    # 16
          :DARK,      # 17
          :FAIRY      # 18
      ]
      
      index = type_order.index(type_symbol)
      
      # Si no se encuentra, intentar con algunos alias comunes
      if index.nil?
          case type_symbol
          when :DARK
          index = 17
          when :FAIRY
          index = 18
          when :STEEL
          index = 8
          else
          index = 0  # Normal por defecto
          end
      end
      
      return index
  end
  
  #=============================================================================
  # Información de Pokémon Gen 5
  #=============================================================================
  def gen5_pokemon_info(pokemon, party_index)
    # Texto de abajo - SOLO nombre y nivel (SIN ID) - CON MOVIMIENTO
    @s["t2"] = Sprite.new(@vista)
    @s["t2"].bitmap = Bitmap.new(Graphics.width, 64)
    @s["t2"].bitmap.font.size = 24
    @s["t2"].bitmap.font.bold = true
    
    # Dibujar texto directamente sin fondo de ventana
    text = "#{pokemon.name}           Nv. #{pokemon.level}"
    @s["t2"].bitmap.draw_text(0, 0, Graphics.width, 64, text, 1)  # 1 = centrado
    
    # POSICIÓN INICIAL PARA MOVIMIENTO - MÁS A LA IZQUIERDA Y MÁS ABAJO
    @s["t2"].x = Graphics.width + 19 
    @s["t2"].y = Graphics.height - 53
    @s["t2"].z = @vista.z + 15
    @s["t2"].visible = true
    
    # Texto de arriba - SOLO especie y género
    @s["t1_pokemon"] = Sprite.new(@vista)
    @s["t1_pokemon"].bitmap = Bitmap.new(Graphics.width, 64)
    @s["t1_pokemon"].bitmap.font.size = 20
    @s["t1_pokemon"].bitmap.font.bold = true
    
    # Obtener información del Pokémon (SIN ID)
    species_data = GameData::Species.get(pokemon.species)
    gender_symbol = get_pokemon_gender_symbol(pokemon)
    
    # Solo especie y género
    top_text = "#{species_data.name} #{gender_symbol}"
    @s["t1_pokemon"].bitmap.draw_text(0, 0, Graphics.width, 64, top_text, 1)  # 1 = centrado
    
    # POSICIÓN INICIAL PARA MOVIMIENTO - MÁS A LA DERECHA
    @s["t1_pokemon"].x = -Graphics.width - 200
    @s["t1_pokemon"].y = 29
    @s["t1_pokemon"].z = @vista.z + 15
    @s["t1_pokemon"].visible = true
  end
  
  #=============================================================================
  # Secuencia final del entrenador
  #=============================================================================
  def show_gen5_trainer_sequence
    # Posicionar todos los Pokémon para la escena final
    setup_final_pokemon_positions
    
    create_gen5_trainer_elements
    create_gen5_final_windows
    
    # Animación de entrada del entrenador
    animate_gen5_trainer_entrance
    
    # Bucle principal con input del jugador
    trainer_shown = false
    
    loop do
      Graphics.update
      Input.update
      
      # Actualizar animaciones de Pokémon
      party_pokemon = get_non_egg_pokemon
      party_pokemon.each_with_index do |pokemon, index|
        break if index >= 6
        if @s["poke#{index}"] && @s["poke#{index}"].respond_to?(:update)
          @s["poke#{index}"].update
        end
      end
      
      @s["bll"].angle -= 0.5
      
      if !trainer_shown && @s["trainer"].y >= Graphics.height / 2 - 80  # Posición original restaurada
        show_gen5_final_elements
        trainer_shown = true
      end
      
      # Salir cuando el jugador presione la tecla C (USE)
      if Input.trigger?(Input::USE)
        break
      end
    end
  end
  
  def setup_final_pokemon_positions
    party_pokemon = get_non_egg_pokemon
    
    # FORMACIÓN ESCALONADA MEJORADA - Con métricas y alturas progresivas
    party_pokemon.each_with_index do |pokemon, index|
      break if index >= 6
      
      if @s["poke#{index}"]
        # Posiciones base relativas al entrenador (centro horizontal: Graphics.width/2)
        case index
        when 0  # Primer Pokémon - Izquierda del entrenador, un poco más alto
          base_x = Graphics.width/2 - 80
          base_y = 350
          z_layer = 7
        when 1  # Segundo Pokémon - Derecha del entrenador, un poco más alto  
          base_x = Graphics.width/2 + 80
          base_y = 350
          z_layer = 7
        when 2  # Tercer Pokémon - Más a la izquierda, más alto
          base_x = Graphics.width/2 - 140
          base_y = 330
          z_layer = 6
        when 3  # Cuarto Pokémon - Más a la derecha, más alto
          base_x = Graphics.width/2 + 140
          base_y = 330
          z_layer = 6
        when 4  # Quinto Pokémon - Extremo izquierdo, más alto
          base_x = Graphics.width/2 - 200
          base_y = 310
          z_layer = 5
        when 5  # Sexto Pokémon - Extremo derecho, más alto
          base_x = Graphics.width/2 + 200
          base_y = 310
          z_layer = 5
        end
        base_y -= 152
        
        # APLICAR MÉTRICAS DEL POKÉMON
        species_data = GameData::Species.get(pokemon.species)
        form = pokemon.form || 0
        metrics = GameData::SpeciesMetrics.get_species_form(species_data.species, form)
        
        # Ajustar posición con métricas (índice 0 = sprite frontal del jugador, 1 = sprite frontal del oponente)
        # Para la escena final, usamos índice 1 (frontal del oponente)
        final_x = base_x
        final_y = base_y
        
        if metrics
          # Aplicar ajustes de métricas para sprite frontal (índice 1)
          final_x += metrics.front_sprite[0] * 2
          final_y += metrics.front_sprite[1] * 2
          final_y -= metrics.front_sprite_altitude * 2  # Pokémon voladores se elevan
        end
        
        # Configurar sprite
        @s["poke#{index}"].x = final_x
        @s["poke#{index}"].y = final_y
        @s["poke#{index}"].z = @vista.z + z_layer
        @s["poke#{index}"].visible = true
        @s["poke#{index}"].opacity = 0  # Empezar invisible para la animación
        
        # Centrar el sprite
        @s["poke#{index}"].ox = @s["poke#{index}"].bitmap.width / 2
        @s["poke#{index}"].oy = @s["poke#{index}"].bitmap.height / 2
        
        # ESCALA NORMAL - sin reducir
        @s["poke#{index}"].zoom_x = 1.0
        @s["poke#{index}"].zoom_y = 1.0
        
        # NUEVO: VOLTEAR HORIZONTALMENTE LOS POKÉMON DE LA DERECHA (índices 1, 3, 5)
        if [1, 3, 5].include?(index)
          @s["poke#{index}"].mirror = true  # Voltear horizontalmente
        end
      end
    end
  end
  
  def create_gen5_trainer_elements
    # Pokéball giratoria - POSICIÓN CORREGIDA
    @s["bll"] = Sprite.new(@vista)
    begin
      @s["bll"].bitmap = HallOfFameResources.get_bitmap("hallfameBWball")
    rescue
      @s["bll"].bitmap = Bitmap.new(64, 64)
      @s["bll"].bitmap.fill_rect(0, 0, 64, 64, Color.new(200, 50, 50))
    end
    @s["bll"].ox = @s["bll"].bitmap.width / 2
    @s["bll"].oy = @s["bll"].bitmap.height / 2
    # CORREGIDO: Posición fija de la Pokéball, no debe moverse
    @s["bll"].x = Graphics.width / 2
    @s["bll"].y = Graphics.height / 2 - 50
    @s["bll"].z = @vista.z + 2  # Z menor que el entrenador
    
    # Entrenador - POSICIÓN CORREGIDA PARA QUE NO SE MUEVA
    @s["trainer"] = create_trainer_sprite(false)
    @s["trainer"].x = Graphics.width / 2 - @s["trainer"].bitmap.width / 2
    @s["trainer"].y = -@s["trainer"].bitmap.height  # Empezar arriba para la animación
    @s["trainer"].z = @vista.z + 15  # Z más alto que todos los Pokémon
    
    @trainer_shown = false
  end
  
  def create_gen5_final_windows
    # Ventanas de nombre y datos - POSICIONES CORREGIDAS
    ["name", "data"].each_with_index do |window_name, index|
      @s[window_name] = Sprite.new(@vista)
      
      begin
        @s[window_name].bitmap = HallOfFameResources.get_bitmap("hallfameBWnb")
        src_y = $player.male? ? 0 : @s[window_name].bitmap.height / 2
        @s[window_name].src_rect.set(0, src_y, @s[window_name].bitmap.width, @s[window_name].bitmap.height / 2)
      rescue
        @s[window_name].bitmap = Bitmap.new(Graphics.width, 50)
        @s[window_name].bitmap.fill_rect(0, 0, Graphics.width, 50, Color.new(100, 150, 200))
      end
      
      # CORREGIDO: Posiciones fijas, no deben moverse
      @s[window_name].x = 0  # Siempre en x = 0
      @s[window_name].y = (index == 0) ? 40 : Graphics.height - 80
      @s[window_name].zoom_x = 2
      @s[window_name].zoom_y = 2
      @s[window_name].z = @vista.z + 10
      @s[window_name].visible = false
    end
    
    # Ventanas de texto SIN FONDO - POSICIONES CORREGIDAS Y FIJAS
    @s["t3"] = Sprite.new(@vista)
    @s["t3"].bitmap = Bitmap.new(Graphics.width, 64)
    @s["t3"].bitmap.font.size = 20
    text3 = "¡Campeón de la Liga de #{HallDeLaFama_REGION}! ¡Felicidades!"
    @s["t3"].bitmap.draw_text(0, 0, Graphics.width, 64, text3, 1)
    # CORREGIDO: Posición fija
    @s["t3"].x = 0  # Siempre en x = 0
    @s["t3"].y = 53
    @s["t3"].z = @vista.z + 20
    @s["t3"].visible = false
    
    time = get_play_time_formatted
    trainer_id = sprintf("%05d", $player.id)
    @s["t4"] = Sprite.new(@vista)
    @s["t4"].bitmap = Bitmap.new(Graphics.width, 64)
    @s["t4"].bitmap.font.size = 18
    @s["t4"].bitmap.font.bold = true
    text4 = "#{$player.name}                Tiempo : #{time}"
    @s["t4"].bitmap.draw_text(0, 0, Graphics.width, 64, text4, 1)
    # CORREGIDO: Posición fija
    @s["t4"].x = 0  # Siempre en x = 0
    @s["t4"].y = Graphics.height - 66
    @s["t4"].z = @vista.z + 20
    @s["t4"].visible = false
  end
  
  def animate_gen5_trainer_entrance
    # CORREGIDO: El entrenador baja hasta su posición final exacta
    target_trainer_y = Graphics.height / 2 - 80  # Posición final del entrenador
    
    while @s["trainer"].y < target_trainer_y
      @s["trainer"].y += 10
      
      # ACTUALIZAR ANIMACIONES DE POKÉMON DURANTE LA ENTRADA DEL ENTRENADOR
      party_pokemon = get_non_egg_pokemon
      party_pokemon.each_with_index do |pokemon, index|
        break if index >= 6
        if @s["poke#{index}"] && @s["poke#{index}"].respond_to?(:update)
          @s["poke#{index}"].update
        end
      end
      
      Graphics.update
      Input.update
    end
    
    # ASEGURAR POSICIÓN FINAL EXACTA DEL ENTRENADOR
    @s["trainer"].y = target_trainer_y
    
    # Pequeña pausa antes de mostrar los Pokémon
    pbWait(0.5)
    
    # Animar la aparición de todos los Pokémon con un efecto gradual
    party_pokemon = get_non_egg_pokemon
    party_pokemon.each_with_index do |pokemon, index|
      break if index >= 6
      
      if @s["poke#{index}"]
        # Efecto de aparición gradual
        20.times do |i|
          @s["poke#{index}"].opacity = (255 * i / 20)
          @s["poke#{index}"].update if @s["poke#{index}"].respond_to?(:update)
          
          # También actualizar otros Pokémon ya visibles
          (0...index).each do |prev_index|
            if @s["poke#{prev_index}"] && @s["poke#{prev_index}"].respond_to?(:update)
              @s["poke#{prev_index}"].update
            end
          end
          
          Graphics.update
          Input.update
        end
        @s["poke#{index}"].opacity = 255
        
        # Pequeña pausa entre cada Pokémon
        pbWait(0.1)
      end
    end
  end
  
  def show_gen5_final_elements
    @s["name"].visible = true
    @s["data"].visible = true
    @s["t3"].visible = true
    @s["t4"].visible = true
  end
  
  def fade(fade_in = true)
    return if !@vista || @vista.disposed?
    
    if fade_in
      # Fade lento a blanco (más frames)
      40.times do |fd|  # Aumentado de 13 a 40 para que sea más lento
        @vista.tone = Tone.new(15 * fd, 15 * fd, 15 * fd)  # Reducido de 20 a 15 para más suave
        Graphics.update
        Input.update
      end
    else
      @vista.tone = Tone.new(0, 0, 0)
    end
  end
end