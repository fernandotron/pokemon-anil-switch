################################################################################
#                             Menú de Monotype                                 #
################################################################################
module MonotypeMenu
  # Configuración del menú
  module Config
    # Variable que almacena el tipo elegido
    CHOSEN_MONOTYPE = 500
    
    # Configuración visual
    MAX_VISIBLE_OPTIONS = 4

    # Variable que almacena un array con los starters del tipo elegido
    STARTER_VARIABLE_ID = 31

    INTRO_TEXT = _INTL("¿Quieres activar el <b>RETO MONOTYPE</b>? Si es tu <b>primera partida</b> en Pokémon Añil te recomendamos <b>no elegirlo</b>.")

    INTRO_TEXT_ACTIVE = _INTL("El <b>RETO MONOTYPE</b> de tipo <b>{1}</b> está activado.\n¿Qué quieres hacer?")

    INFO_TEXT = _INTL("Un \\c[1]Reto Monotype\\c[0] es aquel en el que el jugador solo puede capturar a Pokémon de un determinado tipo. Cualquier otro Pokémon que no lo sea no podrá ser capturado. Por temas de balanceo y para garantizar una buena experiencia de juego, no todos los tipos son recomendados para hacer el \\c[1]Reto Monotype\\c[0]. Te aconsejamos que elijas un tipo de los preferentes.")

    GRAPHICS_PATH = File.join("Graphics", "UI", "MonotypeMenu")
  end

  # Colores para la interfaz
  module Colors
    BASELIGHT = Color.new(248, 248, 248).freeze
    SHADOWLIGHT = Color.new(72, 80, 88).freeze
    BASEDARK = Color.new(88, 88, 80).freeze
    SHADOWDARK = Color.new(168, 184, 184).freeze
  end

  # Tipos recomendados para jugadores principiantes (balanceados y fáciles de obtener)
  LISTA_RECOMENDADOS = [
    ["Planta",   :GRASS,   [:SNOVER, :BUDEW, :LOTAD]],
    ["Fuego",    :FIRE,    [:MAGBY, :LITWICK, :ROLYCOLY]],
    ["Agua",     :WATER,   [:BUIZEL, :HORSEA, :TYMPOLE]],
    ["Eléctrico",:ELECTRIC,[:SHINX, :MAGNEMITE, :ELEKID]],
    ["Normal",   :NORMAL,  [:TEDDIURSA, :WOOLOO, :LECHONK]],
    ["Bicho",    :BUG,     [:SCATTERBUG, :GRUBBIN, :BLIPBUG]],
    ["Veneno",   :POISON,  [:SKRELP, :CROAGUNK, :SALANDIT]],
    ["Volador",  :FLYING,  [:STARLY, :PIKIPEK, :ROOKIDEE]],
    ["Psíquico", :PSYCHIC, [:MUNNA, :BRONZOR, :HATENNA]],
    ["Lucha",    :FIGHTING,[:MACHOP, :MAKUHITA, :PANCHAM]],
    ["Hada",     :FAIRY,   [:CUTIEFLY, :SPRITZEE, :SWIRLIX]]
  ]

  # Tipos no recomendados (más difíciles o escasos al inicio)
  LISTA_NO_RECOMENDADOS = [
    ["Tierra",    :GROUND, [:TRAPINCH, :SANDILE, :GIBLE]],
    ["Roca",      :ROCK,   [:GEODUDE, :NACLI, :LARVITAR]],
    ["Fantasma",  :GHOST,  [:GASTLY, :LITWICK, :DUSKULL]],
    ["Acero",     :STEEL,  [:MAGNEMITE, :HONEDGE, :TINKATINK]],
    ["Hielo",     :ICE,    [:SPHEAL, :VANILLITE, :FRIGIBAX]],
    ["Dragón",    :DRAGON, [:DRATINI, :GOOMY, :JANGMOO]],
    ["Siniestro", :DARK,   [:ZIGZAGOON_1, :IMPIDIMP, :DEINO]]
  ]

  module_function

  def display
    if MonotypeChallenge.enabled?
      choice = pbMessage(
        _INTL(Config::INTRO_TEXT_ACTIVE, MonotypeChallenge.type_name),
        [_INTL("Cambiar tipo"), _INTL("Desactivar")], -1
      )
    else
      choice = pbMessage(
        Config::INTRO_TEXT,
        [_INTL("Sí"), _INTL("Información"), _INTL("No")], -1
      )
    end

    case choice
    when 0  # Sí
      show_type_selection_menu
    when 1  # Información
      if MonotypeChallenge.enabled?
        MonotypeChallenge.disable
      else  
        show_info
        display
      end
    when 2  # No
      return
    end
  end

  def show_type_selection_menu
    current_type = :recommended
  
    loop do
      lista = get_types_list(current_type)
      primary_list = (current_type == :recommended)
      
      scene = MonotypeMenu_Scene.new(lista, primary_list)
      screen = MonotypeMenu_Screen.new(scene)
      result = screen.pbStartScreen
      
      case result
      when :terminar
        break
      when :show_not_recommended
        current_type = :not_recommended
      when :show_recommended
        current_type = :recommended
      end
    end
  end

  def get_types_list(current_type)
    current_type == :recommended ? 
      MonotypeMenu::LISTA_RECOMENDADOS : 
      MonotypeMenu::LISTA_NO_RECOMENDADOS
  end
  
  def show_info
    pbMessage(MonotypeMenu::Config::INFO_TEXT)
  end

  class MonotypeMenu_Screen
    def initialize(scene)
      @scene = scene
    end
  
    def pbStartScreen
      @scene.pbStartScene
      result = @scene.pbSelectElement
      @scene.pbEndScene unless @scene.closed?
      result
    end
  end


  #*******************************************************************************
  # CLASE QUE GESTIONA LA VISUALIZACIÓN DE LOS ELEMENTOS
  #*******************************************************************************
  class MonotypeMenu_Scene
    include Colors
  
    # Inicialización.
    def initialize(type_list, primary_list)
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @sprites = {}
      @type_list = type_list
      @primary_list = primary_list
      @max_visible_options = Config::MAX_VISIBLE_OPTIONS
      @close = false
    end
    
  
    # COMIENZO DE LA ESCENA
    def pbStartScene
      initialize_variables
      create_base_sprites
      create_navigation_arrows
      configure_menu
      pbRedrawList
      pbFadeInAndShow(@sprites) { pbUpdate }
    end
  
    private
  
    def initialize_variables
      @index = 0
      @selection = 0
    end
  
    def create_base_sprites
      @sprites["base"] = IconSprite.new(0, 0, @viewport)
      @sprites["base"].setBitmap(File.join(Config::GRAPHICS_PATH, "menu_bg"))
    end
  
    def create_navigation_arrows
      # Flecha superior
      arrows_path = File.join("Graphics", "UI")
      @sprites["uparrow"] = AnimatedSprite.new(File.join(arrows_path,"up_arrow"), 8, 28, 40, 2, @viewport)
      @sprites["uparrow"].x = Graphics.width / 2 - @sprites["uparrow"].bitmap.width / 16
      @sprites["uparrow"].y = 64
      @sprites["uparrow"].visible = false
      @sprites["uparrow"].play
  
      # Flecha inferior
      @sprites["downarrow"] = AnimatedSprite.new(File.join(arrows_path,"down_arrow"), 8, 28, 40, 2, @viewport)
      @sprites["downarrow"].x = Graphics.width / 2 - @sprites["uparrow"].bitmap.width / 16
      @sprites["downarrow"].y = Graphics.height - 44
      @sprites["downarrow"].visible = false
      @sprites["downarrow"].play
    end
  
    def configure_menu
      @menu_size = @type_list.length + 1 # +1 para opción especial (ver otros tipos o volver)
      create_overlay_title
    end
  
    def create_overlay_title
      @sprites["overlayA"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @overlayA = @sprites["overlayA"].bitmap
      pbSetSystemFont(@overlayA)
      @overlayA.font.size = 42
      titulo = _INTL("Elige un tipo Monotype")
      pbDrawTextPositions(@overlayA, [[titulo, Graphics.width / 2, 26, 2, BASELIGHT, SHADOWLIGHT, 1]])
    end
  
    public
  
    # Seleccionar un elemento de la lista
    def pbSelectElement
      loop do
        Graphics.update
        Input.update
        pbUpdate
  
        if Input.repeat?(Input::UP)
          handle_navigation_up
        elsif Input.repeat?(Input::DOWN)
          handle_navigation_down
        elsif Input.trigger?(Input::USE)
          result = handle_selection
          return result if result
        end
      end
    end
  
    private
  
    def handle_navigation_up
      pbPlayCursorSE
      if @index > 0
        @index -= 1
        @selection -= 1 if @selection > 0
      else
        # Ir al final de la lista
        @index = @menu_size - 1
        @selection = [@max_visible_options - 1, @menu_size - 1].min
      end
      pbRedrawList
    end
  
    def handle_navigation_down
      pbPlayCursorSE
      if @index < @menu_size - 1
        @index += 1
        @selection += 1 if @selection < [@max_visible_options - 1, @menu_size - 1].min
      else
        # Volver al inicio
        @index = 0
        @selection = 0
      end
      pbRedrawList
    end
  
    def handle_selection
      if @index == @menu_size - 1
        # Opción especial (cambiar lista o volver)
        return @primary_list ? :show_not_recommended : :show_recommended
      else
        # Seleccionar tipo
        return confirm_selection
      end
    end
  
    def confirm_selection
      type = @type_list[@index]
      nombre, simbolo, starters = type
      
      mensaje = build_confirmation_message(nombre)    
      if pbConfirmMessage(mensaje)
        apply_selection(simbolo, starters)
        return :terminar
      end
      nil
    end
  
    def build_confirmation_message(nombre)
      advertencia = @primary_list ? 
        "" : 
        " Recuerda que has elegido un tipo <b>no recomendado</b> para este reto por la escasez de este en el comienzo del juego."
      
      _INTL("¿Quieres elegir el tipo <b>{1}</b> para tu Reto Monotype?{2} <b>No podrás cambiarlo una vez hayas iniciado la partida.</b>",
            nombre, advertencia)
    end
  
    def apply_selection(simbolo, starters)
      pbPlayDecisionSE
      $game_variables[Config::CHOSEN_MONOTYPE] = simbolo
      MonotypeChallenge.type = simbolo
      if defined?(RandomizedChallenge) && RandomizedChallenge.enabled?
        generate_random_starters
        chosen_starters = RandomizedChallenge::RANDOM_STARTER_VARIABLES.map { |var| pbGet(var) }
      else
        chosen_starters = pbGet(31)
      end
      
      if chosen_starters.is_a?(Array)
        case MonotypeChallenge.type
        when :GRASS
          starters[0] = chosen_starters[0]
        when :FIRE
          starters[1] = chosen_starters[1]
        when :WATER
          starters[2] = chosen_starters[2]
        when :ELECTRIC
          if $game_switches[335] # Switch Let's GO
            starters[0] = chosen_starters[0]
          end
        when :NORMAL
          if $game_switches[335] # Switch Let's GO
            starters[2] = chosen_starters[2]
          end
        end
      end
      pbSet(Config::STARTER_VARIABLE_ID, starters)
      @close = true
      pbEndScene
    end
  
    public
  
  
    def pbRedrawList
      clear_previous_sprites
      elementos_visibles = calculate_visible_elements
      
      create_option_sprites(elementos_visibles)
      update_arrow_visibility
      draw_option_text(elementos_visibles)
    end
  
    private
  
    def clear_previous_sprites
      (0...@menu_size).each do |i|
        @sprites["selecc#{i}"]&.dispose
        @sprites.delete("selecc#{i}")
      end
    end
  
    def calculate_visible_elements
      difference = @index - @selection
      elements = @type_list[difference, @max_visible_options] || []
      
      # Añadir la opción especial si es necesaria
      if difference + @max_visible_options >= @menu_size
        elements << nil  # Para mostrar la última opción
      end
      
      elements
    end
  
    def create_option_sprites(visible_elements)
      visible_elements.each_with_index do |element, i|
        @sprites["selecc#{i}"] = IconSprite.new(0, 0, @viewport)
        
        base_path = Config::GRAPHICS_PATH
        graphic_name = (i == @selection) ? "option_sel.png" : "option.png"
        
        @sprites["selecc#{i}"].setBitmap(File.join(base_path, graphic_name))
        @sprites["selecc#{i}"].x = Graphics.width / 2 - (@sprites["selecc#{i}"].bitmap.width / 2)
        @sprites["selecc#{i}"].y = 98 + i * 64
      end
    end
  
    def update_arrow_visibility
      @sprites["uparrow"].visible = (@index - @selection > 0)
      @sprites["downarrow"].visible = ((@index + ((@max_visible_options - 1) - @selection)) < @menu_size - 1)
    end
  
    def draw_option_text(elementos_visibles)
      # Limpiar overlay anterior
      @sprites["overlay"]&.dispose
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @overlay = @sprites["overlay"].bitmap
      pbSetSystemFont(@overlay)
  
      textpos = []
      elementos_visibles.each_with_index do |elemento, i|
        texto = get_option_text(elemento)
        textpos.push([texto, Graphics.width / 2, 116 + i * 64, 2, BASEDARK, SHADOWDARK])
      end
      
      pbDrawTextPositions(@overlay, textpos)
    end
  
    def get_option_text(element)
      if element
        _INTL("Tipo {1}", element[0])
      else
        @primary_list ? _INTL("Tipos no recomendados") : _INTL("Volver atrás")
      end
    end
  
    public
  
  
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
  
    # Verificar si debe cerrar completamente el menú
    def closed?
      @close || false
    end
  end
end