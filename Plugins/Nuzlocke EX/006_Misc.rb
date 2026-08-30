#-------------------------------------------------------------------------------
# Force nickname for any newly obtained Pokemon
#-------------------------------------------------------------------------------
alias __challenge__pbEnterPokemonName pbEnterPokemonName unless defined?(__challenge__pbEnterPokemonName)
def pbEnterPokemonName(*args)
  return __challenge__pbEnterPokemonName(*args) if !ChallengeModes.on?(:FORCE_NICKNAME)
  species_name = args[4].nil? ? args[3] : args[4].speciesName
  ret = ""
  loop do
    ret = __challenge__pbEnterPokemonName(*args)
    if ret.nil? || ret.empty? || ret.downcase == species_name.downcase
      rule_name = _INTL(ChallengeModes::RULES[:FORCE_NICKNAME][:display_name])
      pbMessage(_INTL("¡La regla \"{1}\" hace obligatorio ponerle un mote a tu Pokémon!", rule_name))
      next
    end
    break
  end
  return ret
end

alias __challenge__pbNickname pbNickname unless defined?(__challenge__pbNickname)
def pbNickname(pkmn)
  return if $PokemonSystem.givenicknames != 0
  species_name = pkmn.speciesName
  if ChallengeModes.on?(:FORCE_NICKNAME) ||
     pbConfirmMessage(_INTL("¿Te gustaría darle un mote a {1}?", species_name))
    pkmn.name = pbEnterPokemonName(_INTL("¿Mote de {1}?", species_name),
                                   0, Pokemon::MAX_NAME_SIZE, pkmn.name != species_name ? pkmn.name : "", pkmn)
  end
end

module Battle::CatchAndStoreMixin
  alias __challenge__pbStorePokemon pbStorePokemon #unless method_defined?(:__challenge__pbStorePokemon)
  def pbStorePokemon(*args)
    return __challenge__pbStorePokemon(*args) if !ChallengeModes.on?(:FORCE_NICKNAME)
    pkmn = args[0]
    if !pkmn.shadowPokemon?
      nickname = @scene.pbNameEntry(_INTL("¿Mote de {1}?", pkmn.speciesName), pkmn)
      pkmn.name = nickname
    end
    $PokemonSystem.givenicknames = 1
    ret = __challenge__pbStorePokemon(*args)
    pkmn.name = nickname
    $PokemonSystem.givenicknames = 0
    return ret
  end
end

alias __challenge__pbPurify pbPurify unless defined?(__challenge__pbPurify)
def pbPurify(*args)
  return __challenge__pbPurify(*args) if !ChallengeModes.on?(:FORCE_NICKNAME)
  $PokemonSystem.givenicknames = 1
  ret = __challenge__pbPurify(*args)
  pkmn = args[0]
  newname = pbEnterPokemonName(_INTL("¿Mote de {1}?", pkmn.speciesName),
                                 0, Pokemon::MAX_NAME_SIZE, pkmn.name != pkmn.speciesName ? pkmn.name : "", pkmn)
  pkmn.name = newname
  $PokemonSystem.givenicknames = 0
  return ret
end

class PokemonEggHatch_Scene
  alias __challenge__pbMain pbMain unless method_defined?(:__challenge__pbMain)
  def pbMain(*args)
    return __challenge__pbMain if !ChallengeModes.on?(:FORCE_NICKNAME)
    $PokemonSystem.givenicknames = 1
    ret = __challenge__pbMain(*args)
    $PokemonSystem.givenicknames = 0
    nickname = pbEnterPokemonName(_INTL("¿Mote de {1}?", @pokemon.name),
                                    0, Pokemon::MAX_NAME_SIZE, @pokemon.name != @pokemon.speciesName ? @pokemon.name : "", @pokemon, true)
    @pokemon.name = nickname
    @nicknamed = true
    return ret
  end
end

#-------------------------------------------------------------------------------
# Force set battle style in battle
#-------------------------------------------------------------------------------
MenuHandlers.remove(:options_menu, :battle_style)
MenuHandlers.remove(:options_menu, :give_nicknames)

MenuHandlers.add(:options_menu, :battle_style, {
  "name"        => _INTL("Estilo Combate"),
  "order"       => 50,
  "type"        => EnumOption,
  "condition"   => proc { next !ChallengeModes.on?(:FORCE_SET_BATTLES) && ( $game_switches && !$game_switches[MODO_RADICAL] ) },
  "parameters"  => [_INTL("Cambio"), _INTL("Fijo")],
  "description" => _INTL("Elige si puedes cambiar de Pokémon al derrotar un Pokémon rival."),
  "get_proc"    => proc { next $PokemonSystem.battlestyle },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.battlestyle = value }
})

MenuHandlers.add(:options_menu, :give_nicknames, {
  "name"        => _INTL("Poner Motes"),
  "order"       => 80,
  "type"        => EnumOption,
  "condition"   => proc { next !ChallengeModes.on?(:FORCE_NICKNAME) },
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Elige si quieres que te pregunte qué mote ponerle a un Pokémon al conseguirlo."),
  "get_proc"    => proc { next $PokemonSystem.givenicknames },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.givenicknames = value }
})

#-------------------------------------------------------------------------------
# Prevent item usage in trainer battles
#-------------------------------------------------------------------------------
class Battle::Scene
  alias __challenge__pbItemMenu pbItemMenu unless method_defined?(:__challenge__pbItemMenu)
  def pbItemMenu(*args, &block)
    if ( ChallengeModes.on?(:NO_TRAINER_BATTLE_ITEMS) || $game_switches[MODO_RADICAL] ) && @battle.trainerBattle?
      rule_name = _INTL(ChallengeModes::RULES[:NO_TRAINER_BATTLE_ITEMS][:display_name])
      pbSEStop
      pbSEPlay("GUI sel buzzer")
      if $game_switches[MODO_RADICAL]
        pbDisplayPausedMessage(_INTL("¡El modo radical no permite usar objetos en combates de entrenador!"))
      else
        pbDisplayPausedMessage(_INTL("¡La regla \"{1}\" bloquea el uso de objetos en las Batallas de Entrenador!", rule_name))
      end
      return [0, -1]
    end
    return __challenge__pbItemMenu(*args, &block)
  end
end

#-------------------------------------------------------------------------------
# Various data to be stored related to challenge modes
#-------------------------------------------------------------------------------
class PokemonGlobalMetadata
  attr_accessor :challenge_qued
  attr_accessor :challenge_started
  attr_accessor :challenge_rules
  attr_accessor :challenge_encs
  attr_accessor :challenge_lives

  attr_writer :challenge_state

  def challenge_state
    @challenge_state = {} if !@challenge_state.is_a?(Hash)
    return @challenge_state
  end
end