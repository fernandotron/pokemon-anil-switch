#===============================================================================
# ANIL → AAI Compatibility — Switch intelligence patches
#===============================================================================
return unless defined?(AdvancedAI)

module AnilAAI_SwitchIntelligence
  def evaluate_pivot_move_option(user, skill)
    bonus = super
    return bonus if bonus > 0
    return bonus unless user && skill >= 50
    return bonus unless AnilAAI.has_emergency_exit_bug_pivot?(@battle, user)

    user.moves.each do |move|
      next unless move && AnilAAI.emergency_exit_pivot_move?(user, move)

      bonus += 25

      @battle.allOtherSideBattlers(user.index).each do |target|
        next unless target && !target.fainted?

        move_type = AdvancedAI::CombatUtilities.resolve_move_type(user, move)
        effectiveness = Effectiveness.calculate(move_type, *target.pbTypes(true))
        if Effectiveness.super_effective?(effectiveness)
          bonus += 10
          break
        end
      end

      break
    end

    bonus
  end

  def evaluate_switch_candidate_detailed(pkmn, current_user, skill)
    score = super
    return score unless pkmn

    ability_id = pkmn.ability_id if pkmn.respond_to?(:ability_id)
    if ability_id == :ESPANTO
      score += 20
    elsif ability_id == :TINTINEO
      score += 10
    elsif ability_id == :ILLUMINATE
      score += 8
    end

    score
  end

  def evaluate_switch_matchup_detailed(switch_pkmn, current_user)
    score = super
    return score unless switch_pkmn

    if switch_pkmn.item_id == :SUPEREVIOLITE &&
       AnilAAI.super_eviolite_active?(switch_pkmn)
      score -= 15
    end

    score
  end

  def calculate_incoming_damage(switch_pkmn, move, attacker)
    damage = super
    return damage unless switch_pkmn && attacker

    if switch_pkmn.item_id == :SUPEREVIOLITE &&
       AnilAAI.super_eviolite_active?(switch_pkmn)
      damage *= 0.67
    end

    atk_holder = attacker.respond_to?(:pokemon) ? attacker.pokemon : attacker
    if attacker.item_id == :SUPEREVIOLITE &&
       AnilAAI.super_eviolite_active?(atk_holder)
      damage *= 1.5
    end

    damage
  end

  def score_status_utility(move, user, target, skill, status_multiplier = 1.0)
    score = super
    return score unless move && target

    fc = move.function_code.to_s rescue ""
    status_fc = ["ParalyzeTarget", "BurnTarget", "PoisonTarget", "BadPoisonTarget",
                 "SleepTarget", "FreezeTarget"].any? { |c| fc.include?(c) }
    return score unless status_fc

    penalty = 0
    @battle.allSameSideBattlers(target).each do |ally|
      next unless ally && AnilAAI.has_active_ability?(ally, :TINTINEO)
      penalty += 25
    end

    if AnilAAI.has_active_ability?(target, :TINTINEO)
      penalty += 25
    end

    score -= penalty if penalty > 0
    score
  end
end

class Battle::AI
  prepend AnilAAI_SwitchIntelligence
end
