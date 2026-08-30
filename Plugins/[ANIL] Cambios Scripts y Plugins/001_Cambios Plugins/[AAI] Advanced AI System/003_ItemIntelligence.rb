#===============================================================================
# ANIL → AAI Compatibility — ItemIntelligence patches
#===============================================================================
return unless defined?(AdvancedAI)

module AdvancedAI
  module ItemIntelligence
    unless const_defined?(:ANIL_PATCHED)
      ANIL_PATCHED = true
      DEFENSIVE_ITEMS[:SUPEREVIOLITE] = { stat: :both, multiplier: 1.5, super_nfe: true }
      PLATE_ITEMS << :BLANKPLATE unless PLATE_ITEMS.include?(:BLANKPLATE)
    end
  end
end

module AnilAAI_ItemIntelligence
  def calculate_item_multiplier(battler, move)
    mult = super
    return mult unless battler && move

    item = battler.item_id
    return mult unless item

    resolved_type = AdvancedAI::CombatUtilities.resolve_move_type(battler, move)

    if AnilAAI::PLATE_TYPES.key?(item) && resolved_type == AnilAAI::PLATE_TYPES[item]
      mult *= AnilAAI::PLATE_CORRECTION
    end

    mult
  end

  def get_item_threat_modifier(battler)
    mod = super
    return mod unless battler&.item_id == :SUPEREVIOLITE
    return mod unless AnilAAI.super_eviolite_active?(battler.pokemon || battler)

    mod + 0.6
  end
end

AdvancedAI::ItemIntelligence.singleton_class.prepend(AnilAAI_ItemIntelligence)
