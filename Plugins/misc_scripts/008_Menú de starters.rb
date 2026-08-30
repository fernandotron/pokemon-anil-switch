################################################################################
#                             Menú de Starters                                 #
#                               por Skyflyer                                   #
################################################################################
module PBEleccionStarters
  STARTER_REGIONS = [
    ["Kanto", [:BULBASAUR, :CHARMANDER, :SQUIRTLE]],
    ["Let's Go", [:PIKACHU_16, nil, :EEVEE_1]],
    ["Johto", [:CHIKORITA, :CYNDAQUIL, :TOTODILE]],
    ["Hoenn", [:TREECKO, :TORCHIC, :MUDKIP]],
    ["Sinnoh", [:TURTWIG, :CHIMCHAR, :PIPLUP]],
    ["Teselia", [:SNIVY, :TEPIG, :OSHAWOTT]],
    ["Kalos", [:CHESPIN, :FENNEKIN, :FROAKIE]],
    ["Alola", [:ROWLET, :LITTEN, :POPPLIO]],
    ["Galar", [:GROOKEY, :SCORBUNNY, :SOBBLE]],
    ["Hisui", [:ROWLET_1, :CYNDAQUIL_1, :OSHAWOTT_1]],
    ["Paldea", [:SPRIGATITO, :FUECOCO, :QUAXLY]],
  ]
  CHOSEN_STARTERS = 31

  GRAPHICS_PATH = File.join("Graphics", "UI", "Starter selection")
end


def pbMostrarListaStarters() 
  # Iniciar la escena
  pbFadeOutIn(99999) {
    scene = StarterMenu_Scene.new              # Creamos el viewport de la escena
    screen = StarterMenu_Screen.new(scene)     # Cargamos el viewport y la lista.
    screen.pbStartScreen                   # Comenzamos la lógica del script.
  }
end


class StarterMenu_Screen
  def initialize(scene)
    @scene = scene
    @options_to_use = PBEleccionStarters::STARTER_REGIONS
    # keep only the first 3 rows
    @options_to_use = @options_to_use.first(3) if $game_switches[MODO_CLASICO]
    # @elementos = elementos
  end

  # Función que gestiona el comienzo y final de la escena.
  def pbStartScreen
    @scene.pbStartScene       # Inicialización
    pbMessage(_INTL("Elige de qué generación quieres que sean los Pokémon Iniciales con los que puedas empezar."))
    @scene.pbSelectElement    # Gestión de la selección de elementos
    @scene.pbEndScene         # Finalizar
  end
end


#*******************************************************************************
# CLASE QUE GESTIONA LA VISUALIZACIÓN DE LOS ELEMENTOS
#*******************************************************************************
class StarterMenu_Scene
  BASELIGHT        = Color.new(248,248,248)
  SHADOWLIGHT      = Color.new(72,80,88)
  BASEDARK         = Color.new(88,88,80)
  SHADOWDARK       = Color.new(168,184,184)
  MOVINGBACKGROUND = true
  

  # Inicialización.
  def initialize
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @options_to_use = PBEleccionStarters::STARTER_REGIONS
    # keep only the first 3 rows
    @options_to_use = @options_to_use.first(3) if $game_switches[MODO_CLASICO]
  end
  

  # COMIENZO DE LA ESCENA
  def pbStartScene
    arrows_path = File.join("Graphics", "UI")
    @index = 0
    @menu_selecc = 0
    # @elementos = elementos
    @max_opciones_visibles = 4
    # Imagen de fondo
    @sprites["base"] = IconSprite.new(0,0,@viewport)
    @sprites["base"].setBitmap(File.join(PBEleccionStarters::GRAPHICS_PATH, "menu_bg"))
    # Flechas verticales
    @sprites["uparrow"] = AnimatedSprite.new(File.join(arrows_path,"up_arrow"),8,28,40,2,@viewport)
    @sprites["uparrow"].x = Graphics.width/2 - @sprites["uparrow"].bitmap.width/16
    @sprites["uparrow"].y = 64
    @sprites["uparrow"].visible = false
    @sprites["uparrow"].play
    @sprites["downarrow"] = AnimatedSprite.new(File.join(arrows_path,"down_arrow"),8,28,40,2,@viewport)
    @sprites["downarrow"].x = Graphics.width/2 - @sprites["uparrow"].bitmap.width/16
    @sprites["downarrow"].y = Graphics.height-44
    @sprites["downarrow"].visible = false
    @sprites["downarrow"].play
    # Actualizamos la variable @tam_menu en base a si hay menos opciones que las que caben.
    cursor_max_opcion
    # Dibujamos en pantalla las opciones
    pbRedrawList
  end


  def cursor_max_opcion
    # Número de opciones del menú
    @tam_menu = @options_to_use.length
    # Creamos el overlay para el título
    @sprites["overlayA"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @overlayA = @sprites["overlayA"].bitmap
    pbSetSystemFont(@overlayA)
    @overlayA.font.size = 42
    textpos = []
    textpos.push([_INTL("Elige tus Iniciales"),Graphics.width/2,26,2,BASELIGHT,SHADOWLIGHT,1])
    pbDrawTextPositions(@overlayA,textpos)
  end

  
  # Seleccionar un elemento de la lista
  def pbSelectElement
    loop do
      Graphics.update
      Input.update
      pbUpdate

      if Input.repeat?(Input::UP)
        pbPlayCursorSE
        @index -= 1
        if @index < 0
          @index = @tam_menu - 1
          @menu_selecc = [@max_opciones_visibles - 1, @tam_menu - 1].min
        elsif @menu_selecc > 0
          @menu_selecc -= 1
        end
        pbRedrawList

      elsif Input.repeat?(Input::DOWN)
        pbPlayCursorSE
        @index += 1
        if @index >= @tam_menu
          @index = 0
          @menu_selecc = 0
        elsif @menu_selecc < [@max_opciones_visibles - 1, @tam_menu - 1].min
          @menu_selecc += 1
        end
        pbRedrawList

      elsif Input.trigger?(Input::USE)
        # pbPlayCursorSE
        result =  pbMessage(_INTL("¿Quieres elegir a los iniciales de {1}? Estos serán los que estén en el Laboratorio.", @options_to_use[@index][0]), [_INTL("Sí"), _INTL("No")], -1)
        if result == 0
          pbPlayDecisionSE
          switch = 334 + @index
          $game_switches[switch] = true
          # if MonotypeChallenge.enabled? 
          #   chosen_starters = @options_to_use[@index][1]
          #   monotype_starters = pbGet(31)
          #   if monotype_starters.is_a?(Array)
          #     case  MonotypeChallenge.type
          #     when :GRASS
          #       monotype_starters[0] = chosen_starters[0]
          #     when :FIRE
          #       monotype_starters[0] = chosen_starters[1]
          #     when :WATER
          #       monotype_starters[0] = chosen_starters[2]
          #     end
          #   end
          #   pbSet(PBEleccionStarters::CHOSEN_STARTERS, monotype_starters)
          # else
          pbSet(PBEleccionStarters::CHOSEN_STARTERS, @options_to_use[@index][1])
          # end
          break
        end
      end
    end
  end



  def pbRedrawList
    # Eliminamos los sprites anteriores
    for i in 0...@tam_menu
      @sprites["selecc#{i}"]&.dispose
      @sprites.delete("selecc#{i}")
    end

    # Cálculo de desplazamiento en la lista
    diferencia_menu = @index - @menu_selecc
    elementos_visibles = @options_to_use[diferencia_menu, @max_opciones_visibles] || []

    # Dibujar los nuevos sprites de opciones visibles
    elementos_visibles.each_with_index do |elemento, i|
      @sprites["selecc#{i}"] = IconSprite.new(0, 0, @viewport)
      # Índice real del elemento dentro de la lista global
      real_index = diferencia_menu + i
      # Ruta base
      base_path = PBEleccionStarters::GRAPHICS_PATH
      # Intentar cargar gráficos específicos si existen
      graphic_name = if i == @menu_selecc
        FileTest.exist?(File.join(base_path, "option#{real_index}_sel.png")) ? "option#{real_index}_sel.png" : "option_sel.png"
      else
        FileTest.exist?(File.join(base_path, "option#{real_index}.png")) ? "option#{real_index}.png" : "option.png"
      end
      @sprites["selecc#{i}"].setBitmap(File.join(base_path, graphic_name))
      @sprites["selecc#{i}"].x = Graphics.width / 2 - (@sprites["selecc#{i}"].bitmap.width / 2)
      @sprites["selecc#{i}"].y = 98 + i * 64
    end

    # Flechas de desplazamiento
    @sprites["uparrow"].visible = (@index - @menu_selecc > 0)
    @sprites["downarrow"].visible = ((@index + ((@max_opciones_visibles - 1) - @menu_selecc)) < @options_to_use.length - 1)

    # Overlay de texto
    @sprites["overlay"]&.dispose
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @overlay = @sprites["overlay"].bitmap
    pbSetSystemFont(@overlay)

    # Dibujar los textos de los elementos visibles
    textpos = []
    elementos_visibles.each_with_index do |elemento, i|
      element_data = elemento[0]
      textpos.push([_INTL("Iniciales de ") + _INTL(element_data.to_s), 110, 116 + i * 64, 0, BASEDARK, SHADOWDARK])
    end
    pbDrawTextPositions(@overlay, textpos)
  end

  

  # Actualizar los gráficos.
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
  

  # Fin de la escena.
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end