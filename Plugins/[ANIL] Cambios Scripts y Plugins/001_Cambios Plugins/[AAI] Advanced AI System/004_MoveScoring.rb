#===============================================================================
# ANIL → AAI Compatibility — Move scoring patches
#===============================================================================
return unless defined?(AdvancedAI)

module AnilAAI_MoveScoring
  def score_damage_potential(move, user, target, skill)
    score = super
    return score unless skill >= 60 && target && move && user

    # Anular bonus vanilla de chip <50% HP: Emergency Exit ya no usa ese trigger.
    if target.hasActiveAbility?(:EMERGENCYEXIT) &&
       !target.hasActiveAbility?(:WIMPOUT) &&
       !AdvancedAI::Utilities.ignores_ability?(user) &&
       target.hp > target.totalhp / 2
      bp = calculate_effective_power(move, user, target) rescue nil
      rough_damage = calculate_rough_damage(move, user, target, bp) rescue 0
      chip_triggers = rough_damage >= target.hp - (target.totalhp / 2) && rough_damage < target.hp
      score -= 20 if chip_triggers
    end

    score
  end

  def score_pivot_utility(move, user, target, skill)
    score = super
    score + AnilAAI.evaluate_emergency_exit_pivot(@battle, user, move, target, skill)
  end

  def score_type_effectiveness(move, user, target)
    score = super
    return score unless move && target

    if AnilAAI.super_effective_against_bug?(move) && target.pbHasType?(:BUG)
      effective_type = AdvancedAI::CombatUtilities.resolve_move_type(user, move)
      type_mod = AnilAAI.anil_effectiveness(effective_type, target.pbTypes(true), move)

      if target.hasActiveAbility?(:WONDERGUARD) && !AdvancedAI::Utilities.ignores_ability?(user)
        return Effectiveness.super_effective?(type_mod) ? 40 : -200
      end

      if Effectiveness.super_effective?(type_mod)
        return 40
      elsif Effectiveness.not_very_effective?(type_mod)
        return user.hasActiveAbility?(:TINTEDLENS) ? -5 : -30
      elsif Effectiveness.ineffective?(type_mod)
        return -200
      end
    end

    score
  end

  def calculate_rough_damage(move, user, target, override_bp = nil)
    damage = super
    return damage if damage <= 0

    eff_ratio = AnilAAI.effectiveness_damage_ratio(move, user, target)
    damage = (damage * eff_ratio).to_i if eff_ratio != 1.0

    extra = AnilAAI.extra_damage_multiplier(move, user, target, @battle)
    damage = (damage * extra).to_i if extra != 1.0

    [damage, 1].max
  end
end

class Battle::AI
  prepend AnilAAI_MoveScoring
end
