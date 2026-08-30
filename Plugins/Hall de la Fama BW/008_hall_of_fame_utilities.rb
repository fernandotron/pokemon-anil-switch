#===============================================================================
#
#-------------------------------------------------------------------------------
#                 Utilidades y PC del Salón de la Fama
#                             por JessWishes
#                      Porteado a v21 por Assistant
#-------------------------------------------------------------------------------
#
# Este archivo contiene las utilidades finales, sistema de PC,
# comandos de debug y configuraciones adicionales
#
#===============================================================================

#===============================================================================
# Integración con el menú de PC
#===============================================================================
# MenuHandlers.add(:pc_menu, :hall_of_fame, {
#   "name"      => _INTL("Hall de la Fama"),
#   "order"     => 40,
#   "condition" => proc { next $PokemonGlobal.hallOfFameLastNumber > 0 },
#   "effect"    => proc { |menu|
#     pbMessage("\\se[PC access]" + _INTL("Has accedido al Hall de la Fama."))
#     pbHallOfFamePC
#     next false
#   }
# })

#===============================================================================
# Función principal para acceder al PC
#===============================================================================
def pbHallOfFamePC
  scene = HallOfFameViewerScene.new
  screen = HallOfFameViewerScreen.new(scene)
  screen.pbStartScreen
end

#===============================================================================
# Escena del visor del Hall de la Fama
#===============================================================================
class HallOfFameViewerScene
  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @hallIndex = $PokemonGlobal.hallOfFame.size - 1
    @hallEntry = $PokemonGlobal.hallOfFame[-1]
    @pokemonIndex = 0
    
    # Verificar que hay datos
    if !@hallEntry || @hallEntry.empty?
      pbMessage(_INTL("No hay registros en el Hall de la Fama."))
      return false
    end
    
    create_background
    create_pokemon_sprites
    update_display
    
    pbFadeInAndShow(@sprites)
    return true
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  def create_background
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    
    # Crear fondo degradado
    (0...Graphics.height).each do |y|
      intensity = 32 + (y * 32 / Graphics.height)
      color = Color.new(intensity, intensity, intensity + 32)
      @sprites["bg"].bitmap.fill_rect(0, y, Graphics.width, 1, color)
    end
  end

  def create_pokemon_sprites
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].x = Graphics.width / 2
    @sprites["pokemon"].y = Graphics.height / 2
    @sprites["pokemon"].z = 5
    
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 10
    pbSetSystemFont(@sprites["overlay"].bitmap)
  end

  def update_display
    return if !@hallEntry || @hallEntry.empty?
    
    pokemon = @hallEntry[@pokemonIndex]
    @sprites["pokemon"].setPokemonBitmap(pokemon)
    
    # Centrar el sprite
    if @sprites["pokemon"].bitmap
      @sprites["pokemon"].ox = @sprites["pokemon"].bitmap.width / 2
      @sprites["pokemon"].oy = @sprites["pokemon"].bitmap.height / 2
    end
    
    update_overlay_text(pokemon)
  end
  
  def update_overlay_text(pokemon)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    
    # Información del Pokémon
    pokename = pokemon.name
    speciesname = pokemon.speciesName
    genero = ""
    genero = " ♂" if pokemon.male?
    genero = " ♀" if pokemon.female?
    speciesname += genero
    
    # Número de entrada al Hall de la Fama
    hall_number = $PokemonGlobal.hallOfFameLastNumber + @hallIndex - $PokemonGlobal.hallOfFame.size + 1
    
    # Información adicional
    trainer_name = pokemon.owner.name
    trainer_id = sprintf("%05d", pokemon.owner.public_id)
    
    # Obtener información del lugar donde fue capturado
    map_name = "Lugar desconocido"
    if pokemon.obtain_map && pokemon.obtain_map > 0
      map_name = pbGetMapNameFromId(pokemon.obtain_map)
    end
    map_name = pokemon.obtain_text if pokemon.obtain_text && !pokemon.obtain_text.empty?
    
    # Tipos del Pokémon
    type1_name, type2_name = HallOfFameTypes.get_type_names(pokemon)
    type_text = type1_name
    type_text += "/#{type2_name}" if type2_name
    
    # Posiciones del texto
    text_positions = [
      # Título
      [_INTL("Hall de la Fama No. {1}", hall_number), Graphics.width / 2, 32, :center, 
       Color.new(255, 255, 255), Color.new(128, 128, 128)],
      
      # Información del Pokémon
      [pokename, Graphics.width / 2, Graphics.height - 160, :center, 
       Color.new(255, 255, 255), Color.new(0, 0, 0)],
      [speciesname, Graphics.width / 2, Graphics.height - 140, :center, 
       Color.new(200, 200, 255), Color.new(0, 0, 0)],
      [_INTL("Nivel {1}", pokemon.level), Graphics.width / 2, Graphics.height - 120, :center, 
       Color.new(255, 255, 200), Color.new(0, 0, 0)],
      [_INTL("Tipo: {1}", type_text), Graphics.width / 2, Graphics.height - 100, :center, 
       Color.new(200, 255, 200), Color.new(0, 0, 0)],
      
      # Información del entrenador
      [_INTL("Entrenador: {1}", trainer_name), Graphics.width / 2, Graphics.height - 70, :center, 
       Color.new(255, 200, 200), Color.new(0, 0, 0)],
      [_INTL("ID: {1}", trainer_id), Graphics.width / 2, Graphics.height - 50, :center, 
       Color.new(255, 200, 200), Color.new(0, 0, 0)],
      [_INTL("Capturado en: {1}", map_name), Graphics.width / 2, Graphics.height - 30, :center, 
       Color.new(180, 255, 180), Color.new(0, 0, 0)],
      
      # Controles
      [_INTL("◄ ► Cambiar Pokémon"), 32, Graphics.height - 32, :left, 
       Color.new(255, 255, 255), Color.new(0, 0, 0)],
      [_INTL("Acción: Cambiar Equipo"), 32, Graphics.height - 16, :left, 
       Color.new(255, 255, 255), Color.new(0, 0, 0)],
      [_INTL("X: Salir"), Graphics.width - 32, Graphics.height - 16, :right, 
       Color.new(255, 255, 255), Color.new(0, 0, 0)]
    ]
    
    pbDrawTextPositions(overlay, text_positions)
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      
      if Input.trigger?(Input::BACK)
        break
      elsif Input.trigger?(Input::LEFT)
        @pokemonIndex -= 1
        @pokemonIndex = @hallEntry.size - 1 if @pokemonIndex < 0
        update_display
        pbSEPlay("GUI menu cursor")
      elsif Input.trigger?(Input::RIGHT)
        @pokemonIndex += 1
        @pokemonIndex = 0 if @pokemonIndex >= @hallEntry.size
        update_display
        pbSEPlay("GUI menu cursor")
      elsif Input.trigger?(Input::USE)
        # Cambiar equipo
        @hallIndex -= 1
        if @hallIndex < 0
          @hallIndex = $PokemonGlobal.hallOfFame.size - 1
        end
        @hallEntry = $PokemonGlobal.hallOfFame[@hallIndex]
        @pokemonIndex = 0
        update_display
        pbSEPlay("GUI menu cursor")
      end
    end
  end
end

#===============================================================================
# Pantalla del visor del Hall de la Fama
#===============================================================================
class HallOfFameViewerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    if @scene.pbStartScene
      @scene.pbMain
      @scene.pbEndScene
    end
  end
end

#===============================================================================
# Funciones principales de acceso
#===============================================================================
def pbHallOfFameEntry
  # Iniciamos con un fade
  pbFadeOutIn { SalonDeFama.registrar }
end

def pbEnterHallOfFame
  pbFadeOutIn { SalonDeFama.registrar }
end

def pbViewHallOfFameEntry(entry_number)
  return false if entry_number < 1 || entry_number > $PokemonGlobal.hallOfFame.size
  
  # Implementación básica - se puede expandir
  pbMessage(_INTL("Viendo entrada #{entry_number} del Hall de la Fama"))
  return true
end

#===============================================================================
# Funciones de estadísticas y utilidades
#===============================================================================

# Obtener número total de entradas
def pbGetHallOfFameCount
  return $PokemonGlobal.hallOfFame.size
end

# Obtener la entrada más reciente
def pbGetLatestHallOfFameEntry
  return nil if $PokemonGlobal.hallOfFame.empty?
  return $PokemonGlobal.hallOfFame.last
end

# Verificar si un Pokémon específico ha estado en el Hall de la Fama
def pbPokemonInHallOfFame?(pokemon)
  $PokemonGlobal.hallOfFame.each do |entry|
    entry.each do |hall_pokemon|
      return true if hall_pokemon.species == pokemon.species && 
                     hall_pokemon.personalID == pokemon.personalID
    end
  end
  return false
end

# Obtener todas las especies que han estado en el Hall de la Fama
def pbGetHallOfFameSpecies
  species_set = Set.new
  
  $PokemonGlobal.hallOfFame.each do |entry|
    entry.each do |pokemon|
      species_set.add(pokemon.species)
    end
  end
  
  return species_set.to_a
end

# Estadísticas del Hall de la Fama
def pbGetHallOfFameStats
  return {
    total_entries: $PokemonGlobal.hallOfFame.size,
    unique_species: pbGetHallOfFameSpecies.size,
    first_entry_date: nil, # Se podría implementar con timestamps
    latest_entry_number: $PokemonGlobal.hallOfFameLastNumber
  }
end

#===============================================================================
# Comandos de debug (solo disponibles en modo debug)
#===============================================================================
if defined?(DebugMenuCommands)
  DebugMenuCommands.register("halloffame", {
    "parent"      => "playermenu",
    "name"        => _INTL("Test Hall of Fame"),
    "description" => _INTL("Test the Hall of Fame sequence."),
    "effect"      => proc {
      if $player.party.empty?
        pbMessage(_INTL("No hay Pokémon en el equipo."))
      else
        SalonDeFama.registrar
      end
    }
  })
  
  DebugMenuCommands.register("clearhalloffame", {
    "parent"      => "playermenu", 
    "name"        => _INTL("Clear Hall of Fame"),
    "description" => _INTL("Clear all Hall of Fame entries."),
    "effect"      => proc {
      if pbConfirmMessage(_INTL("¿Borrar todos los registros del Salón de la Fama?"))
        $PokemonGlobal.hallOfFame.clear
        $PokemonGlobal.hallOfFameLastNumber = 0
        pbMessage(_INTL("Registros del Salón de la Fama borrados."))
      end
    }
  })
  
  DebugMenuCommands.register("showhalloffamestats", {
    "parent"      => "playermenu",
    "name"        => _INTL("Show Hall of Fame Stats"),
    "description" => _INTL("Show statistics about Hall of Fame entries."),
    "effect"      => proc {
      stats = pbGetHallOfFameStats
      message = _INTL("Estadísticas del Hall de la Fama:\n")
      message += _INTL("Entradas totales: {1}\n", stats[:total_entries])
      message += _INTL("Especies únicas: {1}\n", stats[:unique_species])
      message += _INTL("Última entrada: #{stats[:latest_entry_number]}")
      pbMessage(message)
    }
  })
  
  DebugMenuCommands.register("addfakehalloffame", {
    "parent"      => "playermenu",
    "name"        => _INTL("Add Fake Hall of Fame Entry"),
    "description" => _INTL("Add a fake entry for testing."),
    "effect"      => proc {
      if $player.party.empty?
        pbMessage(_INTL("Necesitas Pokémon en el equipo para crear una entrada falsa."))
      else
        fake_entry = []
        $player.party.each { |p| fake_entry.push(p.clone) unless p.egg? }
        $PokemonGlobal.hallOfFame.push(fake_entry)
        $PokemonGlobal.hallOfFameLastNumber += 1
        pbMessage(_INTL("Entrada falsa del Hall de la Fama añadida."))
      end
    }
  })
end

#===============================================================================
# Integración con Battle Frontier (si se usa)
#===============================================================================
def pbEliteFourEnd
  pbHallOfFameEntry
end

def pbChampionBattleEnd
  pbHallOfFameEntry
end

#===============================================================================
# Soporte para música personalizada
#===============================================================================
module HallOfFameBGM
  HALL_BGM = "HallOfFame"  # Cambiar por el nombre de tu archivo BGM
  
  def self.play
    if pbResolveAudioFile("Audio/BGM/#{HALL_BGM}")
      pbBGMPlay(HALL_BGM)
    else
      # Fallback a música por defecto
      pbBGMPlay("victory")
    end
  end
  
  def self.stop
    pbBGMStop
  end
  
  def self.fade(duration = 1.0)
    pbBGMFade(duration)
  end
end

# Los datos del Hall of Fame se guardan automáticamente 
# como parte de $PokemonGlobal - no necesitamos tocar el sistema de guardado

#===============================================================================
# Manejo de errores mejorado
#===============================================================================
def pbHandleHallOfFameError(error)
  error_message = _INTL("Error en el Salón de la Fama: #{error.message}")
  pbMessage(error_message)
  
  if $DEBUG
    puts "=== Hall of Fame Error Debug Info ==="
    puts "Error: #{error.message}"
    puts "Backtrace:"
    error.backtrace.each { |line| puts "  #{line}" }
    puts "======================================"
  end
  
  # Intentar limpiar recursos si es posible
  begin
    HallOfFameResources.clear_cache if defined?(HallOfFameResources)
  rescue
    # Falló la limpieza, pero no importa
  end
end

#===============================================================================
# Eventos automáticos
#===============================================================================

# Limpiar cache al cambiar de mapa
EventHandlers.add(:on_map_change, :hall_of_fame_cache_cleanup,
  proc { |_new_map_id, _new_map|
    HallOfFameResources.clear_cache if defined?(HallOfFameResources)
  }
)

#===============================================================================
# Documentación final integrada
#===============================================================================

=begin

SALÓN DE LA FAMA v2.0 - GUÍA COMPLETA DE USO

INSTALACIÓN:
1. Colocar todos los archivos (001-008) en la carpeta Plugins/
2. Copiar los gráficos a Graphics/Pictures/Hall de la Fama BW/
3. Configurar las constantes en 001_hall_of_fame_main.rb

USO BÁSICO:
- SalonDeFama.registrar (función principal)
- pbHallOfFameEntry (alias amigable)
- pbHallOfFamePC (visor desde PC)

CONFIGURACIÓN:
- HallDeLaFama_GEN: Generación del estilo (1-5)
- HallDeLaFama_REGION: Nombre de tu región
- Otros parámetros específicos por generación

FUNCIONES DISPONIBLES:
- pbGetHallOfFameCount: Número de entradas
- pbPokemonInHallOfFame?(pokemon): Verificar Pokémon
- pbGetHallOfFameStats: Estadísticas completas

COMANDOS DEBUG (modo debug):
- Test Hall of Fame: Probar la secuencia
- Clear Hall of Fame: Borrar registros
- Show Stats: Ver estadísticas
- Add Fake Entry: Añadir entrada de prueba

CRÉDITOS:
- Script original: JessWishes
- Porteo a v21: Assistant
- Basado en Pokémon Essentials v21

=end