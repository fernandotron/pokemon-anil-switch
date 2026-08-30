#-------------------------------------------------------------------------------
# Hard Level Cap related Additions
#-------------------------------------------------------------------------------
class Pokemon

  alias level_caps_level_equals level= unless method_defined?(:level_caps_level_equals)
  def level=(value)
    validate value => Integer
    if value < 1 || value > GameData::GrowthRate.max_level
      max_lvl = GameData::GrowthRate.max_level
      limit = (value < 1)? ["below the minimum  of level 1", "1"] : ["above the maximum of level #{max_lvl}", "#{max_lvl}"]
      echoln _INTL("Level {1} for {2} is not a valid level as it goes {3}. The level has been reset to {4}",
                    value, self, limit[0], limit[1])
      value = value.clamp(1, GameData::GrowthRate.max_level)
    end
    
    # Additional check for hard level cap - but respect bypass switch
    if LevelCapsEX.hard_cap? && value > LevelCapsEX.level_cap && !$game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH]
      value = LevelCapsEX.level_cap
    end
    
    @exp = growth_rate.minimum_exp_for_level(value)
    @level = value
  end

  def crosses_level_cap?
    return (LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap?) && self.level >= LevelCapsEX.level_cap
  end

  def level
    @level = growth_rate.level_from_exp(@exp) if !@level
    self.level = GameData::GrowthRate.max_level if @level > GameData::GrowthRate.max_level
    return @level
  end
end

module GameData
  class GrowthRate
    def self.max_level
      return Settings::MAXIMUM_LEVEL if LevelCapsEX::BYPASS_LEVEL_CAP_ON_DEBUG && $DEBUG
      return LevelCapsEX.hard_level_cap
    end
  end
end

#-------------------------------------------------------------------------------
# Soft Level Cap related Additions
#-------------------------------------------------------------------------------
class Battle
  alias __level_caps_initialize initialize unless method_defined?(:__level_caps_initialize)
  
  def initialize(*args)
    __level_caps_initialize(*args)
    
    # Debug logging
    # echoln("[Level Caps EX] Battle initialization")
    # echoln("[Level Caps EX] Bypass switch #{LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH} = #{$game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH]}")
    
    # Early return if bypass switch is ON
    if $game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH] || (LevelCapsEX::BYPASS_LEVEL_CAP_ON_DEBUG && $DEBUG)
      # echoln("[Level Caps EX] Bypass switch is ON - skipping level cap enforcement")
      return
    end
    
    # Apply level caps to opponent Pokemon only if bypass is OFF
    if opponent && opponent.respond_to?(:party)
      # echoln("[Level Caps EX] Checking opponent Pokemon levels")
      opponent.party.each do |pkmn|
        next if !pkmn
        if pkmn.level > LevelCapsEX.level_cap
          old_level = pkmn.level
          pkmn.level = LevelCapsEX.level_cap
          pkmn.calc_stats
          # echoln("[Level Caps EX] Adjusted #{pkmn.name} from Lv.#{old_level} to Lv.#{LevelCapsEX.level_cap}")
        end
      end
    end
  end

  def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    pkmn = pbParty(0)[idxParty]   # The Pokémon gaining Exp from defeatedBattler
    growth_rate = pkmn.growth_rate
    
    # Hard level cap check - completely block exp gain
    if LevelCapsEX.hard_cap? && pkmn.level >= LevelCapsEX.level_cap
      return
    end
    
    # Don't bother calculating if gainer is already at max Exp
    if pkmn.exp >= growth_rate.maximum_exp
      pkmn.calc_stats   # To ensure new EVs still have an effect
      return
    end
    isPartic    = defeatedBattler.participants.include?(idxParty)
    hasExpShare = expShare.include?(idxParty)
    level = defeatedBattler.level
    # Main Exp calculation
    exp = 0
    a = level * defeatedBattler.pokemon.base_exp
    if expShare.length > 0 && (isPartic || hasExpShare)
      if numPartic == 0   # No participants, all Exp goes to Exp Share holders
        exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
      elsif Settings::SPLIT_EXP_BETWEEN_GAINERS   # Gain from participating and/or Exp Share
        exp = a / (2 * numPartic) if isPartic
        exp += a / (2 * expShare.length) if hasExpShare
      else   # Gain from participating and/or Exp Share (Exp not split)
        exp = a # (isPartic) ? a : a / 2
      end
    elsif isPartic   # Participated in battle, no Exp Shares held by anyone
      exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
    elsif expAll   # Didn't participate in battle, gaining Exp due to Exp All
      # NOTE: Exp All works like the Exp Share from Gen 6+, not like the Exp All
      #       from Gen 1, i.e. Exp isn't split between all Pokémon gaining it.
      exp = a / 2
    end
    return if exp <= 0
    # Pokémon gain more Exp from trainer battles
    exp = (exp * 1.5).floor if Settings::MORE_EXP_FROM_TRAINER_POKEMON && trainerBattle?
    # Scale the gained Exp based on the gainer's level (or not)
    if Settings::SCALED_EXP_FORMULA
      exp /= 5
      # levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      if  (level+5 <= pkmn.level)   # Si el rival tiene mucho menos nivel
        levelAdjust = ((1 * level) + 10.0) / (pkmn.level + level + 10.0)
      elsif (level < pkmn.level)    # Si el rival tiene menos nivel que tú
        levelAdjust = ((1.5 * level) + 10.0) / (pkmn.level + level + 10.0)
      elsif (pkmn.level <= level-10) #Si tu no tienes mucho nivel
        levelAdjust = ((3 * level) + 10.0) / (pkmn.level + level + 10.0)
      elsif (pkmn.level <= level-5) #Si tu no tienes mucho nivel
        levelAdjust = ((2.5 * level) + 10.0) / (pkmn.level + level + 10.0)
      elsif (pkmn.level <= level-2) # Si tu no tienes mucho nivel
        levelAdjust = ((2.2 * level) + 10.0) / (pkmn.level + level + 10.0)
      else
        levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      end
      levelAdjust **= 5
      levelAdjust = Math.sqrt(levelAdjust)
      exp *= levelAdjust
      exp = exp.floor
      exp += 1 if isPartic || hasExpShare
    else
      exp /= 7
    end
    # Foreign Pokémon gain more Exp
    isOutsider = (pkmn.owner.id != pbPlayer.id ||
                 (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language))
    if isOutsider
      if pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language
        exp = (exp * 1.7).floor
      else
        exp = (exp * 1.5).floor
      end
    end
    # Exp. Charm increases Exp gained
    exp = exp * 3 / 2 if $bag.has?(:EXPCHARM)
    # Modify Exp gain based on pkmn's held item
    i = Battle::ItemEffects.triggerExpGainModifier(pkmn.item, pkmn, exp)
    if i < 0
      i = Battle::ItemEffects.triggerExpGainModifier(@initialItems[0][idxParty], pkmn, exp)
    end
    exp = i if i >= 0
    # Boost Exp gained with high affection
    if Settings::AFFECTION_EFFECTS && @internalBattle && pkmn.affection_level >= 4 && !pkmn.mega?
      exp = exp * 6 / 5
      isOutsider = true   # To show the "boosted Exp" message
    end
    # Modify exp gain based on soft level cap
    over_level_cap = false
    if LevelCapsEX.soft_cap? && pkmn.level >= LevelCapsEX.level_cap
      over_level_cap = true
      exp = (exp / 10).to_i
      exp = 1 if exp < 1
    end
    # Make sure Exp doesn't exceed the maximum
    expFinal = growth_rate.add_exp(pkmn.exp, exp)
    
    # Add additional check: don't let experience exceed level cap if hard cap is on
    if LevelCapsEX.hard_cap?
      max_exp_allowed = growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap)
      expFinal = [expFinal, max_exp_allowed].min
    end
    
    expGained = expFinal - pkmn.exp
    return if expGained <= 0
    # "Exp gained" message
    if showMessages
      message = _INTL("¡{1} obtuvo {2} puntos de experiencia!", pkmn.name, expGained)
      message = _INTL("¡{1} obtuvo {2} puntos de experiencia extra!", pkmn.name, expGained) if isOutsider
      message = _INTL("¡{1} obtuvo {2} puntos de experiencia extra!", pkmn.name, expGained) if over_level_cap
      pbDisplayPaused(message)
    end
    curLevel = pkmn.level
    newLevel = growth_rate.level_from_exp(expFinal)
    if newLevel < curLevel
      debugInfo = "Levels: #{curLevel}->#{newLevel} | Exp: #{pkmn.exp}->#{expFinal} | gain: #{expGained}"
      raise _INTL("{1}'s new level is less than its current level, which shouldn't happen.", pkmn.name) + "\n[#{debugInfo}]"
    end
    # Give Exp
    if pkmn.shadowPokemon?
      if pkmn.heartStage <= 3
        pkmn.exp += expGained
        $stats.total_exp_gained += expGained
      end
      return
    end
=begin
    $stats.total_exp_gained += expGained
    tempExp1 = pkmn.exp
    battler = pbFindBattler(idxParty)
    loop do   # For each level gained in turn...
      # EXP Bar animation
      levelMinExp = growth_rate.minimum_exp_for_level(curLevel)
      levelMaxExp = growth_rate.minimum_exp_for_level(curLevel + 1)
      tempExp2 = (levelMaxExp < expFinal) ? levelMaxExp : expFinal
      pkmn.exp = tempExp2
      @scene.pbEXPBar(battler, levelMinExp, levelMaxExp, tempExp1, tempExp2)
      tempExp1 = tempExp2
      curLevel += 1
      if curLevel > newLevel
        # Gained all the Exp now, end the animation
        pkmn.calc_stats
        battler&.pbUpdate(false)
        @scene.pbRefreshOne(battler.index) if battler
        break
      end
      # Levelled up
      pbCommonAnimation("LevelUp", battler) if battler
      oldTotalHP = pkmn.totalhp
      oldAttack  = pkmn.attack
      oldDefense = pkmn.defense
      oldSpAtk   = pkmn.spatk
      oldSpDef   = pkmn.spdef
      oldSpeed   = pkmn.speed
      battler.pokemon.changeHappiness("levelup") if battler&.pokemon
      pkmn.calc_stats
      battler&.pbUpdate(false)
      @scene.pbRefreshOne(battler.index) if battler
      pbDisplayPaused(_INTL("¡{1} subió al nivel {2}!", pkmn.name, curLevel)) { pbSEPlay("Pkmn level up") }
      @scene.pbLevelUp(pkmn, battler, oldTotalHP, oldAttack, oldDefense,
                       oldSpAtk, oldSpDef, oldSpeed)
      # Learn all moves learned at this level
      moveList = pkmn.getMoveList
      moveList.each { |m| pbLearnMove(idxParty, m[1]) if m[0] == curLevel }
    end
=end

    $stats.total_exp_gained += expGained
    pkmn.exp = expFinal
    battler = pbFindBattler(idxParty)
    levelMinExp = growth_rate.minimum_exp_for_level(curLevel)
    levelMaxExp = growth_rate.minimum_exp_for_level(newLevel)
    @scene.pbEXPBar(battler, levelMinExp, levelMaxExp, pkmn.exp - expGained, pkmn.exp)
    oldTotalHP = pkmn.totalhp
    oldAttack  = pkmn.attack
    oldDefense = pkmn.defense
    oldSpAtk   = pkmn.spatk
    oldSpDef   = pkmn.spdef
    oldSpeed   = pkmn.speed
    pkmn.calc_stats
    battler&.pbUpdate(false)
    @scene.pbRefreshOne(battler.index) if battler
    if newLevel > curLevel
      pbCommonAnimation("LevelUp", battler) if battler
      pbDisplayPaused(_INTL("¡{1} subió al nivel {2}!", pkmn.name, newLevel)) { pbSEPlay("Pkmn level up") }
      @scene.pbLevelUp(pkmn, battler, oldTotalHP, oldAttack, oldDefense,
                      oldSpAtk, oldSpDef, oldSpeed)
      battler.pokemon.changeHappiness("levelup") if battler&.pokemon
      moveList = pkmn.getMoveList
      (curLevel+1).upto(newLevel) do |lvl|
        moveList.each { |m| pbLearnMove(idxParty, m[1]) if m[0] == lvl }
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Obedience Related Level Cap Additions
#-------------------------------------------------------------------------------
class Battle::Battler

  alias __level_cap__pbObedienceCheck? pbObedienceCheck? unless method_defined?(:__level_cap__pbObedienceCheck?)
  def pbObedienceCheck?(*args)
    ret = __level_cap__pbObedienceCheck?(*args)
    db = @disobeyed
    @disobeyed = false
    return ret if ret || db
    # Level Cap Disobedience checks
    return true if LevelCapsEX.level_cap_mode != 3
    lv_diff = @level - LevelCapsEX.level_cap
    lv_diff = 5 if lv_diff >= 5
    disobedient = rand(5 - lv_diff) == 0
    return pbDisobey(args[0], (lv_diff * 2)) if lv_diff >= 5 || disobedient
    return true
  end

  alias __level_cap__pbDisobey pbDisobey unless method_defined?(:__level_cap__pbDisobey)
  def pbDisobey(*args)
    ret = __level_cap__pbDisobey(*args)
    @disobeyed = true
    return ret
  end
end

#-------------------------------------------------------------------------------
# Fix for battle system: Prevents opponent from sending out fainted Pokémon
#-------------------------------------------------------------------------------
class Battle::AI
  alias __level_caps_pbDefaultChooseNewEnemy pbDefaultChooseNewEnemy unless method_defined?(:__level_caps_pbDefaultChooseNewEnemy)
  
  def pbDefaultChooseNewEnemy(idxBattler = @idxBattler)
    # Get the original result
    ret = __level_caps_pbDefaultChooseNewEnemy(idxBattler)
    
    # Check if the selected Pokémon is able to battle
    if ret && ret >= 0
      party = @battle.pbParty(@idxBattler)
      if ret < party.length && !party[ret].able?
        # The chosen Pokémon is not able to battle, find another one
        new_choice = -1
        party.each_with_index do |pkmn, i|
          next if !pkmn || !pkmn.able? || @battle.pbFindBattler(i, @idxBattler)
          new_choice = i
          break
        end
        ret = new_choice
      end
    end
    
    return ret
  end
end

#-------------------------------------------------------------------------------
# Fix for Level Caps EX causing PBS compilation to fail
#-------------------------------------------------------------------------------
# This is a workaround for the issue where Level Caps EX causes PBS compilation
# to fail. Since we can't reliably patch the compiler directly, we'll use a
# different approach to detect PBS compilation.
#-------------------------------------------------------------------------------

module GameData
  class GrowthRate
    # Store original max level value from Settings
    @original_max_level = Settings::MAXIMUM_LEVEL
    
    class << self
      alias_method :original_max_level, :max_level unless method_defined?(:original_max_level)
      
      def max_level
        # During PBS compilation, use the original maximum level
        # PBS compilation can be detected by checking the stack trace
        if caller.any? { |c| c.include?("compile") }
          return @original_max_level || Settings::MAXIMUM_LEVEL
        end
        # Normal gameplay - use the level cap
        cap = LevelCapsEX.hard_level_cap
        return cap
      end
    end
  end
end

class Pokemon_Trainer
  alias __level_caps_initialize initialize unless method_defined?(:__level_caps_initialize)
  
  def initialize(*args)
    # echoln("Trainer initialization started")  # Debug line
    # echoln("Level Cap Bypass Switch #{LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH} state: #{$game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH]}")
    __level_caps_initialize(*args)
    enforce_level_cap
  end

  def enforce_level_cap
    # echoln("Enforcing level cap check started")  # Debug line
    # echoln("Current level cap: #{LevelCapsEX.level_cap}")
    # echoln("Bypass switch #{LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH} is: #{$game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH] ? 'ON' : 'OFF'}")
    
    return if $game_switches[LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH] || (LevelCapsEX::BYPASS_LEVEL_CAP_ON_DEBUG && $DEBUG)
    return unless LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap?
    
    cap = LevelCapsEX.level_cap
    @party&.each_with_index do |pkmn, index|
      next if !pkmn
      # echoln("Checking Pokemon #{index + 1}: #{pkmn.name} Level #{pkmn.level}")
      if pkmn.level > cap
        old_level = pkmn.level
        pkmn.level = cap
        pkmn.calc_stats
        # echoln("Adjusted #{pkmn.name} from level #{old_level} to #{cap}")
      end
    end
  end
end