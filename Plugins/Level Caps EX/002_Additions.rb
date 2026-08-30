#-------------------------------------------------------------------------------
# Rare Candy edits for Level Caps
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemonMaximum.add(:RARECANDY, proc { |item, pkmn|
  max_lv = LevelCapsEX.soft_cap? ? LevelCapsEX.level_cap : GameData::GrowthRate.max_level
  next max_lv - pkmn.level
})

ItemHandlers::UseOnPokemon.add(:RARECANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("No tendrá ningún efecto."))
    next false
  elsif pkmn.level >= GameData::GrowthRate.max_level
    new_species = pkmn.check_evolution_on_level_up
    if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
      scene.pbDisplay(_INTL("No tendrá ningún efecto."))
      next false
    end
    # Check for evolution
    pbFadeOutInWithMusic do
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn, new_species)
      evo.pbEvolution
      evo.pbEndScreen
      scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
    end
    next true
  elsif pkmn.crosses_level_cap?
    scene.pbDisplay(_INTL("{1} se niega comer {2}.", pkmn.name, GameData::Item.get(item).name))
    next false
  end
  # Level up
  pbSEPlay("Pkmn level up")
  pbChangeLevel(pkmn, pkmn.level + qty, scene)
  scene.pbHardRefresh
  next true
})

#-------------------------------------------------------------------------------
# EXP Candy Edits for Level Caps
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXS, proc { |item, pkmn|
  gain_amount = 100
  max_exp = LevelCapsEX.soft_cap? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next ((max_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 100, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYS, proc { |item, pkmn|
  gain_amount = 800
  max_exp = LevelCapsEX.soft_cap? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next ((max_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 800, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYM, proc { |item, pkmn|
  gain_amount = 3_000
  max_exp = LevelCapsEX.soft_cap? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next ((max_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYM, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 3_000, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYL, proc { |item, pkmn|
  gain_amount = 10_000
  max_exp = LevelCapsEX.soft_cap? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next ((max_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 10_000, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXL, proc { |item, pkmn|
  gain_amount = 30_000
  max_exp = LevelCapsEX.soft_cap? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next ((max_exp - pkmn.exp) / gain_amount.to_f).ceil
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 30_000, qty, scene, item)
})

def pbGainExpFromExpCandy(pkmn, base_amt, qty, scene, item)
  if pkmn.level >= GameData::GrowthRate.max_level || pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("No tendrá ningún efecto."))
    return false
  end
  
  # Hard cap check - completely prevent exp gain if level cap is reached
  if LevelCapsEX.hard_cap? && pkmn.level >= LevelCapsEX.level_cap
    scene.pbDisplay(_INTL("{1} se niega comer {2}.", pkmn.name, GameData::Item.get(item).name))
    return false
  end
  
  # Berechne die maximale Exp, die das Pokémon erhalten kann
  max_exp = LevelCapsEX.soft_cap? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  exp_gain = base_amt * qty
  new_exp = pkmn.exp + exp_gain
  
  # Wenn die neue Exp das Level Cap überschreiten würde, begrenze die Exp-Vergabe
  if new_exp > max_exp
    exp_gain = max_exp - pkmn.exp
    if exp_gain <= 0
      scene.pbDisplay(_INTL("{1} se niega comer {2}.", pkmn.name, GameData::Item.get(item).name))
      return false
    end
  end
  
  pbSEPlay("Pkmn level up")
  scene.scene.pbSetHelpText("") if scene.is_a?(PokemonPartyScreen)
  if qty > 1
    (qty - 1).times { pkmn.changeHappiness("vitamin") }
  end
  pbChangeExp(pkmn, pkmn.exp + exp_gain, scene)
  scene.pbHardRefresh
  return true
end

#-------------------------------------------------------------------------------
# Additions to Game Variables to log Level Cap changes and set defaults
#-------------------------------------------------------------------------------
class Game_Variables
  alias __level_caps__set_variable []= unless method_defined?(:__level_caps__set_variable)
  def []=(variable_id, value)
    old_value = self[variable_id]
    ret = __level_caps__set_variable(variable_id, value)
    if value != old_value && LevelCapsEX::LOG_LEVEL_CAP_CHANGES
      if variable_id == LevelCapsEX::LEVEL_CAP_VARIABLE
        echoln "Current Level Cap updated from Lv. #{old_value} to Lv. #{value}"
      elsif variable_id == LevelCapsEX::LEVEL_CAP_MODE_VARIABLE && self[LevelCapsEX::LEVEL_CAP_VARIABLE] != 0
        mode_names = [
          "None",
          "Hard Cap",
          "EXP Cap",
          "Obedience Cap"
        ]
        old_name = mode_names[old_value] || "None"
        new_name = mode_names[value] || "None"
        echoln "Current Level Cap Mode updated from \"#{old_name}\" to \"#{new_name}\""
      end
    end
    return ret
  end
end

module Game
  class << self
    alias __level_caps__start_new start_new unless method_defined?(:__level_caps__start_new)
    alias __level_caps__load load unless method_defined?(:__level_caps__load)
  end

  def self.start_new(*args)
    __level_caps__start_new(*args)
    $game_variables[LevelCapsEX::LEVEL_CAP_MODE_VARIABLE] = LevelCapsEX::DEFAULT_LEVEL_CAP_MODE
  end

  def self.load(save_data)
    __level_caps__load(save_data)
    LevelCapsEX.toggle if !LevelCapsEX.enabled?
  end
end

#-------------------------------------------------------------------------------
# Main Level Cap Module
#-------------------------------------------------------------------------------
module LevelCapsEX

  module_function

  def turn_on_level_cap(mode = DEFAULT_LEVEL_CAP_MODE)
    $game_variables[LEVEL_CAP_MODE_VARIABLE] = mode
  end

  def level_cap
    cap = get_level_cap
    return cap if cap && cap > 0 
    return Settings::MAXIMUM_LEVEL
  end

  def level_cap_mode
    return if !$game_variables
    $game_variables[LEVEL_CAP_MODE_VARIABLE] ||= DEFAULT_LEVEL_CAP_MODE
    lv_cap_mode = $game_variables[LEVEL_CAP_MODE_VARIABLE]
    return lv_cap_mode if [1, 2, 3].include?(lv_cap_mode)
    return 0
  end

  def hard_cap?
    return level_cap_mode == 1 && $game_variables[LEVEL_CAP_VARIABLE] > 0
  end

  def soft_cap?
    return [2, 3].include?(level_cap_mode) && $game_variables[LEVEL_CAP_VARIABLE] > 0
  end

  def hard_level_cap
    max_lv = Settings::MAXIMUM_LEVEL
    return max_lv if !$game_variables
    lv_cap_mode = level_cap_mode
    lv_cap = level_cap
    return max_lv if lv_cap > max_lv 
    return lv_cap if lv_cap > 0 && lv_cap_mode == 1
    return max_lv
  end
  
  # Add a new method to check if a Pokemon can gain EXP
  def can_gain_exp?(pokemon)
    return false if hard_cap? && pokemon.level >= level_cap
    return true
  end
end