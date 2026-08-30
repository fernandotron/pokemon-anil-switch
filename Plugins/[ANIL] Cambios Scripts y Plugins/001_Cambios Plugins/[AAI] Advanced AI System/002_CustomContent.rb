#===============================================================================
# ANIL → AAI Compatibility — CustomContent ability tables & damage mods
#===============================================================================
return unless defined?(AdvancedAI)

module AdvancedAI
  module CustomContent
    OFFENSIVE_ABILITIES.merge!(AnilAAI::OFFENSIVE_ABILITIES)
    SUPPORT_ABILITIES.merge!(AnilAAI::SUPPORT_ABILITIES)
    SPEED_ABILITIES[:PODERGELIDO] = 2.0
  end
end

module AnilAAI_CustomContent
  def calculate_ability_damage_modifier(attacker, target, move, battle)
    mod = super
    return mod unless attacker && target && move

    effective_type = AdvancedAI::CombatUtilities.resolve_move_type(attacker, move)

    if AnilAAI.has_active_ability?(attacker, :SOBRECARGA) &&
       attacker.hp <= attacker.totalhp * AnilAAI::PINCH_HP_RATIO &&
       effective_type == :ELECTRIC
      mod *= 1.5
    end

    if AnilAAI.has_active_ability?(attacker, :PODERSABIO) && move.specialMove?
      mod *= 1.5
    end

    if AnilAAI.has_active_ability?(attacker, :CAMORRISTA) &&
       move.respond_to?(:kickingMove?) && move.kickingMove?
      mod *= 1.2
    end

    if AnilAAI.has_active_ability?(attacker, :ACOMETIDA) &&
       attacker.respond_to?(:turnCount) && attacker.turnCount.zero?
      mod *= 1.3
    end

    AnilAAI::TYPE_BOOST_ABILITIES.each do |ability, type|
      mod *= 1.5 if AnilAAI.has_active_ability?(attacker, ability) && effective_type == type
    end

    if AnilAAI.has_active_ability?(attacker, :REALEZA) &&
       attacker.respond_to?(:pbHasType?) && !attacker.pbHasType?(effective_type)
      mod *= 1.5
    end

    if AnilAAI.has_active_ability?(attacker, :SILVANO) && battle &&
       (battle.field.terrain == :Grassy rescue false)
      mod *= 1.3
    end

    if AnilAAI.has_active_ability?(attacker, :RIVALRY) &&
       attacker.gender != 2 && target.gender != 2 && attacker.gender == target.gender
      mod *= 1.25
    end

    if move.respond_to?(:soundMove?) && move.soundMove?
      if AnilAAI.has_active_ability?(attacker, :LIQUIDVOICE) ||
         AnilAAI.has_active_ability?(attacker, :TINTINEO)
        mod *= AnilAAI::SOUND_POWER_BOOST
      end
    end

    if AnilAAI.has_active_ability?(attacker, :PODERGELIDO) && effective_type == :ICE && battle
      weather = battle.pbWeather rescue nil
      mod *= 1.5 if [:Hail, :Snowstorm, :Snow].include?(weather)
    end

    mod
  end
end

AdvancedAI::CustomContent.singleton_class.prepend(AnilAAI_CustomContent)
