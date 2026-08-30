class Pokemon
    def get_egg_moves_full()
        especie = self.species_data
        return especie.egg_moves if !especie.egg_moves.empty?
        prevo = especie.get_previous_species
        return GameData::Species.get_species_form(prevo, especie.form).get_egg_moves if prevo != especie.species
        return especie.egg_moves
    end

    def can_learn_egg_move?
        return false if egg? || shadowPokemon?
        return !get_egg_moves_full().empty?
    end
end

#===============================================================================
# Scene class for handling appearance of the screen
#===============================================================================
class EggMoveLearner_Scene
    VISIBLEMOVES = 4
  
    def pbDisplay(msg, brief = false)
      UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
    end
  
    def pbConfirm(msg)
      UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
    end
  
    def pbUpdate
      pbUpdateSpriteHash(@sprites)
    end
  
    def pbStartScene(pokemon, moves)
      @pokemon = pokemon
      @moves = moves
      moveCommands = []
      moves.each { |m| moveCommands.push(GameData::Move.get(m).name) }
      # Create sprite hash
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @sprites = {}
      addBackgroundPlane(@sprites, "bg", "Move Reminder/bg", @viewport)
      @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
      @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
      @sprites["pokeicon"].x = 314  # Cambiado de 320 a 314
      @sprites["pokeicon"].y = 70   # Cambiado de 84 a 70
      @sprites["background"] = IconSprite.new(0, 0, @viewport)
      @sprites["background"].setBitmap("Graphics/UI/Move Reminder/cursor")
      @sprites["background"].y = 70  # Cambiado de 78 a 70
      @sprites["background"].src_rect = Rect.new(0, 72, 258, 72)
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSystemFont(@sprites["overlay"].bitmap)
      @sprites["commands"] = Window_CommandPokemon.new(moveCommands, 32)
      @sprites["commands"].height = 32 * (VISIBLEMOVES + 1)
      @sprites["commands"].visible = false
      @sprites["msgwindow"] = Window_AdvancedTextPokemon.new
      @sprites["msgwindow"].visible = false
      @sprites["msgwindow"].viewport = @viewport
      @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      pbDrawMoveList
      pbDeactivateWindows(@sprites)
      # Fade in all sprites
      pbFadeInAndShow(@sprites) { pbUpdate }
    end
  
    def pbDrawMoveList
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      @pokemon.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * 28, 64, 28)
        # Posición actualizada para los tipos
        type_x = (@pokemon.types.length == 1) ? 396 : 362 + (70 * i)  # Cambiado de 400/366 a 396/362
        overlay.blt(type_x, 50, @typebitmap.bitmap, type_rect)  # Cambiado Y de 70 a 50
      end
      textpos = [
        # Header con nuevos colores
        [_INTL("¿Enseñar movimiento?"), 16, 38, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)]
      ]
      imagepos = []
      yPos = 70  # Cambiado de 88 a 70
      VISIBLEMOVES.times do |i|
        moveobject = @moves[@sprites["commands"].top_item + i]
        if moveobject
          moveData = GameData::Move.get(moveobject)
          type_number = GameData::Type.get(moveData.display_type(@pokemon)).icon_position
          imagepos.push([_INTL("Graphics/UI/types"), 10, yPos + 1, 0, type_number * 28, 64, 28])  # Ajustado X e Y
          # Nombre del movimiento con nuevos colores
          textpos.push([moveData.name, 76, yPos + 6, :left, Color.new(248, 248, 248), Color.new(0, 0, 0)])  # Cambiado posición y colores
          # PP con nuevos colores
          textpos.push([_INTL("PP"), 140, yPos + 34, :left, Color.new(248, 248, 248), Color.new(0, 0, 0)])  # Cambiado posición y colores
          if moveData.total_pp > 0
            textpos.push([moveData.total_pp.to_s + "/" + moveData.total_pp.to_s, 240, yPos + 34, :right,
                          Color.new(248, 248, 248), Color.new(0, 0, 0)])  # Cambiado posición y colores
          else
            textpos.push(["--", 240, yPos + 34, :right, Color.new(248, 248, 248), Color.new(0, 0, 0)])  # Cambiado posición y colores
          end
        end
        yPos += 64
      end
      imagepos.push(["Graphics/UI/Move Reminder/cursor",
                     7, 69 + ((@sprites["commands"].index - @sprites["commands"].top_item) * 64),  # Ajustado posición del cursor
                     0, 0, 258, 72])
      selMoveData = GameData::Move.get(@moves[@sprites["commands"].index])
      power = selMoveData.display_damage(@pokemon)
      category = selMoveData.display_category(@pokemon)
      accuracy = selMoveData.display_accuracy(@pokemon)
      
      # Propiedades del movimiento con nuevos colores y posiciones
      textpos.push([_INTL("CATEGORÍA"), 278, 165, :left, Color.new(64, 64, 64), Color.new(162, 162, 162)])  # Cambiado posición y colores
      textpos.push([_INTL("POTENCIA"), 278, 105, :left, Color.new(64, 64, 64), Color.new(162, 162, 162)])   # Cambiado posición y colores
      power_text = power <= 1 ? (power == 1 ? "???" : "---") : power.to_s
      textpos.push([power_text, 480, 105, :right, Color.new(64, 64, 64), Color.new(162, 162, 162)])  # Cambiado posición y colores
      textpos.push([_INTL("PRECISIÓN"), 278, 135, :left, Color.new(64, 64, 64), Color.new(162, 162, 162)])  # Cambiado posición y colores
      accuracy_text = accuracy == 0 ? "---" : "#{accuracy}%"
      textpos.push([accuracy_text, 480, 135, :right, Color.new(64, 64, 64), Color.new(162, 162, 162)])  # Cambiado posición y colores
      
      pbDrawTextPositions(overlay, textpos)
      imagepos.push(["Graphics/UI/category", 434, 160, 0, category * 28, 64, 28])  # Cambiado posición
      
      # Botones de navegación corregidos
      if @sprites["commands"].top_item > 0  # Mostrar flecha arriba si hay elementos arriba de la vista
        imagepos.push(["Graphics/UI/Move Reminder/buttons", 228, 36, 0, 20, 20, 20])
      end
      if @sprites["commands"].top_item + VISIBLEMOVES < @moves.length  # Mostrar flecha abajo si hay elementos debajo de la vista
        imagepos.push(["Graphics/UI/Move Reminder/buttons", 228, Graphics.height - 52, 0, 0, 20, 20])
      end
      
      pbDrawImagePositions(overlay, imagepos)
      # Descripción con nuevos colores y posición
      drawTextEx(overlay, 275, 200, 235, 5, selMoveData.description,  # Cambiado posición
                 Color.new(64, 64, 64), Color.new(162, 162, 162))
    end
  
    # Processes the scene
    def pbChooseMove
      oldcmd = -1
      pbActivateWindow(@sprites, "commands") do
        loop do
          oldcmd = @sprites["commands"].index
          Graphics.update
          Input.update
          pbUpdate
          if @sprites["commands"].index != oldcmd
            @sprites["background"].x = 7  # Ajustado posición X
            @sprites["background"].y = 69 + ((@sprites["commands"].index - @sprites["commands"].top_item) * 64)  # Ajustado posición Y
            pbDrawMoveList
          end
          if Input.trigger?(Input::BACK)
            return nil
          elsif Input.trigger?(Input::USE)
            return @moves[@sprites["commands"].index]
          end
        end
      end
    end
  
    # End the scene here
    def pbEndScene
      pbFadeOutAndHide(@sprites) { pbUpdate }
      pbDisposeSpriteHash(@sprites)
      @typebitmap.dispose
      @viewport.dispose
    end
end
  
#===============================================================================
# Screen class for handling game logic
#===============================================================================
class EggMoveLearnerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbGetLearnableEggMoves(pkmn)
    return [] if !pkmn || pkmn.egg? || pkmn.shadowPokemon?
    return pkmn.get_egg_moves_full()
  end

  def pbStartScreen(pkmn)
    moves = pbGetLearnableEggMoves(pkmn)
    @scene.pbStartScene(pkmn, moves)
    loop do
      move = @scene.pbChooseMove
      if move
        if @scene.pbConfirm(_INTL("¿Enseñar {1}?", GameData::Move.get(move).name))
          if pbLearnMove(pkmn, move)
            $stats.moves_taught_by_reminder += 1
            @scene.pbEndScene
            return true
          end
        end
      elsif @scene.pbConfirm(_INTL("¿Dejar de enseñarle un movimiento a {1}?", pkmn.name))
        @scene.pbEndScene
        return false
      end
    end
  end
end
  
def pbLearnEggMoveScreen(pkmn)
    retval = true
    pbFadeOutIn do
      scene = EggMoveLearner_Scene.new
      screen = EggMoveLearnerScreen.new(scene)
      retval = screen.pbStartScreen(pkmn)
    end
    return retval
end