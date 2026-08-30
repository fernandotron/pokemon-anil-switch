#===============================================================================
#
#-------------------------------------------------------------------------------
#                     Clase Principal del Salón de la Fama
#                             por JessWishes
#                      Porteado a v21 por Assistant
#-------------------------------------------------------------------------------
#
# Este archivo contiene la clase base HallDeLaFama con métodos comunes
# y la lógica principal del sistema
#
#===============================================================================

#===============================================================================
# Clase principal del Salón de la Fama
#===============================================================================
class HallDeLaFama
  attr_reader :vista, :s, :vistos, :obtenidos
  
  def initialize
    @s = {}
    @vista = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @vista.z = 99999
    @vistos = $player.pokedex.seen_count
    @obtenidos = $player.pokedex.owned_count
    
    # Viewports adicionales para animaciones complejas
    @bg_v = nil
    @bg_w = nil
    
    # Determinar qué generación ejecutar
    case HallDeLaFama_GEN
    when 1; jsGen1(1)
    when 2; jsGen1(2)
    when 3; jsGen3
    when 4; (HallDeLaFama_ST4 == 1) ? jsGen4_DPP : jsGen4_HGSS
    when 5; jsGen5
    when 6; jsGen6
    when 7; jsGen7
    else
      pbMessage(_INTL("Error: Generación #{HallDeLaFama_GEN} no soportada. Usando Generación 1."))
      jsGen1(1)
    end
  end
  
  #=============================================================================
  # Métodos principales de la clase
  #=============================================================================
  
  def dispose
    # Dispose de viewports adicionales
    [@bg_v, @bg_w].each { |v| v.dispose if v && !v.disposed? }
    
    # Dispose de todos los sprites
    pbDisposeSpriteHash(@s) if @s
    
    # Dispose del viewport principal
    @vista.dispose if @vista && !@vista.disposed?
  end
  
  def fade(fade_in = true)
    return if !@vista || @vista.disposed?
    
    if fade_in
      13.times do |fd|  # Reducido de 26 a 13
        @vista.tone = Tone.new(20 * fd, 20 * fd, 20 * fd)  # Aumentado de 10 a 20
        Graphics.update
        Input.update
      end
    else
      @vista.tone = Tone.new(0, 0, 0)
    end
  end
  
  def dex_info
    case @obtenidos
    when 0...30
      pbMessage(_INTL("Mmm, parece que aún te faltan lugares por explorar.\nRecuerda que los Pokémon se encuentran en diversos lugares."))
    when 30...75
      pbMessage(_INTL("Mmm, veo que has capturado una cantidad decente."))
    when 75...150
      pbMessage(_INTL("No olvides que los pokémon necesitan ser cuidados de manera apropiada."))
    else
      pbMessage(_INTL("¡Increíble!\n¡No tenía idea que existieran tantas especies distintas!"))
    end
  end
  
  #=============================================================================
  # Métodos para crear sprites de Pokémon
  #=============================================================================
  
  def pokes_info
    party_index = 0
    
    $player.party.each_with_index do |pokemon, i|
      next if pokemon.egg?
      
      # Sprite frontal
      @s["poke#{party_index}"] = PokemonSprite.new(@vista)
      @s["poke#{party_index}"].setPokemonBitmap(pokemon)
      @s["poke#{party_index}"].x = -@s["poke#{party_index}"].bitmap.width
      @s["poke#{party_index}"].y = 180
      @s["poke#{party_index}"].ox = @s["poke#{party_index}"].bitmap.width / 2
      @s["poke#{party_index}"].oy = @s["poke#{party_index}"].bitmap.height / 2
      
      # Sprite trasero
      @s["poke#{party_index}_2"] = PokemonSprite.new(@vista)
      @s["poke#{party_index}_2"].setPokemonBitmap(pokemon, true)
      @s["poke#{party_index}_2"].x = Graphics.width + 100
      @s["poke#{party_index}_2"].y = (Graphics.height - @s["poke#{party_index}_2"].bitmap.height) + 79
      @s["poke#{party_index}_2"].ox = @s["poke#{party_index}_2"].bitmap.width / 2
      @s["poke#{party_index}_2"].oy = @s["poke#{party_index}_2"].bitmap.height / 2
      
      party_index += 1
    end
  end
  
  #=============================================================================
  # Métodos para crear sprites de entrenador
  #=============================================================================
  
  def create_trainer_sprite(back = false)
    sprite = Sprite.new(@vista)
    
    begin
      if back
        filename = GameData::TrainerType.back_sprite_filename($player.trainer_type)
      else
        filename = GameData::TrainerType.front_sprite_filename($player.trainer_type)
      end
      sprite.bitmap = Bitmap.new(filename)
    rescue => e
      # Crear sprite de fallback
      sprite.bitmap = Bitmap.new(64, 64)
      color = back ? Color.new(150, 100, 100) : Color.new(100, 100, 200)
      sprite.bitmap.fill_rect(0, 0, 64, 64, color)
      
      # Dibujar forma simple de entrenador
      if back
        sprite.bitmap.fill_rect(20, 10, 24, 40, Color.new(200, 150, 150))
      else
        sprite.bitmap.fill_rect(16, 8, 32, 48, Color.new(150, 150, 250))
      end
      
      puts "Advertencia: No se pudo cargar sprite de entrenador: #{e.message}" if $DEBUG
    end
    
    return sprite
  end
  
  #=============================================================================
  # Métodos de utilidad para información de Pokémon
  #=============================================================================
  
  def get_pokemon_type_info(pokemon)
    return HallOfFameTypes.get_type_names(pokemon)
  end
  
  def get_pokemon_type_color(pokemon)
    return HallOfFameTypes.get_type_color(pokemon)
  end
  
  def get_play_time_formatted
    totalsec = $stats.play_time.to_i
    hour = totalsec / 3600
    min = (totalsec % 3600) / 60
    return sprintf("%02d:%02d", hour, min)
  end
  
  def get_pokemon_gender_symbol(pokemon)
    return "♂" if pokemon.male?
    return "♀" if pokemon.female?
    return ""
  end
  
  def get_non_egg_pokemon
    party_pokemon = []
    $player.party.each { |p| party_pokemon.push(p) unless p.egg? }
    return party_pokemon
  end
  
  #=============================================================================
  # Métodos para crear ventanas de texto
  #=============================================================================
  
  def create_text_window(text, x, y, width, height, visible = false)
    window = HallOfFameTextWindow.new(text, x, y, width, height, @vista)
    window.visible = visible
    return window
  end
  
  def create_title_window(title_text, y_position = nil)
    y_pos = y_position || Graphics.height - 65
    window = create_text_window(
      _INTL("<ac>#{title_text}</ac>"),
      40, y_pos, Graphics.width - 80, 64
    )
    return window
  end
  
  def create_info_window(text, x, y, width, height)
    return create_text_window(_INTL(text), x, y, width, height)
  end
  
  #=============================================================================
  # Métodos para efectos visuales
  #=============================================================================
  
  def flash_viewport(color = Color.new(255, 255, 255), duration = 20)
    return if !@vista || @vista.disposed?
    @vista.flash(color, duration)
  end
  
  def shake_sprite(sprite, intensity = 5, duration = 10)
    return if !sprite || sprite.disposed?
    
    original_x = sprite.x
    duration.times do
      sprite.x = original_x + rand(intensity * 2) - intensity
      Graphics.update
      Input.update
    end
    sprite.x = original_x
  end
  
  def animate_sprite_entrance(sprite, direction = :from_left, duration = 30)
    return if !sprite || sprite.disposed?
    
    case direction
    when :from_left
      start_x = -sprite.bitmap.width
      end_x = sprite.x
      sprite.x = start_x
      
      duration.times do |i|
        sprite.x = start_x + (end_x - start_x) * i / duration
        Graphics.update
        Input.update
      end
      sprite.x = end_x
      
    when :from_right
      start_x = Graphics.width + sprite.bitmap.width
      end_x = sprite.x
      sprite.x = start_x
      
      duration.times do |i|
        sprite.x = start_x - (start_x - end_x) * i / duration
        Graphics.update
        Input.update
      end
      sprite.x = end_x
      
    when :from_top
      start_y = -sprite.bitmap.height
      end_y = sprite.y
      sprite.y = start_y
      
      duration.times do |i|
        sprite.y = start_y + (end_y - start_y) * i / duration
        Graphics.update
        Input.update
      end
      sprite.y = end_y
      
    when :from_bottom
      start_y = Graphics.height + sprite.bitmap.height
      end_y = sprite.y
      sprite.y = start_y
      
      duration.times do |i|
        sprite.y = start_y - (start_y - end_y) * i / duration
        Graphics.update
        Input.update
      end
      sprite.y = end_y
    end
  end
  
  #=============================================================================
  # Métodos de limpieza y validación
  #=============================================================================
  
  def safe_dispose_sprite(sprite_name)
    return if !@s || !@s[sprite_name]
    sprite = @s[sprite_name]
    sprite.dispose if sprite && !sprite.disposed?
    @s.delete(sprite_name)
  end
  
  def safe_set_sprite_property(sprite_name, property, value)
    return if !@s || !@s[sprite_name]
    sprite = @s[sprite_name]
    return if !sprite || sprite.disposed?
    
    case property
    when :visible
      sprite.visible = value
    when :opacity
      sprite.opacity = value
    when :x
      sprite.x = value
    when :y
      sprite.y = value
    when :z
      sprite.z = value
    when :color
      sprite.color = value
    when :tone
      sprite.tone = value
    end
  end
  
  def validate_pokemon_data(pokemon)
    return false if !pokemon
    return false if pokemon.egg?
    return false if !pokemon.species
    return true
  end
  
  #=============================================================================
  # Métodos placeholder para las generaciones (serán sobrescritos)
  #=============================================================================
  
  def jsGen1(generation)
    pbMessage(_INTL("Generación 1-2 no implementada en el core. Cargar archivo 004."))
  end
  
  def jsGen3
    pbMessage(_INTL("Generación 3 no implementada en el core. Cargar archivo 005."))
  end
  
  def jsGen4_DPP
    pbMessage(_INTL("Generación 4 DPP no implementada en el core. Cargar archivo 006."))
  end
  
  def jsGen4_HGSS
    pbMessage(_INTL("Generación 4 HGSS no implementada en el core. Cargar archivo 006."))
  end
  
  def jsGen5
    pbMessage(_INTL("Generación 5 no implementada en el core. Cargar archivo 007."))
  end
  
  def jsGen6
    pbMessage(_INTL("Animación de Generación 6 no implementada aún.\nUsando Generación 1..."))
    jsGen1(1)
  end
  
  def jsGen7
    pbMessage(_INTL("Animación de Generación 7 no implementada aún.\nUsando Generación 1..."))
    jsGen1(1)
  end
  
  #=============================================================================
  # Métodos de debug y testing
  #=============================================================================
  
  def debug_sprite_info(sprite_name)
    return if !$DEBUG || !@s || !@s[sprite_name]
    
    sprite = @s[sprite_name]
    puts "=== Debug Info for #{sprite_name} ==="
    puts "Disposed: #{sprite.disposed?}"
    puts "Visible: #{sprite.visible}"
    puts "Position: (#{sprite.x}, #{sprite.y})"
    puts "Size: #{sprite.bitmap ? "#{sprite.bitmap.width}x#{sprite.bitmap.height}" : "No bitmap"}"
    puts "Opacity: #{sprite.opacity}"
    puts "Z: #{sprite.z}"
  end
  
  def debug_all_sprites
    return if !$DEBUG || !@s
    
    puts "=== All Sprites Debug Info ==="
    @s.each_key do |key|
      debug_sprite_info(key)
    end
  end
  
  def force_cleanup
    puts "Forzando limpieza de recursos..." if $DEBUG
    
    # Dispose todos los sprites
    @s.each_value { |sprite| sprite.dispose if sprite && !sprite.disposed? } if @s
    @s.clear if @s
    
    # Dispose viewports
    [@vista, @bg_v, @bg_w].each { |v| v.dispose if v && !v.disposed? }
    
    # Limpiar cache de recursos
    HallOfFameResources.clear_cache
    
    puts "Limpieza completada." if $DEBUG
  end
end

#===============================================================================
# Extensiones para mejor compatibilidad
#===============================================================================
class HallDeLaFama
  # Aliases para métodos con nombres en inglés (por compatibilidad)
  alias_method :hall_dispose, :dispose
  alias_method :hall_fade, :fade
  alias_method :pokemon_info, :pokes_info
end
