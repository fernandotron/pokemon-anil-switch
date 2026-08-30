class PokemonPartyScreen
  def pbPokemonMultipleEntryScreenOrder(ruleset)
    annot = []
    statuses = []
    ordinals = [
       _INTL("NO APTO"),
       _INTL("NO ELEGIDO"),
       _INTL("BANEADO"),
       _INTL("PRIMERO"),
       _INTL("SEGUNDO"),
       _INTL("TERCERO"),
       _INTL("CUARTO"),
       _INTL("QUINTO"),
       _INTL("SEXTO")
    ]
    return nil if !ruleset.hasValidTeam?(@party)
    ret = nil
    addedEntry = false
    for i in 0...@party.length
      statuses[i] = (ruleset.isPokemonValid?(@party[i])) ? 1 : 2
    end
    for i in 0...@party.length
      annot[i] = ordinals[statuses[i]]
    end
    @scene.pbStartScene(@party,_INTL("Elige un Pokémon y confirma."),annot,true)
    loop do
      realorder = []
      for i in 0...@party.length
        for j in 0...@party.length
          if statuses[j]==i+3
            realorder.push(j)
            break
          end
        end
      end
      for i in 0...realorder.length
        statuses[realorder[i]] = i+3
      end
      for i in 0...@party.length
        annot[i] = ordinals[statuses[i]]
      end
      @scene.pbAnnotate(annot)
      if realorder.length==ruleset.number && addedEntry
        @scene.pbSelect(6)
      end
      @scene.pbSetHelpText(_INTL("Elige al Pokémon y confirma."))
      pkmnid = @scene.pbChoosePokemon
      addedEntry = false
      if pkmnid==6 # Confirm was chosen
        ret = []
        test_ret = []
        for i in realorder
          ret.push(i)
          test_ret.push(@party[i])
        end
        error = []
        break if ruleset.isValid?(test_ret,error)
        pbDisplay(error[0])
        ret = nil
        test_ret = nil
      end
      break if pkmnid<0 # Canceled
      cmdEntry   = -1
      cmdNoEntry = -1
      cmdSummary = -1
      commands = []
      if (statuses[pkmnid] || 0) == 1
        commands[cmdEntry = commands.length]   = _INTL("Seleccionar")
      elsif (statuses[pkmnid] || 0) > 2
        commands[cmdNoEntry = commands.length] = _INTL("No seleccionar")
      end
      pkmn = @party[pkmnid]
      commands[cmdSummary = commands.length]   = _INTL("Detalles")
      commands[commands.length]                = _INTL("Cancelar")
      command = @scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),commands) if pkmn
      if cmdEntry>=0 && command==cmdEntry
        if realorder.length>=ruleset.number && ruleset.number>0
          pbDisplay(_INTL("No puedes elegir más de {1} Pokémon.",ruleset.number))
        else
          statuses[pkmnid] = realorder.length+3
          addedEntry = true
          pbRefreshSingle(pkmnid)
        end
      elsif cmdNoEntry>=0 && command==cmdNoEntry
        statuses[pkmnid] = 1
        pbRefreshSingle(pkmnid)
      elsif cmdSummary>=0 && command==cmdSummary
        @scene.pbSummary(pkmnid,true)
      end
    end
    @scene.pbEndScene
    return ret
  end
end