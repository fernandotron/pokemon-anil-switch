class PokemonGlobalMetadata
  attr_accessor :level_cap_enabled
  alias level_cap_initialize initialize
  def initialize
    level_cap_initialize
    @level_cap_enabled = true
  end
end
module LevelCapsEX


  # Set this to the Game Variable which controls the value of the
  # level cap
  LEVEL_CAP_VARIABLE      = 27

  # Set this to the Game Variable which controls the mode of the
  # level cap. The 3 modes are:
  #   1 (Hard Cap) - The Pokemon cannot level up/gain experience 
  #   past the level cap.
  #   2 (EXP Cap) - The Pokemon will gain reduced EXP when it
  #   crosses the level cap.
  #   3 (Obedience Cap)  - The Pokemon will gain disobey the player
  #   when it crosses the level cap.
  LEVEL_CAP_MODE_VARIABLE = 28

  # Set this to the default mode of the Level Cap
  DEFAULT_LEVEL_CAP_MODE  = 1

  # Set this to the Game Switch which, when ON, disables level cap for enemy trainers
  LEVEL_CAP_BYPASS_SWITCH = 29
  BYPASS_LEVEL_CAP_ON_DEBUG = true

  # Set this to true if any changes to the Level Cap/Level Cap mode
  # should be printed to the console.
  LOG_LEVEL_CAP_CHANGES   = true

  # INTERRUPTOR DE CADA GYM
  SWITCHGYM1 = 184
  SWITCHGYM2 = 185
  SWITCHGYM3 = 186
  SWITCHGYM4 = 187
  SWITCHGYM5 = 192
  SWITCHGYM6 = 196
  SWITCHGYM7 = 212
  SWITCHGYM8 = 225
  SWITCHGYM9 = 249

  # NIVEL DEL LEVEL CAP CON CADA GYM
  LEVELGYM0 = 14
  LEVELGYM1 = 23
  LEVELGYM2 = 30
  LEVELGYM3 = 39
  LEVELGYM4 = 49
  LEVELGYM5 = 54
  LEVELGYM6 = 59
  LEVELGYM7 = 66
  LEVELGYM8 = 75
  LEVELGYM9 = 100

  def self.get_level_cap
    return Settings::MAXIMUM_LEVEL if ($DEBUG && BYPASS_LEVEL_CAP_ON_DEBUG) || !enabled? || $player.connecting_online?
    $PokemonGlobal.level_cap_enabled ||= true
    gym_levels = {
      SWITCHGYM1  => LEVELGYM1,
      SWITCHGYM2  => LEVELGYM2,
      SWITCHGYM3  => LEVELGYM3,
      SWITCHGYM4  => LEVELGYM4,
      SWITCHGYM5  => LEVELGYM5,
      SWITCHGYM6  => LEVELGYM6,
      SWITCHGYM7  => LEVELGYM7,
      SWITCHGYM8  => LEVELGYM8,
      SWITCHGYM9  => LEVELGYM9
    }
    cap = LEVELGYM0
    gym_levels.each do |switch, level|
      cap = level if $game_switches[switch] && level > cap
    end
    $game_variables[LEVEL_CAP_VARIABLE] = cap
  end

  def self.toggle
    $PokemonGlobal.level_cap_enabled = true if $PokemonGlobal.level_cap_enabled.nil?
    $PokemonGlobal.level_cap_enabled = !$PokemonGlobal.level_cap_enabled  
  end

  def self.enabled?
    return $PokemonGlobal.level_cap_enabled ? true : false
  end

end