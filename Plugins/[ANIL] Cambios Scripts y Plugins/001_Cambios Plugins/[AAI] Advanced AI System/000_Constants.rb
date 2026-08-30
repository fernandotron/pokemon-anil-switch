#===============================================================================
# ANIL → AAI Compatibility — Constants & shared helpers
#===============================================================================
return unless defined?(AdvancedAI)

module AnilAAI
  PLATE_DAMAGE_MULT = 1.25
  TYPE_ITEM_MULT    = 1.2
  AAI_PLATE_MULT    = 1.2   # Valor que usa AAI por defecto en placas
  PLATE_CORRECTION  = PLATE_DAMAGE_MULT / AAI_PLATE_MULT
  SOUND_POWER_BOOST = 1.2
  PINCH_HP_RATIO    = 1.0 / 3.0

  SLUSH_RUSH_ABILITIES = [:SLUSHRUSH, :PODERGELIDO].freeze

  PLATE_TYPES = {
    :FISTPLATE   => :FIGHTING, :SKYPLATE    => :FLYING,  :TOXICPLATE  => :POISON,
    :EARTHPLATE  => :GROUND,  :STONEPLATE  => :ROCK,    :INSECTPLATE => :BUG,
    :SPOOKYPLATE => :GHOST,    :IRONPLATE   => :STEEL,   :FLAMEPLATE  => :FIRE,
    :SPLASHPLATE => :WATER,   :MEADOWPLATE => :GRASS,   :ZAPPLATE    => :ELECTRIC,
    :MINDPLATE   => :PSYCHIC, :ICICLEPLATE => :ICE,     :DRACOPLATE  => :DRAGON,
    :DREADPLATE  => :DARK,    :PIXIEPLATE  => :FAIRY,   :BLANKPLATE  => :NORMAL
  }.freeze

  # Boosts ofensivos por tipo (DamageCalcFromUser en ANIL)
  TYPE_BOOST_ABILITIES = {
    :COLEOPTERO  => :BUG,
    :INFLAMABLE  => :FIRE,
    :ALBINISMO   => :ICE,
    :FLORACION   => :GRASS,
    :PODERGELIDO => :ICE
  }.freeze

  OFFENSIVE_ABILITIES = {
    :PODERSABIO  => 2.0,
    :COLEOPTERO  => 1.5,
    :INFLAMABLE  => 1.5,
    :ALBINISMO   => 1.5,
    :FLORACION   => 1.5,
    :REALEZA     => 1.5,
    :ACOMETIDA   => 1.5,
    :CAMORRISTA  => 1.2,
    :SOBRECARGA  => 1.5,
    :RIVALRY     => 1.2
  }.freeze

  SUPPORT_ABILITIES = {
    :ESPANTO         => 1.5,
    :TINTINEO        => 1.2,
    :ILLUMINATE      => 1.0,
    :EMERGENCYEXIT   => 1.5   # Pivot ofensivo con movimientos Bicho
  }.freeze

  EMERGENCY_EXIT_PIVOT_MIN_SKILL = 60

  def self.super_eviolite_active?(pokemon)
    return false if pokemon.nil?
    species_data = pokemon.species_data rescue nil
    return false unless species_data
    (species_data.get_evolutions(true).length > 1 rescue false)
  end

  def self.has_active_ability?(battler, ability_id)
    return false unless battler
    if battler.respond_to?(:hasActiveAbility?)
      battler.hasActiveAbility?(ability_id)
    elsif battler.respond_to?(:ability_id)
      battler.ability_id == ability_id
    else
      false
    end
  end

  def self.super_effective_against_bug?(move)
    return false unless move
    return true if move.respond_to?(:id) && move.id == :ATRAPAMOSCAS
    fc = move.function_code.to_s rescue ""
    fc == "SuperEffectiveAgainstBug"
  end

  def self.anil_effectiveness(move_type, defender_types, move)
    types = defender_types.compact
    return Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER if types.empty?
    return Effectiveness.calculate(move_type, *types) unless super_effective_against_bug?(move)

    mod = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    types.each do |def_type|
      single = if def_type == :BUG
                 Effectiveness::SUPER_EFFECTIVE_MULTIPLIER
               else
                 Effectiveness.calculate(move_type, def_type)
               end
      mod *= single
    end
    mod
  end

  def self.plate_correction(user, effective_type)
    return 1.0 unless user.respond_to?(:item_id) && user.item_id
    plate_type = PLATE_TYPES[user.item_id]
    return 1.0 unless plate_type && effective_type == plate_type
    PLATE_CORRECTION
  end

  def self.extra_damage_multiplier(move, user, target, battle)
    return 1.0 unless move && user && target

    mult = 1.0
    effective_type = AdvancedAI::CombatUtilities.resolve_move_type(user, move)

    # Pinch: Sobrecarga (eléctrico ≤ 33% HP)
    if has_active_ability?(user, :SOBRECARGA) &&
       user.hp <= user.totalhp * PINCH_HP_RATIO &&
       effective_type == :ELECTRIC
      mult *= 1.5
    end

    # Poder Gélido: hielo en granizo/nieve
    if has_active_ability?(user, :PODERGELIDO) && effective_type == :ICE && battle
      weather = battle.pbWeather rescue nil
      mult *= 1.5 if [:Hail, :Snowstorm, :Snow].include?(weather)
    end

    # Boosts por tipo
    TYPE_BOOST_ABILITIES.each do |ability, type|
      mult *= 1.5 if has_active_ability?(user, ability) && effective_type == type
    end

    # Poder Sabio: +50% especial
    mult *= 1.5 if has_active_ability?(user, :PODERSABIO) && move.specialMove?

    # Camorrista: +20% patadas
    if has_active_ability?(user, :CAMORRISTA) &&
       move.respond_to?(:kickingMove?) && move.kickingMove?
      mult *= 1.2
    end

    # Acometida: primer turno +30%
    if has_active_ability?(user, :ACOMETIDA) &&
       user.respond_to?(:turnCount) && user.turnCount.zero?
      mult *= 1.3
    end

    # Realeza: +50% si el movimiento no es STAB del usuario
    if has_active_ability?(user, :REALEZA) && user.respond_to?(:pbHasType?) &&
       !user.pbHasType?(effective_type)
      mult *= 1.5
    end

    # Silvano: +30% en hierba
    if has_active_ability?(user, :SILVANO) && battle &&
       (battle.field.terrain == :Grassy rescue false)
      mult *= 1.3
    end

    # Rivalidad: mismo género +25%
    if has_active_ability?(user, :RIVALRY) &&
       user.gender != 2 && target.gender != 2 && user.gender == target.gender
      mult *= 1.25
    end

    # Liquid Voice / Tintineo: powerBoost en sonido
    if move.respond_to?(:soundMove?) && move.soundMove?
      if has_active_ability?(user, :LIQUIDVOICE) || has_active_ability?(user, :TINTINEO)
        mult *= SOUND_POWER_BOOST
      end
    end

    mult *= plate_correction(user, effective_type)

    # Supermin. Evol.: +50% ataque si puede evolucionar 2 veces
    if user.respond_to?(:item_id) && user.item_id == :SUPEREVIOLITE &&
       super_eviolite_active?(user.pokemon || user)
      mult *= 1.5
    end

    mult
  end

  # Emergency Exit (ANIL): al usar un ataque Bicho, el usuario sale como U-turn.
  def self.emergency_exit_pivot_move?(user, move)
    return false unless user && move
    return false unless has_active_ability?(user, :EMERGENCYEXIT)
    return false unless move.damagingMove?

    effective_type = AdvancedAI::CombatUtilities.resolve_move_type(user, move)
    effective_type == :BUG
  end

  def self.can_emergency_exit_pivot?(battle, user)
    return false unless battle && user
    return false unless battle.pbCanSwitchOut?(user.index) rescue false
    return false unless battle.pbCanChooseNonActive?(user.index) rescue false
    true
  end

  def self.evaluate_emergency_exit_pivot(battle, user, move, target, skill)
    return 0 if skill < EMERGENCY_EXIT_PIVOT_MIN_SKILL
    return 0 unless emergency_exit_pivot_move?(user, move)
    return 0 unless can_emergency_exit_pivot?(battle, user)

    AdvancedAI::PivotMoves.evaluate_offensive_pivot(battle, user, move, target, skill)
  end

  def self.at_type_disadvantage?(user, target)
    return false unless user && target

    target_types = target.pbTypes(true).compact rescue []
    user_types = user.pbTypes(true).compact rescue []
    return false if target_types.empty? || user_types.empty?

    target_types.any? do |type|
      Effectiveness.super_effective?(Effectiveness.calculate(type, *user_types))
    end
  end

  # Contexto de pbGetReplacementPokemonIndex tras un pivot Bicho de Emergency Exit.
  def self.emergency_exit_switch_pending?(battle, idxBattler)
    return false unless battle && idxBattler

    battler = battle.battlers[idxBattler]
    return false unless battler && has_active_ability?(battler, :EMERGENCYEXIT)

    last_id = battler.lastRegularMoveUsed || battler.lastMoveUsed
    return false unless last_id

    move_data = GameData::Move.try_get(last_id)
    return false unless move_data
    return false if move_data.category == 2   # Status

    begin
      move = Battle::Move.from_pokemon_move(battle, Pokemon::Move.new(last_id))
      return false unless move.damagingMove?

      effective_type = if defined?(AdvancedAI)
                         AdvancedAI::CombatUtilities.resolve_move_type(battler, move)
                       else
                         move_data.type
                       end
      effective_type == :BUG
    rescue
      move_data.type == :BUG
    end
  end

  # Selección forzada de reemplazo (sin anti-ping-pong de AAI).
  def self.pick_forced_replacement(battle, ai, idxBattler)
    return -1 unless battle && ai

    skill = if ai.trainer
              (ai.trainer.instance_variable_get(:@aai_skill_override) rescue nil) || ai.trainer.skill
            elsif battle.wildBattle?
              (AdvancedAI::WILD_POKEMON_SKILL_LEVEL rescue 50)
            else
              100
            end

    if defined?(AdvancedAI) && AdvancedAI.qualifies_for_advanced_ai?(skill) &&
       AdvancedAI.feature_enabled?(:switch_intelligence, skill) && ai.user
      begin
        best_idx = ai.send(:find_best_switch_advanced, ai.user, skill, true)
        return best_idx if best_idx && battle.pbCanSwitchIn?(idxBattler, best_idx)
      rescue => e
        AdvancedAI.log("Emergency Exit replacement: #{e.message}", "AnilAAI") if AdvancedAI.respond_to?(:log)
      end
    end

    if ai.respond_to?(:aai_choose_best_replacement_pokemon, true)
      idx = ai.aai_choose_best_replacement_pokemon(idxBattler, true)
      return idx if idx >= 0
    end

    party = battle.pbParty(idxBattler)
    party.each_with_index do |pkmn, i|
      next unless pkmn && !pkmn.fainted?
      return i if battle.pbCanSwitchIn?(idxBattler, i)
    end
    -1
  end

  def self.has_emergency_exit_bug_pivot?(battle, user)
    return false unless battle && user
    return false unless has_active_ability?(user, :EMERGENCYEXIT)
    return false unless can_emergency_exit_pivot?(battle, user)

    user.moves.any? { |m| m && emergency_exit_pivot_move?(user, m) }
  end

  def self.effectiveness_damage_ratio(move, user, target)
    return 1.0 unless super_effective_against_bug?(move) && target.respond_to?(:pbTypes)
    effective_type = AdvancedAI::CombatUtilities.resolve_move_type(user, move)
    wrong = Effectiveness.calculate(effective_type, *target.pbTypes(true))
    right = anil_effectiveness(effective_type, target.pbTypes(true), move)
    return 1.0 if wrong <= 0
    right.to_f / wrong
  end
end
