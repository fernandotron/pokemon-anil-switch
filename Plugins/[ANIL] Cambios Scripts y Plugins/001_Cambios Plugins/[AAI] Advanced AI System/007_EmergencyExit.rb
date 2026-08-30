#===============================================================================
# ANIL → AAI Compatibility — Emergency Exit (pivot Bicho)
#===============================================================================
return unless defined?(AdvancedAI)

module AnilAAI_EmergencyExitRole
  def score_role_synergy(move, user, target, skill)
    score = super
    return score unless move && user
    return score unless AnilAAI.emergency_exit_pivot_move?(user, move)
    return score unless AnilAAI.can_emergency_exit_pivot?(@battle, user)

    if target && AnilAAI.at_type_disadvantage?(user, target)
      score += 20
    end
    score += 10

    score
  end

  def score_choice_prelock(move, user, target)
    score = super
    return score unless move && user
    return score unless AnilAAI.emergency_exit_pivot_move?(user, move)
    return score unless AnilAAI.can_emergency_exit_pivot?(@battle, user)

    score + 25
  end
end

class Battle::AI
  prepend AnilAAI_EmergencyExitRole

  # Alias en clase (no prepend): super entraba en bucle con Debug_Replacement.rb.
  unless method_defined?(:anil_aai_orig_choose_best_replacement_pokemon)
    alias anil_aai_orig_choose_best_replacement_pokemon choose_best_replacement_pokemon
  end

  def choose_best_replacement_pokemon(idxBattler, terrible_moves = false)
    if AnilAAI.emergency_exit_switch_pending?(@battle, idxBattler)
      return AnilAAI.pick_forced_replacement(@battle, self, idxBattler)
    end
    anil_aai_orig_choose_best_replacement_pokemon(idxBattler, terrible_moves)
  end
end
