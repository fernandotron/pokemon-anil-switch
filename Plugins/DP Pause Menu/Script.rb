#==============================================================================#
#                         Diamond/Pearl Pause Menu                             #
#                                  by Marin                                    #
#==============================================================================#
#                                Instructions                                  #
#                                                                              #
#  To call the Pause menu individually (not by pressing B), use `pbPauseMenu`  #
#                                                                              #
# To make/add your own options, find `@options = []`. Underneath, all options  #
#        are initialized and added. They follow a very simple format:          #
#           [displayname, unselected, selected, code, (condition)]             #
# `displayname` : This is what's actually displayed on screen.                 #
# `unselected` : This is the icon that will be displayed when the option is    #
#                NOT selected. For it to be gender dependent, make it an array #
# `selected` : This is the icon that will be displayed when the option IS      #
#              selected. For it to be gender dependent, make it an array.      #
# `code` : This is what's executed when you click the button.                  #
# `condition` : If you only want the option to be visible at certain times,    #
#               this is where you can add a condition (e.g. $player.pokedex). #
#==============================================================================#
#                    Please give credit when using this.                       #
#==============================================================================#

# Calls the Pause menu
def pbPauseMenu
  DP_PauseMenu.precache_assets rescue nil
  DP_PauseMenu.new
end

# This overwrites the old pause menu. Take/comment out these 10 lines to keep
# the old Pause menu.
class Scene_Map
  def call_menu
    $game_temp.menu_calling = false
    $game_temp.in_menu = true
    $game_player.straighten
    $game_map.update
    pbPauseMenu # Calls the DP Pause Menu
    $game_temp.in_menu = false
  end
end

# Variables used to store last selected index.
class PokemonGlobalMetadata
  attr_accessor :last_menu_index
end

class DP_PauseMenu
  # Color base del texto mostrado
  BaseColor = Color.new(250, 250, 250)
  # Color de sombra del texto mostrado
  ShadowColor = Color.new(75,75,75)

  def self.precache_assets
    return if @assets_precached
    @assets_precached = true
    if defined?(RPG::Cache)
      ["bgTop", "bgMid", "bgBtm", "bgTop_short", "bgMid_short", "bgBtm_short", "selector", 
       "pokedexA", "pokedexB", "pokemonA", "pokemonB", "bagA", "bagBm", "bagBf", 
       "PlayercardA", "PlayercardB", "saveA", "saveBm", "saveBf", "optionsA", "optionsB", 
       "exitA", "exitB", "fly", "pokevial", "vial", "vial_empty", "radar", "repel",
       "repel_off", "night", "day", "sun", "moon", "icon_own"].each do |f|
        begin
          bm = RPG::Cache.load_bitmap("Graphics/Pictures/DP Pause Menu/", f)
          bm.never_dispose = true if bm.respond_to?(:never_dispose=)
        rescue
        end
      end
    end
  end
  
  def initialize
    @options = []
    # BOTÓN DE POKÉDEX
    @options << ["Pokédex", "pokedexA", "pokedexB", proc {
      if Settings::USE_CURRENT_REGION_DEX
        pbFadeOutIn do
          scene = PokemonPokedex_Scene.new
          screen = PokemonPokedexScreen.new(scene)
          screen.pbStartScreen
        end
      elsif $player.pokedex.accessible_dexes.length == 1
        $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[0]
        pbFadeOutIn do
          scene = PokemonPokedex_Scene.new
          screen = PokemonPokedexScreen.new(scene)
          screen.pbStartScreen
        end
      else
        pbFadeOutIn do
          scene = PokemonPokedexMenu_Scene.new
          screen = PokemonPokedexMenuScreen.new(scene)
          screen.pbStartScreen
        end
      end 
    }] if $player.has_pokedex
    # BOTÓN DE EQUIPO
    @options << ["Pokémon", "pokemonA", "pokemonB", proc {
      hiddenmove = nil
      pbFadeOutIn(99999) do
        sscene = PokemonParty_Scene.new
        sscreen = PokemonPartyScreen.new(sscene, $player.party)
        hiddenmove = sscreen.pbPokemonScreen
        if hiddenmove
          @sprites.visible = false
          @done = true
        end
      end
      if hiddenmove
        $game_temp.in_menu = false
        pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
      end
      }] if $player.party.size > 0
    # BOTÓN DE MOCHILA
    @options << ["Bolsa", "bagA", ["bagBm", "bagBf"], proc {
      item = nil
      pbFadeOutIn(99999) do
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        item = screen.pbStartScreen
      end
      next false if !item
      @sprites.visible = false
      @done = true
      $game_temp.in_menu = false
      pbUseKeyItemInField(item)
      next true
    }]
    # BOTÓN DE TARJETA ENTRENADOR
    @options << [$player.name, "PlayercardA", "PlayercardB", proc {
      pbFadeOutIn(99999) do
        scene = PokemonTrainerCard_Scene.new
        screen = PokemonTrainerCardScreen.new(scene)
        screen.pbStartScreen
      end
    }]
    # BOTÓN DE GUARDAR
    @options << ["Guardar", "saveA", ["saveBm","saveBf"], proc {
      @sprites.visible = false
      scene = PokemonSave_Scene.new
      screen = PokemonSaveScreen.new(scene)
      if screen.pbSaveScreen
        @done = true
      else
        @sprites.visible = true
      end
    }]
    # BOTÓN DE OPCIONES
    @options << ["Opciones", "optionsA", "optionsB", proc {
      pbFadeOutIn(99999) do
        scene = PokemonOption_Scene.new
        screen = PokemonOptionScreen.new(scene)
        screen.pbStartScreen
        pbUpdateSceneMap
      end
    }]
    # BOTÓN DE CONTROLES
    @options << ["Controles", "controlesA", "controlesB", proc {
      pbFadeOutIn(99999) do
        scene = PokemonControls_Scene.new
        screen = PokemonControlsScreen.new(scene)
        screen.pbStartScreen
        pbUpdateSceneMap
      end
    }]
    # BOTÓN DE SALIR
    @options << ["Salir", "exitA", "exitB", proc {
      if pbConfirmMessage(_INTL("¿Estás segur\\@ de que quieres volver a la pantalla de título?"))
        @done = true
        @sprites.visible = false
        $game_temp.in_menu = false
        scene = PokemonSave_Scene.new
        screen = PokemonSaveScreen.new(scene)
        screen.pbSaveScreen
        pbFadeOutIn(99999) do
          $scene.dispose
          SaveData.mark_values_as_unloaded
          pbBGMFade(1.0)
          pbBGSFade(1.0)
          $scene = pbCallTitle
        end
      end
    }]
    @count = @options.size
    return if @count == 0
    $PokemonGlobal.last_menu_index ||= 0
    @option = $PokemonGlobal.last_menu_index
    @option = 0 if @option >= @options.size
    @done = false
    @i = 0
    @scaling = 0
    @viewport = Viewport.new(Graphics.width - 204, 4, 200, 24 + 48 * @count)
    @viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @viewport2.z = 99999
    @sprites = SpriteHash.new
    @sprites[:bgTop] = Sprite.new(@viewport)
    @sprites[:bgTop].bmp("Graphics/Pictures/DP Pause Menu/bgTop")
    @sprites[:bgMid] = Sprite.new(@viewport)
    @sprites[:bgMid].bmp("Graphics/Pictures/DP Pause Menu/bgMid")
    @sprites[:bgMid].y = 12
    @sprites[:bgMid].zoom_y = 48 * @count
    @sprites[:bgBtm] = Sprite.new(@viewport)
    @sprites[:bgBtm].bmp("Graphics/Pictures/DP Pause Menu/bgBtm")
    @sprites[:bgBtm].y = 12 + @sprites[:bgMid].zoom_y
    @sprites[:sel] = Sprite.new(@viewport)
    @sprites[:sel].bmp("Graphics/Pictures/DP Pause Menu/selector")
    @sprites[:sel].xyz = 8, 10 + 48 * @option, 1
    @sprites[:txt] = TextSprite.new(@viewport)
    # Reset shortcut positioning before drawing any shortcuts
    reset_shortcut_positioning
    draw_fly_shortcut if $bag.has?(:POKERIDER) && ADD_POKERIDER_SHORTCUT_IN_MENU
    draw_vial_shortcut if $bag.has?(:VIAL) || $bag.has?(:EMPTYVIAL)
    draw_radar_shortcut if $bag.has?(:RADAR) && (!RandomizedChallenge.enabled? || RandomizedChallenge.consistent_wild_encounters?)
    draw_repel_shortcut if $bag.has?(:INFREPEL) || $bag.has?(:INFREPELOFF)
    draw_helpful_text
    
    draw_sun_moon_icon
    draw_captured_icon 
    
    for i in 0...@options.size
      @sprites[:txt].draw([
          @options[i][0],72,26 + 48 * i,0,BaseColor,ShadowColor
      ])
      @sprites[@options[i][0].to_sym] = Sprite.new(@viewport)
      idx = (i == @option ? 2 : 1)
      path = @options[i][idx]
      path = path[$player.gender] if path.is_a?(Array)
      @sprites[@options[i][0].to_sym].bmp("Graphics/Pictures/DP Pause Menu/#{path}")
      @sprites[@options[i][0].to_sym].center_origins
      @sprites[@options[i][0].to_sym].xyz = 39, 36 + 48 * i
    end
    pbSEPlay("GUI menu open")
    main
  end
  
  def main
    loop do
      update
      old = @option
      if Input.repeat?(Input::DOWN)
        @option += 1
        @option = 0 if @option == @count
        changed = true
      end
      if Input.repeat?(Input::UP)
        @option -= 1
        @option = @count - 1 if @option == -1
        changed = true
      end
      if (Input.trigger?(Input::JUMPDOWN) || Input.trigger?(Input::AUX1) || (Input.respond_to?(:triggerex?) && Input.triggerex?(:S))) && $bag.has?(:POKERIDER) && ADD_POKERIDER_SHORTCUT_IN_MENU
        pbPlayDecisionSE
        if pokerider
          @sprites.visible = false
          @done = true
          pokerider_fly
          ret = -2
          break
        end
      elsif (Input.trigger?(Input::ACTION) || (Input.respond_to?(:triggerex?) && Input.triggerex?(:A))) && ( $bag.has?(:VIAL) || $bag.has?(:EMPTYVIAL) )
        pbPlayDecisionSE
        if use_pokevial
          draw_vial_shortcut(true)
        end
      elsif (Input.trigger?(Input::AUX2) || (Input.respond_to?(:triggerex?) && Input.triggerex?(:R))) && ( $bag.has?(:INFREPEL) || $bag.has?(:INFREPELOFF) )
        pbPlayDecisionSE
        pbToggleInfiniteRepel
        draw_repel_shortcut(true)
      elsif (Input.trigger?(Input::SPECIAL) || (Input.respond_to?(:triggerex?) && Input.triggerex?(:D))) && $bag.has?(:RADAR) && (!RandomizedChallenge.enabled? || RandomizedChallenge.consistent_wild_encounters?)
        pbPlayDecisionSE
        pbStartRadar
      elsif Input.trigger_controls?
        pbPlayDecisionSE
        pbFadeOutIn(99999) do
          scene = PokemonControls_Scene.new
          screen = PokemonControlsScreen.new(scene)
          screen.pbStartScreen
          pbUpdateSceneMap
        end
        draw_helpful_text
      end
      confirmed = true if Input.trigger?(Input::USE)
      if changed
        pbSEPlay("Voltorb Flip mark")
        $PokemonGlobal.last_menu_index = @option
        path = @options[old][1]
        path = path[$player.gender] if path.is_a?(Array)
        @sprites[@options[old][0].to_sym].bmp("Graphics/Pictures/DP Pause Menu/#{path}")
        @sprites[@options[old][0].to_sym].angle = 0
        @sprites[@options[old][0].to_sym].zoom_x = 1
        @sprites[@options[old][0].to_sym].zoom_y = 1
        @sprites[:sel].y = 10 + 48 * @option
        path = @options[@option][2]
        path = path[$player.gender] if path.is_a?(Array)
        @sprites[@options[@option][0].to_sym].bmp("Graphics/Pictures/DP Pause Menu/#{path}")
        changed = false
        @scaling = 0
        @sprites[@options[@option][0].to_sym].angle = 0
        @i = 0
      end
      if confirmed
        pbPlayDecisionSE
        @options[@option][3].call
        Input.update
      end
      confirmed = false
      if @done
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
    dispose
  end
  
  def update
    Graphics.update
    Input.update
    pbUpdateSceneMap
    if @scaling
      @scaling += 1
      case @scaling
      when 1..6
        @sprites[@options[@option][0].to_sym].zoom_x += 0.033
        @sprites[@options[@option][0].to_sym].zoom_y += 0.033
      when 12..18
        @sprites[@options[@option][0].to_sym].zoom_x -= 0.033
        @sprites[@options[@option][0].to_sym].zoom_y -= 0.033
      end
      @scaling = nil if @scaling == 18
    else
      @i += 1
      case @i
      when 1..12
        @sprites[@options[@option][0].to_sym].angle -= 0.5
      when 12..24
        @sprites[@options[@option][0].to_sym].angle -= 0.5
      when 25..36
        @sprites[@options[@option][0].to_sym].angle -= 0.5  
      when 37..48
        @sprites[@options[@option][0].to_sym].angle -= 0.5
      when 49..60
        @sprites[@options[@option][0].to_sym].angle += 0.5
      when 61..72
        @sprites[@options[@option][0].to_sym].angle += 0.5
      when 73..84
        @sprites[@options[@option][0].to_sym].angle += 0.5
      when 85..96
        @sprites[@options[@option][0].to_sym].angle += 0.5
      end
      @i = 0 if @i == 96
    end
  end
  def dispose
    @sprites.dispose
    @viewport.dispose
    Input.update
  end
end