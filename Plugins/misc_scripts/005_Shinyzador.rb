SHINYZADOR_SWTICH = 122
ItemHandlers::UseFromBag.add(:SHINYZADOR, proc { |item| 
  if $game_switches[SHINYZADOR_SWTICH]
    pbMessage(_INTL("Ya has usado una Poción Brillante."))
    next 0
  else
    $game_switches[SHINYZADOR_SWTICH] = true
    pbMessage(_INTL("El siguiente Pokémon salvaje que te encuentres será variocolor."))
    next 1
  end
})

EventHandlers.add(:on_wild_pokemon_created, :shinyzador,
  proc { |pkmn|
    if $game_switches[SHINYZADOR_SWTICH] && !$PokemonSystem.salvajes_visibles_en_ow?
      pkmn.shiny = true 
      pkmn.super_shiny = false # if rand(10) == 0
      $game_switches[SHINYZADOR_SWTICH] = false
    end
  }
)