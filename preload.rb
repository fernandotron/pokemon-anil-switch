# ==============================================================================
# Nintendo Switch (Horizon OS) & Modern Ruby Compatibility Shims for mkxp-z
# ==============================================================================

# 1.0 Inicialización del Logging Eficiente
$mkxp_log_file ||= (File.open("mkxp_ruby.log", "a") rescue nil)
$LOG_COMPAT_DEDUP ||= {}
$LOG_COMPAT_COUNT ||= 0
$LOG_COMPAT_MAX_LINES ||= 5000
$SWITCH_STRICT_EVENTS ||= false

def log_compat(msg)
  return if $LOG_COMPAT_COUNT >= $LOG_COMPAT_MAX_LINES
  msg_str = msg.to_s
  dedup_key = msg_str[0, 120]
  return if $LOG_COMPAT_DEDUP[dedup_key]
  $LOG_COMPAT_DEDUP[dedup_key] = true
  $LOG_COMPAT_COUNT += 1

  puts msg_str rescue nil if $SWITCH_VERBOSE
  if $mkxp_log_file
    $mkxp_log_file.puts(msg_str) rescue nil
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
log_compat("=================================================================")

# 1.05 Pre-indexación de Assets en RAM para 60 FPS sin I/O en MicroSD (Arranque Instantáneo)
$GRAPHICS_LOOKUP_TABLE ||= {}
$AUDIO_LOOKUP_TABLE ||= {}
$RESOLVE_AUDIO_MEMO_CACHE ||= {}
$RESOLVED_BITMAP_CACHE ||= {}

if File.exist?("Data/switch_assets_index.dat")
  begin
    raw = File.open("Data/switch_assets_index.dat", "rb") { |f| f.read }
    if raw && !raw.empty?
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f
      $GRAPHICS_LOOKUP_TABLE, $AUDIO_LOOKUP_TABLE = Marshal.load(raw)
      t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC) rescue Time.now.to_f
      log_compat(sprintf("[Switch Assets] Cargados %d graficos y %d audios desde .dat en %.3fs (Arranque Instantaneo).", ($GRAPHICS_LOOKUP_TABLE.length rescue 0), ($AUDIO_LOOKUP_TABLE.length rescue 0), (t1 - t0))) rescue nil
    end
  rescue Exception => e
    log_compat("[Warning Switch Assets DAT] #{e.message}") rescue nil
  end
elsif File.exist?("Data/switch_assets_index.rb")
  begin
    code = File.open("Data/switch_assets_index.rb", "rb") { |f| f.read }
    if code && !code.empty?
      TOPLEVEL_BINDING.eval(code, "Data/switch_assets_index.rb")
      log_compat("[Switch Assets] Cargados #{$GRAPHICS_LOOKUP_TABLE.length rescue 0} graficos y #{$AUDIO_LOOKUP_TABLE.length rescue 0} audios pre-indexados en RAM desde .rb fallback.") rescue nil
    end
  rescue Exception => e
    log_compat("[Warning Switch Assets Index] #{e.message}") rescue nil
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
      nil
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
      if defined?(SwitchAssetOptimizer)
        SwitchAssetOptimizer.prewarm_all rescue nil
      end
    rescue Exception => e
      log_compat("[Warning set_up_system] #{e.class}: #{e.message}") rescue nil
    end
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
  AUX1   = 18 unless const_defined?(:AUX1)
  AUX2   = 17 unless const_defined?(:AUX2)
  SPECIAL = 23 unless const_defined?(:SPECIAL)

  class << self
    alias __mkxp_native_input_update update unless method_defined?(:__mkxp_native_input_update) rescue nil
    def update_KGC_ScreenCapture
      __mkxp_native_input_update rescue nil
    end
    def mouse_in_window; false; end
    def mouse_in_window?; false; end
    def mouse_x; 0; end
    def mouse_y; 0; end
    def scroll_v; 0; end
    def release?(*args); false; end
    def time?(*args); 0; end
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
      [@name, @volume, @pitch].pack("a*NN") rescue ""
    end

    def self._load(str)
      AudioFile.new
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
      alias __switch_native_bgs_play bgs_play rescue nil
      alias __switch_native_me_play me_play rescue nil
      alias __switch_native_se_play se_play rescue nil
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
        found = $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_down}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_clean}/#{base_down}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_clean}/#{base_clean}"] ||
                $AUDIO_LOOKUP_TABLE[p_down] ||
                $AUDIO_LOOKUP_TABLE[p_clean] ||
                $AUDIO_LOOKUP_TABLE["audio/" + p_down] ||
                $AUDIO_LOOKUP_TABLE["audio/" + p_clean] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete(' ')}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete('_')}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete('-')}"] ||
                $AUDIO_LOOKUP_TABLE["#{def_down}/#{base_clean.delete(' _-')}"] ||
                $AUDIO_LOOKUP_TABLE[base_clean] ||
                $AUDIO_LOOKUP_TABLE[base_down] ||
                $AUDIO_LOOKUP_TABLE[base_clean.delete(" ")] ||
                $AUDIO_LOOKUP_TABLE[base_clean.delete("_")] ||
                $AUDIO_LOOKUP_TABLE[base_clean.delete("-")] ||
                $AUDIO_LOOKUP_TABLE[base_clean.delete(" _-")]

        if found && !found.empty?
          $RESOLVE_AUDIO_MEMO_CACHE[cache_key] = found
          return found
        end

        # Probar extensiones .wav y .ogg prioritarias bajo default_dir
        clean_p = p.sub(/\.[^.]+$/, "")
        cand = p.start_with?("Audio/") ? clean_p : "#{default_dir}/#{clean_p}"
        [cand + ".wav", cand + ".ogg", cand + ".mp3", p].each do |test_f|
          if $AUDIO_LOOKUP_TABLE[test_f.downcase]
            found = $AUDIO_LOOKUP_TABLE[test_f.downcase]
            $RESOLVE_AUDIO_MEMO_CACHE[cache_key] = found
            return found
          end
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
      if track
        __switch_native_bgm_play(file, vol, (pitch || 100).to_i, (pos || 0.0).to_f, track) rescue (__switch_native_bgm_play(file, vol, (pitch || 100).to_i, (pos || 0.0).to_f) rescue nil)
      else
        __switch_native_bgm_play(file, vol, (pitch || 100).to_i, (pos || 0.0).to_f) rescue nil
      end
    rescue Exception
    end

    def bgs_play(filename, volume = 100, pitch = 100, pos = 0.0)
      return if filename.nil? || filename.to_s.empty?
      file = resolve_audio_file(filename, nil, "Audio/BGS")
      file = filename.to_s if file.nil? || file.empty?
      __switch_native_bgs_play(file, (volume || 100).to_i, (pitch || 100).to_i, (pos || 0.0).to_f) rescue nil
    rescue Exception
    end

    def me_play(filename, volume = 100, pitch = 100)
      return if filename.nil? || filename.to_s.empty?
      file = resolve_audio_file(filename, nil, "Audio/ME")
      file = filename.to_s if file.nil? || file.empty?
      __switch_native_me_play(file, (volume || 100).to_i, (pitch || 100).to_i) rescue nil
    rescue Exception
    end

    def me_stop
      __switch_native_me_stop rescue nil
    end

    def me_fade(time)
      __switch_native_me_fade(time) rescue nil
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
    "GUI menu open", "GUI menu close", "GUI sel cursor", "GUI sel decision",
    "GUI sel cancel", "GUI sel buzzer", "GUI naming tab swap start", "GUI naming tab swap end",
    "GUI storage show party panel", "GUI storage hide party panel", "GUI summary change page",
    "GUI party switch", "GUI trainer card open", "GUI trainer card flip", "GUI bag cursor",
    "Player jump", "jump", "Player bump", "Door enter", "Door exit", "Door open", "Door close",
    "Ledge jump", "Bicycle", "Cut", "Rock Smash", "Headbutt", "Fly", "Surf",
    "pkmn_ball", "Recall", "Battle throw", "Battle ball drop", "Battle ball hit",
    "Battle ball shake", "Battle recall", "Battle damage normal", "Battle damage super",
    "Battle damage weak", "Battle flee", "Pkmn faint", "Battle exp full", "Battle stat up",
    "Battle stat down", "Item get", "Key item get", "Item obtain", "Mining item get",
    "Voltorb Flip point", "Voltorb Flip mark", "Voltorb Flip win"
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
  core_sounds = [
    "Player jump", "jump", "Player bump",
    "GUI sel cursor", "GUI sel decision", "GUI sel cancel", "GUI sel buzzer",
    "GUI menu open", "GUI menu close", "GUI save choice", "GUI bag pocket", "GUI bag cursor",
    "Door enter", "Door exit", "Door slide", "pkmn_ball", "Recall",
    "Battle ball throw", "Battle throw", "Battle ball hit", "Battle ball drop", "Battle ball shake",
    "Battle ball capture", "Battle critical catch throw", "Battle jump to ball",
    "Battle damage normal", "Battle damage super", "Battle damage weak", "Battle flee",
    "Battle recall", "Battle exp", "Battle ball burst", "Battle faint",
    "itemget", "Item get", "Voltorb Flip point", "Audio/ME/Item get.wav"
  ]
  core_sounds.each do |s|
    resolved = ::Audio.resolve_audio_file(s, nil, "Audio/SE")
    if resolved && !resolved.empty?
      ::Audio.__switch_native_se_play(resolved, 0, 100) rescue nil
    end
  end
  ::Audio.se_stop rescue nil
  log_compat("[Switch Audio] Pre-calentados #{core_sounds.length} efectos basicos de UI/movimiento/captura en OpenAL RAM.") rescue nil
rescue Exception => e
  log_compat("[Warning warmup_core_switch_audio] #{e.message}") rescue nil
end

def prewarm_pause_menu_graphics!
  return unless defined?(RPG::Cache)
  dp_icons = [
    "bgTop", "bgMid", "bgBtm", "selector",
    "pokedexA", "pokedexB",
    "pokemonA", "pokemonB",
    "bagA", "bagBm", "bagBf",
    "PlayercardA", "PlayercardB",
    "saveA", "saveBm", "saveBf",
    "optionsA", "optionsB",
    "exitA", "exitB"
  ]
  dp_icons.each do |ic|
    RPG::Cache.load_bitmap("Graphics/Pictures/DP Pause Menu/", ic) rescue nil
  end
rescue Exception
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
    0
  end
  def battlescene=(val)
    @battlescene = 0
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

module Kernel
  unless method_defined?(:__switch_orig_exit)
    alias __switch_orig_exit exit rescue nil
    alias __switch_orig_exit_bang exit! rescue nil
  end

  def exit(*args)
    log_compat("[Kernel.exit] Salida limpia...") rescue nil
    $scene = nil if defined?($scene)
    __switch_orig_exit(*args) rescue nil
  end

  def exit!(*args)
    log_compat("[Kernel.exit!] Salida limpia...") rescue nil
    $scene = nil if defined?($scene)
    __switch_orig_exit_bang(*args) rescue nil
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

def pbSetResizeFactor(factor = 0)
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

      if defined?($RESOLVED_BITMAP_CACHE) && $RESOLVED_BITMAP_CACHE && $RESOLVED_BITMAP_CACHE.has_key?(p)
        res = !!$RESOLVED_BITMAP_CACHE[p]
        $FILE_EXIST_CACHE[p] = res
        return res
      end

      res = (open(p, "rb") { true } rescue false)
      res = ::Dir.exist?(p) if !res
      writable = (p =~ /\.(rxdata|bak|sav|log|txt)$/i && !p.start_with?("Data/"))
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
class Module
  unless method_defined?(:__switch_orig_mod_const_missing)
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
    # Resilient fallback dummy class for Marshal.load
    dummy = Class.new
    const_set(name, dummy) rescue nil
    log_compat("[const_missing] Definida clase fallback para: #{self}::#{name}") rescue nil
    return dummy
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

    # Si el primer argumento es un Binding explícito, usarlo; si no, usar TOPLEVEL_BINDING
    if args.length > 0 && args[0].is_a?(Binding)
      target_binding = args.shift
    else
      target_binding = TOPLEVEL_BINDING
    end

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
      src = src.gsub(/module\s+Graphics\b/, 'module ::Graphics')
      src = src.gsub(/module\s+Input\b/, 'module ::Input')
      src = src.gsub(/module\s+Audio\b/, 'module ::Audio')
      src = src.gsub(/Graphics\.frame_rate\b/, '(Graphics.respond_to?(:frame_rate) ? Graphics.frame_rate : 40)')
      src = src.gsub(/class\s+(Rect|Color|Tone)\s*<\s*Object/m, 'class \1')
      src = src.gsub(/class\s+(GameStats|Game_Temp|PokemonSystem)\s*<\s*\1/m, 'class \1')
      src = src.gsub(/class\s+(ScrollingSprite|RainbowSprite|TrailingSprite)\s*<\s*[\w:]+/m, 'class \1')
      src = src.gsub(/class\s+Player\b(?!\s*<\s*Trainer)/, 'class Trainer; end unless defined?(Trainer); class Player < Trainer')
      src = src.gsub(/(?<!::)\bSaveData\.initialize_bootup_values\b/, '(SaveData.respond_to?(:initialize_bootup_values) ? SaveData.initialize_bootup_values : nil)')
      src = src.gsub(/(?<!::)\bSaveData\.load_bootup_values\((.*?)\)/, '(SaveData.respond_to?(:load_bootup_values) ? SaveData.load_bootup_values(\1) : nil)')
      src = src.gsub(/def\s+pbSetResizeFactor\b.*?\nend\b/m, "def pbSetResizeFactor(factor = 0); Graphics.fixed_aspect_ratio = (factor == 1) rescue nil; Graphics.integer_scaling = false rescue nil; Graphics.smooth_scaling = 3 rescue nil; Graphics.fullscreen = true rescue nil; end")
      src = src.gsub(/Graphics\.fullscreen\s*=\s*(?:false|!\s*Graphics\.fullscreen)/, 'Graphics.fullscreen = true')
      src = src.gsub(/Graphics\.scale\s*=\s*[^\n;]+/, '# Graphics.scale skipped on Switch')
      src = src.gsub(/Graphics\.resize_screen\b[^\n;]*/, '# Graphics.resize_screen skipped on Switch')
      src = src.gsub(/Graphics\.resize_window\b[^\n;]*/, '# Graphics.resize_window skipped on Switch')
      src = src.gsub(/next\s+(?:Kernel\.)?pbShowCommands\(/, 'next send(:pbShowCommands, ')
      src = src.gsub(/next\s+(?:Kernel\.)?pbShowCommandsWithHelp\(/, 'next send(:pbShowCommandsWithHelp, ')
      src = src.gsub(/Kernel\.pb([A-Za-z0-9_]+)/, 'pb\1')
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
    log_compat("[Kernel.exit interceptado] Código: #{code}\n  #{caller[0..5]&.join("\n  ")}")
  end
  def abort(msg = nil)
    log_compat("[Kernel.abort interceptado] #{msg}\n  #{caller[0..5]&.join("\n  ")}")
  end
  def exit!(code = 0)
    log_compat("[Kernel.exit! interceptado] Código: #{code}\n  #{caller[0..5]&.join("\n  ")}")
  end
  module_function :exit, :abort, :exit! rescue nil
end

def exit(code = 0); Kernel.exit(code); end
def abort(msg = nil); Kernel.abort(msg); end
def exit!(code = 0); Kernel.exit!(code); end

module Process
  def self.exit(code = 0)
    log_compat("[Process.exit interceptado] Código: #{code}")
  end
  def self.exit!(code = 0)
    log_compat("[Process.exit! interceptado] Código: #{code}")
  end
  def self.abort(msg = nil)
    log_compat("[Process.abort interceptado] #{msg}")
  end
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
  if $!
    bt = ($!.backtrace || []).take(12).join("\n")
    err_msg = "CRASH EN RUBY DETECTADO [#{Time.now rescue ''}]:\nExcepción: #{$!.class}: #{$!.message}\nBacktrace:\n#{bt}"
    log_compat(err_msg)
    begin
      File.open("crash_report.txt", "w") { |f| f.puts(err_msg) }
    rescue Exception
    end
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
      return if @anims_preloaded
      @anims_preloaded = true
      
      log_compat("[SwitchAssetOptimizer] Pre-cargando Data/PkmnAnimations.rxdata en memoria...")
      $PokemonBattleAnimations = (load_data("Data/PkmnAnimations.rxdata") rescue nil)
      if $PokemonBattleAnimations
        log_compat("[SwitchAssetOptimizer] PkmnAnimations.rxdata (#{$PokemonBattleAnimations.length rescue 0} animaciones) precargado en RAM.")
      end
    rescue Exception => e
      log_compat("[SwitchAssetOptimizer Error Anims] #{e.class}: #{e.message}")
    end

    def prewarm_battle(battle)
      return if !battle
      # 1. Preload active moves graphics of all battlers
      $PokemonBattleAnimations ||= (load_data("Data/PkmnAnimations.rxdata") rescue nil)
      if defined?($PokemonBattleAnimations) && $PokemonBattleAnimations && battle.respond_to?(:battlers) && battle.battlers
        battle.battlers.compact.each do |b|
          next if !b.respond_to?(:moves) || !b.moves
          b.moves.each do |m|
            next if !m
            begin
              anim_id = pbFindMoveAnimation(m.id, b.index, 0) rescue nil
              if anim_id && $PokemonBattleAnimations[anim_id[0]]
                anim = $PokemonBattleAnimations[anim_id[0]]
                if anim.graphic && !anim.graphic.empty?
                  pbGetAnimation(anim.graphic, anim.hue || 0) rescue nil
                end
              end
            rescue Exception
            end
          end
        end
      end
    rescue Exception => e
      log_compat("[SwitchAssetOptimizer Error prewarm_battle] #{e.message}") rescue nil
    end

    def prewarm_all
      build_audio_cache!
      preload_battle_animations

      # Pre-decode common SEs into fast audio buffers in RAM (volume 0)
      COMMON_SE_FILES.each do |se|
        real_path = pbResolveAudioSE(se) rescue nil
        if real_path
          Audio.se_play(real_path, 0, 100) rescue nil
        end
      end
      Audio.se_stop rescue nil

      # Pre-warm common overworld animations (dust, grass rustle, emotes, ball effects)
      $data_animations ||= (load_data("Data/Animations.rxdata") rescue nil)
      if $data_animations
        $data_animations.compact.each do |anim|
          next if !anim || !anim.animation_name || anim.animation_name.empty?
          pbGetAnimation(anim.animation_name, anim.animation_hue || 0) rescue nil
          if anim.respond_to?(:timings) && anim.timings
            anim.timings.each do |t|
              if t.se && t.se.name && !t.se.name.empty?
                real_path = pbResolveAudioSE(t.se.name) rescue nil
                Audio.se_play(real_path, 0, 100) if real_path rescue nil
              end
            end
          end
        end
        Audio.se_stop rescue nil
      end

      # Pre-warm common battle particles and sendout graphics
      [
        "Graphics/Battle animations/ballBurst_particle",
        "Graphics/Battle animations/ballBurst_particle_s",
        "Graphics/Battle animations/ballBurst_ray",
        "Graphics/Battle animations/ballBurst_ring1",
        "Graphics/Battle animations/ballBurst_ring2",
        "Graphics/Battle animations/ballBurst_ring3",
        "Graphics/Battle animations/ballBurst_dazzle",
        "Graphics/Battle animations/ballBurst_bubble",
        "Graphics/Battle animations/ballBurst_diamond",
        "Graphics/Animations/003-Attack01",
        "Graphics/Animations/004-Attack02",
        "Graphics/Animations/015-Fire01",
        "Graphics/Animations/016-Ice01",
        "Graphics/Animations/017-Thunder01",
        "Graphics/Animations/018-Water01",
        "Graphics/Animations/anim sheet",
        "Graphics/Animations/Common-BallOpen",
        "Graphics/Animations/Common-BallRecall"
      ].each do |anim_path|
        pbGetAnimation(anim_path, 0) rescue nil
      end

      # Pre-warm pause menu in RPG::Cache for instant opening
      [
        "Graphics/Pictures/DP Pause Menu/bgTop",
        "Graphics/Pictures/DP Pause Menu/bgMid",
        "Graphics/Pictures/DP Pause Menu/bgBtm",
        "Graphics/Pictures/DP Pause Menu/bgTop_short",
        "Graphics/Pictures/DP Pause Menu/bgMid_short",
        "Graphics/Pictures/DP Pause Menu/bgBtm_short",
        "Graphics/Pictures/DP Pause Menu/selector",
        "Graphics/Pictures/DP Pause Menu/pokedexA",
        "Graphics/Pictures/DP Pause Menu/pokedexB",
        "Graphics/Pictures/DP Pause Menu/pokemonA",
        "Graphics/Pictures/DP Pause Menu/pokemonB",
        "Graphics/Pictures/DP Pause Menu/bagA",
        "Graphics/Pictures/DP Pause Menu/bagBm",
        "Graphics/Pictures/DP Pause Menu/bagBf",
        "Graphics/Pictures/DP Pause Menu/PlayercardA",
        "Graphics/Pictures/DP Pause Menu/PlayercardB",
        "Graphics/Pictures/DP Pause Menu/saveA",
        "Graphics/Pictures/DP Pause Menu/saveBm",
        "Graphics/Pictures/DP Pause Menu/saveBf",
        "Graphics/Pictures/DP Pause Menu/optionsA",
        "Graphics/Pictures/DP Pause Menu/optionsB",
        "Graphics/Pictures/DP Pause Menu/exitA",
        "Graphics/Pictures/DP Pause Menu/exitB"
      ].each do |bmp_path|
        RPG::Cache.load_bitmap("", bmp_path) rescue nil
      end

      # Pre-warm overworld shadows
      [
        "defaultShadow", "smallShadow", "mediumShadow", "largeShadow"
      ].each do |shdw|
        RPG::Cache.load_bitmap("Graphics/Characters/Shadows/", shdw) rescue nil
      end
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
            $GRAPHICS_LOOKUP_TABLE["graphics/autotiles/" + clean_noext + ".png"]
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
  $ANIMATION_BITMAP_SIZES&.clear
  $ANIMATION_BITMAP_BYTES = 0
end

def pbGetAnimation(name, hue = 0)
  return nil if nil_or_empty?(name)
  key = "#{name}_#{hue}"
  if $ANIMATION_BITMAP_CACHE.has_key?(key)
    bm = $ANIMATION_BITMAP_CACHE[key]
    if bm.nil?
      return nil
    elsif !bm.disposed?
      $ANIMATION_BITMAP_CACHE.delete(key)
      $ANIMATION_BITMAP_CACHE[key] = bm
      return bm
    end
  end

  clean_name = name.to_s.sub(/^Graphics\/Animations\//i, "").sub(/^Animations\//i, "").sub(/^Graphics\/Battle animations\//i, "").sub(/^Battle animations\//i, "")
  real_path = pbResolveBitmap("Graphics/Animations/" + clean_name) ||
              pbResolveBitmap("Graphics/Battle animations/" + clean_name) ||
              pbResolveBitmap(clean_name)
  if real_path
    bm = (Bitmap.new(real_path) rescue nil) ||
         (AnimatedBitmap.new(real_path, hue).deanimate rescue nil)
  else
    bm = (AnimatedBitmap.new("Graphics/Animations/" + clean_name, hue).deanimate rescue nil) ||
         (AnimatedBitmap.new(clean_name, hue).deanimate rescue nil)
  end

  size = (bm && !bm.disposed?) ? (bm.width * bm.height * 4) : 0
  if $ANIMATION_BITMAP_CACHE.has_key?(key)
    old_size = $ANIMATION_BITMAP_SIZES.delete(key) || 0
    $ANIMATION_BITMAP_BYTES = [$ANIMATION_BITMAP_BYTES - old_size, 0].max
  end

  $ANIMATION_BITMAP_CACHE[key] = bm
  $ANIMATION_BITMAP_SIZES[key] = size
  $ANIMATION_BITMAP_BYTES += size

  while $ANIMATION_BITMAP_BYTES > $ANIMATION_BITMAP_MAX_BYTES && !$ANIMATION_BITMAP_CACHE.empty?
    oldest_key = $ANIMATION_BITMAP_CACHE.keys.first
    old_bm = $ANIMATION_BITMAP_CACHE.delete(oldest_key)
    old_sz = $ANIMATION_BITMAP_SIZES.delete(oldest_key) || 0
    $ANIMATION_BITMAP_BYTES = [$ANIMATION_BITMAP_BYTES - old_sz, 0].max
    old_bm.dispose if old_bm && !old_bm.disposed?
  end

  return bm
end

def pbLoadBattleAnimations
  return $PokemonBattleAnimations if $PokemonBattleAnimations.is_a?(PBAnimations) && $PokemonBattleAnimations.length > 0
  begin
    $PokemonBattleAnimations = load_data("Data/PkmnAnimations.rxdata")
  rescue Exception => e
    log_compat("[Animaciones] Fallo al cargar PkmnAnimations.rxdata: #{e.class}: #{e.message}")
    $PokemonBattleAnimations = nil
  end
  if !$PokemonBattleAnimations.is_a?(PBAnimations)
    log_compat("[Animaciones] Tipo inesperado: #{$PokemonBattleAnimations.class}")
    $PokemonBattleAnimations = PBAnimations.new(0)
  end
  if defined?($game_temp) && $game_temp
    $game_temp.battle_animations_data = $PokemonBattleAnimations
  end
  return $PokemonBattleAnimations
end

def pbLoadMoveToAnim
  return $game_temp.move_to_battle_animation_data if defined?($game_temp) && $game_temp&.move_to_battle_animation_data && !$game_temp.move_to_battle_animation_data.empty?
  data = (load_data("Data/move2anim.dat") rescue nil) || []
  $game_temp.move_to_battle_animation_data = data if defined?($game_temp) && $game_temp
  return data
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

Graphics.resize_screen(512, 384) rescue nil
Graphics.fixed_aspect_ratio = false rescue nil
Graphics.integer_scaling = false rescue nil
Graphics.smooth_scaling = 3 rescue nil
Graphics.fullscreen = true rescue nil
log_compat("Stubs de compatibilidad inicializados correctamente.")

