class CableClub_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    @frames += 1
    @sprites["messagebox"].text    = @dots_message + "...".slice(0..(@frames/8) % 3) if @dots_message
  end
  
  def change_state(text=nil); @frames = 0; end
  
  def pbDisplay(text)
    @dots_message = nil
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    @sprites["messagebox"].letterbyletter = true
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      else
        if Input.trigger?(Input::B) || Input.trigger?(Input::C)
          break
        end
      end
    end
  end
  
  def pbDisplayDots(text)
    @sprites["messagebox"].text    = text + "...".slice(0..(@frames/8) % 3)
    @sprites["messagebox"].visible = true
    @sprites["messagebox"].letterbyletter = false
    @dots_message = text
  end
  
  def pbHideMessageBox
    @dots_message = nil
    @sprites["messagebox"].visible = false
    @sprites["messagebox"].text = ""
  end


  def pbEnterText(helptext, starttext, passwordbox, maxlength, regex_check = nil)
    @dots_message = nil
    @sprites["messagebox"].text    = helptext
    @sprites["messagebox"].visible = true
    @sprites["messagebox"].letterbyletter = false
    ret=""
    using(window = Window_TextEntry_Keyboard.new(starttext, 0, 0, 240, 64, nil, false, regex_check, maxlength)){
      window.maxlength=maxlength
      window.visible=true
      pbPositionNearMsgWindow(window,@sprites["messagebox"],:right)
      window.z = @viewport.z+1
      window.text=starttext
      window.passwordChar="*" if passwordbox
      Input.text_input = true
      loop do
        Graphics.update
        Input.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.triggerex?(:ESCAPE) && (!Input.triggerex?(0x30) || !Input.repeatex?(0x30)) # 0x30 es el codigo del 0 en el numpad
            ret=''
            break
          elsif Input.triggerex?(:RETURN)
            ret=window.text
            break
          end
        end
        window.update
      end
      Input.text_input = false
      window.dispose
      Input.update
    }
    return ret
  end
  
  def pbShowCommands(helptext,commands,cmdIfCancel=0)
    ret = -1
    @dots_message = nil
    @sprites["messagebox"].text    = helptext
    @sprites["messagebox"].visible = true
    @sprites["messagebox"].letterbyletter = false
    using(cmdwindow = Window_CommandPokemon.new(commands)) {
      cmdwindow.z     = @viewport.z+1
      pbPositionNearMsgWindow(cmdwindow,@sprites["messagebox"],:right)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        pbUpdate
        if Input.trigger?(Input::B)
          pbPlayCancelSE if cmdIfCancel!=0
          if cmdIfCancel>0
            ret=cmdIfCancel-1
            break
          elsif cmdIfCancel<0
            ret=cmdIfCancel
            break
          end
        elsif Input.trigger?(Input::C)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    }
    return ret
  end

  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"],2)
    @frames = 0
    @dots_message = nil
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
  
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  def pbSelectBattleSettings(partner_party,local_rules,server_rules)
    ret  = nil
    type = 0
    random_battle = false

    # Paso 1: Elegir tipo de combate
    battle_type_cmds = [_INTL("Mis Pokémon"), _INTL("Pokémon de Préstamo"), _INTL("Cancelar")]
    bt_cmd = pbShowCommands(_INTL("¿Qué Pokémon quieres usar?"), battle_type_cmds, -1)
    return [nil, nil] if bt_cmd < 0 || bt_cmd >= battle_type_cmds.length-1
    random_battle = (bt_cmd == 1)

    # Elegir si usar últimas reglas
    rules_choice_cmds = [_INTL("Nuevas reglas")]
    rules_choice_cmds.insert(0, _INTL("Últimas reglas")) if online_reglas_previas?
    rules_choice_cmds.push(_INTL("Salir"))

    cmd = pbShowCommands(_INTL("Elige con qué reglas jugar."), rules_choice_cmds, -1)
    return [nil, nil] if cmd < 0 || cmd == rules_choice_cmds.length - 1

    use_last_rules = false
    if online_reglas_previas? && cmd == 0
      use_last_rules = true
      if !use_last_rules
        cmd = 1  # Continuar como si hubiera elegido "Nuevas reglas"
      end
    elsif online_reglas_previas?
      cmd -= 1  # Ajustar índice para cuando existe "Últimas reglas"
    end

    if use_last_rules
      rules = PokemonOnlineRules.new
      rules.setRandomBattle if random_battle
      # Seteamos las reglas del random battle
      rules.set_random_battle_config($online_last_ruleset[:random_config])

      rules.setNumberRange(1, 6)
      rules.addPokemonRule(NonEggRestriction)

      case $online_last_ruleset[:battle_type]
      when :doble
        rules.setNumberRange(2, 6)
        rules.addBattleRule(DoubleBattle)
      when :triple
        rules.setNumberRange(3, 6)
        rules.addBattleRule(TripleBattle)
      end

      case $online_last_ruleset[:level_mode]
      when 1
        if $online_last_ruleset[:custom_level] && $online_last_ruleset[:custom_level] > 0
          rules.setLevelAdjustment(FixedLevelAdjustment, $online_last_ruleset[:custom_level])
        end
      when 2
        rules.setLevelAdjustment(FixedLevelAdjustment, 50)
      when 3
        rules.setLevelAdjustment(FixedLevelAdjustment, 100)
      end
      rules.setTeamPreview(30) if $online_last_ruleset[:team_preview]

      battle_type_string = _INTL("Batalla Individual")
      case $online_last_ruleset[:battle_type]
      when :doble;  battle_type_string = _INTL("Batalla Doble")
      when :triple; battle_type_string = _INTL("Batalla Triple")
      end

      level_string = _INTL("Libre")
      case $online_last_ruleset[:level_mode]
      when 1
        level = $online_last_ruleset[:custom_level] || 50
        level_string = _INTL("Nv. {1}", level)
      when 2
        level_string = _INTL("Nv. 50")
      when 3
        level_string = _INTL("Nv. 100")
      end

      desc = online_ruleset_to_desc($online_last_ruleset)
      return [[desc, desc, rules], 0]
    else

      # Configuraciones si se elige modo préstamo
      if random_battle
        # 1. Preparamos el hash
        random_config = {
          allow_mega: false,
          allow_mega_item: false,
          allow_singulars: false,
          allow_major_legendaries: false,
          allow_minor_legendaries: false,
          allow_ultra_beasts: false,
          allow_paradoxes: false
        }
        # Preguntar sobre megas
        if pbShowCommands(_INTL("¿Quieres usar Megaevoluciones? Necesitas haber obtenido el Megaaro para activarlas."), [_INTL("Sí"), _INTL("No")], 2) == 0
          random_config[:allow_mega] = true
          random_config[:allow_mega_item] = true
        end

        # Preguntar sobre legendarios
        legends_choice = pbShowCommands(_INTL("¿Quieres que haya Legendarios y Singulares?"),
          [_INTL("Sí"), _INTL("Elegir restringidos"), _INTL("No")], 3)

        case legends_choice
        when 0
          random_config[:allow_singulars]         = true
          random_config[:allow_major_legendaries] = true
          random_config[:allow_minor_legendaries] = true
          random_config[:allow_ultra_beasts]      = true
          random_config[:allow_paradoxes]         = true
        when 1
          legend_options = [
            [_INTL("[  ] Legendarios Mayores"),    :allow_major_legendaries],
            [_INTL("[  ] Legendarios Menores"),    :allow_minor_legendaries],
            [_INTL("[  ] Singulares"),             :allow_singulars],
            [_INTL("[  ] Ultraentes"),             :allow_ultra_beasts],
            [_INTL("[  ] Pokémon Paradoja"),       :allow_paradoxes],
            [_INTL("Confirmar los seleccionados"), :done]
          ]
          loop do
            current_options = legend_options.map { |opt, key|
              next opt if key == :done
              flag = random_config[key]
              opt.sub("[  ]", flag ? "[X]" : "[  ]")
            }
            choice = pbShowCommands(_INTL("Elige qué tipos de Pokémon permites."), current_options, -1)
            break if choice == legend_options.length - 1
            key = legend_options[choice][1]
            random_config[key] = !random_config[key]
          end
        end
        # Guardamos la random config en las últimas reglas
        $online_last_ruleset[:random_config] = random_config
      end


      # Paso 3: Elegir el tipo de combate.
      commands = []
      cmdSingleBattle  = -1
      cmdDoubleBattle  = -1
      cmdTripleBattle  = -1
      cmdRandomBattle  = -1
      cmdLocalRule     = -1
      cmdServerRule    = -1
      cmdSalir         = -1
      commands[cmdSingleBattle = commands.length]  = _INTL("Batalla Individual")
      commands[cmdDoubleBattle = commands.length]  = _INTL("Batalla Doble")
      commands[cmdTripleBattle = commands.length]  = _INTL("Batalla Triple")
      #commands[cmdLocalRule = commands.length]     = _INTL("Cargar reglas locales") if local_rules && !local_rules.empty?
      #commands[cmdServerRule = commands.length]    = _INTL("Cargar reglas del servidor") if server_rules && !server_rules.empty?
      commands[cmdSalir = commands.length]         = _INTL("Salir")
      loop do
        break if ret
        cmd = pbShowCommands(_INTL("Elige el tipo de combate que queréis hacer."),commands,-1)
        if cmd < 0 || cmd >= commands.length - 1
          online_limpiar_reglas_previas
          return [nil, nil]
        end
        if (cmdSingleBattle>=0 && cmd==cmdSingleBattle) ||
          (cmdDoubleBattle>=0 && cmd==cmdDoubleBattle) ||
          (cmdTripleBattle>=0 && cmd==cmdTripleBattle)
          rules=PokemonOnlineRules.new
          rules.setRandomBattle if random_battle
          rules.set_random_battle_config(random_config)
          rules.setNumberRange(1,6)
          rules.addPokemonRule(NonEggRestriction)
          if cmd == cmdDoubleBattle
            rules.setNumberRange(1,6) # No pedir mínimo de Pokémon
            rules.addBattleRule(DoubleBattle)
            $online_last_ruleset[:battle_type] = :doble
          elsif cmd == cmdTripleBattle
            rules.setNumberRange(1,6) # No pedir mínimo de Pokémon
            rules.addBattleRule(TripleBattle)
            $online_last_ruleset[:battle_type] = :triple
          else
            $online_last_ruleset[:battle_type] = :singles
          end
          if !rules.ruleset.hasRegistrableTeam?($player.party)
            pbDisplay(_INTL("Lo siento, parece que no tienes un equipo Pokémon válido con estas reglas."))
          elsif !rules.ruleset.hasRegistrableTeam?(partner_party)
            pbDisplay(_INTL("Lo siento, parece que tu compañero no tiene un equipo Pokémon válido con estas reglas."))
          else
            # ELECCIÓN DEL NIVEL DEL COMBATE
            bracket_cmds = []
            bracket_cmds.push(_INTL("Libre")) unless random_battle
            bracket_cmds.concat([_INTL("Nv. 50"), _INTL("Nv. 100"), _INTL("Elegir nivel"), _INTL("Salir")])
            
            if random_battle
              bracket = pbShowCommands(_INTL("Elige el nivel de todos los Pokémon."), bracket_cmds, -1)
            else
              bracket = pbShowCommands(_INTL("Elige el nivel de todos los Pokémon (o libre para que no se modifiquen)."), bracket_cmds, -1)
            end

            # Salir
            if bracket < 0 || bracket == bracket_cmds.length - 1
              online_limpiar_reglas_previas
              return [nil, nil]
            end
            
            if bracket >= 0
              # Ajustar índice si no hay opción "Libre"
              adjusted_bracket = random_battle ? bracket + 1 : bracket
              
              case adjusted_bracket
              # Libre (solo para batallas normales)
              when 0
                $online_last_ruleset[:level_mode] = 0
              # Nivel 50
              when 1
                rules.setLevelAdjustment(FixedLevelAdjustment, 50)
                $online_last_ruleset[:level_mode] = 2
              # Nivel 100
              when 2
                rules.setLevelAdjustment(FixedLevelAdjustment, 100)
                $online_last_ruleset[:level_mode] = 3
              # Elegir nivel
              when 3
                params = ChooseNumberParams.new
                params.setMaxDigits(3)
                params.setRange(1,100)
                params.setDefaultValue($online_last_ruleset[:custom_level] || 50)
                params.setCancelValue(-1)
                level = pbMessageChooseNumber("Elige el nivel para el combate.", params)
                if level > 0
                  rules.setLevelAdjustment(FixedLevelAdjustment, level)
                  $online_last_ruleset[:level_mode] = 1
                  $online_last_ruleset[:custom_level] = level
                end
              end
              if pbConfirmMessage(_INTL("¿Quieres que haya Sleep Clause? (esto impedirá que se duerma a más de 1 Pokémon a la vez)"))
                rules.addBattleRule(SleepClause)
              end
              if !random_battle && pbConfirmMessage(_INTL("¿Quieres que haya Item Clause? (esto impedirá que se repitan los objetos)"))
                rules.addTeamRule(ItemClause)
              end
              desc = online_ruleset_to_desc($online_last_ruleset)
              ret = [desc, desc, rules]

              # Elección de que haya Team preview
              if pbShowCommands(_INTL("¿Quieres que ambos equipos se vean antes del combate?"), [_INTL("Sí"), _INTL("No")], 2) == 0
                ret[1] += " + Team Preview."
                ret[2].setTeamPreview(30)
                $online_last_ruleset[:team_preview] = true
              else
                $online_last_ruleset[:team_preview] = false
              end
              break
            end
          end 
=begin
        # REGLAS LOCALES O DEL SERVIDOR (NO USADO)
        elsif (cmdLocalRule>=0 && cmd==cmdLocalRule) ||
              (cmdServerRule>=0 && cmd==cmdServerRule)
          commands = []
          rule_array = []
          rule_array = local_rules if cmd == cmdLocalRule
          rule_array = server_rules if cmd == cmdServerRule
          rule_array.each do |r|
            commands.push(r[0])
          end
          r_cmd = pbShowCommands(_INTL("Elige el reglamento del combate"),commands,-1)
          if r_cmd>=0
            loop do
              conf_cmd = pbShowCommands(_INTL("Reglamento: {1}",rule_array[r_cmd][0]),[_INTL("Sí"),_INTL("Ver Detalles"),_INTL("No")],3)
              case conf_cmd
              when 1
                pbDisplay(rule_array[r_cmd][1])
              when 0
                rules = rule_array[r_cmd][2]
                if !rules.ruleset.hasRegistrableTeam?($player.party)
                  pbDisplay(_INTL("Lo siento, no tienes un equipo Pokémon válido, con estas reglas."))
                elsif !rules.ruleset.hasRegistrableTeam?(partner_party)
                  pbDisplay(_INTL("Lo siento, tu compañero no tiene un equipo Pokémon válido, con estas reglas."))
                else
                  ret = rule_array[r_cmd]
                  type = ((cmd==cmdLocalRule) ? 1 : 2)
                  break
                end
              when 2
                break
              end
            end
          end
=end
        else
          break
        end
      end
    end
    return ret,type
  end


  def online_ruleset_to_desc(ruleset)
    battle_type_string = _INTL("Batalla Individual")
    case ruleset[:battle_type]
    when :doble;  battle_type_string = _INTL("Batalla Doble")
    when :triple; battle_type_string = _INTL("Batalla Triple")
    end

    level_string = _INTL("Libre")
    case ruleset[:level_mode]
    when 1
      level = ruleset[:custom_level] || 50
      level_string = _INTL("Nv. {1}", level)
    when 2
      level_string = _INTL("Nv. 50")
    when 3
      level_string = _INTL("Nv. 100")
    end

    desc = _INTL("{1} ({2})", battle_type_string, level_string)
    desc += _INTL(" + Vista de equipo.") if ruleset[:team_preview]
    return desc
  end


  
  def pbTeamPreview(partner_trainer,partner_party,timer)
    dummy_trainer = NPCTrainer.new($player.name,$player.online_trainer_type)
    pbFadeOutIn(99999){
      scene = TeamPreview_Scene.new
      screen = TeamPreviewScreen.new(scene)
      screen.pbStartScreen(dummy_trainer,$player.party,partner_trainer,partner_party,timer)
    }
  end
end

class CableClubScreen
  def initialize(scene)
    @scene = scene
    @state = nil
    @client_id = 0
    @partner_name = nil
    @partner_trainertype = nil
    @partner_party = nil
    @partner_win_text = nil
    @partner_lose_text = nil
    @local_rules = nil
    @server_rules = nil
    @chosen_pokemon = nil
    @partner_chosen = nil
    @battle_settings = nil
    load_local_rules
  end
  
  def load_local_rule(filename)
    begin
      name=nil
      desc=nil
      rules=PokemonOnlineRules.new
      lineno=0
      category=0
      targetno=-1
      File.foreach(sprintf("%s/%s",CableClub::FOLDER_FOR_BATTLE_PRESETS,filename))do |line|
        line = line.chomp
        case lineno
        when 0
          raise "comma found \"#{line}\", aborting load" if line.index(',')
          name = line
        when 1
          raise "comma found \"#{line}\", aborting load" if line.index(',')
          desc = line
        when 2; rules.setTeamPreview(line.to_i)
        when 3
          line[/(\d+),(\d+)/]
          minValue = $~[1].to_i
          maxValue = $~[2].to_i
          rules.setNumberRange(minValue,maxValue)
        when 4
          if !line.empty?
            level_adjustment_data = line.split(";")
            level_adjustmentClass = level_adjustment_data.shift
            level_adjustment_args = CableClub::process_args_type_hint(*level_adjustment_data)
            if Object.const_defined?(level_adjustmentClass)
              rules.setLevelAdjustment(Kernel.const_get(level_adjustmentClass),*level_adjustment_args)
            end
          end
        else
          if targetno<0
            targetno = lineno + line.to_i
          else
            clause_data = line.split(";")
            clauseClass = clause_data.shift
            clause_args = CableClub::process_args_type_hint(*clause_data)
            if Object.const_defined?(clauseClass)
              case category
              when 0 #battle
                rules.addBattleRule(Kernel.const_get(clauseClass),*clause_args)
              when 1 #pokemon
                rules.addPokemonRule(Kernel.const_get(clauseClass),*clause_args)
              when 2 #subset
                rules.addSubsetRule(Kernel.const_get(clauseClass),*clause_args)
              when 3 #team
                rules.addTeamRule(Kernel.const_get(clauseClass),*clause_args)
              end
            end
          end
          if lineno == targetno
            category +=1
            targetno =-1
          end
        end
        lineno+=1
      end
    rescue
      return nil
    end
    return [name,desc,rules]
  end
  
  def load_local_rules
    begin
      files = []
      Dir.chdir(CableClub::FOLDER_FOR_BATTLE_PRESETS + "/"){
        Dir.glob("*.rules") {|f| files.push(f)}
      }
    rescue
      return
    end
    rules = []
    files.each do |f|
      r=load_local_rule(f)
      rules.push(r) if r
    end
    @local_rules = rules
  end
  
  def change_state(new_state)
    if @state != new_state
      @scene.change_state
    end
    @state = new_state
    if block_given?
      loop do
        break if self.update
        yield
      end
    end
  end
  
  def update
    Graphics.update
    Input.update
    @scene.pbUpdate
    if Input.press?(Input::BACK)
      #return false if @state == :choose_activity
      message = case @state
      when :await_server; _INTL("¿Cancelar conexión?")
      when :await_partner; _INTL("¿Cancelar búsqueda?")
      else; _INTL("¿Desconectarse?")
      end
      return true if pbConfirmSerious(message)
    end
    return false
  end
  
  def pbDisplay(text); @scene.pbDisplay(text); end
  def pbDisplayDots(text); @scene.pbDisplayDots(text); end
  def pbHideMessageBox; @scene.pbHideMessageBox; end
  def pbEnterText(helptext, starttext, passwordbox, maxlength, regex_check = nil)
    @scene.pbEnterText(helptext, starttext, passwordbox, maxlength, regex_check)
  end
  def pbShowCommands(helptext, commands, cmdIfCancel=0)
    return @scene.pbShowCommands(helptext, commands, cmdIfCancel)
  end
  def pbConfirm(helptext); return (@scene.pbShowCommands(helptext,[_INTL("Sí"), _INTL("No")],2)==0); end
  def pbConfirmSerious(helptext); return (@scene.pbShowCommands(helptext,[_INTL("No"), _INTL("Sí")],1)==1); end
  
  def pbStartScreen
    @scene.pbStartScene
    pbConnectDisconnectSetup
    ret = pbAttemptConnection
    pbConnectDisconnectSetup(true)
    @scene.pbEndScene
    return ret
  end
  
  def pbConnectDisconnectSetup(disconnect=false)
    if disconnect
      $player.heal_party
      restore_original_team
      FollowingPkmn.toggle_on
    end
  end

  def connect_setup
    FollowingPkmn.toggle_off
    pbSet(76, $game_map.map_id)
    pbSet(1, 4)
    pbSet(2, 8)
    $game_switches[133] = false
    $game_switches[134] = false
    $game_switches[136] = false
    online_limpiar_reglas_previas
  end
  
  def pbAttemptConnection
    if $player.party_count == 0
      pbDisplay(_INTL("Lo siento, pero debes tener al menos un Pokémon para entrar al Modo Online."))
      return false
    end

    pbSEPlay("GUI save choice")
    slot = $player.save_slot
    if Game.save(slot)
      pbMessage("\\se[]" + _INTL("{1} guardó la partida.", $player.name) + "\\me[GUI save game]\\wtnp[20]")
    else
      pbMessage("\\se[]" + _INTL("El guardado ha fallado.") + "\\wtnp[30]")
      save_failed = true
    end
    return false if save_failed
    connect_setup

    loop do
      begin
        msg = _ISPRINTF("Código de la sala:")
        group_id = ""
        regex_check = /[0-9]/
        loop do
          # CAMBIAR EL 2 POR LA CANTIDAD DE NÚMEROS QUE QUEREMOS PARA EL CÓDIGO
          pbMessage("Ahora tendrás que poner el código de la sala a la que te quieres conectar. Deberás inventarte un número de 8 dígitos, y que la otra persona ponga el mismo código.")
          group_id = pbEnterText(msg, group_id, false, CableClub::GROUP_ID_LENGTH, regex_check)
          if group_id.empty?
            pbHideMessageBox  
            if pbConfirmMessage(_INTL("No has introducido ningún código. ¿Quieres salir?"))
              return false
            else
              next
            end
          end
          break if group_id =~ /^[0-9]{#{CableClub::GROUP_ID_LENGTH}}$/
        end
        pbConnectServer(group_id)
        raise Connection::Disconnected.new("disconnected")

      rescue Connection::Disconnected => e
        case e.message
        when "disconnected"
          pbDisplay(_INTL("Gracias por usar el Modo Online. Esperamos verte de nuevo pronto."))
          $game_switches[135] = true
          return true
        when "invalid party"
          pbDisplay(_INTL("Lo siento, tu equipo contiene Pokémon no permitidos en el Modo Online."))
          return false
        when "peer disconnected"
          pbDisplay(_INTL("El otro Entrenador se ha desconectado. Gracias por usar el Modo Online."))
          return true
        when "invalid version"
          pbDisplay(_INTL("Lo siento, tu juego está desactualizado para el Modo Online. Actualizalo e intentalo de nuevo."))
          return false
        when "group full"
          pbDisplay(_INTL("Lo sentimos. El grupo #{group_id} ya está lleno, prueba con otro."))
          next   # <-- vuelve al inicio del bucle para pedir otro código
        when "connection timed out"
          pbDisplay(_INTL("Error de conexión: tiempo de espera agotado."))
          return false
        else
          pbDisplay(_INTL("Lo siento, ha ocurrido un error inesperado."))
          return false
        end

      rescue Errno::ECONNABORTED
        pbDisplay(_INTL("El otro Entrenador se ha desconectado. Gracias por usar el Modo Online."))
        return true
      rescue Errno::ECONNREFUSED
        pbDisplay(_INTL("Lo siento, el Modo Online no está disponible en estos momentos."))
        return false
      rescue
        pbPrintException($!)
        pbDisplay(_INTL("Lo siento, ha ocurrido un error inesperado."))
        return false
      ensure
        pbHideMessageBox
      end
    end
  end

  
  def pbConnectServer(group_id)
    host,port = CableClub::get_server_info
    Connection.open(host,port) do |connection|
      await_server(connection,group_id)
    end
  end
  
  # These states handle the connection process itself
  def await_server(connection,group_id)
    change_state(:await_server){
      if connection.can_send?
        connection.send do |writer|
          writer.sym(:find)
          writer.str(Settings::GAME_VERSION)
          writer.int(group_id)
          writer.str($player.name)
          writer.int($player.id)
          writer.sym($player.online_trainer_type)
          writer.int($player.online_win_text)
          writer.int($player.online_lose_text)
          CableClub::write_party(writer)
        end
        break
      else
        pbDisplayDots(_ISPRINTF("Conectando al grupo {1:05d}",group_id))
      end
    }
    await_partner(connection,group_id)
  end
  
  def await_partner(connection,group_id)
    partner_found = false
    change_state(:await_partner){  
      pbDisplayDots(_ISPRINTF("Buscando el grupo {1:05d}",group_id))
      connection.update do |record|
        case (type = record.sym)
        when :found
          @client_id = record.int
          @partner_name = record.str
          @partner_trainertype = record.sym
          @partner_win_text = record.int
          @partner_lose_text = record.int
          @partner_party = CableClub::parse_party(record)
          @server_rules = CableClub::parse_battle_rules(record)

          # Guardamos los valores en una variable global
          $partner_online = [@partner_name, @partner_trainertype, @partner_win_text, @partner_lose_text, @partner_party, @server_rules]

          partner_found = true
        else
          echoln "Unknown message: #{type}"
        end
      end
      break if partner_found
    }
    if partner_found
      pbDisplay(_INTL("¡{1} se ha conectado!", @partner_name))
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    end
  end
  
  def choose_activity(connection)
    # Recuperamos equipo original si estaba guardado.
    exchange_teams(connection) if restore_original_team

    # Apagamos el PC del tradeo si estaba encendido.
    $game_switches[ENCENDER_PC_ONLINE] = false

    cmds = [_INTL("Combate"), _INTL("Intercambio")]
    cmds.push(_INTL("Mix Records")) if CableClub::ENABLE_RECORD_MIXER
    cmds.push(_INTL("Salir"))
    cmd = -1
    change_state(:choose_activity){
      cmd = pbShowCommands(_INTL("Elige una actividad."), cmds, -1)
      break
    } 
    case cmd
    when 0 # Battle
      @battle_settings = nil
      choose_battle_settings(connection)
    when 1 # Trade
      connection.send do |writer|
        writer.sym(:trade)
      end
      await_accept_activity(connection,:trade,:choose_trade_pokemon)
    when 2 && CableClub::ENABLE_RECORD_MIXER # # Mix Records
      connection.send do |writer|
        writer.sym(:record_mix)
      end
      await_accept_activity(connection,:record_mix,:do_mix_records)
    else # Cancel/Disconnect
      if pbConfirmMessage("¿Estás seguro que quieres salir del Modo Online?")
        connection.send do |writer|
          writer.str("disconnect")
          writer.str("peer disconnected")
        end
        # raise Connection::Disconnected.new("disconnect")
      else
        connection.send do |writer|
          writer.sym(:noop)
        end
        connection.discard(1)
        choose_activity(connection)
      end
    end
  end
  
  def await_accept_activity(connection,activity,method_on_accept)
    accepted = nil
    change_state(:await_accept_activity){
      pbDisplayDots(_INTL("Esperando a que {1} acepte", @partner_name))
      connection.update do |record|
        case (type = record.sym)
        when :ok
          accepted = true
        when :cancel
          accepted = false
        else
          echoln "Unknown message: #{type}"
        end
      end
      break unless accepted.nil?
    }
    if accepted
      self.send(method_on_accept,connection)
    else
      activity_name = _INTL(CableClub::ACTIVITY_OPTIONS[activity])
      pbDisplay(_INTL("Parece que {1} ha rechazado {2}.", @partner_name, activity_name))
      choose_activity(connection)
    end
  end
  
  def await_choose_activity(connection)
    
    # Recuperamos posible equipo original
    exchange_teams(connection) if restore_original_team

    method_for_accepting = nil
    change_state(:await_choose_activity){
      pbDisplayDots(_INTL("Esperando a que {1} elija qué hacer", @partner_name))
      connection.update do |record|
        case (type = record.sym)
        when :battle
          method_for_accepting = :partner_accept_battle
          seed = record.int
          battle_origin = record.int
          battle_rule = CableClub::parse_battle_rule(record)
          @battle_settings = [seed,battle_rule,battle_origin]
        when :trade
          method_for_accepting = :partner_accept_trade
        when :record_mix
          method_for_accepting = :partner_accept_record_mix
        when :noop
          # No hace nada
        else
          echoln "Unknown message: #{type}"
        end
      end
      break if method_for_accepting
    }
    self.send(method_for_accepting,connection) if method_for_accepting
  end
  
  # These methods handle battles
  def choose_battle_settings(connection)
    battle_rule,battle_origin = @scene.pbSelectBattleSettings(@partner_party,@local_rules,@server_rules)
    if battle_rule
      seed = rand(2**31)
      connection.send do |writer|
        writer.sym(:battle)
        writer.int(seed)
        writer.int(battle_origin)
        CableClub::write_battle_rule(writer,battle_rule)
      end
      @battle_settings = [seed,battle_rule,battle_origin]

      # 🔧 Enviar y recibir equipos justo después de seleccionar reglas
      exchange_teams(connection) if restore_original_team

      await_accept_activity(connection,:battle,:battle_check_team_preview)
    else
      connection.send do |writer|
        writer.sym(:cancel)
      end
      connection.discard(1)
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    end
  end
  
  def partner_accept_battle(connection)
    accepted = false
    origin_string = [_INTL("Reglamento"),_INTL("Reglamento Local"),_INTL("Reglamento Servidor")][@battle_settings[2]]
    loop do
      cmd = pbShowCommands(_INTL("¡{1} quiere combatir!\n{2}: {3}", @partner_name,origin_string,@battle_settings[1][0]),[_INTL("Sí"),_INTL("Ver detalles"),_INTL("No")],3)
      case cmd
      when 1  # Detalles
        pbDisplay(@battle_settings[1][1])
      when 0  # Aceptar
        accepted = true
        connection.send do |writer|
          writer.sym(:ok)
        end
        break
      when 2  # Cancelar
        connection.send do |writer|
          writer.sym(:cancel)
        end
        break
      end
    end
    if accepted
      battle_check_team_preview(connection)
    else
      await_choose_activity(connection)
    end
  end

  def apply_random_config_to_generator(config)
    RandomTeamGenerator.allow_mega              = config[:allow_mega]
    RandomTeamGenerator.allow_mega_item         = config[:allow_mega_item]
    RandomTeamGenerator.allow_singulars         = config[:allow_singulars]
    RandomTeamGenerator.allow_major_legendaries = config[:allow_major_legendaries]
    RandomTeamGenerator.allow_minor_legendaries = config[:allow_minor_legendaries]
    RandomTeamGenerator.allow_ultra_beasts      = config[:allow_ultra_beasts]
    RandomTeamGenerator.allow_paradoxes         = config[:allow_paradoxes]
  end

  def battle_check_team_preview(connection)
    team_order = nil
    partner_order = nil
    cancel_battle = false
    cancel_partner = false
    battle_rules = @battle_settings[1][2]

    # Check de batalla random
    if battle_rules.random_battle?
      apply_random_config_to_generator(battle_rules.random_config)
      generate_temp_team
      exchange_teams(connection)
    end

    # Team preview
    if battle_rules.team_preview?
      level_adjust = battle_rules.rules_hash[:level_adjust]
      level_string = _INTL("Libre")
      if level_adjust
        level_string = _INTL("Cust.")
        if level_adjust[0] == FixedLevelAdjustment
          level_string = sprintf("%d", level_adjust[1][1])
        end
      end
      partner = NPCTrainer.new(@partner_name, @partner_trainertype)
      @scene.pbTeamPreview(partner, @partner_party, battle_rules.team_preview)
    end

    # Elección de orden de equipo
    team_order = CableClub::choose_team(battle_rules.ruleset)

    if team_order
      if @client_id == 0
        # Jugador 0 envía primero, luego espera
        connection.send do |writer|
          writer.sym(:ok)
          writer.int(team_order.length)
          team_order.each { |i| writer.int(i) }
        end

        change_state(:await_battle_order) {
          pbDisplayDots(_INTL("Esperando a que {1} elija su equipo", @partner_name))
          connection.update do |record|
            case (type = record.sym)
            when :ok
              partner_order = []
              record.int.times { partner_order.push(record.int) }
            when :cancel
              cancel_partner = true
            else
              echoln "Unknown message: #{type}"
            end
          end
          break if !partner_order.empty? || cancel_partner
        }
        pbHideMessageBox
      else
        # Jugador 1 espera primero, luego envía
        responded = false
        change_state(:await_battle_order) {
          pbDisplayDots(_INTL("Esperando a que {1} elija su equipo", @partner_name))
          connection.update do |record|
            case (type = record.sym)
            when :ok
              partner_order = []
              record.int.times { partner_order.push(record.int) }
              unless responded
                connection.send do |writer|
                  writer.sym(:ok)
                  writer.int(team_order.length)
                  team_order.each { |i| writer.int(i) }
                end
                responded = true
              end
            when :cancel
              cancel_partner = true
            else
              echoln "Unknown message: #{type}"
            end
          end
          break if !partner_order.empty? || cancel_partner
        }
        pbHideMessageBox
      end
    else
      # Cancelaste la selección de equipo
      connection.send do |writer|
        writer.sym(:cancel)
      end
      connection.discard(1)
      cancel_battle = true
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
      return
    end

    if cancel_battle || cancel_partner
      # Recuperamos posible equipo original
      exchange_teams(connection) if restore_original_team
      pbDisplay(_INTL("Parece que {1} no quiere combatir.", @partner_name)) if cancel_partner
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    else
      do_battle(connection, team_order, partner_order)
      exchange_teams(connection) if restore_original_team
    end
  end

  
  def do_battle(connection,team_order,partner_order)
    partner = NPCTrainer.new(@partner_name, @partner_trainertype)
    partner.win_text =  _INTL(CableClub::ONLINE_WIN_SPEECHES_LIST[@partner_win_text])
    partner.lose_text = _INTL(CableClub::ONLINE_LOSE_SPEECHES_LIST[@partner_lose_text])
    seed,battle_rules = @battle_settings
    party_player = $player.party
    if team_order
      party_player=[]
      team_order.each do |i|
        party_player.push($player.party[i])
      end
    end
    party_partner = @partner_party
    if partner_order
      party_partner=[]
      partner_order.each do |i|
        party_partner.push(@partner_party[i])
      end
    end
    decision = CableClub::do_battle(connection, @client_id, seed, battle_rules[2], party_player, partner, party_partner)
    # Recuperamos posible equipo original
    exchange_teams(connection) if restore_original_team

    @battle_settings = nil
    if @client_id == 0
      choose_activity(connection)
    else
      await_choose_activity(connection)
    end
  end
  
  # These methods handle trading pokemon
  def partner_accept_trade(connection)
    if pbConfirm(_INTL("¡{1} quiere intercambiar!", @partner_name))
      connection.send do |writer|
        writer.sym(:ok)
      end
      choose_trade_pokemon(connection)
    else
      connection.send do |writer|
        writer.sym(:cancel)
      end
      await_choose_activity(connection)
    end
  end
  
  def choose_trade_pokemon(connection)
    
    # Borramos los mensajes anteriores.
    pbHideMessageBox

    # Saltamos a la sala del Intercambio.
    CableClub.transfer_to_trade_room if !$game_switches[134] 

    @chosen_pokemon = CableClub.choose_pokemon
    if @chosen_pokemon >= 0
      connection.send do |writer|
        writer.sym(:ok)
        writer.int(@chosen_pokemon)
      end
      confirm_trade_pokemon(connection)
    else
      connection.send do |writer|
        writer.sym(:cancel)
      end
      connection.discard(1)
      if @client_id == 0
        choose_activity(connection)
      else
        await_choose_activity(connection)
      end
    end
  end
  
  def confirm_trade_pokemon(connection)
    @partner_chosen = nil
    change_state(:await_trade){
      pbDisplayDots(_INTL("Esperando a que {1}\nelija un Pokémon", @partner_name))
      connection.update do |record|
        case (type = record.sym)
        when :ok
          @partner_chosen = record.int
        when :cancel
          @partner_chosen = -1
        else
          echoln "Unknown message: #{type}"
        end
      end
      break if !@partner_chosen.nil?
    }
    trade_state = :waiting
    if @partner_chosen && @partner_chosen>=0
      $player.heal_party
      @partner_party.each {|pkmn| pkmn.heal}
      partner_pkmn = @partner_party[@partner_chosen]
      your_pkmn = $player.party[@chosen_pokemon]
      abort=$player.able_pokemon_count==1 && your_pkmn==$player.able_party[0] && partner_pkmn.egg?
      able_party=@partner_party.find_all { |p| p && !p.egg? && p.hp>0 }
      abort|=able_party.length==1 && partner_pkmn==able_party[0] && your_pkmn.egg?
      unless abort
        partner_speciesname = (partner_pkmn.egg?) ? _INTL("Huevo") : partner_pkmn.speciesName
        your_speciesname = (your_pkmn.egg?) ? _INTL("Huevo") : your_pkmn.speciesName
        loop do
          cmd = pbShowCommands(_INTL("{1} ofrece {2} ({3}) por tu {4} ({5}).",
                                      @partner_name,partner_pkmn.name,partner_speciesname,your_pkmn.name,your_speciesname),
                                      [_INTL("Ver la propuesta de {1}",@partner_name), _INTL("Ver mi propuesta"), _INTL("Aceptar Intercambio"),_INTL("Rechazar Intercambio")],-1)
          case cmd
          when 0 # Partner offer
            CableClub::check_pokemon(partner_pkmn)
          when 1 # Your offer
            CableClub::check_pokemon(your_pkmn)
          when 2 # Accept Trade
            trade_state = :ok
            connection.send do |writer|
              writer.sym(:ok)
            end
            break
          when 3 # Deny Trade
            trade_state = :denied
            connection.send do |writer|
              writer.sym(:cancel)
            end
            connection.discard(1)
            break
          else
            trade_state = :denied
            connection.send do |writer|
              writer.sym(:cancel)
            end
            connection.discard(1)
            pbMessage(_INTL("Has cancelado el intercambio."))
            break
          end
        end
        await_trade_partner(connection) if trade_state == :ok
      else
        trade_state = :abort
      end
    else
      trade_state = :cancel
    end
    @chosen_pokemon = nil
    @partner_chosen = nil
    case trade_state
    when :cancel; pbDisplay(_INTL("Lo siento, {1} no quiere intercambiar.", @partner_name))
    when :abort; pbDisplay(_INTL("Lo siento, el intercambio con {1} no pudo ser completado.", @partner_name))
    end
    if @client_id == 0
      choose_activity(connection)
    else
      await_choose_activity(connection)
    end
  end
  
  def await_trade_partner(connection)
    partner_confirm = nil
    change_state(:confirm_trade){
      pbDisplayDots(_INTL("Esperando a que {1}\nconfirme el intercambio", @partner_name))
      connection.update do |record|
        case (type = record.sym)
        when :ok
          partner_confirm = true
        when :cancel
          partner_confirm = false
        else
          echoln "Unknown message: #{type}"
        end
      end
      break if !partner_confirm.nil?
    }
    if partner_confirm
      do_trade(connection)
    else
      pbDisplay(_INTL("{1} rechazó el intercambio.", @partner_name))
    end
  end
  
  def do_trade(connection)
    partner = NPCTrainer.new(@partner_name, @partner_trainertype)
    pkmn = @partner_party[@partner_chosen]
    CableClub::do_trade(@chosen_pokemon, partner, pkmn)
    connection.send do |writer|
      writer.sym(:update)
      CableClub::write_pkmn(writer, $player.party[@chosen_pokemon])
    end
    resync=false
    change_state(:resync_trade){
      pbDisplayDots(_INTL("Esperando a que {1} resincronice", @partner_name))
      connection.update do |record|
        case (type = record.sym)
        when :update
          @partner_party[@partner_chosen] = CableClub::parse_pkmn(record)
          resync = true
        else
          echoln "Unknown message: #{type}"
        end
      end
      break if resync
    }
  end
  
  # these methods are for record mixing
  def partner_accept_record_mix(connection)
    if pbConfirm(_INTL("¡{1} quiere compartir récords!", @partner_name))
      connection.send do |writer|
        writer.sym(:ok)
      end
      do_mix_records(connection)
    else
      connection.send do |writer|
        writer.sym(:cancel)
      end
      await_choose_activity(connection)
    end
  end
  
  def do_mix_records(connection)
    CableClub::do_mix_records(connection) do |text|
      pbDisplayDots(text)
    end
    pbDisplay(_INTL("¡Mezcla de récords completada!"))
    if @client_id == 0
      choose_activity(connection)
    else
      await_choose_activity(connection)
    end
  end


  def exchange_teams(connection, symbol = :team_party)
    if @client_id == 0
      connection.send do |writer|
        writer.sym(symbol)
        CableClub.write_party(writer)
      end
      wait_for_partner_team(connection, symbol)
    else
      wait_for_partner_team(connection, symbol)
      connection.send do |writer|
        writer.sym(symbol)
        CableClub.write_party(writer)
      end
    end
  end

  def wait_for_partner_team(connection, symbol = :team_party)
    @partner_party = nil
    change_state(:await_team_sync) {
      pbDisplayDots(_INTL("Sincronizando datos de {1}", @partner_name))
      connection.update do |record|
        case record.sym
        when symbol
          @partner_party = CableClub.parse_party(record)
        when :cancel
          raise Connection::Disconnected.new("cancel")
        end
      end
      break if @partner_party
    }
  end
end

class TeamPreview_Scene
  def update
    pbUpdateSpriteHash(@sprites)
    if @enable_timer
      curtime=@timer-(Time.now-@start)
      if curtime != @total_sec
        # Calculate total number of seconds
        @total_sec = curtime
        # Make a string for displaying the timer
        min = @total_sec / 60
        sec = @total_sec % 60
        @sprites["timer"].text = _ISPRINTF("<ac>{1:02d}:{2:02d} (pulsa X para salir ya)", min, sec)
      end
    end
  end

  def pbStartScene(left_trainer,left_party,right_trainer,right_party,timer)
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    addBackgroundPlane(@sprites,"background","CableClub/bg_team_preview",@viewport)
    @sprites["card"]=IconSprite.new(0,16,@viewport)
    if Essentials::VERSION =~ /^20/
      @sprites["card"].setBitmap("Graphics/Pictures/CableClub/overlay_team_preview")
    else
      @sprites["card"].setBitmap("Graphics/UI/CableClub/overlay_team_preview")
    end
    left_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*80)
      @sprites["party_l#{i}"] = PokemonIconSprite.new(pkmn,@viewport)
      @sprites["party_l#{i}"].x = base_x + 32
      @sprites["party_l#{i}"].y = base_y + 52
      @sprites["item_l#{i}"] = HeldItemIconSprite.new((base_x+72),(base_y+96),pkmn,@viewport)
    end
    right_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*80)
      @sprites["party_r#{i}"] = PokemonIconSprite.new(pkmn,@viewport)
      @sprites["party_r#{i}"].x = base_x + 288
      @sprites["party_r#{i}"].y = base_y + 52
      @sprites["item_r#{i}"] = HeldItemIconSprite.new((base_x+328),(base_y+96),pkmn,@viewport)
    end
    @sprites["timer"] = Window_AdvancedTextPokemon.newWithSize("",0,Graphics.height-64,Graphics.width,64)
    @sprites["timer"].viewport = @viewport
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTeamPreviewText(left_trainer.name,right_trainer.name,left_party,right_party)
    @start=Time.now
    @timer=timer
    @total_sec=@timer
    @enable_timer = false
    pbFadeInAndShow(@sprites) { update }
  end

  def pbDrawTeamPreviewText(left_name,right_name,left_party,right_party)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor=Color.new(216,216,216)
    shadowColor=Color.new(80,80,80)
    text_pos = [
      [left_name,114,22,2,baseColor,shadowColor],
      [right_name,398,22,2,baseColor,shadowColor],
    ]
    left_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*86)
      text_pos.push([pkmn.name,(base_x+64),(base_y+122-12),2,baseColor,shadowColor])
      if pkmn.male?
        text_pos.push([_INTL("♂"),(base_x+96),(base_y+70),false,Color.new(0,112,248),Color.new(120,184,232)])
      elsif pkmn.female?
        text_pos.push([_INTL("♀"),(base_x+96),(base_y+70),false,Color.new(232,32,16),Color.new(248,168,184)])
      end
    end
    right_party.each_with_index do |pkmn, i|
      base_x = ((i%2)*128)
      base_y = ((i/2)*86)
      text_pos.push([pkmn.name,(base_x+320),(base_y+122-12),2,baseColor,shadowColor])
      if pkmn.male?
        text_pos.push([_INTL("♂"),(base_x+350),(base_y+70),false,Color.new(0,112,248),Color.new(120,184,232)])
      elsif pkmn.female?
        text_pos.push([_INTL("♀"),(base_x+350),(base_y+70),false,Color.new(232,32,16),Color.new(248,168,184)])
      end
    end
    pbDrawTextPositions(overlay,text_pos)
  end
  
  def pbPreviewTeam
    @enable_timer = true
    loop do
      Graphics.update
      Input.update
      self.update
      if Input.trigger?(Input::B) || @total_sec <= 0
        @enable_timer = false
        @sprites["timer"].text = _ISPRINTF("<ac>00:00 (pulsa X para salir ya)")
        break
      end
    end 
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class TeamPreviewScreen
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(left_trainer,left_party,right_trainer,right_party,timer)
    @scene.pbStartScene(left_trainer,left_party,right_trainer,right_party,timer)
    @scene.pbPreviewTeam
    @scene.pbEndScene
  end
end



def online_limpiar_reglas_previas
  $online_last_ruleset = {
    battle_type: nil,
    level_mode: 0,
    team_preview: nil,
    custom_level: nil,
    random_config: nil
  }
end


def online_reglas_previas?
  last = $online_last_ruleset
  last && last[:battle_type] && last[:level_mode]
end

