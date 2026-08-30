#===============================================================================
# Advanced AI System - Advanced Ability Awareness
# Handles complex ability interactions and strategic implications
#===============================================================================

module AdvancedAI
  # Ability threat multipliers for strategic awareness
  SNOWBALL_ABILITIES = {
    :MOXIE         => 1.8,  # +1 Atk on KO - snowball threat
    :BEASTBOOST    => 1.8,  # +1 highest stat on KO
    :SOULDEVOURING => 1.8,  # +1 all stats on KO (custom)
    :CHILLINGNEIGH => 1.7,  # +1 Atk on KO (Ice)
    :GRIMNEIGH     => 1.7,  # +1 SpAtk on KO (Dark)
    :ASONEGLASTRIER => 1.9, # Unnerve + Chilling Neigh (+1 Atk on KO)
    :ASONESPECTRIER => 1.9, # Unnerve + Grim Neigh (+1 SpAtk on KO)
    :POWEROFALCHEMY => 1.5,  # Copies fainted ally's ability (could gain Moxie/Speed Boost)
    :RECEIVER       => 1.5,  # Same as Power of Alchemy (doubles variant)
  }
  
  SPEED_SHIFT_ABILITIES = {
    :UNBURDEN      => 2.5,  # 2x Speed after item consumed - MASSIVE threat
    :SLOWSTART     => 0.3,  # Half Atk/Speed for 5 turns - weakling
    :SPEEDBOOST    => 1.6,  # +1 Speed per turn
  }
  
  REVERSE_ABILITIES = {
    :CONTRARY      => 2.0,  # Inverts stat changes (Leaf Storm = +2 SpAtk)
    :DEFIANT       => 1.7,  # +2 Atk when stat lowered
    :COMPETITIVE   => 1.7,  # +2 SpAtk when stat lowered
  }
  
  SWITCH_ABILITIES = {
    :REGENERATOR   => 1.4,  # Heals 33% on switch-out - free recovery
    :NATURALCURE   => 1.3,  # Cures status on switch-out
    :SHEDSKIN      => 1.2,  # 33% chance to cure status per turn
  }
end

class Battle::AI
  # ============================================================================
  # SNOWBALL THREAT DETECTION (Moxie, Beast Boost)
  # ============================================================================
  
  alias advanced_abilities_pbRegisterMove pbRegisterMove
  def pbRegisterMove(user, move)
    score = advanced_abilities_pbRegisterMove(user, move)
    
    return score unless user && move
    
    # Check all targets for snowball abilities
    @battle.allOtherSideBattlers(user.index).each do |target|
      next unless target && !target.fainted?
      
      # SNOWBALL ABILITIES: Don't feed kills to Moxie/Beast Boost users
      snowball_key = AdvancedAI::SNOWBALL_ABILITIES.keys.find { |a| target.hasActiveAbility?(a) }
      if snowball_key
        score += evaluate_snowball_threat(user, move, target)
      end
      
      # REVERSE ABILITIES: Stat drops = stat boosts!
      reverse_key = AdvancedAI::REVERSE_ABILITIES.keys.find { |a| target.hasActiveAbility?(a) }
      if reverse_key
        score += evaluate_reverse_ability(user, move, target)
      end
      
      # SPEED SHIFT: Unburden activation warning
      if target.hasActiveAbility?(:UNBURDEN) && target.item
        score += evaluate_unburden_threat(user, move, target)
      end
    end
    
    # REGENERATOR: Penalty for forcing switch (they get free 33% heal)
    if ["SwitchOutTargetStatusMove", "SwitchOutTargetDamagingMove"].include?(move.function_code)
      # In doubles, only penalize once for the actual target (not all opponents)
      target_battler = @battle.allOtherSideBattlers(user.index).first
      if target_battler && target_battler.hasActiveAbility?(:REGENERATOR)
        score -= 15  # Penalty - they get free 33% heal
        AdvancedAI.log("  #{move.name} vs Regenerator: -15 (free heal on force-out)", "Abilities")
      end
    end
    
    return score
  end
  
  # Evaluate Moxie/Beast Boost snowball threat
  def evaluate_snowball_threat(user, move, target)
    return 0 unless move.damagingMove?
    
    score = 0
    ability_name = ""
    AdvancedAI::SNOWBALL_ABILITIES.each do |ab, _|
      if target.hasActiveAbility?(ab)
        ability_name = GameData::Ability.try_get(ab)&.name || ab.to_s
        break
      end
    end
    
    # Check if this move would KO the target
    rough_damage = AdvancedAI::CombatUtilities.estimate_damage(user, move, target, as_percent: true)
    would_ko = (rough_damage >= target.hp.to_f / target.totalhp)
    
    if would_ko
      # KOing Moxie/Beast Boost user is GOOD (prevent snowball)
      score += 30
      AdvancedAI.log("  KO #{target.name} (#{ability_name}): +30 (prevent snowball)", "Abilities")
    else
      # DON'T leave them at low HP for easy snowball
      hp_percent = target.hp.to_f / target.totalhp
      if hp_percent < 0.35 && rough_damage > 0.2
        score -= 20  # They can easily KO us next turn and get +1
        AdvancedAI.log("  Damage to #{ability_name}: -20 (sets up snowball)", "Abilities")
      end
    end
    
    # If they already have +1 or more, URGENT to KO
    if target.stages[:ATTACK] >= 1 || target.stages[:SPECIAL_ATTACK] >= 1
      score += 25
      AdvancedAI.log("  #{ability_name} already boosted: +25 (stop snowball)", "Abilities")
    end
    
    return score
  end
  
  # Evaluate Contrary/Defiant/Competitive
  def evaluate_reverse_ability(user, move, target)
    score = 0
    ability_id = AdvancedAI::REVERSE_ABILITIES.keys.find { |a| target.hasActiveAbility?(a) }
    
    case ability_id
    when :CONTRARY
      # DON'T use stat-lowering moves on Contrary users (they become buffs!)
      # This includes both status moves AND damaging moves with stat-drop effects
      # (e.g., Snarl, Icy Wind, Moonblast, Psychic)
      # Check if move lowers target's stats (function_code is a CamelCase string)
      # Exclude LowerTargetHP (Endeavor) — it equalizes HP, doesn't lower stats
      stat_drops = move.function_code.include?("LowerTarget") &&
                   !move.function_code.include?("LowerTargetHP")
      
      if stat_drops
        score -= 50  # NEVER do this
        AdvancedAI.log("  #{move.name} vs Contrary: -50 (inverts to buff!)", "Abilities")
      end
      
      # Contrary users love Leaf Storm, Draco Meteor, Overheat (self-drops = boosts)
      # Prioritize KOing them
      if move.damagingMove?
        score += 15
        AdvancedAI.log("  Damage to Contrary: +15 (prevent reverse setup)", "Abilities")
      end
      
    when :DEFIANT, :COMPETITIVE
      # DON'T use Intimidate switch-ins or stat-lowering moves
      # Includes damaging moves with stat-drop effects (Snarl, Icy Wind, etc.)
      # Exclude LowerTargetHP (Endeavor) — it equalizes HP, doesn't lower stats
      stat_drops = move.function_code.include?("LowerTarget") &&
                   !move.function_code.include?("LowerTargetHP")
      if stat_drops
        score -= 40  # They get +2 Atk/SpAtk!
        AdvancedAI.log("  #{move.name} vs #{ability_id}: -40 (triggers +2)", "Abilities")
      end
      
      # NOTE: Intimidate+Baton Pass interaction removed — Intimidate triggers on
      # SWITCH-IN, not switch-out. The user's own Intimidate is irrelevant here.
    end
    
    return score
  end
  
  # Evaluate Unburden threat
  def evaluate_unburden_threat(user, move, target)
    return 0 unless target.item  # No item = no threat
    
    score = 0
    
    # If move removes item (Knock Off, Thief, Covet)
    if ["RemoveTargetItem", "UserTakesTargetItem"].include?(move.function_code)
      score -= 35  # DON'T trigger Unburden unless KO
      AdvancedAI.log("  #{move.name} vs Unburden: -35 (doubles speed!)", "Abilities")
      
      # Unless it KOs
      rough_damage = AdvancedAI::CombatUtilities.estimate_damage(user, move, target, as_percent: true)
      if rough_damage >= target.hp.to_f / target.totalhp
        score += 50  # KO is fine
        AdvancedAI.log("  But KOs: +50 (worth it)", "Abilities")
      end
    end
    
    # Warn if target has consumable item (Berry) that could trigger Unburden
    consumable_items = [:SITRUSBERRY, :LUMBERRY, :ORANBERRY, :AGUAVBERRY, 
                       :FIGYBERRY, :IAPAPABERRY, :MAGOBERRY, :WIKIBERRY]
    if consumable_items.include?(target.item_id)
      score -= 10  # Might trigger via damage
      AdvancedAI.log("  Unburden + Berry: -10 (might auto-trigger)", "Abilities")
    end
    
    return score
  end
  
  # ============================================================================
  # REGENERATOR SWITCH PREDICTION
  # ============================================================================
  
  def predict_regenerator_switch(target)
    return false unless target.hasActiveAbility?(:REGENERATOR)
    
    hp_percent = target.hp.to_f / target.totalhp
    
    # Regenerator users switch out at 40-60% HP for free recovery
    if hp_percent < 0.6 && hp_percent > 0.2
      AdvancedAI.log("  Regenerator switch predicted (#{(hp_percent * 100).to_i}% HP)", "Abilities")
      return true
    end
    
    return false
  end
  
  # ============================================================================
  # ABILITY-BASED THREAT ASSESSMENT
  # ============================================================================
  
  def calculate_ability_threat_modifier(battler)
    return 1.0 unless battler
    
    multiplier = 1.0
    
    # Snowball abilities
    snowball_key = AdvancedAI::SNOWBALL_ABILITIES.keys.find { |a| battler.hasActiveAbility?(a) }
    if snowball_key
      base = AdvancedAI::SNOWBALL_ABILITIES[snowball_key]
      # Higher if already boosted
      if battler.stages[:ATTACK] >= 1 || battler.stages[:SPECIAL_ATTACK] >= 1
        multiplier = base * 1.3
      else
        multiplier = base
      end
    end
    
    # Speed shift abilities
    speed_key = AdvancedAI::SPEED_SHIFT_ABILITIES.keys.find { |a| battler.hasActiveAbility?(a) }
    if speed_key
      multiplier = AdvancedAI::SPEED_SHIFT_ABILITIES[speed_key]
      
      # Unburden: Only threat if item consumed
      if speed_key == :UNBURDEN && battler.item
        multiplier = 1.0  # Not active yet
      elsif speed_key == :UNBURDEN && !battler.item
        multiplier = 2.5  # ACTIVE - extreme threat
      end
    end
    
    # Reverse abilities
    reverse_key = AdvancedAI::REVERSE_ABILITIES.keys.find { |a| battler.hasActiveAbility?(a) }
    if reverse_key
      multiplier = AdvancedAI::REVERSE_ABILITIES[reverse_key]
    end
    
    # Switch abilities
    switch_key = AdvancedAI::SWITCH_ABILITIES.keys.find { |a| battler.hasActiveAbility?(a) }
    if switch_key
      multiplier = AdvancedAI::SWITCH_ABILITIES[switch_key]
    end
    
    return multiplier
  end
  
  # ============================================================================
  # GEN 9: Zero to Hero / Costar / Hospitality switch-in awareness
  # Used by switch evaluators to bias bringing these mons in.
  # ============================================================================
  def gen9_switchin_bonus(pkmn)
    return 0 unless pkmn
    bonus = 0
    begin
      ab = pkmn.respond_to?(:ability_id) ? pkmn.ability_id : (pkmn.ability rescue nil)
      ab = ab.id if ab.is_a?(GameData::Ability)
      
      case ab
      when :ZEROTOHERO
        # Palafin: switching out and back in flips to Hero form (huge stat boost).
        # Massive value when this is its second switch-in.
        bonus += 60
      when :ORICHALCUMPULSE
        bonus += 25  # Sets Sun + 1.33x physical
      when :HADRONENGINE
        bonus += 25  # Sets Electric Terrain + 1.33x special
      when :PROTOSYNTHESIS, :QUARKDRIVE
        # Booster Energy active = guaranteed boost on switch-in
        if pkmn.respond_to?(:item_id) && pkmn.item_id == :BOOSTERENERGY
          bonus += 30
        end
        # Auto-active via weather/terrain (no item needed)
        if @battle
          begin
            wx      = (@battle.field.weather rescue :None)
            terrain = (@battle.field.terrain rescue :None)
            if (ab == :PROTOSYNTHESIS && wx == :Sun) ||
               (ab == :QUARKDRIVE     && terrain == :Electric)
              bonus += 20
            end
          rescue
          end
        end
      when :GRIMNEIGH, :CHILLINGNEIGH
        bonus += 5  # Ready to snowball if it KOs
      when :REGENERATOR
        bonus += 10  # Comes in healthier on subsequent switches
      when :INTIMIDATE
        bonus += 15  # Free -1 Atk on opponent
      when :GOODASGOLD
        bonus += 15  # Status immunity is hugely valuable defensively
      when :PURIFYINGSALT
        bonus += 15  # Status immunity + Ghost resistance
      when :ICESCALES
        bonus += 20  # Halves all special damage — premier special wall
      when :FURCOAT
        bonus += 18  # Halves all physical damage
      when :THERMALEXCHANGE
        bonus += 12  # Burn immunity + Atk boost on Fire hits
      when :GUARDDOG
        bonus += 10  # Intimidate immunity + can't be phazed
      when :WINDPOWER
        # Charge effect on wind hits — minor pre-emptive value
        bonus += 5
      when :CUDCHEW
        # If holding a berry, will recycle it next turn → effectively two uses
        if pkmn.respond_to?(:item_id) && pkmn.item_id
          item_data = (GameData::Item.try_get(pkmn.item_id) rescue nil)
          if item_data && item_data.is_berry?
            bonus += 12
          end
        end
      when :ARMORTAIL, :DAZZLING, :QUEENLYMAJESTY
        bonus += 8  # Priority immunity (vs. Sucker Punch / Fake Out / etc.)
      when :MIRRORARMOR
        bonus += 8  # Reflects stat drops back (Intimidate / etc.)
      when :EMBODYASPECT_TEAL, :EMBODYASPECT_HEARTHFLAME, :EMBODYASPECT_WELLSPRING, :EMBODYASPECT_CORNERSTONE
        # Ogerpon masks: free +1 stat on switch-in (Speed/Atk/SpDef/Def respectively)
        bonus += 20
      when :SUPERSWEETSYRUP
        # Dipplin/Hydrapple line: -1 evasion on opponents on first switch-in
        bonus += 10
      when :OPPORTUNIST
        # Copies opponent boosts when they happen — minor switch bias if opponent has setup moves
        bonus += 5
      when :COSTAR
        # Doubles-only: copies ally stat changes on switch-in
        if @battle && @user
          begin
            user_side = @user.idxOwnSide rescue (@user.index & 1)
            @battle.battlers.each do |a|
              next unless a && !a.fainted?
              a_side = a.idxOwnSide rescue (a.index & 1)
              next if a_side != user_side
              next if a.index == @user.index
              total = 0
              [:ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED, :ACCURACY, :EVASION].each do |st|
                stage = (a.stages[st] rescue 0)
                total += stage if stage > 0
              end
              bonus += total * 8  # Each copied positive stage ~ +8 score
            end
          rescue
          end
        else
          bonus += 5
        end
      when :HOSPITALITY
        # Doubles-only: heal ally 25% on switch-in
        if @battle && @user
          begin
            user_side = @user.idxOwnSide rescue (@user.index & 1)
            @battle.battlers.each do |a|
              next unless a && !a.fainted?
              a_side = a.idxOwnSide rescue (a.index & 1)
              next if a_side != user_side
              next if a.index == @user.index
              hp_missing = 1.0 - (a.hp.to_f / [a.totalhp, 1].max)
              bonus += (hp_missing * 30).to_i  # Up to +30 if ally is at 0%
            end
          rescue
          end
        else
          bonus += 5
        end
      when :COMMANDER
        # Tatsugiri: massive boosts when Dondozo is on field as ally
        if @battle && @user
          begin
            user_side = @user.idxOwnSide rescue (@user.index & 1)
            has_dondozo_ally = @battle.battlers.any? do |b|
              next false unless b && !b.fainted?
              b_side = b.idxOwnSide rescue (b.index & 1)
              b_side == user_side && b.index != @user.index && b.isSpecies?(:DONDOZO)
            end
            bonus += 50 if has_dondozo_ally  # +2 to ALL stats on Dondozo is huge
          rescue
          end
        end
      end
      
      # === Iron Ball penalty: halves Speed + grounds the holder ===
      # Bad on a fast attacker, neutral on a Trick-Room mon, situationally good
      # if user wants to be grounded for Earthquake immunity reasons (rare).
      if pkmn.respond_to?(:item_id) && pkmn.item_id == :IRONBALL
        spd = (pkmn.respond_to?(:speed) ? pkmn.speed : (pkmn.calcStats[:SPEED] rescue 0))
        if @battle && (@battle.field.effects[PBEffects::TrickRoom] > 0 rescue false)
          bonus += 10  # Halved Speed is good in Trick Room
        elsif spd >= 90
          bonus -= 20  # Crippling on fast attackers
        else
          bonus -= 5   # Mild penalty otherwise
        end
        # Extra penalty if Flying-type / Levitate (Iron Ball negates immunity)
        types = (pkmn.types rescue [])
        ab = pkmn.respond_to?(:ability_id) ? pkmn.ability_id : nil
        if types.include?(:FLYING) || ab == :LEVITATE
          bonus -= 15  # Loses Ground immunity
        end
      end
    rescue
    end
    return bonus
  end
end

AdvancedAI.log("Advanced Abilities System loaded", "Core")
AdvancedAI.log("  - Snowball detection (Moxie, Beast Boost)", "Abilities")
AdvancedAI.log("  - Gen 9 switch-in awareness (Zero to Hero, Booster Energy paradoxes)", "Abilities")
AdvancedAI.log("  - Reverse abilities (Contrary, Defiant, Competitive)", "Abilities")
AdvancedAI.log("  - Speed shift (Unburden, Speed Boost)", "Abilities")
AdvancedAI.log("  - Switch abilities (Regenerator, Natural Cure)", "Abilities")
