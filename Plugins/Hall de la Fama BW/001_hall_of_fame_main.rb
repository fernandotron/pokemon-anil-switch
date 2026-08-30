#===============================================================================
#
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#                     Script : Salón de la Fama 2.0
#                             por JessWishes
#                      Porteado a v21 por Assistant
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#                 Creado para RPG Maker XP con base Essentials
#                        Compatible : versión 21+
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# Muestra diferentes tipos de animaciones del Salón de la Fama
#-------------------------------------------------------------------------------
# DevianArt :
# https://www.deviantart.com/jesswshs
#
# Twitter :
# https://twitter.com/JessWishes
#
# Pagina de Recursos
# https://jessdev.weebly.com
#
# Discord : PixelWooper
# https://discord.gg/eTHrHD9e9a
#
#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#  Esto ha tomado tiempo y esfuerzo en ser diseñado, aunque es de uso libre,
#   se agradece que se den créditos y que no se publique en otros sitios
#   externos como foros, pastebin o sitios de almacenamiento.
#
#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#                     Información de la versión
#
#  Versión 1.0 - Animaciones de Generación 1 hasta Generacion 5.
#
#  Versión 2.0 - Agregar animaciones faltantes e información del equipo.
#                 Porteo completo a v21.
#
#-------------------------------------------------------------------------------
#                             Modo de uso
#
# 1.-Añadir la carpeta de gráficos a Graphics/Pictures
#
# 2.- Para activar e iniciar la escena, se debe usar la siguiente función :
#
#     SalonDeFama.registrar
#
#
# 3.- La escena donde se muestra el registro actual del equipo que ha entrado al
#     salón de la fama, aún no ha sido agregada, pero lo estará para la versión
#     2.0, pero por ahora la información se guardará en la PC con el script
#     de HallOfFame que ya trae Essentials.
#
#
# 4.- Para poder seleccionar el tipo de estilo a usar, se deben modificar las
#     siguientes constantes.
#
#-------------------------------------------------------------------------------
#                            Constantes
#-------------------------------------------------------------------------------

# Estilo de la animación según la generación (1-5)
HallDeLaFama_GEN = 5

# Nombre de la Región en la que se realiza la Liga
# Para no mostrarla, colocar "" en su lugar
HallDeLaFama_REGION = "KANTO" # ""

# Color de fondo para Gen1
HallDeLaFama_COLOR = [255,255,255] # Blanco

# Color del fondo para Gen3
# 1 => Azul/Rosa según genero del jugador
# 2 => Verde de Esmeralda
# 3 => Azul de FR/LG
HallDeLaFama_EMER = 1

# Seleccionar entre DPP o HGSS para Gen4
# 1 => DPP
# 2 => HGSS
HallDeLaFama_ST4 = 1

# Colores según los tipos elementales para Gen 5 - CORREGIDOS
# Orden v21: NORMAL, FIGHTING, FLYING, POISON, GROUND, ROCK, BUG, GHOST, STEEL, FIRE, WATER, GRASS, ELECTRIC, PSYCHIC, ICE, DRAGON, DARK, FAIRY
HallDeLaFama_BW_COLOR = [ 
  Tone.new(  20,  20,  20), # 0  - NORMAL
  Tone.new( 100, -10,-100), # 1  - FIGHTING
  Tone.new( -50,  30, 100), # 2  - FLYING
  Tone.new(  80, -20,  80), # 3  - POISON
  Tone.new(  90,  20, -30), # 4  - GROUND
  Tone.new(  60,  30, -10), # 5  - ROCK
  Tone.new(  10,  90, -10), # 6  - BUG
  Tone.new(  50,  10, 100), # 7  - GHOST
  Tone.new(  30,  30,  50), # 8  - STEEL
  Tone.new( 120, -10, -40), # 9  - FIRE
  Tone.new( -30,  50, 120), # 10 - WATER
  Tone.new( -20, 100,  20), # 11 - GRASS
  Tone.new( 110,  60, -20), # 12 - ELECTRIC
  Tone.new(  90,   0,  60), # 13 - PSYCHIC
  Tone.new( -20,  80, 100), # 14 - ICE
  Tone.new(  20,  40, 110), # 15 - DRAGON
  Tone.new(  40,  40,  60), # 16 - DARK
  Tone.new( 110,  30,  90)  # 17 - FAIRY
]

#-------------------------------------------------------------------------------
#                         Extensiones de Clases
#-------------------------------------------------------------------------------

class Game_Player
  attr_accessor :HallDeLaFamaActivar
end

#===============================================================================
# Función de guardado compatible
#===============================================================================
def Kernel.guardar
  if defined?(Game) && Game.respond_to?(:save)
    return Game.save
  else
    return pbSave
  end
end

#===============================================================================
# PokemonGlobalMetadata extension
#===============================================================================
class PokemonGlobalMetadata
  attr_writer :hallOfFame, :hallOfFameLastNumber

  def hallOfFame
    @hallOfFame = [] if !@hallOfFame
    return @hallOfFame
  end

  def hallOfFameLastNumber
    return @hallOfFameLastNumber || 0
  end
  
  # Asegurar inicialización en save files existentes
  alias_method :hall_original_initialize, :initialize #if method_defined?(:initialize)
  
  def initialize
    hall_original_initialize #if respond_to?(:hall_original_initialize)
    @hallOfFame = [] if !@hallOfFame
    @hallOfFameLastNumber = 0 if !@hallOfFameLastNumber
  end
end

#===============================================================================
# Módulo Principal del Salón de la Fama
#===============================================================================
module SalonDeFama
  
  def self.registrar
    begin
      return if !$scene || $player.party.size == 0
      
      # Verificar que hay Pokémon no huevos
      non_egg_count = $player.party.count { |p| !p.egg? }
      return if non_egg_count == 0
      
      r = Kernel.guardar
      return if !r
      
      $game_player.HallDeLaFamaActivar = true if $game_player
      
      # Crear instancia con manejo de errores
      hall_instance = HallDeLaFama.new
      
      pbWait(1)
      pt_f = []
      for i in 0...$player.party.size
        next if $player.party[i].egg?
        pt_f.push($player.party[i].clone)
      end
      
      $PokemonGlobal.hallOfFame.push(pt_f)
      $PokemonGlobal.hallOfFameLastNumber += 1
      
      # Store time of first Hall of Fame in $player.halloffame if not array is empty
      totalsec = Graphics.frame_count / Graphics.frame_rate
      hour = totalsec / 60 / 60
      min = totalsec / 60 % 60
      if !$player.halloffame || $player.halloffame.empty?
        $player.halloffame ||= []
        $player.halloffame.push(pbGetTimeNow)
        $player.halloffame.push(totalsec)
      end
      
    rescue => e
      pbMessage(_INTL("Error en el Salón de la Fama: #{e.message}"))
      if $DEBUG
        p "Hall of Fame Error: #{e.message}"
        p e.backtrace
      end
    end
  end
  
end

#===============================================================================
# Gestión mejorada de recursos para el Salón de la Fama
#===============================================================================
module HallOfFameResources
  GRAPHICS_PATH = "Graphics/UI/Hall de la Fama BW/"
  
  # Cache de bitmaps para optimizar rendimiento
  @@bitmap_cache = {}
  
  # Obtener bitmap con fallback automático
  def self.get_bitmap(filename, fallback_color = nil)
    cache_key = "#{GRAPHICS_PATH}#{filename}"
    
    # Verificar cache primero
    return @@bitmap_cache[cache_key] if @@bitmap_cache[cache_key] && !@@bitmap_cache[cache_key].disposed?
    
    begin
      @@bitmap_cache[cache_key] = Bitmap.new(cache_key)
    rescue
      # Crear bitmap de fallback
      @@bitmap_cache[cache_key] = create_fallback_bitmap(filename, fallback_color)
    end
    
    return @@bitmap_cache[cache_key]
  end
  
  # Crear bitmap de fallback basado en el tipo de archivo
  def self.create_fallback_bitmap(filename, color = nil)
    case filename
    when /bg/
      bitmap = Bitmap.new(Graphics.width, Graphics.height)
      color ||= Color.new(50, 70, 120)
      bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, color)
      
    when /bar/
      bitmap = Bitmap.new(Graphics.width, 64)
      color ||= Color.new(100, 100, 150)
      bitmap.fill_rect(0, 0, Graphics.width, 64, color)
      
    when /ball/
      bitmap = Bitmap.new(64, 64)
      color ||= Color.new(200, 50, 50)
      # Dibujar círculo simple
      (0...64).each do |x|
        (0...64).each do |y|
          distance = Math.sqrt((x-32)**2 + (y-32)**2)
          if distance <= 30
            bitmap.set_pixel(x, y, color)
          end
        end
      end
      
    when /star/
      bitmap = Bitmap.new(32, 32)
      color ||= Color.new(255, 255, 100)
      # Dibujar estrella simple
      bitmap.fill_rect(14, 6, 4, 20, color)
      bitmap.fill_rect(6, 14, 20, 4, color)
      bitmap.fill_rect(10, 10, 12, 12, color)
      
    else
      bitmap = Bitmap.new(64, 64)
      color ||= Color.new(128, 128, 128)
      bitmap.fill_rect(0, 0, 64, 64, color)
    end
    
    return bitmap
  end
  
  # Obtener sprite de entrenador con fallback mejorado
  def self.get_trainer_sprite(back = false)
    begin
      if back
        return GameData::TrainerType.player_back_sprite_filename($player.trainer_type)
      else
        return GameData::TrainerType.player_front_sprite_filename($player.trainer_type)
      end
    rescue
      # Fallback genérico
      return back ? "Graphics/Trainers/trback000.png" : "Graphics/Trainers/trainer000.png"
    end
  end
  
  # Limpiar cache
  def self.clear_cache
    @@bitmap_cache.each_value { |bitmap| bitmap.dispose if bitmap && !bitmap.disposed? }
    @@bitmap_cache.clear
  end
  
  # Precargar recursos comunes
  def self.preload_common_resources
    common_files = [
      "hallfamebg", "hallfamebg_2", "hallfameHGSSbg",
      "hallfameBWbars", "hallfameBWball", "hallfameBWstars"
    ]
    
    common_files.each { |file| get_bitmap(file) }
  end
end

#===============================================================================
# Gestión mejorada de tipos de Pokémon para Gen 5 - CORREGIDA
#===============================================================================
module HallOfFameTypes
  # Mapeo correcto de tipos según v21
  TYPE_ORDER_V21 = [
    :NORMAL,    # 0
    :FIGHTING,  # 1
    :FLYING,    # 2
    :POISON,    # 3
    :GROUND,    # 4
    :ROCK,      # 5
    :BUG,       # 6
    :GHOST,     # 7
    :STEEL,     # 8
    :FIRE,      # 9
    :WATER,     # 10
    :GRASS,     # 11
    :ELECTRIC,  # 12
    :PSYCHIC,   # 13
    :ICE,       # 14
    :DRAGON,    # 15
    :DARK,      # 16
    :FAIRY      # 17
  ]
  
  # Obtener índice correcto del tipo
  def self.get_type_index(type_symbol)
    return 0 if !type_symbol
    
    # Buscar en el orden definido
    index = TYPE_ORDER_V21.index(type_symbol)
    return index if index
    
    # Fallback con GameData
    begin
      type_data = GameData::Type.try_get(type_symbol)
      if type_data && type_data.respond_to?(:id_number)
        potential_index = type_data.id_number
        return potential_index if potential_index >= 0 && potential_index < HallDeLaFama_BW_COLOR.length
      end
    rescue
      # Ignorar errores
    end
    
    return 0  # Normal por defecto
  end
  
  # Mapeo seguro de tipos a colores
  def self.get_type_color(pokemon)
    return Tone.new(20, 20, 20) if !pokemon || !pokemon.types || pokemon.types.empty?
    
    primary_type = pokemon.types[0]
    type_index = get_type_index(primary_type)
    
    # Verificar que el índice esté en rango
    if type_index >= 0 && type_index < HallDeLaFama_BW_COLOR.length
      return HallDeLaFama_BW_COLOR[type_index]
    else
      return HallDeLaFama_BW_COLOR[0]  # Normal por defecto
    end
  end
  
  # Obtener nombres de tipos de manera segura
  def self.get_type_names(pokemon)
    return ["Normal", nil] if !pokemon || !pokemon.types || pokemon.types.empty?
    
    types = pokemon.types
    type1_data = GameData::Type.try_get(types[0])
    type1_name = type1_data ? type1_data.name : "Normal"
    
    type2_name = nil
    if types.length > 1 && types[0] != types[1]
      type2_data = GameData::Type.try_get(types[1])
      type2_name = type2_data ? type2_data.name : nil
    end
    
    return [type1_name, type2_name]
  end
end

#===============================================================================
# Validación de constantes para evitar errores
#===============================================================================

# Verificar que las constantes estén definidas
if !defined?(HallDeLaFama_GEN)
  HallDeLaFama_GEN = 1
end

if !defined?(HallDeLaFama_REGION)
  HallDeLaFama_REGION = "REGIÓN"
end

if !defined?(HallDeLaFama_BW_COLOR) || HallDeLaFama_BW_COLOR.empty?
  HallDeLaFama_BW_COLOR = [Tone.new(18, 18, 18)] * 18  # Array con 18 elementos iguales
end

#===============================================================================
# Auto-cleanup cuando se cambia de mapa
#===============================================================================
EventHandlers.add(:on_map_change, :hall_of_fame_cleanup,
  proc { |_new_map_id, _new_map|
    HallOfFameResources.clear_cache
  }
)

#===============================================================================
# Plugin registration para v21
#===============================================================================
PluginManager.register({
  :name    => "Salón de la Fama",
  :version => "2.0",
  :link    => "https://www.deviantart.com/jesswshs",
  :credits => ["JessWishes", "Assistant (v21 Port)"]
})

#===============================================================================
# Funciones de compatibilidad adicionales
#===============================================================================

# Función para obtener nombre de mapa (v21 compatible)
def pbGetMapNameFromId(map_id)
  return "Un lugar lejano" if !map_id || map_id == 0
  
  begin
    map_infos = pbLoadMapInfos
    return "Un lugar lejano" if !map_infos || !map_infos[map_id]
    return map_infos[map_id].name || "Un lugar lejano"
  rescue
    return "Un lugar lejano"
  end
end

#===============================================================================
# Función principal de acceso
#===============================================================================

# Use this in an event to trigger the Hall of Fame
def pbHallOfFameEntry
  SalonDeFama.registrar
end

# Use this to check if player has entered Hall of Fame
def pbHallOfFameCount
  return $PokemonGlobal.hallOfFameLastNumber
end

# Check if a specific Pokemon has been in the Hall of Fame
def pbPokemonInHallOfFame?(pokemon)
  $PokemonGlobal.hallOfFame.each do |entry|
    entry.each do |hall_pokemon|
      return true if hall_pokemon.species == pokemon.species && 
                     hall_pokemon.personalID == pokemon.personalID
    end
  end
  return false
end