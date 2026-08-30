#===============================================================================#
#                                                                               #
#               --- [CableClub] PATCH - RNG SYNC & STABILITY ---                #
#                                                                               # 
#===============================================================================#

#===============================================================================
# Generador de números aleatorios aislado y determinista
#===============================================================================
module ZCable
  class BattleRNG
    attr_reader :seed
    attr_reader :call_count

    def initialize(seed)
      @seed = seed
      @rng = Random.new(seed)
      @call_count = 0
    end

    def rand(max)
      @call_count += 1
      return @rng.rand(max)
    end

    def random
      @call_count += 1
      return @rng.rand
    end
  end
end

#===============================================================================
# Inyección en la clase base Battle y AI
#===============================================================================
class Battle
  attr_accessor :z_rng

  unless method_defined?(:z_original_pbRandom)
    alias z_original_pbRandom pbRandom
  end

  def pbRandom(x)
    if @z_rng
      return @z_rng.rand(x)
    else
      return z_original_pbRandom(x)
    end
  end
end

class Battle::AI 
  def pbAIRandom(x)
    if @battle.z_rng
      return @battle.z_rng.rand(x)
    else
      return rand(x)
    end
  end
end

#===============================================================================
# Battle_CableClub (RNG + Speed Tie Fix)
#===============================================================================
class Battle_CableClub < Battle
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
    
    # INYECCIÓN DE Z-RNG
    @z_rng = ZCable::BattleRNG.new(seed)
    @battleRNG = nil # Anulamos el RNG viejo para evitar confusión
    
    echoln "[CableClub] Batalla Online iniciada. Semilla: #{seed} | Cliente: #{client_id}"
  end

  remove_method :pbRandom if method_defined?(:pbRandom)

  #-----------------------------------------------------------------------------
  # CORRECCIÓN DE PRIORIDAD
  #-----------------------------------------------------------------------------
  def pbCalculatePriority(fullCalc = false, indexArray = nil)
    needRearranging = false
    
    if fullCalc
      @priorityTrickRoom = (@field.effects[PBEffects::TrickRoom] > 0)
      
      # Generamos la lista aleatoria SINCRONIZADA.
      # Esta lista será IDÉNTICA en ambos clientes.
      randomOrder = Array.new(maxBattlerIndex + 1) { |i| i }
      (randomOrder.length - 1).times do |i|
        r = i + pbRandom(randomOrder.length - i)
        randomOrder[i], randomOrder[r] = randomOrder[r], randomOrder[i]
      end
      
      @priority.clear
      (0..maxBattlerIndex).each do |i|
        b = @battlers[i]
        next if !b
        
        # Si soy el Cliente 1 (Guest), invierto la lectura del array aleatorio.
        # Esto garantiza que si el Host gana el tie-breaker, el Guest pierda, y viceversa.
        tie_breaker_index = i
        if @client_id == 1
          tie_breaker_index = i ^ 1
        end
        tie_breaker_value = randomOrder[tie_breaker_index]
        
        entry = [b, b.pbSpeed, 0, 0, 0, 0, tie_breaker_value]
        
        if @choices[b.index][0] == :UseMove || @choices[b.index][0] == :Shift
          if @choices[b.index][0] == :UseMove
            move = @choices[b.index][2]
            pri = move.pbPriority(b)
            
            if b.abilityActive?
              pri = Battle::AbilityEffects.triggerPriorityChange(b.ability, b, move, pri)
            end
            if b.itemActive?
              pri = Battle::ItemEffects.triggerPriorityChange(b.item, b, move, pri)
            end
            
            entry[5] = pri
            @choices[b.index][4] = pri
          end
          
          if b.abilityActive?
            entry[2] = Battle::AbilityEffects.triggerPriorityBracketChange(b.ability, b, self)
          end
          if b.itemActive?
            entry[3] = Battle::ItemEffects.triggerPriorityBracketChange(b.item, b, self)
          end
        end
        
        @priority.push(entry)
      end
      needRearranging = true
      
    else
      if (@field.effects[PBEffects::TrickRoom] > 0) != @priorityTrickRoom
        needRearranging = true
        @priorityTrickRoom = (@field.effects[PBEffects::TrickRoom] > 0)
      end
      
      @priority.each do |entry|
        next if !entry
        next if indexArray && !indexArray.include?(entry[0].index)        
        newSpeed = entry[0].pbSpeed
        needRearranging = true if newSpeed != entry[1]
        entry[1] = newSpeed        
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
    
    @priority.each do |entry|
      entry[0].effects[PBEffects::PriorityAbility] = false
      entry[0].effects[PBEffects::PriorityItem] = false      
      subpri = entry[2]
      if (subpri == 0 && entry[3] != 0) || (subpri < 0 && entry[3] >= 1)
        subpri = entry[3]
        entry[0].effects[PBEffects::PriorityItem] = true
      elsif subpri != 0
        entry[0].effects[PBEffects::PriorityAbility] = true
      end
      entry[4] = subpri
    end
    
    if needRearranging
      @priority.sort! do |a, b|
        if a[5] != b[5]
          b[5] <=> a[5]
        elsif a[4] != b[4]
          b[4] <=> a[4]
        elsif @priorityTrickRoom
          (a[1] == b[1]) ? b[6] <=> a[6] : a[1] <=> b[1]
        else
          (a[1] == b[1]) ? b[6] <=> a[6] : b[1] <=> a[1]
        end
      end
      
      if fullCalc && $DEBUG
        logMsg = "[CableClub Priority] Client #{@client_id}: "
        @priority.each_with_index do |entry, i|
          logMsg += ", " if i > 0
          battler = entry[0]
          logMsg += "#{battler.pbThis(i > 0)} (Tie: #{entry[6]})"
        end
        PBDebug.log(logMsg)
      end
    end
  end
end

#===============================================================================
# AI_CableClub
#===============================================================================
class Battle::AI_CableClub < Battle::AI
  def pbDefaultChooseEnemyCommand(index)
    our_indices = @battle.pbGetOpposingIndicesInOrder(1).reverse
    their_indices = @battle.pbGetOpposingIndicesInOrder(0).reverse    
    if index == their_indices.last
      target_order = CableClub::pokemon_target_order(@battle.client_id)
      @battle.connection.send do |writer|
        writer.sym(:battle_data)
        cur_seed = @battle.battleRNG.srand
        @battle.battleRNG.srand(cur_seed)
        writer.sym(:seed)
        writer.int(cur_seed)       
        writer.sym(:mechanic)
        mega = @battle.megaEvolution[0][0]
        mega ^= 1 if mega >= 0
        writer.int(mega)
        
        if PluginManager.installed?("ZUD Mechanics") || PluginManager.installed?("[DBK] Z-Power")
          zmove = @battle.zMove[0][0]; zmove ^= 1 if zmove >= 0
          ultra = @battle.ultraBurst[0][0]; ultra ^= 1 if ultra >= 0
          writer.int(zmove); writer.int(ultra)
        end
        if PluginManager.installed?("ZUD Mechanics") || PluginManager.installed?("[DBK] Dynamax")
          dmax = @battle.dynamax[0][0]; dmax ^= 1 if dmax >= 0
          writer.int(dmax)
        end
        if PluginManager.installed?("PLA Battle Styles")
          style = @battle.battleStyle[0][0]
          style_trigger = (style >= 0) ? @battle.battlers[style].style_trigger : 0
          style ^= 1 if style >= 0
          writer.int(style); writer.int(style_trigger)
        end
        if PluginManager.installed?("Terastal Phenomenon") || PluginManager.installed?("[DBK] Terastallization")
          tera = @battle.terastallize[0][0]; tera ^= 1 if tera >= 0
          writer.int(tera)
        end
        if PluginManager.installed?("Focus Meter System")
          focus = @battle.focusMeter[0][0]; focus ^= 1 if focus >= 0
          writer.int(focus)
        end

        for our_index in our_indices
          pkmn = @battle.battlers[our_index]
          writer.sym(:choice)
          writer.sym(@battle.choices[our_index][0])
          writer.int(@battle.choices[our_index][1])
          move = !!@battle.choices[our_index][2]
          writer.nil_or(:bool, move)
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
          
          if Input.trigger?(Input::BACK) && Kernel.pbConfirmMessage(_INTL("¿Quieres desconectarte?"))
             raise Connection::Disconnected.new("disconnected")
          end

          @battle.connection.update do |record|
            case (type = record.sym)
            when :forfeit
              pbSEPlay("Battle flee")
              @battle.pbDisplay(_INTL("¡{1} se ha rendido!", @battle.opponent[0].full_name))
              @battle.decision = 1
              @battle.pbAbort             
            when :battle_data
              loop do
                break if record.empty?               
                case (t = record.sym)
                when :seed
                  seed = record.int
                  @battle.battleRNG.srand(seed) if @battle.client_id == 1                 
                when :mechanic
                  @battle.megaEvolution[1][0] = record.int
                  
                  if PluginManager.installed?("ZUD Mechanics") || PluginManager.installed?("[DBK] Z-Power")
                    @battle.zMove[1][0] = record.int
                    @battle.ultraBurst[1][0] = record.int
                  end
                  if PluginManager.installed?("ZUD Mechanics") || PluginManager.installed?("[DBK] Dynamax")
                    @battle.dynamax[1][0] = record.int
                  end
                  if PluginManager.installed?("PLA Battle Styles")
                    focus_index = record.int
                    @battle.battleStyle[1][0] = focus_index
                    style_trigger = record.int
                    @battle.battlers[focus_index].style_trigger = style_trigger if focus_index >= 0
                  end
                  if PluginManager.installed?("Terastal Phenomenon") || PluginManager.installed?("[DBK] Terastallization")
                    @battle.terastallize[1][0] = record.int
                  end
                  if PluginManager.installed?("Focus Meter System")
                    @battle.focusMeter[1][0] = record.int
                  end
                  
                when :choice
                  if their_indices.empty?
                    record.int; record.nil_or(:bool); record.int
                    next
                  end                  
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
                else
                  echoln "[CableClub] Símbolo desconocido recibido: #{t}"
                end
              end
              
              # Limpieza de basura para evitar crash
              while !record.empty?
                basura = record.str rescue nil
                echoln "[CableClub] Datos sobrantes descartados: #{basura}"
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
end

 
#==============================================================================================
# DESCOMENTA PARA GENERAR UN .txt CON LOS NUMEROS GENERADOS DURANTE CADA TURNO DEL COMBATE
#==============================================================================================

=begin
module ZCable
  class BattleRNG
    def rand(max = nil)
      if max.is_a?(Integer)
        val = @rng.rand(max)
        req = "Int(#{max})"
      elsif max.is_a?(Float)
        val = @rng.rand(max)
        req = "Float(#{max})"
      else
        val = @rng.rand
        req = "Float(0.0-1.0)"
      end
      trace = caller(1, 1).first 

      trace = trace.split("/").last if trace
      log_line = sprintf("[%04d] %-15s => %-10s | %s", @call_count, req, val.to_s, trace)
      filename = "Z_RNG_LOG_CLIENTE_#{$player ? $player.id : 'UNKNOWN'}.txt"      
      
      File.open(filename, "a") do |f|
        f.puts(log_line)
      end
      @call_count += 1
      return val
    end
    
    def random
      return self.rand(nil)
    end
  end
end

#===============================================================================
# Marcadores de Contexto
#===============================================================================
class Battle
  alias z_debug_pbCommandPhase pbCommandPhase
  def pbCommandPhase
    log_marker("--- INICIO FASE DE COMANDOS (Turno #{@turnCount + 1}) ---")
    z_debug_pbCommandPhase
  end

  alias z_debug_pbAttackPhase pbAttackPhase
  def pbAttackPhase
    log_marker("--- INICIO FASE DE ATAQUE (Turno #{@turnCount + 1}) ---")
    z_debug_pbAttackPhase
  end
  
  def log_marker(msg)
    return unless @z_rng
    filename = "Z_RNG_LOG_CLIENTE_#{$player.id}.txt"
    File.open(filename, "a") { |f| f.puts("\n#{msg}\n") } rescue nil
  end
end

Dir.glob("Z_RNG_LOG_CLIENTE_*.txt").each { |f| File.delete(f) }
=end