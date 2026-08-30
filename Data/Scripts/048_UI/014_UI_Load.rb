#===============================================================================
#
#===============================================================================
class PokemonLoadPanel < Sprite
  attr_reader :selected

  TEXT_COLOR               = Color.new(232, 232, 232)
  TEXT_SHADOW_COLOR        = Color.new(136, 136, 136)
  MALE_TEXT_COLOR          = Color.new(56, 160, 248)
  MALE_TEXT_SHADOW_COLOR   = Color.new(56, 104, 168)
  FEMALE_TEXT_COLOR        = Color.new(240, 72, 88)
  FEMALE_TEXT_SHADOW_COLOR = Color.new(160, 64, 64)

  @@shared_bgbitmap = nil
  def self.shared_bgbitmap
    if !@@shared_bgbitmap || @@shared_bgbitmap.disposed?
      @@shared_bgbitmap = AnimatedBitmap.new("Graphics/UI/Load/panels")
    end
    @@shared_bgbitmap
  end

  def initialize(index, title, isContinue, trainer, stats, mapid, viewport = nil)
    super(viewport)
    self.z = 200
    @index = index
    @title = title
    @isContinue = isContinue
    @trainer = trainer
    @totalsec = stats&.play_time.to_i || 0
    @mapid = mapid
    @selected = (index == 0)
    @bgbitmap = self.class.shared_bgbitmap
    build_bitmaps
    update_display_bitmap
  end

  def dispose
    @bmp_sel&.dispose
    @bmp_unsel&.dispose
    super
  end

  def build_bitmaps
    h = @isContinue ? 222 : 46
    w = @bgbitmap.width
    @bmp_unsel = Bitmap.new(w, h)
    @bmp_sel   = Bitmap.new(w, h)
    pbSetSystemFont(@bmp_unsel) rescue nil
    pbSetSystemFont(@bmp_sel) rescue nil

    if @isContinue
      @bmp_unsel.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, 0, w, 222)) rescue nil
      @bmp_sel.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, 222, w, 222)) rescue nil
    else
      @bmp_unsel.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, 444, w, 46)) rescue nil
      @bmp_sel.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, 490, w, 46)) rescue nil
    end

    textpos = []
    if @isContinue
      textpos.push([@title, 32, 16, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
      textpos.push([_INTL("Medallas:"), 32, 118, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
      textpos.push([@trainer ? @trainer.badge_count.to_s : "0", 206, 118, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
      textpos.push([_INTL("Pokédex:"), 32, 150, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
      textpos.push([@trainer ? @trainer.pokedex.seen_count.to_s : "0", 206, 150, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
      textpos.push([_INTL("Tiempo:"), 32, 182, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
      hour = @totalsec / 60 / 60
      min  = @totalsec / 60 % 60
      if hour > 0
        textpos.push([_INTL("{1}h {2}m", hour, min), 206, 182, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
      else
        textpos.push([_INTL("{1}m", min), 206, 182, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
      end
      if @trainer&.male?
        textpos.push([@trainer.name, 112, 70, :left, MALE_TEXT_COLOR, MALE_TEXT_SHADOW_COLOR])
      elsif @trainer&.female?
        textpos.push([@trainer.name, 112, 70, :left, FEMALE_TEXT_COLOR, FEMALE_TEXT_SHADOW_COLOR])
      elsif @trainer
        textpos.push([@trainer.name, 112, 70, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
      end
      mapname = pbGetMapNameFromId(@mapid) rescue ""
      mapname = mapname.gsub(/\\PN/, @trainer.name) rescue mapname if @trainer
      textpos.push([mapname, 386, 16, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
    else
      textpos.push([@title, 32, 14, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
    end
    pbDrawTextPositions(@bmp_unsel, textpos) rescue nil
    pbDrawTextPositions(@bmp_sel, textpos) rescue nil
  end

  def update_display_bitmap
    self.bitmap = @selected ? @bmp_sel : @bmp_unsel
    if self.bitmap
      self.src_rect.set(0, 0, self.bitmap.width, self.bitmap.height)
    end
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    update_display_bitmap
  end

  def pbRefresh
    update_display_bitmap
  end

  def refresh
    update_display_bitmap
  end
end

#===============================================================================
#
#===============================================================================
class PokemonLoad_Scene
  def pbStartScene(commands, show_continue, trainer, stats, map_id)
    @commands = commands
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    bg_file = pbResolveBitmap("Graphics/UI/Load/bg")
    if bg_file
      @sprites["background"] = Sprite.new(@viewport)
      @sprites["background"].bitmap = Bitmap.new(bg_file) rescue nil
      @sprites["background"].z = 0
    else
      addBackgroundOrColoredPlane(@sprites, "background", "Load/bg", Color.new(248, 248, 248), @viewport)
      @sprites["background"].z = 0 if @sprites["background"]
    end
    y = 32
    commands.length.times do |i|
      @sprites["panel#{i}"] = PokemonLoadPanel.new(
        i, commands[i], (show_continue) ? (i == 0) : false, trainer, stats, map_id, @viewport
      )
      @sprites["panel#{i}"].x = 48
      @sprites["panel#{i}"].y = y
      @sprites["panel#{i}"].z = 200
      @sprites["panel#{i}"].visible = true
      @sprites["panel#{i}"].pbRefresh
      y += (show_continue && i == 0) ? 224 : 48
    end
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["cmdwindow"].visible  = false
    Graphics.update rescue nil
  end

  def pbStartScene2
    @sprites.each_value { |s| s.visible = true if s && !s.disposed? }
    pbUpdate
    Graphics.update rescue nil
  end

  def pbStartDeleteScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    addBackgroundOrColoredPlane(@sprites, "background", "Load/bg", Color.new(248, 248, 248), @viewport)
    @sprites["background"].z = 0 if @sprites["background"]
  end

  def pbUpdate
    oldi = @sprites["cmdwindow"].index rescue 0
    pbUpdateSpriteHash(@sprites)
    newi = @sprites["cmdwindow"].index rescue 0
    if oldi != newi
      @sprites["panel#{oldi}"].selected = false if @sprites["panel#{oldi}"]
      @sprites["panel#{oldi}"].pbRefresh if @sprites["panel#{oldi}"]
      @sprites["panel#{newi}"].selected = true if @sprites["panel#{newi}"]
      @sprites["panel#{newi}"].pbRefresh if @sprites["panel#{newi}"]
      while @sprites["panel#{newi}"] && @sprites["panel#{newi}"].y > Graphics.height - 80
        @commands.length.times do |i|
          @sprites["panel#{i}"].y -= 48 if @sprites["panel#{i}"]
        end
        6.times do |i|
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y -= 48
        end
        @sprites["leftarrow"].y -= 48 if @sprites["leftarrow"]
        @sprites["rightarrow"].y -= 48 if @sprites["rightarrow"]
        @sprites["player"].y -= 48 if @sprites["player"]
      end
      while @sprites["panel#{newi}"] && @sprites["panel#{newi}"].y < 32
        @commands.length.times do |i|
          @sprites["panel#{i}"].y += 48 if @sprites["panel#{i}"]
        end
        6.times do |i|
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y += 48
        end
        @sprites["leftarrow"].y += 48 if @sprites["leftarrow"]
        @sprites["rightarrow"].y += 48 if @sprites["rightarrow"]
        @sprites["player"].y += 48 if @sprites["player"]
      end
    end
  end

  def pbSetParty(trainer)
    return if !trainer || !trainer.party
    meta = GameData::PlayerMetadata.get(trainer.character_ID)
    if meta
      filename = pbGetPlayerCharset(meta.walk_charset, trainer, true)
      @sprites["player"] = TrainerWalkingCharSprite.new(filename, @viewport)
      if !@sprites["player"].bitmap
        raise _INTL("No se ha encontrado el charset del jugador {1} andando (archivo: \"{2}\").", trainer.character_ID, filename)
      end
      charwidth  = @sprites["player"].bitmap.width
      charheight = @sprites["player"].bitmap.height
      @sprites["player"].x = 112 - (charwidth / 8)
      @sprites["player"].y = 112 - (charheight / 8)
      @sprites["player"].z = 99999
    end
    trainer.party.each_with_index do |pkmn, i|
      @sprites["party#{i}"] = PokemonIconSprite.new(pkmn, @viewport)
      @sprites["party#{i}"].setOffset(PictureOrigin::CENTER)
      @sprites["party#{i}"].x = 334 + (66 * (i % 2))
      @sprites["party#{i}"].y = 112 + (50 * (i / 2))
      @sprites["party#{i}"].z = 99999
    end

    # Añadimos flechas laterales a los lados del panel.
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport)
    @sprites["leftarrow"].x = 10
    @sprites["leftarrow"].y = 130
    @sprites["leftarrow"].visible = SaveData.get_save_count > 1 #true
    @sprites["leftarrow"].play
    @sprites["rightarrow"] =  AnimatedSprite.new("Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport)
    @sprites["rightarrow"].x = 454
    @sprites["rightarrow"].y = 130
    @sprites["rightarrow"].visible = SaveData.get_save_count > 1 #true
    @sprites["rightarrow"].play
  end

  def pbChoose(commands)
    @sprites["cmdwindow"].commands = commands
    while Input.press?(Input::USE) || Input.press?(Input::C) || Input.press?(Input::ACTION) || Input.press?(Input::A) || Input.press?(Input::B) || Input.press?(Input::BACK)
      Graphics.update
      Input.update
      pbUpdate
    end
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::USE) || Input.trigger?(Input::C) || Input.trigger?(Input::ACTION) || Input.trigger?(Input::A)
        idx = @sprites["cmdwindow"].index
        log_compat("[PokemonLoad_Scene] Opción seleccionada: #{idx} (#{commands[idx]})") rescue nil
        return idx
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbCloseScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    if SaveData.exists?
      @save_data = load_save_file(SaveData::FILE_PATH)
    else
      @save_data = {}
    end
  end

  # @param file_path [String] file to load save data from
  # @return [Hash] save data
  def load_save_file(file_path)
    save_data = (SaveData.read_from_file(file_path) rescue {})
    unless SaveData.valid?(save_data)
      if File.file?(file_path + ".bak")
        save_data = (load_save_file(file_path + ".bak") rescue {})
      else
        return {}
      end
    end
    return save_data || {}
  end

  # Called if all save data is invalid.
  # Prompts the player to delete the save files.
  def prompt_save_deletion
    pbMessage(_INTL("La partida guardada está corrupta, o es incompatible con este juego.") + "\1")
    exit unless pbConfirmMessageSerious(
      _INTL("¿Quieres borrar la partida y empezar una nueva?")
    )
    self.delete_save_data
    $game_system   = Game_System.new
    $PokemonSystem = PokemonSystem.new
  end

  def pbStartDeleteScreen
    @scene.pbStartDeleteScene
    @scene.pbStartScene2
    if SaveData.exists?
      if pbConfirmMessageSerious(_INTL("¿Borrar todos los datos guardados?"))
        pbMessage(_INTL("Una vez que los datos se borren no habrá forma de recuperarlos.") + "\1")
        if pbConfirmMessageSerious(_INTL("¿Borrar los datos guardados de todos modos?"))
          pbMessage(_INTL("Borrando todos los datos. No cierres el juego.") + "\\wtnp[0]")
          self.delete_save_data
        end
      end
    else
      pbMessage(_INTL("No se han encontrado datos de guardado."))
    end
    @scene.pbEndScene
    $scene = pbCallTitle
  end

  def delete_save_data
    begin
      SaveData.delete_file
      pbMessage(_INTL("Los datos guardados se han borrado."))
    rescue SystemCallError
      pbMessage(_INTL("No se han podido borrar todos los datos guardados."))
    end
  end

  def pbStartLoadScreen
    PokeUpdater.check_for_updates() if defined?(PokeUpdater) && defined?(PokeUpdater.check_for_updates) # Required for PokéUpdater to check for gameupdates.
    commands = []
    cmd_continue     = -1
    cmd_new_game     = -1
    cmd_options      = -1
    cmd_language     = -1
    cmd_mystery_gift = -1
    cmd_update     = -1
    cmd_debug        = -1
    cmd_quit         = -1
    show_continue = !@save_data.empty?
    if show_continue
      commands[cmd_continue = commands.length] = _INTL("Continuar")
      if @save_data[:player].mystery_gift_unlocked
        commands[cmd_mystery_gift = commands.length] = _INTL("Regalo Misterioso")
      end
    end
    commands[cmd_new_game = commands.length]  = _INTL("Partida Nueva")
    commands[cmd_options = commands.length]   = _INTL("Opciones")
    commands[cmd_language = commands.length]  = _INTL("Idioma") if Settings::LANGUAGES.length >= 2
    commands[cmd_update=commands.length]      = _INTL("Buscar actualizaciones") if defined?(PokeUpdater) && defined?(PokeUpdater.validate_game_version_and_update)
    commands[cmd_debug = commands.length]     = _INTL("Debug") if $DEBUG
    commands[cmd_quit = commands.length]      = _INTL("Cerrar Juego")
    log_compat("[PokemonLoadScreen] Iniciando pbStartScene con #{commands.length} opciones: #{commands.join(', ')}...") rescue nil
    map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
    @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
    @scene.pbSetParty(@save_data[:player]) if show_continue
    log_compat("[PokemonLoadScreen] pbStartScene2...") rescue nil
    @scene.pbStartScene2
    log_compat("[PokemonLoadScreen] Entrando en loop de pbChoose...") rescue nil
    loop do
      command = @scene.pbChoose(commands)
      log_compat("[PokemonLoadScreen] Comando elegido: #{command} (#{commands[command]})") rescue nil
      pbPlayDecisionSE if command != cmd_quit
      case command
      when cmd_continue
        @scene.pbEndScene
        Game.load(@save_data)
        return
      when cmd_new_game
        log_compat("[PokemonLoadScreen] Iniciando Partida Nueva (Game.start_new)...") rescue nil
        @scene.pbEndScene
        Game.start_new
        return
      when cmd_mystery_gift
        pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
      when cmd_options
        pbFadeOutIn do
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
          @scene.pbUpdate rescue nil
          Graphics.frame_reset rescue nil
        end
      when cmd_language
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
        if show_continue
          @save_data[:pokemon_system] = $PokemonSystem
          File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
        end
        $scene = pbCallTitle
        return
      when cmd_debug
        pbFadeOutIn { pbDebugMenu(false) }
      when cmd_update
        PokeUpdater.validate_game_version_and_update(true) if defined?(PokeUpdater) && defined?(PokeUpdater.validate_game_version_and_update)
      when cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      else
        pbPlayBuzzerSE
      end
    end
  end
end

