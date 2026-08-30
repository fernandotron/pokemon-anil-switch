
# Función de conversión de la 16 a la 21 para mover panoramas.
def pbPanoramaMove(x,y)
  $game_map.move_panorama(x-4.25,y-4.25)
end

# Función para la taza de caramelos.
RARE_CANDY_CUP_VARIABLE = 121
def get_rare_candies
  $bag.add(:RARECANDY, 100)
  # msgwindow = Window_AdvancedTextPokemon.new(_INTL("¡Parece que hay muchos caramelos en la taza! ¿Cuántos te gustaría llevarte?"))
  # params = ChooseNumberParams.new
  # params.setMaxDigits(3)
  # params.setDefaultValue($game_variables[RARE_CANDY_CUP_VARIABLE])
  # params.setCancelValue(-1)
  # quantity = pbChooseNumber(msgwindow, params)
  # pbDisposeMessageWindow(msgwindow)
  # return false if quantity < 1
  # $game_variables[RARE_CANDY_CUP_VARIABLE] = quantity
  # $player.outfit=2
  # pbReceiveItem(:RARECANDY, quantity, nil, false)
  # $player.outfit=0
  # $game_map.need_refresh = true if $game_map
  # return true
end

# Mostrar "gifs"
def gif(numero,carpeta)
  $game_screen.pictures[numero].show("#{carpeta}/frame_#{$game_variables[301]}_delay-0.13s",0,0,0,100,100,255,0)
end

def battle_mewtwo_armadura
  $game_switches[COMBATE_MEWTWO] = true
  setBattleRule("battleBGM", "CombateMewtwo")
  setBattleRule("victoryBGM", "VictoriaVillano")
  setBattleRule("cannotRun")
  setBattleRule("disablePokeBalls")
  setBattleRule("2v1")
  setBattleRule("outcomevar", 1)
  setBattleRule("unrandomized") if RandomizedChallenge.enabled?
  setBattleRule("editWildPokemon", {
    :moves   => [:PSYSTRIKE, :AURASPHERE, :FLAMETHROWER, :SHADOWBALL],
    :iv      => 31,
    :ev      => 100
  })
  WildBattle.start(:MEWTWO_5, 70)
  $game_switches[COMBATE_MEWTWO] = false
end

def unown_check
  forms = [19, 8, 4, 12, 15, 14]
  # Verificar que haya suficientes Pokémon en el equipo
  return false if $player.pokemon_party.length < forms.length
  # Verificar cada posición del equipo contra el array de formas
  forms.each_with_index do |form, index|
    return false unless $player.has_species_in_order?(:UNOWN, form, -1, index)
  end
  return true
end


def contar_primeros_pokemon(cantidad)
  echoln "=== CONTANDO PRIMEROS #{cantidad} POKÉMON EN ORDEN DE DEXES ==="
  
  count = 0
  numero_global = 1
  
  # Recorrer dexes en orden: Kanto (0), Johto (1), Hoenn (2), etc.
  (0..8).each do |region|
    echoln "--- Procesando región #{region} ---"
    
    # Obtener todas las especies de esta región ordenadas por número
    especies_region = []
    GameData::Species.each do |species_data|
      next if species_data.form != 0
      numero_regional = pbGetRegionalNumber(region, species_data.species)
      if numero_regional > 0
        especies_region << [numero_regional, species_data.species]
      end
    end
    
    # Ordenar por número regional
    especies_region.sort! { |a, b| a[0] <=> b[0] }
    
    # Asignar números globales consecutivos
    especies_region.each do |numero_regional, species|
      if numero_global <= cantidad
        owned = $player.owned?(species)
        echoln "Global #{numero_global}: #{species} (Región #{region} ##{numero_regional}) - ¿Capturado? #{owned}"
        count += 1 if owned
        numero_global += 1
      else
        break
      end
    end
    
    break if numero_global > cantidad
  end
  
  echoln "--- Resultado final: #{count}/#{cantidad} ---"
  return count
end



def has_any_custom_modes?
  return true if RandomizedChallenge.enabled?
  return true if ChallengeModes.on? || ChallengeModes.queued?
  return true if $game_switches[MODO_VGC]
  return true if $game_switches[MODO_INVERSO]
  return true if $game_switches[MODO_SIN_GRINDEO]
  return false
end

def pbRuleBook
  return unless has_any_custom_modes?
  
  # Build array of available modes with their identifiers
  available_modes = []
  available_modes << [:random, _INTL("Modo Random")] if RandomizedChallenge.enabled?
  available_modes << [:nuzlocke, _INTL("Modo Nuzlocke")] if ChallengeModes.on? || ChallengeModes.queued?
  available_modes << [:vgc, _INTL("Modo VGC (dobles)")] if $game_switches[MODO_VGC]
  available_modes << [:inverso, _INTL("Modo Inverso")] if $game_switches[MODO_INVERSO]
  available_modes << [:minimal_grinding, _INTL("Modo Sin Grindeo")] if $game_switches[MODO_SIN_GRINDEO]
  
  # Extract just the display names for the message
  mode_names = available_modes.map { |mode| mode[1] }
  mode_names << _INTL("Salir")
  
  choice = pbMessage(_INTL("Selecciona el modo para el cual quieres ver las reglas"), mode_names, -1)
  
  # Handle exit or cancel
  return if choice == -1 || choice >= available_modes.length
  
  # Get the selected mode identifier
  selected_mode = available_modes[choice][0]
  
  case selected_mode
  when :random
    RandomizerConfigurator.display_current_rules
  when :nuzlocke
    ChallengeModes.display_rules
  when :vgc
    pbMessage(_INTL("Todos los combates serán dobles. Si llevas 1 solo Pokémon, será un 1v2"))
  when :inverso
    pbMessage(_INTL("La tabla de tipos es invertida, es decir Fuego es fuerte contra Agua y Agua es fuerte contra Fuego, etc."))
  when :minimal_grinding
    pbMessage(_INTL("En este modo los EVs e IVs no se tienen en cuenta en combate. (Se seguirán calculando para cosas como el tipo del poder oculto)"))
  end
end

ItemHandlers::UseFromBag.add(:RULEBOOK, proc{ |item|
  pbRuleBook
  next 1
})

ItemHandlers::UseInField.add(:RULEBOOK, proc{ |item|
  pbRuleBook
  next 1
})















# Script dinámico para el casino de Azulona
def casino_pokemon_exchange
  # Array de premios: [símbolo_pokémon, precio_monedas, nivel]
  premios = [
    [:PIKACHU, 3000, 35],
    [:SCYTHER, 7000, 35], 
    [:PORYGON, 10000, 35],
    [:DRATINI, 15000, 35],
    [:CORSOLA, 5000, 35]
  ]
  
  # Construir las opciones del menú dinámicamente
  opciones = []
  premios.each do |pokemon, precio, nivel|
    nombre = GameData::Species.get(pokemon).name
    opciones.push("#{nombre} - #{precio} monedas")
  end
  opciones.push("Nada")
  
  # USAR \\cn en el mensaje para mostrar las monedas arriba
  choice = pbMessage("\\cnAquí puedes cambiar tus monedas por Pokémon.\\n¿Qué premio quieres?", opciones, -1)
  
  # Si eligió "Nada" o canceló
  if choice == -1 || choice >= premios.length
    pbMessage("De acuerdo, vuelve cuando quieras.")
    return
  end
  
  # Obtener datos del premio elegido
  pokemon_elegido = premios[choice][0]
  precio_elegido = premios[choice][1] 
  nivel_elegido = premios[choice][2]
  nombre_elegido = GameData::Species.get(pokemon_elegido).name
  
  # Confirmar compra (manteniendo las monedas visibles)
  if pbConfirmMessage("\\cn¿Quieres canjear tus monedas por un #{nombre_elegido}?")
    # Verificar si tiene suficientes monedas
    if $player.coins >= precio_elegido
      # Restar monedas
      $player.coins -= precio_elegido
      
      # Dar el Pokémon
      if RandomizedChallenge.randomize_pokemon? && MonotypeChallenge.enabled?
        species = valid_random_species(nil, false, MonotypeChallenge.type)
        pokemon_elegido = species if species
        RandomizedChallenge.pause_random_species
        enable_random = true
      end
      pokemon = Pokemon.new(pokemon_elegido, nivel_elegido)
      RandomizedChallenge.resume_random_species if enable_random
      pbAddPokemon(pokemon, nivel_elegido)

      pbMessage("\\cn¡Gracias por tu canje! ¡Esperamos que cuides bien de él!")
    else
      pbMessage("\\cnNo tienes suficientes monedas.\\nNecesitas #{precio_elegido} monedas.")
    end
  else
    pbMessage("De acuerdo, vuelve cuando quieras.")
  end
end



def comprar_monedas_casino
  # Saludo inicial
  pbMessage("¡Te doy la bienvenida al Casino Azulona!")
  
  # Verificar si tiene el monedero
  if !$bag.has?(:COINCASE)
    pbMessage("Aquí vendemos monedas, pero para ello necesitas un monedero. ¡Habla conmigo cuando tengas uno!")
    return
  end
  
  # Preguntar si quiere comprar monedas
  if !pbConfirmMessage("¿Te gustaría comprar monedas para poder jugar?")
    pbMessage("¿No? Piénsalo bien. ¡Solo se vive una vez!")
    return
  end
  
  # Array de opciones: [monedas, precio_dinero]
  opciones_monedas = [
    [50, 1000],
    [500, 10000], 
    [5000, 100000]
  ]
  
  loop do
    # Construir opciones del menú
    opciones_texto = []
    opciones_monedas.each do |monedas, precio|
      opciones_texto.push("#{monedas} monedas [#{precio.to_s_formatted}$]")
    end
    opciones_texto.push("Salir")
    
    # Mostrar menú con dinero y monedas visibles
    choice = pbMessage("\\g\\cn¿Cuántas monedas quieres comprar?", opciones_texto, -1)
    
    # Si eligió "Salir" o canceló
    if choice == -1 || choice >= opciones_monedas.length
      pbMessage("¿No? Piénsalo bien. ¡Solo se vive una vez!")
      break
    end
    
    # Obtener datos de la opción elegida
    monedas_elegidas = opciones_monedas[choice][0]
    precio_elegido = opciones_monedas[choice][1]
    
    # AÑADIDO: Mensaje de confirmación antes de comprar
    if !pbConfirmMessage("\\g\\cn¿Quieres comprar #{monedas_elegidas} monedas por #{precio_elegido.to_s_formatted}$?")
      next  # Volver al menú si dice que no
    end
    
    # Verificar si el monedero se llenaría
    if $player.coins + monedas_elegidas > Settings::MAX_COINS
      pbMessage("\\g\\cnTu Monedero está lleno.")
      next
    end
    
    # Verificar si tiene suficiente dinero
    if $player.money < precio_elegido
      pbMessage("\\g\\cnNo te lo puedes permitir, lo siento.")
      next
    end
    
    # Realizar la transacción
    $player.money -= precio_elegido
    $player.coins += monedas_elegidas
    
    # AÑADIDO: Sonido de compra exitosa
    pbSEPlay("Mart buy item")
    
    pbMessage("\\g\\cnAquí tienes, ¡muchas gracias!")
    
    # Preguntar si quiere comprar más
    if !pbConfirmMessage("\\g\\cn¿Quieres comprar algo más?")
      break
    end
  end
end



# Función para dar una Estrella en la Tarjeta de Entrenador
NUM_ENTREN_IMPORTANTES = 19

def aumentar_entrenadores_importantes
  $game_variables[72] += 1
  todas_entrenadores_importantes_hechos?
end

def todas_entrenadores_importantes_hechos?
  if $game_variables[72] == NUM_ENTREN_IMPORTANTES &&
      $game_switches[375] == false
    $player.stars += 1
    $game_switches[375] = true
    pbMEPlay("Voltorb Flip win")
    pbMessage("¡Has obtenido una <b>Estrella</b> en tu Tarjeta de Entrenador!")
  end
end