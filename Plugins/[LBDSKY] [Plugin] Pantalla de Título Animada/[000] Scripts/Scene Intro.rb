#===============================================================================
#  New animated and modular Title Screen for Pokemon Essentials
#    by Luka S.J.
#
#  ONLY FOR Essentials v19.x
# ----------------
#  Adds new visual styles to the Pokemon Essentials title screen, and animates
#  depending on the styles selected.
#
#  A lot of time and effort went into making this an extensive and comprehensive
#  resource. So please be kind enough to give credit when using it.
#===============================================================================
class Scene_Intro
  #-----------------------------------------------------------------------------
  # load the title screen
  #-----------------------------------------------------------------------------
  def main
    # Este transition SI hace falta, aunque en el arranque en frio no haga nada. Importa al
    # VOLVER al titulo desde la partida: la escena anterior deja un Graphics.freeze pendiente, y
    # sin descongelar aqui el ultimo fotograma del mapa se queda pegado en pantalla durante toda
    # la construccion del titulo. En el arranque en frio no hay freeze pendiente y es un no-op
    # inofensivo (mkxp-z/src/display/graphics.cpp: "if (!p->frozen) return;").
    Graphics.transition(10) rescue nil
    Input.update
    species = ModularTitle::SPECIES rescue :PIKACHU
    species = species.upcase.to_sym if species.is_a?(String)
    species = GameData::Species.get(species).id rescue :PIKACHU
    @cry = species.nil? ? nil : (GameData::Species.cry_filename(species, ModularTitle::SPECIES_FORM) rescue nil)
    @skip = false
    self.cyclePics
    # La pantalla de arranque de preload.rb sigue visible aqui, con su barra al 92%.
    #
    # Precision importante: ModularTitleScreen#initialize NO llama a Graphics.update en ningun
    # momento, asi que la barra NO avanza durante la construccion: se queda congelada al 92%
    # todo el tramo. Eso es lo que se puede conseguir sin reescribir ModularTitleScreen, y es
    # intencionado. Lo que cambia respecto a antes no es que la barra se mueva, es QUE HAY ALGO
    # en pantalla: el bloque Main destruia la overlay justo antes de entrar aqui, y estos
    # segundos se pagaban con el televisor en negro. Eso era la "segunda pantalla de carga".
    @screen = ModularTitleScreen.new
    update_boot_progress(100, "¡Listo!") if defined?(update_boot_progress)
    # Se retira en seco, sin fundido: @screen.intro arranca con su propio destello, asi que
    # fundir hacia un titulo ya terminado para que la intro lo borre acto seguido se ve como un
    # parpadeo. La propia intro hace de transicion.
    if defined?(pbDisposeBootOverlay)
      pbDisposeBootOverlay(0)
    end
    @screen.playBGM rescue nil
    @screen.intro rescue nil
    self.update
  ensure
    disposeTitle rescue nil
    Graphics.freeze rescue nil
  end

  #-----------------------------------------------------------------------------
  # main update loop
  #-----------------------------------------------------------------------------
  def update
    ret = 0
    Input.update
    loop do
      @screen.update if @screen
      Graphics.update
      Input.update
      if Input.press?(Input::DOWN) && Input.press?(Input::B) && Input.press?(Input::CTRL)
        ret = 1
        break
      end
      if Input.trigger?(Input::USE) || Input.trigger?(Input::C) || Input.trigger?(Input::ACTION) || Input.trigger?(Input::A) || Input.trigger?(Input::START) || (defined?($mouse) && $mouse.leftClick?)
        ret = 2
        break
      end
    end
    case ret
    when 1
      closeTitleDelete
    when 2
      closeTitle
    end
  end

  #-----------------------------------------------------------------------------
  # close title screen and dispose of elements
  #-----------------------------------------------------------------------------
  def closeTitle
    pbSEPlay(@cry, 100, 100) if @cry && (ModularTitle::MOSTRAR_GRITO rescue false) rescue nil
    disposeTitle
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
  end

  #-----------------------------------------------------------------------------
  # close title screen when save delete
  #-----------------------------------------------------------------------------
  def closeTitleDelete
    disposeTitle
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartDeleteScreen rescue sscreen.pbStartLoadScreen
  end

  #-----------------------------------------------------------------------------
  # cycle splash images
  #-----------------------------------------------------------------------------
  def cyclePics
    pics = (IntroEventScene::SPLASH_IMAGES rescue ["splash2"])
    return if !pics || pics.empty?
    frames = 10
    sprite = Sprite.new
    # Por encima de la pantalla de arranque de preload.rb, que ahora sigue viva durante esta
    # secuencia ($switch_boot_viewport.z == 999999). Con el 999999 de antes el empate de z
    # dejaba indefinido cual de los dos quedaba arriba.
    sprite.z = 1000500
    sprite.opacity = 0
    for i in 0...pics.length
      bitmap = (pbBitmap("Graphics/Titles/#{pics[i]}") rescue nil)
      next if !bitmap
      sprite.bitmap = bitmap
      frames.times do
        sprite.opacity += 255.0/frames
        Graphics.update
        Input.update
        break if Input.trigger?(Input::C) || Input.trigger?(Input::USE) || Input.trigger?(Input::A) || Input.trigger?(Input::ACTION)
      end
      15.times do
        Graphics.update
        Input.update
        break if Input.trigger?(Input::C) || Input.trigger?(Input::USE) || Input.trigger?(Input::A) || Input.trigger?(Input::ACTION)
      end
      frames.times do
        sprite.opacity -= 255.0/frames
        Graphics.update
        Input.update
        break if Input.trigger?(Input::C) || Input.trigger?(Input::USE) || Input.trigger?(Input::A) || Input.trigger?(Input::ACTION)
      end
    end
    sprite.dispose rescue nil
    10.times do
      Graphics.update
      Input.update
    end
  end

  #-----------------------------------------------------------------------------
  # dispose of title screen
  #-----------------------------------------------------------------------------
  def disposeTitle
    return if !@screen
    @screen.dispose rescue nil
    @screen = nil
  end

  #-----------------------------------------------------------------------------
  # wait command (skippable)
  #-----------------------------------------------------------------------------
  def wait(frames = 1, advance = true)
    return false if @skip
    frames.times do
      Graphics.update
      Input.update
      @skip = true if Input.trigger?(Input::C) || Input.trigger?(Input::USE) || Input.trigger?(Input::A)
    end
    return true
  end
end

#===============================================================================
#  sprite compatibility
#===============================================================================
class Sprite
  attr_accessor :id
  def id?(val = nil)
    return (@id == val) if @id
    return false
  end
end

#===============================================================================
#  title call override
#===============================================================================
def pbCallTitle
  return Scene_DebugIntro.new if $DEBUG && !Settings::SHOW_TITLE_SCREEN_ON_DEBUG
  return Scene_Intro.new
end
