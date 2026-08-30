#===============================================================================
# Hardcoded Midbattle Scripts
#===============================================================================
# You may add Midbattle Handlers here to create custom battle scripts you can
# call on. Unlike other methods of creating battle scripts, you can use these
# handlers to freely hardcode what you specifically want to happen in battle
# instead of the other methods which require specific values to be inputted.
#
# This method requires fairly solid scripting knowledge, so it isn't recommended
# for inexperienced users. As with other methods of calling midbattle scripts,
# you may do so by setting up the "midbattleScript" battle rule.
#
# 	For example:  
#   setBattleRule("midbattleScript", :demo_capture_tutorial)
#
#   *Note that the symbol entered must be the same as the symbol that appears as
#    the second argument in each of the handlers below. This may be named whatever
#    you wish.
#-------------------------------------------------------------------------------

################################################################################
# Demo scenario vs. wild Rotom that shifts forms.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_wild_rotom,
  proc { |battle, idxBattler, idxTarget, trigger|
    foe = battle.battlers[1]
    logname = _INTL("{1} ({2})", foe.pbThis(true), foe.index)
    case trigger
    #---------------------------------------------------------------------------
    # The player's Poke Balls are disabled at the start of the first round.
    when "RoundStartCommand_1_foe"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("{1} emitió un poderoso pulso magnético!", foe.pbThis))
      battle.pbAnimation(:CHARGE, foe, foe)
      pbSEPlay("Anim/Paralyze3")
      battle.pbDisplayPaused(_INTL("¡Tus Poké Ball se cortocircuitaron!\n¡No pueden ser utilizadas en esta batalla!"))
      battle.disablePokeBalls = true
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # After taking Super Effective damage, the opponent changes form each round.
    when "RoundEnd_foe"
      next if !battle.pbTriggerActivated?("TargetWeakToMove_foe")
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbAnimation(:NIGHTMARE, foe.pbDirectOpposing(true), foe)
      form = battle.pbRandom(1..5)
      foe.pbSimpleFormChange(form, _INTL("{1} poseyó un nuevo aparato!", foe.pbThis))
      foe.pbRecoverHP(foe.totalhp / 4)
      foe.pbCureAttract
      foe.pbCureConfusion
      foe.pbCureStatus
      if foe.ability_id != :MOTORDRIVE
        battle.pbShowAbilitySplash(foe, true, false)
        foe.ability = :MOTORDRIVE
        battle.pbReplaceAbilitySplash(foe)
        battle.pbDisplay(_INTL("¡{1} adquirió {2}!", foe.pbThis, foe.abilityName))
        battle.pbHideAbilitySplash(foe)
      end
      if foe.item_id != :CELLBATTERY
        foe.item = :CELLBATTERY
        battle.pbDisplay(_INTL("¡{1} se equipó una {2} que encontró en el electrodoméstico!", foe.pbThis, foe.itemName))
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent gains various effects when its HP falls to 50% or lower.
    when "TargetHPHalf_foe"
      next if battle.pbTriggerActivated?(trigger)
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbAnimation(:CHARGE, foe, foe)
      if foe.effects[PBEffects::Charge] <= 0
        foe.effects[PBEffects::Charge] = 5
        battle.pbDisplay(_INTL("¡{1} comenzó a cargar energía!", foe.pbThis))
      end
      if foe.effects[PBEffects::MagnetRise] <= 0
        foe.effects[PBEffects::MagnetRise] = 5
        battle.pbDisplay(_INTL("¡{1} levitó con electromagnetismo!", foe.pbThis))
      end
      battle.pbStartTerrain(foe, :Electric)
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent paralyzes the player's Pokemon when taking Super Effective damage.
    when "UserMoveEffective_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("¡{1} emitió un pulso eléctrico por desesperación!", foe.pbThis))
      battler = battle.battlers[idxBattler]
      if battler.pbCanInflictStatus?(:PARALYSIS, foe, true)
        battler.pbInflictStatus(:PARALYSIS)
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    end
  }
)


################################################################################
# Demo scenario vs. Rocket Grunt in a collapsing cave.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_collapsing_cave,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Introduction text explaining the event.
    when "RoundStartCommand_1_foe"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("¡El techo de la cueva comienza a derrumbarse a tu alrededor!"))
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡No voy a dejarte escapar!"))
      battle.pbDisplayPaused(_INTL("No me importa si toda esta cueva se derrumba sobre ambos... ¡jaja!"))
      scene.pbForceEndSpeech
      battle.pbDisplayPaused(_INTL("¡Derrota a tu oponente antes de que se acabe el tiempo!"))      
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Repeated end-of-round text.
    when "RoundEnd_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("¡La cueva sigue derrumbándose a tu alrededor!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Player's Pokemon is struck by falling rock, dealing damage & causing confusion.
    when "RoundEnd_2_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("¡{1} fue golpeado en la cabeza por una roca que caía!", battler.pbThis))
      battle.pbAnimation(:ROCKSMASH, battler.pbDirectOpposing(true), battler)
      old_hp = battler.hp
      battler.hp -= (battler.totalhp / 4).round
      scene.pbHitAndHPLossAnimation([[battler, old_hp, 0]])
      if battler.fainted?
        battler.pbFaint(true)
      elsif battler.pbCanConfuse?(battler, false)
        battler.pbConfuse
      end
    #---------------------------------------------------------------------------
    # Warning message.
    when "RoundEnd_3_player"
      battle.pbDisplayPaused(_INTL("¡Te estás quedando sin tiempo!"))
      battle.pbDisplayPaused(_INTL("¡Necesitas escapar inmediatamente!"))      
    #---------------------------------------------------------------------------
    # Player runs out of time and is forced to forfeit.
    when "RoundEnd_4_player"
      battle.pbDisplayPaused(_INTL("¡Fallaste en derrotar a tu oponente a tiempo!"))
      scene.pbRecall(idxBattler)
      battle.pbDisplayPaused(_INTL("¡Te viste obligado/a a huir de la batalla!"))      
      pbSEPlay("Battle flee")
      battle.decision = 3
    #---------------------------------------------------------------------------
    # Opponent's Pokemon stands its ground when its HP is low.
    when "LastTargetHPLow_foe"
      next if battle.pbTriggerActivated?(trigger)
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Mi {1} nunca se rendirá!", battler.name))
      scene.pbForceEndSpeech
      battle.pbAnimation(:BULKUP, battler, battler)
      battler.displayPokemon.play_cry
      battler.pbRecoverHP(battler.totalhp / 2)
      battle.pbDisplayPaused(_INTL("¡{1} está defendiendo su posición!", battler.pbThis))      
      showAnim = true
      [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStage(stat, 2, battler, showAnim)
        showAnim = false
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent mocks the player when forfeiting the match.
    when "BattleEndForfeit"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Ja, ja... ¡nunca saldrás con vida!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    end
  }
)


#===============================================================================
# Global Midbattle Scripts
#===============================================================================
# Global midbattle scripts are always active and will affect all battles as long
# as the conditions for the scripts are met. These are not set in a battle rule,
# and are instead triggered passively in any battle.
#-------------------------------------------------------------------------------

################################################################################
# Used for wild Mega battles.
################################################################################

MidbattleHandlers.add(:midbattle_global, :wild_mega_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle?
    next if battle.wildBattleMode != :mega
    foe = battle.battlers[1]
    next if !foe.wild?
    logname = _INTL("{1} ({2})", foe.pbThis, foe.index)
    case trigger
    #---------------------------------------------------------------------------
    # Mega Evolves wild battler immediately at the start of the first round.
    when "RoundStartCommand_1_foe"
      if battle.pbCanMegaEvolve?(foe.index)
        PBDebug.log("[Midbattle Global] #{logname} will Mega Evolve")
        battle.pbMegaEvolve(foe.index)
        battle.disablePokeBalls = true
        battle.sosBattle = false if defined?(battle.sosBattle)
        battle.totemBattle = nil if defined?(battle.totemBattle)
        foe.damageThreshold = 20
      else
        battle.wildBattleMode = nil
      end
    #---------------------------------------------------------------------------
    # Un-Mega Evolves wild battler once damage cap is reached.
    when "BattlerReachedHPCap_foe"
      PBDebug.log("[Midbattle Global] #{logname} damage cap reached")
      foe.unMega
      battle.disablePokeBalls = false
      battle.pbDisplayPaused(_INTL("¡La Megaevolución de {1} se desvaneció!\n¡Ahora puede ser capturado!", foe.pbThis))
    #---------------------------------------------------------------------------
    # Tracks player's win count.
    when "BattleEndWin"
      if battle.wildBattleMode == :mega
        $stats.wild_mega_battles_won += 1
      end
    end
  }
)


################################################################################
# Plays low HP music when the player's Pokemon reach critical health.
################################################################################

MidbattleHandlers.add(:midbattle_global, :low_hp_music,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !Settings::PLAY_LOW_HP_MUSIC
    battler = battle.battlers[idxBattler]
    next if !battler || !battler.pbOwnedByPlayer?
    track = battle.pbGetBattleLowHealthBGM
    next if !track.is_a?(RPG::AudioFile)
    playingBGM = battle.playing_bgm
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "BattlerHPRecovered_player"
      next if playingBGM != track.name
      next if battle.pbAnyBattlerLowHP?(idxBattler)
      battle.pbResumeBattleBGM
      PBDebug.log("[Midbattle Global] low HP music ended")
    #---------------------------------------------------------------------------
    # Restores original BGM when battler is fainted.
    when "BattlerHPReduced_player"
      next if playingBGM != track.name
	    next if battle.pbAnyBattlerLowHP?(idxBattler)
      next if !battler.fainted?
      battle.pbResumeBattleBGM
      PBDebug.log("[Midbattle Global] low HP music ended")
    #---------------------------------------------------------------------------
    # Plays low HP music when HP is critical.
    when "BattlerHPCritical_player"
      next if playingBGM == track.name
      battle.pbPauseAndPlayBGM(track)
      PBDebug.log("[Midbattle Global] low HP music begins")
    #---------------------------------------------------------------------------
    # Restores original BGM when sending out a healthy Pokemon.
    # Plays low HP music when sending out a Pokemon with critical HP.
    when "AfterSendOut_player"
      if battle.pbAnyBattlerLowHP?(idxBattler)
        next if playingBGM == track.name
        battle.pbPauseAndPlayBGM(track)
        PBDebug.log("[Midbattle Global] low HP music begins")
      elsif playingBGM == track.name
        battle.pbResumeBattleBGM
        PBDebug.log("[Midbattle Global] low HP music ended")
      end
    end
  }
)













################################################################################
# RAIDS
################################################################################

# AUMENTO DE TODO EN 1
MidbattleHandlers.add(:midbattle_scripts, :raids,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("¡El {1} parece enfadado!", battler.name))
      battle.pbCommonAnimation("StatUp", battler)
      # Aumentamos las estadísticas del Pokémon rival
      [:ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 1)
      end
      battle.pbDisplayPaused(_INTL("¡Las estadísticas de {1} han aumentado! ¡Ten cuidado!", battler.name))
    end
  }
)

# AUMENTO DE TODO EN 2
MidbattleHandlers.add(:midbattle_scripts, :raids3,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("¡El {1} parece enfadado!", battler.name))
      battle.pbCommonAnimation("StatUp", battler)
      # Aumentamos las estadísticas del Pokémon rival
      [:ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 2)
      end
      battle.pbDisplayPaused(_INTL("¡Las estadísticas de {1} han aumentado! ¡Ten cuidado!", battler.name))
    end
  }
)

# AUMENTO DE AT, ATESP Y VEL EN 2 y DEFS EN 3
MidbattleHandlers.add(:midbattle_scripts, :raids4,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("¡El {1} parece enfadado!", battler.name))
      battle.pbCommonAnimation("StatUp", battler)
      # Aumentamos las estadísticas del Pokémon rival
      [:ATTACK, :SPECIAL_ATTACK, :SPEED].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 2)
      end
      [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 3)
      end
      battle.pbDisplayPaused(_INTL("¡Las estadísticas de {1} han aumentado! ¡Ten cuidado!", battler.name))
    end
  }  
)

# AUMENTO DE ATS EN 2, VEL EN 3 Y DEFS EN 4
MidbattleHandlers.add(:midbattle_scripts, :raids2,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("¡El {1} parece enfadado!", battler.name))
      battle.pbCommonAnimation("StatUp", battler)
      # Aumentamos las estadísticas del Pokémon rival
      [:ATTACK, :SPECIAL_ATTACK].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 2)
      end
      [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 4)
      end
      [:SPEED].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 3)
      end
      battle.pbDisplayPaused(_INTL("¡Las estadísticas de {1} han aumentado! ¡Ten cuidado!", battler.name))
    end
  }  
)


# AUMENTO DE 4 EN TODO
MidbattleHandlers.add(:midbattle_scripts, :raids5,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("¡El {1} parece enfadado!", battler.name))
      battle.pbCommonAnimation("StatUp", battler)
      # Aumentamos las estadísticas del Pokémon rival
      [:ATTACK, :SPECIAL_ATTACK, :DEFENSE, :SPECIAL_DEFENSE, :SPEED].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 4)
      end
      battle.pbDisplayPaused(_INTL("¡Las estadísticas de {1} han aumentado! ¡Ten cuidado!", battler.name))
    end
  }  
)

MidbattleHandlers.add(:midbattle_scripts, :cryogonal1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("¡El {1} parece enfadado!", battler.name))
      battle.pbCommonAnimation("StatUp", battler)
      # Aumentamos las estadísticas del Pokémon rival
      [:ATTACK, :SPECIAL_ATTACK].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 2)
      end
      [:DEFENSE, :SPECIAL_DEFENSE, :SPEED].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 3)
      end
      battle.pbDisplayPaused(_INTL("¡Las estadísticas de {1} han aumentado! ¡Ten cuidado!", battler.name))
    end
  }  
)





################################################################################
# FRASES AÑIL EN COMBATE
################################################################################


MidbattleHandlers.add(:midbattle_scripts, :azul_combate_inicial,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "RoundStartCommand_1_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Te veo con bastante confianza. ¿Crees que serás capaz de ganarme cuando tienes la tabla de tipos en tu contra, {1}?", $player.name))
      scene.pbForceEndSpeech
    end
  }
)



MidbattleHandlers.add(:midbattle_scripts, :lider1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Venga! ¡Tienes la victoria a un tiro de piedra! Pero tampoco pienso derrumbarme..."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :lider2,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Esto ya no es una ola, ¡es un auténtico tsunami! ¡Y va a acabar contigo!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :lider3,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Esta chispa que se está encendiendo en mi interior... ¿Qué es exactamente? ¡No sentía algo así desde la guerra!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :atlas1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Te estás pasando de la raya, ¿eh?"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :rojohoja2,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Las opciones se me acaban... ¿queda algo que pueda hacer?"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :azul3,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Si dudas aunque solo sea un momento... ¡serás historia!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :lider4,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Mi poder florece de forma esplendorosa cuando llega la primavera, ¡siente la furia de la naturaleza!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :atenea1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¿Me obligas a usar a esta criatura? ¡Has ido demasiado lejos!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :rojohoja3,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Lo tengo bastante crudo pero... tal vez si intento esto..."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :azul5,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¿No te estremece combatir aquí, rodeado de tantas tumbas?"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :giovanni1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Ya veo que has cuidado de tus Pokémon con mucho esmero."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :urano1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Vamos! ¡Ven a por mí!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :agatha1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Dime, joven, ¿crees en los fantasmas o necesitas más?"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :rojohoja4,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Gracias a mis Pokémon he aprendido a no rendirme! ¡Esto no ha terminado!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :lider5,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Vamos a utilizar nuestra técnica final ninja, ¡esto va a ponerse intenso!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :azul6,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Observa a mi imponente Pokémon! Ya ha evolucionado a su fase final."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :giovanni2,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¿Es que no paras? ¡Necesitas un poco de mano dura!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :lider6,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Ya he visto el final de esto. Un resultado sorprendente."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :surya1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Había una vez un Pokémon Princesa que se hizo muuuuuuy fuerte..."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :lider7,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Estás a punto de desatar un calor infernal, ¿lo has pensado bien?"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :surya2,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("En un reino muy, muy lejano... alguien perdió a todos sus Pokémon."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :giovanni3,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Nadie volverá a cuestionar la fuerza de Giovanni, el Entrenador más fuerte del mundo."))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :lider8,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Este calor... este fuego... ¡no me sentía así desde que era joven!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :rojohoja5,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Observa lo que está a punto de suceder! ¡Es el resultado del vínculo que he forjado con mis Pokémon!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :altomando1,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Ji, ji, ji! ¿Notas cómo se entumecen tus articulaciones? ¡Pues ahora sentirás frío de verdad!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :altomando2,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Aún puedo liberar más fuerza! ¡Concentraré la energía que me queda en un último ataque devastador!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :altomando3,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Ju, ju, ju, ju! ¿Te dan miedo los fantasmas? ¡Pues estás a punto de ver uno aterrador!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :altomando4,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¿Crees que esos burdos ataques mellarán las escamas de mis dragones? ¡Te aplastaremos!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :campeon,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon Campeon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("He luchado con todo mi ser para llegar hasta aquí… ¡y ahora lo daré todo, sin ningún tipo de arrepentimiento! ¡Con mis Pokémon y el poder de la Megaevolución, conquistaré el título! ¡Este es mi máximo poder!"))
      scene.pbForceEndSpeech
    when "TurnEnd_1_foe"
      next if battle.pbAbleNonActiveCount(1) > 0 # Que sea tras sacar al último Pokémon.
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¿Lo sientes? Este ardor, esta emoción… ¡es el verdadero poder de un Maestro Pokémon! Hemos vivido muchas aventuras recorriendo la región de Kanto, y todas y cada una de ellas terminan en este preciso instante. ¡Adelante! ¡Es la hora del Campeón!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :oak,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Cuando un Entrenador se encuentra ante la espada y la pared, saca lo mejor de sí mismo. ¡Qué recuerdos me trae esto!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :ash,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Anime op")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Hacía tanto tiempo que no conocía a alguien así... ¡Vamos! ¡Sigue dándolo todo hasta el final!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :bill,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Qué privilegio poder ver tu colección de raros Pokémon! ¡Sigamos!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :maximo,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡No me puedo creer que haya conocido a alguien tan fuerte! ¿Cómo conociste a tus Pokémon? ¡Quiero saber más!"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :cintia,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Los grandes maestros poseen un vínculo muy fuerte con sus compañeros Pokémon. Pero lo tuyo es incluso más poderoso. ¿Podría ser...?"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :mirto,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Es admirable lo lejos que has llegado, ¿dónde está tu horizonte? ¿Hasta dónde llega tu vista?"))
      scene.pbForceEndSpeech
    end
  }
)

MidbattleHandlers.add(:midbattle_scripts, :prisma,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Ancestros... ¡dadme fuerza! ¡Concededme el poder para superar a este monstruo!"))
      scene.pbForceEndSpeech
    end
  }
)



################################################################################

MidbattleHandlers.add(:midbattle_scripts, :placeholder,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    case trigger
    #---------------------------------------------------------------------------
    when "AfterLastSwitchIn_foe" 
      battle.pbPauseAndPlayBGM("Ultimo Pokemon")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("AAAAA"))
      scene.pbForceEndSpeech
    end
  }
)
