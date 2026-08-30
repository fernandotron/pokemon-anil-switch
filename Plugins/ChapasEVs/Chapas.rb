#===============================================================================
# Change IVs Neme
#===============================================================================
IVGANADOS = 10

def pbJustRaiseIndividualValues(pkmn, stat, ivGain)
  stat = GameData::Stat.get(stat).id
  ivGain = ivGain.clamp(0, Pokemon::IV_STAT_LIMIT - pkmn.iv[stat])
  if ivGain > 0
    pkmn.iv[stat] += ivGain
    pkmn.calc_stats
  end
  return ivGain
end

def pbRaiseIndividualValues(pkmn, stat, ivGain = IVGANADOS)
  stat = GameData::Stat.get(stat).id
  return 0 if pkmn.iv[stat] >= Pokemon::IV_STAT_LIMIT
  ivGain = ivGain.clamp(0, Pokemon::IV_STAT_LIMIT - pkmn.iv[stat])
  if ivGain > 0
    pkmn.iv[stat] += ivGain
    pkmn.calc_stats
  end
  return ivGain
end

def pbMaxUsesOfIVRaisingItem(stat, amt_per_use, pkmn)
  max_per_stat = Pokemon::IV_STAT_LIMIT
  amt_can_gain = max_per_stat - pkmn.iv[stat]
  return [(amt_can_gain.to_f / amt_per_use).ceil, 1].max
end

def pbUseIVRaisingItem(stat, amt_per_use, qty, pkmn, happiness_type, scene)
  ret = true
  fainted = pkmn.fainted?
  qty.times do |i|
    if pbRaiseIndividualValues(pkmn, stat, amt_per_use) > 0
      pkmn.changeHappiness(happiness_type)
    else
      ret = false if i == 0
      break
    end
  end
  if !ret
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    return false
  end
  if fainted && !pkmn.fainted?
    pkmn.hp = 0
  end
  pbSEPlay("Use item in party")
  scene.pbRefresh
  scene.pbDisplay(_INTL("Los puntos individuales del {2} de {1} han aumentado.", pkmn.name, GameData::Stat.get(stat).name))
  return true
end

def pbUseIVRaisingItemMulti(stat_array, amt_per_use, qty, pkmn, happiness_type, scene)
  ret = false
  stat_array.each do |stat|
    next if pkmn.iv[stat] == 31
    qty.times do |i|
      if pbRaiseIndividualValues(pkmn, stat, amt_per_use) > 0
        pkmn.changeHappiness(happiness_type)
        ret = true
      else
        break
      end
    end
  end
  if !ret
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    return false
  end
  pbSEPlay("Use item in party")
  scene.pbRefresh
  stat_names = stat_array.map { |stat| GameData::Stat.get(stat).name }.join(", ")
  scene.pbDisplay(_INTL("Los puntos individuales de {2} de {1} han aumentado.", pkmn.name, stat_names))
  return true
end

ItemHandlers::UseOnPokemonMaximum.add(:SCapsula, proc { |item, pkmn|
  next pbMaxUsesOfIVRaisingItem(:HP, IVGANADOS, pkmn)
})

ItemHandlers::UseOnPokemon.add(:SCapsula, proc { |item, qty, pkmn, scene|
  next pbUseIVRaisingItem(:HP, IVGANADOS, qty, pkmn, "vitamin", scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:ACapsula, proc { |item, pkmn|
  next pbMaxUsesOfIVRaisingItem(:ATTACK, IVGANADOS, pkmn)
})

ItemHandlers::UseOnPokemon.add(:ACapsula, proc { |item, qty, pkmn, scene|
  next pbUseIVRaisingItem(:ATTACK, IVGANADOS, qty, pkmn, "vitamin", scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:DCapsula, proc { |item, pkmn|
  next pbMaxUsesOfIVRaisingItem(:DEFENSE, IVGANADOS, pkmn)
})

ItemHandlers::UseOnPokemon.add(:DCapsula, proc { |item, qty, pkmn, scene|
  next pbUseIVRaisingItem(:DEFENSE, IVGANADOS, qty, pkmn, "vitamin", scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:AECapsula, proc { |item, pkmn|
  next pbMaxUsesOfIVRaisingItem(:SPECIAL_ATTACK, IVGANADOS, pkmn)
})

ItemHandlers::UseOnPokemon.add(:AECapsula, proc { |item, qty, pkmn, scene|
  next pbUseIVRaisingItem(:SPECIAL_ATTACK, IVGANADOS, qty, pkmn, "vitamin", scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:DECapsula, proc { |item, pkmn|
  next pbMaxUsesOfIVRaisingItem(:SPECIAL_DEFENSE, IVGANADOS, pkmn)
})

ItemHandlers::UseOnPokemon.add(:DECapsula, proc { |item, qty, pkmn, scene|
  next pbUseIVRaisingItem(:SPECIAL_DEFENSE, IVGANADOS, qty, pkmn, "vitamin", scene)
})

ItemHandlers::UseOnPokemonMaximum.add(:VCapsula, proc { |item, pkmn|
  next pbMaxUsesOfIVRaisingItem(:SPEED, IVGANADOS, pkmn)
})

ItemHandlers::UseOnPokemon.add(:VCapsula, proc { |item, qty, pkmn, scene|
  next pbUseIVRaisingItem(:SPEED, IVGANADOS, qty, pkmn, "vitamin", scene)
})

# ItemHandlers::UseOnPokemon.add(:CHAPADORADA, proc { |item, qty, pkmn, scene|
#   next pbUseIVRaisingItemMulti([:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED], 31, qty, pkmn, "vitamin", scene)
# })