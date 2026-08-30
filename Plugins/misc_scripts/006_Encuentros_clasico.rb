# Agrega encuentros del Añil modo Clásico 
class PokemonEncounters
  alias original_encounter_type encounter_type
  def encounter_type
      time = pbGetTimeNow
      ret = original_encounter_type
      if $game_switches[MODO_CLASICO]
        t = nil
        if $PokemonGlobal.surfing
            ret = find_valid_encounter_type_for_time(:WaterClassic, time)
        else   # Land/Cave (can have both in the same map)
          if has_land_encounters? && $game_map.terrain_tag($game_player.x, $game_player.y).land_wild_encounters
            ret = :BugContestClassic if pbInBugContest? && has_encounter_type?(:BugContestClassic)
            ret = find_valid_encounter_type_for_time(:LandClassic, time) if !ret
          end
          if !ret && has_cave_encounters?
            ret = find_valid_encounter_type_for_time(:CaveClassic, time)
          end
        end
      end
      return ret
  end
  
  alias find_valid_encounter_type_for_time_classic find_valid_encounter_type_for_time
  def find_valid_encounter_type_for_time(base_type, time)
    ret = find_valid_encounter_type_for_time_classic(base_type, time)
    if $game_switches[MODO_CLASICO] && ret && !ret.to_s.end_with?("Classic") 
      ret = "#{ret}Classic".to_sym 
    end
    return ret
  end
end



ItemHandlers::UseInField.add(:OLDROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end
  tipo_pesca = $game_switches[MODO_CLASICO] ? :OldRodClassic : :OldRod
  encounter = $PokemonEncounters.has_encounter_type?(tipo_pesca)
  if pbFishing(encounter, 1)
    $stats.fishing_battles += 1
    pbEncounter(tipo_pesca)
  end
  next true
})

ItemHandlers::UseInField.add(:SUPERROD, proc { |item|
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end
  tipo_pesca = $game_switches[MODO_CLASICO] ? :SuperRodClassic : :SuperRod
  encounter = $PokemonEncounters.has_encounter_type?(tipo_pesca)
  if pbFishing(encounter, 1)
    $stats.fishing_battles += 1
    pbEncounter(tipo_pesca)
  end
  next true
})


class BugContestState
  alias original_pbJudge pbJudge 
  def pbJudge
    if $game_switches[MODO_CLASICO]
      judgearray = []
      if @lastPokemon
        judgearray.push([-1, @lastPokemon.species, pbBugContestScore(@lastPokemon)])
      end
      maps_with_encounters = []
      @contestMaps.each do |map|
        enc_type = :BugContestClassic
        enc_type = :LandClassic if !$PokemonEncounters.map_has_encounter_type?(map, enc_type)
        if $PokemonEncounters.map_has_encounter_type?(map, enc_type)
          maps_with_encounters.push([map, enc_type])
        end
      end
      raise _INTL("No hay Concursos de Bicho/encuentros para ningún mapa de Concurso de Bichos.") if maps_with_encounters.empty?
      @contestants.each do |cont|
        enc_data = maps_with_encounters.sample
        enc = $PokemonEncounters.choose_wild_pokemon_for_map(enc_data[0], enc_data[1])
        raise _INTL("No hay encuentros en el mapa {1} por algún motivo, así que no se puede juzgar el concurso.", enc_data[0]) if !enc
        pokemon = Pokemon.new(enc[0], enc[1])
        pokemon.hp = rand(1...pokemon.totalhp)
        score = pbBugContestScore(pokemon)
        judgearray.push([cont, pokemon.species, score])
      end
      raise _INTL("Hay muy pocos participantes del concurso de bichos") if judgearray.length < 3
      judgearray.sort! { |a, b| b[2] <=> a[2] }   # sort by score in descending order
      @places.push(judgearray[0])
      @places.push(judgearray[1])
      @places.push(judgearray[2])
    else
      original_pbJudge
    end
  end
end




# Encuentros especiales del Añil modo Clásico
GameData::EncounterType.register({
  :id             => :LandClassic,
  :type           => :land,
  :trigger_chance => 21
})

GameData::EncounterType.register({
  :id             => :CaveClassic,
  :type           => :cave,
  :trigger_chance => 5
})

GameData::EncounterType.register({
  :id             => :WaterClassic,
  :type           => :water,
  :trigger_chance => 2
})

GameData::EncounterType.register({
  :id             => :OldRodClassic,
  :type           => :fishing
})

GameData::EncounterType.register({
  :id             => :GoodRodClassic,
  :type           => :fishing
})

GameData::EncounterType.register({
  :id             => :SuperRodClassic,
  :type           => :fishing
})

GameData::EncounterType.register({
  :id             => :RockSmashClassic,
  :type           => :none,
  :trigger_chance => 50
})