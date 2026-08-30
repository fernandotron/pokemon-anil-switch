
EventHandlers.add(:on_wild_pokemon_created, :hacer_shiny_a_salvajes,
  proc { |pkmn|
    next if $PokemonSystem.salvajes_visibles_en_ow != 1
    # next if $game_switches[OW_ENCOUNTER_SWITCH] == true
    
    # Initialize catch combo if needed
    $PokemonGlobal.catchcombo = [0, 0] if $PokemonGlobal.catchcombo.nil?
    
    # Helper method to set shiny status
    def set_shiny_status(pkmn, shiny_chance)
      shiny_chance /= 2 if $bag.has?(:SHINYCHARM)
      return unless rand(shiny_chance) == 0
      
      pkmn.shiny = true
      pkmn.super_shiny = true if rand(10) == 0
    end
    
    # Determine shiny probability based on catch combo
    combo_count = $PokemonGlobal.catchcombo[0]
    is_same_species = $PokemonGlobal.catchcombo[1] == pkmn.species
    
    if is_same_species
      # Chain shiny probabilities for same species
      shiny_chance = case combo_count
                     when (CHAINLENGTH * 4)..Float::INFINITY  # 40+ chain
                       SHINYPROBABILITY / 5     # 1/200
                     when (CHAINLENGTH * 3)...(CHAINLENGTH * 4)  # 30-39 chain
                       SHINYPROBABILITY / 5 * 2  # 1/400
                     when (CHAINLENGTH * 2)...(CHAINLENGTH * 3)  # 20-29 chain
                       SHINYPROBABILITY / 5 * 3  # 1/600
                     when CHAINLENGTH...(CHAINLENGTH * 2)        # 10-19 chain
                       SHINYPROBABILITY / 5 * 4  # 1/800
                     else
                       SHINYPROBABILITY         # 1/1000 (base rate)
                     end
    else
      # Base shiny probability for different species
      shiny_chance = SHINYPROBABILITY
    end
    
    set_shiny_status(pkmn, shiny_chance)
  }
)
