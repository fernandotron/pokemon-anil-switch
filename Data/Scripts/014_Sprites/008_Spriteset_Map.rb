#===============================================================================
# Unused.
#===============================================================================
class ClippableSprite < Sprite_Character
  def initialize(viewport, event, tilemap)
    @tilemap = tilemap
    @_src_rect = Rect.new(0, 0, 0, 0)
    super(viewport, event)
  end

  def update
    super
    @_src_rect = self.src_rect
    tmright = (@tilemap.map_data.xsize * Game_Map::TILE_WIDTH) - @tilemap.ox
    echoln "x=#{self.x},ox=#{self.ox},tmright=#{tmright},tmox=#{@tilemap.ox}"
    if @tilemap.ox - self.ox < -self.x
      # clipped on left
      diff = -self.x - @tilemap.ox + self.ox
      self.src_rect = Rect.new(@_src_rect.x + diff, @_src_rect.y,
                               @_src_rect.width - diff, @_src_rect.height)
      echoln "clipped out left: #{diff} #{@tilemap.ox - self.ox} #{self.x}"
    elsif tmright - self.ox < self.x
      # clipped on right
      diff = self.x - tmright + self.ox
      self.src_rect = Rect.new(@_src_rect.x, @_src_rect.y,
                               @_src_rect.width - diff, @_src_rect.height)
      echoln "recortado hacia la derecha: #{diff} #{tmright + self.ox} #{self.x}"
    else
      echoln "-no- recortado hacia la izquierda: #{diff} #{@tilemap.ox - self.ox} #{self.x}"
    end
  end
end

#===============================================================================
#
#===============================================================================
class Spriteset_Map
  attr_reader :map
  attr_accessor :character_sprites

  @@viewport0 = Viewport.new(0, 0, Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)   # Panorama
  @@viewport0.z = -100
  @@viewport1 = Viewport.new(0, 0, Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)   # Map, events, player, fog
  @@viewport1.z = 0
  @@viewport3 = Viewport.new(0, 0, Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)   # Flashing
  @@viewport3.z = 500

  # For access by Spriteset_Global.
  def self.viewport
    return @@viewport1
  end

  def initialize(map = nil)
    @map = (map) ? map : $game_map
    m_id = @map&.map_id || 0
    log_compat("[Scene_Map] Spriteset_Map.initialize START for map #{m_id}") rescue nil
    if $scene && $scene.respond_to?(:map_renderer) && $scene.map_renderer
      log_compat("[Scene_Map] Spriteset_Map: adding tileset #{@map.tileset_name}") rescue nil
      begin
        $scene.map_renderer.add_tileset(@map.tileset_name)
      rescue Exception => e
        log_compat("[Scene_Map] ERROR add_tileset: #{e.class} - #{e.message}") rescue nil
      end
      log_compat("[Scene_Map] Spriteset_Map: adding autotiles") rescue nil
      begin
        @map.autotile_names.each { |filename| $scene.map_renderer.add_autotile(filename) rescue nil }
      rescue Exception => e
        log_compat("[Scene_Map] ERROR add_autotiles: #{e.class} - #{e.message}") rescue nil
      end
      begin
        $scene.map_renderer.add_extra_autotiles(@map.tileset_id) rescue nil
      rescue Exception
      end
    end
    log_compat("[Scene_Map] Spriteset_Map: panorama and fog") rescue nil
    @panorama = AnimatedPlane.new(@@viewport0) rescue nil
    @fog = AnimatedPlane.new(@@viewport1) rescue nil
    @fog.z = 3000 if @fog
    @character_sprites = []
    if @map && @map.events
      ev_count = @map.events.size rescue 0
      log_compat("[Scene_Map] Spriteset_Map: creating #{ev_count} character sprites") rescue nil
      @map.events.keys.sort.each do |i|
        next if !@map.events[i]
        begin
          sprite = Sprite_Character.new(@@viewport1, @map.events[i])
          @character_sprites.push(sprite) if sprite
        rescue Exception => e
          log_compat("[Scene_Map] ERROR creating character sprite #{i} (#{@map.events[i]&.name}): #{e.class} - #{e.message}") rescue nil
        end
      end
    end
    log_compat("[Scene_Map] Spriteset_Map: on_new_spriteset_map trigger") rescue nil
    begin
      EventHandlers.trigger(:on_new_spriteset_map, self, @@viewport1)
    rescue Exception => e
      log_compat("[Scene_Map] ERROR on_new_spriteset_map: #{e.class} - #{e.message}") rescue nil
    end
    log_compat("[Scene_Map] Spriteset_Map: update") rescue nil
    begin
      update
    rescue Exception => e
      log_compat("[Scene_Map] ERROR Spriteset_Map#update: #{e.class} - #{e.message}") rescue nil
    end
    log_compat("[Scene_Map] Spriteset_Map.initialize COMPLETED for map #{m_id}") rescue nil
  end

  def dispose
    if $scene.is_a?(Scene_Map)
      $scene.map_renderer.remove_tileset(@map.tileset_name)
      @map.autotile_names.each { |filename| $scene.map_renderer.remove_autotile(filename) }
      $scene.map_renderer.remove_extra_autotiles(@map.tileset_id)
    end
    @panorama.dispose
    @fog.dispose
    @character_sprites.each { |sprite| sprite.dispose }
    @panorama = nil
    @fog = nil
    @character_sprites.clear
  end

  def getAnimations
    return @usersprites
  end

  def restoreAnimations(anims)
    @usersprites = anims
  end

  def update
    if @panorama_name != @map.panorama_name || @panorama_hue != @map.panorama_hue
      @panorama_name = @map.panorama_name
      @panorama_hue  = @map.panorama_hue
      @panorama.set_panorama(nil) if !@panorama.bitmap.nil?
      @panorama.set_panorama(@panorama_name, @panorama_hue) if !nil_or_empty?(@panorama_name)
      Graphics.frame_reset
    end
    if @fog_name != @map.fog_name || @fog_hue != @map.fog_hue
      @fog_name = @map.fog_name
      @fog_hue = @map.fog_hue
      @fog.set_fog(nil) if !@fog.bitmap.nil?
      @fog.set_fog(@fog_name, @fog_hue) if !nil_or_empty?(@fog_name)
      Graphics.frame_reset
    end
    tmox = (@map.display_x / Game_Map::X_SUBPIXELS).round
    tmoy = (@map.display_y / Game_Map::Y_SUBPIXELS).round
    @@viewport1.rect.set(0, 0, Graphics.width, Graphics.height)
    @@viewport1.ox = 0
    @@viewport1.oy = 0
    @@viewport1.ox += $game_screen.shake
    @panorama.ox = tmox / 2
    @panorama.oy = tmoy / 2
    @fog.ox         = tmox + @map.fog_ox
    @fog.oy         = tmoy + @map.fog_oy
    @fog.zoom_x     = @map.fog_zoom / 100.0
    @fog.zoom_y     = @map.fog_zoom / 100.0
    @fog.opacity    = @map.fog_opacity
    @fog.blend_type = @map.fog_blend_type
    @fog.tone       = @map.fog_tone
    @panorama.update
    @fog.update
    @character_sprites.each do |sprite|
      sprite.update
    end
    @@viewport1.tone = $game_screen.tone
    @@viewport3.color = $game_screen.flash_color
    @@viewport1.update
    @@viewport3.update
  end
end

