#===============================================================================
# ANIL → AAI Compatibility — Speed & weather (Poder Gélido)
#===============================================================================
return unless defined?(AdvancedAI)

module AnilAAI_SpeedTiers
  def calculate_effective_speed(battle, battler)
    speed = super
    return speed unless battler && battle

    effective_weather = AdvancedAI::Utilities.current_weather(battle)
    if AnilAAI.has_active_ability?(battler, :PODERGELIDO) &&
       [:Hail, :Snow].include?(effective_weather)
      speed *= 2
    end

    speed
  end
end

AdvancedAI::SpeedTiers.singleton_class.prepend(AnilAAI_SpeedTiers)

module AnilAAI_CustomContentWeather
  def benefits_from_weather?(battler, weather)
    return true if super
    return false unless battler && weather

    if [:Hail, :Snow].include?(weather)
      return AnilAAI::SLUSH_RUSH_ABILITIES.any? { |a| AnilAAI.has_active_ability?(battler, a) }
    end
    false
  end
end

AdvancedAI::CustomContent.singleton_class.prepend(AnilAAI_CustomContentWeather)
