#===============================================================================
# Rock Smash
#================================[Item Handler]================================#
if AIFM_RockSmash[:item]
  ItemHandlers::UseFromBag.add(AIFM_RockSmash[:internal_name], proc do |item|
    config_name = AIFM_RockSmash
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_RockSmash[:internal_name], proc do |item|
    config_name = AIFM_RockSmash
    facingEvent = $game_player.pbFacingEvent
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    item_name = GameData::Item.get(config_name[:internal_name]).name
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    $stats.rock_smash_count += 1
    $stats.item_rock_smash_count += 1
    if facingEvent && facingEvent.name[/smashrock/i]
      pbSmashEvent(facingEvent)
      pbRockSmashRandomEncounter
      next true
    else
      pbMessage(_INTL("Aquí no se puede usar."))
      # pbMessage(_INTL("There is no sensible reason why you would be trying to use the \\c[1]{1}\\c[0] now!", item_name))
      next true
    end
  end)
end

#================================[Move Handler]================================#
if AIFM_RockSmash[:move]
  AIFM_RockSmash[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_RockSmash
    move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
        next false
      end
      move_index = pkmn.moves.find_index { |move| move.id == move_name }
      if config_name[:uses_pp]
        if pkmn.moves[move_index].pp == 0
          pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
          next false
        end
      end
      facingEvent = $game_player.pbFacingEvent
      if !facingEvent || ( !facingEvent.name[/smashrock/i] && !facingEvent.name[/RocaRompible/i] )
        pbMessage(_INTL("No puedes usar eso aquí")) if showmsg
        next false
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      config_name = AIFM_RockSmash
      pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
      if config_name[:uses_pp]
        move_index = pokemon.moves.find_index { |move| move.id == move_name }
        pokemon.moves[move_index].pp -= 1
      end
      $stats.rock_smash_count += 1
      $stats.move_rock_smash_count += 1
      facingEvent = $game_player.pbFacingEvent
      if facingEvent
        pbSmashEvent(facingEvent)
        pbRockSmashRandomEncounter
      end
      next true
    })
  end
else
  HiddenMoveHandlers::CanUseMove.delete(:ROCKSMASH)
  HiddenMoveHandlers::UseMove.delete(:ROCKSMASH)
end
#===============================================================================
# Cut
#================================[Item Handler]================================#
if AIFM_Cut[:item]
  ItemHandlers::UseFromBag.add(AIFM_Cut[:internal_name], proc do |item|
    config_name = AIFM_Cut
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_Cut[:internal_name], proc do |item|
    config_name = AIFM_Cut
    facingEvent = $game_player.pbFacingEvent
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    item_name = GameData::Item.get(config_name[:internal_name]).name
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    if facingEvent && facingEvent.name[/cuttree/i]
      facingEvent.start
    else
      pbMessage(_INTL("Aquí no se puede usar."))
      # pbMessage(_INTL("There is no sensible reason why you would be trying to use the \\c[0]{1}\\c[0] now!", item_name))
    end
    next true
  end)
end

#================================[Move Handler]================================#
if AIFM_Cut[:move]
  AIFM_Cut[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_Cut
    move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
        next false
      end
      move_index = pkmn.moves.find_index { |move| move.id == move_name }
      if config_name[:uses_pp]
        if pkmn.moves[move_index].pp == 0
          pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
          next false
        end
      end
      facingEvent = $game_player.pbFacingEvent
      if !facingEvent || !facingEvent.name[/cuttree/i]
        pbMessage(_INTL("Aquí no se puede usar.")) if showmsg
        # pbMessage(_INTL("You can't use that here.")) if showmsg
        next false
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      config_name = AIFM_Cut
      pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
      if config_name[:uses_pp]
        move_index = pokemon.moves.find_index { |move| move.id == move_name }
        pokemon.moves[move_index].pp -= 1
      end
      $stats.cut_count += 1
      $stats.move_cut_count += 1
      facingEvent = $game_player.pbFacingEvent
      pbSmashEvent(facingEvent) if facingEvent
      next true
    })
  end
else
  HiddenMoveHandlers::CanUseMove.delete(:CUT)
  HiddenMoveHandlers::UseMove.delete(:CUT)
end

#===============================================================================
# Ice Smash
#================================[Item Handler]================================#
# if AIFM_IceSmash[:item]
#   ItemHandlers::UseFromBag.add(AIFM_IceSmash[:internal_name], proc do |item|
#     config_name = AIFM_IceSmash
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_IceSmash[:internal_name], proc do |item|
#     config_name = AIFM_IceSmash
#     facingEvent = $game_player.pbFacingEvent
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if facingEvent && facingEvent.name[/breakice/i]
#       facingEvent.start
#       next true
#     end
#     pbMessage(_INTL("There is no sensible reason why you would be trying to use the \\c[0]{1}\\c[0] now!", item_name))
#     next false
#   end)
# end

#================================[Move Handler]================================#
# if AIFM_IceSmash[:move]
#   AIFM_IceSmash[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_IceSmash
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
#           next false
#         end
#       end
#       facingEvent = $game_player.pbFacingEvent
#       if !facingEvent || !facingEvent.name[/breakice/i]
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_IceSmash
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.ice_count += 1
#       $stats.move_ice_count += 1
#       facingEvent = $game_player.pbFacingEvent
#       pbSmashEvent(facingEvent) if facingEvent
#       next true
#     })
#   end
# end

#===============================================================================
# Headbutt
#================================[Item Handler]================================#
if AIFM_Headbutt[:item]
  ItemHandlers::UseFromBag.add(AIFM_Headbutt[:internal_name], proc do |item|
    config_name = AIFM_Headbutt
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_Headbutt[:internal_name], proc do |item|
    config_name = AIFM_Headbutt
    facingEvent = $game_player.pbFacingEvent
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    item_name = GameData::Item.get(config_name[:internal_name]).name
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    if facingEvent && facingEvent.name[/headbutttree/i]
      pbHeadbuttEffect(facingEvent)
    else
      pbMessage(_INTL("Aquí no se puede usar."))
      # pbMessage(_INTL("There is no sensible reason why you would be trying to use the \\c[0]{1}\\c[0] now!", item_name))
    end
    next false
  end)
end

#================================[Move Handler]================================#
if AIFM_Headbutt[:move]
  AIFM_Headbutt[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_Headbutt
    move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
        next false
      end
      move_index = pkmn.moves.find_index { |move| move.id == move_name }
      if config_name[:uses_pp]
        if pkmn.moves[move_index].pp == 0
          pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
          next false
        end
      end
      facingEvent = $game_player.pbFacingEvent
      if !facingEvent || !facingEvent.name[/headbutttree/i]
        pbMessage(_INTL("Aquí no se puede usar.")) if showmsg
        # pbMessage(_INTL("You can't use that here.")) if showmsg
        next false
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      config_name = AIFM_Headbutt
      facingEvent = $game_player.pbFacingEvent
      pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
      if config_name[:uses_pp]
        move_index = pokemon.moves.find_index { |move| move.id == move_name }
        pokemon.moves[move_index].pp -= 1
      end
      $stats.headbutt_count += 1
      $stats.move_headbutt_count += 1
      pbHeadbuttEffect(facingEvent)
      next true
    })
  end
else
  HiddenMoveHandlers::CanUseMove.delete(:HEADBUTT)
  HiddenMoveHandlers::UseMove.delete(:HEADBUTT)
end

#===============================================================================
# Sweet Scent
#================================[Item Handler]================================#
# if AIFM_SweetScent[:item]
#   ItemHandlers::UseFromBag.add(AIFM_SweetScent[:internal_name], proc do |item|
#     config_name = AIFM_SweetScent
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_SweetScent[:internal_name], proc do |item|
#     config_name = AIFM_SweetScent
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#     pbMessage(_INTL("¡\\c[1]{1}\\c[0] used the \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
#     $stats.sweetscent_count += 1
#     $stats.item_sweetscent_count += 1
#     pbSweetScent
#     end)
# end

#================================[Move Handler]================================#
# if AIFM_SweetScent[:move]
#   AIFM_SweetScent[:move_name].each do |move_name|  # repeat over each move name
#     config_name = AIFM_SweetScent
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_SweetScent
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.sweetscent_count += 1
#       $stats.move_sweetscent_count += 1
#       pbSweetScent
#       next true
#     })
#   end
# else
#   HiddenMoveHandlers::CanUseMove.delete(:SWEETSCENT)
#   HiddenMoveHandlers::UseMove.delete(:SWEETSCENT)
# end

#===============================================================================
# Strength
#================================[Item Handler]================================#
if AIFM_Strength[:item]
  ItemHandlers::UseFromBag.add(AIFM_Strength[:internal_name], proc do |item|
    config_name = AIFM_Strength
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_Strength[:internal_name], proc do |item|
    config_name = AIFM_Strength
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    if $PokemonMap.strengthUsed
      pbMessage(_INTL("Ya has usado fuerza."))
      next false
    end
    facingEvent = $game_player.pbFacingEvent
    if facingEvent && facingEvent.name[/strengthboulder/i]
      pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] used the \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
      pbMessage(_INTL("¡Gracias a Fuerza puedes desplazar rocas!"))
      $stats.strength_count += 1
      $stats.item_strength_count += 1
      $PokemonMap.strengthUsed = true
    else
      pbMessage(_INTL("Aquí no se puede usar."))
      # pbMessage(_INTL("There is no sensible reason why you would be trying to use the \\c[0]{1}\\c[0] now!", item_name))
    end
    next true
  end)
end

#================================[Move Handler]================================#
if AIFM_Strength[:move]
  AIFM_Strength[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_Strength
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("Una nueva \\c[1]{1}\\c[0] es necesaria para usar \\c[1]{2}\\c[0] fuera de combate.", config_name[:text_move_badge], name)) if showmsg
        next false
      end
      if $PokemonMap.strengthUsed
        pbMessage(_INTL("Ya has usado fuerza")) if showmsg
        next false
      end
      move_index = pkmn.moves.find_index { |move| move.id == move_name }
      if config_name[:uses_pp]
        if pkmn.moves[move_index].pp == 0
          pbMessage(_INTL("No tienes suficientes \\c[1]PP\\c[0]...")) if showmsg
          next false
        end
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      config_name = AIFM_Strength
      pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
      if config_name[:uses_pp]
        move_index = pokemon.moves.find_index { |move| move.id == move_name }
        pokemon.moves[move_index].pp -= 1
      end
      pbMessage(_INTL("¡Gracias a Fuerza puedes desplazar rocas!"))
      $stats.strength_count += 1
      $stats.move_strength_count += 1
      $PokemonMap.strengthUsed = true
      next true
    })
  end
else
  HiddenMoveHandlers::CanUseMove.delete(:STRENGTH)
  HiddenMoveHandlers::UseMove.delete(:STRENGTH)
end

#===============================================================================
# Flash
#================================[Item Handler]================================#
if AIFM_Flash[:item]
  ItemHandlers::UseFromBag.add(AIFM_Flash[:internal_name], proc do |item|
    config_name = AIFM_Flash
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_Flash[:internal_name], proc do |item|
    config_name = AIFM_Flash
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    if !$game_map.metadata&.dark_map
      pbMessage(_INTL("Aquí no se puede usar."))
      # pbMessage(_INTL("There is no sensible reason why you would be trying to use the {1} now!", item_name))
      next false
    end
    if $PokemonGlobal.flashUsed
      pbMessage(_INTL("Ya has usado el Iluminador."))
      next false
    end
    $stats.flash_count += 1
    $stats.item_flash_count += 1
    pbFlashArea
    next true
  end)
end

#================================[Move Handler]================================#
if AIFM_Flash[:move]
  AIFM_Flash[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_Flash
    move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
        next false
      end
      if !$game_map.metadata&.dark_map
        pbMessage(_INTL("Aquí no se puede usar."))
        # pbMessage(_INTL("You can't use that here.")) if showmsg
        next false
      end
      if $PokemonGlobal.flashUsed
        pbMessage(_INTL("Ya has usado Destello.")) if showmsg
        next false
      end
      move_index = pkmn.moves.find_index { |move| move.id == move_name }
      if config_name[:uses_pp]
        if pkmn.moves[move_index].pp == 0
          pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
          next false
        end
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      config_name = AIFM_Flash
      darkness = $game_temp.darkness_sprite
      next false if !darkness || darkness.disposed?
      pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
      if config_name[:uses_pp]
        move_index = pokemon.moves.find_index { |move| move.id == move_name }
        pokemon.moves[move_index].pp -= 1
      end
      $PokemonGlobal.flashUsed = true
      $stats.flash_count += 1
      $stats.move_flash_count += 1
      pbFlashArea
      next true
    })
  end
else
  HiddenMoveHandlers::CanUseMove.delete(:FLASH)
  HiddenMoveHandlers::UseMove.delete(:FLASH)
end

#===============================================================================
# Defog
#================================[Item Handler]================================#
# if AIFM_Defog[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Defog[:internal_name], proc do |item|
#     config_name = AIFM_Defog
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Defog[:internal_name], proc do |item|
#     config_name = AIFM_Defog
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if $game_screen.weather_type != :Fog
#       pbMessage(_INTL("There is no foggy weather."))
#       next false
#     end
#     $stats.defog_count += 1
#     $stats.item_defog_count += 1
#     pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#     pbMessage(_INTL("¡\\c[1]{1}\\c[0] used the \\c[1]{2}\\c[0]!\nto clear the heavy fog surrounding them.", $player.name, item_name))
#     pbDefog
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Defog[:move]
#   AIFM_Defog[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Defog
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("A new \\c[1]{1}\\c[0] is required to use \\c[1]{2}\\c[0] in the wild.", config_name[:text_move_badge], name)) if showmsg
#         next false
#       end
#       if $game_screen.weather_type != :Fog
#         pbMessage(_INTL("There is no foggy weather.")) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Defog
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.defog_count += 1
#       $stats.move_defog_count += 1
#       pbDefog
#       next true
#     })
#   end
# end

#===============================================================================
# Weather Music
#================================[Event Handler]================================
# if AIFM_Weather[:item] || AIFM_Weather[:move]
#   EventHandlers.add(:on_leave_map, :end_weather,
#   proc { |new_map_id, new_map|
#     next if new_map_id == 0
#     old_map_metadata = $game_map.metadata
#     #next if !old_map_metadata || !old_map_metadata.weather
#     map_infos = pbLoadMapInfos
#     if $game_map.name == map_infos[new_map_id].name
#       new_map_metadata = GameData::MapMetadata.try_get(new_map_id)
#       next if new_map_metadata&.weather
#     end
#     $game_screen.weather(:None, 0, 0)
#     }
#   )
# end

# if AIFM_Pocket1[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Pocket1[:internal_name], proc do |item|
#     config_name = AIFM_Pocket1
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = AIFM_Weather[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCheckForItem(config_name)
#       pbMessage(_INTL("First {1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Pocket1[:internal_name], proc do |item|
#     config_name = AIFM_Pocket1
#     map_metadata = GameData::MapMetadata.try_get($game_map.map_id)
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = AIFM_Weather[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCheckForItem(config_name)
#       pbMessage(_INTL("Second {1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !map_metadata || !map_metadata.outdoor_map
#       pbMessage(_INTL("Can't use the {1} indoors.", item_name))
#       next false
#     end
#     pbFluteMenu
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Weather[:move]
#   AIFM_Weather[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Weather
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       map_metadata = GameData::MapMetadata.try_get($game_map.map_id)
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if !map_metadata || !map_metadata.outdoor_map
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Weather
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       pbWeatherMoveUse(move)
#       $stats.weather_count += 1
#       $stats.move_weather_count += 1
#       next true
#     })
#   end
# end

# #========================[Music Book // Sheets Handler]=========================
# if AIFM_Weather[:item] || AIFM_Weather[:move]
#   ItemHandlers::UseInField.add(AIFM_Weather[:sheetsbookitem], proc { |item|
#     pbMusicBook
#     next 1
#   })
# end
# #===============================================================================
# # Camouflage
# #================================[Event Handler]================================
# if AIFM_Camouflage[:autoDetection] && (AIFM_Camouflage[:item] || AIFM_Camouflage[:move])
#   EventHandlers.add(:on_player_interact, :hiddenFromEvents,
#     proc {
#       facingEvent = $game_player.pbFacingEvent
#       listKeywords = AIFM_Camouflage[:hiddenFromEvents]
#       if $PokemonGlobal.camouflage && facingEvent && !listKeywords.any? { |keyword| facingEvent.name[/#{keyword}/i] }
#           turnVisible
#       end
#     }
#   )

#   EventHandlers.add(:on_player_step_taken_can_transfer, :hiddenFromEvents,
#     proc {
#       facingEvent = $game_player.pbFacingEvent
#       listKeywords = AIFM_Camouflage[:unhideFromEvents]
#       if $PokemonGlobal.camouflage && facingEvent && listKeywords.any? { |keyword| facingEvent.name[/#{keyword}/i] }
#           turnVisible
#       end
#     }
#   )
# end
# #================================[Item Handler]================================#
# if AIFM_Camouflage[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Camouflage[:internal_name], proc do |item|
#     config_name = AIFM_Camouflage
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Camouflage[:internal_name], proc do |item|
#     config_name = AIFM_Camouflage
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$game_player.can_ride_vehicle_with_follower?
#       pbMessage(_INTL("It can't be used when you have someone with you."))
#       next false
#     end
#     if $PokemonGlobal.bicycle
#       pbMessage(_INTL("You can't use the \\c[0]{1}\\c[0] to turn invisible, while cycling.",item_name))
#       next false
#     end
#     if $PokemonGlobal.surfing
#       pbMessage(_INTL("You can't use the \\c[0]{1}\\c[0] to turn invisible, while surfing.",item_name))
#       next false
#     end
#     pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#     if $PokemonGlobal.camouflage
#       pbMessage(_INTL("\\c[0]{1}\\c[0] took off the \\c[0]{2}\\c[0] to turn visible!",$player.name ,item_name)) unless $PokemonSystem.animation_item == 1
#       $camouflage_check = true
#     else
#       pbMessage(_INTL("\\c[0]{1}\\c[0] put on the \\c[0]{2}\\c[0] to turn invisible!",$player.name ,item_name)) unless $PokemonSystem.animation_item == 1
#       $camouflage_check = false
#     end
#     $stats.camouflage_count += 1
#     $stats.item_camouflage_count += 1
#     pbVanishCheck
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Camouflage[:move]
#   AIFM_Camouflage[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Camouflage
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if !$game_player.can_ride_vehicle_with_follower?
#         pbMessage(_INTL("It can't be used when you have someone with you."))
#         next false
#       end
#       if $PokemonGlobal.bicycle
#         pbMessage(_INTL("You can't use \\c[0]{1}\\c[0] to turn invisible, while cycling.", GameData::Move.get(move).name))
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Camouflage
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       if !$PokemonGlobal.camouflage
#         pbMessage(_INTL("\\c[0]{1}\\c[0] used \\c[0]{2}\\c[0] to turn \\c[0]{3}\\c[0] and itself invisible!",pokemon.name, GameData::Move.get(move).name, $player.name)) unless $PokemonSystem.animation_move == 1
#         $camouflage_check = false
#       else
#         pbMessage(_INTL("\\c[0]{1}\\c[0] removed the \\c[0]{2}\\c[0] to turn \\c[0]{3}\\c[0] and itself visible!",pokemon.name, GameData::Move.get(move).name, $player.name)) unless $PokemonSystem.animation_move == 1
#         $camouflage_check = true
#       end
#       if config_name[:uses_pp] && $PokemonGlobal.camouflage == false
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.camouflage_count += 1
#       $stats.move_camouflage_count += 1
#       pbVanishCheck
#       next true
#     })
#   end
# end

#===============================================================================
# Surf
#================================[Event Handler]===============================#
EventHandlers.add(:on_player_interact, :start_surfing,
  proc {
    next if $PokemonGlobal.surfing
    next if $game_map.metadata&.always_bicycle
    next if !$game_player.pbFacingTerrainTag.can_surf_freely
    next if !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
    pbSurf
  }
)

#================================[Item Handler]================================#
if AIFM_Surf[:item]
  ItemHandlers::UseFromBag.add(AIFM_Surf[:internal_name], proc do |item|
    config_name = AIFM_Surf
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      echoln "show_message #{config_name[:show_message]}"
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name)) if config_name[:show_message]
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_Surf[:internal_name], proc do |item|
    config_name = AIFM_Surf
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    if $PokemonGlobal.surfing
      pbMessage(_INTL("Ya estás surfeando."))
      next false
    end
    if !$game_player.can_ride_vehicle_with_follower?
      pbMessage(_INTL("It can't be used when you have someone with you."))
      next false
    end
    if GameData::MapMetadata.exists?($game_map.map_id) &&
      GameData::MapMetadata.get($game_map.map_id).always_bicycle
      pbMessage(_INTL("¡Disfrutemos del ciclismo!")) 
      next false
    end
    if !$game_player.pbFacingTerrainTag.can_surf_freely ||
      !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
      pbMessage(_INTL("Aquí no se puede usar."))
      # pbMessage(_INTL("You can't use the \\c[0]{1}\\c[0] here!", item_name))
      next false
    end
    pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
    $stats.item_surf_count += 1
    pbStartSurfing
    next true
  end)
end

#================================[Move Handler]================================#
if AIFM_Surf[:move]
  AIFM_Surf[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_Surf
    move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
        next false
      end
      if $PokemonGlobal.surfing
        pbMessage(_INTL("Ya estás surfeando.")) if showmsg
        next false
      end
      if !$game_player.can_ride_vehicle_with_follower?
        pbMessage(_INTL("No se puede usar cuando hay alguien contigo.")) if showmsg
        next false
      end
      if $game_map.metadata&.always_bicycle
        pbMessage(_INTL("¡Disfrutemos del ciclismo!")) if showmsg
        next false
      end
      if !$game_player.pbFacingTerrainTag.can_surf_freely ||
         !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
         pbMessage(_INTL("Aquí no se puede usar.")) if showmsg
        next false
      end
      move_index = pkmn.moves.find_index { |move| move.id == move_name }
      if config_name[:uses_pp]
        if pkmn.moves[move_index].pp == 0
          pbMessage(_INTL("No tienes suficientes \\c[1]PP\\c[0]...")) if showmsg
          next false
        end
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      config_name = AIFM_Surf
      pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
      mount = ow_mount(pokemon)
      $PokemonGlobal.base_pkmn_surf = mount
      if config_name[:uses_pp]
        move_index = pokemon.moves.find_index { |move| move.id == move_name }
        pokemon.moves[move_index].pp -= 1
      end
      $stats.move_surf_count += 1
      pbStartSurfing
      next true
    })
  end
else
  HiddenMoveHandlers::CanUseMove.delete(:SURF)
  HiddenMoveHandlers::UseMove.delete(:SURF)
end

#===============================================================================
# Dive
#================================[Event Handler]===============================#
# EventHandlers.add(:on_player_interact, :diving,
#   proc {
#     if $PokemonGlobal.diving
#       surface_map_id = nil
#       GameData::MapMetadata.each do |map_data|
#         next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
#         surface_map_id = map_data.id
#         break
#       end
#       if surface_map_id &&
#          $map_factory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
#         pbSurfacing
#       end
#     elsif $game_player.terrain_tag.can_dive
#       pbDive
#     end
#   }
# )

#================================[Item Handler]================================#
# if AIFM_Dive[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Dive[:internal_name], proc do |item|
#     config_name = AIFM_Dive
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Dive[:internal_name], proc do |item|
#     config_name = AIFM_Dive
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if (!$PokemonGlobal.diving && !$game_map.metadata&.dive_map_id) || (($PokemonGlobal.diving || !$PokemonGlobal.surfing) && $game_map.metadata&.dive_map_id)
#       pbMessage(_INTL("There is no sensible reason why you would be trying to use the \\c[0]{1}\\c[0] now!", item_name))
#       next false
#     end
#     if $PokemonGlobal.diving
#       surface_map_id = nil
#       GameData::MapMetadata.each do |map_data|
#         next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
#         surface_map_id = map_data.id
#         break
#       end
#       if !surface_map_id || !$map_factory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
#         pbMessage(_INTL("You can't use that here."))
#         next false
#       end
#     else
#       if !$game_map.metadata&.dive_map_id || !$game_player.terrain_tag.can_dive
#         pbMessage(_INTL("You can't use that here."))
#         next false
#       end
#     end
#     wasdiving = $PokemonGlobal.diving
#     if $PokemonGlobal.diving
#       dive_map_id = nil
#       GameData::MapMetadata.each do |map_data|
#         next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
#         dive_map_id = map_data.id
#         break
#       end
#     else
#       dive_map_id = $game_map.metadata&.dive_map_id
#     end
#     next false if !dive_map_id
#     pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#     pbMessage(_INTL("¡\\c[1]{1}\\c[0] used the \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
#     $stats.dive_count += 1 unless wasdiving
#     $stats.dive_descend_count += 1 unless wasdiving
#     $stats.item_dive_descend_count += 1 unless wasdiving
#     $stats.dive_ascend_count += 1 unless !wasdiving
#     $stats.item_dive_ascend_count += 1 unless !wasdiving
#     pbFadeOutIn {
#       $game_temp.player_new_map_id    = dive_map_id
#       $game_temp.player_new_x         = $game_player.x
#       $game_temp.player_new_y         = $game_player.y
#       $game_temp.player_new_direction = $game_player.direction
#       $PokemonGlobal.surfing = wasdiving
#       $PokemonGlobal.diving  = !wasdiving
#       pbUpdateVehicle
#       $scene.transfer_player(false)
#       $game_map.autoplay
#       $game_map.refresh
#     }
#     next true
#   end)
# end

#================================[Move Handler]================================#
# if AIFM_Dive[:move]
#   AIFM_Dive[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Dive
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if $PokemonGlobal.diving
#         surface_map_id = nil
#         GameData::MapMetadata.each do |map_data|
#           next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
#           surface_map_id = map_data.id
#           break
#         end
#         if !surface_map_id || !$map_factory.getTerrainTag(surface_map_id, $game_player.x, $game_player.y).can_dive
#           pbMessage(_INTL("You can't use that here.")) if showmsg
#           next false
#         end
#       else
#         if !$game_map.metadata&.dive_map_id || !$game_player.terrain_tag.can_dive
#           pbMessage(_INTL("You can't use that here.")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Dive
#       wasdiving = $PokemonGlobal.diving
#       if $PokemonGlobal.diving
#         dive_map_id = nil
#         GameData::MapMetadata.each do |map_data|
#           next if !map_data.dive_map_id || map_data.dive_map_id != $game_map.map_id
#           dive_map_id = map_data.id
#           break
#         end
#       else
#         dive_map_id = $game_map.metadata&.dive_map_id
#       end
#       next false if !dive_map_id
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1 if wasdiving
#       end
#       $stats.dive_count += 1 unless wasdiving
#       $stats.dive_descend_count += 1 unless wasdiving
#       $stats.move_dive_descend_count += 1 unless wasdiving
#       $stats.dive_ascend_count += 1 unless !wasdiving
#       $stats.move_dive_ascend_count += 1 unless !wasdiving
#       $PokemonGlobal.divingpkmn = false
#       mount = ow_mount(pokemon)
#       $PokemonGlobal.base_pkmn_dive = mount
#       pbFadeOutIn do
#         $game_temp.player_new_map_id    = dive_map_id
#         $game_temp.player_new_x         = $game_player.x
#         $game_temp.player_new_y         = $game_player.y
#         $game_temp.player_new_direction = $game_player.direction
#         $PokemonGlobal.surfing = wasdiving
#         $PokemonGlobal.diving  = !wasdiving
#         pbUpdateVehicle
#         $scene.transfer_player(false)
#         $game_map.autoplay
#         $game_map.refresh
#       end
#       next true
#     })
#   end
# else
#   HiddenMoveHandlers::CanUseMove.delete(:DIVE)
#   HiddenMoveHandlers::UseMove.delete(:DIVE)
# end

#===============================================================================
# Waterfall
#================================[Item Handler]================================#
# EventHandlers.add(:on_player_interact, :waterfall,
#   proc {
#     terrain = $game_player.pbFacingTerrainTag
#     if terrain.waterfall
#       pbWaterfall
#     elsif terrain.waterfall_crest
#       pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
#     end
#   }
# )

# if AIFM_Waterfall[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Waterfall[:internal_name], proc do |item|
#     config_name = AIFM_Waterfall
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Waterfall[:internal_name], proc do |item|
#     config_name = AIFM_Waterfall
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.waterfall && $PokemonGlobal.surfing
#       pbMessage(_INTL("You can't use that here."))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.waterfall && !$PokemonGlobal.surfing
#       pbMessage(_INTL("There is no sednsible reason why you would be trying to use the {1} now!", item_name))
#       next false
#     end
#     if $PokemonGlobal.surfing
#       $stats.item_waterfall_count += 1
#       pbAscendWaterfall
#       next true
#     else
#       pbMessage(_INTL("You can use {1} here!", item_name))
#       next false
#     end
#   end)
# end

#================================[Move Handler]================================#
# if AIFM_Waterfall[:move]
#   AIFM_Waterfall[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Waterfall
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if !$game_player.pbFacingTerrainTag.waterfall
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Waterfall
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       if $PokemonGlobal.surfing
#         $stats.move_waterfall_count += 1
#         pbAscendWaterfall
#         next true
#       else
#         pbMessage(_INTL("You can use {1} here!", item_name))
#         next false
#       end
#     })
#   end
# else
#   HiddenMoveHandlers::CanUseMove.delete(:WATERFALL)
#   HiddenMoveHandlers::UseMove.delete(:WATERFALL)
# end

#===============================================================================
# Whirlpool
#================================[Event Handler]===============================#
# EventHandlers.add(:on_player_interact, :whirlpool,
#   proc {
#     config_name = AIFM_Whirlpool
#     if $game_player.pbFacingTerrainTag.whirlpool && $PokemonGlobal.surfing
#       if (pbCanUseItem(config_name) && config_name[:item]) || (pbCanUseMove(config_name) && config_name[:move])
#         pbWhirlpool
#       end
#       next false
#     end
#   }
# )

# #================================[Item Handler]================================#
# if AIFM_Whirlpool[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Whirlpool[:internal_name], proc do |item|
#     config_name = AIFM_Whirlpool
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Whirlpool[:internal_name], proc do |item|
#     config_name = AIFM_Whirlpool
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.whirlpool && $PokemonGlobal.surfing
#       pbMessage(_INTL("You can't use that here."))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.whirlpool && !$PokemonGlobal.surfing
#       pbMessage(_INTL("There is no sednsible reason why you would be trying to use the {1} now!", item_name))
#       next false
#     end
#     $stats.move_whirlpool_cross_count += 1
#     pbWhirlpoolMove
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Whirlpool[:move]
#   AIFM_Whirlpool[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Whirlpool
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !$game_player.pbFacingTerrainTag.whirlpool
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("A new \\c[1]{1}\\c[0] is required to use \\c[1]{2}\\c[0] in the wild.", config_name[:text_move_badge], name)) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Whirlpool
#       if pbCanUseMove(config_name)
#         pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#         pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       end
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.move_whirlpool_cross_count += 1
#       pbWhirlpoolMove
#       next true
#     })
#   end
# end

#===============================================================================
# Fly
#================================[Item Handler]================================#
# if AIFM_Fly[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Fly[:internal_name], proc do |item|
#     config_name = AIFM_Fly
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Fly[:internal_name], proc do |item|
#     config_name = AIFM_Fly
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$game_map.metadata&.outdoor_map
#       pbMessage(_INTL("You can't use the \\c[0]{1}\\c[0] when you are inside.", item_name))
#       next false
#     end
#     if !$game_player.can_map_transfer_with_follower?
#       pbMessage(_INTL("It can't be used when you have someone with you."))
#       next false
#     end
#     scene = PokemonRegionMap_Scene.new(-1, false)
#     screen = PokemonRegionMapScreen.new(scene)
#     ret = screen.pbStartFlyScreen
#     if ret
#       $game_temp.fly_destination = ret
#     end
#     if $game_temp.fly_destination.nil?
#       pbMessage(_INTL("You can't use that here."))
#       next false
#     end
#     pbFlyToNewLocation($player, item_name)
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Fly[:move]
#   AIFM_Fly[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Fly
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if !$game_map.metadata&.outdoor_map
#         pbMessage(_INTL("You can't use the \\c[0]{1}\\c[0] when you are inside.", move_name)) if showmsg
#         next false
#       end
#       if !$game_player.can_ride_vehicle_with_follower?
#         pbMessage(_INTL("It can't be used when you have someone with you."))
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Fly
#       if $game_temp.fly_destination.nil?
#         pbMessage(_INTL("You can't use that here."))
#         next false
#       end
#       pbFlyToNewLocation(pokemon, move)
#       next true
#     })
#   end
# else
#   HiddenMoveHandlers::CanUseMove.delete(:FLY)
#   HiddenMoveHandlers::UseMove.delete(:FLY)
# end

#===============================================================================
# Dig
#================================[Item Handler]================================#
# if AIFM_Dig[:item]
#   ItemHandlers::ConfirmUseInField.add(AIFM_Dig[:internal_name], proc { |item|
#     escape = ($PokemonGlobal.escapePoint rescue nil)
#     next false if !escape || escape == []
#     mapname = pbGetMapNameFromId(escape[0])
#     next pbConfirmMessage(_INTL("Want to escape from here and return to \\c[0]{1}\\c[0]?", mapname))
#   })

#   ItemHandlers::UseFromBag.add(AIFM_Dig[:internal_name], proc do |item|
#     config_name = AIFM_Dig
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     escape = ($PokemonGlobal.escapePoint rescue nil)
#     next 0 if !escape || escape == []
#     mapname = pbGetMapNameFromId(escape[0])
#     next 0 unless pbConfirmMessage(_INTL("Want to escape from here and return to \\c[0]{1}\\c[0]?", mapname))
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Dig[:internal_name], proc do |item|
#     config_name = AIFM_Dig
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     escape = ($PokemonGlobal.escapePoint rescue nil)
#     if !escape || escape == []
#       pbMessage(_INTL("You can't use that here."))
#       next false
#     end
#     if !$game_player.can_map_transfer_with_follower?
#       pbMessage(_INTL("It can't be used when you have someone with you."))
#       next false
#     end
#     pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#     pbMessage(_INTL("¡\\c[1]{1}\\c[0] used the \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
#     $stats.dig_count += 1
#     $stats.item_dig_count += 1
#     pbAllowDig
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Dig[:move]
#   AIFM_Dig[:move_name].each do |move_name|  # repeat over each move name
#     config_name = AIFM_Dig
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       escape = ($PokemonGlobal.escapePoint rescue nil)
#       if !escape || escape == []
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#       if !$game_player.can_map_transfer_with_follower?
#         pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Dig
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.dig_count += 1
#       $stats.move_dig_count += 1
#       pbAllowDig
#       next true
#     })
#   end
# else
#   HiddenMoveHandlers::CanUseMove.delete(:DIG)
#   HiddenMoveHandlers::UseMove.delete(:DIG)
# end

#===============================================================================
# Teleport
#================================[Item Handler]================================#
# if AIFM_Teleport[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Teleport[:internal_name], proc do |item|
#     config_name = AIFM_Teleport
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     if !AIFM_Teleport[:behav_as_fly]
#       healing = $PokemonGlobal.healingSpot
#       healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
#       healing = GameData::Metadata.get.home if !healing   # Home
#       next 0 if !healing
#       mapname = pbGetMapNameFromId(healing[0])
#       next 0 unless pbConfirmMessage(_INTL("Want to return to the healing spot used last in \\c[0]{1}\\c[0]?", mapname))
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Teleport[:internal_name], proc do |item|
#     config_name = AIFM_Teleport
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$game_map.metadata&.outdoor_map
#       pbMessage(_INTL("You can't use the \\c[0]{1}\\c[0] when you are inside.", item_name))

#       next false
#     end
#     if !AIFM_Teleport[:behav_as_fly]
#       healing = $PokemonGlobal.healingSpot
#       healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
#       healing = GameData::Metadata.get.home if !healing   # Home
#       if !healing
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#     end
#     if !$game_player.can_map_transfer_with_follower?
#       pbMessage(_INTL("It can't be used when you have someone with you."))
#       next false
#     end
#     if !AIFM_Teleport[:behav_as_fly]
#       pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used the \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
#       $stats.teleport_count += 1
#       $stats.item_teleport_count += 1
#       pbAllowTeleport
#     else
#       scene = PokemonRegionMap_Scene.new(-1, false)
#       screen = PokemonRegionMapScreen.new(scene)
#       ret = screen.pbStartFlyScreen
#       if ret
#         $game_temp.fly_destination = ret
#       end
#       if $game_temp.fly_destination.nil?
#         pbMessage(_INTL("You can't use that here."))
#         next false
#       end
#       pbFlyToNewLocation($player, item_name)
#     end
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Teleport[:move]
#   if !AIFM_Teleport[:behav_as_fly] # IS FALSE
#     AIFM_Teleport[:move_name].each do |move_name|  # repeat over each move name
#       HiddenMoveHandlers::ConfirmUseMove.add(move_name, proc { |move, pkmn|
#       healing = $PokemonGlobal.healingSpot
#       healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
#       healing = GameData::Metadata.get.home if !healing   # Home
#       next false if !healing
#       mapname = pbGetMapNameFromId(healing[0])
#       next pbConfirmMessage(_INTL("Want to return to the healing spot used last in \\c[0]{1}\\c[0]?", mapname))
#       })
#     end
#   else # Is True
#     HiddenMoveHandlers::ConfirmUseMove.delete(:TELEPORT)
#   end

#   AIFM_Teleport[:move_name].each do |move_name|  # repeat over each move name
#     config_name = AIFM_Teleport
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if !$game_map.metadata&.outdoor_map
#         pbMessage(_INTL("You can't use the \\c[1]{1}\\c[0] when you are inside.", name)) if showmsg
#         next false
#       end
#       if !AIFM_Teleport[:behav_as_fly]
#         healing = $PokemonGlobal.healingSpot
#         healing = GameData::PlayerMetadata.get($player.character_ID)&.home if !healing
#         healing = GameData::Metadata.get.home if !healing   # Home
#         if !healing
#           pbMessage(_INTL("You can't use that here.")) if showmsg
#           next false
#         end
#       end
#       if !$game_player.can_map_transfer_with_follower?
#         pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Teleport
#       if !AIFM_Teleport[:behav_as_fly]
#         pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#         pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#         if config_name[:uses_pp]
#           move_index = pokemon.moves.find_index { |move| move.id == move_name }
#           pokemon.moves[move_index].pp -= 1
#         end
#         $stats.teleport_count += 1
#         $stats.move_teleport_count += 1
#         pbAllowTeleport
#       else
#         scene = PokemonRegionMap_Scene.new(-1, false)
#         screen = PokemonRegionMapScreen.new(scene)
#         ret = screen.pbStartFlyScreen
#         if ret
#           $game_temp.fly_destination = ret
#         end
#         if $game_temp.fly_destination.nil?
#           pbMessage(_INTL("You can't use that here."))
#           next false
#         end
#         pbFlyToNewLocation(pokemon, move)
#       end
#       next true
#     })
#   end
# else
#   HiddenMoveHandlers::CanUseMove.delete(:TELEPORT)
#   HiddenMoveHandlers::UseMove.delete(:TELEPORT)
# end

#===============================================================================
# Rock Climb | pbRockClimb > pbStartRockClimb > automove > pbEndRockClimb
#================================[Event Handler]===============================#
  EventHandlers.add(:on_player_interact, :rockclimb,
    proc {
      terrain = $game_player.pbFacingTerrainTag
      if terrain.rockclimb && !$PokemonGlobal.rockclimb
        pbRockClimb
      end
      }
    )

    # Do things after a jump to start/end rockclimb.
  EventHandlers.add(:on_step_taken, :rockclimb_jump,
    proc { |event|
      next if !$scene.is_a?(Scene_Map) || !event.is_a?(Game_Player)
      next if !$game_temp.rockclimb_base_coords
      # Hide the temporary surf base graphic after jumping onto/off it
      $game_temp.rockclimb_base_coords = nil
      # Finish up dismounting from surfing
      if $game_temp.ending_rockclimb
        pbCancelVehicles
        $game_map.autoplayAsCue
        $game_temp.ending_rockclimb = false
      end
    }
  )
#================================[Item Handler]================================#
if AIFM_RockClimb[:item]
  ItemHandlers::UseFromBag.add(AIFM_RockClimb[:internal_name], proc do |item|
    config_name = AIFM_RockClimb
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next 0
    end
    next 2
  end)

  ItemHandlers::UseInField.add(AIFM_RockClimb[:internal_name], proc do |item|
    config_name = AIFM_RockClimb
    item_name = GameData::Item.get(config_name[:internal_name]).name
    item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
    if !pbCanUseItem(config_name)
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
      next false
    end
    if !$game_player.pbFacingTerrainTag.rockclimb
      pbMessage(_INTL("Aquí no se puede usar."))
      next false
    end
    $stats.item_rockclimb_count += 1
    pbStartRockClimb
    next true
  end)
end

#================================[Move Handler]================================#
if AIFM_RockClimb[:move]
  AIFM_RockClimb[:move_name].each do |move_name|  # iterate over each move name
    config_name = AIFM_RockClimb
    HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
      if !pbCanUseMove(config_name)
        name = GameData::Move.get(move_name).name
        pbMessage(_INTL("Necesitas una nueva \\c[1]{1}\\c[0] para usar \\c[1]{2}\\c[0] fuera de combate.", config_name[:text_move_badge], name)) if showmsg
        next false
      end
      if !$game_player.pbFacingTerrainTag.rockclimb
        pbMessage(_INTL("Aquí no se puede usar")) if showmsg
        next false
      end
      move_index = pkmn.moves.find_index { |move| move.id == move_name }
      if config_name[:uses_pp]
        if pkmn.moves[move_index].pp == 0
          pbMessage(_INTL("No tienes suficientes \\c[1]PP\\c[0]...")) if showmsg
          next false
        end
      end
      next true
    })

    HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
      config_name = AIFM_RockClimb
      if pbCanUseMove(config_name)
        pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
        pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
      end
      if config_name[:uses_pp]
        move_index = pokemon.moves.find_index { |move| move.id == move_name }
        pokemon.moves[move_index].pp -= 1
      end
      $stats.move_rockclimb_count += 1
      mount = ow_mount(pokemon)
      $PokemonGlobal.base_pkmn_rockclimb = mount
      pbStartRockClimb
      next true
    })
  end
end

#===============================================================================
# Lifting Object
#================================[Event Handler]===============================#
# if AIFM_Lift[:item] || AIFM_Lift[:move]
#   EventHandlers.add(:on_player_step_taken, :lift_rock,
#     proc { |event|
#       next if !$scene.is_a?(Scene_Map) || !event.is_a?(Game_Player)
#       if $game_player.lifted_event
#         $game_player.lifted_event.moveto($game_player.x, $game_player.y - 1)
#       end
#     }
#   )

#   EventHandlers.add(:on_leave_map, :delete_lifted_object,
#     proc {
#       if $game_player.lifted_event
#         $game_player.lifted_event = nil
#         $game_player.lifted_event_down = nil
#         $PokemonGlobal.lifting = false
#       end
#     }
#   )
# end
# #================================[Item Handler]================================#
# if AIFM_Lift[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Lift[:internal_name], proc do |item|
#     config_name = AIFM_Lift
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Lift[:internal_name], proc do |item|
#     config_name = AIFM_Lift
#     facingEvent = $game_player.pbFacingEvent
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if $PokemonMap.liftUsed
#       pbMessage(_INTL("{1} is already being used.", item_name))
#       next false
#     end
#     if facingEvent && facingEvent.name[/pickup/i]
#       facingEvent.start
#       next true
#     end
#     next false
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Lift[:move]
#   AIFM_Lift[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Lift
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if $PokemonMap.liftUsed
#         pbMessage(_INTL("{1} is already being used."), name) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
#           next false
#         end
#       end
#       facingEvent = $game_player.pbFacingEvent
#       if !facingEvent || !facingEvent.name[/pickup/i]
#         pbMessage(_INTL("Why would you try to lift now?")) if showmsg
#         next false
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Lift
#       facingEvent = $game_player.pbFacingEvent
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       facingEvent.start
#       next true
#     })
#   end
# end

#===============================================================================
# Lava Fishing
#================================[Event Handler]===============================#
# ItemHandlers::UseInField.add(:SPEICALROD, proc { |item|
#   notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
#   canFish = $game_player.pbFacingTerrainTag.can_fish || $game_player.pbFacingTerrainTag.can_lavafish
#   canSurf = ($PokemonGlobal.surfing || $PokemonGlobal.lavasurfing) || notCliff
#   if !canFish || !canSurf
#     pbMessage(_INTL("Can't use that here."))
#     next false
#   end
#   encounter = $PokemonEncounters.has_encounter_type?(:LavaRod)
#   if pbLavaFishing(encounter, 3)
#     $stats.fishing_battles += 1
#     pbEncounter(:LavaRod)
#   end
#   next true
# })

#===============================================================================
# Lava Surf
#================================[Event Handler]===============================#
# EventHandlers.add(:on_player_interact, :start_lavasurfing,
#   proc {
#     next if $PokemonGlobal.lavasurfing
#     next if $game_map.metadata&.always_bicycle
#     next if !$game_player.pbFacingTerrainTag.can_lavasurf_freely
#     next if !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
#     pbLavaSurf
#   }
# )

# # Do things after a jump to start/end surfing.
# EventHandlers.add(:on_step_taken, :lavasurf_jump,
#   proc { |event|
#     next if !$scene.is_a?(Scene_Map) || !event.is_a?(Game_Player)
#     next if !$game_temp.lavasurf_base_coords
#     # Hide the temporary surf base graphic after jumping onto/off it
#     $game_temp.lavasurf_base_coords = nil
#     # Finish up dismounting from surfing
#     if $game_temp.ending_lavasurf
#       pbCancelVehicles
#       $PokemonEncounters.reset_step_count
#       $game_map.autoplayAsCue   # Play regular map BGM
#       $game_temp.ending_lavasurf = false
#     end
#   }
# )

# #================================[Item Handler]================================#
# if AIFM_LavaSurf[:item]
#   ItemHandlers::UseFromBag.add(AIFM_LavaSurf[:internal_name], proc do |item|
#     config_name = AIFM_LavaSurf
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_LavaSurf[:internal_name], proc do |item|
#     config_name = AIFM_LavaSurf
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if $PokemonGlobal.lavasurfing
#       pbMessage(_INTL("You're already lavasurfing."))
#       next false
#     end
#     if !$game_player.can_ride_vehicle_with_follower?
#       pbMessage(_INTL("It can't be used when you have someone with you."))
#       next false
#     end
#     if GameData::MapMetadata.exists?($game_map.map_id) &&
#       GameData::MapMetadata.get($game_map.map_id).always_bicycle
#       pbMessage(_INTL("Let's enjoy cycling!"))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.can_lavasurf_freely ||
#       !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
#       pbMessage(_INTL("You can't use the \\c[0]{1}\\c[0] here!", item_name))
#       next false
#     end
#     pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#     $stats.item_lavasurf_count += 1
#     pbStartLavaSurfing
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_LavaSurf[:move]
#   AIFM_LavaSurf[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_LavaSurf
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if $PokemonGlobal.lavasurfing
#         pbMessage(_INTL("You're already lavasurfing.")) if showmsg
#         next false
#       end
#       if !$game_player.can_ride_vehicle_with_follower?
#         pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
#         next false
#       end
#       if $game_map.metadata&.always_bicycle
#         pbMessage(_INTL("Let's enjoy cycling!")) if showmsg
#         next false
#       end
#       if !$game_player.pbFacingTerrainTag.can_lavasurf_freely ||
#          !$game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
#         pbMessage(_INTL("You can't use the {1} here!", move_name)) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_LavaSurf
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       mount = ow_mount(pokemon)
#       $PokemonGlobal.base_pkmn_lavasurf = mount
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.move_lavasurf_count += 1
#       pbStartLavaSurfing
#       next true
#     })
#   end
# end

#===============================================================================
# Lavafall
#================================[Item Handler]================================#
# EventHandlers.add(:on_player_interact, :lavafall,
#   proc {
#     terrain = $game_player.pbFacingTerrainTag
#     if terrain.lavafall
#       pbLavafall
#     elsif terrain.lavafall_crest
#       pbMessage(_INTL("A wall of lava is crashing down with a mighty roar."))
#     end
#   }
# )

# if AIFM_Lavafall[:item]
#   ItemHandlers::UseFromBag.add(AIFM_Lavafall[:internal_name], proc do |item|
#     config_name = AIFM_Lavafall
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_Lavafall[:internal_name], proc do |item|
#     config_name = AIFM_Lavafall
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.lavafall && $PokemonGlobal.lavasurfing
#       pbMessage(_INTL("You can't use that here."))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.lavafall && !$PokemonGlobal.lavasurfing
#       pbMessage(_INTL("There is no sednsible reason why you would be trying to use the {1} now!", item_name))
#       next false
#     end
#     if $PokemonGlobal.lavasurfing
#       $stats.item_lavafall_count += 1
#       pbAscendLavafall
#       next true
#     else
#       pbMessage(_INTL("You can't use {1} here!", item_name))
#       next false
#     end
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_Lavafall[:move]
#   AIFM_Lavafall[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_Lavafall
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       if !$game_player.pbFacingTerrainTag.lavafall
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_Lavafall
#       pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       if $PokemonGlobal.lavasurfing
#         $stats.move_lavafall_count += 1
#         pbAscendLavafall
#         next true
#       else
#         pbMessage(_INTL("You can't use {1} here!", item_name))
#         next false
#       end
#     })
#   end
# end

#===============================================================================
# Lava Swirl
#================================[Event Handler]===============================#
# EventHandlers.add(:on_player_interact, :lavaswirl,
#   proc {
#     config_name = AIFM_LavaSwirl
#     if $game_player.pbFacingTerrainTag.lavaswirl && $PokemonGlobal.lavasurfing
#       if (pbCanUseItem(config_name) && config_name[:item]) || (pbCanUseMove(config_name) && config_name[:move])
#         pbLavaSwirl
#       end
#       next false
#     end
#   }
# )

# #================================[Item Handler]================================#
# if AIFM_LavaSwirl[:item]
#   ItemHandlers::UseFromBag.add(AIFM_LavaSwirl[:internal_name], proc do |item|
#     config_name = AIFM_LavaSwirl
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_LavaSwirl[:internal_name], proc do |item|
#     config_name = AIFM_LavaSwirl
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.lavaswirl && $PokemonGlobal.lavasurfing
#       pbMessage(_INTL("You can't use that here."))
#       next false
#     end
#     if !$game_player.pbFacingTerrainTag.lavaswirl && !$PokemonGlobal.lavasurfing
#       pbMessage(_INTL("There is no sednsible reason why you would be trying to use the {1} now!", item_name))
#       next false
#     end
#     $stats.item_lavaswirl_cross_count += 1
#     pbLavaSwirlMove
#     next true
#   end)
# end

# #================================[Move Handler]================================#
# if AIFM_LavaSwirl[:move]
#   AIFM_LavaSwirl[:move_name].each do |move_name|  # iterate over each move name
#     config_name = AIFM_LavaSwirl
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !$game_player.pbFacingTerrainTag.lavaswirl
#         pbMessage(_INTL("You can't use that here.")) if showmsg
#         next false
#       end
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("A new \\c[1]{1}\\c[0] is required to use \\c[1]{2}\\c[0] in the wild.", config_name[:text_move_badge], name)) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("Not enough \\c[1]PP\\c[0]...")) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_LavaSwirl
#       if pbCanUseMove(config_name)
#         pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#         pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#       end
#       if config_name[:uses_pp]
#         move_index = pokemon.moves.find_index { |move| move.id == move_name }
#         pokemon.moves[move_index].pp -= 1
#       end
#       $stats.move_lavaswirl_cross_count += 1
#       pbLavaSwirlMove
#       next true
#     })
#   end
# end

#===============================================================================
# Reveal Truth || Unmask
#================================[Event Handler]===============================#
# EventHandlers.add(:on_player_step_taken, :decrement_reveal_step_count,
#   proc { |event|
#     $PokemonGlobal.revealstepcount = [$PokemonGlobal.revealstepcount - 1, 0].max
#     if $PokemonGlobal.revealstepcount == 0
#       $PokemonGlobal.revealtruth = false
#     end
#   }
# )
#================================[Item Handler]================================#
# if AIFM_SenseTruth[:item]
#   ItemHandlers::UseFromBag.add(AIFM_SenseTruth[:internal_name], proc do |item|
#     config_name = AIFM_SenseTruth
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next 0
#     end
#     next 2
#   end)

#   ItemHandlers::UseInField.add(AIFM_SenseTruth[:internal_name], proc do |item|
#     config_name = AIFM_SenseTruth
#     item_name = GameData::Item.get(config_name[:internal_name]).name
#     item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
#     if !pbCanUseItem(config_name)
#       pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
#       next false
#     end
#     if !$PokemonGlobal.revealtruth
#       pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
#       pbMessage(_INTL("¡\\c[1]{1}\\c[0] used the \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
#       $stats.sense_count += 1
#       $stats.item_sense_count += 1
#     end
#     pbRevealTruth
#     next true
#     end)
# end

#================================[Move Handler]================================#
# if AIFM_SenseTruth[:move]
#   AIFM_SenseTruth[:move_name].each do |move_name|  # repeat over each move name
#     config_name = AIFM_SenseTruth
#     move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
#     HiddenMoveHandlers::CanUseMove.add(move_name, proc { |move, pkmn, showmsg|
#       if !pbCanUseMove(config_name)
#         name = GameData::Move.get(move_name).name
#         pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name)) if showmsg
#         next false
#       end
#       move_index = pkmn.moves.find_index { |move| move.id == move_name }
#       if config_name[:uses_pp]
#         if pkmn.moves[move_index].pp == 0
#           pbMessage(_INTL("{1}", config_name[:missing_PP])) if showmsg
#           next false
#         end
#       end
#       next true
#     })

#     HiddenMoveHandlers::UseMove.add(move_name, proc { |move, pokemon|
#       config_name = AIFM_SenseTruth
#       if !$PokemonGlobal.revealtruth
#         pbCallMoveAnimation(pokemon) unless $PokemonSystem.animation_move == 1
#         pbMessage(_INTL("¡\\c[1]{1}\\c[0] used \\c[1]{2}\\c[0]!", pokemon.name, GameData::Move.get(move).name)) unless $PokemonSystem.animation_move == 1
#         if config_name[:uses_pp]
#           move_index = pokemon.moves.find_index { |move| move.id == move_name }
#           pokemon.moves[move_index].pp -= 1
#         end
#         $stats.sense_count += 1
#         $stats.move_sense_count += 1
#       end
#       pbRevealTruth
#       next true
#     })
#   end
# end
