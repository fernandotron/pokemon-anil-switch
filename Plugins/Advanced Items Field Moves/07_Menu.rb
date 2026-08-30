#===============================================================================
# => Quick Menu Moves
#===============================================================================
# def pbUseKeyItem
#   moves = []
#   moves.concat(AIFM_RockSmash[:move_name])
#   moves.concat(AIFM_Cut[:move_name])
#   # moves.concat(AIFM_IceSmash[:move_name])
#   moves.concat(AIFM_Headbutt[:move_name])
#   # moves.concat(AIFM_SweetScent[:move_name])
#   moves.concat(AIFM_Strength[:move_name])
#   moves.concat(AIFM_Flash[:move_name])
#   # moves.concat(AIFM_Defog[:move_name])
#   # moves.concat(AIFM_Weather[:move_name])
#   # moves.concat(AIFM_Camouflage[:move_name])
#   moves.concat(AIFM_Surf[:move_name])
#   # moves.concat(AIFM_Dive[:move_name])
#   # moves.concat(AIFM_Waterfall[:move_name])
#   # moves.concat(AIFM_Whirlpool[:move_name])
#   # moves.concat(AIFM_Fly[:move_name])
#   # moves.concat(AIFM_Dig[:move_name])
#   # moves.concat(AIFM_Teleport[:move_name])
#   moves.concat(AIFM_RockClimb[:move_name])
#   # moves.concat(AIFM_Lift[:move_name])
#   # moves.concat(AIFM_LavaSurf[:move_name])
#   # moves.concat(AIFM_Lavafall[:move_name])
#   # moves.concat(AIFM_LavaSwirl[:move_name])
#   # moves.concat(AIFM_SenseTruth[:move_name])
#   # moves.concat(AIFM_SecretBase[:move_name]) if PluginManager.findDirectory("Secret Bases Remade")
#   moves.sort!
#   real_moves = []
#   moves.each do |move|
#     $player.party.each_with_index do |pkmn, i|
#       next if pkmn.egg? || !pkmn.hasMove?(move)
#       real_moves.push([move, i]) if pbCanUseHiddenMove?(pkmn, move, false)
#     end
#   end
#   real_items = []
#   $bag.registered_items.each do |i|
#     itm = GameData::Item.get(i).id
#     real_items.push(itm) if $bag.has?(itm)
#   end
#   if real_items.length == 0 && real_moves.length == 0
#     pbMessage(_INTL("Puedes registrar un objeto de la Mochila para usarlo con esta tecla."))
#   else
#     $game_temp.in_menu = true
#     $game_map.update
#     sscene = PokemonReadyMenu_Scene.new
#     sscreen = PokemonReadyMenu.new(sscene)
#     sscreen.pbStartReadyMenu(real_moves, real_items)
#     $game_temp.in_menu = false
#   end
# end

#===============================================================================
# Select Move Menu Button
#===============================================================================
class SelectMoveMenuButton < Sprite
  attr_reader :index   # ID of button
  attr_reader :selected
  attr_reader :side

  def initialize(index, command, selected, viewport = nil, pp_check = nil)
    super(viewport)
    @index = index
    @command = command   # Item/move ID, name, mode (T move/F item), pkmnIndex
    @selected = selected
    @pp_check = pp_check # Flag to determine if PP display is needed
    @button = AnimatedBitmap.new("Graphics/UI/Ready Menu/icon_movesbutton")
    @contents = Bitmap.new(@button.width, @button.height / 2)
    self.bitmap = @contents
    pbSetSystemFont(self.bitmap)
    @icon = PokemonIconSprite.new($player.party[@command[2]], viewport)
    @icon.setOffset(PictureOrigin::CENTER)
    @icon.z = self.z + 1
    puts ("Quick Menu pp_check ? #{@pp_check}") if $DEBUG
    refresh
  end

  def dispose
    @button.dispose
    @contents.dispose
    @icon.dispose
    super
  end

  def visible=(val)
    @icon.visible = val
    super(val)
  end

  def selected=(val)
    oldsel = @selected
    @selected = val
    refresh if oldsel != val
  end

  def refresh
    sel = (@selected == @index)
    self.y = ((Graphics.height - (@button.height / 2)) / 2) - ((@selected - @index) * ((@button.height / 2) + 4))
    self.x = (sel) ? Graphics.width - @button.width : Graphics.width + 16 - @button.width
    @icon.x = self.x + 52
    @icon.y = self.y + 32
    self.bitmap.clear
    rect = Rect.new(0, (sel ? @button.height / 2 : 0), @button.width, @button.height / 2)
    self.bitmap.blt(0, 0, @button.bitmap, rect)
    # Add PP display if pp_check is true and @command[3] contains data
    if @pp_check && @command[3]
      pp_data = @command[3] # PP data passed in @command[3]
      current_pp = pp_data[:pp]
      max_pp = pp_data[:max_pp]
      # Define PP color thresholds
      ppBase   = [Color.new(248, 248, 248),  # More than 1/2 of total PP
                  Color.new(248, 192, 0),    # 1/2 of total PP or less
                  Color.new(248, 136, 32)]   # 1/4 of total PP or less
      ppShadow = [Color.new(40, 40, 40),     # More than 1/2 of total PP
                  Color.new(144, 104, 0),    # 1/2 of total PP or less
                  Color.new(144, 72, 24)]    # 1/4 of total PP or less
      # Determine PP fraction
      ppfraction = 0
      if current_pp * 4 <= max_pp
        ppfraction = 2
      elsif current_pp * 2 <= max_pp
        ppfraction = 1
      end
      # Add move name and PP text with dynamic colors
      textpos = [
        [@command[1], 150, 10, :center, Color.new(248, 248, 248), Color.new(40, 40, 40), :outline],
        [_INTL("{1}/{2}", current_pp, max_pp), 150, 38, :center, ppBase[ppfraction], ppShadow[ppfraction], :outline]
      ]
    else
      # Draw the move name
      textpos = [[@command[1], 150, 24, :center, Color.new(248, 248, 248), Color.new(40, 40, 40), :outline]]
    end
    pbDrawTextPositions(self.bitmap, textpos)
  end

  def update
    @icon&.update
    super
  end
end

#===============================================================================
# SelectMoveMenu Scene
#===============================================================================
class SelectMoveMenu_Scene
  attr_reader :sprites

  def pbStartScene(commands, pp_check = false)
    @commands = commands
    @index = 0
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    # Create buttons
    @commands.each_with_index do |command, i|
      @sprites["button#{i}"] = SelectMoveMenuButton.new(i, command, @index, @viewport, pp_check)
    end
    pbSEPlay("GUI menu open")
  end

  def pbShowCommands
    loop do
      pbUpdate
      if Input.trigger?(Input::UP)
        pbPlayCursorSE
        @index = (@index - 1) % @commands.length
        refresh_buttons
      elsif Input.trigger?(Input::DOWN)
        pbPlayCursorSE
        @index = (@index + 1) % @commands.length
        refresh_buttons
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        return @index
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        return -1
      end
    end
  end

  def refresh_buttons
    @commands.each_index do |i|
      @sprites["button#{i}"].selected = @index
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# SelectMoveMenu Main
#===============================================================================
class SelectMoveMenu
  def initialize(scene)
    @scene = scene
  end

  # Accept two arguments: moves and pp_check
  def pbStartSelectMoveMenu(moves, pp_check = false)
    @scene.pbStartScene(moves, pp_check)
    command = @scene.pbShowCommands
    @scene.pbEndScene
    return nil if command < 0
    return moves[command]
  end
end

#===============================================================================
# Use Move from SelectMoveMenu
#===============================================================================
def pbSelectMoveMenu(moves, pp_check = false)
  if moves.empty?
    pbMessage(_INTL("Ninguno de tus Pokémon tiene un movimiento utilizable."))
    return nil
  end
  # Start the SelectMoveMenu
  sscene = SelectMoveMenu_Scene.new
  sscreen = SelectMoveMenu.new(sscene)
  result = sscreen.pbStartSelectMoveMenu(moves, pp_check) # Pass the pp_check as true
  return nil if result.nil? # Handle if the user cancels the menu
  # Extract selected move data
  move_id = result[0]
  user = $player.party[result[2]] # Pokémon index is stored in the third element
  #pbMessage(_INTL("Dude {1} used {2}!", user.name, GameData::Move.get(move_id).name))
  #pbUseHiddenMove(user, move_id)
  return user, move_id
end

#===============================================================================
# Option Menu Added
#===============================================================================
class PokemonSystem < PokemonSystem
  attr_accessor :animation_item
  attr_accessor :animation_move
  attr_accessor :ask_text
  attr_accessor :moves_option
  attr_accessor :camouflaged
  attr_accessor :surf_option

  alias aifm_initialize initialize
  def initialize
    aifm_initialize
    @animation_item       = 0
    @animation_move       = 0
    @moves_option         = 0
    @ask_text             = 1
    # @camouflaged          = AIFM_Camouflage[:transpernt] - AIFM_Camouflage[:transpernt_min]
    @surf_option          = 0
  end
end

#===============================================================================
# Options AIFM Menu Integration
#===============================================================================
module AIFMHandlers
  @@handlers = {}

  def self.add(category, option_name, hash)
    @@handlers[category] ||= {}
    @@handlers[category][option_name] = hash
  end

  def self.get_handlers(category)
    return @@handlers[category] || {}
  end

  def self.each(category)
    return if !@@handlers.has_key?(category)
    @@handlers[category].each { |option_name, hash| yield option_name, hash }
  end

  def self.each_sorted(category)
    return if !@@handlers.has_key?(category)
    @@handlers[category].sort_by { |option_name, hash| hash["order"] || @@handlers[category].keys.index(option_name) }.each do |option_name, hash|
      yield option_name, hash
    end
  end
end