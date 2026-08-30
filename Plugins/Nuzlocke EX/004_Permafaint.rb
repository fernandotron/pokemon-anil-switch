#-------------------------------------------------------------------------------
# Add Perma faint functionality to Pokemon
#-------------------------------------------------------------------------------
class Pokemon

  def perma_faint
    return false if !ChallengeModes.on?(:PERMAFAINT)
    return @perma_faint
  end

  def perma_faint=(value)
    @perma_faint = value
    @hp = 0 if @perma_faint
  end

  alias __challenge__heal_HP heal_HP unless method_defined?(:__challenge__heal_HP)
  def heal_HP
    return if perma_faint
    __challenge__heal_HP
  end

  alias __challenge__hp hp unless method_defined?(:__challenge__hp)
  def hp; return perma_faint ? 0 : __challenge__hp; end

  alias __challenge__fainted? fainted? unless method_defined?(:__challenge__fainted?)
  def fainted?; return perma_faint ? true : __challenge__fainted?; end

  alias __challenge__able? able? unless method_defined?(:__challenge__able?)
  def able?; return perma_faint ? false : __challenge__able?; end

  alias __challenge__hp_set hp= unless method_defined?(:__challenge__hp_set)
  def hp=(val)
    self.perma_faint = true if ChallengeModes.on?(:PERMAFAINT) && val <= 0
    new_val = perma_faint ? 0 : val
    __challenge__hp_set(new_val)
  end

  def curar_equipo_debilitado_debug
    @perma_faint = false
    @hp = @totalhp
  end
end

#-------------------------------------------------------------------------------
# Make Revival items ineffective on Permafainted Pokemon
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:REVIVE, proc { |item, qty, pkmn, scene|
  if !pkmn.fainted? || pkmn.perma_faint
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.hp = (pkmn.totalhp / 2).floor
  pkmn.hp = 1 if pkmn.hp <= 0
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("La salud de {1} fue restaurada.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:MAXREVIVE, proc { |item, qty, pkmn, scene|
  if !pkmn.fainted? || pkmn.perma_faint
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_HP
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("La salud de {1} fue restaurada.", pkmn.name))
  next true
})

ItemHandlers::UseOnPokemon.add(:CENIZASSAGRADAS, proc { |item, qty, pkmn, scene|
  if !pkmn.fainted? || (pkmn.perma_faint && !ChallengeModes.on?(:MODOASISTIDO))
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pkmn.perma_faint = false if pkmn.perma_faint && ChallengeModes.on?(:MODOASISTIDO)    
  pbSEPlay("Use item in party")
  pkmn.heal_HP
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("La salud de {1} fue restaurada.", pkmn.name))
  next true
})


ItemHandlers::UseOnPokemon.copy(:MAXREVIVE, :MAXHONEY)

ItemHandlers::UseOnPokemon.add(:REVIVALHERB, proc { |item, qty, pkmn, scene|
  if !pkmn.fainted? || pkmn.perma_faint
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  pbSEPlay("Use item in party")
  pkmn.heal_HP
  pkmn.heal_status
  pkmn.changeHappiness("revivalherb")
  scene.pbRefresh
  scene.pbDisplay(_INTL("La salud de {1} fue restaurada.", pkmn.name))
  next true
})

ItemHandlers::UseInField.add(:SACREDASH, proc { |item|
  if $player.pokemon_count == 0
    pbMessage(_INTL("No hay ningún Pokémon."))
    next false
  end
  canrevive = false
  $player.pokemon_party.each do |i|
    next if !i.fainted? || i.perma_faint
    canrevive = true
    break
  end
  if !canrevive
    pbMessage(_INTL("No tendría ningún efecto."))
    next false
  end
  revived = 0
  pbFadeOutIn do
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene, $player.party)
    screen.pbStartScene(_INTL("Usando objeto..."), false)
    pbSEPlay("Use item in party")
    $player.party.each_with_index do |pkmn, i|
      next if !pkmn.fainted? || i.perma_faint
      revived += 1
      pkmn.heal
      screen.pbRefreshSingle(i)
      screen.pbDisplay(_INTL("La salud de {1} fue restaurada.", pkmn.name))
    end
    screen.pbDisplay(_INTL("No tendría ningún efecto.")) if revived == 0
    screen.pbEndScene
  end
  next (revived > 0)
})

ItemHandlers::CanUseInBattle.add(:REVIVE, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  if !pokemon.fainted? || pokemon.perma_faint
    scene.pbDisplay(_INTL("No tendría ningún efecto.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:REVIVE, :MAXREVIVE, :REVIVALHERB, :MAXHONEY)