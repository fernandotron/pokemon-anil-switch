module ChallengeModes
  module_function

  # Erzwungene Regeln für den Nuzlocke-Modus
  FORCED_RULES = [:PERMAFAINT, :FIRST_CAPTURE, :SHINY_CLAUSE, :DUPS_CLAUSE, :FORCE_NICKNAME, :FORCE_SET_BATTLES, :NO_TRAINER_BATTLE_ITEMS]

  # Flag für erzwungene Regeln
  @@use_forced_rules = false

  #-----------------------------------------------------------------------------
  # Methode zur Aktivierung der erzwungenen Regeln
  #-----------------------------------------------------------------------------
  def use_forced_rules(flag)
    @@use_forced_rules = flag
  end

  #-----------------------------------------------------------------------------
  # Methode zur Festlegung der erzwungenen Regeln
  #-----------------------------------------------------------------------------
  def set_forced_rules(rules)
    FORCED_RULES.replace(rules)
  end

  #-----------------------------------------------------------------------------
  # Startet den Challenge-Modus mit den entsprechenden Regeln
  #-----------------------------------------------------------------------------
  def start
    if @@use_forced_rules
      $PokemonGlobal.challenge_rules = FORCED_RULES
    else
      $PokemonGlobal.challenge_rules = select_mode
    end
    return if $PokemonGlobal.challenge_rules.empty?
    $PokemonGlobal.challenge_qued  = true
    $PokemonGlobal.challenge_encs  = {}
    return if !$bag
    GameData::Item.each do |item|
      next if !item.is_poke_ball? || !$bag.has?(item)
      begin_challenge
      pbMessage(_INTL("¡Tu desafío ha comenzado! ¡Buena suerte!"))
      return
    end
  end

  def open_rules_menu
    $PokemonGlobal.challenge_rules = select_mode($PokemonGlobal.challenge_rules)
  end

  #-----------------------------------------------------------------------------
  # Select rules for challenge mode
  #-----------------------------------------------------------------------------
  def select_mode(preselected_rules = [])
    selected_rules = preselected_rules
    loop do
      selected_rules = select_custom_rules(preselected_rules)
      if selected_rules.empty?
        next if pbMessage(_INTL("¿Te gustaría jugar al juego sin ningún modificador de desafío?"), [_INTL("Sí"), _INTL("No")]) != 0
      else
        display_rules(selected_rules)
        next if pbMessage(_INTL("¿Te gustaría jugar al juego con los modificadores seleccionados?"), [_INTL("Sí"), _INTL("No")]) != 0
      end
      break
    end
    return selected_rules
  end

  #-----------------------------------------------------------------------------
  # Select custom ruleset for challenge
  #-----------------------------------------------------------------------------
  def select_custom_rules(preselected_rules = [])
    selected_rules = preselected_rules
    # catch_clauses  = [:SHINY_CLAUSE, :DUPS_CLAUSE, :GIFT_CLAUSE]
    vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
    infowindow = Window_AdvancedTextPokemon.newWithSize("", 0, Graphics.height - 96, Graphics.width, 96, vp)
    infowindow.setSkin(MessageConfig.pbGetSystemFrame)
    cmdwindow = Window_CommandPokemon_Challenge.new([])
    cmdwindow.viewport = vp
    cmdwindow.y = 64
    text = _INTL("Opciones de Desafío")
    titlewindow = Window_UnformattedTextPokemon.newWithSize(
      text, 0, 0, Graphics.width, 64, vp)
    need_refresh = true
    rules = RULES.keys.clone
    rules.sort! { |a, b| RULES[a][:order] <=> RULES[b][:order] }
    pbSetNarrowFont(infowindow.contents)
    infowindow.text = _INTL(RULES[rules.first][:desc])
    defaultskin = MessageConfig.pbGetSystemFrame.gsub("Graphics/Windowskins/", "")
    loop do
      if need_refresh
        commands = []
        rules.each do |rule|
          toggle = selected_rules.include?(rule) ? 1 : 0
          commands.push([RULES[rule][:name], toggle])
        end
        commands.push(_INTL("Confirmar"))
        cmdwindow.commands = commands
        cmdwindow.width = Graphics.width
        cmdwindow.height = Graphics.height - 160
        need_refresh = false
      end
      Graphics.update
      Input.update
      old_index = cmdwindow.index
      cmdwindow.update
      infowindow.update
      pbUpdateSceneMap
      if old_index != cmdwindow.index
        text = ""
        if cmdwindow.index == cmdwindow.commands.length - 1
          text = _INTL("Confirma la siguiente selección de modificadores.") 
        else
          text = RULES[rules[cmdwindow.index]][:desc]
        end
        infowindow.text = _INTL(text) 
        old_index = cmdwindow.index
      end
      if Input.trigger?(Input::BACK)
        infowindow.visible = false
        break if selected_rules.empty?
        selected_rules.clear if pbConfirmMessage(_INTL("\\w[{1}]¿Borrar la selección actual de modificadores?", defaultskin))
        infowindow.visible = true
        need_refresh = true
      elsif Input.trigger?(Input::USE)
        command = cmdwindow.index
        break if command == ChallengeModes::RULES.values.length
        rule = rules[command]
        updated = false
        # if rule == :PERMALOCKE && !selected_rules.include?(:PERMALOCKE)
        #   msgwindow = Window_AdvancedTextPokemon.new("Elige cuantas vidas puedes perder antes de empezar a perder slots del equipo")
        #   params = ChooseNumberParams.new
        #   params.setMaxDigits(2)
        #   params.setDefaultValue(permalocke_max_shields)
        #   params.setCancelValue(-1)
        #   quantity = pbChooseNumber(msgwindow, params)
        #   permalocke_set_shields(quantity) if quantity >= 0
        #   pbDisposeMessageWindow(msgwindow)
        if rule == :MODOVIDAS && !selected_rules.include?(:MODOVIDAS)
          # if pbConfirmMessage(_INTL("¿Te gustaría jugar con vidas? Estás vidas también aplicarán al modo Permalocke."))
            msgwindow = Window_AdvancedTextPokemon.new("Elige con cuántas vidas quieres jugar (entre 1 y 100 como máximo).")
            params = ChooseNumberParams.new
            params.setMaxDigits(3)
            params.setDefaultValue(10)
            params.setRange(1, 100)
            params.setCancelValue(-1)
            quantity = pbChooseNumber(msgwindow, params)
            msgwindow.dispose
            next if quantity <= 0
            $PokemonGlobal.challenge_lives = quantity
            permalocke_set_shields(quantity)
            pbDisposeMessageWindow(msgwindow)
          # end
        end
        if rule == :MODOASISTIDO && !selected_rules.include?(:MODOASISTIDO)
          # if pbConfirmMessage(_INTL("¿Quieres recibir resurrecciones luego de vencer a líderes de gimnasio?"))
            cmd = pbMessage(_INTL("¿Cuántas resurrecciones quieres?"), [_INTL("1"), _INTL("3"), _INTL("Cancelar")], -1)
            if cmd == 0
              $PokemonGlobal.sacred_ash_count = 1
            elsif cmd == 1
              $PokemonGlobal.sacred_ash_count = 3
            elsif cmd == -1 || cmd == 2
              next
            end
          # end
        end
        if selected_rules.include?(rule)
          selected_rules.delete(rule)
          if rule == :MODOVIDAS
            $PokemonGlobal.challenge_lives = -1
            permalocke_set_shields($PokemonGlobal.challenge_lives)
          elsif rule == :MODOASISTIDO
            $PokemonGlobal.sacred_ash_count = 0
          end
          if rule == :PERMALOCKE && selected_rules.include?(:PERMALOCKE_RESTORES)
            selected_rules.delete(:PERMALOCKE_RESTORES)
          end
          if rule == :PERMAFAINT
            selected_rules.delete_if { |k, _| RULES[k][:parent] == :PERMAFAINT }
          end
          # catch_clauses.each { |r| selected_rules.delete(r) } if rule == :FIRST_CAPTURE
          # selected_rules.push(:GAME_OVER_WHITEOUT) if (!selected_rules.include?(:PERMAFAINT) && !selected_rules.include?(:GAME_OVER_WHITEOUT)) 
          selected_rules.delete(:GAME_OVER_WHITEOUT) if selected_rules.first == :GAME_OVER_WHITEOUT && selected_rules.length == 1
          selected_rules.push(:PERMAFAINT) if !selected_rules.include?(:PERMAFAINT) && ChallengeModes::RULES[rule][:parent] == :PERMAFAINT
          updated = true
        else
        # elsif rule == :GAME_OVER_WHITEOUT#(selected_rules.include?(:FIRST_CAPTURE) && catch_clauses.include?(rule)) || 
              # (selected_rules.include?(:PERMAFAINT) && rule == :GAME_OVER_WHITEOUT) ||
          selected_rules.push(rule)
          selected_rules.push(:PERMAFAINT) if !selected_rules.include?(:PERMAFAINT) && rule == :GAME_OVER_WHITEOUT
          updated = true
        end
        if rule != :PERMAFAINT && !selected_rules.include?(:PERMAFAINT) && ChallengeModes::RULES[rule][:parent] == :PERMAFAINT
          selected_rules.push(:PERMAFAINT)
          updated = true
        end
        if rule != :ONE_CAPTURE && !selected_rules.include?(:ONE_CAPTURE) && ChallengeModes::RULES[rule][:parent] == :ONE_CAPTURE
          selected_rules.push(:ONE_CAPTURE)
          updated = true
        end
        if rule != :PERMALOCKE && !selected_rules.include?(:PERMALOCKE) && ChallengeModes::RULES[rule][:parent] == :PERMALOCKE
          selected_rules.push(:PERMALOCKE)
          updated = true
        end
        if !updated
          pbPlayBuzzerSE
        else
          pbPlayCursorSE
          selected_rules.sort! { |a, b| RULES[a][:order] <=> RULES[b][:order] }
          need_refresh = true
        end
      end
    end
    cmdwindow.dispose
    infowindow.dispose
    titlewindow.dispose
    vp.dispose
    return selected_rules
  end

  def display_rules(rules = $PokemonGlobal.challenge_rules)
    return if rules.empty?
    vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
    vp.z = 999999
    infowindow = Window_AdvancedTextPokemon.newWithSize("", 0, 0, Graphics.width, Graphics.height, vp)
    infowindow.setSkin(MessageConfig.pbGetSystemFrame)
    infowindow.letterbyletter = true
    infowindow.lineHeight = 28
    infowindow.z = 999999
    rule_text  = ""
    rules.each_with_index do |rule, i| 
      next if rule == :GAME_OVER_WHITEOUT
      rule_text += "- " + _INTL(ChallengeModes::RULES[rule][:desc]) if (rule != :MODOVIDAS || (rule != :MODOASISTIDO && $PokemonGlobal.sacred_ash_count > 0))
      if rule == :MODOVIDAS && $PokemonGlobal.challenge_lives >= 0
        vidas_plural = $PokemonGlobal.challenge_lives == 1 ? "vida" : "vidas"
        rule_text += "\n- " + "Tendrás #{$PokemonGlobal.challenge_lives} " + vidas_plural + ", si las pierdes perderás el desafío."
      # elsif rule == :PERMALOCKE && $PokemonGlobal.challenge_lives > 0
      #   rule_text += "\nTendrás #{permalocke_shields} escudos, una vez pierdas estos escudos, por cada muerte perderás un slot del equipo, si pierdes todos los slots del equipo perderás el desafío."
      end
      if rule == :MODOASISTIDO && $PokemonGlobal.sacred_ash_count > 0
        num_resu = $PokemonGlobal.sacred_ash_count == 1 ? "resurrección" : "resurrecciones"
        rule_text += "\n- " + "Recibirás #{$PokemonGlobal.sacred_ash_count} " + num_resu + " al vencer a un Líder de Gimnasio."
      end
      rule_text += "\n" if i != rules.length - (rules.include?(:GAME_OVER_WHITEOUT) ? 2 : 1)
    end
    pbSetSmallFont(infowindow.contents)
    infowindow.text = rule_text
    infowindow.resizeHeightToFit(rule_text)
    infowindow.height = Graphics.height if infowindow.height > Graphics.height
    infowindow.y = (Graphics.height - infowindow.height) / 2
    infowindow.z = 999999
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      infowindow.update
      pbUpdateSceneMap
      if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        if infowindow.busy?
          pbPlayDecisionSE if infowindow.pausing?
          infowindow.resume
        else
          break
        end
      end
    end
    rule_text  = ""
    if rules.include?(:GAME_OVER_WHITEOUT) #|| !rules.include?(:PERMAFAINT)
      rule_text += "- " + _INTL(ChallengeModes::RULES[:GAME_OVER_WHITEOUT][:desc])
    elsif rules.include?(:PERMAFAINT) 
      rule_text += "- " + _INTL("Si todos los Pokémon de tu equipo se debilitan en la batalla, podrás continuar el desafío con los Pokémon no debilitados de tu PC.")
      rule_text += "\n- " + _INTL("Si todos los Pokémon de tu equipo y de tu PC se debilitan, perderás el desafío.")
    end
    rule_text += "\n" if !rule_text.empty?
    rule_text += "- " + _INTL("El desafío comienza después de que hayas obtenido tu primera Poké Ball.")
    pbSetSmallFont(infowindow.contents)
    infowindow.text = rule_text
    infowindow.resizeHeightToFit(rule_text)
    infowindow.height = Graphics.height if infowindow.height > Graphics.height
    infowindow.y = (Graphics.height - infowindow.height) / 2
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      infowindow.update
      pbUpdateSceneMap
      if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        if infowindow.busy?
          pbPlayDecisionSE if infowindow.pausing?
          infowindow.resume
        else
          break
        end
      end
    end
    infowindow.dispose
    vp.dispose
  end
end

class Window_CommandPokemon_Challenge < Window_CommandPokemon
  def initialize(commands, width = nil)
    @text_key = []
    commands.each_with_index do |command, i|
      next if !command.is_a?(Array)
      commands[i]  = command[0]
      @text_key[i] = command[1]
    end
    super(commands, width)
  end

  def drawItem(index, count, rect)
    pbSetSystemFont(self.contents)
    rect = drawCursor(index, rect)
    base   = self.baseColor
    shadow = self.shadowColor
    x_pos = rect.x 
    y_pos = rect.y 
    pbDrawShadowText(self.contents, x_pos + 4, y_pos + (self.contents.text_offset_y || 0), 
      rect.width, rect.height, @commands[index], base, shadow)
    return if !@text_key[index]
    text = _INTL("DESACTIVADO")
    shadow   = Color.new(232, 32, 16)
    base = Color.new(248, 168, 184)
    if @text_key[index] == 1
      text = _INTL("ACTIVADO")
      shadow   = Color.new(0, 112, 248)
      base = Color.new(120, 184, 232)
    end
    text = "[#{text}]"
    option_width = rect.width / 2
    x_pos += rect.width - option_width
    pbSetSystemFont(self.contents)
    pbDrawShadowText(self.contents, x_pos, rect.y + (self.contents.text_offset_y || 0),
      option_width, rect.height, text, base, shadow, 1)
  end

  def commands=(commands)
    @text_key = []
    commands.each_with_index do |command, i|
      next if !command.is_a?(Array)
      commands[i]  = command[0]
      @text_key[i] = command[1]
    end
    @commands = commands
  end
end