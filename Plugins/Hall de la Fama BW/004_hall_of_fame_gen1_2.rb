#===============================================================================
#
#-------------------------------------------------------------------------------
#                 Generaciones 1 y 2 del Salón de la Fama
#                             por JessWishes
#                      Porteado a v21 por Assistant
#-------------------------------------------------------------------------------
#
# Este archivo contiene las implementaciones de las animaciones
# de las Generaciones 1 y 2 del Salón de la Fama
#
#===============================================================================

class HallDeLaFama
  
  #=============================================================================
  # Generación 1 y 2 - Estilo clásico
  #=============================================================================
  def jsGen1(gene = 1)
    # Configurar fondo
    @s["bg"] = Sprite.new(@vista)
    @s["bg"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @s["bg"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, 
                              Color.new(HallDeLaFama_COLOR[0], HallDeLaFama_COLOR[1], HallDeLaFama_COLOR[2]))
    
    # Mensaje de guardado
    pbMessage(_INTL("Guardando Partida\\wtnp[5].\\wtnp[5].\\wtnp[5].\\wtnp[30]"))
    
    # Crear sprites de Pokémon
    pokes_info
    
    # Título principal
    title_text = (gene == 1) ? "Salón de la Fama" : "Nuevo en el Salón de la Fama"
    @s["t1"] = create_text_window(
      "<ac>#{title_text}</ac>",
      40, gene == 1 ? Graphics.height - 65 : 0,
      Graphics.width - 80, 64
    )
    
    # Animación de Pokémon
    animate_pokemon_sequence(gene)
    
    # Mostrar entrenador
    show_trainer_sequence(gene)
    
    # Información del Pokédex
    show_pokedex_info(gene)
    
    # Verificación final
    pbMessage(_INTL("Verificando Pokédex\\wtnp[5].\\wtnp[5].\\wtnp[5].\\wtnp[5]"))
    dex_info
    
    # Fade final y limpieza
    fade(true)
    dispose
  end
  
  private
  
  #=============================================================================
  # Animación secuencial de Pokémon
  #=============================================================================
  def animate_pokemon_sequence(gene)
    party_index = 0
    
    $player.party.each_with_index do |pokemon, i|
      next if pokemon.egg?
      
      # Animación de entrada del sprite trasero (OPTIMIZADA)
      25.times do  # Reducido de 50 a 25
        @s["poke#{party_index}_2"].x -= 34  # Aumentado de 17 a 34
        Graphics.update
        Input.update
      end
      
      # Animación de entrada del sprite frontal (OPTIMIZADA)
      movement_count = (gene == 1) ? 27 : 20  # Reducido de 54/41 a 27/20
      movement_count.times do
        @s["poke#{party_index}"].x += 20  # Aumentado de 10 a 20
        Graphics.update
        Input.update
      end
      
      # Mostrar información del Pokémon
      gen1_pokemon_info(party_index, gene)
      @s["t1"].visible = true
      pbWait(2.5)  # Era 100 frames = ~2.5 segundos
      
      # Transición
      fade(true)
      safe_set_sprite_property("poke#{party_index}", :visible, false)
      safe_set_sprite_property("poke#{party_index}_2", :visible, false)
      
      if @s["t2"]
        @s["t2"].visible = false
        @s["t2"].dispose
      end
      
      @s["t1"].visible = false
      fade(false)
      pbWait(0.25)  # Era 10 frames = ~0.25 segundos
      
      party_index += 1
    end
  end
  
  #=============================================================================
  # Secuencia del entrenador
  #=============================================================================
  def show_trainer_sequence(gene)
    # Crear sprite de entrenador (empezar con sprite trasero)
    @s["trainer"] = create_trainer_sprite(true)
    @s["trainer"].x = Graphics.width
    @s["trainer"].y = Graphics.height - @s["trainer"].bitmap.height
    
    # Animación de entrada desde la derecha (OPTIMIZADA)
    25.times do  # Reducido de 50 a 25
      @s["trainer"].x -= 34  # Aumentado de 17 a 34
      Graphics.update
      Input.update
    end
    
    # Cambiar a sprite frontal
    @s["trainer"].dispose
    @s["trainer"] = create_trainer_sprite(false)
    @s["trainer"].x = 384  # Posición después de la animación
    @s["trainer"].y = 105
    
    # Movimiento final (OPTIMIZADA)
    28.times do  # Reducido de 57 a 28
      @s["trainer"].x += 24  # Aumentado de 12 a 24
      Graphics.update
      Input.update
    end
    
    # Nombre del jugador (solo Gen 1)
    if gene == 1
      @s["t3"] = create_text_window(
        "<ac>#{$player.name}</ac>",
        70, (Graphics.height / 4) - 85,
        Graphics.width - 140, 64
      )
    end
    
    # Información del entrenador
    gen1_trainer_info(gene)
  end
  
  #=============================================================================
  # Información del Pokédex
  #=============================================================================
  def show_pokedex_info(gene)
    pokedex_text = if gene == 1
      "<ar><b>Vistos : #{@vistos}</b></ar>\n<ar><b>Obtenidos : #{@obtenidos}</b></ar>"
    else
      "<ac><b>#{@vistos}</b> Pokémon vistos</ac><ac><b>#{@obtenidos}</b> Pokémon obtenidos</ac>"
    end
    
    @s["t4"] = create_text_window(
      pokedex_text,
      0, Graphics.height - 120,
      Graphics.width, 120
    )
    
    if gene == 1
      @s["t5"] = create_text_window(
        "Pokédex",
        10, Graphics.height - 120,
        Graphics.width, 64
      )
    end
    
    pbWait(3.0)  # Era 120 frames = ~3 segundos
    
    if gene == 1
      @s["t5"].visible = false
    end
    @s["t4"].visible = false
  end
  
  #=============================================================================
  # Información individual de Pokémon
  #=============================================================================
  def gen1_pokemon_info(pokemon_index, gene = 1)
    g2 = (gene == 2)
    gene = 1 if pokemon_index.is_a?(String)
    
    time = get_play_time_formatted
    
    if pokemon_index.is_a?(Integer)
      pokemon = $player.party[pokemon_index]
      
      if gene == 1
        # Obtener información de tipos
        type1_name, type2_name = get_pokemon_type_info(pokemon)
        
        if type2_name.nil?
          texto = "#{pokemon.name}\nNivel/\n       <b>#{pokemon.level}</b>\nTipo 1/\n       <b>#{type1_name}</b>"
        else
          texto = "#{pokemon.name}\nNivel/\n       <b>#{pokemon.level}</b>\nTipo 1/\n       <b>#{type1_name}</b>\nTipo 2/\n       <b>#{type2_name}</b>"
        end
      else
        genero = get_pokemon_gender_symbol(pokemon)
        species_data = GameData::Species.get(pokemon.species)
        texto = "<ac><b>No. #{species_data.id_number}</b>  #{species_data.name}  #{genero}</ac>" +
                "<ac>/#{pokemon.name}</ac>\n" +
                "<ac><b>Nv. #{pokemon.level}     <b>ID No.</b> /#{sprintf('%05d', pokemon.owner.public_id)}</ac>"
      end
    else
      if g2
        texto2 = "#{$player.name}\n<b>ID No./ #{sprintf('%05d', $player.public_id)}</b>\n" +
                 "Tiempo de Juego\n<b><ac>#{time}</ac></b>"
      else
        texto2 = "Tiempo Jugado\n<b><ac>#{time}</ac></b>\nDinero\n<ac><b>$#{$player.money}</b></ac>"
      end
    end
    
    # Crear ventana de información
    text_content = (pokemon_index == "entrenador") ? texto2 : texto
    width = (gene == 1) ? Graphics.width / 2 : Graphics.width
    x_pos = gene == 1 ? 20 : 0
    y_pos = if pokemon_index.is_a?(Integer)
              (Graphics.height / 4) - 60
            else
              (Graphics.height / 4)
            end
    y_pos = 256 if gene == 2
    
    @s["t2"] = create_text_window(text_content, x_pos, y_pos, width, 120)
  end
  
  #=============================================================================
  # Información del entrenador
  #=============================================================================
  def gen1_trainer_info(gene)
    gen1_pokemon_info("entrenador", gene)
  end
end
