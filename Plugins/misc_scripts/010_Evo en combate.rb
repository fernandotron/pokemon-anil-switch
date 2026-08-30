
class Battle 

    alias pbGainExp_evo_en_combate pbGainExp

    def pbGainExp

        pbGainExp_evo_en_combate

        # Código nuevo
        $player.party.each_with_index do |pkmn, i|
          next if !pkmn || pkmn.egg?
          next if pkmn.fainted? && !Settings::CHECK_EVOLUTION_FOR_FAINTED_POKEMON
          # Find an evolution
          new_species = nil
          if new_species.nil? && $game_temp.party_levels_before_battle &&
                  $game_temp.party_levels_before_battle[i] &&
                  $game_temp.party_levels_before_battle[i] < pkmn.level

            new_species = pkmn.check_evolution_on_level_up
            $game_temp.party_levels_before_battle[i] = pkmn.level ##
          end
          new_species = pkmn.check_evolution_after_battle(i) if new_species.nil?
          #echoln "new_species: #{new_species}"

          next if new_species.nil?
          
          pbFadeOutIn do
            # Guardar datos antes de la evolución
            old_item = pkmn.item
            battler = pbFindBattler(i)  # Buscar al Pokémon en el campo de batalla si está presente
            previousBGM = $game_system.getPlayingBGM
            #echoln "Música previa: #{previousBGM}"
        
            # Evolve Pokémon if possible
            evo = PokemonEvolutionScene.new
            evo.pbStartScreen(pkmn, new_species)
            evo.pbEvolution
            evo.pbEndScreen
        
            # Actualizar la representación del Pokémon en combate tras la evolución
            if battler
              @scene.pbChangePokemon(battler, battler.pokemon)
              battler.name = pkmn.name
              pkmn.moves.each_with_index do |move, j|
                battler.moves[j] = Battle::Move.from_pokemon_move(self, move)
              end
              battler.pbCheckFormOnMovesetChange
              if pkmn.item != old_item
                battler.item = pkmn.item
                battler.setInitialItem(pkmn.item)
                battler.setRecycleItem(pkmn.item)
              end
              battler.pbUpdate(false)
              @scene.pbRefreshOne(battler.index)
            end
            pbBGMPlay(previousBGM)
          end
        end
    end
end