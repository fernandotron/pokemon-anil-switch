#===============================================================================
#
#===============================================================================
class IntroEventScene < EventScene
  # Splash screen images that appear for a few seconds and then disappear.
  SPLASH_IMAGES         = ["splash2"]
  # The main title screen background image.
  TITLE_BG_IMAGE        = "title"
  TITLE_START_IMAGE     = "start"
  TITLE_START_IMAGE_X   = 0
  TITLE_START_IMAGE_Y   = 322 + 20
  SECONDS_PER_SPLASH    = 1
  TICKS_PER_ENTER_FLASH = 40   # 20 ticks per second
  FADE_TICKS            = 8    # 20 ticks per second

  def initialize(viewport = nil)
    super(viewport)
    @pic = addImage(0, 0, "")
    @pic.setVisible(0, true)
    @pic.setOpacity(0, 255)
    @pic2 = addImage(0, 0, "")
    @pic2.setVisible(0, true)
    @pic2.setOpacity(0, 255)
    @index = 0
    if SPLASH_IMAGES.empty?
      open_title_screen(self, nil)
    else
      open_splash(self, nil)
    end
  end

  def open_splash(_scene, *args)
    onCTrigger.clear
    log_compat("[IntroEventScene] Mostrando imagen splash #{@index + 1}/#{SPLASH_IMAGES.length}: #{SPLASH_IMAGES[@index]}") rescue nil
    @pic.name = "Graphics/Titles/" + SPLASH_IMAGES[@index]
    @pic.setVisible(0, true)
    @pic.setOpacity(0, 255)
    @pic.moveOpacity(0, FADE_TICKS, 255)
    pictureWait
    @timer = System.uptime                  # reset the timer
    onUpdate.set(method(:splash_update))    # called every frame
    onCTrigger.set(method(:close_splash))   # called when C key is pressed
  end

  def close_splash(scene, args)
    onUpdate.clear
    onCTrigger.clear
    @pic.moveOpacity(0, FADE_TICKS, 0)
    pictureWait
    @index += 1   # Move to the next picture
    if @index >= SPLASH_IMAGES.length
      open_title_screen(scene, args)
    else
      open_splash(scene, args)
    end
  end

  def splash_update(scene, args)
    if (System.uptime - @timer >= SECONDS_PER_SPLASH) ||
       Input.trigger?(Input::USE) || Input.trigger?(Input::C) || Input.trigger?(Input::ACTION)
      close_splash(scene, args)
    end
  end

  def open_title_screen(_scene, *args)
    onUpdate.clear
    onCTrigger.clear
    log_compat("[IntroEventScene] Abriendo pantalla de título: Graphics/Titles/#{TITLE_BG_IMAGE}") rescue nil
    @pic.name = "Graphics/Titles/" + TITLE_BG_IMAGE
    @pic.setVisible(0, true)
    @pic.setOpacity(0, 255)
    @pic2.name = "Graphics/Titles/" + TITLE_START_IMAGE
    @pic2.setXY(0, TITLE_START_IMAGE_X, TITLE_START_IMAGE_Y)
    @pic2.setVisible(0, true)
    @pic2.setOpacity(0, 255)
    pictureWait
    begin
      $data_system ||= load_data("Data/System.rxdata") rescue nil
      if $data_system && $data_system.respond_to?(:title_bgm) && $data_system.title_bgm
        log_compat("[IntroEventScene] Reproduciendo música de título: #{$data_system.title_bgm.name}") rescue nil
        pbBGMPlay($data_system.title_bgm)
      end
    rescue Exception => e_bgm
      log_compat("[Title BGM Warning] #{e_bgm.message}") rescue nil
    end
    log_compat("[IntroEventScene] ¡Pantalla de título lista! Esperando botón A / USE / ENTER...") rescue nil
    onUpdate.set(method(:title_screen_update))    # called every frame
    onCTrigger.set(method(:close_title_screen))   # called when C key is pressed
  end

  def fade_out_title_screen(scene)
    onUpdate.clear
    onCTrigger.clear
    scene.dispose rescue nil
  end

  def close_title_screen(scene, *args)
    log_compat("[IntroEventScene] Botón presionado, abriendo menú de partida...") rescue nil
    fade_out_title_screen(scene)
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
  end

  def close_title_screen_delete(scene, *args)
    fade_out_title_screen(scene)
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartDeleteScreen
  end

  def title_screen_update(scene, args)
    # Flashing of "Press Enter" picture
    if !@pic2.running?
      @pic2.moveOpacity(TICKS_PER_ENTER_FLASH * 2 / 10, TICKS_PER_ENTER_FLASH * 4 / 10, 0)
      @pic2.moveOpacity(TICKS_PER_ENTER_FLASH * 6 / 10, TICKS_PER_ENTER_FLASH * 4 / 10, 255)
    end
    if Input.press?(Input::DOWN) &&
       Input.press?(Input::BACK) &&
       Input.press?(Input::CTRL)
      close_title_screen_delete(scene, args)
    elsif Input.trigger?(Input::USE) || Input.trigger?(Input::C) || Input.trigger?(Input::ACTION) || Input.trigger?(Input::A) || Input.trigger?(Input::B) || Input.trigger?(Input::X) || Input.trigger?(Input::Y)
      close_title_screen(scene, args)
    end
  end
end

#===============================================================================
#
#===============================================================================
class Scene_Intro
  def main
    log_compat("[Scene_Intro] Iniciando IntroEventScene (Pantalla de Título)...") rescue nil
    Graphics.transition(10) rescue nil
    begin
      @scene = IntroEventScene.new
      @scene.main
    rescue Exception => e
      log_compat("[Scene_Intro Error] #{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}") rescue nil
      sscene = PokemonLoad_Scene.new
      sscreen = PokemonLoadScreen.new(sscene)
      sscreen.pbStartLoadScreen
    end
    Graphics.freeze
  end
end

