#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# Refresh Following Pokemon when mounting Bike
#-------------------------------------------------------------------------------
alias __followingpkmn__pbMountBike pbMountBike unless defined?(__followingpkmn__pbMountBike)
def pbMountBike(*args)
  bike_anim_1 = FollowingPkmn.active?
  ret = __followingpkmn__pbMountBike(*args)
  FollowingPkmn.refresh_internal
  bike_anim_2 = FollowingPkmn.active?
  FollowingPkmn.refresh(bike_anim_1 != bike_anim_2)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon when dismounting Bike
#-------------------------------------------------------------------------------
alias __followingpkmn__pbDismountBike pbDismountBike unless defined?(__followingpkmn__pbDismountBike)
def pbDismountBike(*args)
  bike_anim_1 = FollowingPkmn.active?
  ret = __followingpkmn__pbDismountBike(*args)
  FollowingPkmn.refresh_internal
  bike_anim_2 = FollowingPkmn.active?
  FollowingPkmn.refresh(bike_anim_1 != bike_anim_2)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after accessing the PC
#-------------------------------------------------------------------------------
alias __followingpkmn__pbTrainerPC pbTrainerPC unless defined?(__followingpkmn__pbTrainerPC)
def pbTrainerPC(*args)
  ret = __followingpkmn__pbTrainerPC(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after accessing Poke Centre PC
#-------------------------------------------------------------------------------
alias __followingpkmn__pbPokeCenterPC pbPokeCenterPC unless defined?(__followingpkmn__pbPokeCenterPC)
def pbPokeCenterPC(*args)
  ret = __followingpkmn__pbPokeCenterPC(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after accessing Party Screen
#-------------------------------------------------------------------------------
class PokemonParty_Scene
  alias __followingpkmn__pbEndScene pbEndScene unless method_defined?(:__followingpkmn__pbEndScene)
  def pbEndScene(*args)
    ret = __followingpkmn__pbEndScene(*args)
    FollowingPkmn.refresh(false)
    return ret
  end
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after any kind of Evolution
#-------------------------------------------------------------------------------
class PokemonEvolutionScene
  alias __followingpkmn__pbEndScreen pbEndScreen unless method_defined?(:__followingpkmn__pbEndScreen)
  def pbEndScreen(*args)
    ret = __followingpkmn__pbEndScreen(*args)
    FollowingPkmn.refresh(false)
    return ret
  end
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after any kind of Trade is made
#-------------------------------------------------------------------------------
class PokemonTrade_Scene
  alias __followingpkmn__pbEndScreen pbEndScreen unless method_defined?(:__followingpkmn__pbEndScreen)
  def pbEndScreen(*args)
    ret = __followingpkmn__pbEndScreen(*args)
    FollowingPkmn.refresh(false)
    return ret
  end
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after any Egg is hatched
#-------------------------------------------------------------------------------
alias __followingpkmn__pbHatch pbHatch unless defined?(__followingpkmn__pbHatch)
def pbHatch(*args)
  ret = __followingpkmn__pbHatch(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after usage of Bag. For form changes and stuff
#-------------------------------------------------------------------------------
class PokemonBagScreen
  alias __followingpkmn__pbStartScreen pbStartScreen unless method_defined?(:__followingpkmn__pbStartScreen)
  def pbStartScreen(*args)
    ret = __followingpkmn__pbStartScreen(*args)
    FollowingPkmn.refresh(false)
    return ret
  end
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon upon loading the Debug menu
#-------------------------------------------------------------------------------
alias __followingpkmn__pbDebugMenu pbDebugMenu unless defined?(__followingpkmn__pbDebugMenu)
def pbDebugMenu(*args)
  ret = __followingpkmn__pbDebugMenu(*args)
  FollowingPkmn.refresh(false)
  return ret
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon upon closing the pause menu
#-------------------------------------------------------------------------------
class Scene_Map
  alias __followingpkmn__call_menu call_menu unless method_defined?(:__followingpkmn__call_menu)
  def call_menu(*args)
    __followingpkmn__call_menu(*args)
    FollowingPkmn.refresh(false)
  end
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after depositing Pokemon in Daycare
#-------------------------------------------------------------------------------
class DayCare
  class << self
    alias __followingpkmn__deposit deposit unless method_defined?(:followingpkmn__deposit)
  end

  def self.deposit(*args)
    __followingpkmn__deposit(*args)
    FollowingPkmn.refresh(false)
  end
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon upon loading up the game
#-------------------------------------------------------------------------------
module Game
  class << self
    alias __followingpkmn__load_map load_map unless method_defined?(:__followingpkmn__load_map)
    alias __followingpkmn__load load unless method_defined?(:__followingpkmn__load)
  end

  # Fix for frozen player when saving during Following Pokemon animations
  # This hook runs when loading a saved game
  def self.load(*args)
    __followingpkmn__load(*args)
    FollowingPkmn.clear_frozen_state
    FollowingPkmn.reset_follower_position
  end

  def self.load_map(*args)
    __followingpkmn__load_map(*args)
    FollowingPkmn.clear_frozen_state
    FollowingPkmn.reset_follower_position
    FollowingPkmn.refresh(false)
  end
end

module FollowingPkmn
  # Clear any stale movement states that may have been saved mid-animation
  def self.clear_frozen_state
    # Clear stale move routes from the player
    if $game_player
      $game_player.instance_variable_set(:@move_route_forcing, false)
      $game_player.instance_variable_set(:@original_move_route, nil)
      $game_player.instance_variable_set(:@original_move_route_index, 0)
      $game_player.instance_variable_set(:@locked, false)
      $game_player.instance_variable_set(:@wait_count, 0)
      $game_player.instance_variable_set(:@wait_start, nil)
    end
    # Also clear stale move routes from the Following Pokemon event
    follower_event = FollowingPkmn.get_event rescue nil
    if follower_event
      follower_event.instance_variable_set(:@move_route_forcing, false)
      follower_event.instance_variable_set(:@original_move_route, nil)
      follower_event.instance_variable_set(:@original_move_route_index, 0)
      follower_event.instance_variable_set(:@locked, false)
      follower_event.instance_variable_set(:@wait_count, 0)
      follower_event.instance_variable_set(:@wait_start, nil)
    end
    # Re-enable menu in case it was disabled during a Following Pokemon interaction
    $game_system.menu_disabled = false if $game_system
  end

   # Reset follower position to be next to the player
  def self.reset_follower_position
    return if !$game_temp || !$PokemonGlobal || !$game_player
    # Force recreation of the follower factory to properly link with loaded save data
    $game_temp.instance_variable_set(:@followers, nil)
    # This will trigger the lazy initialization with fresh data from $PokemonGlobal
    $game_temp.followers
  end
end

#-------------------------------------------------------------------------------
# Queue a Following Pokemon refresh after the end of a battle
#-------------------------------------------------------------------------------
module BattleCreationHelperMethods
  class << self
    alias __followingpkmn__after_battle after_battle unless method_defined?(:__followingpkmn__after_battle)
  end

  def self.after_battle(*args)
    __followingpkmn__after_battle(*args)
    # Teleportiere Follower zur Spielerposition nach Kampf
    if FollowingPkmn.can_check? && FollowingPkmn.get_event
      event = FollowingPkmn.get_event
      event.moveto($game_player.x, $game_player.y) if event
    end
    FollowingPkmn.refresh(false)
    $PokemonGlobal.call_refresh = true
  end
end

class Scene_Map
  #-----------------------------------------------------------------------------
  # Check for Toggle input and update Following Pokemon's time_taken for to
  # track the happiness increase and hold item
  #-----------------------------------------------------------------------------
  alias __followingpkmn__update update unless method_defined?(:__followingpkmn__update)
  def update(*args)
    __followingpkmn__update(*args)
    if FollowingPkmn.can_check?
      if ($PokemonGlobal&.follower_toggled != false) && $player&.first_able_pokemon
        if !FollowingPkmn.get
          $PokemonGlobal.follower_toggled = true
          $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
          $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil
          $game_temp.followers.add_follower($game_player, "FollowingPkmn", FollowingPkmn::FOLLOWER_COMMON_EVENT) rescue nil
          FollowingPkmn.refresh(false) rescue nil
        elsif !FollowingPkmn.active?
          FollowingPkmn.refresh(false) rescue nil
        end
      elsif !$player&.first_able_pokemon && FollowingPkmn.get
        FollowingPkmn.remove_sprite rescue nil
        $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
        $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil if $game_temp&.followers
      end
    end
    toggle_triggered = false
    if !$game_temp.in_menu && !$game_temp.message_window_showing && !$game_player.moving?
      # Only respond to Switch X button (Input::JUMPUP / :follower) or Keyboard X key
      if (Input.respond_to?(:trigger_action?) && Input.trigger_action?(:follower)) || Input.trigger?(Input::JUMPUP)
        toggle_triggered = true
      end
    end
    if toggle_triggered
      if $player&.first_able_pokemon
        FollowingPkmn.toggle(nil, true)
      end
      return
    end
    return if !FollowingPkmn.active?
    FollowingPkmn.increase_time
    if defined?(FollowingPkmn::CYCLE_PARTY_KEY) && FollowingPkmn::CYCLE_PARTY_KEY &&
       ((Input.const_defined?(FollowingPkmn::CYCLE_PARTY_KEY) &&
        Input.trigger?(Input.const_get(FollowingPkmn::CYCLE_PARTY_KEY))) ||
        Input.triggerex?(FollowingPkmn::CYCLE_PARTY_KEY))
      FollowingPkmn.toggle_off
      loop do
        pkmn = $player.party.shift
 			  $player.party.push(pkmn)
        $PokemonGlobal.follower_toggled = true
        if FollowingPkmn.active?
          $PokemonGlobal.follower_toggled = false
          break
        end
        $PokemonGlobal.follower_toggled = false
      end
      FollowingPkmn.toggle_on
      return
    end
  end
  #-----------------------------------------------------------------------------
  # Forcefully set the Following Pokemon direction when the player transfers to
  # a new area
  #-----------------------------------------------------------------------------
  alias __followingpkmn__transfer_player transfer_player unless method_defined?(:__followingpkmn__transfer_player)
  def transfer_player(*args)
    __followingpkmn__transfer_player(*args)
    leader = $game_player
    # Ensure follower is unhidden after map transfer
    FollowingPkmn.unhide_follower if FollowingPkmn.hidden?
    FollowingPkmn.refresh(false)
    $game_temp.followers.each_follower do |event, follower|
      pbTurnTowardEvent(event, leader)
      follower.direction = event.direction
      leader = event
    end
  end
  #-----------------------------------------------------------------------------
  # Update Following Pokemon's time_taken for to tracking the happiness increase
  # and hold item
  #-----------------------------------------------------------------------------
  alias __followingpkmn__miniupdate miniupdate unless method_defined?(:__followingpkmn__miniupdate)
  def miniupdate(*args)
    __followingpkmn__miniupdate(*args)
    return if !FollowingPkmn.active?
    FollowingPkmn.increase_time
  end
  #-----------------------------------------------------------------------------
end

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after using the Pokecenter
#-------------------------------------------------------------------------------
# Queue a Pokecenter refresh if the Following Pokemon is active and the player
# heals at a PokeCenter
alias __followingpkmn__pbSetPokemonCenter pbSetPokemonCenter unless defined?(__followingpkmn__pbSetPokemonCenter)
def pbSetPokemonCenter(*args)
  ret = __followingpkmn__pbSetPokemonCenter(*args)
  $game_temp.pokecenter_following_pkmn = 1  if FollowingPkmn::SHOW_POKECENTER_ANIMATION && FollowingPkmn.active?
  return ret
end

class Interpreter
  #-----------------------------------------------------------------------------
  # Toggle Following Pokemon off if a Pokecenter refresh is queued and the
  # Pokemon are healed
  #-----------------------------------------------------------------------------
  alias __followingpkmn__command_314 command_314 unless method_defined?(:__followingpkmn__command_314)
  def command_314(*args)
    ret = __followingpkmn__command_314(*args)
    if FollowingPkmn::SHOW_POKECENTER_ANIMATION && $game_temp.pokecenter_following_pkmn > 0 &&
      FollowingPkmn.active?
      FollowingPkmn.toggle_off
      $game_temp.pokecenter_following_pkmn = 2
    end
    return ret
  end
  #-----------------------------------------------------------------------------
  # Refresh Following Pokemon after using the Pokecneter healing event is
  # completely done
  #-----------------------------------------------------------------------------
  alias __followingpkmn__update update unless method_defined?(:__followingpkmn__update)
  def update(*args)
    __followingpkmn__update(*args)
    if FollowingPkmn::SHOW_POKECENTER_ANIMATION && $game_temp.pokecenter_following_pkmn > 0 && !running?
      FollowingPkmn.toggle_on
      $game_temp.pokecenter_following_pkmn = 0
    end
  end
  #-----------------------------------------------------------------------------
end

# Reset the queued pokecenter refresh if nothing changed
EventHandlers.add(:on_enter_map, :pokecenter_follower_reset, proc { |_old_map_id|
  $game_temp.pokecenter_following_pkmn = 0
})

#-------------------------------------------------------------------------------
# Ensure Following Pokemon is spawned and visible immediately on map entry
#-------------------------------------------------------------------------------
EventHandlers.add(:on_enter_map, :following_pkmn_spawn_on_map, proc { |_old_map_id|
  FollowingPkmn.clear_frozen_state
  if $player && $player.first_able_pokemon
    $PokemonGlobal.follower_toggled = true if $PokemonGlobal.follower_toggled.nil?
    $PokemonGlobal.follower_toggle_locked = false
    if $PokemonGlobal.follower_toggled
      if $game_temp&.followers && !FollowingPkmn.get
        $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
        $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil
        $game_temp.followers.add_follower($game_player, "FollowingPkmn", FollowingPkmn::FOLLOWER_COMMON_EVENT) rescue nil
      end
      FollowingPkmn.refresh(false) rescue nil
    end
  else
    FollowingPkmn.remove_sprite rescue nil
    $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
    $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil if $game_temp&.followers
  end
})

EventHandlers.add(:on_map_or_spriteset_change, :following_pkmn_ensure_spawn, proc { |sender, e|
  if $player && $player.first_able_pokemon && ($PokemonGlobal&.follower_toggled != false)
    if $game_temp&.followers && !FollowingPkmn.get
      $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
      $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil
      $game_temp.followers.add_follower($game_player, "FollowingPkmn", FollowingPkmn::FOLLOWER_COMMON_EVENT) rescue nil
    end
    FollowingPkmn.refresh(false) rescue nil
  elsif $player && !$player.first_able_pokemon
    FollowingPkmn.remove_sprite rescue nil
    $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
    $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil if $game_temp&.followers
  end
})

#-------------------------------------------------------------------------------
# Refresh Following Pokemon after taking a step, when a refresh is queued
#-------------------------------------------------------------------------------
EventHandlers.add(:on_player_step_taken, :forced_follower_refresh, proc {
  next if !$PokemonGlobal.call_refresh[0]
  # Wait for steps
  if $PokemonGlobal.call_refresh[2] && $PokemonGlobal.call_refresh[2] > 0
    $PokemonGlobal.call_refresh[2] -= 1
    $PokemonGlobal.call_refresh.delete_at(2) if $PokemonGlobal.call_refresh[2] == 0
    next
  end
  # Refresh queued
  FollowingPkmn.refresh($PokemonGlobal.call_refresh[1])
  $PokemonGlobal.call_refresh = false
})
