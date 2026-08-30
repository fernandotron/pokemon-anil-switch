class Battle
  attr_reader :client_id
  # Focus Meter System
  attr_accessor :focusMeter
  #PLA Battle Styles
  attr_accessor :battleStyle
end

class Battle_CableClub < Battle
  attr_reader :connection
  attr_reader :battleRNG
  
  # Override pbSendOut to restore randomized mega abilities when switching in
  def pbSendOut(sendOuts, startBattle = false)
    super(sendOuts, startBattle)
    # Restore mega ability for randomized Pokémon that are already mega evolved
    if defined?(RandomizedChallenge) && RandomizedChallenge.enabled? && RandomizedChallenge.random_abilities?
      sendOuts.each do |b|
        battler = @battlers[b[0]]
        next if !battler || !battler.pokemon
        # If the Pokémon is mega evolved and has a stored mega_ability, restore it
        if battler.mega? && battler.pokemon.mega_ability
          battler.ability = battler.pokemon.mega_ability
        end
      end
    end
  end
  
  def initialize(connection, client_id, scene, player_party, opponent_party, opponent, seed)
    @connection = connection
    @client_id = client_id
    online_back_check = GameData::TrainerType.player_back_sprite_filename($player.online_trainer_type)
    if online_back_check
      player = NPCTrainer.new($player.name, $player.online_trainer_type)
    else
      player = NPCTrainer.new($player.name, $player.trainertype)
    end
    super(scene, player_party, opponent_party, [player], [opponent])
    @battleAI  = AI_CableClub.new(self)
    @battleRNG = Random.new(seed)
  end
  
  def pbRandom(x)
    valor_rand = @battleRNG.rand(x)
    # p "#{x} #{valor_rand}"
    return valor_rand
  end

  def pbMegaEvolve(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasMega? || battler.mega?
    $stats.mega_evolution_count += 1 if battler.pbOwnedByPlayer?
    pbDeluxeTriggers(idxBattler, nil, "BeforeMegaEvolution", battler.species, *battler.pokemon.types)
    @scene.pbAnimateSubstitute(idxBattler, :hide)
    old_ability = battler.ability_id
    if battler.hasActiveAbility?(:ILLUSION)
      Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, self)
    end
    if battler.wild?
      case battler.pokemon.megaMessage
      when 1
        pbDisplay(_INTL("¡{1} irradia energía!", battler.pbThis))
      else
        pbDisplay(_INTL("¡{2} de {2} irradia energía!", battler.pbThis, battler.itemName))
      end
    else
      trainerName = pbGetOwnerName(idxBattler)
      case battler.pokemon.megaMessage
      when 1
        pbDisplay(_INTL("¡El deseo ferviente de {1} ha alcanzado a {2}!", trainerName, battler.pbThis))
      else
        pbDisplay(_INTL("¡La {2} de {1} está reaccionando al {4} de {3}!",
                        battler.pbThis(true), battler.itemName, trainerName, pbGetMegaRingName(idxBattler)))
      end
    end
    pbAnimateMegaEvolution(battler)
    megaName = battler.pokemon.megaName
    megaName = _INTL("Mega {1}", battler.pokemon.speciesName) if nil_or_empty?(megaName)
    pbDisplay(_INTL("¡{1} ha megaevolucionado en {2}!", battler.pbThis, megaName))
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @megaEvolution[side][owner] = -2
    if battler.isSpecies?(:GENGAR) && battler.mega?
      battler.effects[PBEffects::Telekinesis] = 0
    end
    battler.pbOnLosingAbility(old_ability)

    if (defined?(RandomizedChallenge) && RandomizedChallenge.enabled? && RandomizedChallenge.random_abilities?) && battler.pokemon.mega_ability
      battler.ability = battler.pokemon.mega_ability
    end
    
    battler.pbTriggerAbilityOnGainingIt
    pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION
    pbDeluxeTriggers(idxBattler, nil, "AfterMegaEvolution", battler.species, *battler.pokemon.types)
    @scene.pbAnimateSubstitute(idxBattler, :show)
  end
  
  # Added optional args to not make v18 break.
  def pbSwitchInBetween(index, checkLaxOnly = false, canCancel = false)
    if pbOwnedByPlayer?(index)
      choice = super(index, checkLaxOnly, canCancel)
      # bug fix for the unknown type :switch. cause: going into the pokemon menu then backing out and attacking, which sends the switch symbol regardless.
      if !canCancel # forced switches do not allow canceling, and both sides would expect a response.
        @connection.send do |writer|
          writer.sym(:switch)
          writer.int(choice)
        end
      end
      return choice
    else
      # our_indices = pbGetOpposingIndicesInOrder(1).reverse
      their_indices = pbGetOpposingIndicesInOrder(0).reverse
      frame = 0
      @scene.pbShowWindow(Battle::Scene::MESSAGE_BOX)
      cw = @scene.sprites["messageWindow"]
      cw.letterbyletter = false
      begin
        loop do
          frame += 1
          cw.text = _INTL("Esperando" + "." * (1 + ((frame / 8) % 3)))
          @scene.pbFrameUpdate(cw)
          Graphics.update
          Input.update
          raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::BACK) && pbConfirmMessageSerious("¿Desea desconectarse?")
          @connection.update do |record|
            case (type = record.sym)
            when :forfeit
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("¡{1} se ha rendido!", @opponent[0].full_name))
              @decision = 1
              pbAbort
            when :switch
              return record.int
            when :battle_data
              loop do
                case (t = record.sym)
                when :seed
                  seed=record.int()
                  self.battleRNG.srand(seed) if self.client_id==1
                when :mechanic
                  self.megaEvolution[1][0] = record.int
                  if PluginManager.installed?("ZUD Mechanics") ||
                     PluginManager.installed?("[DBK] Z-Power")
                    self.zMove[1][0] = record.int
                    self.ultraBurst[1][0] = record.int
                  end
                  if PluginManager.installed?("ZUD Mechanics") || 
                     PluginManager.installed?("[DBK] Dynamax")
                    self.dynamax[1][0] = record.int
                  end
                  if PluginManager.installed?("PLA Battle Styles")
                    focus_index = record.int
                    self.battleStyle[1][0] = focus_index
                    style_trigger = record.int
                    self.battlers[focus_index].style_trigger = style_trigger if focus_index >= 0
                  end
                  if PluginManager.installed?("Terastal Phenomenon") ||
                     PluginManager.installed?("[DBK] Terastallization")
                    self.terastallize[1][0] = record.int
                  end
                  if PluginManager.installed?("Focus Meter System")
                    self.focusMeter[1][0] = record.int
                  end
                when :choice
                  their_index = their_indices.shift
                  partner_pkmn = self.battlers[their_index]
                  self.choices[their_index][0] = record.sym
                  self.choices[their_index][1] = record.int
                  if PluginManager.installed?("[DBK] Z-Power")
                    partner_pkmn.display_zmoves if self.zMove[1][0] == their_index
                  end
                  if PluginManager.installed?("[DBK] Dynamax")
                    partner_pkmn.display_dynamax_moves if self.dynamax[1][0] == their_index
                  end
                  if PluginManager.installed?("ZUD Mechanics")
                    if self.zMove[1][0] == their_index
                      partner_pkmn.display_power_moves(1)
                      partner_pkmn.power_trigger = true
                    elsif self.ultraBurst[1][0] == their_index
                      partner_pkmn.power_trigger = true
                    elsif self.dynamax[1][0] == their_index
                      partner_pkmn.display_power_moves(2)
                      partner_pkmn.power_trigger = true
                    end
                  end
                  if PluginManager.installed?("PLA Battle Styles")
                    if self.battleStyle[1][0] == their_index
                      partner_pkmn.toggle_style_moves(partner_pkmn.style_trigger)
                    end
                  end
                  move = record.nil_or(:bool)
                  if move
                    move = (self.choices[their_index][1]<0) ? self.struggle : partner_pkmn.moves[self.choices[their_index][1]]
                  end
                  self.choices[their_index][2] = move
                  self.choices[their_index][3] = record.int
                  break if their_indices.empty?
                else
                  echoln "Unknown message in battle_data (switch): #{t}"
                  # Try to consume any remaining data to prevent the error
                  break
                end
              end
            else
              echoln "Unknown message: #{type}"
            end
          end
        end
      ensure
        cw.letterbyletter = false
      end
    end
  end

  def pbRun(idxBattler, duringBattle = false)
    ret = super(idxBattler, duringBattle)
    if ret == 1
      @connection.send do |writer|
        writer.sym(:forfeit)
      end
      @connection.discard(1)
    end
    return ret
  end

  def pbCanShowCommands?(idxBattler)
    last_index = pbGetOpposingIndicesInOrder(0).reverse.last
    return true if last_index==idxBattler
    return super(idxBattler)
  end
  
  # avoid unnecessary checks and check in same order
  def pbEORSwitch(favorDraws=false)
    return if @decision>0 && !favorDraws
    return if @decision==5 && favorDraws
    pbJudge
    return if @decision>0
    # Check through each fainted battler to see if that spot can be filled.
    switched = []
    loop do
      switched.clear
      # check in same order
      battlers = []
      order = CableClub::pokemon_order(@client_id)
      order.each_with_index do |o,i|
        battlers[i] = @battlers[o]
      end
      battlers.each do |b|
        next if !b || !b.fainted?
        idxBattler = b.index
        next if !pbCanChooseNonActive?(idxBattler)
        if !pbOwnedByPlayer?(idxBattler)   # Opponent/ally is switching in
          idxPartyNew = pbSwitchInBetween(idxBattler)
          opponent = pbGetOwnerFromBattlerIndex(idxBattler)
          pbRecallAndReplace(idxBattler,idxPartyNew)
          switched.push(idxBattler)
        else
          idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
          pbRecallAndReplace(idxBattler,idxPlayerPartyNew)
          switched.push(idxBattler)
        end
      end
      break if switched.length==0
      pbOnBattlerEnteringBattle(switched)
    end
  end

def pbCalculatePriority(fullCalc = false, indexArray = nil)
    needRearranging = false
    
    if fullCalc
      @priorityTrickRoom = (@field.effects[PBEffects::TrickRoom] > 0)
      
      # En lugar de usar RNG local, usar el RNG sincronizado para el orden aleatorio
      randomOrder = Array.new(maxBattlerIndex + 1) { |i| i }
      (randomOrder.length - 1).times do |i|
        # Usar el RNG sincronizado de la batalla online
        r = i + pbRandom(randomOrder.length - i)
        randomOrder[i], randomOrder[r] = randomOrder[r], randomOrder[i]
      end
      
      @priority.clear
      (0..maxBattlerIndex).each do |i|
        b = @battlers[i]
        next if !b
        
        # Estructura: [battler, speed, sub-priority from ability, sub-priority from item,
        #             final sub-priority, priority, tie-breaker order]
        entry = [b, b.pbSpeed, 0, 0, 0, 0, randomOrder[i]]
        
        if @choices[b.index][0] == :UseMove || @choices[b.index][0] == :Shift
          # Calcular prioridad del movimiento
          if @choices[b.index][0] == :UseMove
            move = @choices[b.index][2]
            pri = move.pbPriority(b)
            
            # Efectos de habilidad en prioridad
            if b.abilityActive?
              pri = Battle::AbilityEffects.triggerPriorityChange(b.ability, b, move, pri)
            end
            
            # Efectos de objeto en prioridad
            if b.itemActive?
              pri = Battle::ItemEffects.triggerPriorityChange(b.item, b, move, pri)
            end
            
            entry[5] = pri
            @choices[b.index][4] = pri
          end
          
          # Calcular cambios de sub-prioridad
          # Habilidades (como Stall)
          if b.abilityActive?
            entry[2] = Battle::AbilityEffects.triggerPriorityBracketChange(b.ability, b, self)
          end
          
          # Objetos (Quick Claw, Custap Berry, Lagging Tail, Full Incense)
          if b.itemActive?
            entry[3] = Battle::ItemEffects.triggerPriorityBracketChange(b.item, b, self)
          end
        end
        
        @priority.push(entry)
      end
      needRearranging = true
      
    else
      # Recálculo parcial
      if (@field.effects[PBEffects::TrickRoom] > 0) != @priorityTrickRoom
        needRearranging = true
        @priorityTrickRoom = (@field.effects[PBEffects::TrickRoom] > 0)
      end
      
      # Revisar velocidades y cambios de prioridad
      @priority.each do |entry|
        next if !entry
        next if indexArray && !indexArray.include?(entry[0].index)
        
        # Recalcular velocidad
        newSpeed = entry[0].pbSpeed
        needRearranging = true if newSpeed != entry[1]
        entry[1] = newSpeed
        
        # Recalcular prioridad del movimiento
        choice = @choices[entry[0].index]
        if choice[0] == :UseMove
          move = choice[2]
          pri = move.pbPriority(entry[0])
          
          if entry[0].abilityActive?
            pri = Battle::AbilityEffects.triggerPriorityChange(entry[0].ability, entry[0], move, pri)
          end
          
          if entry[0].itemActive?
            pri = Battle::ItemEffects.triggerPriorityChange(entry[0].item, entry[0], move, pri)
          end
          
          needRearranging = true if pri != entry[5]
          entry[5] = pri
          choice[4] = pri
        end
      end
    end
    
    # Calcular sub-prioridad final
    @priority.each do |entry|
      entry[0].effects[PBEffects::PriorityAbility] = false
      entry[0].effects[PBEffects::PriorityItem] = false
      
      subpri = entry[2]   # Sub-prioridad de habilidad
      
      if (subpri == 0 && entry[3] != 0) ||
         (subpri < 0 && entry[3] >= 1)
        subpri = entry[3]   # Sub-prioridad de objeto
        entry[0].effects[PBEffects::PriorityItem] = true
      elsif subpri != 0
        entry[0].effects[PBEffects::PriorityAbility] = true
      end
      
      entry[4] = subpri   # Sub-prioridad final
    end
    
    # Reordenar el array de prioridad
    if needRearranging
      @priority.sort! do |a, b|
        if a[5] != b[5]
          # Ordenar por prioridad (valor más alto primero)
          b[5] <=> a[5]
        elsif a[4] != b[4]
          # Ordenar por sub-prioridad (valor más alto primero)
          b[4] <=> a[4]
        elsif @priorityTrickRoom
          # Ordenar por velocidad (más bajo primero), usar desempate si es necesario
          (a[1] == b[1]) ? b[6] <=> a[6] : a[1] <=> b[1]
        else
          # Ordenar por velocidad (más alto primero), usar desempate si es necesario
          (a[1] == b[1]) ? b[6] <=> a[6] : b[1] <=> a[1]
        end
      end
      
      # Log de debug mejorado para online
      if fullCalc && $DEBUG
        logMsg = "[Cable Club - Round order] Client #{@client_id}: "
        @priority.each_with_index do |entry, i|
          logMsg += ", " if i > 0
          battler = entry[0]
          move_name = "No move"
          if @choices[battler.index][0] == :UseMove && @choices[battler.index][2]
            move_name = @choices[battler.index][2].name
          end
          logMsg += "#{battler.pbThis(i > 0)} (#{battler.index}) - #{move_name} [Pri: #{entry[5]}, Spd: #{entry[1]}, Tie: #{entry[6]}]"
        end
        PBDebug.log(logMsg)
      end
    end
    
    # Verificación adicional para debug en modo desarrollador
    if $DEBUG
      puts "=== PRIORITY CALCULATION DEBUG ==="
      puts "Client ID: #{@client_id}"
      puts "Full Calc: #{fullCalc}"
      puts "Trick Room: #{@priorityTrickRoom}"
      @priority.each_with_index do |entry, i|
        battler = entry[0]
        move_name = "No action"
        if @choices[battler.index][0] == :UseMove && @choices[battler.index][2]
          move_name = @choices[battler.index][2].name
        elsif @choices[battler.index][0] == :UseItem
          move_name = "Use Item"
        elsif @choices[battler.index][0] == :SwitchOut
          move_name = "Switch"
        end
        puts "#{i + 1}. #{battler.pbThis} (Index: #{battler.index})"
        puts "   Action: #{move_name}"
        puts "   Priority: #{entry[5]} | Speed: #{entry[1]} | Sub-Pri: #{entry[4]} | Tie-breaker: #{entry[6]}"
      end
      puts "=================================="
    end
  end
end

class Battle
  class AI_CableClub < AI
    def pbDefaultChooseEnemyCommand(index)
      # Hurray for default methods. have to reverse it to show the expected order.
      our_indices = @battle.pbGetOpposingIndicesInOrder(1).reverse
      their_indices = @battle.pbGetOpposingIndicesInOrder(0).reverse
      # Sends our choices after they have all been locked in.
      if index == their_indices.last
        # TODO: patch this up to be index agnostic.
        # Would work fine if restricted to single/double battles
        target_order = CableClub::pokemon_target_order(@battle.client_id)
        @battle.connection.send do |writer|
          writer.sym(:battle_data)
          # Send Seed
          cur_seed=@battle.battleRNG.srand
          @battle.battleRNG.srand(cur_seed)
          writer.sym(:seed)
          writer.int(cur_seed)
          # Send Extra Battle Mechanics
          writer.sym(:mechanic)
          # Mega Evolution
          mega=@battle.megaEvolution[0][0]
          mega^=1 if mega>=0
          writer.int(mega)
          # ZUD / [DBK] Z-Power
          if PluginManager.installed?("ZUD Mechanics") ||
             PluginManager.installed?("[DBK] Z-Power")
            zmove = @battle.zMove[0][0]
            zmove^=1 if zmove>=0
            writer.int(zmove)
            ultra = @battle.ultraBurst[0][0]
            ultra^=1 if ultra>=0
            writer.int(ultra)
          end
          if PluginManager.installed?("ZUD Mechanics") ||
             PluginManager.installed?("[DBK] Dynamax")
            dmax = @battle.dynamax[0][0]
            dmax^=1 if dmax>=0
            writer.int(dmax)
          end
          # PLA Styles
          if PluginManager.installed?("PLA Battle Styles")
            style = @battle.battleStyle[0][0]
            style_trigger = 0
            if style>=0
              style_trigger = @battle.battlers[style].style_trigger
              style^=1
            end
            writer.int(style)
            writer.int(style_trigger)
          end
          if PluginManager.installed?("Terastal Phenomenon") ||
             PluginManager.installed?("[DBK] Terastallization")
            tera = @battle.terastallize[0][0]
            tera^=1 if tera>=0
            writer.int(tera)
          end
          # Focus
          if PluginManager.installed?("Focus Meter System")
            focus = @battle.focusMeter[0][0]
            focus^=1 if focus>=0
            writer.int(focus)
          end
          # Send Choices for Player's Mons
          for our_index in our_indices
            pkmn = @battle.battlers[our_index]
            writer.sym(:choice)
            # choice picked was changed to be a symbol now.
            writer.sym(@battle.choices[our_index][0])
            writer.int(@battle.choices[our_index][1])
            move = !!@battle.choices[our_index][2]
            writer.nil_or(:bool, move)
            # -1 invokes the RNG, out of order (somehow?!) which causes desync.
            # But this is a single battle, so the only possible choice is the foe.
            #if @battle.singleBattle? && @battle.choices[our_index][3] == -1
            #  @battle.choices[our_index][3] = their_indices[0]
            #end
            # Target from their POV.
            our_target = @battle.choices[our_index][3]
            their_target = target_order[our_target] rescue our_target
            writer.int(their_target)
          end
        end
        frame = 0
        @battle.scene.pbShowWindow(Battle::Scene::MESSAGE_BOX)
        cw = @battle.scene.sprites["messageWindow"]
        cw.letterbyletter = false
        begin
          loop do
            frame += 1
            cw.text = _INTL("Esperando" + "." * (1 + ((frame / 8) % 3)))
            @battle.scene.pbFrameUpdate(cw)
            Graphics.update
            Input.update
            raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::BACK) && pbConfirmMessageSerious("¿Quieres desconectarte?")
            @battle.connection.update do |record|
              case (type = record.sym)
              when :forfeit
                pbSEPlay("Battle flee")
                @battle.pbDisplay(_INTL("¡{1} se ha rendido!", @battle.opponent[0].full_name))
                @battle.decision = 1
                @battle.pbAbort
  
              when :battle_data
                loop do
                  case (t = record.sym)
                  when :seed
                    seed=record.int()
                    @battle.battleRNG.srand(seed) if @battle.client_id==1
                  when :mechanic
                    # Always read mega evolution data first
                    @battle.megaEvolution[1][0] = record.int
                    
                    # Read ZUD/Z-Power mechanics if available
                    if PluginManager.installed?("ZUD Mechanics") ||
                       PluginManager.installed?("[DBK] Z-Power")
                      @battle.zMove[1][0] = record.int
                      @battle.ultraBurst[1][0] = record.int
                    end
                    
                    # Read ZUD/Dynamax mechanics if available
                    if PluginManager.installed?("ZUD Mechanics") ||
                       PluginManager.installed?("[DBK] Dynamax")
                      @battle.dynamax[1][0] = record.int
                    end
                    
                    # Read PLA Battle Styles if available
                    if PluginManager.installed?("PLA Battle Styles")
                      focus_index = record.int
                      @battle.battleStyle[1][0] = focus_index
                      style_trigger = record.int
                      @battle.battlers[focus_index].style_trigger = style_trigger if focus_index >= 0
                    end
                    
                    # Read Terastal mechanics if available
                    if PluginManager.installed?("Terastal Phenomenon") ||
                       PluginManager.installed?("[DBK] Terastallization")
                      @battle.terastallize[1][0] = record.int
                    end
                    
                    # Read Focus Meter System if available
                    if PluginManager.installed?("Focus Meter System")
                      @battle.focusMeter[1][0] = record.int
                    end
                  when :choice
                    their_index = their_indices.shift
                    partner_pkmn = @battle.battlers[their_index]
                    @battle.choices[their_index][0] = record.sym
                    @battle.choices[their_index][1] = record.int
                    if PluginManager.installed?("[DBK] Z-Power")
                      partner_pkmn.display_zmoves if @battle.zMove[1][0] == their_index
                    end
                    if PluginManager.installed?("[DBK] Dynamax")
                      partner_pkmn.display_dynamax_moves if @battle.dynamax[1][0] == their_index
                    end
                    if PluginManager.installed?("ZUD Mechanics")
                      if @battle.zMove[1][0] == their_index
                        partner_pkmn.display_power_moves(1)
                        partner_pkmn.power_trigger = true
                      elsif @battle.ultraBurst[1][0] == their_index
                        partner_pkmn.power_trigger = true
                      elsif @battle.dynamax[1][0] == their_index
                        partner_pkmn.display_power_moves(2)
                        partner_pkmn.power_trigger = true
                      end
                    end
                    if PluginManager.installed?("PLA Battle Styles")
                      if @battle.battleStyle[1][0] == their_index
                        partner_pkmn.toggle_style_moves(partner_pkmn.style_trigger)
                      end
                    end
                    move = record.nil_or(:bool)
                    if move
                      move = (@battle.choices[their_index][1]<0) ? @battle.struggle : partner_pkmn.moves[@battle.choices[their_index][1]]
                    end
                    @battle.choices[their_index][2] = move
                    @battle.choices[their_index][3] = record.int
                    break if their_indices.empty?
                  else
                    echoln "Unknown message in battle_data: #{t}"
                    # Try to consume any remaining data to prevent the error
                    break
                  end
                end
                return
  
              else
                echoln "Unknown message: #{type}"
              end
            end
          end
        ensure
          cw.letterbyletter = true
        end
      end
    end
  
    def pbDefaultChooseNewEnemy(index, party)
      raise "Expected this to be unused."
    end
  end
end

#===============================================================================
# This move permanently turns into the last move used by the target. (Sketch)
#===============================================================================
class Battle::Move::ReplaceMoveWithTargetLastMoveUsed
  alias _cc_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if CableClub::DISABLE_SKETCH_ONLINE && !@battle.internalBattle
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return _cc_pbMoveFailed?(user, targets)
  end
end



# Corrección para que se mantenga el orden en ataques que dan a varios rivales a la vez.
class Battle
  def pbChangeTargets(move, user)
    targets = move.pbTarget(user)
    # Solo reordenar si es un movimiento con múltiples objetivos en combate online
    if self.is_a?(Battle_CableClub) && targets.length > 1
      targets = CableClub.sort_targets(targets, @client_id)
    end
    return targets
  end
end

module CableClub
  def self.sort_targets(targets, client_id)
    order = CableClub.pokemon_order(client_id)
    return targets.sort_by { |b| order.index(b.index) || 999 }
  end
end