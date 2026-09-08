# ==============================================================================
# Nintendo Switch (Horizon OS) & Modern Ruby Compatibility Shims for mkxp-z
# ==============================================================================

# Guard against duplicate preload execution (mkxp-z C++ patch + mkxp.json preloadScript)
# Primer instante en que el reloj de Ruby y el del motor quedan en la MISMA escala: System.puts
# esta enlazado a Debug(), que estampa SDL_GetTicks. El salto respecto a la linea
# "[Ruby] Cargando automaticamente preload.rb..." es el coste de compilar este fichero a ISeq.
System.puts("[preload] compilado; empieza ejecucion") rescue nil
$PRELOAD_RB_LOADED ||= false
if $PRELOAD_RB_LOADED
  log_compat("[Switch Compatibility] preload.rb ya fue evaluado anteriormente.") rescue nil
end
$PRELOAD_RB_LOADED = true

# Reloj del arranque de Ruby. Se fija lo mas arriba posible para que el instante del primer
# pixel se pueda medir de verdad en vez de estimarlo. El tiempo ABSOLUTO desde que arranco el
# homebrew lo da mkxp.log, que cuenta desde SDL_Init; este cuenta desde que Ruby toma el control.
$SWITCH_BOOT_T0 ||= (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f)

# 0. Renderizado instantáneo en el fotograma 0 (Feedback visual inmediato a < 15ms)
module Graphics
  class << self
    def width; 512; end unless method_defined?(:width)
    def height; 384; end unless method_defined?(:height)
  end
end

$switch_boot_viewport = nil
$switch_boot_bg = nil
$switch_boot_logo = nil
$switch_boot_bar = nil

$switch_boot_pct = 0

def update_boot_progress(pct, text = "")
  return unless defined?($switch_boot_bar) && $switch_boot_bar && $switch_boot_bar.bitmap && !$switch_boot_bar.bitmap.disposed?
  # Clamp monotono. La barra la alimentan CUATRO emisores con bandas propias: preload.rb, las
  # lineas que patch_scripts.js inyecta en las secciones, el bloque Main, y ademas
  # 006_PluginManager.rb y 002_GameData.rb, que calculan su porcentaje con constantes escritas a
  # mano. Basta con que uno de ellos se quede desincronizado para que la barra retroceda a la
  # vista del jugador. Aqui se ignora cualquier valor menor que el ultimo pintado, de modo que la
  # barra nunca puede ir hacia atras aunque algun emisor futuro se olvide de actualizar su banda.
  # El TEXTO si se actualiza siempre: la fase que se esta ejecutando se sigue viendo.
  pct = pct.to_i
  pct = $switch_boot_pct if pct < $switch_boot_pct
  pct = 100 if pct > 100
  $switch_boot_pct = pct
  # Contador incremental a proposito: reparte todo el tramo 2%->100% sobre el reloj del motor.
  # No se usa log_compat aqui porque descarta mensajes cuyos primeros 120 caracteres se repiten
  # (preload.rb, dedup_key) y la marca de ms se anade DESPUES, fuera de esa clave: dos repintados
  # con el mismo pct y texto se colapsarian en uno y el hueco medido saldria falsamente largo.
  $switch_boot_tick = ($switch_boot_tick || 0) + 1
  System.puts("[barra ##{$switch_boot_tick}] #{pct}% #{text}") rescue nil
  begin
    bm = $switch_boot_bar.bitmap
    bm.clear
    bar_w = 340
    bar_h = 10
    bar_x = (512 - bar_w) / 2
    bar_y = 318
    # Borde y fondo oscuro de la barra
    bm.fill_rect(bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4, Color.new(20, 30, 50, 200))
    bm.fill_rect(bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2, Color.new(70, 110, 180, 240))
    bm.fill_rect(bar_x, bar_y, bar_w, bar_h, Color.new(15, 20, 32, 255))
    # Relleno del progreso (azul Añil con brillo)
    fill_w = [([pct.to_i, 0].max * bar_w) / 100, bar_w].min
    if fill_w > 0
      bm.fill_rect(bar_x, bar_y, fill_w, bar_h, Color.new(45, 130, 245, 255))
      bm.fill_rect(bar_x, bar_y, fill_w, 2, Color.new(120, 180, 255, 255))
    end
    # Texto de estado
    if bm.font
      bm.font.size = 17 rescue nil
      bm.font.bold = true rescue nil
      bm.font.color = Color.new(235, 242, 255, 255) rescue nil
    end
    bm.draw_text(0, 334, 512, 22, text.to_s, 1) rescue nil
    if bm.font
      bm.font.size = 14 rescue nil
      bm.font.bold = false rescue nil
      bm.font.color = Color.new(160, 185, 225, 255) rescue nil
    end
    bm.draw_text(0, 356, 512, 18, "#{pct}%", 1) rescue nil
    Graphics.update rescue nil
  rescue Exception => e
    log_compat("[BootProgress Error] #{e.message}") rescue nil
  end
end

# Descarta la pantalla de arranque. Una sola implementacion: antes estaba duplicada en dos
# bloques de patch_scripts.js y el segundo era codigo muerto (las globales ya eran nil).
# Es idempotente: llamarla dos veces no hace nada la segunda.
# IMPORTANTE: no la llames antes de tener algo compuesto que la sustituya, o la pantalla se
# queda en negro. La escena de titulo la invoca cuando ya ha construido sus bitmaps.
def switch_dispose_sprite!(spr)
  return nil if !spr
  begin
    bm = spr.bitmap
    bm.dispose if bm && !bm.disposed?
  rescue Exception
  end
  begin
    spr.dispose
  rescue Exception
  end
  nil
end

def pbDisposeBootOverlay(fade_frames = 0)
  begin
    # Graphics.transition solo hace algo si antes hubo un Graphics.freeze
    # (mkxp-z/src/display/graphics.cpp: "if (!p->frozen) return;"). Sin este freeze el
    # corte hacia la escena siguiente seria a negro seco en vez de un fundido.
    Graphics.freeze if fade_frames > 0
  rescue Exception
  end
  $switch_boot_bg = switch_dispose_sprite!($switch_boot_bg) if defined?($switch_boot_bg)
  $switch_boot_logo = switch_dispose_sprite!($switch_boot_logo) if defined?($switch_boot_logo)
  $switch_boot_bar = switch_dispose_sprite!($switch_boot_bar) if defined?($switch_boot_bar)
  $loading_sprite = switch_dispose_sprite!($loading_sprite) if defined?($loading_sprite)
  if defined?($switch_boot_viewport) && $switch_boot_viewport
    begin
      $switch_boot_viewport.dispose
    rescue Exception
    end
    $switch_boot_viewport = nil
  end
  if defined?($loading_viewport) && $loading_viewport
    begin
      $loading_viewport.dispose
    rescue Exception
    end
    $loading_viewport = nil
  end
  begin
    Graphics.transition(fade_frames) if fade_frames > 0
  rescue Exception
  end
  nil
end

begin
  if defined?(Graphics) && Graphics.respond_to?(:update)
    vw = (Graphics.width rescue 512) || 512
    vh = (Graphics.height rescue 384) || 384
    $switch_boot_viewport = Viewport.new(0, 0, vw, vh) rescue nil
    if $switch_boot_viewport
      $switch_boot_viewport.z = 999999

      # 1. Fondo principal del juego (title.png o splash2.png o fondo azul oscuro)
      bg_file = ["Graphics/Titles/title.png", "Graphics/Titles/title", "Graphics/Titles/splash2.png", "Graphics/Titles/splash2"].find do |p|
        File.exist?(p) || File.exist?("./#{p}") rescue false
      end
      $switch_boot_bg = Sprite.new($switch_boot_viewport) rescue nil
      if $switch_boot_bg
        $switch_boot_bg.bitmap = Bitmap.new(bg_file) if bg_file rescue nil
        if $switch_boot_bg.bitmap.nil?
          $switch_boot_bg.bitmap = Bitmap.new(vw, vh) rescue nil
          $switch_boot_bg.bitmap.fill_rect(0, 0, vw, vh, Color.new(14, 22, 40)) rescue nil
        end
      end

      # 2. Logotipo Pokémon Añil 4.0 centrado
      logo_file = ["Graphics/Titles/logo1.png", "Graphics/Titles/logo1"].find do |p|
        File.exist?(p) || File.exist?("./#{p}") rescue false
      end
      $switch_boot_logo = Sprite.new($switch_boot_viewport) rescue nil
      if $switch_boot_logo && logo_file
        $switch_boot_logo.bitmap = Bitmap.new(logo_file) rescue nil
        if $switch_boot_logo.bitmap
          lw = $switch_boot_logo.bitmap.width
          lh = $switch_boot_logo.bitmap.height
          $switch_boot_logo.x = (vw - lw) / 2
          $switch_boot_logo.y = 18
        end
      end

      # 3. Sprite para la barra de carga y texto dinámico
      $switch_boot_bar = Sprite.new($switch_boot_viewport) rescue nil
      if $switch_boot_bar
        $switch_boot_bar.bitmap = Bitmap.new(vw, vh) rescue nil
        $switch_boot_bar.z = $switch_boot_viewport.z + 10
      end

      # 4. Renderizado inmediato del primer fotograma en pantalla
      update_boot_progress(2, "Iniciando Pokémon Añil...")
      Graphics.transition(0) rescue nil
      6.times { Graphics.update rescue nil }
      Graphics.frame_reset rescue nil
      # PRIMER PIXEL. Es el instante que hay que medir: hasta aqui la pantalla lleva negra
      # desde que arranco el homebrew, y todo lo anterior es coste de C++ (SDL/GL, path cache,
      # fuentes, VM de Ruby, lectura de Scripts.rxdata).
      # Es relativo a $SWITCH_BOOT_T0 (arriba del fichero). El absoluto desde que arranco el
      # homebrew lo da mkxp.log del motor, que cuenta desde SDL_Init.
      $SWITCH_FIRST_PIXEL_MS = (((Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f) - $SWITCH_BOOT_T0) * 1000.0).to_i rescue nil
      # EL NUMERO DECISIVO. En la escala absoluta de SDL_GetTicks, que es la unica comparable
      # con el cronometro. Si sale muy por debajo de los 34 s medidos, el tiempo se va ANTES
      # de SDL_Init (carga del NRO por hbloader) y no dentro del arranque trazado.
      System.puts("[preload] PRIMER PIXEL") rescue nil
    end
  end
rescue Exception => e_boot
  log_compat("[Switch Boot Error] #{e_boot.message}") rescue nil
end


# 1.0 Inicialización del Logging Eficiente
# Se abre en "w", no en "a": en FAT/exFAT abrir en modo append obliga a recorrer la cadena de
# clusters hasta el final, y un log que crece entre arranques encarece cada escritura. Ademas
# interesa el log de ESTE arranque, no el historico acumulado.
$mkxp_log_file ||= (File.open("mkxp_ruby.log", "w") rescue nil)

# Reloj del arranque. Todas las lineas de log llevan los ms transcurridos desde aqui, para poder
# leer el arranque como una linea temporal en vez de como una lista de mensajes.
$SWITCH_BOOT_T0 ||= (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f)

def switch_boot_ms
  t = (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f)
  ((t - $SWITCH_BOOT_T0) * 1000.0).to_i
rescue Exception
  0
end

$LOG_COMPAT_DEDUP ||= {}
$LOG_COMPAT_COUNT ||= 0
$LOG_COMPAT_MAX_LINES ||= 5000
$SWITCH_STRICT_EVENTS ||= false

def write_crash_report(e, context = "Global")
  return if e.nil? || (defined?(SystemExit) && e.is_a?(SystemExit))
  bt = (e.backtrace || []).take(15).join("\n  ")
  report = "CRASH REPORT [#{Time.now rescue ''}] - Contexto: #{context}\nExcepcion: #{e.class}: #{e.message}\nBacktrace:\n  #{bt}\n"
  log_compat("[CRASH REPORT - #{context}] #{e.class}: #{e.message}\n  #{bt}") rescue nil
  begin
    File.open("crash_report.txt", "w") do |f|
      f.puts(report)
      f.flush rescue nil
    end
  rescue Exception
  end
end

def log_compat(msg)
  return if $LOG_COMPAT_COUNT >= $LOG_COMPAT_MAX_LINES
  msg_str = msg.to_s
  dedup_key = msg_str[0, 120]
  return if $LOG_COMPAT_DEDUP[dedup_key]
  $LOG_COMPAT_DEDUP[dedup_key] = true

  lines = msg_str.split("\n")
  if lines.length > 20
    lines = lines.take(20) + ["  ... [traza truncada en log]"]
  end
  $LOG_COMPAT_COUNT += lines.length

  puts msg_str rescue nil if $SWITCH_VERBOSE
  if $mkxp_log_file
    # Marca de tiempo en ms desde que empezo preload.rb. Convierte este log en una linea
    # temporal del arranque: sin esto solo se sabe QUE paso, no CUANDO ni cuanto costo, y
    # el arranque se ha estado diagnosticando a base de estimaciones en vez de medidas.
    ms = switch_boot_ms
    lines.each { |l| $mkxp_log_file.puts(sprintf("[%8d ms] %s", ms, l)) rescue nil }
    $mkxp_log_file.flush rescue nil
  end
rescue
  nil
end

def switch_define_unless(mod, sym, singleton = false)
  target = singleton ? mod.singleton_class : mod
  return if target.method_defined?(sym) || target.private_method_defined?(sym)
  yield
end

log_compat("=================================================================")
log_compat("[Switch Compatibility] *** PRELOAD BUILD 2026-PERFECT-60FPS-STABLE ***")
log_compat("[Switch Compatibility] Iniciando preload.rb en Nintendo Switch...")
log_compat("[PERF] Primer pixel en pantalla a los #{$SWITCH_FIRST_PIXEL_MS} ms desde que Ruby tomo el control") if defined?($SWITCH_FIRST_PIXEL_MS) && $SWITCH_FIRST_PIXEL_MS
log_compat("=================================================================")

# 1.05 Pre-indexación de Assets en RAM para 60 FPS sin I/O en MicroSD (Arranque Instantáneo)
$GRAPHICS_LOOKUP_TABLE ||= {}
$AUDIO_LOOKUP_TABLE ||= {}
$RESOLVE_AUDIO_MEMO_CACHE ||= {}
$RESOLVED_BITMAP_CACHE ||= {}
$SWITCH_ASSETS_INDEX_LOADED ||= false

def pbLoadSwitchAssetsIndex
  return if $SWITCH_ASSETS_INDEX_LOADED
  $SWITCH_ASSETS_INDEX_LOADED = true
  dat_file = ["Data/switch_assets_index.dat", "./Data/switch_assets_index.dat"].find { |p| File.exist?(p) }
  if dat_file && ($GRAPHICS_LOOKUP_TABLE.nil? || $GRAPHICS_LOOKUP_TABLE.empty?)
    begin
      raw = File.open(dat_file, "rb") { |f| f.read }
      if raw && !raw.empty?
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f
        $GRAPHICS_LOOKUP_TABLE, $AUDIO_LOOKUP_TABLE = Marshal.load(raw)
        t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f
        log_compat(sprintf("[Switch Assets] Cargados %d graficos y %d audios desde .dat en %.3fs (Arranque Instantaneo).", ($GRAPHICS_LOOKUP_TABLE.length rescue 0), ($AUDIO_LOOKUP_TABLE.length rescue 0), (t1 - t0))) rescue nil
      end
    rescue Exception => e
      log_compat("[Warning Switch Assets DAT] #{e.message}") rescue nil
    end
  end
end




# 1.1 Soporte de Encoding para Ruby 3.x
if defined?(Encoding)
  Encoding.const_set(:UTF_8, Encoding.find("UTF-8")) unless Encoding.const_defined?(:UTF_8) rescue nil
  Encoding.const_set(:ASCII_8BIT, Encoding.find("ASCII-8BIT")) unless Encoding.const_defined?(:ASCII_8BIT) rescue nil
  Encoding.const_set(:US_ASCII, Encoding.find("US-ASCII")) unless Encoding.const_defined?(:US_ASCII) rescue nil
  Encoding.const_set(:BINARY, Encoding.find("ASCII-8BIT")) unless Encoding.const_defined?(:BINARY) rescue nil
  Encoding.const_set(:UTF8, Encoding.find("UTF-8")) unless Encoding.const_defined?(:UTF8) rescue nil
end

class ::String
  def first(n = 1)
    return "" if n <= 0
    self[0...n]
  end

  def last(n = 1)
    return "" if n <= 0
    return self if n >= length
    self[-n..-1]
  end
end

class ::Array
  include Enumerable
  def each_with_index(&block)
    return to_enum(:each_with_index) unless block_given?
    idx = 0
    each do |item|
      yield(item, idx)
      idx += 1
    end
    self
  end
end

# 1.2 Interceptor seguro de Threads para evitar crashes de pthreads en Nintendo Switch
class ::Thread
  class DummyThread
    def status; false; end
    def alive?; false; end
    def stop?; true; end
    def join(*args); self; end
    def value; nil; end
    def kill; self; end
    def terminate; self; end
    def exit; self; end
    def []=(k, v); end
    def [](k); nil; end
  end

  class << self
    def new(*args, &block)
      DummyThread.new
    end
    alias start new
    alias fork new
  end
end

module Kernel
  def sleep(duration = 0)
    duration = duration.to_f
    if duration <= 0
      Graphics.update rescue nil
      return 0
    end
    frames = (duration * 40).to_i
    frames = [frames, 40].min
    frames.times { Graphics.update rescue nil }
    duration
  end
end





# 1.3 Módulo Zlib universal
module ::Zlib
  class Error < StandardError; end
  class StreamError < Error; end
  class DataError < Error; end
  
  class Inflate
    def self.inflate(string)
      string
    end
    def inflate(string)
      string
    end
  end
  
  class Deflate
    def self.deflate(string, level = nil)
      string
    end
    def deflate(string, level = nil)
      string
    end
  end
  
  def self.crc32(string = nil, crc = 0)
    0
  end
  def self.inflate(string)
    string
  end
  def self.deflate(string, level = nil)
    string
  end
end

::Zlib = Zlib unless Object.const_defined?(:Zlib)
Kernel.const_set(:Zlib, ::Zlib) unless Kernel.const_defined?(:Zlib)
Module.const_set(:Zlib, ::Zlib) unless Module.const_defined?(:Zlib)

# 1.4 Módulo System completo
module ::System
  VERSION = "2.4.2" unless const_defined?(:VERSION)
  BUILD = "Horizon" unless const_defined?(:BUILD)
  PLATFORM = "Nintendo Switch" unless const_defined?(:PLATFORM)

  class << self
    def raw_uptime
      Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue (Time.now.to_f)
    end

    def uptime
      raw_uptime
    end

    def real_uptime
      raw_uptime
    end

    def unscaled_uptime
      raw_uptime
    end

    def data_directory
      "."
    end

    def game_title
      "Pokemon Anil"
    end

    def set_window_title(title = "")
      title
    end

    def user_name
      "Ash"
    end

    def user_language
      "es_ES"
    end

    def power_state
      { :discharging => false, :percent => 100, :seconds => nil }
    end

    def battery_charge
      100
    end

    def show_cursor
      false
    end

    def show_cursor=(val)
      val
    end unless method_defined?(:show_cursor=)

    def nproc
      4
    end

    def memory
      4 * 1024 * 1024 * 1024
    end

    def platform
      "Nintendo Switch"
    end

    def method_missing(m, *a, &b)
      nil
    end
  end
end

module Kernel
  if defined?(Kernel::System) && Kernel::System != ::System
    Kernel.send(:remove_const, :System) rescue nil
  end
  System = ::System unless const_defined?(:System)
end

# 1.5 Módulo SaveData universal con soporte de Multi Save y Essentials v21.1
module ::SaveData
  Zlib = ::Zlib
  @values ||= []
  @conversions ||= { essentials: {}, game: {} }
  FILE_PATH = "./Game.rxdata" unless const_defined?(:FILE_PATH)
  AUTO_SLOTS = ['Auto 1', 'Auto 2', 'Auto 3'] unless const_defined?(:AUTO_SLOTS)

  class << self
    def initialize_bootup_values(*args)
      if defined?(@values) && @values
        @values.each do |value|
          next unless value.respond_to?(:load_in_bootup?) && value.load_in_bootup?
          value.load_new_game_value if value.respond_to?(:has_new_game_proc?) && value.has_new_game_proc? && !value.loaded?
        end rescue nil
      end
      nil
    end

    def load_bootup_values(save_data = {})
      if defined?(@values) && @values
        load_values(save_data) { |value| !value.loaded? && value.load_in_bootup? } rescue nil
      end
      nil
    end

    def load_new_game_values(*args)
      if defined?(@values) && @values
        @values.each do |value|
          value.load_new_game_value if value.respond_to?(:has_new_game_proc?) && value.has_new_game_proc? && (!value.respond_to?(:loaded?) || !value.loaded? || (value.respond_to?(:reset_on_new_game?) && value.reset_on_new_game?))
        end rescue nil
      end
      nil
    end

    def mark_values_as_unloaded(*args)
      if defined?(@values) && @values
        @values.each do |value|
          value.mark_as_unloaded if value.respond_to?(:mark_as_unloaded) && (!value.respond_to?(:load_in_bootup?) || !value.load_in_bootup? || (value.respond_to?(:reset_on_new_game?) && value.reset_on_new_game?))
        end rescue nil
      end
      nil
    end

    def exists?
      return true if File.file?(FILE_PATH) || File.file?("./Game.rxdata") || File.file?("Game.rxdata")
      (1..10).any? { |i| File.file?("./Partida #{i}.rxdata") || File.file?("Partida #{i}.rxdata") }
    end

    def get_newest_save_slot
      nil
    end

    def read_from_file_safe(path, **opts)
      {}
    end

    def get_full_path(slot = nil)
      return "./Game.rxdata" if slot.nil? || slot.to_s.empty?
      file_name = slot.to_s
      file_name += ".rxdata" unless file_name.end_with?(".rxdata")
      file_name = "./#{file_name}" unless file_name.start_with?("./") || file_name.start_with?("/")
      file_name
    end

    def method_missing(m, *a, &b)
      log_compat("[SaveData] metodo no implementado: #{m}") rescue nil
      super
    end
  end
end

class ::Trainer; end unless defined?(::Trainer)
class ::Player < ::Trainer
  attr_accessor :last_time_saved, :save_slot, :last_save_slot, :autosave_steps unless method_defined?(:save_slot)
end

module Kernel
  SaveData = ::SaveData
end

# 1.6 Módulo PluginManager
module ::PluginManager
  Zlib = ::Zlib
  @@Plugins ||= {}

  class << self
    def installed?(plugin_name, plugin_version = nil, mustequal = false)
      plugin = @@Plugins[plugin_name]
      return false if plugin.nil?
      return true if plugin_version.nil?
      true
    end

    def runPlugins
    end

    def error(msg)
      puts "[PluginManager Error] #{msg}"
    end
  end
end

module Kernel
  PluginManager = ::PluginManager
end

# 1.7 Módulo Compiler
module ::Compiler
  Zlib = ::Zlib

  class << self
    def validate_all_compiled_pokemon; end
    def validate_all_compiled_pokemon_forms; end
    def validate_compiled_pokemon(*args); end
    def validate_compiled_pokemon_forms(*args); end
    def compile_all; end
    def main; end
  end
end

module ::MessageTypes
  Zlib = ::Zlib
end

# 1.8 Clases de compatibilidad para animaciones de combate
class AnimFrame
  X          = 0
  Y          = 1
  ZOOMX      = 2
  ANGLE      = 3
  MIRROR     = 4
  BLENDTYPE  = 5
  VISIBLE    = 6
  PATTERN    = 7
  OPACITY    = 8
  ZOOMY      = 11
  COLORRED   = 12
  COLORGREEN = 13
  COLORBLUE  = 14
  COLORALPHA = 15
  TONERED    = 16
  TONEGREEN  = 17
  TONEBLUE   = 18
  TONEGRAY   = 19
  LOCKED     = 20
  FLASHRED   = 21
  FLASHGREEN = 22
  FLASHBLUE  = 23
  FLASHALPHA = 24
  PRIORITY   = 25
  FOCUS      = 26
end unless defined?(AnimFrame)

class PBAnimTiming
  attr_accessor :frame, :timingType, :name, :volume, :pitch
  attr_accessor :bgX, :bgY, :opacity, :colorRed, :colorGreen, :colorBlue, :colorAlpha
  attr_accessor :duration, :flashScope, :flashColor, :flashDuration

  def initialize(type = 0)
    @frame = 0; @timingType = type; @name = ""; @volume = 80; @pitch = 100
    @bgX = nil; @bgY = nil; @opacity = nil; @colorRed = nil; @colorGreen = nil; @colorBlue = nil; @colorAlpha = nil
    @duration = 5; @flashScope = 0; @flashColor = Color.new(255, 255, 255); @flashDuration = 5
  end

  def timingType; @timingType || 0; end
  def duration; @duration || 5; end
end unless defined?(PBAnimTiming)

class PBAnimation < Array
  attr_accessor :id, :name, :graphic, :hue, :position, :speed, :array, :timing, :scope

  def speed; @speed || 20; end
  def timing; @timing ||= []; end

  def initialize(size = 1)
    @id = -1; @name = ""; @graphic = ""; @hue = 0; @position = 4; @array = []; @timing = []; @scope = 0
  end

  def length
    return @array.length if @array
    return super rescue 0
  end

  def size
    return @array.size if @array
    return super rescue 0
  end

  def [](i)
    return @array[i] if @array
    return super(i) rescue nil
  end

  def []=(i, v)
    if @array
      @array[i] = v
    else
      super(i, v) rescue nil
    end
  end

  def each(&block)
    return @array.each(&block) if @array
    return super(&block) rescue nil
  end
end unless defined?(PBAnimation)

class PBAnimations < Array
  attr_accessor :array, :selected

  def initialize(size = 1)
    @array = []; @selected = 0
  end

  def length
    return @array.length if @array
    return super rescue 0
  end

  def empty?
    return (@array || []).empty?
  end

  def size
    return @array.size if @array
    return super rescue 0
  end

  def [](i)
    return @array[i] if @array
    return super(i) rescue nil
  end

  def []=(i, v)
    if @array
      @array[i] = v
    else
      super(i, v) rescue nil
    end
  end

  def each(&block)
    return @array.each(&block) if @array
    return super(&block) rescue nil
  end

  def get_from_name(name)
    list = @array || self
    list.each { |i| return i if i&.name == name }
    return nil
  end
end unless defined?(PBAnimations)


# 1.8 Módulo Game
module ::Game
  class << self
    def initialize(*args); end
    def set_up_system(*args)
      if defined?(SaveData) && SaveData.respond_to?(:initialize_bootup_values)
        SaveData.initialize_bootup_values rescue nil
      end
      if defined?(SaveData) && SaveData.respond_to?(:load_options)
        SaveData.load_options rescue nil
      end
      if defined?(SwitchAssetOptimizer)
        SwitchAssetOptimizer.prewarm_all rescue nil
      end
    rescue Exception => e
      log_compat("[Warning set_up_system] #{e.class}: #{e.message}") rescue nil
    end
  end
end

def pbPlayMovie(filename)
  log_compat("[Movie Shim] pbPlayMovie: #{filename} omitido de forma segura en Switch.") rescue nil
  Graphics.freeze rescue nil
  Graphics.transition(10) rescue nil
end unless defined?(pbPlayMovie)

module Graphics
  class << self
    def play_movie(filename)
      log_compat("[Movie Shim] Graphics.play_movie: #{filename} omitido de forma segura en Switch.") rescue nil
    end unless method_defined?(:play_movie)
  end
end

# 1.9 Clases de Animación para Marshal.load (PkmnAnimations.rxdata)
unless defined?(::AnimFrame)
  class AnimFrame
    X          = 0
    Y          = 1
    ZOOMX      = 2
    ANGLE      = 3
    MIRROR     = 4
    BLENDTYPE  = 5
    VISIBLE    = 6
    PATTERN    = 7
    OPACITY    = 8
    ZOOMY      = 11
    COLORRED   = 12
    COLORGREEN = 13
    COLORBLUE  = 14
    COLORALPHA = 15
    TONERED    = 16
    TONEGREEN  = 17
    TONEBLUE   = 18
    TONEGRAY   = 19
    LOCKED     = 20
    FLASHRED   = 21
    FLASHGREEN = 22
    FLASHBLUE  = 23
    FLASHALPHA = 24
    PRIORITY   = 25
    FOCUS      = 26
  end
end
  class PBAnimTiming
    attr_accessor :frame, :name, :volume, :pitch, :bgX, :bgY, :opacity
    attr_accessor :colorRed, :colorGreen, :colorBlue, :colorAlpha
    attr_accessor :flashScope, :flashColor, :flashDuration
    attr_writer   :timingType, :duration

    def initialize(type = 0)
      @frame         = 0
      @timingType    = type
      @name          = ""
      @volume        = 80
      @pitch         = 100
      @duration      = 5
      @flashScope    = 0
    end

    def timingType; @timingType || 0; end
    def duration; @duration || 5; end
  end

# Ensure Kernel::Array does NOT exist and Array is always ::Array
Kernel.send(:remove_const, :Array) rescue nil

unless defined?(::PBAnimation)
  class ::PBAnimation < ::Array
    attr_accessor :id, :name, :graphic, :hue, :position
    attr_writer   :speed
    attr_reader   :array, :timing

    def speed; @speed || 20; end

    def initialize(size = 1)
      @id       = -1
      @name     = ""
      @graphic  = ""
      @hue      = 0
      @position = 4
      @array    = []
      @timing   = []
      @scope    = 0
    end
  end
end

unless defined?(::PBAnimations)
  class ::PBAnimations < ::Array
    attr_reader   :array
    attr_accessor :selected

    def initialize(size = 1)
      @array = []
      @selected = 0
    end
  end
end

::AnimFrame = AnimFrame unless Object.const_defined?(:AnimFrame)
::PBAnimTiming = PBAnimTiming unless Object.const_defined?(:PBAnimTiming)
::PBAnimation = PBAnimation unless Object.const_defined?(:PBAnimation)
::PBAnimations = PBAnimations unless Object.const_defined?(:PBAnimations)

# 1.10 Módulo Input de RGSS
module ::Input
  DOWN  = 2  unless const_defined?(:DOWN)
  LEFT  = 4  unless const_defined?(:LEFT)
  RIGHT = 6  unless const_defined?(:RIGHT)
  UP    = 8  unless const_defined?(:UP)
  A     = 11 unless const_defined?(:A)
  B     = 12 unless const_defined?(:B)
  C     = 13 unless const_defined?(:C)
  X     = 14 unless const_defined?(:X)
  Y     = 15 unless const_defined?(:Y)
  Z     = 16 unless const_defined?(:Z)
  L     = 17 unless const_defined?(:L)
  R     = 18 unless const_defined?(:R)
  SHIFT = 21 unless const_defined?(:SHIFT)
  CTRL  = 22 unless const_defined?(:CTRL)
  ALT   = 23 unless const_defined?(:ALT)
  F5    = 25 unless const_defined?(:F5)
  F6    = 26 unless const_defined?(:F6)
  F7    = 27 unless const_defined?(:F7)
  F8    = 28 unless const_defined?(:F8)
  F9    = 29 unless const_defined?(:F9)
  
  MOUSELEFT   = 1 unless const_defined?(:MOUSELEFT)
  MOUSERIGHT  = 2 unless const_defined?(:MOUSERIGHT)
  MOUSEMIDDLE = 3 unless const_defined?(:MOUSEMIDDLE)
  
  BACK   = 12 unless const_defined?(:BACK)
  USE    = 13 unless const_defined?(:USE)
  ACTION = 11 unless const_defined?(:ACTION)
  TAB    = 9  unless const_defined?(:TAB)
  ENTER  = 13 unless const_defined?(:ENTER)
  ESCAPE = 12 unless const_defined?(:ESCAPE)
  SPACE  = 13 unless const_defined?(:SPACE)
  AUX1   = 17 unless const_defined?(:AUX1)
  AUX2   = 18 unless const_defined?(:AUX2)
  SPECIAL = 23 unless const_defined?(:SPECIAL)

  class << self
    alias __mkxp_native_input_update update unless method_defined?(:__mkxp_native_input_update) rescue nil

    def update_switch_triggers
      if defined?(::Input::Controller) && ::Input::Controller.connected?
        trig = (::Input::Controller.axes_trigger rescue nil)
        if trig
          zl_now = ((trig[0] || 0.0) > 0.45)
          zr_now = ((trig[1] || 0.0) > 0.45)
          @zl_triggered = zl_now && !@zl_pressed_last
          @zr_triggered = zr_now && !@zr_pressed_last
          @zl_pressed_last = zl_now
          @zr_pressed_last = zr_now
        else
          @zl_triggered = false
          @zr_triggered = false
        end
      end
    end

    def update_KGC_ScreenCapture
      update_switch_triggers
      __mkxp_native_input_update rescue nil
    end

    def update
      update_switch_triggers
      __mkxp_native_input_update rescue nil
    end

    def mouse_in_window; false; end
    def mouse_in_window?; false; end
    def mouse_x; 0; end
    def mouse_y; 0; end
    def scroll_v; 0; end
    def release?(*args); false; end
    def time?(*args); 0; end

    # Gatillos analógicos ZL y ZR en Nintendo Switch (umbral 0.45)
    def press_zl?
      return false unless defined?(::Input::Controller) && ::Input::Controller.connected?
      ((::Input::Controller.axes_trigger[0] rescue 0.0) || 0.0) > 0.45
    end

    def press_zr?
      return false unless defined?(::Input::Controller) && ::Input::Controller.connected?
      ((::Input::Controller.axes_trigger[1] rescue 0.0) || 0.0) > 0.45
    end

    def trigger_zl?
      @zl_triggered == true
    end

    def trigger_zr?
      @zr_triggered == true
    end

    # Botón + (Plus / Start en Switch)
    def trigger_plus?
      if defined?(::Input::Controller) && ::Input::Controller.connected?
        return true if (::Input::Controller.triggerex?(:START) rescue false)
      end
      if ::Input.respond_to?(:triggerex?)
        return true if (::Input.triggerex?(:RETURN) || ::Input.triggerex?(:KP_ENTER) rescue false)
      end
      false
    end

    # Botón L en Nintendo Switch
    def trigger_l?
      if defined?(::Input::Controller) && ::Input::Controller.connected?
        return true if (::Input::Controller.triggerex?(:LEFTSHOULDER) rescue false)
      end
      return true if (::Input.trigger?(::Input::L) rescue false)
      return true if (::Input.trigger?(::Input::AUX1) rescue false)
      return true if (::Input.respond_to?(:triggerex?) && ::Input.triggerex?(:L) rescue false)
      false
    end

    # Botón R en Nintendo Switch
    def trigger_r?
      if defined?(::Input::Controller) && ::Input::Controller.connected?
        return true if (::Input::Controller.triggerex?(:RIGHTSHOULDER) rescue false)
      end
      return true if (::Input.trigger?(::Input::R) rescue false)
      return true if (::Input.trigger?(::Input::AUX2) rescue false)
      return true if (::Input.respond_to?(:triggerex?) && ::Input.triggerex?(:R) rescue false)
      false
    end

    # Detección inteligente de Turbo (L por defecto, o R / ZR según menú Controles)
    def trigger_turbo?
      return true if (::Input.trigger?(::Input::ALT) rescue false)
      return true if (::Input.respond_to?(:triggerex?) && ::Input.triggerex?(:M) rescue false)
      mode = ($PokemonSystem&.turbo_button || 0) rescue 0
      case mode
      when 1 # Asignado a botón R
        return true if trigger_r?
      when 2 # Asignado a gatillo ZR
        return true if trigger_zr?
      else   # Asignado a botón L (predeterminado)
        return true if trigger_l?
      end
      false
    end

    def trigger_controls?
      if defined?(::Input::Controller) && ::Input::Controller.connected?
        return true if (::Input::Controller.triggerex?(:BACK) rescue false)
      end
      if ::Input.respond_to?(:triggerex?)
        return true if (::Input.triggerex?(:MINUS) || ::Input.triggerex?(:KP_MINUS) rescue false)
        return true if (::Input.triggerex?(:H) rescue false)
      end
      false
    end

    def remap_button(num)
      layout = ($PokemonSystem&.button_layout || 0) rescue 0
      if layout == 1 # Estilo PC / Xbox invertido: A y B intercambiados
        if num == 13 # Input::USE / C
          return 12  # Input::BACK / B
        elsif num == 12 # Input::BACK / B
          return 13  # Input::USE / C
        end
      end
      num
    end

    alias __native_btn_trigger? trigger? unless method_defined?(:__native_btn_trigger?)
    alias __native_btn_press? press? unless method_defined?(:__native_btn_press?)
    alias __native_btn_repeat? repeat? unless method_defined?(:__native_btn_repeat?)

    def trigger?(num)
      __native_btn_trigger?(remap_button(num))
    end

    def press?(num)
      __native_btn_press?(remap_button(num))
    end

    def repeat?(num)
      __native_btn_repeat?(remap_button(num))
    end
  end
end

class PokemonSystem
  attr_accessor :button_layout, :turbo_button, :plus_action unless method_defined?(:button_layout)
  def only_speedup_battles; @only_speedup_battles || 0; end
  def turbo_button; @turbo_button || 0; end
  def plus_action; @plus_action || 0; end
  def button_layout; @button_layout || 0; end
end

# Optimizaciones maestras de rendimiento para Nintendo Switch (V4.13)
# 1. Carga perezosa de iconos de Poke Ball en ChangelingSprite (elimina congelación de 1.2s en menú de equipo)
module NXBolas
  @instalado = false
  class << self
    attr_reader :instalado
    def instala
      return true if @instalado
      return false unless Object.const_defined?(:ChangelingSprite) &&
                          ChangelingSprite.method_defined?(:add_bitmap)
      @instalado = true
      ChangelingSprite.class_eval do
        def add_bitmap(mode, *data)
          if ![1, 5].include?(data.length)
            raise ArgumentError.new(_INTL("wrong number of arguments (given {1}, expected 2 or 6)", data.length + 1))
          end
          @changeling_data[mode] = (data[0].is_a?(Array) ? data[0].clone : [data[0]])
        end

        alias_method :nx_change_bitmap_sin_carga, :change_bitmap unless method_defined?(:nx_change_bitmap_sin_carga)
        def change_bitmap(mode)
          datos = @changeling_data[mode]
          if mode && datos
            ruta = datos[0]
            @bitmaps[ruta] = AnimatedBitmap.new(ruta) if !@bitmaps[ruta]
          end
          nx_change_bitmap_sin_carga(mode)
        end
      end
      true
    end
  end
end

# 2. Reutilización de tiras de animación en PokemonSprite [DBK] (elimina congelación de 600ms en datos del Pokémon)
module NXTira
  @instalado = false
  @aciertos = 0
  @fallos = 0
  class << self
    attr_reader :instalado
    def clave(pokemon, back)
      return nil unless pokemon.is_a?(Pokemon)
      fichero = GameData::Species.sprite_filename(
        pokemon.species, pokemon.form, pokemon.gender, pokemon.shiny?,
        pokemon.shadowPokemon?, back, pokemon.egg?)
      hue = (pokemon.respond_to?(:super_shiny?) && pokemon.super_shiny?) ? pokemon.super_shiny_hue : nil
      [fichero, back ? 1 : 0, pokemon.personalID, hue]
    rescue StandardError
      nil
    end

    def instala
      return true if @instalado
      return false unless Object.const_defined?(:PokemonSprite) &&
                          PokemonSprite.method_defined?(:pbSetDisplay) &&
                          Object.const_defined?(:DeluxeBitmapWrapper)
      @instalado = true
      PokemonSprite.class_eval do
        alias_method :nx_setPokemonBitmap_sin_memoria, :setPokemonBitmap unless method_defined?(:nx_setPokemonBitmap_sin_memoria)
        def setPokemonBitmap(pokemon, back = false)
          clave = NXTira.clave(pokemon, back)
          tira = @_iconbitmap
          if clave && clave == @nx_clave_tira && tira.is_a?(DeluxeBitmapWrapper) &&
             !tira.disposed? && !self.disposed?
            @pkmn = pokemon
            tira.instance_variable_set(:@pokemon, pokemon)
            tira.update_pokemon_sprite
            self.bitmap = tira.bitmap
            self.color = Color.new(0, 0, 0, 0)
            self.make_grey_if_fainted = pokemon.perma_faint rescue false
            changeOrigin
            if tira.respond_to?(:constrict_x=)
              tira.constrict_x = 0
              tira.constrict_y = 0
              tira.constrict_w = nil
              tira.constrict_h = nil
            end
            pbSetDisplay
            return
          end
          nx_setPokemonBitmap_sin_memoria(pokemon, back)
          @nx_clave_tira = clave
        end
      end
      true
    end
  end
end

# 3. Teclado virtual con cursor en Nintendo Switch
module NXTeclado
  @hecho = false
  class << self
    attr_accessor :hecho
    def revisar
      return true if @hecho
      return false unless defined?(PokemonEntryScene2)
      return false unless Object.private_method_defined?(:pbEnterText) || Object.method_defined?(:pbEnterText)
      @hecho = true
      Object.send(:alias_method, :nx_pbEnterText_con_teclado, :pbEnterText) unless Object.method_defined?(:nx_pbEnterText_con_teclado)
      Object.send(:define_method, :pbEnterText) do |*args|
        if defined?($PokemonSystem) && $PokemonSystem.respond_to?(:textinput) && ($PokemonSystem.textinput || 0) == 0
          $PokemonSystem.textinput = 1
        end
        nx_pbEnterText_con_teclado(*args)
      end
      true
    rescue Exception
      @hecho = true
    end
  end
end

# Inyección segura en bucle de renderizado para activación diferida
module ::Graphics
  class << self
    alias __nx_opt_update update unless method_defined?(:__nx_opt_update)
    def update
      NXBolas.instala unless defined?(NXBolas) && NXBolas.instalado
      NXTira.instala unless defined?(NXTira) && NXTira.instalado
      NXTeclado.revisar unless defined?(NXTeclado) && NXTeclado.hecho
      __nx_opt_update
    end
  end
end

# Interruptores y constantes globales
MODO_CLASICO  = 64 unless defined?(MODO_CLASICO)
NO_EXP_SWITCH = 661 unless defined?(NO_EXP_SWITCH)
SWITCH_ONLINE_COMBATE = 133 unless defined?(SWITCH_ONLINE_COMBATE)
SWITCH_ONLINE_INTERCAMBIO = 134 unless defined?(SWITCH_ONLINE_INTERCAMBIO)
ENCENDER_PC_ONLINE = 136 unless defined?(ENCENDER_PC_ONLINE)
OW_ENCOUNTER_SWITCH = 141 unless defined?(OW_ENCOUNTER_SWITCH)
MODO_VGC = 147 unless defined?(MODO_VGC)
MODO_INVERSO = 148 unless defined?(MODO_INVERSO)
MODO_SIN_GRINDEO = 149 unless defined?(MODO_SIN_GRINDEO)
COMBATE_MEWTWO = 155 unless defined?(COMBATE_MEWTWO)
MODO_RADICAL = 666 unless defined?(MODO_RADICAL)

module Kernel
  MODO_CLASICO = 64 unless const_defined?(:MODO_CLASICO)
  NO_EXP_SWITCH = 661 unless const_defined?(:NO_EXP_SWITCH)
  SWITCH_ONLINE_COMBATE = 133 unless const_defined?(:SWITCH_ONLINE_COMBATE)
  SWITCH_ONLINE_INTERCAMBIO = 134 unless const_defined?(:SWITCH_ONLINE_INTERCAMBIO)
  ENCENDER_PC_ONLINE = 136 unless const_defined?(:ENCENDER_PC_ONLINE)
  OW_ENCOUNTER_SWITCH = 141 unless const_defined?(:OW_ENCOUNTER_SWITCH)
  MODO_VGC = 147 unless const_defined?(:MODO_VGC)
  MODO_INVERSO = 148 unless const_defined?(:MODO_INVERSO)
  MODO_SIN_GRINDEO = 149 unless const_defined?(:MODO_SIN_GRINDEO)
  COMBATE_MEWTWO = 155 unless const_defined?(:COMBATE_MEWTWO)
  MODO_RADICAL = 666 unless const_defined?(:MODO_RADICAL)
end

if defined?(Kernel::Input) && Kernel::Input != ::Input
  Kernel.send(:remove_const, :Input) rescue nil
end
Kernel.const_set(:Input, ::Input) unless Kernel.const_defined?(:Input) && Kernel.const_get(:Input) == ::Input rescue nil

# Shims offline para Nintendo Switch (evita bloqueos de sockets y timeouts HTTP en el hilo de render)
module ::PokeAPI
  def self.get_data(*args)
    nil
  end
end unless defined?(::PokeAPI)

def pbCableClub(*args)
  pbMessage(_INTL("La funcionalidad online del Club del Cable no está disponible en Nintendo Switch.")) rescue nil
end unless defined?(pbCableClub)

$FOLLOWER_SPRITE_MEMO ||= {}

# 1.105 Sprite compatibilidad
class ::Sprite
  attr_accessor :z, :x, :y, :ox, :oy, :zoom_x, :zoom_y, :angle, :mirror, :bush_depth, :opacity, :blend_type, :color, :tone, :visible, :bitmap, :viewport, :src_rect unless method_defined?(:z=)
end



# 1.107 Graphics resolucion fija para Essentials
module ::Graphics
  class << self
    def width; 512; end
    def height; 384; end
  end
end

# 1.108 PokemonSystem compatibilidad universal
class ::PokemonSystem
  attr_accessor :textspeed, :battlescene, :battlestyle, :sendtoboxes, :givenicknames
  attr_accessor :frame, :textskin, :screensize, :language, :runstyle, :bgmvolume, :sevolume
  attr_accessor :textinput, :vsync, :autotile_animations, :salvajes_visibles_en_ow

  def bgmvolume
    @bgmvolume || 100
  end

  def bgmvolume=(val)
    @bgmvolume = val
  end

  def sevolume
    @sevolume || 100
  end

  def sevolume=(val)
    @sevolume = val
  end

  def textspeed
    @textspeed || 2
  end

  def textspeed=(val)
    @textspeed = val
  end

  def frame
    @frame || 0
  end

  def textskin
    @textskin || 0
  end

  def salvajes_visibles_en_ow
    @salvajes_visibles_en_ow || 0
  end

  def salvajes_visibles_en_ow=(val)
    @salvajes_visibles_en_ow = val
  end

  def salvajes_visibles_en_ow?
    (@salvajes_visibles_en_ow || 0) == 0
  end
end

def pb_salvajes_visibles_en_ow?
  return $PokemonSystem ? $PokemonSystem.salvajes_visibles_en_ow? : true
end

module Kernel
  def pb_salvajes_visibles_en_ow?
    return $PokemonSystem ? $PokemonSystem.salvajes_visibles_en_ow? : true
  end
end

class ::PokemonSystem

  def method_missing(name, *args, &block)
    if name.to_s.end_with?("=")
      var = "@#{name.to_s.chop}".to_sym
      instance_variable_set(var, args[0])
    elsif name.to_s.end_with?("?")
      var = "@#{name.to_s.chop}".to_sym
      val = instance_variable_get(var)
      val == true || val == 1 || val == 0
    else
      var = "@#{name}".to_sym
      instance_variable_get(var)
    end
  end

  def respond_to_missing?(name, include_private = false)
    true
  end
end

module ::RandomizedChallenge
  class << self
    def enabled?; false; end
    def randomize_pokemon?; false; end
    def consistent_wild_encounters?; false; end
    def method_missing(m, *args, &block); false; end
    def respond_to_missing?(m, include_private = false); true; end
  end
end

module ::ChallengeModes
  class << self
    def on?(*args); false; end
    def queued?(*args); false; end
    def running?(*args); false; end
    def won?(*args); false; end
    def rules; []; end
    def method_missing(m, *args, &block); false; end
    def respond_to_missing?(m, include_private = false); true; end
  end
end

module ::MonotypeChallenge
  class << self
    def enabled?; false; end
    def type; nil; end
    def method_missing(m, *args, &block); false; end
    def respond_to_missing?(m, include_private = false); true; end
  end
end

module Kernel
  RandomizedChallenge = ::RandomizedChallenge unless const_defined?(:RandomizedChallenge)
  ChallengeModes = ::ChallengeModes unless const_defined?(:ChallengeModes)
  MonotypeChallenge = ::MonotypeChallenge unless const_defined?(:MonotypeChallenge)

  def pbGet(id)
    if id == 31
      val = ($game_variables ? $game_variables[31] : nil)
      if !val.is_a?(Array) || val.length < 3 || val[0].nil?
        val = [:BULBASAUR, :CHARMANDER, :SQUIRTLE]
        $game_variables[31] = val if $game_variables
      end
      return val
    end
    return $game_variables ? $game_variables[id] : 0
  end
end

class Game_Temp
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "single", "1v1", "1v2", "2v1", "1v3", "3v1",
         "double", "2v2", "2v3", "3v2", "triple", "3v3"
      rules["size"] = rule.to_s.downcase
    when "canlose"                then rules["canLose"]             = true
    when "cannotlose"             then rules["canLose"]             = false
    when "canrun"                 then rules["canRun"]              = true
    when "cannotrun"              then rules["canRun"]              = false
    when "roamerflees"            then rules["roamerFlees"]         = true
    when "canswitch"              then rules["canSwitch"]           = true
    when "cannotswitch"           then rules["canSwitch"]           = false
    when "noexp"                  then rules["expGain"]             = false
    when "nomoney"                then rules["moneyGain"]           = false
    when "disablepokeballs"       then rules["disablePokeBalls"]    = true
    when "forcecatchintoparty"    then rules["forceCatchIntoParty"] = true
    when "switchstyle"            then rules["switchStyle"]         = true
    when "setstyle"               then rules["switchStyle"]         = false
    when "anims"                  then rules["battleAnims"]         = true
    when "noanims"                then rules["battleAnims"]         = false
    when "terrain"
      rules["defaultTerrain"] = GameData::BattleTerrain.try_get(var)&.id rescue nil
    when "weather"
      rules["defaultWeather"] = GameData::BattleWeather.try_get(var)&.id rescue nil
    when "environment", "environ"
      rules["environment"] = GameData::Environment.try_get(var)&.id rescue nil
    when "backdrop", "battleback" then rules["backdrop"]            = var
    when "base"                   then rules["base"]                = var
    when "outcome", "outcomevar"  then rules["outcomeVar"]          = var
    when "nopartner"              then rules["noPartner"]           = true
    when "adjustlevels"           then rules["adjustLevels"]        = true
    when "adjustlevelsresetmoves" then rules["adjustLevelsResetMoves"] = true
    when "midbattlescript", "midbattle" then rules["midbattleScript"] = var
    else
      rules[rule.to_s] = var.nil? ? true : var
    end
  end
end

def setBattleRule(*args)
  r = nil
  args.each do |arg|
    if r
      $game_temp.add_battle_rule(r, arg)
      r = nil
    else
      case arg.to_s.downcase
      when "terrain", "weather", "environment", "environ", "backdrop", "battleback", "base", "outcome", "outcomevar", "midbattlescript", "midbattle"
        r = arg
        next
      end
      $game_temp.add_battle_rule(arg)
    end
  end
  $game_temp.add_battle_rule(r) if r
end

$RESOLVED_BITMAP_CACHE ||= {}

def pbResolveBitmap(x)
  return nil if !x
  return $RESOLVED_BITMAP_CACHE[x] if $RESOLVED_BITMAP_CACHE.has_key?(x)
  noext = x.gsub(/\.(bmp|png|gif|jpg|jpeg)$/, "")
  filename = nil
  RTP.eachPathFor(noext) do |path|
    filename = pbTryString(path + ".png") if !filename
    filename = pbTryString(path + ".gif") if !filename
  end
  $RESOLVED_BITMAP_CACHE[x] = filename
  return filename
end

# 1.11 Bitmap y Renderizado de Fuentes Nítidas
class ::Bitmap
  attr_accessor :text_offset_y

  class << self
    def max_size
      4096
    end

    unless method_defined?(:__switch_bitmap_orig_new)
      alias __switch_bitmap_orig_new new
      def new(*args)
        begin
          __switch_bitmap_orig_new(*args)
        rescue Exception => e
          log_compat("[Bitmap.new Fallback] Error al cargar Bitmap #{args.inspect}: #{e.class} - #{e.message}") rescue nil
          if args.length == 2 && args[0].is_a?(Numeric) && args[1].is_a?(Numeric)
            w = [[args[0].to_i, 1].max, 4096].min
            h = [[args[1].to_i, 1].max, 4096].min
            __switch_bitmap_orig_new(w, h) rescue __switch_bitmap_orig_new(32, 32)
          else
            __switch_bitmap_orig_new(32, 32)
          end
        end
      end
    end
  end

  def mega?
    return false if (disposed? rescue true)
    h = (self.height rescue 0)
    max_s = (Bitmap.max_size rescue 4096) || 4096
    return h > max_s
  end
end

def pbSetSystemFont(bitmap)
  return if !bitmap || bitmap.disposed?
  bitmap.font.name = "Power Clear" rescue nil
  bitmap.font.size = 28 rescue nil
end

def pbSetSmallFont(bitmap)
  return if !bitmap || bitmap.disposed?
  bitmap.font.name = "Power Clear" rescue nil
  bitmap.font.size = 22 rescue nil
end

def pbSetNarrowFont(bitmap)
  return if !bitmap || bitmap.disposed?
  bitmap.font.name = "Power Clear" rescue nil
  bitmap.font.size = 28 rescue nil
end

def pbDrawPlainText(bitmap, x, y, width, height, string, baseColor, align = 0)
  return if !bitmap || !string
  ts = bitmap.text_size(string)
  w = (width < 0) ? ts.width + 2 : width
  h = (height < 0) ? ts.height + 12 : [height, ts.height + 12].max
  draw_y = y - 4
  if baseColor && baseColor.alpha > 0
    bitmap.font.color = baseColor
    bitmap.draw_text(x, draw_y, w, h, string, align)
  end
end

def pbDrawShadowText(bitmap, x, y, width, height, string, baseColor, shadowColor = nil, align = 0)
  return if !bitmap || !string
  ts = bitmap.text_size(string)
  w = (width < 0) ? ts.width + 2 : width
  h = (height < 0) ? ts.height + 12 : [height, ts.height + 12].max
  draw_y = y - 4
  if shadowColor && shadowColor.alpha > 0
    bitmap.font.color = shadowColor
    bitmap.draw_text(x + 2, draw_y + 2, w, h, string, align)
  end
  if baseColor && baseColor.alpha > 0
    bitmap.font.color = baseColor
    bitmap.draw_text(x, draw_y, w, h, string, align)
  end
end

def pbDrawOutlineText(bitmap, x, y, width, height, string, baseColor, shadowColor = nil, align = 0)
  return if !bitmap || !string
  ts = bitmap.text_size(string)
  w = (width < 0) ? ts.width + 4 : width
  h = (height < 0) ? ts.height + 12 : [height, ts.height + 12].max
  draw_y = y - 4
  if shadowColor && shadowColor.alpha > 0
    bitmap.font.color = shadowColor
    bitmap.draw_text(x - 2, draw_y - 2, w, h, string, align)
    bitmap.draw_text(x, draw_y - 2, w, h, string, align)
    bitmap.draw_text(x + 2, draw_y - 2, w, h, string, align)
    bitmap.draw_text(x - 2, draw_y, w, h, string, align)
    bitmap.draw_text(x + 2, draw_y, w, h, string, align)
    bitmap.draw_text(x - 2, draw_y + 2, w, h, string, align)
    bitmap.draw_text(x, draw_y + 2, w, h, string, align)
    bitmap.draw_text(x + 2, draw_y + 2, w, h, string, align)
  end
  if baseColor && baseColor.alpha > 0
    bitmap.font.color = baseColor
    bitmap.draw_text(x, draw_y, w, h, string, align)
  end
end

module Kernel
  def pbShowCommands(msgwindow, commands = nil, cmdIfCancel = 0, defaultCmd = 0, &block)
    return 0 if !commands
    cmdwindow = Window_AdvancedCommandPokemon.new(commands)
    cmdwindow.z = 99999
    cmdwindow.visible = true
    cmdwindow.resizeToFit(cmdwindow.commands)
    pbPositionNearMsgWindow(cmdwindow, msgwindow, :right) rescue nil
    cmdwindow.index = defaultCmd
    command = 0
    loop do
      Graphics.update
      Input.update
      cmdwindow.update
      msgwindow&.update
      yield if block_given?
      if Input.trigger?(Input::BACK)
        if cmdIfCancel > 0
          command = cmdIfCancel - 1
          break
        elsif cmdIfCancel < 0
          command = cmdIfCancel
          break
        end
      end
      if Input.trigger?(Input::USE)
        command = cmdwindow.index
        break
      end
      pbUpdateSceneMap rescue nil
    end
    ret = command
    cmdwindow.dispose
    Input.update
    return ret
  end

  def pbShowCommandsWithHelp(msgwindow, commands, help, cmdIfCancel = 0, defaultCmd = 0, &block)
    msgwin = msgwindow
    msgwin = pbCreateMessageWindow(nil) if !msgwindow
    oldlbl = msgwin.letterbyletter
    msgwin.letterbyletter = false
    if commands
      cmdwindow = Window_AdvancedCommandPokemon.new(commands)
      cmdwindow.z = 99999
      cmdwindow.visible = true
      cmdwindow.resizeToFit(cmdwindow.commands)
      cmdwindow.height = msgwin.y if cmdwindow.height > msgwin.y
      cmdwindow.index = defaultCmd
      command = 0
      msgwin.text = help[cmdwindow.index] rescue ""
      msgwin.width = msgwin.width rescue 0
      loop do
        Graphics.update
        Input.update
        oldindex = cmdwindow.index
        cmdwindow.update
        if oldindex != cmdwindow.index
          msgwin.text = help[cmdwindow.index] rescue ""
          msgwin.width = msgwin.width rescue 0
        end
        msgwin.update
        yield if block_given?
        if Input.trigger?(Input::BACK)
          if cmdIfCancel > 0
            command = cmdIfCancel - 1
            break
          elsif cmdIfCancel < 0
            command = cmdIfCancel
            break
          end
        end
        if Input.trigger?(Input::USE)
          command = cmdwindow.index
          break
        end
        pbUpdateSceneMap rescue nil
      end
      ret = command
      cmdwindow.dispose
      Input.update
      return ret
    end
    return 0
  end

  module_function :pbShowCommands, :pbShowCommandsWithHelp rescue nil
end

class Object
  public :pbShowCommands rescue nil
  public :pbShowCommandsWithHelp rescue nil
end

# 1.12 Color, Tone y Rect helpers
class ::Color
  def [](idx)
    case idx
    when 0 then red
    when 1 then green
    when 2 then blue
    when 3 then alpha
    else nil
    end
  end unless method_defined?(:[])
  def self.white; Color.new(255, 255, 255); end
  def self.black; Color.new(0, 0, 0); end
end

class ::Tone
  def [](idx)
    case idx
    when 0 then red
    when 1 then green
    when 2 then blue
    when 3 then gray
    else nil
    end
  end unless method_defined?(:[])
end

class ::Rect
  def contains?(cx, cy)
    cx >= self.x && cx < self.x + self.width && cy >= self.y && cy < self.y + self.height
  end
end

# Font existence fallback
class ::Font
  class << self
    alias __mkxp_orig_exist? exist? unless method_defined?(:__mkxp_orig_exist?) rescue nil
    def exist?(name)
      return true if ["Power Green", "Power Green Small", "Power Green Narrow", "Power Clear", "Power Clear Bold", "Power Red and Blue", "Power Red and Green", "Arial", "MS Gothic", "Sword", "Annon"].include?(name.to_s)
      return true if __mkxp_orig_exist?(name) rescue true
      true
    end
  end
end



begin
  ::Font.default_name = ["Power Clear", "Power Green"]
  ::Font.default_size = 28
rescue Exception
end

class String
  def name; self; end
  def volume; 100; end
  def pitch; 100; end
end



# 1.126 Módulo RPG
module ::RPG
  class AudioFile
    attr_accessor :name, :volume, :pitch

    def initialize(name = "", volume = 100, pitch = 100)
      @name   = name.to_s
      @volume = (volume || 100).to_i
      @pitch  = (pitch || 100).to_i
    end

    def to_s
      @name
    end

    def _dump(limit = -1)
      [@name.to_s, (@volume || 100).to_i, (@pitch || 100).to_i].pack("a*NN")
    end

    def self._load(str)
      return new if str.nil? || str.empty?
      if str.bytesize >= 8
        name = str[0...-8]
        vol, pit = str[-8..-1].unpack("NN")
        new(name, vol, pit)
      else
        new(str)
      end
    rescue Exception
      new
    end
  end

  class BGM < AudioFile
    def play(pos = 0)
      return if !@name || @name.empty?
      file = @name.to_s
      file = "Audio/BGM/" + file unless file.start_with?("Audio/BGM/") || file.start_with?("Audio/")
      ::Audio.bgm_play(file, (@volume || 100).to_i, (@pitch || 100).to_i, pos) rescue nil
    end

    def self.stop
      ::Audio.bgm_stop rescue nil
    end

    def self.fade(time)
      ::Audio.bgm_fade(time) rescue nil
    end

    def self.last
      @last ||= BGM.new
    end
  end

  class BGS < AudioFile
    def play(pos = 0)
      return if !@name || @name.empty?
      file = @name.to_s
      file = "Audio/BGS/" + file unless file.start_with?("Audio/BGS/") || file.start_with?("Audio/")
      ::Audio.bgs_play(file, (@volume || 100).to_i, (@pitch || 100).to_i, pos) rescue nil
    end

    def self.stop
      ::Audio.bgs_stop rescue nil
    end

    def self.fade(time)
      ::Audio.bgs_fade(time) rescue nil
    end
  end

  class ME < AudioFile
    def play
      return if !@name || @name.empty?
      file = @name.to_s
      file = "Audio/ME/" + file unless file.start_with?("Audio/ME/") || file.start_with?("Audio/")
      ::Audio.me_play(file, (@volume || 100).to_i, (@pitch || 100).to_i) rescue nil
    end

    def self.stop
      ::Audio.me_stop rescue nil
    end

    def self.fade(time)
      ::Audio.me_fade(time) rescue nil
    end
  end

  class SE < AudioFile
    def play
      return if !@name || @name.empty?
      file = @name.to_s
      file = "Audio/SE/" + file unless file.start_with?("Audio/SE/") || file.start_with?("Audio/")
      ::Audio.se_play(file, (@volume || 100).to_i, (@pitch || 100).to_i) rescue nil
    end

    def self.stop
      ::Audio.se_stop rescue nil
    end
  end
end

module ::Audio
  def self.bgm_playing?
    (bgm_pos rescue 0).to_i > 0
  end unless respond_to?(:bgm_playing?)
end

# Ultra-fast On-demand Memoized Resolvers leveraging mkxp-z native C++ pathCache
$RESOLVED_BITMAP_CACHE ||= {}
$RESOLVE_AUDIO_MEMO_CACHE ||= {}

def build_asset_caches!; end
def build_audio_cache!; end
def build_graphics_cache!; end

unless defined?($SWITCH_BITMAP_INIT_HOOKED)
  $SWITCH_BITMAP_INIT_HOOKED = true
  class ::Bitmap
    alias __switch_native_bitmap_init initialize
    def initialize(*args)
      if args.length == 1 && args[0].is_a?(String) && !args[0].empty?
        k = args[0].to_s.gsub("\\", "/")
        cached = $RESOLVED_BITMAP_CACHE[k]
        return __switch_native_bitmap_init(cached) if cached

        base = File.basename(k)
        base_no_ext = base.sub(/\.(bmp|png|gif|jpg|jpeg)$/i, "")
        k_noext = k.sub(/\.(bmp|png|gif|jpg|jpeg)$/i, "")

        if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE && !$GRAPHICS_LOOKUP_TABLE.empty?
          found = $GRAPHICS_LOOKUP_TABLE[k.downcase] ||
                  $GRAPHICS_LOOKUP_TABLE[k_noext.downcase] ||
                  $GRAPHICS_LOOKUP_TABLE[base.downcase] ||
                  $GRAPHICS_LOOKUP_TABLE[base_no_ext.downcase] ||
                  $GRAPHICS_LOOKUP_TABLE["graphics/" + k.downcase] ||
                  $GRAPHICS_LOOKUP_TABLE["graphics/" + k_noext.downcase]
          if found
            $RESOLVED_BITMAP_CACHE[k] = found
            return __switch_native_bitmap_init(found)
          end
        end

        candidates = [
          k,
          "#{k}.png",
          "#{k}.gif",
          "#{k_noext}.png",
          "Graphics/#{k}",
          "Graphics/#{k}.png",
          "Graphics/#{k_noext}.png",
          "Graphics/Characters/#{base_no_ext}.png",
          "Graphics/Characters/#{base}",
          "Graphics/Pictures/#{base_no_ext}.png",
          "Graphics/Pictures/#{base}",
          "Graphics/Animations/#{base_no_ext}.png",
          "Graphics/Animations/#{base}",
          "Graphics/UI/#{base_no_ext}.png",
          "Graphics/UI/#{base}"
        ]

        found = nil
        candidates.each do |cand|
          if FileTest.exist?(cand) || File.exist?(cand)
            found = cand
            break
          end
        end

        res = found || args[0]
        $RESOLVED_BITMAP_CACHE[k] = res
        return __switch_native_bitmap_init(res)
      end
      __switch_native_bitmap_init(*args)
    end
  end
end

module ::Audio
  class << self
    unless method_defined?(:__switch_native_bgm_play)
      alias __switch_native_bgm_play bgm_play rescue nil
      alias __switch_native_bgm_stop bgm_stop rescue nil
      alias __switch_native_bgm_fade bgm_fade rescue nil
      alias __switch_native_bgs_play bgs_play rescue nil
      alias __switch_native_bgs_stop bgs_stop rescue nil
      alias __switch_native_bgs_fade bgs_fade rescue nil
      alias __switch_native_se_play se_play rescue nil
      alias __switch_native_se_stop se_stop rescue nil
      alias __switch_native_me_stop me_stop rescue nil
      alias __switch_native_me_fade me_fade rescue nil
    end

    $LAST_SE_TIME ||= {}

    def resolve_audio_file(path, exts = nil, default_dir = "Audio/SE")
      return "" if path.nil? || path.to_s.empty?
      p = path.to_s.gsub("\\", "/").gsub(/\.\.\//, "").sub(/^\/+/, "")
      cache_key = "#{p}_#{default_dir}"
      cached = $RESOLVE_AUDIO_MEMO_CACHE[cache_key]
      return cached if cached

      p_down = p.downcase
      p_clean = p_down.sub(/\.[^.]+$/, "")
      base = File.basename(p)
      base_down = base.downcase
      base_clean = base_down.sub(/\.[^.]+$/, "")
      def_down = default_dir.to_s.downcase
      def_clean = def_down.sub(/^audio\//i, "")

      if defined?($AUDIO_LOOKUP_TABLE) && $AUDIO_LOOKUP_TABLE && !$AUDIO_LOOKUP_TABLE.empty?
        # 1. Búsqueda calificada con el default_dir
        found = $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_down}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_clean}/#{base_down}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_clean}/#{base_clean}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete(' ')}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete('_')}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete('-')}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete(' _-')}"]

        # 2. Si la ruta original ya especificaba una carpeta o prefijo Audio/
        if !found && (p.start_with?("Audio/") || p.start_with?("audio/") || p.include?("/"))
          found = $AUDIO_LOOKUP_TABLE[p_down] ||
                  $AUDIO_LOOKUP_TABLE[p_clean] ||
                  $AUDIO_LOOKUP_TABLE["audio/" + p_down] ||
                  $AUDIO_LOOKUP_TABLE["audio/" + p_clean]
        end

        # 3. Probar extensiones .wav y .ogg prioritarias bajo default_dir
        if !found
          clean_p = p.sub(/\.[^.]+$/, "")
          cand = p.start_with?("Audio/") ? clean_p : (default_dir + "/" + clean_p)
          [cand + ".wav", cand + ".ogg", cand + ".mp3", (default_dir + "/" + p)].each do |test_f|
            t_down = test_f.downcase
            if $AUDIO_LOOKUP_TABLE[t_down]
              found = $AUDIO_LOOKUP_TABLE[t_down]
              break
            end
          end
        end

        # 4. Respaldo por nombre base SOLO si pertenece al default_dir solicitado
        if !found
          cand_base = $AUDIO_LOOKUP_TABLE[base_clean] ||
                      $AUDIO_LOOKUP_TABLE[base_down] ||
                      $AUDIO_LOOKUP_TABLE[base_clean.delete(" ")] ||
                      $AUDIO_LOOKUP_TABLE[base_clean.delete("_")] ||
                      $AUDIO_LOOKUP_TABLE[base_clean.delete("-")] ||
                      $AUDIO_LOOKUP_TABLE[base_clean.delete(" _-")]
          if cand_base && (default_dir.to_s.empty? || cand_base.downcase.start_with?(def_down) || cand_base.downcase.start_with?("audio/" + def_clean))
            found = cand_base
          end
        end

        if found && !found.empty?
          $RESOLVE_AUDIO_MEMO_CACHE[cache_key] = found
          return found
        end
      end

      res = (p.end_with?(".wav") || p.end_with?(".ogg") || p.end_with?(".mp3")) ? (p.start_with?("Audio/") ? p : "#{default_dir}/#{p}") : ""
      $RESOLVE_AUDIO_MEMO_CACHE[cache_key] = res if res && !res.empty?
      return res
    end

    def bgm_play(filename, volume = 100, pitch = 100, pos = 0.0, track = nil)
      return if filename.nil? || filename.to_s.empty?
      file = resolve_audio_file(filename, nil, "Audio/BGM")
      file = filename.to_s if file.nil? || file.empty?
      if file.empty?
        file = ["Audio/BGM/Title.ogg", "Audio/BGM/title_frlg.ogg", "Audio/BGM/title_origin.ogg", "Audio/BGM/title_bw.ogg"].find { |f| File.exist?(f) } || "Audio/BGM/Title.ogg"
      end
      vol = [(volume || 100).to_i, 1].max # Asegurar que volumen nunca quede en 0
      pit = (pitch || 100).to_i

      __switch_native_bgm_stop rescue nil
      if track
        __switch_native_bgm_play(file, vol, pit, (pos || 0.0).to_f, track) rescue (__switch_native_bgm_play(file, vol, pit, (pos || 0.0).to_f) rescue nil)
      else
        __switch_native_bgm_play(file, vol, pit, (pos || 0.0).to_f) rescue nil
      end
    rescue Exception
    end

    def bgm_stop(track = nil)
      if track
        __switch_native_bgm_stop(track) rescue (__switch_native_bgm_stop rescue nil)
      else
        __switch_native_bgm_stop rescue nil
      end
    rescue Exception
    end

    def bgm_fade(time, track = nil)
      t = (time || 0.8).to_f
      fade_ms = (t <= 10.0 ? (t * 1000) : t).to_i
      fade_ms = 100 if fade_ms <= 0
      if track
        __switch_native_bgm_fade(fade_ms, track) rescue (__switch_native_bgm_fade(fade_ms) rescue nil)
      else
        __switch_native_bgm_fade(fade_ms) rescue nil
      end
    rescue Exception
    end

    def bgs_stop
      __switch_native_bgs_stop rescue nil
    rescue Exception
    end

    def bgs_fade(time = 0.8)
      t = (time || 0.8).to_f
      fade_ms = (t <= 10.0 ? (t * 1000) : t).to_i
      fade_ms = 100 if fade_ms <= 0
      __switch_native_bgs_fade(fade_ms) rescue nil
    rescue Exception
    end

    def se_stop
      __switch_native_se_stop rescue nil
    rescue Exception
    end

    def bgs_play(filename, volume = 100, pitch = 100, pos = 0.0)
      return if filename.nil? || filename.to_s.empty?
      file = resolve_audio_file(filename, nil, "Audio/BGS")
      file = filename.to_s if file.nil? || file.empty?
      __switch_native_bgs_play(file, (volume || 100).to_i, (pitch || 100).to_i, (pos || 0.0).to_f) rescue nil
    rescue Exception
    end

    # Canal ME nativo redirigido a canal de efectos para nunca cortar ni perder la BGM
    def me_play(filename, volume = 100, pitch = 100)
      return if filename.nil? || filename.to_s.empty?
      file = resolve_audio_file(filename, nil, "Audio/ME")
      file = filename.to_s if file.nil? || file.empty?
      se_play(file, (volume || 100).to_i, (pitch || 100).to_i)
    rescue Exception
    end

    def me_stop
      # No-op para asegurar que la musica de fondo continue sin cortes
    end

    def me_fade(time)
      # No-op para asegurar que la musica de fondo continue sin cortes
    end

    def se_play(filename, volume = 100, pitch = 100)
      return if filename.nil? || filename.to_s.empty?
      file = resolve_audio_file(filename, nil, "Audio/SE")
      file = filename.to_s if file.nil? || file.empty?

      now = Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue (Time.now.to_f rescue 0.0)

      # Debounce de 15ms para evitar saturación de llamadas idénticas en el mismo cuadro
      last = $LAST_SE_TIME[file]
      if last && (now - last) < 0.015 && volume.to_i > 0
        return
      end
      $LAST_SE_TIME[file] = now
      $LAST_SE_TIME.clear if $LAST_SE_TIME.length > 200

      __switch_native_se_play(file, (volume || 100).to_i, (pitch || 100).to_i) rescue nil
    rescue Exception
    end
  end
end

def warmup_audio_buffers!
  return if $CORE_AUDIO_BUFFERS_WARMED
  $CORE_AUDIO_BUFFERS_WARMED = true

  common_ses = [
    "GUI menu open", "GUI sel cursor", "GUI sel decision", "GUI sel cancel"
  ]

  common_ses.each do |se_name|
    begin
      resolved = ::Audio.resolve_audio_file(se_name, nil, "Audio/SE")
      if resolved && !resolved.empty?
        ::Audio.__switch_native_se_play(resolved, 0, 100) rescue nil
      end
    rescue Exception
    end
  end
  ::Audio.se_stop rescue nil
end

warmup_audio_buffers! rescue nil

class AnimFrame
  X          = 0
  Y          = 1
  ZOOMX      = 2
  ANGLE      = 3
  MIRROR     = 4
  BLENDTYPE  = 5
  VISIBLE    = 6
  PATTERN    = 7
  OPACITY    = 8
  ZOOMY      = 11
  COLORRED   = 12
  COLORGREEN = 13
  COLORBLUE  = 14
  COLORALPHA = 15
  TONERED    = 16
  TONEGREEN  = 17
  TONEBLUE   = 18
  TONEGRAY   = 19
  LOCKED     = 20
  FLASHRED   = 21
  FLASHGREEN = 22
  FLASHBLUE  = 23
  FLASHALPHA = 24
  PRIORITY   = 25
  FOCUS      = 26
end unless defined?(AnimFrame)

class PBAnimTiming
  attr_accessor :frame
  attr_writer   :timingType
  attr_accessor :name
  attr_accessor :volume
  attr_accessor :pitch
  attr_accessor :bgX
  attr_accessor :bgY
  attr_accessor :opacity
  attr_accessor :colorRed
  attr_accessor :colorGreen
  attr_accessor :colorBlue
  attr_accessor :colorAlpha
  attr_writer   :duration
  attr_accessor :flashScope
  attr_accessor :flashColor
  attr_accessor :flashDuration

  def initialize(type = 0)
    @frame         = 0
    @timingType    = type
    @name          = ""
    @volume        = 80
    @pitch         = 100
    @duration      = 5
    @flashScope    = 0
    @flashColor    = (Color.white rescue nil)
    @flashDuration = 5
  end

  def timingType; @timingType || 0; end
  def duration; @duration || 5; end
end unless defined?(PBAnimTiming)

class PBAnimation < Array
  include Enumerable
  attr_accessor :id, :name, :graphic, :hue, :position, :speed, :array, :timing
  MAX_SPRITES = 60

  def speed; @speed || 20; end
  def initialize(size = 1)
    @id = -1; @name = ""; @graphic = ""; @hue = 0; @position = 4; @array = []; @timing = []; @scope = 0
  end
  def length; (@array ? @array.length : super); end
  def each; if @array then @array.each { |i| yield i } else super { |i| yield i } end; end
  def [](i); (@array ? @array[i] : super(i)); end
  def []=(i, value); if @array then @array[i] = value else super(i, value) end; end
end unless defined?(PBAnimation)

class PBAnimations < Array
  include Enumerable
  attr_reader   :array
  attr_accessor :selected

  def initialize(size = 1)
    @array = []; @selected = 0
  end
  def length; (@array ? @array.length : super); end
  def empty?; (@array ? @array.empty? : super rescue true); end
  def each; if @array then @array.each { |i| yield i } else super { |i| yield i } end; end
  def [](i); (@array ? @array[i] : super(i)); end
  def []=(i, value); if @array then @array[i] = value else super(i, value) end; end
  def get_from_name(name)
    list = @array || self
    list.each { |i| return i if i&.name == name }
    nil
  end
end unless defined?(PBAnimations)

def warmup_core_switch_audio!
  # No-op en arranque para velocidad instantánea
end

def prewarm_pause_menu_graphics!
  # No-op en arranque para velocidad instantánea
end

warmup_core_switch_audio!
prewarm_pause_menu_graphics!

module TrainerSensor
  BAR_OPACITY = 32 unless defined?(BAR_OPACITY)
  SELF_SWITCH = "A" unless defined?(SELF_SWITCH)
  BAR_HEIGHT  = 64 unless defined?(BAR_HEIGHT)
  BAR_GRAPHIC = "" unless defined?(BAR_GRAPHIC)
end

class PokemonSystem
  def battlescene
    @battlescene || 0
  end
  def battlescene=(val)
    @battlescene = (val || 0).to_i
  end
  def battlestyle
    @battlestyle || 0
  end
  def battlestyle=(val)
    @battlestyle = (val || 0).to_i
  end
end

class Battle
  def showAnims
    true
  end
  def showAnims=(val)
    @showAnims = true
  end
end


$FILE_EXIST_CACHE ||= {}
$DIR_EXIST_CACHE  ||= {}

def switch_invalidate_file_cache(p)
  return if !p.is_a?(String)
  $FILE_EXIST_CACHE.delete(p)
  $FILE_EXIST_CACHE.delete("./" + p)
  $FILE_EXIST_CACHE.delete(p.sub(/\A\.\//, ""))
rescue
  nil
end

def switch_invalidate_dir_cache(p)
  return if !p.is_a?(String)
  $DIR_EXIST_CACHE.delete(p)
  $DIR_EXIST_CACHE.delete("./" + p)
  $DIR_EXIST_CACHE.delete(p.sub(/\A\.\//, ""))
rescue
  nil
end

class << Dir
  unless method_defined?(:__switch_orig_mkdir)
    alias __switch_orig_mkdir mkdir rescue nil
  end
  unless method_defined?(:__switch_orig_rmdir)
    alias __switch_orig_rmdir rmdir rescue nil
  end

  def mkdir(path, *args)
    switch_invalidate_dir_cache(path.to_s)
    __switch_orig_mkdir(path, *args)
  rescue Errno::EEXIST, Errno::EACCES
    0
  rescue Exception => e
    0
  end

  def rmdir(path, *args)
    switch_invalidate_dir_cache(path.to_s)
    __switch_orig_rmdir(path, *args)
  end
end



def getPlayTime(filename)
  120.0
end

def getPlayTime2(filename)
  120.0
end

class ::Sprite
  def center!(snap = false)
    if self.bitmap
      self.ox = (self.bitmap.width / 2 rescue 0)
      self.oy = (self.bitmap.height / 2 rescue 0)
    end
    if snap && self.viewport
      self.x = (self.viewport.rect.width / 2 rescue 0)
      self.y = (self.viewport.rect.height / 2 rescue 0)
    end
  end

  def bottom!(snap = false)
    if self.bitmap
      self.ox = (self.bitmap.width / 2 rescue 0)
      self.oy = (self.bitmap.height rescue 0)
    end
  end

  def center
    [self.width / 2, self.height / 2] rescue [0, 0]
  end

  def bottom
    [self.width / 2, self.height] rescue [0, 0]
  end

  def id?(val = nil)
    false
  end

  def create_outline(color = nil, thickness = 2)
    false
  end

  def colorize(color = nil, amt = 255)
    false
  end

  def glow(color = nil, opacity = 35, keep = true)
    false
  end

  def fuzz(color = nil, opacity = 35)
    false
  end

  def blur_sprite(blur_val = 2, opacity = 35)
    false
  end
end

class ::Object
  def id?(val = nil)
    false
  end
end

module ::RPG
  class EventCommand
    attr_accessor :code, :indent, :parameters
    def initialize(code = 0, indent = 0, parameters = [])
      @code = code
      @indent = indent
      @parameters = parameters
    end
  end

  class MoveRoute
    attr_accessor :repeat, :skippable, :wait, :list
    def initialize
      @repeat = true
      @skippable = false
      @wait = false
      @list = []
    end
  end

  class MoveCommand
    attr_accessor :code, :parameters
    def initialize(code = 0, parameters = [])
      @code = code
      @parameters = parameters
    end
  end
end



# 1.13 Graphics
module ::Graphics
  class << self
    def show_cursor; false; end
    
    def fullscreen; true; end
    
    def scale; 1.0; end
    
    def center; end
    def width; 512; end
    def height; 384; end
    def frame_rate; @frame_rate || 40; end
    def frame_rate=(val); @frame_rate = val; end
    def average_frame_rate; 40.0; end
  end
end

module ::Graphics
  class << self
    alias __orig_fullscreen= fullscreen= rescue nil
    def fullscreen=(val)
      __orig_fullscreen=(true) rescue nil
    end
  end
end

def pbSetResizeFactor(factor = 1)
  if factor == 1
    Graphics.fixed_aspect_ratio = true rescue nil
  else
    Graphics.fixed_aspect_ratio = false rescue nil
  end
  Graphics.integer_scaling = false rescue nil
  Graphics.smooth_scaling = 3 rescue nil
  Graphics.fullscreen = true rescue nil
end
def pbSetWindowText(string = ""); end
def pbGetPlayerCharset(charset = nil, *args)
  return "" if charset.nil?
  charset.to_s
end

module ::System
  class << self
    def uptime
      Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue (Time.now.to_f rescue 0.0)
    end
    def unscaled_uptime
      uptime
    end
    def real_uptime
      uptime
    end
    def data_directory
      "."
    end
  end
end

def pbWait(duration)
  duration = duration.to_f
  timer_start = (System.uptime rescue Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f)
  frames = 0
  max_frames = (duration * 40).ceil + 20
  while frames < max_frames
    now = (System.uptime rescue Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f)
    break if now - timer_start >= duration
    frames += 1
    yield now - timer_start if block_given?
    Graphics.update rescue nil
    Input.update rescue nil
    pbUpdateSceneMap rescue nil
  end
end


# 1.14 File, Dir, FileTest compatibilidad con Super Cache en RAM para Nintendo Switch
$FILE_EXIST_CACHE ||= {}
$DIR_EXIST_CACHE  ||= {}

class ::Dir
  class << self
    def exist?(path)
      return false if path.nil?
      p = path.to_s.tr("\\", "/")
      return true if p == "." || p == ""
      cached = $DIR_EXIST_CACHE[p]
      return cached unless cached.nil?
      res = ((Dir.entries(p) rescue nil) != nil)
      $DIR_EXIST_CACHE[p] = res
      res
    end
    def exists?(path); exist?(path); end
    def pwd; "."; end
    def getwd; pwd; end
  end
end

class ::File
  class << self
    unless method_defined?(:__switch_orig_file_open)
      alias __switch_orig_file_open open rescue nil
    end
    unless method_defined?(:__switch_orig_file_new)
      alias __switch_orig_file_new new rescue nil
    end
    unless method_defined?(:__switch_orig_file_delete)
      alias __switch_orig_file_delete delete rescue nil
    end
    unless method_defined?(:__switch_orig_file_unlink)
      alias __switch_orig_file_unlink unlink rescue nil
    end
    unless method_defined?(:__switch_orig_file_rename)
      alias __switch_orig_file_rename rename rescue nil
    end

    def open(path, *args, &block)
      mode = args[0]
      if mode.is_a?(String) && (mode.include?("w") || mode.include?("a") || mode.include?("+"))
        switch_invalidate_file_cache(path.to_s)
      elsif mode.is_a?(Integer) && (mode & (::File::WRONLY | ::File::RDWR | ::File::CREAT | ::File::APPEND) != 0)
        switch_invalidate_file_cache(path.to_s)
      end
      __switch_orig_file_open(path, *args, &block)
    end

    def new(path, *args, &block)
      mode = args[0]
      if mode.is_a?(String) && (mode.include?("w") || mode.include?("a") || mode.include?("+"))
        switch_invalidate_file_cache(path.to_s)
      elsif mode.is_a?(Integer) && (mode & (::File::WRONLY | ::File::RDWR | ::File::CREAT | ::File::APPEND) != 0)
        switch_invalidate_file_cache(path.to_s)
      end
      __switch_orig_file_new(path, *args, &block)
    end

    def delete(*paths)
      paths.each { |p| switch_invalidate_file_cache(p.to_s) }
      __switch_orig_file_delete(*paths)
    end

    def unlink(*paths)
      paths.each { |p| switch_invalidate_file_cache(p.to_s) }
      __switch_orig_file_unlink(*paths)
    end

    def rename(old_name, new_name)
      switch_invalidate_file_cache(old_name.to_s)
      switch_invalidate_file_cache(new_name.to_s)
      __switch_orig_file_rename(old_name, new_name)
    end

    def directory?(path); ::Dir.exist?(path); end
    def file?(path)
      return false if path.nil? || ::Dir.exist?(path)
      exist?(path)
    end
    def exist?(path)
      return false if path.nil? || path.to_s.empty?
      p = path.to_s.gsub("\\", "/")
      cached = $FILE_EXIST_CACHE[p]
      return cached unless cached.nil?

      if defined?($AUDIO_LOOKUP_TABLE) && $AUDIO_LOOKUP_TABLE && $AUDIO_LOOKUP_TABLE.length > 0
        p_down = p.downcase
        if $AUDIO_LOOKUP_TABLE.has_key?(p_down) || $AUDIO_LOOKUP_TABLE.has_key?(File.basename(p_down))
          $FILE_EXIST_CACHE[p] = true
          return true
        end
      end

      if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE && $GRAPHICS_LOOKUP_TABLE.length > 0
        p_down = p.downcase
        if $GRAPHICS_LOOKUP_TABLE.has_key?(p_down) || $GRAPHICS_LOOKUP_TABLE.has_key?(p_down.sub(/\A\.\//, ""))
          $FILE_EXIST_CACHE[p] = true
          return true
        end
      end

      if defined?($RESOLVED_BITMAP_CACHE) && $RESOLVED_BITMAP_CACHE && $RESOLVED_BITMAP_CACHE.has_key?(p)
        res = !!$RESOLVED_BITMAP_CACHE[p]
        $FILE_EXIST_CACHE[p] = res
        return res
      end

      res = (open(p, "rb") { true } rescue false)
      res = ::Dir.exist?(p) if !res
      writable = (p =~ /\.(rxdata|bak|sav|log|txt|dat|tmp)$/i || p.include?("options"))
      $FILE_EXIST_CACHE[p] = res if !writable
      res
    end
    def exists?(path); exist?(path); end
    def join(*args)
      args.flatten.compact.map(&:to_s).join("/").gsub(%r{/+}, "/")
    end
    def basename(*args)
      return "" if args.empty? || args[0].nil?
      path = args[0].to_s.gsub("\\", "/")
      base = path.split("/").last || ""
      if args[1]
        ext = args[1].to_s
        base = base.sub(/#{Regexp.escape(ext)}$/, '') if ext.length > 0
      end
      base
    end
    def extname(*args)
      return "" if args.empty? || args[0].nil?
      path = args[0].to_s.gsub("\\", "/")
      base = path.split("/").last || ""
      dot = base.rindex(".")
      return "" if !dot || dot == 0
      base[dot..-1]
    end
    def dirname(*args)
      return "." if args.empty? || args[0].nil?
      path = args[0].to_s.gsub("\\", "/")
      parts = path.split("/")
      return "." if parts.length <= 1
      parts.pop
      parts.join("/")
    end
    def copy(src, dst)
      switch_invalidate_file_cache(dst.to_s)
      open(src, "rb") { |r| open(dst, "wb") { |w| w.write(r.read) } } rescue nil
    end
    def move(src, dst)
      switch_invalidate_file_cache(src.to_s)
      switch_invalidate_file_cache(dst.to_s)
      copy(src, dst)
      delete(src) rescue nil
    end
    def read(path)
      open(path, "rb") { |f| f.read } rescue ""
    end
  end
end

module ::FileTest
  def self.directory?(path); ::Dir.exist?(path); end
  def self.file?(path); ::File.file?(path); end
  def self.exist?(path); ::File.exist?(path); end
  def self.exists?(path); ::File.exist?(path); end
  def self.size(path); ::File.size(path) rescue 0; end

  def self.audio_exist?(filename)
    return false if filename.nil? || filename.to_s.empty?
    fn = filename.to_s.gsub("\\", "/").downcase
    base_fn = File.basename(fn)
    base_clean = base_fn.sub(/\.[^.]+$/, "")
    if defined?($AUDIO_LOOKUP_TABLE) && $AUDIO_LOOKUP_TABLE && !$AUDIO_LOOKUP_TABLE.empty?
      return true if $AUDIO_LOOKUP_TABLE.has_key?(fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?(fn.sub(/\.[^.]+$/, "")) ||
                     $AUDIO_LOOKUP_TABLE.has_key?("audio/" + fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?("audio/bgm/" + fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?("audio/se/" + fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?("audio/me/" + fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?("audio/bgs/" + fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?("audio/se/cries/" + fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?("audio/se/anim/" + fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?(base_fn) ||
                     $AUDIO_LOOKUP_TABLE.has_key?(base_clean) ||
                     $AUDIO_LOOKUP_TABLE.has_key?(base_clean.delete(" ")) ||
                     $AUDIO_LOOKUP_TABLE.has_key?(base_clean.delete("_")) ||
                     $AUDIO_LOOKUP_TABLE.has_key?(base_clean.delete("-")) ||
                     $AUDIO_LOOKUP_TABLE.has_key?(base_clean.delete(" _-"))
    end
    return false
  end

  def self.image_exist?(filename)
    return false if filename.nil? || filename.to_s.empty?
    fn = filename.to_s.gsub("\\", "/").downcase
    base_fn = File.basename(fn)
    base_clean = base_fn.sub(/\.[^.]+$/, "")
    if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE && !$GRAPHICS_LOOKUP_TABLE.empty?
      return true if $GRAPHICS_LOOKUP_TABLE.has_key?(fn) ||
                     $GRAPHICS_LOOKUP_TABLE.has_key?(fn.sub(/\.[^.]+$/, "")) ||
                     $GRAPHICS_LOOKUP_TABLE.has_key?("graphics/" + fn) ||
                     $GRAPHICS_LOOKUP_TABLE.has_key?("graphics/characters/" + fn) ||
                     $GRAPHICS_LOOKUP_TABLE.has_key?("graphics/pictures/" + fn) ||
                     $GRAPHICS_LOOKUP_TABLE.has_key?(base_fn) ||
                     $GRAPHICS_LOOKUP_TABLE.has_key?(base_clean)
    end
    return false
  end

  def directory?(path); ::Dir.exist?(path); end
  def file?(path); ::File.file?(path); end
  def exist?(path); ::File.exist?(path); end
  def exists?(path); ::File.exist?(path); end
  module_function :directory?, :file?, :exist?, :exists?, :size rescue nil
end



# 1.15 DebugConsole y Console
module Kernel
  def echo(str = ""); puts(str) if $DEBUG; end
  def echoln(str = ""); puts(str) if $DEBUG; end
  module_function :echo, :echoln rescue nil
end

module Console
  def self.echo(str = "")
    puts(str) if $DEBUG
  end
  def self.echoln(str = "")
    puts(str) if $DEBUG
  end
  def self.echo_h1(str = "")
    puts("*** #{str} ***") if $DEBUG
  end
  def self.echo_h2(str = "", **opts)
    puts(str) if $DEBUG
  end
  def self.echo_h3(str = "")
    puts(str) if $DEBUG
  end
  def self.echo_li(str = "", *args)
    puts("  -> #{str}") if $DEBUG
  end
  def self.echoln_li(str = "", *args)
    puts("  -> #{str}") if $DEBUG
  end
  def self.echoln_li_done(str = "")
    puts("  -> #{str} (listo)") if $DEBUG
  end
end

# 1.15 Extensiones de clases base de Ruby (String, Numeric, Array, NilClass, Class)
class ::String
  def starts_with_vowel?
    ["a", "e", "i", "o", "u"].include?(self[0]&.downcase)
  end

  def first(n = 1)
    n == 1 ? (self[0] || "") : (self[0...n] || "")
  end

  def last(n = 1)
    n == 1 ? (self[-1] || "") : (self[[-n, 0].max..-1] || "")
  end

  def blank?
    strip.empty?
  end
end

class ::NilClass
  def blank?
    true
  end

  def trainer_type; :POKEMONTRAINER_Red; end
  def male?; true; end
  def female?; false; end
  def gender; 0; end
  def walk_charset; ""; end
  def run_charset; ""; end
  def cycle_charset; ""; end
  def surf_charset; ""; end
  def dive_charset; ""; end
  def fish_charset; ""; end
  def surf_fish_charset; ""; end
  def home; nil; end
  def name; ""; end
  def character_ID; 1; end
end

class ::Numeric
  def to_digits(digits = 3)
    sprintf("%0*d", digits, self)
  end

  def to_s_formatted
    to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end
end

class ::Integer
  def to_s_formatted
    to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end
end

class ::Float
  def to_s_formatted
    to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end
end

class ::Array
  include Enumerable

  def each_with_index(&block)
    return to_enum(:each_with_index) unless block_given?
    idx = 0
    each do |item|
      yield(item, idx)
      idx += 1
    end
    self
  end

  def extract_options!
    last.is_a?(Hash) ? pop : {}
  end

  def compact!
    delete_if(&:nil?)
    self
  end
end

class ::Class
  def to_sym
    to_s.to_sym
  end
end

module Kernel
  Console = ::Console
end

# 1.16 Kernel Helpers y Validate
module Kernel
  def validate(*args); end
  module_function :validate rescue nil
  public :validate rescue nil

  def print(*args)
    text = args.map(&:to_s).join
    puts text
    if defined?($log_file) && $log_file
      $log_file.puts(text)
      $log_file.flush
    end
  rescue
    nil
  end
  module_function :print rescue nil
  public :print rescue nil
end

class Object
  def validate(*args); end
  def print(*args)
    Kernel.print(*args)
  end
  def max_party_size
    Kernel.max_party_size
  end
end

class Module
  def validate(*args); end
  def max_party_size
    Kernel.max_party_size
  end
end

module Kernel
  def max_party_size
    return Settings::MAX_PARTY_SIZE rescue 6 if !defined?(ChallengeModes) || !defined?(ChallengeModes.on?) || !ChallengeModes.on?(:PERMALOCKE)
    if defined?($PokemonGlobal) && $PokemonGlobal
      $PokemonGlobal.max_party_size ||= (Settings::MAX_PARTY_SIZE rescue 6)
      return $PokemonGlobal.max_party_size
    end
    return (Settings::MAX_PARTY_SIZE rescue 6)
  end
  module_function :max_party_size
end

module ::ModularTitle
  MODIFIERS       = ["intro:2", "logoY:280", "logo:shine", "effect8", "logo:glow", "bgm:Titulo"] unless defined?(MODIFIERS)
  MOSTRAR_GRITO   = false unless defined?(MOSTRAR_GRITO)
  SPECIES         = :PIKACHU unless defined?(SPECIES)
  SPECIES_FORM    = 0 unless defined?(SPECIES_FORM)
  SPECIES_FEMALE  = false unless defined?(SPECIES_FEMALE)
  SPECIES_SHINY   = false unless defined?(SPECIES_SHINY)
  SPECIES_BACK    = false unless defined?(SPECIES_BACK)
  START_POS       = [nil, nil] unless defined?(START_POS)
end
::MOSTRAR_PANEL_REP_EXP = true unless defined?(::MOSTRAR_PANEL_REP_EXP)

# 1.17 Interceptor de resolución de constantes (Module#const_missing)
$SWITCH_CONST_MISSING_SEEN ||= {}

class Module
  unless private_method_defined?(:__switch_orig_mod_const_missing) || method_defined?(:__switch_orig_mod_const_missing)
    alias __switch_orig_mod_const_missing const_missing rescue nil
  end

  def const_missing(name)
    return true if name == :MOSTRAR_PANEL_REP_EXP
    if ::Object.const_defined?(name, false)
      return ::Object.const_get(name)
    end
    if defined?(Kernel) && Kernel.const_defined?(name, false)
      return Kernel.const_get(name)
    end
    if defined?(GameData) && GameData.const_defined?(name, false)
      return GameData.const_get(name)
    end
    if defined?(::Input) && (self == ::Input || (defined?(Kernel::Input) && self == Kernel::Input))
      if ::Input.const_defined?(name, false)
        return ::Input.const_get(name)
      end
    end
    # Resilient fallback dummy class for Marshal.load (Fase A: sin const_set contaminante)
    if !$SWITCH_CONST_MISSING_SEEN[name]
      $SWITCH_CONST_MISSING_SEEN[name] = true
      log_compat("[const_missing] #{self}::#{name}") rescue nil
    end
    return Class.new
  end
end

$ORIGINAL_KERNEL_EVAL ||= Kernel.method(:eval)

module Kernel
  # Limpiar constantes si se hubieran definido erróneamente en Kernel
  [:Viewport, :Sprite, :Plane, :Window, :Tilemap, :Bitmap, :Rect, :Color, :Tone, :Font, :Battle, :RecordedBattle].each do |c|
    if Kernel.const_defined?(c, false)
      Kernel.send(:remove_const, c) rescue nil
    end
  end

  def tsOff?(c)
    if defined?(@map_id) && defined?(@event) && @event
      return !$game_self_switches[[@map_id, @event.id, c]]
    elsif defined?($game_map) && $game_map
      return true
    end
    return true
  end

  def tsOn?(c)
    if defined?(@map_id) && defined?(@event) && @event
      return !(!$game_self_switches[[@map_id, @event.id, c]])
    end
    return false
  end

  def isTempSwitchOff?(c); tsOff?(c); end
  def isTempSwitchOn?(c); tsOn?(c); end
  
  def get_self
    if defined?($game_map) && $game_map
      if defined?(@event_id) && @event_id && @event_id > 0
        return $game_map.events[@event_id]
      elsif defined?(@event) && @event
        return @event
      elsif defined?($game_player)
        return $game_map.events.values.find { |e| e.onEvent? rescue false } || $game_player
      end
    end
    $game_player if defined?($game_player)
  end
  module_function :tsOff?, :tsOn?, :isTempSwitchOff?, :isTempSwitchOn?, :get_self rescue nil

  def eval(src, *args, &block)
    # Si se evalúa una simple expresión/código sin parámetros de archivo/binding, usar el eval nativo en C
    if args.empty? && block.nil?
      return $ORIGINAL_KERNEL_EVAL.call(src)
    end

    # Si el primer argumento es un Binding explícito o nil, procesarlo; de lo contrario usar TOPLEVEL_BINDING
    if args.length > 0 && (args[0].is_a?(Binding) || args[0].nil?)
      b = args.shift
      target_binding = b if b.is_a?(Binding)
    end
    target_binding ||= TOPLEVEL_BINDING

    filename = (args[0].is_a?(String) ? args[0] : "(eval)")
    lineno = (args[1].is_a?(Integer) ? args[1] : 1)

    # No modificar preload.rb si se llega a evaluar de nuevo
    if filename == "preload.rb" || (src.is_a?(String) && src.include?("[Switch Compatibility]"))
      return target_binding.eval(src, filename, lineno)
    end

    if src.is_a?(String)
      begin
        src = src.dup.force_encoding(Encoding::UTF_8)
        src = src.scrub("") if src.respond_to?(:scrub)
      rescue Exception
        src = src.force_encoding("UTF-8") rescue src
      end
      if src.include?("mkxp_draw_text")
        src = src.gsub(/class\s+Bitmap\b.*?alias\s+mkxp_draw_text\s+draw_text.*?end\b/m, '# Bitmap handled by preload')
      end
      if src.include?("update_KGC_ScreenCapture")
        src = src.gsub(/alias\s+update_KGC_ScreenCapture\s+update/, "alias update_KGC_ScreenCapture update unless method_defined?(:update_KGC_ScreenCapture)")
      end
      # Cada gsub va detras de una guarda String#include? con una subcadena que la expresion
      # regular EXIGE obligatoriamente para poder casar. Son guardas superset: si la guarda
      # falla, la regex tampoco podia casar, asi que la semantica es identica.
      # Motivo: este eval intercepta la evaluacion de los 437 scripts del motor y los 320
      # ficheros de plugin, unos 10,5 MB de fuente. Sin guardas, cada gsub recorre ese texto
      # entero con Onigmo (~10-20 MB/s) y ademas devuelve una copia nueva del String aunque no
      # haya ninguna coincidencia. include? es un memmem del orden de 1 GB/s y no copia nada.
      src = src.gsub(/module\s+Graphics\b/, 'module ::Graphics') if src.include?("Graphics")
      src = src.gsub(/module\s+Input\b/, 'module ::Input') if src.include?("Input")
      src = src.gsub(/module\s+Audio\b/, 'module ::Audio') if src.include?("Audio")
      src = src.gsub(/class\s+(Rect|Color|Tone)\s*<\s*Object/m, 'class \1') if src.include?("Object")
      if src.include?("GameStats") || src.include?("Game_Temp") || src.include?("PokemonSystem")
        src = src.gsub(/class\s+(GameStats|Game_Temp|PokemonSystem)\s*<\s*\1/m, 'class \1')
      end
      if src.include?("ScrollingSprite") || src.include?("RainbowSprite") || src.include?("TrailingSprite")
        src = src.gsub(/class\s+(ScrollingSprite|RainbowSprite|TrailingSprite)\s*<\s*[\w:]+/m, 'class \1')
      end
      if src.include?("Player")
        src = src.gsub(/class\s+Player\b(?!\s*<\s*Trainer)/, 'class Trainer; end unless defined?(Trainer); class Player < Trainer')
      end
      if src.include?("initialize_bootup_values")
        src = src.gsub(/(?<!::)\bSaveData\.initialize_bootup_values\b/, '(SaveData.respond_to?(:initialize_bootup_values) ? SaveData.initialize_bootup_values : nil)')
      end
      if src.include?("load_bootup_values")
        src = src.gsub(/(?<!::)\bSaveData\.load_bootup_values\((.*?)\)/, '(SaveData.respond_to?(:load_bootup_values) ? SaveData.load_bootup_values(\1) : nil)')
      end
      if src.include?("pbSetResizeFactor")
        src = src.gsub(/def\s+pbSetResizeFactor\b.*?\nend\b/m, "def pbSetResizeFactor(factor = 1); Graphics.fixed_aspect_ratio = (factor == 1) rescue nil; Graphics.integer_scaling = false rescue nil; Graphics.smooth_scaling = 3 rescue nil; Graphics.fullscreen = true rescue nil; end")
      end
      if src.include?("fullscreen")
        src = src.gsub(/Graphics\.fullscreen\s*=\s*(?:false|!\s*Graphics\.fullscreen)/, 'Graphics.fullscreen = true')
      end
      if src.include?("Graphics.scale")
        src = src.gsub(/Graphics\.scale\s*=\s*[^\n;]+/, '# Graphics.scale skipped on Switch')
      end
      if src.include?("resize_screen")
        src = src.gsub(/Graphics\.resize_screen\b[^\n;]*/, '# Graphics.resize_screen skipped on Switch')
      end
      if src.include?("resize_window")
        src = src.gsub(/Graphics\.resize_window\b[^\n;]*/, '# Graphics.resize_window skipped on Switch')
      end
      if src.include?("pbShowCommands")
        src = src.gsub(/next\s+(?:Kernel\.)?pbShowCommands\(/, 'next send(:pbShowCommands, ')
        src = src.gsub(/next\s+(?:Kernel\.)?pbShowCommandsWithHelp\(/, 'next send(:pbShowCommandsWithHelp, ')
      end
      if src.include?("Kernel.pb")
        src = src.gsub(/Kernel\.pb([A-Za-z0-9_]+)/, 'pb\1')
      end
    end

    if filename && filename.is_a?(String) && (filename.include?("Plugins/") || filename.start_with?("["))
      log_compat("[Cargando Plugin] -> #{filename.gsub(/^Plugins\//, '')}") rescue nil
    end

    begin
      target_binding.eval(src, filename, lineno)
    rescue Exception => e
      if filename && filename.is_a?(String)
        log_compat("========================================") rescue nil
        log_compat("[ERROR EN SCRIPT] #{filename}") rescue nil
        log_compat("#{e.class}: #{e.message}") rescue nil
        log_compat(e.backtrace&.join("\n  ")) rescue nil
        log_compat("========================================") rescue nil
      end
      if (src.is_a?(String) && (src.include?("setBattleRule") || src.include?("midbattle"))) || e.message.to_s.include?("regla de combate") || e.message.to_s.include?("midbattle")
        return nil
      end
      raise e
    end
  end
  module_function :eval
end

class ::Object
  include Kernel
  def tsOff?(c); Kernel.tsOff?(c); end unless method_defined?(:tsOff?)
  def tsOn?(c); Kernel.tsOn?(c); end unless method_defined?(:tsOn?)
  def isTempSwitchOff?(c); Kernel.tsOff?(c); end unless method_defined?(:isTempSwitchOff?)
  def isTempSwitchOn?(c); Kernel.tsOn?(c); end unless method_defined?(:isTempSwitchOn?)
  def get_self; Kernel.get_self; end unless method_defined?(:get_self)
end

class ::Game_Character; end unless defined?(::Game_Character)
class ::Game_Player < ::Game_Character; end unless defined?(::Game_Player)
class ::Game_Event < ::Game_Character; end unless defined?(::Game_Event)

class ::Game_Character
  def onEvent?; true; end unless method_defined?(:onEvent?)
end



# Garantizar métodos de seguridad en Viewport y Sprite
if defined?(::Viewport)
  class ::Viewport
    def z=(val); @z = val; end unless method_defined?(:z=)
    def visible=(val); @visible = val; end unless method_defined?(:visible=)
    def visible; @visible != false; end unless method_defined?(:visible)
    def rect; @rect ||= Rect.new(0, 0, 640, 480); end unless method_defined?(:rect)
    def rect=(r); @rect = r; end unless method_defined?(:rect=)
    def color; @color ||= Color.new(0, 0, 0, 0); end unless method_defined?(:color)
    def tone; @tone ||= Tone.new(0, 0, 0, 0); end unless method_defined?(:tone)
    def ox; @ox ||= 0; end unless method_defined?(:ox)
    def ox=(val); @ox = val; end unless method_defined?(:ox=)
    def oy; @oy ||= 0; end unless method_defined?(:oy)
    def oy=(val); @oy = val; end unless method_defined?(:oy=)
  end
end

if defined?(::Sprite)
  class ::Sprite
    def visible=(val); @visible = val; end unless method_defined?(:visible=)
    def visible; @visible != false; end unless method_defined?(:visible)
    def z=(val); @z = val; end unless method_defined?(:z=)
    def z; @z ||= 0; end unless method_defined?(:z)
    def x=(val); @x = val; end unless method_defined?(:x=)
    def x; @x ||= 0; end unless method_defined?(:x)
    def y=(val); @y = val; end unless method_defined?(:y=)
    def y; @y ||= 0; end unless method_defined?(:y)
    def zoom_x=(val); @zoom_x = val; end unless method_defined?(:zoom_x=)
    def zoom_y=(val); @zoom_y = val; end unless method_defined?(:zoom_y=)
    def zoom_x; @zoom_x ||= 1.0; end unless method_defined?(:zoom_x)
    def zoom_y; @zoom_y ||= 1.0; end unless method_defined?(:zoom_y)
  end
end

# 1.19 Interceptor visual de errores de Essentials
def pbPrintException(e)
  msg = "========================================\n[ERROR VISUAL ESSENTIALS]\n#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}\n========================================"
  log_compat(msg)
  begin
    File.open("errorlog.txt", "a") { |f| f.puts(msg) }
  rescue Exception
  end
end

# 1.20 Stubs de Sockets y Red para plugins offline
def network_available?
  false
end

class SocketError < StandardError; end
class BasicSocket < IO; end

class Socket < BasicSocket
  AF_INET = 2
  AF_INET6 = 23
  AF_UNSPEC = 0
  SOCK_STREAM = 1
  SOCK_DGRAM = 2
  IPPROTO_TCP = 6
  IPPROTO_UDP = 17
  SOL_SOCKET = 65535
  SO_REUSEADDR = 4
  SO_KEEPALIVE = 8
  
  class Option
    def self.int(*args); new; end
    def self.bool(*args); new; end
    def self.linger(*args); new; end
  end
  
  def self.tcp(*args); TCPSocket.new; end
  def self.getaddrinfo(*args); []; end
  def self.sockaddr_in(*args); ""; end
  def self.pack_sockaddr_in(*args); ""; end
  def self.unpack_sockaddr_in(*args); [0, "127.0.0.1"]; end
end

class IPSocket < BasicSocket
  def addr; ["AF_INET", 0, "127.0.0.1", "127.0.0.1"]; end
  def peeraddr; ["AF_INET", 0, "127.0.0.1", "127.0.0.1"]; end
end

class TCPSocket < IPSocket
  def initialize(*args)
    log_compat("TCPSocket.new llamado con #{args.inspect} (stub Switch offline)")
  end
  def close; end
  def closed?; true; end
  def write(*args); 0; end
  def read(*args); ""; end
  def read_nonblock(*args); ""; end
  def write_nonblock(*args); 0; end
  def gets(*args); nil; end
  def print(*args); nil; end
  def puts(*args); nil; end
  def flush; end
  def setsockopt(*args); end
  def connect_nonblock(*args); end
end

class TCPServer < TCPSocket
  def accept; nil; end
  def accept_nonblock; nil; end
  def listen(*args); end
end

class UDPSocket < IPSocket
  def initialize(*args); end
  def send(*args); 0; end
  def recv(*args); ""; end
  def recvfrom(*args); ["", ["AF_INET", 0, "127.0.0.1", "127.0.0.1"]]; end
  def bind(*args); end
  def close; end
end

class IO
  def wait(*args); nil; end
  def wait_readable(*args); nil; end
  def wait_writable(*args); nil; end
  def nread; 0; end
  def ready?; false; end
  def nonblock?; true; end
  def nonblock=(val); end
end

# 1.21 Interceptor seguro de require
module Kernel
  alias __switch_prev_require require unless method_defined?(:__switch_prev_require) rescue nil
  def require(feature)
    f = feature.to_s.downcase
    case f
    when 'socket', 'io/wait', 'io/nonblock', 'openssl', 'digest', 'digest/md5', 'digest/sha1', 'digest/sha2', 'stringio', 'tempfile', 'net/http', 'net/https', 'uri', 'zlib', 'win32api'
      return true
    else
      begin
        __switch_prev_require(feature)
      rescue LoadError
        return false
      end
    end
  end
end

# 1.22 Interceptores de salida del sistema
module Kernel
  def exit(code = 0)
    log_compat("[Kernel.exit] Salida del sistema (#{code})...") rescue nil
    $scene = nil if defined?($scene)
    raise SystemExit.new(code.is_a?(Integer) ? code : 0)
  end

  def abort(msg = nil)
    log_compat("[Kernel.abort] Abortando: #{msg}") rescue nil
    $scene = nil if defined?($scene)
    raise SystemExit.new(1)
  end

  def exit!(code = 0)
    log_compat("[Kernel.exit!] Salida inmediata (#{code})...") rescue nil
    $scene = nil if defined?($scene)
    raise SystemExit.new(code.is_a?(Integer) ? code : 1)
  end
  module_function :exit, :abort, :exit! rescue nil
end

def exit(code = 0); Kernel.exit(code); end
def abort(msg = nil); Kernel.abort(msg); end
def exit!(code = 0); Kernel.exit!(code); end

module Process
  def self.exit(code = 0); Kernel.exit(code); end
  def self.exit!(code = 0); Kernel.exit!(code); end
  def self.abort(msg = nil); Kernel.abort(msg); end
end

def getKnownFolder(*args)
  Dir.pwd
end

def getFolder(*args)
  Dir.pwd
end

class Hash
  alias has_key? key? unless method_defined?(:has_key?) rescue nil

  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |k, v|
      tv = self[k]
      self[k] = if tv.is_a?(Hash) && v.is_a?(Hash)
        tv.deep_merge(v, &block)
      elsif block_given? && key?(k)
        block.call(k, tv, v)
      else
        v
      end
    end
    self
  end
end

# Stubs para Win32API
class Win32API
  attr_reader :dll_name, :func_name

  def initialize(dll_name, func_name, import_types = nil, return_type = nil)
    @dll_name = dll_name.to_s.downcase
    @func_name = func_name.to_s
    log_compat("Win32API registrado: #{@dll_name} -> #{@func_name}")
  end

  def call(*args)
    case @func_name
    when "GetSystemMetrics"
      index = args[0]
      return 1280 if index == 0 # SM_CXSCREEN
      return 720  if index == 1 # SM_CYSCREEN
      return 0
    when "GetPrivateProfileString", "GetPrivateProfileStringA"
      if args[3] && args[3].is_a?(String)
        args[3].replace(args[2].to_s)
      end
      return args[2].to_s.length
    when "GetAsyncKeyState", "GetKeyState"
      return 0
    when "FindWindow", "FindWindowA", "GetActiveWindow", "GetForegroundWindow"
      return 1
    when "SetWindowText", "SetWindowTextA", "SetWindowPos", "ShowWindow"
      return 1
    when "mciSendString", "mciSendStringA"
      return 0
    else
      return 0
    end
  end

  alias Call call
  alias [] call
end

class MiniFFI
  def initialize(dll_name, func_name, *args)
    @dll_name = dll_name.to_s
    @func_name = func_name.to_s
    log_compat("MiniFFI registrado: #{@dll_name} -> #{@func_name}")
  end

  def call(*args)
    0
  end

  alias Call call
  alias [] call
end

# 1.23 Variables Globales
$DEBUG = false
$TEST = false
$joiplay = true
$DiscordRPC = nil
$PokemonSystem = nil unless defined?($PokemonSystem)

module System
  def self.uptime
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue (Time.now.to_f rescue (Graphics.frame_count / 40.0)))
  end
  def self.real_uptime
    uptime
  end
  def self.unscaled_uptime
    uptime
  end
  def self.data_directory
    "."
  end
  def self.user_language
    "es_ES"
  end
  def self.show_settings; false; end
  def self.set_window_title(*args); end
end

module ::System
  def self.uptime
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue (Time.now.to_f rescue (Graphics.frame_count / 40.0)))
  end
  def self.real_uptime
    uptime
  end
  def self.unscaled_uptime
    uptime
  end
  def self.data_directory
    "."
  end
  def self.user_language
    "es_ES"
  end
  def self.show_settings; false; end
  def self.set_window_title(*args); end
end

module Kernel
  module System
    def self.uptime
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue (Time.now.to_f rescue (Graphics.frame_count / 40.0)))
    end
    def self.real_uptime
      uptime
    end
    def self.unscaled_uptime
      uptime
    end
    def self.data_directory
      "."
    end
    def self.user_language
      "es_ES"
    end
    def self.show_settings; false; end
    def self.set_window_title(*args); end
  end
end

# 1.24 Midbattle & Deluxe Battle Kit Safe Shims
module MidbattleHandlers
  @handlers = {} unless defined?(@handlers)
  def self.add(sym, key, prc)
    @handlers ||= {}
    @handlers[sym] ||= {}
    @handlers[sym][key] = prc
  end
  def self.has_key?(sym, key)
    return false if !defined?(@handlers) || !@handlers || !@handlers[sym]
    @handlers[sym].has_key?(key)
  end
  def self.trigger(sym, key, *args)
    return nil if !has_key?(sym, key)
    @handlers[sym][key].call(*args)
  end
  def self.has_any?(sym)
    return false if !defined?(@handlers) || !@handlers || !@handlers[sym]
    !@handlers[sym].empty?
  end
end

module MidbattleScripts
end

# 1.25 Captura global de excepciones no controladas
at_exit do
  if $! && !(defined?(SystemExit) && $!.is_a?(SystemExit))
    write_crash_report($!, "at_exit")
  end
end

# 1.26 Optimizador de Rendimiento y Pre-carga para Nintendo Switch
class AnimFrame
  X          = 0
  Y          = 1
  ZOOMX      = 2
  ANGLE      = 3
  MIRROR     = 4
  BLENDTYPE  = 5
  VISIBLE    = 6
  PATTERN    = 7
  OPACITY    = 8
  ZOOMY      = 11
  COLORRED   = 12
  COLORGREEN = 13
  COLORBLUE  = 14
  COLORALPHA = 15
  TONERED    = 16
  TONEGREEN  = 17
  TONEBLUE   = 18
  TONEGRAY   = 19
  LOCKED     = 20
  FLASHRED   = 21
  FLASHGREEN = 22
  FLASHBLUE  = 23
  FLASHALPHA = 24
  PRIORITY   = 25
  FOCUS      = 26
end unless defined?(AnimFrame)

class PBAnimTiming
  attr_accessor :frame, :timingType, :name, :volume, :pitch
  attr_accessor :bgX, :bgY, :opacity, :colorRed, :colorGreen, :colorBlue, :colorAlpha
  attr_accessor :duration, :flashScope, :flashColor, :flashDuration

  def initialize(type = 0)
    @frame = 0; @timingType = type; @name = ""; @volume = 80; @pitch = 100
    @bgX = nil; @bgY = nil; @opacity = nil; @colorRed = nil; @colorGreen = nil; @colorBlue = nil; @colorAlpha = nil
    @duration = 5; @flashScope = 0; @flashColor = Color.new(255, 255, 255); @flashDuration = 5
  end

  def timingType; @timingType || 0; end
  def duration; @duration || 5; end
end unless defined?(PBAnimTiming)

class PBAnimation < Array
  attr_accessor :id, :name, :graphic, :hue, :position, :speed, :array, :timing, :scope

  def speed; @speed || 20; end
  def initialize(size = 1)
    @id = -1; @name = ""; @graphic = ""; @hue = 0; @position = 4; @array = []; @timing = []; @scope = 0
  end
  def length; @array.length; end
  def [](i); @array[i]; end
  def []=(i, v); @array[i] = v; end
end unless defined?(PBAnimation)

class PBAnimations < Array
  attr_accessor :array, :selected
  def initialize(size = 1)
    @array = []; @selected = 0
  end
  def length; @array.length; end
  def empty?; (@array || []).empty?; end
  def [](i); @array[i]; end
  def []=(i, v); @array[i] = v; end
  def get_from_name(name)
    @array.each { |i| return i if i&.name == name }
    return nil
  end
end unless defined?(PBAnimations)

module ::SwitchAssetOptimizer
  @audio_prewarmed = false
  @anims_preloaded = false

  COMMON_SE_FILES = [
    # UI & Menus
    "Audio/SE/Voltorb Flip point",
    "Audio/SE/GUI menu open",
    "Audio/SE/GUI menu close",
    "Audio/SE/GUI sel cursor",
    "Audio/SE/GUI sel decision",
    "Audio/SE/GUI sel cancel",
    "Audio/SE/GUI sel buzzer",
    "Audio/SE/GUI bag cursor",
    "Audio/SE/GUI bag pocket",
    "Audio/SE/GUI party switch",
    "Audio/SE/GUI save choice",
    "Audio/SE/GUI summary change page",
    "Audio/SE/GUI trainer card open",
    "Audio/SE/GUI trainer card flip",
    "Audio/SE/Elegir",
    "Audio/SE/Voltorb Flip point",
    "Audio/SE/choose",
    "Audio/SE/Select",
    # Movimiento e Interacción Overworld
    "Audio/SE/Player jump",
    "Audio/SE/Jump",
    "Audio/SE/Bump",
    "Audio/SE/Door enter",
    "Audio/SE/Door exit",
    "Audio/SE/Door slide",
    "Audio/SE/Entering Door",
    "Audio/SE/Exit Door",
    "Audio/SE/Exclaim",
    "Audio/SE/Cut",
    "Audio/SE/Cut 2",
    "Audio/SE/Rock smash",
    "Audio/SE/Fly",
    "Audio/SE/Bicycle",
    "Audio/SE/Camara de fotos",
    "Audio/SE/Itemfinder",
    "Audio/SE/PC access",
    "Audio/SE/PC close",
    "Audio/SE/PC open",
    "Audio/SE/Mart buy item",
    # Pokéballs y Seguidor
    "Audio/SE/pkmn_ball",
    "Audio/SE/Recall",
    "Audio/SE/Ball open",
    "Audio/SE/Battle recall",
    "Audio/SE/Battle throw",
    "Audio/SE/Battle ball drop",
    "Audio/SE/Battle ball hit",
    "Audio/SE/Battle ball shake",
    "Audio/SE/Battle catch click",
    "Audio/SE/Battle jump to ball",
    "Audio/SE/Battle flee",
    # Combate Base y Animaciones Frecuentes
    "Audio/SE/Battle ability",
    "Audio/SE/Battle damage normal",
    "Audio/SE/Battle damage super",
    "Audio/SE/Battle damage weak",
    "Audio/SE/Anim/Damage1",
    "Audio/SE/Anim/Hit1",
    "Audio/SE/Anim/Hit2",
    "Audio/SE/Anim/Hit3",
    "Audio/SE/Anim/Blow1",
    "Audio/SE/Anim/Blow3",
    "Audio/SE/Anim/Blow4",
    "Audio/SE/Anim/Blow5",
    "Audio/SE/Anim/Blow6",
    "Audio/SE/Anim/Blow7",
    "Audio/SE/Anim/Crash",
    "Audio/SE/Anim/Collapse1",
    "Audio/SE/Anim/Battle1",
    "Audio/SE/Anim/Explosion1",
    "Audio/SE/Anim/Explosion2",
    "Audio/SE/Anim/Fire1",
    "Audio/SE/Anim/Fire2",
    "Audio/SE/Anim/Earth1",
    "Audio/SE/Anim/Ice2",
    "Audio/SE/Anim/Flash2"
  ]

  class << self
    def preload_battle_animations
      # Lazy load on first battle via pbLoadBattleAnimations to avoid 15MB parse lag during boot
    end

    def prewarm_battle(battle)
      return if !battle
      begin
        $PokemonBattleAnimations ||= pbLoadBattleAnimations rescue nil
      rescue Exception
      end
    end

    def prewarm_all
      # Non-blocking bootup: audio and graphics lookup tables are already in RAM via .dat
    end
  end
end

$RESOLVED_BITMAP_CACHE ||= {}

def pbResolveBitmap(x)
  return nil if !x || x.to_s.empty?
  key = x.to_s
  return $RESOLVED_BITMAP_CACHE[key] if $RESOLVED_BITMAP_CACHE.has_key?(key)

  if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE
    clean_k = key.gsub("\\", "/").downcase
    clean_noext = clean_k.sub(/\.(bmp|png|gif|jpg|jpeg)$/, "")
    
    found = $GRAPHICS_LOOKUP_TABLE[clean_k] ||
            $GRAPHICS_LOOKUP_TABLE[clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE[clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE[clean_noext + ".gif"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/animations/" + clean_noext.sub(/^animations\//, "") + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/characters/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/battlers/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/battlers/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/battlers/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/pictures/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/battlebacks/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/battlebacks/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/battlebacks/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/ui/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/ui/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/ui/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/autotiles/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/autotiles/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/autotiles/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/trainers/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/trainers/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/trainers/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/transitions/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/transitions/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/transitions/" + clean_noext + ".png"] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/titles/" + clean_k] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/titles/" + clean_noext] ||
            $GRAPHICS_LOOKUP_TABLE["graphics/titles/" + clean_noext + ".png"]
    if found
      $RESOLVED_BITMAP_CACHE[key] = found
      return found
    end
  end

  noext = x.gsub(/\.(bmp|png|gif|jpg|jpeg)$/, "")
  filename = nil
  RTP.eachPathFor(noext) do |path|
    filename = pbTryString(path + ".png") if !filename
    filename = pbTryString(path + ".gif") if !filename
  end rescue nil
  $RESOLVED_BITMAP_CACHE[key] = filename
  return filename
end

$ANIMATION_BITMAP_CACHE ||= {}
$ANIMATION_BITMAP_SIZES ||= {}
$ANIMATION_BITMAP_BYTES ||= 0
$ANIMATION_BITMAP_MAX_BYTES = 40 * 1024 * 1024 # 40 MB

def pbClearAnimationCache
  if defined?($ANIMATION_BITMAP_CACHE) && $ANIMATION_BITMAP_CACHE
    $ANIMATION_BITMAP_CACHE.each_value do |bm|
      bm.dispose if bm && !bm.disposed?
    end
    $ANIMATION_BITMAP_CACHE.clear
  end
  if defined?($ANIMATION_EVICTED_BITMAPS) && $ANIMATION_EVICTED_BITMAPS
    $ANIMATION_EVICTED_BITMAPS.each do |bm|
      bm.dispose if bm && !bm.disposed?
    end
    $ANIMATION_EVICTED_BITMAPS.clear
  end
  $ANIMATION_BITMAP_SIZES&.clear
  $ANIMATION_BITMAP_BYTES = 0
end

def pbGetAnimation(name, hue = 0)
  return nil if nil_or_empty?(name)
  key = "#{name}_#{hue}"
  if $ANIMATION_BITMAP_CACHE.has_key?(key)
    bm = $ANIMATION_BITMAP_CACHE[key]
    return nil if bm.nil?
    if !bm.disposed?
      $ANIMATION_BITMAP_CACHE.delete(key)
      $ANIMATION_BITMAP_CACHE[key] = bm
      return bm
    end
  end

  clean_name = name.to_s.sub(/\A(Graphics\/)?(Battle\s*)?animations\//i, "")
  base_no_ext = clean_name.sub(/\.(bmp|png|gif|jpg|jpeg)\z/i, "")
  base_lower = base_no_ext.downcase

  real_path = nil
  if defined?($GRAPHICS_LOOKUP_TABLE) && $GRAPHICS_LOOKUP_TABLE
    real_path = $GRAPHICS_LOOKUP_TABLE["graphics/animations/#{base_lower}.png"] ||
                $GRAPHICS_LOOKUP_TABLE["animations/#{base_lower}.png"] ||
                $GRAPHICS_LOOKUP_TABLE["graphics/battle animations/#{base_lower}.png"] ||
                $GRAPHICS_LOOKUP_TABLE["battle animations/#{base_lower}.png"] ||
                $GRAPHICS_LOOKUP_TABLE["#{base_lower}.png"] ||
                $GRAPHICS_LOOKUP_TABLE[clean_name.downcase] ||
                $GRAPHICS_LOOKUP_TABLE["graphics/animations/#{clean_name.downcase}"]
  end

  real_path ||= pbResolveBitmap("Graphics/Animations/" + clean_name) ||
                pbResolveBitmap("Graphics/Battle animations/" + clean_name) ||
                pbResolveBitmap(clean_name)

  if !real_path
    cands = [
      "Graphics/Animations/#{clean_name}.png",
      "Graphics/Animations/#{base_no_ext}.png",
      "Graphics/Animations/#{clean_name}",
      "Graphics/Battle animations/#{clean_name}.png",
      "Graphics/Battle animations/#{base_no_ext}.png",
      "Graphics/Battle animations/#{clean_name}"
    ]
    for cand in cands
      if File.exist?(cand) || FileTest.exist?(cand)
        real_path = cand
        break
      end
    end
  end

  bm = nil
  if real_path
    bm = Bitmap.new(real_path) rescue nil
    bm.hue_change(hue) rescue nil if bm && (hue || 0) != 0
  end

  if !bm || bm.disposed?
    bm = (AnimatedBitmap.new("Graphics/Animations/" + clean_name, hue || 0).deanimate rescue nil) ||
         (AnimatedBitmap.new(clean_name, hue || 0).deanimate rescue nil)
  end

  if !bm || bm.disposed?
    $ANIMATION_BITMAP_CACHE[key] = nil
    return nil
  end

  size = (bm.width * bm.height * 4) rescue 0
  if $ANIMATION_BITMAP_CACHE.has_key?(key)
    old_size = $ANIMATION_BITMAP_SIZES.delete(key) || 0
    $ANIMATION_BITMAP_BYTES = [$ANIMATION_BITMAP_BYTES - old_size, 0].max
  end

  $ANIMATION_BITMAP_CACHE[key] = bm
  $ANIMATION_BITMAP_SIZES[key] = size
  $ANIMATION_BITMAP_BYTES += size

  $ANIMATION_EVICTED_BITMAPS ||= []
  while $ANIMATION_BITMAP_BYTES > $ANIMATION_BITMAP_MAX_BYTES && !$ANIMATION_BITMAP_CACHE.empty?
    oldest_key = $ANIMATION_BITMAP_CACHE.keys.first
    old_bm = $ANIMATION_BITMAP_CACHE.delete(oldest_key)
    old_sz = $ANIMATION_BITMAP_SIZES.delete(oldest_key) || 0
    $ANIMATION_BITMAP_BYTES = [$ANIMATION_BITMAP_BYTES - old_sz, 0].max
    $ANIMATION_EVICTED_BITMAPS << old_bm if old_bm && !old_bm.disposed?
  end

  return bm
end

def pbLoadBattleAnimations
  return $PokemonBattleAnimations if $PokemonBattleAnimations && ($PokemonBattleAnimations.is_a?(PBAnimations) || $PokemonBattleAnimations.is_a?(Array)) && $PokemonBattleAnimations.length > 0
  begin
    data = load_data("Data/PkmnAnimations.rxdata")
    if data && (data.is_a?(PBAnimations) || data.is_a?(Array)) && data.length > 0
      $PokemonBattleAnimations = data
      if defined?($game_temp) && $game_temp
        $game_temp.battle_animations_data = $PokemonBattleAnimations
      end
      log_compat("[Animaciones] PkmnAnimations.rxdata cargado con exito: #{data.length} animaciones.") rescue nil
      return $PokemonBattleAnimations
    end
  rescue Exception => e
    log_compat("[Animaciones] Fallo al cargar PkmnAnimations.rxdata: #{e.class}: #{e.message}") rescue nil
  end
  $PokemonBattleAnimations ||= PBAnimations.new(0)
  return $PokemonBattleAnimations
end

def pbLoadMoveToAnim
  return $PokemonMoveToAnim if $PokemonMoveToAnim && !$PokemonMoveToAnim.empty?
  $PokemonMoveToAnim = (load_data("Data/move2anim.dat") rescue nil) || []
  if defined?($game_temp) && $game_temp
    $game_temp.move_to_battle_animation_data = $PokemonMoveToAnim
  end
  return $PokemonMoveToAnim
end

# In-RAM Map Cache for instantaneous overworld transitions on Switch
$MAP_RXDATA_CACHE ||= {}
$MAP_RXDATA_CACHE_MAX = 6

def pbGetCachedMap(map_id)
  key = map_id.is_a?(Numeric) ? sprintf("Data/Map%03d.rxdata", map_id) : map_id.to_s
  key = key.sub(/^data\//i, "Data/")
  cached = $MAP_RXDATA_CACHE[key]
  if cached
    $MAP_RXDATA_CACHE.delete(key)
    $MAP_RXDATA_CACHE[key] = cached
    deserialized = (Marshal.load(cached) rescue nil)
    return deserialized if deserialized
  end
  map = (load_data(key) rescue nil)
  if map
    dumped = (Marshal.dump(map) rescue nil)
    if dumped
      $MAP_RXDATA_CACHE[key] = dumped
      if $MAP_RXDATA_CACHE.size > $MAP_RXDATA_CACHE_MAX
        first_k = $MAP_RXDATA_CACHE.keys.first
        $MAP_RXDATA_CACHE.delete(first_k)
      end
    end
    return map
  end
  return nil
end

opt_fixed = true
begin
  opt_paths = ["options.dat", "Data/options.dat", "SaveData/options.dat"]
  opt_file = opt_paths.find { |p| File.file?(p) rescue false }
  if opt_file
    opts = File.open(opt_file, "rb") { |f| Marshal.load(f) } rescue nil
    if opts.is_a?(Hash) && opts.key?(:screensize)
      opt_fixed = (opts[:screensize] == 1)
    end
  end
rescue Exception
end

Graphics.resize_screen(512, 384) rescue nil
Graphics.fixed_aspect_ratio = opt_fixed rescue nil
Graphics.integer_scaling = false rescue nil
Graphics.smooth_scaling = 3 rescue nil
Graphics.fullscreen = true rescue nil
log_compat("Stubs de compatibilidad inicializados correctamente.")
update_boot_progress(5, "Cargando scripts del motor...") if defined?(update_boot_progress)


