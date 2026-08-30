class PokemonGlobalMetadata
  attr_accessor :monotype_type
end

module MonotypeChallenge
  # Configuración del sistema
  module Config
    # Si está en true se bloquearán las evoluciones a otros tipos
    BLOQUEAR_EVOLUCIONES_A_OTROS_TIPOS = true

    # Bloquear Pokémon regalados, si el Pokémon regalado no cumple con el monotype
    # El jugador no podrá recibirlo
    BLOCK_GIFT_POKEMON = true

    # Si está en true se eliminarán todos los Pokémon del equipo que no cumplan con el
    # tipo de reto monotype.
    DELETE_INVALID_FROM_PARTY = true

    # Si está en true se moverán los Pokémon que no cumplan con el tipo de reto monotype al PC
    MOVE_INVALID_FROM_PARTY_TO_PC = true

    # Si está en true se eliminarán los Pokémon del PC que no cumplan con el tipo de reto monotype
    DELETE_INVALID_FROM_PC = false
  end

  def self.enabled?
    !type.nil?
  end

  def self.disable
    self.type = nil
  end

  # Devuelve el tipo para el modo monotype
  def self.type
    $PokemonGlobal&.monotype_type
  end

  def self.type_name
    return if type.nil?
    GameData::Type.get(type).name
  end

  # Guarda el tipo del monotype
  def self.type=(new_type)
    return unless new_type.nil? || GameData::Type.exists?(new_type)
    $PokemonGlobal.monotype_type = new_type
  end

  def self.no_valid_pokemon_in_party?
    return false unless enabled?
    return false if $player.party.empty?

    pokes_to_remove = []
    party = $player.party

    if !Config::MOVE_INVALID_FROM_PARTY_TO_PC && Config::DELETE_INVALID_FROM_PARTY
      party.delete_if do |poke|
        should_remove = should_remove_pokemon?(poke, party.length)
        pokes_to_remove.push(poke) if should_remove
        should_remove
      end
    elsif Config::MOVE_INVALID_FROM_PARTY_TO_PC
      party.delete_if do |poke|
        should_remove = should_remove_pokemon?(poke, party.length)
        if should_remove
          $PokemonStorage.pbStoreCaught(poke)
          pokes_to_remove.push(poke)
        end
        should_remove
      end
    else
      pokes_to_remove = party.select { |poke| !poke.egg? && !valid_monotype?(poke) }
    end
    
    party.length <= pokes_to_remove.length
  end

  # Método auxiliar para determinar si un Pokémon debe ser removido del equipo
  def self.should_remove_pokemon?(poke, party_length)
    !poke.egg? && !valid_monotype?(poke) && party_length > 1
  end

  # Devuelve 3 starters para el monotype seleccionado
  # def self.choose_starter
  #   return unless enabled?

  #   current_type = type
  #   starters = STARTER_OPTIONS[current_type]&.sample(3)

  #   return if starters.nil? || starters.empty?

  #   commands = starters.map { |starter| GameData::Species.get(starter).name }

  #   chosen = -1
  #   chosen = pbMessage(_INTL('Elige a tu nuevo inicial'), commands, -1) while chosen == -1

  #   pbAddPokemon(starters[chosen], 5)
  #   type_name = GameData::Type.get(current_type).name
  #   delete_invalid_from_pc
  #   pbMessage(_INTL("¡A partir de ahora estás en un <b>Reto Monotype</b> de tipo #{type_name}!"))
  # end

  def self.delete_invalid_from_pc
    return unless enabled? && Config::DELETE_INVALID_FROM_PC

    # Iterar desde el final hacia el inicio para evitar problemas de índices
    (-1...$PokemonStorage.maxBoxes).each do |box_index|
      ($PokemonStorage.maxPokemon(box_index) - 1).downto(0) do |slot_index|
        pkmn = $PokemonStorage[box_index][slot_index]
        next if pkmn.nil? || pkmn.egg?
        
        if !valid_monotype?(pkmn)
          $PokemonStorage.pbDelete(box_index, slot_index)
        end
      end
    end
  end

  # Valida que el pokemon sea válido para el reto monotype elegido
  # Devuelve [bool, mensaje] donde bool indica si es válido y mensaje el tipo requerido si no lo es
  def self.valid_monotype_with_text?(poke, form = 0)
    selected_type = type
    return [true, nil] unless selected_type # No está activo el monotype

    if poke.is_a?(Symbol)
      species_data = GameData::Species.get_species_form(poke, form)
      return [true, nil] if species_data.types.include?(selected_type) || evolved_types(poke).include?(selected_type)
      return [false, GameData::Type.get(selected_type).name]
    end

    # Para objetos Pokemon
    return [true, nil] if poke.types.include?(selected_type) || evolved_types(poke).include?(selected_type)
    
    [false, GameData::Type.get(selected_type).name]
  end

  # Valida que el pokemon sea válido para el monotype elegido
  # Devuelve true si lo es, y false si no
  def self.valid_monotype?(poke, form = 0)
    is_valid, _text = valid_monotype_with_text?(poke, form)
    is_valid
  end

  # Valida si alguna de las evoluciones del pokemon tiene el tipo del monotype elegido
  def self.evolved_types(poke)
    return [] unless poke && (poke.is_a?(Pokemon) || poke.is_a?(Symbol))

    species = poke.is_a?(Pokemon) ? poke.species : poke
    form = poke.respond_to?(:form) ? poke.form : 0
    
    begin
      # Obtener todas las evoluciones de la familia completa
      evos = GameData::Species.get_species_form(species, form).get_family_evolutions
      evos_types = []
      
      evos.each do |evo|
        evo_species = evo[1] # Consigue la especie de la evolución
        evo_data = GameData::Species.get_species_form(evo_species, form)
        evos_types.concat(evo_data.types)
      end
      
      return evos_types.uniq.compact # Eliminar duplicados y valores nil
    rescue
      [] # Retornar array vacío si hay error en la consulta
    end
  end
end


GameData::Evolution.register({
  :id                   => :Shedinja,
  :parameter            => Integer,
  :after_evolution_proc => proc { |pkmn, new_species, parameter, evo_species|
    next false if $player.party_full?
    next false if !$bag.has?(:POKEBALL)
    next false if !MonotypeChallenge.valid_monotype?(new_species)
    PokemonEvolutionScene.pbDuplicatePokemon(pkmn, new_species)
    $bag.remove(:POKEBALL)
    next true
  }
})

# Bloquea la evolución si no tiene el tipo elegido para el reto monotype
if MonotypeChallenge::Config::BLOQUEAR_EVOLUCIONES_A_OTROS_TIPOS
  class Pokemon
    # Método auxiliar para validar evoluciones en el contexto monotype
    def validate_monotype_evolution(new_species)
      return new_species unless MonotypeChallenge.enabled?
      return nil unless new_species
      
      # Permitir la evolución si la especie actual o cualquier evolución futura tiene el tipo correcto
      return new_species if MonotypeChallenge.valid_monotype?(new_species, self.form)
      return new_species if MonotypeChallenge.evolved_types(new_species).include?(MonotypeChallenge.type)
      
      nil
    end

    alias check_evolution_on_level_up_mono check_evolution_on_level_up
    def check_evolution_on_level_up
      new_species = check_evolution_on_level_up_mono
      validate_monotype_evolution(new_species)
    end

    alias check_evolution_on_use_item_mono check_evolution_on_use_item
    def check_evolution_on_use_item(item_used)
      new_species = check_evolution_on_use_item_mono(item_used)
      validate_monotype_evolution(new_species)
    end

    alias check_evolution_on_trade_mono check_evolution_on_trade
    def check_evolution_on_trade(other_pkmn)
      new_species = check_evolution_on_trade_mono(other_pkmn)
      validate_monotype_evolution(new_species)
    end

    alias check_evolution_after_battle_mono check_evolution_after_battle
    def check_evolution_after_battle(party_index)
      new_species = check_evolution_after_battle_mono(party_index)
      validate_monotype_evolution(new_species)
    end

    alias check_evolution_by_event_mono check_evolution_by_event
    def check_evolution_by_event(value = 0)
      new_species = check_evolution_by_event_mono(value)
      validate_monotype_evolution(new_species)
    end
  end
end

if MonotypeChallenge::Config::BLOCK_GIFT_POKEMON
    alias pbAddPokemon_Mono pbAddPokemon
    def pbAddPokemon(pkmn, level = 1, see_form = true)
      return pbAddPokemon_Mono(pkmn, level, see_form) unless MonotypeChallenge.enabled?
      if !pkmn.is_a?(Pokemon)
        pkmn = Pokemon.new(pkmn, level)
      end
      if !MonotypeChallenge.valid_monotype?(pkmn)
        species_name = pkmn.species_data.name
        pbMessage(_INTL("¡No puedes recibir a un {1}!\n¡Solo puedes recibir Pokémon de tipo {2}!", species_name, MonotypeChallenge.type_name))
        return false
      end
      pbAddPokemon_Mono(pkmn, level, see_form)
    end

    alias pbAddPokemonSilent_Mono pbAddPokemonSilent
    def pbAddPokemonSilent(pkmn, level = 1, see_form = true)
      if MonotypeChallenge.enabled? && !MonotypeChallenge.valid_monotype?(pkmn)
        return false
      end
      pbAddPokemonSilent_Mono(pkmn, level, see_form)
    end
end

# Modificación del manejo de Poké Balls para respetar las reglas del monotype
ItemHandlers::CanUseInBattle.remove(:poke_balls)
ItemHandlers::CanUseInBattle.addIf(:poke_balls,
  proc { |item| GameData::Item.get(item).is_poke_ball? },
  proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
    # Verificar espacio disponible
    if battle.pbPlayer.party_full? && $PokemonStorage.full?
      scene.pbDisplay(_INTL("¡No queda espacio en el PC!")) if showMessages
      next false
    end
    
    # Verificar si las Poké Balls están deshabilitadas
    if battle.disablePokeBalls
      scene.pbDisplay(_INTL("¡No puedes lanzar una Poké Ball!")) if showMessages
      next false
    end
    
    # Verificar concentración (primera acción)
    if !firstAction
      scene.pbDisplay(_INTL("¡Es imposible apuntar sin estar concentrado!")) if showMessages
      next false
    end
    
    # Verificar si el objetivo está visible
    if battler.semiInvulnerable?
      scene.pbDisplay(_INTL("¡No sirve! ¡Es imposible apuntar a un Pokémon que no está a la vista!")) if showMessages
      next false
    end
    
    # Verificar cantidad de oponentes
    if battle.pbOpposingBattlerCount > 1 && !(GameData::Item.get(item).is_snag_ball? && battle.trainerBattle?)
      message = battle.pbOpposingBattlerCount == 2 ? 
                "¡No sirve! ¡Es imposible apuntar cuando hay dos Pokémon!" :
                "¡No sirve! ¡Es imposible apuntar cuando hay más de un Pokémon!"
      scene.pbDisplay(_INTL(message)) if showMessages
      next false
    end
    
    # Obtener el objetivo
    target = battler.opposes? ? battler : battler.pbDirectOpposing(true)
    target = target.allAllies.first if target.fainted?
    
    # Validación específica del reto monotype
    if MonotypeChallenge.enabled? && !MonotypeChallenge.valid_monotype?(battler.pokemon)
      if showMessages
        pbSEStop
        type_name = MonotypeChallenge.type_name
        pbMessage(_INTL("¡Solo puedes capturar Pokémon de tipo {1}!", type_name))
      end
      next false
    end
    
    next true
  }
)