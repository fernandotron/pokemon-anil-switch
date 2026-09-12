module FollowingPkmn
  #-----------------------------------------------------------------------------
  # Script Command to have an event follow the player as a Following Pokemon
  #-----------------------------------------------------------------------------
  def self.start_following(event_id = nil, anim = true)
    return if !FollowingPkmn.can_check?
    event = (event_id.nil? && pbMapInterpreter ? pbMapInterpreter.get_character(0) : $game_map.events[event_id])
    return false if !FollowingPkmn.get_pokemon || event.nil?
    leader = $game_player
    if [[-1, 0], [1, 0], [0, 1], [0, -1]].none? { |offset| event.x == ($game_player.x + offset[0]) && event.y == ($game_player.y + offset[1])}
      behind_direction = 10 - leader.direction
      target = $map_factory.getFacingTile(behind_direction, leader)
      target = [leader.map.map_id, leader.x, leader.y] if !target
      event.moveto(target[1], target[2])
    end
    $game_temp.followers.remove_follower_by_name("FollowerPkmn")
    $game_temp.followers.remove_follower_by_name("FollowingPkmn") if FollowingPkmn.get
    $game_temp.followers.add_follower(event, "FollowingPkmn", FollowingPkmn::FOLLOWER_COMMON_EVENT)
    $PokemonGlobal.follower_toggled = true
    event = FollowingPkmn.get_event
    $game_temp.followers.each_follower do |event, follower|
      if follower.following_pkmn?
        pbTurnTowardEvent(event, leader)
        follower.direction = event.direction
      end
      leader = event
    end
    FollowingPkmn.refresh(anim)
  end


  #-----------------------------------------------------------------------------
  # Script Command to remove the event following the player as a Following
  # Pokemon
  #-----------------------------------------------------------------------------
  def self.stop_following
    return if !FollowingPkmn.can_check?
    $game_temp.followers.remove_follower_by_name("FollowerPkmn")
    $game_temp.followers.remove_follower_by_name("FollowingPkmn")
  end
  #-----------------------------------------------------------------------------
  # Script Command to toggle Following Pokemon
  #-----------------------------------------------------------------------------
  def self.toggle(forced = nil, anim = false)
    return if !FollowingPkmn.can_check?
    first_pkmn = FollowingPkmn.get_pokemon
    if !first_pkmn
      FollowingPkmn.remove_sprite rescue nil
      $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
      $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil if $game_temp&.followers
      return
    end
    $PokemonGlobal.follower_toggle_locked = false if forced.nil?
    @@hidden = false
    if !forced.nil?
      $PokemonGlobal.follower_toggled = !(!forced)
    else
      $PokemonGlobal.follower_toggled = !$PokemonGlobal.follower_toggled
    end
    if $PokemonGlobal.follower_toggled
      $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
      $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil
      $game_temp.followers.add_follower($game_player, "FollowingPkmn", FollowingPkmn::FOLLOWER_COMMON_EVENT) rescue nil
      FollowingPkmn.refresh(anim == true)
      $game_temp.followers.move_followers if $game_temp&.followers
      $game_temp.followers.turn_followers if $game_temp&.followers
    else
      FollowingPkmn.refresh(anim == true)
      FollowingPkmn.remove_sprite rescue nil
      $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
      $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil
    end
  end
  #-----------------------------------------------------------------------------
  # Script Command to toggle Following Pokemon off
  #-----------------------------------------------------------------------------
  def self.toggle_off(anim = nil)
    FollowingPkmn.toggle(false, anim)
    $PokemonGlobal.follower_toggle_locked = true
  end
  #-----------------------------------------------------------------------------
  # Script Command to toggle Following Pokemon on
  #-----------------------------------------------------------------------------
  def self.toggle_on(anim = nil)
    $PokemonGlobal.follower_toggle_locked = false
    FollowingPkmn.toggle(true, anim)
  end

  def self.lock_toggle
    $PokemonGlobal.follower_toggle_locked = true
  end

  def self.unlock_toggle
    $PokemonGlobal.follower_toggle_locked = false
  end

  #-----------------------------------------------------------------------------
  # Script Command for talking to Following Pokemon
  #-----------------------------------------------------------------------------
  def self.talk
    return false if !FollowingPkmn.can_talk?(true)
    return false if !$game_temp || $game_temp.in_battle || $game_temp.in_menu
    event = FollowingPkmn.get_event
    pbTurnTowardEvent(event, $game_player)
    first_pkmn = FollowingPkmn.get_pokemon
    first_pkmn&.play_cry
    random_val = rand(6)
    if $PokemonGlobal&.follower_hold_item
      EventHandlers.trigger_2(:following_pkmn_item, first_pkmn, random_val)
    else
      EventHandlers.trigger_2(:following_pkmn_talk, first_pkmn, random_val)
    end
    pbTurnTowardEvent(event, $game_player)
    return true
  end
  #-----------------------------------------------------------------------------
  # Control the following Pokemon using move routes
  #-----------------------------------------------------------------------------
  def self.move_route(commands = nil, wait_complete = false)
    if commands.nil?
      pbMapInterpreter&.follower_move_route("FollowingPkmn")
      return
    end
    return if !FollowingPkmn.can_check?
    event = FollowingPkmn.get_event
    pbMoveRoute(event, commands, false) if event
    pbMapInterpreter&.command_210 if event && wait_complete
  end
  #-----------------------------------------------------------------------------
  # Script Command for adding an animation to the Following Pokemon event
  #-----------------------------------------------------------------------------
  def self.animation(id = nil)
    return if !FollowingPkmn.can_check? || !FollowingPkmn.active?
    if id.nil?
      pbMapInterpreter&.follower_animation("FollowingPkmn")
      return
    end
    sprites = $scene.spritesetGlobal.follower_sprites
    return if !sprites
    sprites.set_animation(id)
  end
  #-----------------------------------------------------------------------------
end


class PokemonGlobalMetadata
  attr_accessor :follower_toggle_locked

  alias init_following_pkmn_lock initialize
  def initialize
    init_following_pkmn_lock
    @follower_toggle_locked = false
  end
end