#===============================================================================
# ANIL → AAI Compatibility — CombatUtilities patches
#===============================================================================
return unless defined?(AdvancedAI)

module AnilAAI_CombatUtilities
  def resolve_move_type(user, move)
    type = super
    return type unless user && move

    if move.respond_to?(:soundMove?) && move.soundMove? &&
       AnilAAI.has_active_ability?(user, :TINTINEO) &&
       !AnilAAI.has_active_ability?(user, :LIQUIDVOICE) &&
       GameData::Type.exists?(:PSYCHIC)
      type = :PSYCHIC
    end

    base_type = move.type
    if base_type == :NORMAL
      if AnilAAI.has_active_ability?(user, :PIELMALDITA) && GameData::Type.exists?(:GHOST)
        type = :GHOST
      elsif AnilAAI.has_active_ability?(user, :PIELHERBACEA) && GameData::Type.exists?(:GRASS)
        type = :GRASS
      end
    end

    type
  end

  def defender_modifier(battle, target, is_physical)
    mod = super
    return mod unless target

    if target.respond_to?(:item_id) && target.item_id == :SUPEREVIOLITE &&
       AnilAAI.super_eviolite_active?(target.pokemon || target)
      mod *= 0.67
    end
    mod
  end
end

AdvancedAI::CombatUtilities.singleton_class.prepend(AnilAAI_CombatUtilities)
