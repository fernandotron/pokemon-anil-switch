################################################################################
# "Caruban's Dynamic Darkness" v 1.2.1
# By Caruban
#-------------------------------------------------------------------------------
# I made this plugin after seeing NuriYuri's DynamicLight (PSDK). 
# With this plugin, you can make dark maps more lively with a light source that you can control freely.
# One example of this kind of darkness is Ecruteak's Gym in HGSS.
#
# SETTINGS
# In the plugin Settings section, you may edit several variables.
# Below is a list of the settings.
# - INITIAL_DARKNESS_CIRCLE
# The initial radius of the darkness circle on dark maps
# - FLASH_CIRCLE_RADIUS
# Radius of darkness circle while using Flash
# - VARIABLE_RADIUS_DARK_MAP
# Variable ID of initial radius based on Map ID
# Any radius changes on these map IDs will be reset after the player gets 
# out of the dark map and saved to this variable.
# - INITIAL_DARKNESS_OPACITY
# Initial opacity of darkness on dark maps
# - OPACITY_DARK_MAP_BY_ID
# Value of initial opacity based on Map ID
# This will give a different opacity for every map IDs listed here.
# - FLASH_PROHIBITED_MAPS
# List of maps that prohibit the player from using flash.
# - FLASHLIGHT_ONLY_MAPS
# List of maps where the player will automatically use a flashlight and also prohibit player to use Flash.
# - INITIAL_FLASHLIGHT_DIST
# Initial value of distance for a flashlight.
# - FLASHLIGHT_MAX_DIST
# The initial value of the maximum distance for a flashlight.
# - FLASHLIGHT_X_OFFSET and FLASHLIGHT_Y_OFFSET
# The value of a flashlight's light sources X and Y offset
# from the centre of the character sprites.
# - CUSTOM_IMAGE_DARKNESS
# Custom darkness images based on Map ID.
# Images are located in "Graphics/Fogs/".
#
# SCRIPT COMMANDS
# There are several script commands that you can use to control the darkness.
# Below is a list of script commands.
# - pbGetDarknessOpacity
# This script command is used to get the darkness opacity on the current map.
# - pbGetDarknessRadius
# This script command is used to get the darkness radius on the current map.
# - pbSetDarknessRadius(value)
# This script command is used to set the darkness radius on the current map.
# - pbMoveDarknessRadius(value)
# This script command is used to change the darkness radius gradually on the current map.
# - pbMoveDarknessRadiusMax
# This script command is used to change the darkness radius gradually to the max on the current map. 
# It will fully brighten the map.
# - pbMoveDarknessRadiusMin
# This script command is used to change the darkness radius gradually to the min on the current map.
# The player will be lost its light source.
#
# EVENT BEHAVIOURS
# These are several pieces of text that can be put into the event's name,
# which will cause those events to have particular behaviours.
# Below is a list of those texts and behaviours.
# - "glowalways"
# An event with this text in its name will always become a light source.
# - "glowswitch(X)"
# An event with this text in its name will become a light source if the switch is ON.
# The "X" is the game variable ID (1 - xxx) or the event's self switch (A, B, C, or D).
# - "glowswitchreverse"
# An event with this text in its name will become a light source if it has "glowswitch(X)" 
# in its name and the switch is OFF. The "X" is the game variable ID (1 - xxx) or 
# the event's self switch (A, B, C, or D).
# - "glowsize(X)"
# An event with this text in its name will become a light source with a radius of "X" pixels.
# This is also treated as "glowalways" if there is no "glowswitch(X)" in its name.
# - "glowstatic"
# An event with this text in its name will become a static light source.
# This is also treated as "glowalways" if there is no "glowswitch(X)" in its name.
# - "flashlight" or "flashlight(X)"
# An event with this text in its name will use a flashlight.
# The "X" is the distance of the flashlight (max. FLASHLIGHT_MAX_DIST).
#
################################################################################
# Configuration
################################################################################
module Settings
  # The initial radius of the darkness circle on dark maps
  INITIAL_DARKNESS_CIRCLE = 64

  # Radius of darkness circle while using Flash
  FLASH_CIRCLE_RADIUS = 200 # 176

  # Variable ID of initial radius based on Map ID
  # Any radius changes on these map IDs will be reset after the player gets 
  # out of the dark map and saved to this variable.
  VARIABLE_RADIUS_DARK_MAP = {
    # Map ID => Variable ID
    # 50 => 26,
  }

  # Initial opacity of darkness on dark maps
  INITIAL_DARKNESS_OPACITY = 245#255

  # Value of initial opacity based on Map ID
  # This will give a different opacity for every map IDs listed here.
  OPACITY_DARK_MAP_BY_ID = {
    # Map ID => Opacity value
    # 52 => 200,
  }

  # List of maps that prohibit the player from using flash
  FLASH_PROHIBITED_MAPS = [
    50,
  ]

  # List of maps where the player will automatically use a flashlight
  # and also prohibit player to use Flash.
  FLASHLIGHT_ONLY_MAPS = [
    50,
  ]

  # Initial value of distance for a flashlight
  INITIAL_FLASHLIGHT_DIST = 2

  # The initial value of the maximum distance for a flashlight
  FLASHLIGHT_MAX_DIST = 3

  # The value of a flashlight's light sources X and Y offset
  # from the centre of the character sprites
  FLASHLIGHT_X_OFFSET = 0
  FLASHLIGHT_Y_OFFSET = 12

  # Custom darkness images based on Map ID
  # Images are located in "Graphics/Fogs/"
  CUSTOM_IMAGE_DARKNESS = {
    # Map ID => "Custom Darkness Image file"
    50 => "DarkMap_50",
  }
end

################################################################################
# Global Variable
################################################################################
class PokemonGlobalMetadata
  # @return [Integer] global darkness radius
  attr_accessor   :darknessRadius
end

################################################################################
# Global Function
################################################################################
# @return [Integer] Opacity of darkness on dark map in this map
def pbGetDarknessOpacity
  opacity = Settings::OPACITY_DARK_MAP_BY_ID[$game_map.map_id]
  opacity = Settings::INITIAL_DARKNESS_OPACITY if !opacity
  return opacity
end

# @return [Integer] Radius of darkness on dark map in this map
def pbGetDarknessRadius
  map_id = $game_map.map_id
  var = Settings::VARIABLE_RADIUS_DARK_MAP[map_id]
  if Settings::FLASHLIGHT_ONLY_MAPS.include?(map_id)
    radius = 0
  elsif var && $game_variables[var]
    radius = $game_variables[var]
  elsif $PokemonGlobal.darknessRadius
    radius = $PokemonGlobal.darknessRadius
  else
    radius = Settings::INITIAL_DARKNESS_CIRCLE
  end
  return radius
end

# Set Radius of darkness on dark map in this map
def pbSetDarknessRadius(value)
  return if value < 0
  return if Settings::FLASHLIGHT_ONLY_MAPS.include?($game_map.map_id)
  return if !$game_temp.darkness_sprite
  darkness = $game_temp.darkness_sprite
  darkness.radius = value
end

# Change darkness circle radius with animation
def pbMoveDarknessRadius(value)
  return if !$game_temp.darkness_sprite
  return if Settings::FLASHLIGHT_ONLY_MAPS.include?($game_map.map_id)
  darkness = $game_temp.darkness_sprite
  value = [darkness.radiusMax, [darkness.radiusMin, value].max].min
  darkness.moveRadius(value)
end

def pbMoveDarknessRadiusMax
  return if !$game_temp.darkness_sprite
  return if Settings::FLASHLIGHT_ONLY_MAPS.include?($game_map.map_id)
  darkness = $game_temp.darkness_sprite
  darkness.moveRadius(darkness.radiusMax)
end

def pbMoveDarknessRadiusMin
  return if !$game_temp.darkness_sprite
  return if Settings::FLASHLIGHT_ONLY_MAPS.include?($game_map.map_id)
  darkness = $game_temp.darkness_sprite
  darkness.moveRadius(darkness.radiusMin)
end

################################################################################
# Event Handlers
################################################################################
# Display darkness circle on dark maps.
EventHandlers.add(:on_map_or_spriteset_change, :show_darkness,
  proc { |scene, _map_changed|
    next if !scene || !scene.spriteset
    map_metadata = $game_map.metadata
    if map_metadata&.dark_map
      $game_temp.darkness_sprite = DarknessSprite.new
      scene.spriteset.addUserSprite($game_temp.darkness_sprite)
      if $PokemonGlobal.flashUsed
        $game_temp.darkness_sprite.radius = Settings::FLASH_CIRCLE_RADIUS
      end
      $PokemonGlobal.darknessRadius = $game_temp.darkness_sprite.radius
    else
      $PokemonGlobal.flashUsed = false
      $game_temp.darkness_sprite&.dispose
      $game_temp.darkness_sprite = nil
      $PokemonGlobal.darknessRadius = nil
    end
  }
)

#===============================================================================
# Flash Handlers
#===============================================================================
=begin
HiddenMoveHandlers::CanUseMove.add(:FLASH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_FLASH, showmsg)
  if !$game_map.metadata&.dark_map || Settings::FLASH_PROHIBITED_MAPS.include?($game_map.map_id) || 
     Settings::FLASHLIGHT_ONLY_MAPS.include?($game_map.map_id)
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  if $PokemonGlobal.flashUsed
    pbMessage(_INTL("Flash is already being used.")) if showmsg
    next false
  end
  if $game_temp.darkness_sprite && pbGetDarknessRadius >= Settings::FLASH_CIRCLE_RADIUS
    pbMessage(_INTL("It is already bright here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLASH, proc { |move, pokemon|
  darkness = $game_temp.darkness_sprite
  next false if !darkness || darkness.disposed?
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $PokemonGlobal.flashUsed = true
  $stats.flash_count += 1
  duration = 0.7
  old_rad = darkness.radius
  pbWait(duration) do |delta_t|
    darkness.radius = lerp(old_rad, Settings::FLASH_CIRCLE_RADIUS, duration, delta_t)
  end
  darkness.radius = Settings::FLASH_CIRCLE_RADIUS
  next true
})
=end



################################################################################
# Darkness Sprites
################################################################################
class DarknessSprite < Sprite
  attr_reader :radius

  def initialize(viewport = nil)
    super(viewport)
    @darkness = Bitmap.new(Graphics.width, Graphics.height)
    @radius = pbGetDarknessRadius
    @light_modifier = 0
    @light_starttime = System.real_uptime
    @last_refresh_time = 0
    @refresh_interval = 4  # Only refresh every 4 frames (~15 FPS refresh rate)
    @frame_counter = 0
    @cached_events = nil
    @last_player_x = -1
    @last_player_y = -1
    @last_radius = -1
    @last_light_modifier = 0
    @needs_full_refresh = true
    self.bitmap = @darkness
    self.z      = 99998
    self.radius = @radius
  end
  
  def radiusMin; return 0;  end
  def radiusMax; return 320; end

  def radius=(value)
    @radius = value.round
    var = Settings::VARIABLE_RADIUS_DARK_MAP[$game_map.map_id]
    if var
      $game_variables[var] = @radius
    elsif $PokemonGlobal.darknessRadius
      $PokemonGlobal.darknessRadius = @radius
    end
    @needs_full_refresh = true
    refresh
  end

  def moveRadius(value)
    return if value < 0 || value == @radius
    duration = 0.7
    old_rad = @radius
    pbWait(duration) do |delta_t|
      self.radius = lerp(old_rad, value, duration, delta_t)
    end
    self.radius = value
  end

  def refresh(force = false)
    # Only refresh if necessary
    player_moved = (@last_player_x != $game_player.x || @last_player_y != $game_player.y)
    radius_changed = (@last_radius != @radius)
    light_modifier_changed = (@last_light_modifier != @light_modifier)
    
    return unless force || @needs_full_refresh || player_moved || radius_changed || light_modifier_changed
    
    @last_player_x = $game_player.x
    @last_player_y = $game_player.y
    @last_radius = @radius
    @last_light_modifier = @light_modifier
    @needs_full_refresh = false
    
    @darkness.clear
    return if @radius >= radiusMax
    
    # Initial dark screen
    darkness_image = Settings::CUSTOM_IMAGE_DARKNESS[$game_map.map_id]
    if darkness_image && pbResolveBitmap("Graphics/Fogs/#{darkness_image}")
      darknessbitmap = AnimatedBitmap.new("Graphics/Fogs/#{darkness_image}")
      tmox = ($game_map.display_x / Game_Map::X_SUBPIXELS).round
      tmoy = ($game_map.display_y / Game_Map::Y_SUBPIXELS).round
      @darkness.blt(-tmox, -tmoy, darknessbitmap.bitmap, Rect.new(0, 0, darknessbitmap.width, darknessbitmap.height))
      darknessbitmap.dispose
    else
      @darkness.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0,0,0, pbGetDarknessOpacity))
    end
    
    # Cache events if player moved significantly or cache is empty
    if @cached_events.nil? || player_moved
      @cached_events = get_nearby_events
    end
    
    numfades = 3
    fade_trans = 0.9
    cradius = @radius + @light_modifier
    # Make deep copies to avoid modifying cached values
    events_pos = @cached_events[:light_sources].map(&:dup)
    flashlights = @cached_events[:flashlights].map(&:dup)
    
    # Get player position on screen
    cx = Graphics.width / 2
    cy = Graphics.height / 2
    flashlight_radius = 32
    
    # Only use flashlight in specific maps
    if Settings::FLASHLIGHT_ONLY_MAPS.include?($game_map.map_id)
      flashlights.push([cx, cy, $game_player.direction, 
                        getFlashlightDistance($game_player, Settings::INITIAL_FLASHLIGHT_DIST), flashlight_radius])
    end
    
    # Draw circle
    (1..numfades).each do |i|
      # Player
      drawCircle(cx,cy,numfades,i,cradius) if @radius > 0
      cradius = (cradius * fade_trans).floor
      # Events
      events_pos.each do |ev|
        next if !ev[3] # switch
        drawCircle(ev[0],ev[1],numfades,i,ev[2])
        ev[2] = (ev[2] * fade_trans).floor
      end
      # Draw Flashlight
      next if i > 2 # Only use 2 shade
      flashlights.each do |ev|
        drawFlashlight(ev[0], ev[1], ev[2], ev[3], ev[4] , i, 2)
        ev[4] = (ev[4] * fade_trans).floor
      end
    end
  end

  # Cache nearby events to avoid repeated calculations
  def get_nearby_events
    events_pos = []
    flashlights = []
    distancia_desaparecer = 13
    
    $game_map.events.each_value { |event|
      # Fast distance check using squared distance
      dx = event.x - $game_player.x
      dy = event.y - $game_player.y
      next if dx.abs > distancia_desaparecer || dy.abs > distancia_desaparecer
      
      # Cache event properties to avoid repeated regex matching
      event_props = get_event_properties(event)
      next unless event_props[:has_light] || event_props[:has_flashlight]
      
      event_x = event.screen_x
      event_y = event.screen_y - event.sprite_size[1]/2
      
      if event_props[:has_light]
        cradius_e = event_props[:glow_size]
        cradius_e += @light_modifier unless event_props[:is_static]
        
        switch_active = true
        if event_props[:switch_id]
          switch_active = check_event_switch(event, event_props[:switch_id], event_props[:reverse_switch])
        end
        
        events_pos.push([event_x, event_y, cradius_e, switch_active])
      end
      
      if event_props[:has_flashlight]
        flashlights.push([event_x, event_y, event.direction, 
                         getFlashlightDistance(event, event_props[:flashlight_dist]), 24])
      end
    }
    
    { light_sources: events_pos, flashlights: flashlights }
  end

  # Cache event properties to avoid repeated regex matching
  def get_event_properties(event)
    name = event.name
    props = {
      has_light: false,
      has_flashlight: false,
      glow_size: Settings::INITIAL_DARKNESS_CIRCLE,
      is_static: false,
      switch_id: nil,
      reverse_switch: false,
      flashlight_dist: Settings::INITIAL_FLASHLIGHT_DIST
    }
    
    # Check for light properties
    if name.match(/glowalways/i) || name.match(/glowsize\((\d+)\)/i) || name.match(/glowstatic/i)
      props[:has_light] = true
      props[:glow_size] = $1.to_i if $1
      props[:is_static] = true if name.match(/glowstatic/i)
    end
    
    # Check for switch
    if match = name.match(/glowswitch\((\w+)\)/i)
      props[:has_light] = true
      props[:switch_id] = match[1]
      props[:reverse_switch] = name.match(/glowswitchreverse/i)
    end
    
    # Check for flashlight
    if match = name.match(/flashlight(?:\((\d+)\))?/i)
      props[:has_flashlight] = true
      props[:flashlight_dist] = [[$1.to_i, 1].max, Settings::FLASHLIGHT_MAX_DIST].min if $1
    end
    
    props
  end

  def check_event_switch(event, switch_id, reverse)
    switch = reverse
    if switch_id.to_i.to_s == switch_id && $game_switches[switch_id.to_i]
      switch = !reverse
    elsif !event.isOff?(switch_id)
      switch = !reverse
    end
    switch
  end

  def drawCircle(cx, cy, numfades, i, cradius, dir = 0) # Added dir to draw half circle
    return if cradius <= 0
    
    alpha = pbGetDarknessOpacity.to_f * (numfades - i) / numfades
    cradius_squared = cradius * cradius
    
    # Optimize by calculating bounds first
    x_start = [0, cx - cradius].max
    x_end = [Graphics.width, cx + cradius].min
    
    (x_start..x_end).step(2) do |j|
      next if dir == 4 && j > cx
      next if dir == 6 && j < cx
      
      diff2 = cradius_squared - ((j - cx) * (j - cx))
      next if diff2 < 0
      
      diff = Math.sqrt(diff2).to_i
      diff += 1 if diff.odd?
      
      # Calculate y bounds to avoid drawing outside screen
      y_top = [0, cy - diff].max
      y_bottom = [Graphics.height, cy + diff].min
      
      case dir
      when 8 # up
        height = [cy, y_bottom].min - y_top
        @darkness.fill_rect(j, y_top, 2, height, Color.new(0, 0, 0, alpha)) if height > 0
      when 2 # down
        height = y_bottom - [cy, y_top].max
        @darkness.fill_rect(j, [cy, y_top].max, 2, height, Color.new(0, 0, 0, alpha)) if height > 0
      else
        height = y_bottom - y_top
        @darkness.fill_rect(j, y_top, 2, height, Color.new(0, 0, 0, alpha)) if height > 0
      end
    end
  end

  def drawFlashlight(cx, cy, dir, distance, cradius, fade, numfades)
    width = cradius
    barwidth = cradius/4
    xOffset = 0
    yOffset = 0
    cx += Settings::FLASHLIGHT_X_OFFSET
    cy += Settings::FLASHLIGHT_Y_OFFSET
    alpha = pbGetDarknessOpacity.to_f * (numfades - fade) / numfades
    # Light bar
    case dir
    when 2 
      yOffset += distance
      @darkness.fill_rect(cx - barwidth/2, cy, barwidth, distance + 2, Color.new(0, 0, 0, alpha))
    when 4
      xOffset -= distance
      @darkness.fill_rect(cx - distance - 2, cy - barwidth/2, distance + 2, barwidth, Color.new(0, 0, 0, alpha))
    when 6 
      xOffset += distance
      @darkness.fill_rect(cx, cy - barwidth/2, distance + 2, barwidth, Color.new(0, 0, 0, alpha))
    when 8
      yOffset -= distance
      @darkness.fill_rect(cx - barwidth/2, cy - distance - 2, barwidth, distance + 2, Color.new(0, 0, 0, alpha))
    end
    # Circle around the event
    drawCircle(cx, cy, numfades, fade, barwidth*2)
    # Half circle
    drawCircle(cx + xOffset, cy + yOffset, numfades, fade, cradius, dir)
    # Triangle
    w = width / 2
    w.times do |i|
      diff = ((i + 1) * distance / w)
      diff += 1 if diff.odd?
      case dir
      when 2
        @darkness.fill_rect(cx + (i + 1)*2 - cradius, cy - diff + distance, 2, diff, Color.new(0, 0, 0, alpha)) # left
        @darkness.fill_rect(cx - (i + 1)*2 + cradius, cy - diff + distance, 2, diff, Color.new(0, 0, 0, alpha)) # right
      when 4
        @darkness.fill_rect(cx - distance, cy - cradius + (i*2)    , diff, 2, Color.new(0, 0, 0, alpha)) # up
        @darkness.fill_rect(cx - distance, cy + cradius - (i*2) - 2, diff, 2, Color.new(0, 0, 0, alpha)) # down
      when 6 
        @darkness.fill_rect(cx + distance - diff, cy- cradius + (i*2)     , diff + 2, 2, Color.new(0, 0, 0, alpha)) # up
        @darkness.fill_rect(cx + distance - diff, cy + cradius - (i*2) - 2, diff + 2, 2, Color.new(0, 0, 0, alpha)) # down
      when 8
        @darkness.fill_rect(cx + (i + 1)*2 - cradius, cy - distance, 2, diff, Color.new(0, 0, 0, alpha)) # left
        @darkness.fill_rect(cx - (i + 1)*2 + cradius, cy - distance, 2, diff, Color.new(0, 0, 0, alpha)) # right
      end
    end
  end

  def getFlashlightDistance(event, maximum_d = Settings::FLASHLIGHT_MAX_DIST)
    dir = event.direction
    xOffset = 0 ; yOffset = 0
    # Event XY Offset
    case dir
    when 2 then yOffset += 1
    when 4 then xOffset -= 1
    when 6 then xOffset += 1
    when 8 then yOffset -= 1
    end
    # Get passable max distance
    max_dist = 1
    maximum_d.times do |i|
      break if !event.passable?(event.x + xOffset * i, event.y + yOffset * i, dir)
      max_dist += 1
    end
    if max_dist > maximum_d
      distance = maximum_d * 32 # The farthest distance of flashlight
    else                        # Get real distance in pixel
      case dir
      when 2
        distance = (event.real_y - (event.y + max_dist) * Game_Map::REAL_RES_Y).abs / Game_Map::Y_SUBPIXELS
      when 8
        distance = (event.real_y - (event.y - max_dist) * Game_Map::REAL_RES_Y).abs / Game_Map::Y_SUBPIXELS
      when 4
        distance = (event.real_x - (event.x - max_dist) * Game_Map::REAL_RES_X).abs / Game_Map::X_SUBPIXELS
      when 6
        distance = (event.real_x - (event.x + max_dist) * Game_Map::REAL_RES_X).abs / Game_Map::X_SUBPIXELS
      end
      distance = distance.to_i.abs
    end
    return distance
  end

  def dispose
    @darkness&.dispose
    @cached_events = nil
    super
  end

  def force_refresh
    @needs_full_refresh = true
    @cached_events = nil
  end

  alias caruban_update update unless method_defined?(:caruban_update)
  def update
    @frame_counter += 1
    # Update light modifier for breathing effect
    duration = 2  # Seconds
    size = 6      # Max light modifier in pixel
    @light_starttime = System.real_uptime if System.real_uptime - @light_starttime > duration
    if System.real_uptime - @light_starttime < duration / 2
      @light_modifier = lerp(0, -size, duration / 2, @light_starttime, System.real_uptime).to_i
    else
      @light_modifier = lerp(-size, 0, duration / 2, @light_starttime + duration / 2, System.real_uptime).to_i
    end

    caruban_update

    # Always refresh to maintain breathing animation
    refresh
  end
end
