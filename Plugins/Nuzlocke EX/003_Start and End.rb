#-------------------------------------------------------------------------------
# Reload challenge data upon save reload
#-------------------------------------------------------------------------------
class PokemonLoadScreen
  alias __challenge__pbStartLoadScreen pbStartLoadScreen #unless method_defined?(:__challenge__pbStartLoadScreen)
  def pbStartLoadScreen
    ret = __challenge__pbStartLoadScreen
    ChallengeModes.begin_challenge if ChallengeModes.running? && !$PokemonGlobal.challenge_rules.empty?
    # ChallengeModes.toggle(true) if ChallengeModes.running?
    return ret
  end
end

alias __challenge__pbTrainerName pbTrainerName unless defined?(__challenge__pbTrainerName)
def pbTrainerName(*args)
  ret = __challenge__pbTrainerName(*args)
  ChallengeModes.reset
  $PokemonGlobal.challenge_state = {}
  return ret
end

#-------------------------------------------------------------------------------
# Starts challenge only after obtaining a Pokeball
#-------------------------------------------------------------------------------
class PokemonBag
  alias __challenge__add add unless method_defined?(:__challenge__add)
  def add(*args)
    ret = __challenge__add(*args)
    item = args[0]
    return ret if !$PokemonGlobal || !$PokemonGlobal.challenge_qued || !GameData::Item.get(item).is_poke_ball?
    ChallengeModes.begin_challenge
    pbMessage(_INTL("¡Tu desafío ha comenzado! ¡Buena suerte!"))
    return ret
  end
end


#-------------------------------------------------------------------------------
# Add Game Over methods
#-------------------------------------------------------------------------------
alias __challenge__pbStartOver pbStartOver unless defined?(__challenge__pbStartOver)
def pbStartOver(*args)
  return __challenge__pbStartOver(*args) if !ChallengeModes.on?
  resume = false
  pbEachPokemon do |pkmn, _|
    next if pkmn.fainted? || pkmn.egg?
    resume = true
    break
  end
  if resume && !ChallengeModes.on?(:GAME_OVER_WHITEOUT) && !ChallengeModes.on?(:PERMALOCKE)
    loop do
      pbMessage("\\w[]\\wm\\c[8]\\l[3]" + 
        _INTL("Todos tus Pokémon se han desmayado. Pero aún tienes Pokémon en tu PC con los que puedes continuar el desafío."))
      pbFadeOutIn(99999) {
        scene = PokemonStorageScene.new
        screen = PokemonStorageScreen.new(scene, $PokemonStorage)
        screen.pbStartScreen(0)
      }
      break if $player.able_pokemon_count != 0
    end
  else
    pbMessage("\\w[]\\wm\\c[8]\\l[3]" + 
      _INTL("Todos tus Pokémon se han desmayado. ¡Has perdido el desafío! Todos los modificadores de desafío estarán desactivados."))
    ChallengeModes.set_loss
  end
  return __challenge__pbStartOver(*args)
end

def check_has_living_pokemon?
  return true if !$PokemonGlobal || !ChallengeModes.on? || !ChallengeModes.on?(:PERMAFAINT)
  has_living = false
  pbEachPokemon do |pkmn, _|
    next if pkmn.fainted? || pkmn.egg?
    has_living = true
    break
  end
  return has_living
end