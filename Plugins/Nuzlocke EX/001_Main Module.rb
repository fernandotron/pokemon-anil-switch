#-------------------------------------------------------------------------------
# Main Module for handling challenge data
#-------------------------------------------------------------------------------
module ChallengeModes
  @@started = false

  module_function
  #-----------------------------------------------------------------------------
  # check if challenge is on, toggle challenge state and get rules
  #-----------------------------------------------------------------------------
  def running?; return $PokemonGlobal && $PokemonGlobal.challenge_started; end

  def on?(rule = nil)
    return false if !(running? && @@started)
    return rule.nil? ? true : rules.include?(rule)
  end

  def toggle(force = nil); @@started = force.nil? ? !@@started : force; end

  def rules; return ($PokemonGlobal && $PokemonGlobal.challenge_rules) || []; end
  #-----------------------------------------------------------------------------
  # Main command to start the challenge
  #-----------------------------------------------------------------------------
  def start
    $PokemonGlobal.challenge_rules = select_mode
    return if $PokemonGlobal.challenge_rules.empty?
    $PokemonGlobal.challenge_qued  = true
    $PokemonGlobal.challenge_encs  = {}
    return if !$bag
    GameData::Item.each do |item|
      next if !item.is_poke_ball? || !$bag.has?(item)
      begin_challenge
      pbMessage(_INTL("¡Tu desafío ha comenzado! ¡Buena suerte!"))
      return
    end
  end

  def queued?; return $PokemonGlobal.challenge_qued; end

  #----------------------------------------------------------------------------
  # Script command to begin challenge
  #----------------------------------------------------------------------------
  def begin_challenge
    @@started                             = true
    $PokemonGlobal.challenge_started      = true
    $PokemonGlobal.challenge_qued         = false
    $PokemonSystem.battlestyle            = 1 if $PokemonGlobal.challenge_rules.include?(:FORCE_SET_BATTLES)
    $PokemonSystem.givenicknames          = 0 if $PokemonGlobal.challenge_rules.include?(:FORCE_NICKNAME)
  end
  #-----------------------------------------------------------------------------
  # Clear all challenge data and stop the challenge
  #-----------------------------------------------------------------------------
  def reset
    @@started                             = false
    return if !$PokemonGlobal
    $PokemonGlobal.challenge_qued         = nil
    $PokemonGlobal.challenge_encs         = nil
    $PokemonGlobal.challenge_started      = nil
    pbEachPokemon do |pkmn, _|
      next if !pkmn.respond_to?(:perma_faint)
      pkmn.perma_faint = false
    end
    # Intentionally not resetting rules so that they can be assessed later in case of loss
  end
  #-----------------------------------------------------------------------------
  # Commands to signify victory/loss in challenge
  #-----------------------------------------------------------------------------
  def set_victory(should_reset = false)
    return if !ChallengeModes.on?
    num = $PokemonGlobal.hallOfFameLastNumber
    num = 0 if num < 0
    $PokemonGlobal.challenge_state[num] = [:VICTORY, ChallengeModes.rules.clone]
    reset if should_reset
  end

  def won?(hall_no = -1)
    if hall_no == -1
      return $PokemonGlobal.challenge_state.values.any? { |v| v.is_a?(Array) && v[0] == :VICTORY }
    else
      return false if !$PokemonGlobal.challenge_state[hall_no].is_a?(Array)
      return $PokemonGlobal.challenge_state[hall_no][0] == :VICTORY
    end
  end

  def set_loss(should_reset = true)
    num = $PokemonGlobal.hallOfFameLastNumber
    num = 0 if num < 0
    return if !ChallengeModes.on? || ChallengeModes.won?(num)
    $PokemonGlobal.challenge_state[num] = [:LOSS, ChallengeModes.rules.clone]
    reset if should_reset
  end

  def lost?(hall_no = -1)
    if hall_no == -1
      return $PokemonGlobal.challenge_state.values.any? { |v| v.is_a?(Array) && v[0] == :LOSS }
    else
      return false if !$PokemonGlobal.challenge_state[hall_no].is_a?(Array)
      return $PokemonGlobal.challenge_state[hall_no][0] == :LOSS
    end
  end
  #-----------------------------------------------------------------------------
  # Set and check for encounter on map
  #-----------------------------------------------------------------------------
  def set_first_encounter(pkmn, owned_flag = nil)
    return if !ChallengeModes.on?(:FIRST_CAPTURE) && !ChallengeModes.on?(:ONE_CAPTURE)
    return if $mystery_gift
    sp_data  = GameData::Species.get_species_form(pkmn.species, pkmn.form)
    captured = true
    captured = false if ChallengeModes::ONE_CAPTURE_WHITELIST.any? { |s| pkmn.isSpecies?(s) }
    captured = false if sp_data.has_flag?("OneCaptureWhitelist")
    if ChallengeModes.on?(:DUPS_CLAUSE)
      sp_data.get_family_species.each do |pk| 
        captured = false if owned_flag.nil? ? $player.owned?(pk) : owned_flag
      end
    end
    captured = false if ChallengeModes.on?(:SHINY_CLAUSE) && pkmn.shiny?
    return if !captured
    map_id = $game_map.map_id
    $PokemonGlobal.challenge_encs[map_id] = true
    
    # Check if current map is a parent and mark all children
    if ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS[map_id]
      ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS[map_id].each do |child_map|
        $PokemonGlobal.challenge_encs[child_map] = true
      end
    end
    
    # Check if current map is a child and mark the parent
    ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS.each do |parent_map, child_maps|
      if child_maps.include?(map_id)
        $PokemonGlobal.challenge_encs[parent_map] = true
        # Also mark all other children of this parent
        child_maps.each do |child_map|
          $PokemonGlobal.challenge_encs[child_map] = true
        end
        break
      end
    end
  end

  def had_first_encounter?(pkmn = nil)
    return false if !ChallengeModes.on?(:FIRST_CAPTURE) && !ChallengeModes.on?(:ONE_CAPTURE)
    return false if pkmn && pkmn.shiny? && ChallengeModes.on?(:SHINY_CLAUSE)
    return false if $mystery_gift
    map_id = $game_map.map_id
    return true if $PokemonGlobal.challenge_encs[map_id]
    
    # Check if current map is a parent and any of its children are marked
    if ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS[map_id]
      ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS[map_id].each do |child_map|
        return true if $PokemonGlobal.challenge_encs[child_map]
      end
    end
    
    # Check if current map is a child and its parent is marked
    ChallengeModes::SPLIT_MAPS_FOR_ENCOUNTERS.each do |parent_map, child_maps|
      if child_maps.include?(map_id)
        return true if $PokemonGlobal.challenge_encs[parent_map]
        # Also check if any sibling is marked
        child_maps.each do |child_map|
          return true if $PokemonGlobal.challenge_encs[child_map]
        end
        break
      end
    end
    return false
  end

  #-----------------------------------------------------------------------------
end