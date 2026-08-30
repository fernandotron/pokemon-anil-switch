#===============================================================================
#
#-------------------------------------------------------------------------------
#                     Sistema de Ventanas del Salón de la Fama
#                             por JessWishes
#                      Porteado a v21 por Assistant
#-------------------------------------------------------------------------------
#
# Este archivo contiene el sistema de ventanas compatible con v21
# Reemplaza Window_UnformattedTextPokemon que no existe en v21
#
#===============================================================================

#===============================================================================
# Clase principal de ventanas de texto para el Salón de la Fama
#===============================================================================
class HallOfFameTextWindow < Sprite
  attr_reader :visible
  
  def initialize(text, x, y, width, height, viewport = nil)
    super(viewport)
    @text = text
    @x = x
    @y = y
    @width = width
    @height = height
    
    self.x = x
    self.y = y
    self.z = 100
    
    # Configuración de fuente
    @font_name = MessageConfig.pbGetSystemFontName rescue "Arial"
    @font_size = MessageConfig::SMALL_FONT_SIZE rescue 20
    
    # Crear bitmap para el texto
    @text_bitmap = Bitmap.new(width, height)
    @text_bitmap.font.name = @font_name
    @text_bitmap.font.size = @font_size
    
    # Crear sprite del fondo de ventana
    @window_sprite = Sprite.new(viewport)
    @window_sprite.bitmap = Bitmap.new(width, height)
    @window_sprite.x = x
    @window_sprite.y = y
    @window_sprite.z = 99
    
    # Sprite del texto
    @text_sprite = Sprite.new(viewport)
    @text_sprite.bitmap = @text_bitmap
    @text_sprite.x = x + 16
    @text_sprite.y = y + 16
    @text_sprite.z = 101
    
    # Estado inicial
    @visible = true
    @disposed = false
    
    # Dibujar contenido
    draw_window_background
    refresh
  end
  
  def text=(new_text)
    @text = new_text
    refresh
  end
  
  def visible=(value)
    @visible = value
    @window_sprite.visible = value
    @text_sprite.visible = value
  end
  
  def x=(value)
    @x = value
    super(value)
    @window_sprite.x = value if @window_sprite
    @text_sprite.x = value + 16 if @text_sprite
  end
  
  def y=(value)
    @y = value
    super(value)
    @window_sprite.y = value if @window_sprite
    @text_sprite.y = value + 16 if @text_sprite
  end
  
  def z=(value)
    super(value)
    @window_sprite.z = value - 1 if @window_sprite
    @text_sprite.z = value + 1 if @text_sprite
  end
  
  def opacity=(value)
    @window_sprite.opacity = value if @window_sprite
    @text_sprite.opacity = value if @text_sprite
  end
  
  def color=(value)
    @text_sprite.color = value if @text_sprite
  end
  
  def tone=(value)
    @window_sprite.tone = value if @window_sprite
  end
  
  def update
    @window_sprite.update if @window_sprite && !@window_sprite.disposed?
    @text_sprite.update if @text_sprite && !@text_sprite.disposed?
  end
  
  def dispose
    return if @disposed
    @disposed = true
    
    @text_bitmap&.dispose
    @window_sprite&.dispose
    @text_sprite&.dispose
    super
  end
  
  def disposed?
    return @disposed || super
  end
  
  private
  
  def draw_window_background
    return if !@window_sprite || !@window_sprite.bitmap
    
    bitmap = @window_sprite.bitmap
    bitmap.clear
    
    # Fondo semi-transparente
    bitmap.fill_rect(0, 0, @width, @height, Color.new(0, 0, 0, 160))
    
    # Borde exterior blanco
    border_color = Color.new(255, 255, 255)
    bitmap.fill_rect(0, 0, @width, 2, border_color)              # Top
    bitmap.fill_rect(0, @height - 2, @width, 2, border_color)    # Bottom
    bitmap.fill_rect(0, 0, 2, @height, border_color)             # Left
    bitmap.fill_rect(@width - 2, 0, 2, @height, border_color)    # Right
    
    # Borde interior para efecto 3D
    inner_color = Color.new(200, 200, 200)
    bitmap.fill_rect(2, 2, @width - 4, 1, inner_color)          # Top inner
    bitmap.fill_rect(2, @height - 3, @width - 4, 1, inner_color) # Bottom inner
    bitmap.fill_rect(2, 2, 1, @height - 4, inner_color)         # Left inner
    bitmap.fill_rect(@width - 3, 2, 1, @height - 4, inner_color) # Right inner
  end
  
  def refresh
    return if !@text_bitmap
    
    @text_bitmap.clear
    return if !@text || @text.empty?
    
    # Procesar tags de texto
    processed_text = process_text_tags(@text)
    
    # Dibujar texto con formato
    draw_formatted_text(processed_text, 0, 0, @width - 32, @height - 32)
  end
  
  def process_text_tags(text)
    return "" if !text
    
    # Procesar tags básicos como <ac> (center), <ar> (right), <b> (bold)
    processed = text.dup
    
    # Tag de centrado <ac>contenido</ac>
    processed.gsub!(/<ac>(.*?)<\/ac>/m) { |match|
      content = $1
      "\x01#{content}\x01"  # Marker para centrado
    }
    
    # Tag de centrado sin cierre <ac>contenido
    processed.gsub!(/<ac>(.*?)(?=<|$)/m) { |match|
      content = $1
      "\x01#{content}\x01"  # Marker para centrado
    }
    
    # Tag de alineación derecha <ar>contenido</ar>
    processed.gsub!(/<ar>(.*?)<\/ar>/m) { |match|
      content = $1
      "\x02#{content}\x02"  # Marker para derecha
    }
    
    # Tag de alineación derecha sin cierre <ar>contenido
    processed.gsub!(/<ar>(.*?)(?=<|$)/m) { |match|
      content = $1
      "\x02#{content}\x02"  # Marker para derecha
    }
    
    # Tag de negrita <b>contenido</b>
    processed.gsub!(/<b>(.*?)<\/b>/m) { |match|
      content = $1
      "\x03#{content}\x03"  # Marker para negrita
    }
    
    return processed
  end
  
  def draw_formatted_text(text, x, y, width, height)
    return if !text || text.empty?
    
    lines = text.split(/\n/)
    line_height = @text_bitmap.font.size + 4
    current_y = y
    
    lines.each do |line|
      next if current_y + line_height > y + height
      
      # Determinar alineación y limpiar markers
      alignment = :left
      clean_line = line
      
      if line.include?("\x01")  # Centrado
        alignment = :center
        clean_line = line.gsub(/\x01/, "")
      elsif line.include?("\x02")  # Derecha
        alignment = :right
        clean_line = line.gsub(/\x02/, "")
      end
      
      # Calcular posición X basada en alineación
      case alignment
      when :center
        text_width = calculate_text_width(clean_line)
        draw_x = x + (width - text_width) / 2
      when :right
        text_width = calculate_text_width(clean_line)
        draw_x = x + width - text_width
      else # :left
        draw_x = x
      end
      
      # Dibujar el texto con formato de negrita si es necesario
      if clean_line.include?("\x03")
        draw_bold_text(clean_line, draw_x, current_y, width, line_height)
      else
        @text_bitmap.draw_text(draw_x, current_y, width, line_height, clean_line)
      end
      
      current_y += line_height
    end
  end
  
  def calculate_text_width(text)
    # Remover markers de negrita para calcular ancho
    clean_text = text.gsub(/\x03/, "")
    return @text_bitmap.text_size(clean_text).width
  end
  
  def draw_bold_text(text, x, y, width, height)
    parts = text.split(/\x03/)
    temp_x = x
    
    parts.each_with_index do |part, index|
      next if part.empty?
      
      if index.odd?  # Parte en negrita
        old_bold = @text_bitmap.font.bold
        @text_bitmap.font.bold = true
        @text_bitmap.draw_text(temp_x, y, width, height, part)
        temp_x += @text_bitmap.text_size(part).width
        @text_bitmap.font.bold = old_bold
      else  # Parte normal
        @text_bitmap.draw_text(temp_x, y, width, height, part)
        temp_x += @text_bitmap.text_size(part).width
      end
    end
  end
end

#===============================================================================
# Extensión de sprites para compatibilidad adicional
#===============================================================================
class HallOfFameTextWindow
  # Método para compatibilidad con código existente
  def self.newWithSize(text, x, y, width, height, viewport = nil)
    return self.new(text, x, y, width, height, viewport)
  end
  
  # Métodos adicionales para compatibilidad
  def contents_opacity=(value)
    @text_sprite.opacity = value if @text_sprite
  end
  
  def contents_opacity
    return @text_sprite ? @text_sprite.opacity : 255
  end
  
  def windowskin=(value)
    # No implementado, pero evita errores
  end
  
  def back_opacity=(value)
    @window_sprite.opacity = value if @window_sprite
  end
  
  def back_opacity
    return @window_sprite ? @window_sprite.opacity : 255
  end
end

#===============================================================================
# Utilidades adicionales para el sistema de ventanas
#===============================================================================
module HallOfFameWindowUtils
  # Crear una ventana de texto simple
  def self.create_simple_window(text, x, y, width, height, viewport = nil)
    window = HallOfFameTextWindow.new(text, x, y, width, height, viewport)
    window.visible = false  # Empezar invisible por defecto
    return window
  end
  
  # Crear una ventana centrada en pantalla
  def self.create_centered_window(text, width, height, viewport = nil)
    x = (Graphics.width - width) / 2
    y = (Graphics.height - height) / 2
    return create_simple_window(text, x, y, width, height, viewport)
  end
  
  # Animar aparición de ventana
  def self.animate_window_in(window, duration = 10)
    return if !window || window.disposed?
    
    window.opacity = 0
    window.visible = true
    
    duration.times do |i|
      window.opacity = (255 * i / duration)
      Graphics.update
    end
    window.opacity = 255
  end
  
  # Animar desaparición de ventana
  def self.animate_window_out(window, duration = 10)
    return if !window || window.disposed?
    
    duration.times do |i|
      window.opacity = 255 - (255 * i / duration)
      Graphics.update
    end
    window.visible = false
  end
  
  # Limpiar múltiples ventanas
  def self.dispose_windows(window_hash)
    return if !window_hash
    
    window_hash.each_value do |window|
      next if !window || window.disposed?
      window.dispose
    end
  end
end

#===============================================================================
# Monkey patch para MessageConfig si no existe
#===============================================================================
if !defined?(MessageConfig)
  module MessageConfig
    SMALL_FONT_SIZE = 20
    
    def self.pbGetSystemFontName
      return "Arial"
    end
  end
end
