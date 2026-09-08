#===============================================================================
# Additional Character state
#===============================================================================
class Game_Character
  attr_accessor :pattern_rockclimb
  attr_accessor :pattern_lifting
  attr_accessor :pattern_lavasurf
  attr_accessor :always_on_top

  alias aifm_initialize initialize
  def initialize(map = nil)
    aifm_initialize(map)
    @pattern_rockclimb  = 0
    @pattern_lifting    = 0
    @pattern_lavasurf   = 0
  end
end

class PokemonMapMetadata
  attr_accessor :liftUsed

  alias original_clear clear

  def clear
    original_clear
    @liftUsed = false
  end
end
#===============================================================================
# PokemonGlobalMetadata
#===============================================================================
class PokemonGlobalMetadata
  # Player data
  attr_accessor :camouflage
  attr_accessor :revealtruth
  attr_accessor :revealstepcount
  attr_accessor :revealtruthcooldown
  #Movement
  attr_accessor :crossing_whirlpool
  attr_accessor :rockclimb
  attr_accessor :lavafishing
  attr_accessor :lavasurfing
  attr_accessor :descending_lavafall
  attr_accessor :ascending_lavafall
  attr_accessor :crossing_lavaswirl
  #Movement Spirtes
  attr_accessor :lifting
  attr_accessor :base_pkmn_surf
  attr_accessor :base_pkmn_dive
  attr_accessor :base_pkmn_rockclimb
  attr_accessor :base_pkmn_lavasurf
  attr_accessor :divingpkmn

  alias aifm_initialize initialize
  def initialize
    aifm_initialize
    # Player data
    @camouflage                     = false
    @revealtruth                    = false
    @revealstepcount                = 0
    @revealtruthcooldown            = nil
    #Movement
    @crossing_whirlpool             = false
    @rockclimb                      = false
    @lifting                        = false
    @lavasurfing                    = false
    @descending_lavafall            = false
    @ascending_lavafall             = false
    @crossing_lavaswirl             = false
    #Movement Spirtes
    @base_pkmn_surf                 = nil
    @base_pkmn_dive                 = nil
    @base_pkmn_rockclimb            = nil
    @base_pkmn_lavasurf             = nil
    @divingpkmn                     = false
  end

  def forced_movement?
    moveWater = @descending_waterfall || @ascending_waterfall || @crossing_whirlpool
    moveLava  = @descending_lavafall || @ascending_lavafall || @crossing_lavaswirl
    return @ice_sliding || moveWater || moveLava
  end

  def forced_rockclimb?
    return @rockclimb
  end
end

#===============================================================================
# Overwrites functions locally to add the Lava Surf & Rock Climb section
#===============================================================================
class Game_Map
  def passable?(x, y, d, self_event = nil)
    return false if !valid?(x, y)
    bit = (1 << ((d / 2) - 1)) & 0x0f
    events.each_value do |event|
      next if event.tile_id <= 0
      next if event == self_event
      next if !event.at_coordinate?(x, y)
      next if event.through
      next if GameData::TerrainTag.try_get(@terrain_tags[event.tile_id]).ignore_passability
      passage = @passages[event.tile_id]
      return false if passage & bit != 0
      return false if passage & 0x0f == 0x0f
      return true if @priorities[event.tile_id] == 0
    end
    return playerPassable?(x, y, d, self_event) if self_event == $game_player
    # All other events
    newx = x
    newy = y
    case d
    when 1
      newx -= 1
      newy += 1
    when 2
      newy += 1
    when 3
      newx += 1
      newy += 1
    when 4
      newx -= 1
    when 6
      newx += 1
    when 7
      newx -= 1
      newy -= 1
    when 8
      newy -= 1
    when 9
      newx += 1
      newy -= 1
    end
    return false if !valid?(newx, newy)
    [2, 1, 0].each do |i|
      tile_id = data[x, y, i]
      terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
      # If already on water, only allow movement to another water tile
      if self_event && terrain.can_surf_freely
        [2, 1, 0].each do |j|
          facing_tile_id = data[newx, newy, j]
          next if facing_tile_id == 0
          return false if facing_tile_id.nil?
          facing_terrain = GameData::TerrainTag.try_get(@terrain_tags[facing_tile_id])
          if facing_terrain.id != :None && !facing_terrain.ignore_passability
            return facing_terrain.can_surf_freely
          end
        end
        return false
        # If already on lava, only allow movement to another lava tile
      elsif self_event && terrain.can_lavasurf_freely
        [2, 1, 0].each do |j|
          facing_tile_id = data[newx, newy, j]
          next if facing_tile_id == 0
          return false if facing_tile_id.nil?
          facing_terrain = GameData::TerrainTag.try_get(@terrain_tags[facing_tile_id])
          if facing_terrain.id != :None && !facing_terrain.ignore_passability
            return facing_terrain.can_lavasurf_freely
          end
        end
        return false
      # Can't walk onto ice
      elsif terrain.ice
        return false
      elsif self_event && self_event.x == x && self_event.y == y
        # Can't walk onto ledges
        [2, 1, 0].each do |j|
          facing_tile_id = data[newx, newy, j]
          next if facing_tile_id == 0
          return false if facing_tile_id.nil?
          facing_terrain = GameData::TerrainTag.try_get(@terrain_tags[facing_tile_id])
          return false if facing_terrain.ledge
          break if facing_terrain.id != :None && !facing_terrain.ignore_passability
        end
      end
      next if terrain&.ignore_passability
      next if tile_id == 0
      # Regular passability checks
      passage = @passages[tile_id]
      return false if passage & bit != 0 || passage & 0x0f == 0x0f
      return true if @priorities[tile_id] == 0
    end
    return true
  end

  def playerPassable?(x, y, d, self_event = nil)
    bit = (1 << ((d / 2) - 1)) & 0x0f
    [2, 1, 0].each do |i|
      tile_id = data[x, y, i]
      next if tile_id == 0
      terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
      passage = @passages[tile_id]
      if terrain
        # Ignore bridge tiles if not on a bridge
        next if terrain.bridge && $PokemonGlobal.bridge == 0
        # Make water tiles passable if player is surfing
        return true if $PokemonGlobal.surfing && terrain.can_surf && !terrain.waterfall && !terrain.whirlpool
        # Make lava tiles passable if player is lavasurfing
        return true if $PokemonGlobal.lavasurfing && terrain.can_lavasurf && !terrain.lavafall && !terrain.lavaswirl
        # Make rockclimb tiles passable if player is climbing
        return true if $PokemonGlobal.rockclimb && terrain.can_climb
        # Prevent cycling in really tall grass/on ice
        return false if $PokemonGlobal.bicycle && terrain.must_walk
        # Depend on passability of bridge tile if on bridge
        if terrain.bridge && $PokemonGlobal.bridge > 0
          return (passage & bit == 0 && passage & 0x0f != 0x0f)
        end
      end
      next if terrain&.ignore_passability
      # Regular passability checks
      return false if passage & bit != 0 || passage & 0x0f == 0x0f
      return true if @priorities[tile_id] == 0
    end
    return true
  end
end

class Game_Temp < Game_Temp
  attr_accessor :ending_rockclimb              # jumping off surf base flag
  attr_accessor :rockclimb_base_coords         # [x, y] while jumping on/off, or nil
  attr_accessor :lavasurf_base_coords          # [x, y] while jumping on/off, or nil
  attr_accessor :lifted_object_base_coords     # [x, y] while jumping on/off, or nil

  alias aifm_initialize initialize
  def initialize
    aifm_initialize

    @ending_rockclimb            = false
  end
end
#===============================================================================
# Game_Player Overwrites | Adding Whirlpool, Rock Climb, Lavasurf, Lava Swirl
#===============================================================================
# Forced Movement With Rockclimb
#===============================================================================
class Game_Player < Game_Character
  def update_command_new
    dir = Input.dir4
    if $PokemonGlobal.forced_movement?
      move_forward
    elsif $PokemonGlobal.forced_rockclimb?
      pbTraverseRockClimb?
    elsif dir.to_i > 0 && !pbMapInterpreterRunning? && !$game_temp.message_window_showing &&
          !$game_temp.in_mini_update && !$game_temp.in_menu
      # Move player in the direction the directional button is being pressed
      subs = System.uptime - @lastdirframe
      if @moved_last_frame ||
         (dir == @lastdir && (subs >= 0.075 || subs.negative?))
        case dir
        when 2 then move_down
        when 4 then move_left
        when 6 then move_right
        when 8 then move_up
        end
      elsif dir != @lastdir
        case dir
        when 2 then turn_down
        when 4 then turn_left
        when 6 then turn_right
        when 8 then turn_up
        end
      end
      # Record last direction input
      @lastdirframe = System.uptime if dir != @lastdir
      @lastdir = dir
    end
  end

  def can_run?
    return @move_speed > 3 if @move_route_forcing
    return false if @bumping
    return false if $game_temp.in_menu || $game_temp.in_battle ||
                    $game_temp.message_window_showing || pbMapInterpreterRunning?
    return false if !$player.has_running_shoes && !$PokemonGlobal.diving &&
                    !$PokemonGlobal.surfing && !$PokemonGlobal.bicycle &&
                    !$PokemonGlobal.rockclimb
    # return false if $game_player.lifted_event_heavy
    return false if jumping?
    return false if pbTerrainTag.must_walk
    run_pressed = Input.press?(Input::ACTION) || Input.press?(Input::BACK) || Input.press?(Input::JUMPUP)
    return ($PokemonSystem.runstyle == 1) ^ run_pressed
  end

  def set_movement_type(type)
    meta = GameData::PlayerMetadata.get($player&.character_ID || 1)
    new_charset = nil
    case type
    when :fishing
      new_charset = pbGetPlayerCharset(meta.fish_charset)
    when :surf_fishing
      new_charset = pbGetPlayerCharset(meta.surf_fish_charset)
    when :diving, :diving_fast, :diving_jumping, :diving_stopped
      self.move_speed = 3 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.dive_charset)

    when :surfing, :surfing_fast, :surfing_jumping, :surfing_stopped
      if !@move_route_forcing
        self.move_speed = (type == :surfing_jumping) ? 3 : 4.2
      end
      new_charset = pbGetPlayerCharset(meta.surf_charset)
    when :descending_waterfall, :ascending_waterfall
      self.move_speed = 2 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.surf_charset)
    when :crossing_whirlpool
      self.move_speed = 2 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.surf_charset)

    when :rockclimb, :rockclimb_fast, :rockclimb_jumping, :rockclimb_stopped
      if !@move_route_forcing
        self.move_speed = (type == :rockclimb_jumping) ? 3 : 5
      end
      new_charset = pbGetPlayerCharset(meta.surf_charset)

    when :lavasurfing, :lavasurfing_fast, :lavasurfing_jumping, :lavasurfing_stopped
      if !@move_route_forcing
        self.move_speed = (type == :lavasurfing_jumping) ? 3 : 4.2
      end
      new_charset = pbGetPlayerCharset(meta.surf_charset)
    when :descending_lavafall, :ascending_lavafall
      self.move_speed = 2 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.surf_charset)
    when :crossing_lavaswirl
      self.move_speed = 2 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.surf_charset)

    when :cycling, :cycling_fast, :cycling_jumping, :cycling_stopped
      if !@move_route_forcing
        self.move_speed = (type == :cycling_jumping) ? 4 : 6
      end
      new_charset = pbGetPlayerCharset(meta.cycle_charset)
    when :lifting, :lifting_fast, :lifting_stopped
      self.move_speed = (type == :lifting_fast) ? 4 : 3 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.walk_lifting_charset)
    when :running
      self.move_speed = 5.5 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.run_charset)
    when :ice_sliding
      self.move_speed = 5 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.walk_charset)
    else   # :walking, :jumping, :walking_stopped
      self.move_speed = 3.5 if !@move_route_forcing
      new_charset = pbGetPlayerCharset(meta.walk_charset)
    end
    self.move_speed = 3.5 if @bumping
    @character_name = new_charset if new_charset
  end


  # Called when the player's character or outfit changes. Assumes the player
  # isn't moving.
  def refresh_charset
    return if @refreshing_charset
    @refreshing_charset = true
    begin
      meta = GameData::PlayerMetadata.get($player&.character_ID || 1) rescue nil
      return unless meta
      new_charset = nil
      if $PokemonGlobal&.diving
        new_charset = pbGetPlayerCharset(meta.dive_charset)
      elsif $PokemonGlobal&.surfing
        new_charset = pbGetPlayerCharset(meta.surf_charset)
      elsif $PokemonGlobal&.lavasurfing
        new_charset = pbGetPlayerCharset(meta.surf_charset)
      elsif $PokemonGlobal&.bicycle
        new_charset = pbGetPlayerCharset(meta.cycle_charset)
      else
        new_charset = pbGetPlayerCharset(meta.walk_charset)
      end
      @character_name = new_charset if new_charset
    ensure
      @refreshing_charset = false
    end
  end

  def add_move_distance_to_stats(distance = 1)
    if $PokemonGlobal&.diving || $PokemonGlobal&.surfing
      $stats.distance_surfed += distance
    elsif $PokemonGlobal&.lavasurfing
      $stats.distance_lavasurfed += distance
    elsif $PokemonGlobal&.bicycle
      $stats.distance_cycled += distance
    else
      $stats.distance_walked += distance
    end
    $stats.distance_slid_on_ice += distance if $PokemonGlobal.ice_sliding
  end

  # def move_generic(dir, turn_enabled = true)
  #   turn_generic(dir, true) if turn_enabled
  #   if !$game_temp.encounter_triggered
  #     if can_move_in_direction?(dir)
  #       x_offset = (dir == 4) ? -1 : (dir == 6) ? 1 : 0
  #       y_offset = (dir == 8) ? -1 : (dir == 2) ? 1 : 0
  #       # Jump over ledges
  #       if pbFacingTerrainTag.ledge
  #         if jumpForward(2)
  #           pbSEPlay("Player jump")
  #           increase_steps
  #         end
  #         return
  #       elsif pbFacingTerrainTag.waterfall_crest && dir == 2
  #         $game_player.always_on_top = true
  #         $PokemonGlobal.descending_waterfall = true
  #         $game_player.through = true
  #         $stats.waterfalls_descended += 1
  #       elsif pbFacingTerrainTag.lavafall_crest && dir == 2
  #         $game_player.always_on_top = true
  #         $PokemonGlobal.descending_lavafall = true
  #         $game_player.through = true
  #         $stats.lavafalls_descended += 1
  #       end
  #       # Jumping out of surfing back onto land
  #       return if pbEndSurf(x_offset, y_offset)
  #       # Jumping out of surfing back onto land
  #       # return if pbEndLavaSurf(x_offset, y_offset)
  #       # General movement
  #       turn_generic(dir, true)
  #       if !$game_temp.encounter_triggered
  #         @move_initial_x = @x
  #         @move_initial_y = @y
  #         @x += x_offset
  #         @y += y_offset
  #         @move_timer = 0.0
  #         add_move_distance_to_stats(x_offset.abs + y_offset.abs)
  #         increase_steps
  #       end
  #     elsif !check_event_trigger_touch(dir)
  #       bump_into_object
  #     end
  #   end
  #   $game_temp.encounter_triggered = false
  # end

  def update_move
    if !@moved_last_frame || @stopped_last_frame   # Started a new step
      if $PokemonGlobal.ice_sliding || @last_terrain_tag.ice
        set_movement_type(:ice_sliding)
      elsif $PokemonGlobal.descending_waterfall
        set_movement_type(:descending_waterfall)
      elsif $PokemonGlobal.ascending_waterfall
        set_movement_type(:ascending_waterfall)
      elsif $PokemonGlobal.crossing_whirlpool
        set_movement_type(:crossing_whirlpool)
        spritWhirlpool
      elsif $PokemonGlobal.descending_lavafall
        set_movement_type(:descending_lavafall)
      elsif $PokemonGlobal.ascending_lavafall
        set_movement_type(:ascending_lavafall)
      elsif $PokemonGlobal.crossing_lavaswirl
        set_movement_type(:crossing_lavaswirl)
        spritLavaSwirl
      elsif $PokemonGlobal.rockclimb
        set_movement_type(:rockclimb)
      else
        faster = can_run?
        if $PokemonGlobal&.diving
          set_movement_type((faster) ? :diving_fast : :diving)
        elsif $PokemonGlobal&.surfing
          set_movement_type((faster) ? :surfing_fast : :surfing)
        elsif $PokemonGlobal&.lavasurfing
          set_movement_type((faster) ? :lavasurfing_fast : :lavasurfing)
        elsif $PokemonGlobal&.rockclimb
          set_movement_type((faster) ? :rockclimb_fast : :rockclimb )
        elsif $PokemonGlobal&.lifting
            set_movement_type((faster) ? :lifting_fast : :lifting)
        elsif $PokemonGlobal&.bicycle
          set_movement_type((faster) ? :cycling_fast : :cycling)
        else
          set_movement_type((faster) ? :running : :walking)
        end
      end
      if jumping?
        if $PokemonGlobal&.diving
          set_movement_type(:diving_jumping)
        elsif $PokemonGlobal&.surfing
          set_movement_type(:surfing_jumping)
        elsif $PokemonGlobal&.lavasurfing
          set_movement_type(:lavasurfing_jumping)
        elsif $PokemonGlobal&.rockclimb
          set_movement_type(:rockclimb_jumping)
        elsif $PokemonGlobal&.bicycle
          set_movement_type(:cycling_jumping)
        else
          set_movement_type(:jumping)   # Walking speed/charset while jumping
        end
      end
    end
    was_jumping = jumping?
    super
    if was_jumping && !jumping? && !@transparent && (@tile_id > 0 || @character_name != "")
      if ((!$PokemonGlobal.surfing || $game_temp.ending_surf) && (!$PokemonGlobal.rockclimb || $game_temp.ending_rockclimb))
        spriteset = $scene.spriteset(map_id)
        spriteset&.addUserAnimation(Settings::DUST_ANIMATION_ID, self.x, self.y, true, 1)
      end
    end
  end

  def update_stop
    if @stopped_last_frame
      if $PokemonGlobal&.diving
        set_movement_type(:diving_stopped)
      elsif $PokemonGlobal&.surfing
        set_movement_type(:surfing_stopped)
      elsif $PokemonGlobal&.lavasurfing
        set_movement_type(:lavasurfing_stopped)
      elsif $PokemonGlobal&.rockclimb
        set_movement_type(:rockclimb_stopped)
      elsif $PokemonGlobal&.lifting
        set_movement_type(:lifting_stopped)
      elsif $PokemonGlobal&.bicycle
        set_movement_type(:cycling_stopped)
      else
        set_movement_type(:walking_stopped)
      end
    end
    super
  end

  def update_pattern
    if $PokemonGlobal&.surfing || $PokemonGlobal&.diving
      bob_pattern = (4 * System.uptime / SURF_BOB_DURATION).to_i % 4
      @pattern = bob_pattern if !@lock_pattern
      @pattern_surf = bob_pattern
      @bob_height = (bob_pattern >= 2) ? 2 : 0
      @anime_count = 0
    elsif $PokemonGlobal&.lavasurfing
      bob_pattern = (4 * System.uptime / SURF_BOB_DURATION).to_i % 4
      @pattern = bob_pattern if !@lock_pattern
      @pattern_lavasurf = bob_pattern
      @bob_height = (bob_pattern >= 2) ? 2 : 0
      @anime_count = 0
    else
      @bob_height = 0
      super
    end
  end
end

def pbUpdateVehicle
  if $PokemonGlobal&.diving
    $game_player.set_movement_type(:diving_stopped)
  elsif $PokemonGlobal&.surfing
    $game_player.set_movement_type(:surfing_stopped)
  elsif $PokemonGlobal&.lavasurfing
    $game_player.set_movement_type(:lavasurfing_stopped)
  elsif $PokemonGlobal&.rockclimb
    $game_player.set_movement_type(:rockclimb_stopped)
  elsif $PokemonGlobal&.lifting
    $game_player.set_movement_type(:lifting_stopped)
  elsif $PokemonGlobal&.bicycle
    $game_player.set_movement_type(:cycling_stopped)
  else
    $game_player.set_movement_type(:walking_stopped)
  end
end

def pbCancelVehicles(destination = nil, cancel_swimming = true)
  $PokemonGlobal.lavasurfing  = false if cancel_swimming
  $PokemonGlobal.surfing      = false if cancel_swimming
  $PokemonGlobal.diving       = false if cancel_swimming
  $PokemonGlobal.bicycle      = false if !destination || !pbCanUseBike?(destination)
  pbUpdateVehicle
end
#===============================================================================
# Finding Sprite to Ride
#===============================================================================
module GameData
  class Species
    def self.ow_mount_filename(species, form = 0, gender = 0, shiny = false, shadow = false)
      paths = [["Graphics/Characters/", "Mount"], ["Graphics/Characters/", "Followers"]]
      ret = nil
      paths.each do |path, suffix|
        ret = self.check_graphic_file(path, species, form, gender, shiny, shadow, suffix)
        puts "Checking #{path}#{species} #{suffix}... #{ret.nil? ? 'Not found' : ret.include?("000") ? 'Not found' : 'Found'}"
        break if !nil_or_empty?(ret)
      end
#      if nil_or_empty?(ret)
#        paths.each do |path, suffix|
#          ret = self.check_graphic_file(path, species, form, 0, shiny, shadow, suffix)
#          puts "Checking #{path}#{species} #{suffix} (nil or empty?)... #{ret.nil? ? 'Not found' : 'Found'}"
#          break if !nil_or_empty?(ret)
#        end
#      end
      ret = "Base" if ret && ret.include?("000") || nil_or_empty?(ret)
      puts "Final result: #{ret}"
      return ret
    end
  end
end

#===============================================================================
# Surf Change?
#===============================================================================
class Sprite_SurfBase
  alias aifm_initialize_surf initialize
  def initialize(parent_sprite, viewport = nil)
    aifm_initialize_surf(parent_sprite, viewport)
    @current_pokemon = nil
  end

  alias surf_update update
  def update
    surf_update
    if $PokemonGlobal.surfing
      # Update the surf bitmap based on the used Pokémon
      if AIFM_Surf[:basePKMN?] && $PokemonGlobal.base_pkmn_surf && (@surfbitmap.nil? || (@current_pokemon != $PokemonGlobal.base_pkmn_surf))
        surfbitmap = GameData::Species.ow_mount_filename($PokemonGlobal.base_pkmn_surf[:species], $PokemonGlobal.base_pkmn_surf[:form], $PokemonGlobal.base_pkmn_surf[:gender], $PokemonGlobal.base_pkmn_surf[:shiny], $PokemonGlobal.base_pkmn_surf[:shadow])
        if surfbitmap == "Base"
          @surfbitmap = AnimatedBitmap.new("Graphics/Characters/base_surf")
        else
          @surfbitmap = AnimatedBitmap.new("#{surfbitmap}")
        end
        @cws = @surfbitmap.width / 4
        @chs = @surfbitmap.height / 4
        @current_pokemon = $PokemonGlobal.base_pkmn_surf
      elsif !$PokemonGlobal.base_pkmn_surf && (@surfbitmap.nil? || @current_pokemon != "base_surf")
        @surfbitmap = AnimatedBitmap.new("Graphics/Characters/base_surf")
        @cws = @surfbitmap.width / 4
        @chs = @surfbitmap.height / 4
        @current_pokemon = "base_surf"
      end
      @sprite.bitmap = @surfbitmap.bitmap if @sprite
      cw = @cws
      ch = @chs
    elsif $PokemonGlobal.diving
      # Update the dive bitmap based on the used Pokémon
      if defined?(AIFM_Dive) && AIFM_Dive[:basePKMN?] && $PokemonGlobal.base_pkmn_dive && !$PokemonGlobal.divingpkmn || (@current_pokemon != $PokemonGlobal.base_pkmn_dive)
        $PokemonGlobal.divingpkmn = true
        divebitmap = GameData::Species.ow_mount_filename($PokemonGlobal.base_pkmn_dive[:species], $PokemonGlobal.base_pkmn_dive[:form], $PokemonGlobal.base_pkmn_dive[:gender], $PokemonGlobal.base_pkmn_dive[:shiny], $PokemonGlobal.base_pkmn_dive[:shadow])
        if divebitmap == "Base"
          @divebitmap = AnimatedBitmap.new("Graphics/Characters/base_dive")
        else
          @divebitmap = AnimatedBitmap.new("#{divebitmap}")
        end
        @cws = @divebitmap.width / 4
        @chs = @divebitmap.height / 4
        @current_pokemon = $PokemonGlobal.base_pkmn_dive
      elsif !$PokemonGlobal.base_pkmn_dive && (@divebitmap.nil? || @current_pokemon != "base_dive")
        @divebitmap = AnimatedBitmap.new("Graphics/Characters/base_dive")
        @cws = @divebitmap.width / 4
        @chs = @divebitmap.height / 4
        @current_pokemon = "base_dive"
      end
      @sprite.bitmap = @divebitmap.bitmap if @sprite
      cw = @cwd
      ch = @chd
    end
    if @sprite && cw && ch
      frame = (Graphics.frame_count / 60) % 4  # 4 frames, 10 frames per second
      sx = frame * cw
      sy = ((event.direction - 2) / 2) * ch
      @sprite.src_rect.set(sx, sy, cw, ch)
    end
  end
end
#===============================================================================
# Lava Surf
#===============================================================================
# class Sprite_LavaSurfBase
#   attr_reader :visible

#   def initialize(parent_sprite, viewport = nil)
#     @parent_sprite = parent_sprite
#     @sprite = nil
#     @viewport = viewport
#     @disposed = false
#     @current_pokemon = nil
#     @lavasurfbitmap = AnimatedBitmap.new("Graphics/Characters/base_lavasurf")
#     RPG::Cache.retain("Graphics/Characters/base_lavasurf")
#     @cws = @lavasurfbitmap.width / 4
#     @chs = @lavasurfbitmap.height / 4
#     update
#   end

#   def dispose
#     return if @disposed
#     @sprite&.dispose
#     @sprite = nil
#     @parent_sprite = nil
#     @lavasurfbitmap.dispose
#     @disposed = true
#   end

#   def disposed?
#     return @disposed
#   end

#   def event
#     return @parent_sprite.character
#   end

#   def visible=(value)
#     @visible = value
#     @sprite.visible = value if @sprite && !@sprite.disposed?
#   end

#   def update
#     return if disposed?
#     if !$PokemonGlobal.lavasurfing
#       # Just-in-time disposal of sprite
#       if @sprite
#         @sprite.dispose
#         @sprite = nil
#       end
#       return
#     end
#     # Just-in-time creation of sprite
#     @sprite = Sprite.new(@viewport) if !@sprite
#     return if !@sprite
#     if $PokemonGlobal.lavasurfing
#       # Update the lavasurf bitmap based on the used Pokémon
#       if AIFM_LavaSurf[:basePKMN?] && $PokemonGlobal.base_pkmn_lavasurf && (@lavasurfbitmap.nil? || @current_pokemon != $PokemonGlobal.base_pkmn_lavasurf)
#         lavasurfbitmap = GameData::Species.ow_mount_filename($PokemonGlobal.base_pkmn_lavasurf[:species], $PokemonGlobal.base_pkmn_lavasurf[:form], $PokemonGlobal.base_pkmn_lavasurf[:gender], $PokemonGlobal.base_pkmn_lavasurf[:shiny], $PokemonGlobal.base_pkmn_lavasurf[:shadow])
#         if lavasurfbitmap == "Base"
#           @lavasurfbitmap = AnimatedBitmap.new("Graphics/Characters/base_lavasurf")
#         else
#           @lavasurfbitmap = AnimatedBitmap.new("#{lavasurfbitmap}")
#         end
#         @cws = @lavasurfbitmap.width / 4
#         @chs = @lavasurfbitmap.height / 4
#         @current_pokemon = $PokemonGlobal.base_pkmn_lavasurf
#       elsif !$PokemonGlobal.base_pkmn_lavasurf && (@lavasurfbitmap.nil? || @current_pokemon != "base_lavasurf")
#         @lavasurfbitmap = AnimatedBitmap.new("Graphics/Characters/base_lavasurf")
#         @cws = @lavasurfbitmap.width / 4
#         @chs = @lavasurfbitmap.height / 4
#         @current_pokemon = "base_lavasurf"
#       end
#       @sprite.bitmap = @lavasurfbitmap.bitmap
#       cw = @cws
#       ch = @chs
#     end
#     sx = event.pattern_lavasurf * cw
#     sy = ((event.direction - 2) / 2) * @chs
#     @sprite.src_rect.set(sx, sy, @cws, @chs)
#     @sprite.src_rect.set(sx, sy, cw, ch)
#     if $game_temp.lavasurf_base_coords
#       spr_x = ((($game_temp.lavasurf_base_coords[0] * Game_Map::REAL_RES_X) - event.map.display_x).to_f / Game_Map::X_SUBPIXELS).round
#       spr_x += (Game_Map::TILE_WIDTH / 2)
#       spr_x = ((spr_x - (Graphics.width / 2)) * TilemapRenderer::ZOOM_X) + (Graphics.width / 2) if TilemapRenderer::ZOOM_X != 1
#       @sprite.x = spr_x
#       spr_y = ((($game_temp.lavasurf_base_coords[1] * Game_Map::REAL_RES_Y) - event.map.display_y).to_f / Game_Map::Y_SUBPIXELS).round
#       spr_y += (Game_Map::TILE_HEIGHT / 2) + 16
#       spr_y = ((spr_y - (Graphics.height / 2)) * TilemapRenderer::ZOOM_Y) + (Graphics.height / 2) if TilemapRenderer::ZOOM_Y != 1
#       @sprite.y = spr_y
#     else
#       @sprite.x = @parent_sprite.x
#       @sprite.y = @parent_sprite.y
#     end
#     @sprite.ox      = cw / 2
#     @sprite.oy      = ch - 16   # Assume base needs offsetting
#     @sprite.oy      -= event.bob_height
#     @sprite.z       = event.screen_z(ch) - 1
#     @sprite.zoom_x  = @parent_sprite.zoom_x
#     @sprite.zoom_y  = @parent_sprite.zoom_y
#     @sprite.tone    = @parent_sprite.tone
#     @sprite.color   = @parent_sprite.color
#     @sprite.opacity = @parent_sprite.opacity
#   end
# end

# class Sprite_Character < RPG::Sprite
#   alias aifm_initialize_lavasurf initialize
#   def initialize(viewport, character = nil)
#     aifm_initialize_lavasurf(viewport, character)
#     @lavasurfbase = Sprite_LavaSurfBase.new(self, viewport) if character == $game_player
#   end

#   alias lavasurf_dispose dispose
#   def dispose
#     lavasurf_dispose
#     @lavasurfbase&.dispose
#     @lavasurfbase = nil
#   end

#   alias lavasurf_update update
#   def update
#     lavasurf_update
#     @lavasurfbase&.update
#   end
# end

#===============================================================================
# Rock Climbing
#===============================================================================

class Sprite_RockClimbBase
  attr_reader :visible

  def initialize(parent_sprite, viewport = nil)
    @parent_sprite = parent_sprite
    @sprite = nil
    @viewport = viewport
    @disposed = false
    @current_pokemon = nil
    @rockclimbbitmap = AnimatedBitmap.new("Graphics/Characters/base_rockclimb")
    RPG::Cache.retain("Graphics/Characters/base_rockclimb")
    @cws = @rockclimbbitmap.width / 4
    @chs = @rockclimbbitmap.height / 4
    update
  end

  def dispose
    return if @disposed
    @sprite&.dispose
    @sprite = nil
    @parent_sprite = nil
    @rockclimbbitmap.dispose
    @disposed = true
  end

  def disposed?
    return @disposed
  end

  def event
    return @parent_sprite.character
  end

  def visible=(value)
    @visible = value
    @sprite.visible = value if @sprite && !@sprite.disposed?
  end

  def update
    return if disposed?
    if !$PokemonGlobal.rockclimb
      # Just-in-time disposal of sprite
      if @sprite
        @sprite.dispose
        @sprite = nil
      end
      return
    end
    # Just-in-time creation of sprite
    @sprite = Sprite.new(@viewport) if !@sprite
    return if !@sprite
    if $PokemonGlobal.rockclimb
      # Update the rockclimb bitmap based on the used Pokémon
      if AIFM_RockClimb[:basePKMN?] && $PokemonGlobal.base_pkmn_rockclimb && (@rockclimbbitmap.nil? || @current_pokemon != $PokemonGlobal.base_pkmn_rockclimb)
        rockclimbpkmnbitmap = GameData::Species.ow_mount_filename($PokemonGlobal.base_pkmn_rockclimb[:species], $PokemonGlobal.base_pkmn_rockclimb[:form], $PokemonGlobal.base_pkmn_rockclimb[:gender], $PokemonGlobal.base_pkmn_rockclimb[:shiny], $PokemonGlobal.base_pkmn_rockclimb[:shadow])
        if rockclimbpkmnbitmap == "Base"
          @rockclimbbitmap = AnimatedBitmap.new("Graphics/Characters/base_rockclimb")
        else
          @rockclimbbitmap = AnimatedBitmap.new("#{rockclimbpkmnbitmap}")
        end
        @cws = @rockclimbbitmap.width / 4
        @chs = @rockclimbbitmap.height / 4
        @current_pokemon = $PokemonGlobal.base_pkmn_rockclimb
      elsif !$PokemonGlobal.base_pkmn_rockclimb && (@rockclimbbitmap.nil? || @current_pokemon != "base_rockclimb")
        @rockclimbbitmap = AnimatedBitmap.new("Graphics/Characters/base_rockclimb")
        @cws = @rockclimbbitmap.width / 4
        @chs = @rockclimbbitmap.height / 4
        @current_pokemon = "base_rockclimb"
      end
      @sprite.bitmap = @rockclimbbitmap.bitmap
      cw = @cws
      ch = @chs
    end
    event.pattern_rockclimb ||= 0
    sx = event.pattern_rockclimb * cw
    sy = ((event.direction - 2) / 2) * @chs
    @sprite.src_rect.set(sx, sy, @cws, @chs)
    @sprite.src_rect.set(sx, sy, cw, ch)
    if $game_temp.rockclimb_base_coords
      spr_x = ((($game_temp.rockclimb_base_coords[0] * Game_Map::REAL_RES_X) - event.map.display_x).to_f / Game_Map::X_SUBPIXELS).round
      spr_x += (Game_Map::TILE_WIDTH / 2)
      spr_x = ((spr_x - (Graphics.width / 2)) * TilemapRenderer::ZOOM_X) + (Graphics.width / 2) if TilemapRenderer::ZOOM_X != 1
      @sprite.x = spr_x
      spr_y = ((($game_temp.rockclimb_base_coords[1] * Game_Map::REAL_RES_Y) - event.map.display_y).to_f / Game_Map::Y_SUBPIXELS).round
      spr_y += (Game_Map::TILE_HEIGHT / 2) + 16
      spr_y = ((spr_y - (Graphics.height / 2)) * TilemapRenderer::ZOOM_Y) + (Graphics.height / 2) if TilemapRenderer::ZOOM_Y != 1
      @sprite.y = spr_y
    else
      @sprite.x = @parent_sprite.x
      @sprite.y = @parent_sprite.y
    end
    @sprite.ox      = cw / 2
    @sprite.oy      = ch - 16   # Assume base needs offsetting
    @sprite.oy      -= event.bob_height
    @sprite.z       = event.screen_z(ch) - 1
    @sprite.zoom_x  = @parent_sprite.zoom_x
    @sprite.zoom_y  = @parent_sprite.zoom_y
    @sprite.tone    = @parent_sprite.tone
    @sprite.color   = @parent_sprite.color
    @sprite.opacity = @parent_sprite.opacity
  end
end

class Sprite_Character < RPG::Sprite
  alias aifm_initialize_rockclimb initialize
  def initialize(viewport, character = nil)
    aifm_initialize_rockclimb(viewport, character)
    @rockclimbbase = Sprite_RockClimbBase.new(self, viewport) if character == $game_player
  end

  alias rockclimb_dispose dispose
  def dispose
    rockclimb_dispose
    @rockclimbbase&.dispose
    @rockclimbbase = nil
  end

  alias rockclimb_update update
  def update
    rockclimb_update
    @rockclimbbase&.update
  end
end

#===============================================================================
# Lift (Zelda Strength) / Events Works Best with Normal Size Events
#===============================================================================
# class Game_Player
#   attr_accessor :lifted_event
#   attr_accessor :lifted_event_down
#   attr_accessor :lifted_event_sprite_name
#   attr_accessor :lifted_event_opacity
#   attr_accessor :lifted_event_always_on_top
#   attr_accessor :lifted_event_heavy

#   alias update_lift update
#   def update
#     update_lift
#     if @lifted_event && $PokemonGlobal.lifting
#       @lifted_event.update
#       if Input.trigger?(Input::C) && !$game_temp.message_window_showing
#         @lifted_event_down = true
#         if $game_player.lifted_event_down
#           if can_place_lifted_event? && !$game_player.pbFacingEvent && !$game_temp.in_menu
#             x = $game_player.x + ($game_player.direction == 6 ? 1 : ($game_player.direction == 4 ? -1 : 0))
#             y = $game_player.y + ($game_player.direction == 2 ? 1 : ($game_player.direction == 8 ? -1 : 0))
#             $game_player.lifted_event.moveto(x, y)
#             $game_player.lifted_event.direction = $game_player.direction
#             $game_player.lifted_event.opacity = @lifted_event_opacity
#             $game_player.lifted_event.always_on_top = @lifted_event_always_on_top
#             $game_player.lifted_event.through = false
#             $game_player.lifted_event = nil
#             $game_player.lifted_event_down = nil
#             $game_player.lifted_event_heavy = nil
#             $PokemonGlobal.lifting = false
#             pbUpdateVehicle
#             pbWait(0.1)
#           else
#             # Don't set the event to nil if placement fails
#             match = $game_player.lifted_event.name.match(/Name\(([^)]+)\)/i)
#             if match
#               event_name = match[1]
#             end
#             $game_player.lifted_event_down = false
#             pbMessage(_INTL("Something is blocking you for placing \\c[1]{1}\\c[0] down here!", event_name))
#           end
#         end
#       end
#     end
#   end

#   def can_place_lifted_event?
#     x = $game_player.x + ($game_player.direction == 6 ? 1 : ($game_player.direction == 4 ? -1 : 0))
#     y = $game_player.y + ($game_player.direction == 2 ? 1 : ($game_player.direction == 8 ? -1 : 0))
#     event_at_target = $game_map.events.values.find { |event| event.x == x && event.y == y && event != $game_player.lifted_event }
#     terrain_tag = $game_map.terrain_tag(x, y)
#     return $game_map.passable?(x, y, 0) && terrain_tag != 1 && (
#       event_at_target.nil? ||
#       (event_at_target.list.size <= 1 && event_at_target.character_name.empty?)
#     )
#   end
# end

# class Sprite_LiftedEvent
#   attr_reader :visible

#   def initialize(parent_sprite, viewport = nil)
#     @parent_sprite = parent_sprite
#     @sprite = nil
#     @viewport = viewport
#     @disposed = false
#     @current_liftet = nil
#     @liftedeventbitmap = AnimatedBitmap.new("Graphics/Characters/Object ball.png")
#     RPG::Cache.retain("Graphics/Characters/Object ball.png")
#     @cws = @liftedeventbitmap.width / 4
#     @chs = @liftedeventbitmap.height / 4
#     update
#   end

#   def dispose
#     return if @disposed
#     @sprite&.dispose
#     @sprite = nil
#     @parent_sprite = nil
#     @liftedeventbitmap.dispose
#     @disposed = true
#   end

#   def disposed?
#     return @disposed
#   end

#   def event
#     return @parent_sprite.character
#   end

#   def visible=(value)
#     @visible = value
#     @sprite.visible = value if @sprite && !@sprite.disposed?
#   end

#   def update
#     return if disposed?
#     if !$PokemonGlobal.lifting
#       # Just-in-time disposal of sprite
#       if @sprite
#         @sprite.dispose
#         @sprite = nil
#       end
#       return
#     end
#     # Just-in-time creation of sprite
#     @sprite = Sprite.new(@viewport) if !@sprite
#     return if !@sprite
#     if $PokemonGlobal.lifting
#       sprite_name = ($game_player.lifted_event_sprite_name || "").empty? ? "Object ball" : $game_player.lifted_event_sprite_name
#       paths = ["Graphics/Characters/Lifted/#{sprite_name}", "Graphics/Characters/#{sprite_name}"]
#       path = paths.find { |p| pbResolveBitmap(p) }
#       @liftedeventbitmap.dispose if @liftedeventbitmap
#       @liftedeventbitmap = AnimatedBitmap.new("Graphics/Characters/#{sprite_name}")
#       RPG::Cache.retain("Graphics/Characters/#{sprite_name}")
#       @cws = @liftedeventbitmap.width / 4
#       @chs = @liftedeventbitmap.height / 4
#       @current_liftet = "Object ball"
#       @sprite.bitmap = @liftedeventbitmap.bitmap
#       cw = @cws
#       ch = @chs
#       frame = (Graphics.frame_count / 60) % 4  # 4 frames, 10 frames per second
#       sx = frame * cw
#       sy = ((event.direction - 2) / 2) * ch
#       @sprite.src_rect.set(sx, sy, @cws, @chs)
#       @sprite.src_rect.set(sx, sy, cw, ch)
#       if $game_player.lifted_event_down
#         @sprite.y += 2
#         if @sprite.y >= @parent_sprite.y - 24
#           $game_player.lifted_event = nil
#           $game_player.lifted_event_down = nil
#           @sprite.dispose if @sprite
#           @sprite = nil
#           @liftedeventbitmap.dispose if @liftedeventbitmap
#           @liftedeventbitmap = nil
#         end
#       else
#         @sprite.x = @parent_sprite.x
#         @sprite.y = @parent_sprite.y - 24
#       end
#       @sprite.ox      = cw / 2
#       @sprite.oy      = ch
#       @sprite.oy      -= event.bob_height
#       @sprite.z = @parent_sprite.z + 1
#       @sprite.zoom_x  = @parent_sprite.zoom_x
#       @sprite.zoom_y  = @parent_sprite.zoom_y
#       @sprite.tone    = @parent_sprite.tone
#       @sprite.color   = @parent_sprite.color
#       @sprite.opacity = @parent_sprite.opacity
#     end
#   end
# end

# class Sprite_Character < RPG::Sprite
#   alias aifm_initialize_lift initialize
#   def initialize(viewport, character = nil)
#     aifm_initialize_lift(viewport, character)
#     @liftedeventbase = Sprite_LiftedEvent.new(self, viewport) if character == $game_player
#   end

#   alias lift_dispose dispose
#   def dispose
#     lift_dispose
#     @liftedeventbase&.dispose
#     @liftedeventbase = nil
#   end

#   alias lift_update update
#   def update
#     lift_update
#     @liftedeventbase&.update
#   end
# end
