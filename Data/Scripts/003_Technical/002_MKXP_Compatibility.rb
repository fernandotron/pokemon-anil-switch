#===============================================================================
# Using mkxp-z v2.4.2/d13f35c - built 2025/10/28.
# https://github.com/mkxp-z/mkxp-z/actions/runs/18874497198
#===============================================================================
$VERBOSE = nil

# Define Encoding if it's not already defined
unless defined?(Encoding)
  module Encoding
    UTF_8 = "UTF-8".freeze
    def self.find(name)
      # Mimic Encoding.find behavior
      return UTF_8 if name == "UTF-8"

      raise ArgumentError, "unknown encoding: #{name}"
    end
  end
end


Font.default_shadow = false if Font.respond_to?(:default_shadow)
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

def pbSetWindowText(string)
  System.set_window_title(string || System.game_title)
end

module Graphics
  class << self
    def scale=(val)
      # No-op on Switch to prevent window shrinking to 512x384
    end
    def resize_screen(w, h)
      # No-op on Switch
    end
    def resize_window(w, h)
      # No-op on Switch
    end
  end
end

def pbSetResizeFactor(factor = 1)
  Graphics.fixed_aspect_ratio = (factor == 1) rescue nil
  Graphics.integer_scaling = false rescue nil
  Graphics.smooth_scaling = 3 rescue nil
  Graphics.fullscreen = true rescue nil
end

#===============================================================================
#
#===============================================================================
class Bitmap
  attr_accessor :text_offset_y
end

class Game_Character
  def name; return ""; end unless method_defined?(:name)
end

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
  def [](i); @array[i]; end
  def []=(i, v); @array[i] = v; end
  def get_from_name(name)
    @array.each { |i| return i if i&.name == name }
    return nil
  end
end unless defined?(PBAnimations)

#===============================================================================
#
#===============================================================================
if System::VERSION != Essentials::MKXPZ_VERSION
  printf(sprintf("\e[1;33mWARNING: mkxp-z version %s detected, but this version of Pokémon Essentials was designed for mkxp-z version %s.\e[0m\r\n",
                 System::VERSION, Essentials::MKXPZ_VERSION))
  printf("\e[1;33mWARNING: Pokémon Essentials may not work properly.\e[0m\r\n")
end