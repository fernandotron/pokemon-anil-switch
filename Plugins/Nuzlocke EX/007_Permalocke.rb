DEFAULT_PERMALOCKE_SHIELDS = 6
class PokemonGlobalMetadata
    attr_accessor :max_party_size
    attr_accessor :permalocke_shields
    attr_accessor :permalocke_max_shields

    alias init_permalocke initialize
    def initialize
        init_permalocke
        valor_vidas = $PokemonGlobal&.challenge_lives || 0
        @permalocke_max_shields ||= valor_vidas
        @permalocke_shields ||= @permalocke_max_shields
    end
end
def permalocke_remove_fainted
  fainted_count = 0
  fainted = {}
  $player.party.each_with_index do |pkmn, index|
    next if !pkmn.fainted?
    fainted_count += 1
    fainted[index] = pkmn
  end 

  slots_to_lock = 0
  shields_to_remove = 0
  shields = permalocke_shields
  if shields > 0
    shields_to_remove = fainted_count > shields ? shields : fainted_count
    permalocke_set_shields(shields - shields_to_remove) 
  end
  
  slots_to_lock = fainted_count - shields_to_remove
  return if permalocke_shields > 0

  $PokemonGlobal.max_party_size -= slots_to_lock
  
  fainted.keys.sort.reverse.each do |index|
    pkmn = fainted[index]
    if $player.has_other_able_pokemon?(index)
      move_fainted_to_storage(pkmn)
      $player.remove_pokemon_at_index(index)
    elsif $player.party.length > 1
      move_fainted_to_storage(pkmn)
      $player.party.delete_at(index)
    else
      break
    end
  end
end

def move_fainted_to_storage(pkmn)
  box = $PokemonStorage.pbFindBoxWithSpace(:desc)
  $PokemonStorage.pbMoveCaughtToBox(pkmn, box)
end

def permalocke_max_shields
  # $PokemonGlobal.permalocke_max_shields ||= DEFAULT_PERMALOCKE_SHIELDS
  $PokemonGlobal.permalocke_max_shields ||= $PokemonGlobal.challenge_lives || 0
  return $PokemonGlobal.permalocke_max_shields
end

def permalocke_shields
  # $PokemonGlobal.permalocke_shields ||= DEFAULT_PERMALOCKE_SHIELDS
  $PokemonGlobal.permalocke_shields ||= $PokemonGlobal.challenge_lives || 0
  return $PokemonGlobal.permalocke_shields
end

def permalocke_set_shields(shields)
  $PokemonGlobal.challenge_lives = shields
  $PokemonGlobal.permalocke_shields = shields
end

def permalocke_restore_slots(slot_count = 1)
  return if !defined?(ChallengeModes) || !ChallengeModes.on?(:PERMALOCKE)
  
  # Calculate how many slots can actually be restored to party
  max_restorable_to_party = Settings::MAX_PARTY_SIZE - $PokemonGlobal.max_party_size
  slots_restored_to_party = [slot_count, max_restorable_to_party].min
  
  # Restore slots to party
  $PokemonGlobal.max_party_size += slots_restored_to_party
  
  # Any remaining slots that couldn't be restored to party go to shields
  remaining_slots = slot_count - slots_restored_to_party
  permalocke_set_shields(permalocke_shields + remaining_slots)
end