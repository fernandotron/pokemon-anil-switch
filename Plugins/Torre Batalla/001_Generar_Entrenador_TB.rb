class PokemonGlobalMetadata
  attr_accessor :tb_jefes_disponibles
  attr_accessor :tb_jefe_pendiente
end

# Variables globales para mantener los pools de entrenadores disponibles
$entrenadores_disponibles = nil
$jefes_disponibles = nil
$jefe_pendiente = nil  # Nueva variable para almacenar el jefe que debe repetirse
$jefes_reiniciados = 0

# Nueva variable para almacenar los datos del entrenador generado
$entrenador_actual_torre = nil

def tb_sync_boss_pool_from_global
  if defined?($PokemonGlobal) && $PokemonGlobal
    $jefes_disponibles = $PokemonGlobal.tb_jefes_disponibles if !$PokemonGlobal.tb_jefes_disponibles.nil?
    $jefe_pendiente = $PokemonGlobal.tb_jefe_pendiente if !$PokemonGlobal.tb_jefe_pendiente.nil?
  end
end

def tb_sync_boss_pool_to_global
  if defined?($PokemonGlobal) && $PokemonGlobal
    $PokemonGlobal.tb_jefes_disponibles = $jefes_disponibles
    $PokemonGlobal.tb_jefe_pendiente = $jefe_pendiente
  end
end

def inicializar_pools_entrenadores(reset_jefes = true)
  # Inicializa o resetea los pools copiando los arrays originales
  $entrenadores_disponibles = TorreBatallaDinamica::ENTRENADORES_TORRE_BATALLA.dup
  if reset_jefes
    $jefes_disponibles = TorreBatallaDinamica::JEFES_TORRE_BATALLA.dup
    tb_sync_boss_pool_to_global
  end
end

def obtener_entrenador_unico(es_jefe = false)
  tb_sync_boss_pool_from_global
  # Inicializar pools si es la primera vez o si están vacíos
  if es_jefe
    # Si hay un jefe pendiente (perdiste contra él), devuelve ese jefe
    if $jefe_pendiente
      return $jefe_pendiente
    end
    
    if $jefes_disponibles.nil? || $jefes_disponibles.empty?
      inicializar_pools_entrenadores(true)
      $jefes_reiniciados += 1
    end
    # Seleccionar uno al azar y eliminarlo del pool
    indice_aleatorio = rand($jefes_disponibles.size)
    entrenador_seleccionado = $jefes_disponibles.delete_at(indice_aleatorio)
    tb_sync_boss_pool_to_global
  else
    if $entrenadores_disponibles.nil? || $entrenadores_disponibles.empty?
      inicializar_pools_entrenadores(false)
    end
    # Seleccionar uno al azar y eliminarlo del pool
    indice_aleatorio = rand($entrenadores_disponibles.size)
    entrenador_seleccionado = $entrenadores_disponibles.delete_at(indice_aleatorio)
  end
  
  return entrenador_seleccionado
end

def batalla_torre_batalla(trainer_name)
  inicializar_pools_entrenadores
  entrenador_seleccionado = obtener_entrenador_unico
  while entrenador_seleccionado[0] != trainer_name
    entrenador_seleccionado = obtener_entrenador_unico
  end
  entrenador_torre_batalla(false,entrenador_seleccionado)
end

def generar_entrenador_torre_batalla(es_jefe = false, entrenador_seleccionado = nil)
  # Obtener un entrenador único (sin repetir)
  entrenador_seleccionado = obtener_entrenador_unico(es_jefe) if entrenador_seleccionado.nil?
  
  nombre         = entrenador_seleccionado[0]
  genero         = entrenador_seleccionado[1]
  max_pokemon    = entrenador_seleccionado[2].size
  equipo_pokemon = entrenador_seleccionado[2]
  nivel_ajustado = 100
  
  if entrenador_seleccionado.size > 3 && GameData::TrainerType.exists?(entrenador_seleccionado[3])
    trainer_type = entrenador_seleccionado[3]
  else
    trainer_type = (genero == :Male) ? TorreBatallaDinamica::TRAINER_TYPES_MALE.sample : TorreBatallaDinamica::TRAINER_TYPES_FEMALE.sample
  end
  
  # Si es un jefe, almacénalo como pendiente antes de la batalla
  if es_jefe
    $jefe_pendiente = entrenador_seleccionado
    tb_sync_boss_pool_to_global
  end
  
  # Crear los datos del entrenador pero NO registrarlo todavía
  pokemon_usados = equipo_pokemon.first(max_pokemon)
  iv_hash = {
    :HP              => 31,
    :ATTACK          => 31,
    :DEFENSE         => 31,
    :SPECIAL_ATTACK  => 31,
    :SPECIAL_DEFENSE => 31,
    :SPEED           => 31
  }
  
  trainer_data = []
  pokemon_usados.each do |pokemon_species|
    form = 0
    if !GameData::Species.exists?(pokemon_species) && pokemon_species.to_s =~ /^(.+)_(\d+)$/
      base_sym = $1.to_sym
      if GameData::Species.exists?(base_sym)
        pokemon_species = base_sym
        form = $2.to_i
      end
    end
    trainer_data << {
      :species => pokemon_species,
      :form    => form,
      :level   => nivel_ajustado,
      :iv      => iv_hash.dup
    }
  end
  
  # Asignar número de trainer type a la variable 191
  $game_variables[191] = TorreBatallaDinamica::VARNUM_TRAINER_TYPES.fetch(trainer_type, 0)

  # Almacenar todos los datos del entrenador en la variable global
  $entrenador_actual_torre = {
    :trainer_type => trainer_type,
    :nombre => nombre,
    :genero => genero,
    :es_jefe => es_jefe,
    :pokemon_data => trainer_data,
    :entrenador_original => entrenador_seleccionado
  }
  # Actualizamos el mapa
  $game_map.refresh
  
  return $entrenador_actual_torre
end

def combate_torre_batalla
  # Verificar que hay un entrenador generado
  if $entrenador_actual_torre.nil?
    log_compat("[TorreBatalla] Error: No hay entrenador generado. Usa generar_entrenador_torre_batalla primero.") if defined?(log_compat)
    return false
  end
  
  # Extraer los datos del entrenador almacenado
  trainer_type = $entrenador_actual_torre[:trainer_type]
  nombre = $entrenador_actual_torre[:nombre]
  es_jefe = $entrenador_actual_torre[:es_jefe]
  trainer_data = $entrenador_actual_torre[:pokemon_data]
  
  # Obtener versión libre y registrar el entrenador
  version_libre = pbGetFreeTrainerParty(trainer_type, nombre)
  version_libre = 0 if version_libre.nil? || version_libre < 0

  GameData::Trainer.register({
    :id           => [trainer_type, nombre, version_libre],
    :trainer_type => trainer_type,
    :real_name    => nombre,
    :version      => version_libre,
    :pokemon      => trainer_data,
  })

  # Configurar las reglas de batalla
  setBattleRule("opponentlosetext", TorreBatallaDinamica::FRASES_TORRE_BATALLA_GANAR.sample.to_s)
  setBattleRule("opponentwintext",  TorreBatallaDinamica::FRASES_TORRE_BATALLA_PERDER.sample.to_s)

  # Combate sin mochila y en modo sin cambios
  setBattleRule("setstyle")
  setBattleRule("nobag")
  setBattleRule("noExp")
  setBattleRule("canLose")
  setBattleRule("battleBGM", "Batalla Jefe Torre") if es_jefe

  # Inicia la batalla usando la versión registrada
  resultado_batalla = TrainerBattle.start(trainer_type, nombre, version_libre)
  
  # Switch 1 indica si se ha perdido en el evento del mapa 215
  $game_switches[1] = !resultado_batalla

  # Guardar récord (Var 50) al perder antes de que Map 215 Ev#19 reinicie Var 192 a 0
  if !resultado_batalla && $game_variables && $game_variables[192].to_i > $game_variables[50].to_i
    $game_variables[50] = $game_variables[192].to_i
  end

  # Si es un jefe y el jugador ganó, limpia el jefe pendiente
  if es_jefe && resultado_batalla
    $jefe_pendiente = nil
    tb_sync_boss_pool_to_global
  end
  
  # Limpiar los datos del entrenador actual después del combate
  $entrenador_actual_torre = nil
  
  return resultado_batalla
end

# Función de compatibilidad con el código anterior
def entrenador_torre_batalla(es_jefe = false, entrenador_seleccionado = nil)
  generar_entrenador_torre_batalla(es_jefe, entrenador_seleccionado)
  return combate_torre_batalla
end

def crear_entrenador_dinamico(trainer_type, nombre, pokemon_list, nivel, max_pokemon)
  pokemon_usados = pokemon_list.first(max_pokemon)
  trainer_data = []
  iv_hash = {
    :HP              => 31,
    :ATTACK          => 31,
    :DEFENSE         => 31,
    :SPECIAL_ATTACK  => 31,
    :SPECIAL_DEFENSE => 31,
    :SPEED           => 31
  }
  pokemon_usados.each do |pokemon_species|
    trainer_data << {
      :species => pokemon_species,
      :level   => nivel,
      :iv      => iv_hash.dup
    }
  end
  version_libre = pbGetFreeTrainerParty(trainer_type, nombre)
  version_libre = 0 if version_libre.nil? || version_libre < 0

  GameData::Trainer.register({
    :id           => [trainer_type, nombre, version_libre],
    :trainer_type => trainer_type,
    :real_name    => nombre,
    :version      => version_libre,
    :pokemon      => trainer_data,
  })
  return version_libre
end

# Función auxiliar para resetear manualmente los pools al retirarse (conserva pool de 39 jefes únicos)
def resetear_entrenadores_torre
  inicializar_pools_entrenadores(false)
  $jefe_pendiente = nil  # También resetea el jefe pendiente
  tb_sync_boss_pool_to_global
  $entrenador_actual_torre = nil  # Limpia el entrenador actual
end

# Función para limpiar manualmente el jefe pendiente
def limpiar_jefe_pendiente
  $jefe_pendiente = nil
  tb_sync_boss_pool_to_global
end

# Función para obtener información del entrenador actual (para mostrar gráfico)
def obtener_info_entrenador_actual
  return nil if $entrenador_actual_torre.nil?
  
  return {
    :trainer_type => $entrenador_actual_torre[:trainer_type],
    :nombre => $entrenador_actual_torre[:nombre],
    :genero => $entrenador_actual_torre[:genero],
    :es_jefe => $entrenador_actual_torre[:es_jefe]
  }
end

# Función para ver el estado actual (opcional, para debug)
def estado_torre_batalla
  tb_sync_boss_pool_from_global
  jefes_restantes = $jefes_disponibles.nil? ? TorreBatallaDinamica::JEFES_TORRE_BATALLA.size : $jefes_disponibles.size
  entrenadores_restantes = $entrenadores_disponibles.nil? ? TorreBatallaDinamica::ENTRENADORES_TORRE_BATALLA.size : $entrenadores_disponibles.size
  
  if defined?(log_compat)
    log_compat("[TorreBatalla] Jefes restantes: #{jefes_restantes}, Entrenadores restantes: #{entrenadores_restantes}")
    if $jefe_pendiente
      log_compat("[TorreBatalla] Jefe pendiente: #{$jefe_pendiente[0]}")
    end
    if $entrenador_actual_torre
      log_compat("[TorreBatalla] Entrenador actual: #{$entrenador_actual_torre[:nombre]} (#{$entrenador_actual_torre[:trainer_type]})")
    end
  end
end

# Función para ver cuántos entrenadores quedan disponibles (opcional, para debug)
def entrenadores_restantes
  estado_torre_batalla  # Llama a la función más completa
end


def validar_especies_torre_batalla
  especies_invalidas = []
  
  # Revisar entrenadores normales
  TorreBatallaDinamica::ENTRENADORES_TORRE_BATALLA.each_with_index do |entrenador, i|
    nombre = entrenador[0]
    equipo = entrenador[2]
    
    equipo.each do |especie|
      unless GameData::Species.exists?(especie)
        especies_invalidas << "Entrenador #{i+1} (#{nombre}): #{especie}"
      end
    end
  end
  
  # Revisar jefes
  TorreBatallaDinamica::JEFES_TORRE_BATALLA.each_with_index do |jefe, i|
    nombre = jefe[0]
    equipo = jefe[2]
    
    equipo.each do |especie|
      unless GameData::Species.exists?(especie)
        especies_invalidas << "Jefe #{i+1} (#{nombre}): #{especie}"
      end
    end
  end
  
  # Mostrar resultados
  if especies_invalidas.empty?
    log_compat("[TorreBatalla] Todas las especies son válidas") if defined?(log_compat)
    return true
  else
    if defined?(log_compat)
      log_compat("[TorreBatalla] Especies inválidas encontradas:")
      especies_invalidas.each { |error| log_compat("  #{error}") }
    end
    return false
  end
end