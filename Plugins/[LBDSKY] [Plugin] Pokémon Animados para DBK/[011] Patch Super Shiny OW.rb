# ===========================================================================
# Following Pokemon EX
# ===========================================================================
if PluginManager.installed?("Following Pokemon EX")
  module FollowingPkmn
    class << self
      alias_method :dbk_change_sprite, :change_sprite
      
      def change_sprite(pkmn)
        dbk_change_sprite(pkmn)
        if pkmn && pkmn.respond_to?(:super_shiny?) && pkmn.super_shiny? && pkmn.respond_to?(:super_shiny_hue)
          hue = pkmn.super_shiny_hue
          FollowingPkmn.get_event&.character_hue = hue
          FollowingPkmn.get_data&.character_hue  = hue
        end
      end
    end
  end
end

# ===========================================================================
# Voltseon's Overworld Encounters (VOE)
# ===========================================================================
if PluginManager.installed?("Voltseon's Overworld Encounters")
  def pbChangeEventSprite(event, pkmn, water = false)
    shiny = pkmn.shiny?
    
    fname = pbOWSpriteFilename(pkmn.species, pkmn.form, pkmn.gender, shiny, pkmn.shadow, water)
    fname = pbOWSpriteFilename(pkmn.species, 0, pkmn.gender, shiny, pkmn.shadow, water) if pkmn.species == :MINIOR

    raise "Following Pokémon sprites were not found." if nil_or_empty?(fname)
    fname.gsub!("Graphics/Characters/", "")
    event.character_name = fname
    
    hue = 0
    if pkmn.super_shiny? && pkmn.respond_to?(:super_shiny_hue)
      hue = pkmn.super_shiny_hue
    end

    event.character_hue = hue
  end
end

# ===========================================================================
# Visible Overworld Wild Encounters (VOWE)
# ===========================================================================
if PluginManager.installed?("Visible Overworld Wild Encounters")
  class Game_Map
    alias_method :dbk_spawnPokeEvent, :spawnPokeEvent 
    
    def spawnPokeEvent(x, y, pokemon)
      dbk_spawnPokeEvent(x, y, pokemon)
    
      event_id = @events.keys.max
      event = @events[event_id]
      return unless event && event.is_a?(Game_PokeEvent)
    
      if pokemon.super_shiny?
        fname = ow_sprite_filename(pokemon.species, pokemon.form, pokemon.gender, true, pokemon.shadowPokemon?)        
        fname.gsub!("Graphics/Characters/", "")        
        hue = pokemon.respond_to?(:super_shiny_hue) ? pokemon.super_shiny_hue : 0
        rpg_event_data = event.instance_variable_get(:@event)
      
        if rpg_event_data && rpg_event_data.pages[0]
          rpg_event_data.pages[0].graphic.character_name = fname
          event.character_name = fname
        
          rpg_event_data.pages[0].graphic.character_hue = hue
          event.character_hue = hue
        end
      end
    end
  end
end 