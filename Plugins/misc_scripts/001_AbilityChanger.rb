module AbilityChanger
  # Main public interface for changing a Pokemon's ability
  def self.change_ability
    # Selecciona un Pokémon que no sea huevo, no sea sombra y que tenga más de una habilidad
    pbChoosePokemon(1, 2, proc { |poke| !poke.egg? && 
                                        !poke.shadowPokemon? && 
                                        ( poke.getAbilityList.size > 1 || (poke.forced_ability? && poke.traded?) ) })

    # Comprueba si se ha seleccionado un Pokémon válido
    return false unless $game_variables[1] != -1

    # Get the selected Pokémon directly from the player's party
    pokemon = $player.party[pbGet(1)]    
    return false unless pokemon # Additional safety check
    if pokemon.forced_ability? && pokemon.traded?
      if !pbConfirmMessage(_INTL("Este Pokémon fue intercambiado y tiene una habilidad forzada. Si la cambias, perderá esa habilidad. ¿Quieres continuar?"))
        return false
      end
      pokemon.forced_ability = nil # Remove forced ability if confirmed
    end

    abilities = pokemon.getAbilityList
    current_ability_id = pokemon.ability_id

    # Crear lista de habilidades para mostrar
    ability_options, ability_descs = build_ability_lists(abilities)

    current_ability_index = abilities.index { |ability| ability[0] == current_ability_id } || 0
    # Pregunta al jugador qué habilidad quiere seleccionar
    chosen_ability = MessageUI.show_with_help_lines(
      _INTL("¿Qué habilidad quieres para #{pokemon.name}?"), 
      ability_options, 
      ability_descs, 
      -1, nil, current_ability_index, 3
    )

    return handle_ability_choice(pokemon, abilities, current_ability_id, chosen_ability)
  end

  private

  # Builds the ability options and descriptions for display
  def self.build_ability_lists(abilities)
    ability_options = []
    ability_descs = []
    
    abilities.each do |ability|
      ability_data = GameData::Ability.get(ability[0])
      name = ability_data.name + (ability[1] < 2 ? '' : ' (H)')
      desc = ability_data.description
      ability_options << name
      ability_descs << desc
    end
    
    [ability_options, ability_descs]
  end

  # Handles the player's ability choice and applies the change
  def self.handle_ability_choice(pokemon, abilities, current_ability_id, chosen_ability)
    case chosen_ability
    when -1
      pbMessage(_INTL('Piénsatelo bien, tus Pokémon pueden tener habilidades ocultas muy interesantes.'))
      false
    else
      chosen_ability_id = abilities[chosen_ability][0]
      if chosen_ability_id == current_ability_id
        pbMessage(_INTL('Tu Pokémon ya posee esa habilidad.'))
        false
      else
        # Cambia la habilidad del Pokémon si se ha hecho una elección válida
        pokemon.forced_ability = nil # Reset forced ability
        pokemon.ability_index = abilities[chosen_ability][1]
        pokemon.calc_stats
        true
      end
    end
  end
end

# UI helper module for message display with help text
module MessageUI
  def self.show_with_help_lines(message, commands = nil, help = nil, cmd_if_cancel = 0, skin = nil, default_cmd = 0, lines = 2, &block)
    ret = 0
    msgwindow = pbCreateMessageWindow(nil, skin, lines)
    
    begin
      if commands
        ret = pbMessageDisplay(msgwindow, message, true,
            proc { |msgwindow|
              if help
                show_commands_with_help_and_text(msgwindow, commands, help, cmd_if_cancel, default_cmd, message, lines, &block)
              else
                pbShowCommands(msgwindow, commands, cmd_if_cancel, default_cmd, &block)
              end
            }, &block)
      else
        pbMessageDisplay(msgwindow, message, &block)
      end
    ensure
      pbDisposeMessageWindow(msgwindow)
      Input.update
    end
    
    ret
  end

  def self.show_commands_with_help_and_text(msgwindow, commands, help, cmd_if_cancel = 0, default_cmd = 0, text = '', lines = 2)
    msgwin = msgwindow || pbCreateMessageWindow(nil)
    msgwin2 = nil
    cmdwindow = nil
    
    begin
      old_letterbyletter = msgwin.letterbyletter
      msgwin.letterbyletter = false
      
      return 0 unless commands
      
      # Setup command window
      cmdwindow = Window_CommandPokemonEx.new(commands)
      cmdwindow.z = 99999
      cmdwindow.visible = true
      cmdwindow.resizeToFit(cmdwindow.commands)
      cmdwindow.index = default_cmd
      
      # Setup description window
      setup_description_window(msgwin, help, cmdwindow, lines)
      
      # Setup optional text window
      if text.length > 0
        msgwin2 = create_text_window(text, lines)
        cmdwindow.y = msgwin2.height
      end
      
      # Main input loop
      command = handle_user_input(cmdwindow, msgwin, help, cmd_if_cancel)
      
      command
    ensure
      # Cleanup resources
      cmdwindow&.dispose
      msgwin2&.dispose
      msgwin.letterbyletter = old_letterbyletter if defined?(old_letterbyletter)
      msgwin.dispose unless msgwindow
      Input.update
    end
  end

  private

  def self.setup_description_window(msgwin, help, cmdwindow, lines)
    msgwin.text = help[cmdwindow.index]
    msgwin.width = msgwin.width # Necessary to use proper margins
    
    # Ensure minimum height for description
    min_height = (msgwin.borderY rescue 32) + (lines * 32)
    msgwin.height = min_height if msgwin.height < min_height
    
    # Position windows
    msgwin.y = Graphics.height - msgwin.height
    cmdwindow.height = msgwin.y if cmdwindow.height > msgwin.y
  end

  def self.create_text_window(text, lines)
    msgwin2 = pbCreateMessageWindow(nil, nil, lines)
    msgwin2.letterbyletter = false
    msgwin2.setText(text)
    msgwin2.resizeToFit(text)
    msgwin2.y = 0
    msgwin2
  end

  def self.handle_user_input(cmdwindow, msgwin, help, cmd_if_cancel)
    command = 0
    
    loop do
      Graphics.update
      Input.update
      
      old_index = cmdwindow.index
      cmdwindow.update
      
      # Update help text when selection changes
      if old_index != cmdwindow.index
        msgwin.text = help[cmdwindow.index]
      end
      
      msgwin.update
      yield if block_given?
      
      # Handle input
      if Input.trigger?(Input::B)
        if cmd_if_cancel > 0
          command = cmd_if_cancel - 1
          break
        elsif cmd_if_cancel < 0
          command = cmd_if_cancel
          break
        end
      end
      
      if Input.trigger?(Input::C)
        command = cmdwindow.index
        break
      end
      
      pbUpdateSceneMap
    end
    
    command
  end
end

# Backward compatibility - maintain the original function name for existing code
def pbChangeAbility
  AbilityChanger.change_ability
end

# Backward compatibility for UI functions
def pbMessageWithHelpLines(message, commands = nil, help = nil, cmd_if_cancel = 0, skin = nil, default_cmd = 0, lines = 2, &block)
  MessageUI.show_with_help_lines(message, commands, help, cmd_if_cancel, skin, default_cmd, lines, &block)
end

def pbShowCommandsWithHelpAndText(msgwindow, commands, help, cmd_if_cancel = 0, default_cmd = 0, text = '', lines = 2)
  MessageUI.show_commands_with_help_and_text(msgwindow, commands, help, cmd_if_cancel, default_cmd, text, lines)
end
