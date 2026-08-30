
# #===============================================================================
# # Cable Club RNG Synchronization Fixes for Move Effects
# # 
# # This file contains aliases to fix RNG desynchronization issues in online
# # battles by ensuring all random number generation uses the synchronized
# # battleRNG instead of global rand() calls.
# #===============================================================================

# #===============================================================================
# # Fix for move category determination when physical and special damage are equal
# #===============================================================================
# class Battle::Move::CategoryDependsOnHigherDamagePoisonTarget < Battle::Move::PoisonTarget
#   alias_method :pbOnStartUse_original, :pbOnStartUse
  
#   def pbOnStartUse(user, targets)
#     # Only apply fix for Cable Club battles
#     if @battle.is_a?(Battle_CableClub)
#       target = targets[0]
#       return if !target
#       max_stage = Battle::Battler::STAT_STAGE_MAXIMUM
#       stageMul = Battle::Battler::STAT_STAGE_MULTIPLIERS
#       stageDiv = Battle::Battler::STAT_STAGE_DIVISORS
      
#       # Calculate user's effective attacking values
#       attack_stage         = user.stages[:ATTACK] + max_stage
#       real_attack          = (user.attack.to_f * stageMul[attack_stage] / stageDiv[attack_stage]).floor
#       special_attack_stage = user.stages[:SPECIAL_ATTACK] + max_stage
#       real_special_attack  = (user.spatk.to_f * stageMul[special_attack_stage] / stageDiv[special_attack_stage]).floor
      
#       # Calculate target's effective defending values
#       defense_stage         = target.stages[:DEFENSE] + max_stage
#       real_defense          = (target.defense.to_f * stageMul[defense_stage] / stageDiv[defense_stage]).floor
#       special_defense_stage = target.stages[:SPECIAL_DEFENSE] + max_stage
#       real_special_defense  = (target.spdef.to_f * stageMul[special_defense_stage] / stageDiv[special_defense_stage]).floor
      
#       # Perform simple damage calculation
#       physical_damage = real_attack.to_f / real_defense
#       special_damage = real_special_attack.to_f / real_special_defense
      
#       # Determine move's category - FIXED: Always use synchronized RNG
#       if physical_damage == special_damage
#         @calcCategory = @battle.pbRandom(2)
#       else
#         @calcCategory = (physical_damage > special_damage) ? 0 : 1
#       end
#     else
#       # Use original method for non-Cable Club battles
#       pbOnStartUse_original(user, targets)
#     end
#   end
# end

# #===============================================================================
# # Fix damage variation calculation to use deterministic method in Cable Club
# #===============================================================================
class Battle::Move
  alias_method :pbCalcDamage_original, :pbCalcDamage if !method_defined?(:pbCalcDamage_original)
  alias_method :pbOnStartUse_move_original, :pbOnStartUse if !method_defined?(:pbOnStartUse_move_original)
  
  def pbOnStartUse(user, targets)
    # Reset hit counter at the start of each move for Cable Club battles
    if @battle.is_a?(Battle_CableClub)
      @battle.cable_hit_counter = 0
    end
    
    # Call original method
    pbOnStartUse_move_original(user, targets)
  end
  
#   def pbCalcDamage(user, target, numTargets = 1)
#     # For Cable Club battles, we need to ensure damage variation is deterministic
#     if @battle.is_a?(Battle_CableClub)
#       # Store original pbRandom method
#       original_pbRandom = @battle.method(:pbRandom)
      
#       # Initialize hit counter if it doesn't exist
#       @battle.cable_hit_counter = 0 if !@battle.respond_to?(:cable_hit_counter) || @battle.cable_hit_counter.nil?
      
#       # Create a deterministic random value based on turn and move data
#       # Use a combination of factors that are identical on both clients
#       seed_factors = [
#         @battle.turnCount,
#         user.index,
#         target.index,
#         @id.to_s.sum,  # Move ID as string sum
#         @battle.cable_hit_counter  # Include hit number for multi-hit moves
#       ]
#       deterministic_seed = seed_factors.sum % 16
      
#       # Temporarily override pbRandom for damage variation
#       @battle.define_singleton_method(:pbRandom) do |max|
#         if max == 16  # This is the damage variation call
#           return deterministic_seed
#         else
#           return original_pbRandom.call(max)
#         end
#       end
      
#       # Call original damage calculation
#       result = pbCalcDamage_original(user, target, numTargets)
      
#       # Increment hit counter for deterministic multi-hit variation
#       @battle.cable_hit_counter += 1
      
#       # Restore original pbRandom method
#       @battle.define_singleton_method(:pbRandom, original_pbRandom)
      
#       return result
#     else
#       # Use original method for non-Cable Club battles
#       return pbCalcDamage_original(user, target, numTargets)
#     end
#   end
end

# #===============================================================================
# # Fix damage variation calculation for Deluxe Battle Kit version
# #===============================================================================
# class Battle::Move
#   alias_method :pbCalcDamageMults_Random_original, :pbCalcDamageMults_Random if method_defined?(:pbCalcDamageMults_Random) && !method_defined?(:pbCalcDamageMults_Random_original)
  
#   def pbCalcDamageMults_Random(user, target, numTargets, type, baseDmg, multipliers)
#     # For Cable Club battles, use deterministic damage variation
#     if @battle.is_a?(Battle_CableClub)
#       # Critical hits
#       if target.damageState.critical
#         if Settings::NEW_CRITICAL_HIT_RATE_MECHANICS
#           multipliers[:final_damage_multiplier] *= 1.5
#         else
#           multipliers[:final_damage_multiplier] *= 2
#         end
#       end
#       # Random variance - FIXED: Use deterministic calculation
#       if !self.is_a?(Battle::Move::Confusion)
#         # Initialize hit counter if it doesn't exist
#         @battle.cable_hit_counter = 0 if !@battle.respond_to?(:cable_hit_counter) || @battle.cable_hit_counter.nil?
        
#         # Create deterministic random value based on battle state
#         seed_factors = [
#           @battle.turnCount,
#           user.index,
#           target.index,
#           @id.to_s.sum,
#           @battle.cable_hit_counter  # Include hit number for multi-hit moves
#         ]
#         deterministic_random = (seed_factors.sum % 16)
#         random = 85 + deterministic_random
#         multipliers[:final_damage_multiplier] *= random / 100.0
        
#         # Increment hit counter for deterministic multi-hit variation
#         @battle.cable_hit_counter += 1
#       end
#     else
#       # Use original method for non-Cable Club battles
#       pbCalcDamageMults_Random_original(user, target, numTargets, type, baseDmg, multipliers) if respond_to?(:pbCalcDamageMults_Random_original)
#     end
#   end
# end

#===============================================================================
# Add hit counter accessor to Battle_CableClub
#===============================================================================
class Battle_CableClub
  attr_accessor :cable_hit_counter
end

#===============================================================================
# Fix for multi-hit moves with Loaded Dice item
#===============================================================================
class Battle::Move::HitTwoToFiveTimesOrThreeForAshGreninja < Battle::Move::HitTwoToFiveTimes
  alias_method :pbNumHits_original, :pbNumHits
  
  def pbNumHits(user, targets)
    # Only apply fix for Cable Club battles with Loaded Dice
    if @battle.is_a?(Battle_CableClub) && user.hasActiveItem?(:LOADEDDICE)
      return 4 + @battle.pbRandom(2)
    else
      return pbNumHits_original(user, targets)
    end
  end
end

class Battle::Move::HitTenTimes < Battle::Move
  alias_method :pbNumHits_original, :pbNumHits
  
  def pbNumHits(user, targets)
    # Only apply fix for Cable Club battles with Loaded Dice
    if @battle.is_a?(Battle_CableClub) && user.hasActiveItem?(:LOADEDDICE)
      return 4 + @battle.pbRandom(7)
    else
      return pbNumHits_original(user, targets)
    end
  end
end

# #===============================================================================
# # Fix for any other move category determination issues
# #===============================================================================
# class Battle::Move::CategoryDependsOnHigherDamageIgnoreTargetAbility < Battle::Move::IgnoreTargetAbility
#   alias_method :pbOnStartUse_original, :pbOnStartUse
  
#   def pbOnStartUse(user, targets)
#     # Only apply fix for Cable Club battles
#     if @battle.is_a?(Battle_CableClub)
#       # Calculate user's effective attacking value
#       max_stage = Battle::Battler::STAT_STAGE_MAXIMUM
#       stageMul = Battle::Battler::STAT_STAGE_MULTIPLIERS
#       stageDiv = Battle::Battler::STAT_STAGE_DIVISORS
#       atk        = user.attack
#       atkStage   = user.stages[:ATTACK] + max_stage
#       realAtk    = (atk * stageMul[atkStage] / stageDiv[atkStage]).floor
#       spAtk      = user.spatk
#       spAtkStage = user.stages[:SPECIAL_ATTACK] + max_stage
#       realSpAtk  = (spAtk * stageMul[spAtkStage] / stageDiv[spAtkStage]).floor
      
#       # Determine move's category
#       @calcCategory = (realAtk > realSpAtk) ? 0 : 1
      
#       if @battle.moldBreaker && targets[0].hasActiveItem?(:ABILITYSHIELD)
#         @battle.moldBreaker = false
#       end
#     else
#       # Use original method for non-Cable Club battles
#       pbOnStartUse_original(user, targets)
#     end
#   end
# end
# =end