#-------------------------------------------------------------------------------
# Change EBDX Following Pokemon check since EBDX hasn't updated
#-------------------------------------------------------------------------------
if PluginManager.installed?("Elite Battle: DX")
  module EliteBattle
    def self.follower(battle)
      return nil if !EliteBattle::USE_FOLLOWER_EXCEPTION
      return (FollowingPkmn.active? && battle.scene.firstsendout) ? 0 : nil
    end
  end
end

#-------------------------------------------------------------------------------
# New GameData::Species method for easily get the appropriate Following Pokemon
# graphic
#-------------------------------------------------------------------------------
module GameData
  class Species
    def self.ow_sprite_filename(species, form = 0, gender = 0, shiny = false, shadow = false, swimming = false)
      # Check for swimming sprites first if swimming
      if swimming
        folder = shiny ? "Swimming Shiny" : "Swimming"
        ret = self.check_graphic_file("Graphics/Characters/", species, form,
                                      gender, shiny, shadow, folder)
        return ret if !nil_or_empty?(ret)
        
        # If no swimming sprite, check for levitate sprites (for airborne Pokemon)
        folder = shiny ? "Levitates Shiny" : "Levitates"
        ret = self.check_graphic_file("Graphics/Characters/", species, form,
                                      gender, shiny, shadow, folder)
        return ret if !nil_or_empty?(ret)
      end
      
      # Fall back to regular follower sprites
      ret = self.check_graphic_file("Graphics/Characters/", species, form,
                                    gender, shiny, shadow, "Followers")
      ret = "Graphics/Characters/Followers/000" if nil_or_empty?(ret)
	    return ret
    end
  end
end

#-------------------------------------------------------------------------------
# Prevent Enhanced Stairs from messing with FollowingPokemon
#-------------------------------------------------------------------------------
class Game_FollowerFactory
  alias __followingpkmn__update update unless method_defined?(:__followingpkmn__update)
  def update(*args)
    __followingpkmn__update(*args)
    followers = $PokemonGlobal.followers
    return if followers.length == 0
    leader = $game_player
    followers.each_with_index do |follower, i|
      event = @events[i]
      next if !@events[i]
      event.move_speed = leader.move_speed if follower.following_pkmn?
      leader = event
    end
  end
end

#-------------------------------------------------------------------------------
# Make sure shadows of Following Pokemon exist
#-------------------------------------------------------------------------------
class Game_Follower
  alias __followingpkmn__initialize initialize unless method_defined?(:__followingpkmn__initialize)
  def initialize(*args)
    __followingpkmn__initialize(*args)
    calculate_bush_depth
  end
end

#===============================================================================
# Options Categories - Fallback if not defined
#===============================================================================
module OptionsCategories
  BATTLE = :battle
  AUDIO = :audio
  GRAPHICS = :graphics
  GAMEPLAY = :gameplay
  PLUGINS = :plugins
  SYSTEM = :system
end unless defined?(OptionsCategories)

#-------------------------------------------------------------------------------
# New option in the Options menu to toggle Following Pokemon
#-------------------------------------------------------------------------------
MenuHandlers.add(:options_menu, :follower_toggle, {
  "name"        => _INTL("Pokémon siguiendo"),
  "order"       => 160,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Permite que el primer Pokémon de tu equipo te siga por los mapas."),
  "category"    => OptionsCategories::PLUGINS,
  "condition"   => proc { FollowingPkmn.can_check? && FollowingPkmn::SHOW_TOGGLE_IN_OPTIONS },
  "get_proc"    => proc { next ($PokemonGlobal&.follower_toggled ? 0 : 1) },
  "set_proc"    => proc { |value, _scene|
    next if !FollowingPkmn.can_check?
    $PokemonGlobal.follower_toggled = (value == 0)
    if $PokemonGlobal.follower_toggled
      $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
      $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil
      $game_temp.followers.add_follower($game_player, "FollowingPkmn", FollowingPkmn::FOLLOWER_COMMON_EVENT) rescue nil
      FollowingPkmn.refresh(false) rescue nil
    else
      FollowingPkmn.refresh(false) rescue nil
      FollowingPkmn.remove_sprite rescue nil
    end
  }
})

#-------------------------------------------------------------------------------
# Extend PokemonOptionScreen to refresh scene map after options
#-------------------------------------------------------------------------------
class PokemonOptionScreen
  alias __followingpkmn__pbStartScreen pbStartScreen unless method_defined?(:__followingpkmn__pbStartScreen)
  def pbStartScreen(*args)
    __followingpkmn__pbStartScreen(*args)
    pbRefreshSceneMap
  end
end

#-------------------------------------------------------------------------------
# New trigger method for Named Events that returns the value of the callback
#-------------------------------------------------------------------------------
class NamedEvent
  def trigger_2(*args)
    @callbacks.each_value { |callback|
      ret = callback.call(*args)
      return ret if !ret.nil?
    }
    return -1
  end
end

#-------------------------------------------------------------------------------
# New trigger method for EventHandlers that returns the value of the callback
#-------------------------------------------------------------------------------
module EventHandlers
  def self.trigger_2(event, *args)
    return @@events[event]&.trigger_2(*args)
  end
end
