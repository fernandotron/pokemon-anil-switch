#===============================================================================
#
#-------------------------------------------------------------------------------
#                   Generación 3 del Salón de la Fama
#                             por JessWishes
#                      Porteado a v21 por Assistant
#-------------------------------------------------------------------------------
#
# Este archivo contiene la implementación de la animación
# de la Generación 3 del Salón de la Fama (Ruby/Sapphire/Emerald)
#
#===============================================================================

class HallDeLaFama
  
  #=============================================================================
  # Generación 3 - Estilo Ruby/Sapphire/Emerald
  #=============================================================================
  def jsGen3
    setup_gen3_background
    setup_gen3_panels
    
    pbMessage(_INTL("Guardando Partida\\wtnp[5].\\wtnp[5].\\wtnp[5].\\wtnp[30]"))
    pokes_info
    
    # Animación de Pokémon
    animate_gen3_pokemon_sequence
    
    # Efecto confeti
    confetti_effect
    
    # Secuencia del entrenador
    show_gen3_trainer_sequence
    
    pbWait(3.0)  # Era 120 frames = ~3 segundos
    fade(true)
    dispose
  end
  
  private
  
  #=============================================================================
  # Configuración del fondo Generación 3
  #=============================================================================
  def setup_gen3_background
    @s["bg"] = Sprite.new(@vista)
    
    begin
      @s["bg"].bitmap = HallOfFameResources.get_bitmap("hallfamebg")
      
      # Aplicar cambio de color según configuración
      case HallDeLaFama_EMER
      when 1  # Azul/Rosa según género
        @s["bg"].bitmap.hue_change($player.female? ? 100 : 330)
      when 2  # Verde Esmeralda
        @s["bg"].bitmap.hue_change(280)
      when 3  # Azul FR/LG
        @s["bg"].bitmap.hue_change(20)
      end
    rescue
      # Fallback background
      @s["bg"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
      @s["bg"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, 
                                Color.new(100, 150, 200))
    end
  end
  
  #=============================================================================
  # Paneles decorativos
  #=============================================================================
  def setup_gen3_panels
    # Panel superior
    @s["p1"] = Sprite.new(@vista)
    @s["p1"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["p1"].bitmap.fill_rect(0, 0, Graphics.width, 15, Color.new(0, 0, 0, 120))
    
    # Panel inferior
    @s["p2"] = Sprite.new(@vista)
    @s["p2"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["p2"].bitmap.fill_rect(0, Graphics.height - 110, Graphics.width, 135, 
                              Color.new(0, 0, 0, 120))
  end
  
  #=============================================================================
  # Animación secuencial de Pokémon Gen 3
  #=============================================================================
  def animate_gen3_pokemon_sequence
    party_index = 0
    
    $player.party.each_with_index do |pokemon, i|
      next if pokemon.egg?
      
      # Posiciones iniciales según el índice del Pokémon
      initial_positions = [
        [Graphics.width / 2, Graphics.height],          # Centro-abajo
        [Graphics.width, Graphics.height],              # Derecha-abajo
        [-@s["poke#{party_index}"].bitmap.width, Graphics.height], # Izquierda-abajo
        [Graphics.width / 2, -@s["poke#{party_index}"].bitmap.height], # Centro-arriba
        [-@s["poke#{party_index}"].bitmap.width, -@s["poke#{party_index}"].bitmap.height], # Izquierda-arriba
        [Graphics.width, -@s["poke#{party_index}"].bitmap.height]  # Derecha-arriba
      ]
      
      pos = initial_positions[party_index] || initial_positions[0]
      @s["poke#{party_index}"].x = pos[0]
      @s["poke#{party_index}"].y = pos[1]
      @s["poke#{party_index}"].z = @vista.z + 1
      
      # Crear ventana de información
      gen3_pokemon_info(party_index)
      
      # Animaciones específicas por posición
      animate_gen3_pokemon_movement(party_index)
      
      @s["t1"].visible = true
      pbWait(0.75)  # Era 30 frames = ~0.75 segundos
      @s["t1"].dispose
      @s["poke#{party_index}"].opacity = 120
      
      party_index += 1
    end
    
    pbWait(0.25)  # Era 10 frames
    # Restaurar opacidad de todos los Pokémon
    (0...party_index).each { |i| @s["poke#{i}"].opacity = 255 }
  end
  
  #=============================================================================
  # Movimientos específicos por posición
  #=============================================================================
  def animate_gen3_pokemon_movement(party_index)
    case party_index
    when 0  # Centro hacia arriba
      21.times do
        @s["poke#{party_index}"].y -= 14
        Graphics.update
        Input.update
      end
    when 1  # Derecha hacia centro-arriba
      21.times do
        @s["poke#{party_index}"].x -= 20
        @s["poke#{party_index}"].y -= 14
        Graphics.update
        Input.update
      end
    when 2  # Izquierda hacia centro-arriba
      21.times do
        @s["poke#{party_index}"].x += 28
        @s["poke#{party_index}"].y -= 14
        Graphics.update
        Input.update
      end
    when 3  # Centro hacia abajo
      21.times do
        @s["poke#{party_index}"].y += 18
        Graphics.update
        Input.update
      end
    when 4  # Izquierda hacia centro-abajo
      21.times do
        @s["poke#{party_index}"].x += 28
        @s["poke#{party_index}"].y += 18
        Graphics.update
        Input.update
      end
    when 5  # Derecha hacia centro-abajo
      21.times do
        @s["poke#{party_index}"].x -= 20
        @s["poke#{party_index}"].y += 18
        Graphics.update
        Input.update
      end
    end
  end
  
  #=============================================================================
  # Efecto confeti
  #=============================================================================
  def confetti_effect
    # Mostrar mensaje de entrada
    gen3_pokemon_info(0, true)
    @s["t1"].visible = true
    
    begin
      create_confetti_sprites
      animate_confetti
    rescue => e
      puts "Error en efecto confeti: #{e.message}" if $DEBUG
      pbWait(60)  # Fallback: solo esperar
    end
    
    @s["t1"].visible = false
  end
  
  def create_confetti_sprites
    con_v = Viewport.new(0, 0, Graphics.width, Graphics.height - 110)
    con_v.z = @vista.z + 1
    
    16.times do |sp|
      @s["c#{sp}"] = Sprite.new(con_v)
      
      begin
        @s["c#{sp}"].bitmap = HallOfFameResources.get_bitmap("hallfameconffeti")
        @s["c#{sp}"].src_rect.set(0, 16 * sp, 16, 16)
      rescue
        # Fallback: crear confeti simple
        @s["c#{sp}"].bitmap = Bitmap.new(8, 8)
        colors = [Color.new(255, 0, 0), Color.new(0, 255, 0), 
                  Color.new(0, 0, 255), Color.new(255, 255, 0)]
        @s["c#{sp}"].bitmap.fill_rect(0, 0, 8, 8, colors[sp % 4])
      end
      
      @s["c#{sp}"].x = rand(Graphics.width)
      @s["c#{sp}"].y = -(rand(Graphics.height))
      @s["c#{sp}"].z = con_v.z + 1
    end
  end
  
  def animate_confetti
    mst = 0
    
    loop do
      case mst
      when 0, 3
        8.times do |sp|
          unless @s["c#{sp}"].disposed?
            @s["c#{sp}"].x += 15
            @s["c#{sp}"].y += 16
          end
          unless @s["c#{sp + 8}"].disposed?
            @s["c#{sp + 8}"].y += 16
            @s["c#{sp + 8}"].x -= 15
          end
          Graphics.update
          Input.update
        end
      when 1, 2
        8.times do |sp|
          unless @s["c#{sp}"].disposed?
            @s["c#{sp}"].x -= 15
            @s["c#{sp}"].y += 16
          end
          unless @s["c#{sp + 8}"].disposed?
            @s["c#{sp + 8}"].y += 16
            @s["c#{sp + 8}"].x += 15
          end
          Graphics.update
          Input.update
        end
      end
      
      mst += 1
      mst = 0 if mst > 3
      
      # Dispose confeti que sale de pantalla
      16.times do |sp|
        if @s["c#{sp}"].y > (Graphics.height - 110)
          @s["c#{sp}"].dispose
        end
      end
      
      # Verificar si todo el confeti ha terminado
      finished_count = 0
      16.times { |sp| finished_count += 1 if @s["c#{sp}"].disposed? }
      break if finished_count == 16
    end
  end
  
  #=============================================================================
  # Secuencia del entrenador Gen 3
  #=============================================================================
  def show_gen3_trainer_sequence
    pbWait(0.25)
    @s["p1"].dispose
    @s["p2"].dispose
    
    # Atenuar Pokémon
    party_count = get_non_egg_pokemon.size
    (0...party_count).each { |i| @s["poke#{i}"].opacity = 120 }
    
    # Crear sprite del entrenador
    @s["trainer"] = create_trainer_sprite(false)
    @s["trainer"].x = Graphics.width / 2 - 83
    @s["trainer"].y = Graphics.height / 2 - 116
    @s["trainer"].z = @vista.z + 2
    
    pbWait(0.75)  # Era 30 frames
    
    # Animación de entrada del entrenador
    40.times do
      @s["trainer"].x += 5
      Graphics.update
      Input.update
    end
    
    # Mostrar datos del entrenador
    gen3_trainer_data
    gen3_final_message
  end
  
  #=============================================================================
  # Información de Pokémon Gen 3
  #=============================================================================
  def gen3_pokemon_info(pokemon_index, show_message = false, is_final = false)
    if is_final
      @s["t1"] = create_text_window(
        "¡CAMPEÓN DE LA LIGA #{HallDeLaFama_REGION}!\n¡FELICIDADES!",
        0, 288, Graphics.width, 64
      )
    else
      if show_message
        text = "<ac>¡Has entrado al Salón de la Fama!</ac>"
      else
        pokemon = $player.party[pokemon_index]
        genero = get_pokemon_gender_symbol(pokemon)
        species_data = GameData::Species.get(pokemon.species)
        text = "<ac>No. #{species_data.id_number}  #{pokemon.name}/#{species_data.name} #{genero}</ac>" +
               "<ac>Nv. #{pokemon.level}  /#{sprintf('%05d', pokemon.owner.public_id)}</ac>"
      end
      
      @s["t1"] = create_text_window(
        text, 0, show_message ? 300 : 288, Graphics.width, 64, false
      )
    end
  end
  
  #=============================================================================
  # Datos del entrenador
  #=============================================================================
  def gen3_trainer_data
    time = get_play_time_formatted
    
    @s["sts"] = create_text_window(
      "#{$player.name}\nID : #{$player.public_id}\nTiempo Jugado : #{time}",
      0, 20, Graphics.width / 2, 100
    )
  end
  
  def gen3_final_message
    gen3_pokemon_info(0, false, true)
  end
end
