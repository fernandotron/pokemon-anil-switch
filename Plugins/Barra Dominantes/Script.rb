# Constants for better maintainability
module BossBattleConstants
  # Switch for boss battle mode
  BOSS_BATTLE_SWITCH = 45
  
  # Graphics paths
  GRAPHICS_PATH = "Graphics/UI/Battle/"
  DATABOX_SPECIAL = "databox_special"
  DATABOX_SPECIAL_FOE = "databox_special_foe" 
  DATABOX_SPECIAL_THIN = "databox_special_thin"
  DATABOX_NORMAL = "databox_normal"
  DATABOX_NORMAL_FOE = "databox_normal_foe"
  DATABOX_THIN = "databox_thin"
  DATABOX_THIN_FOE = "databox_thin_foe"
  
  # HP bar widths
  HP_BAR_WIDTH_BOSS = 132
  HP_BAR_WIDTH_NORMAL = 78
  
  # Z-depth values for proper layering
  HP_BAR_Z_BEHIND_POKEMON = 160   # Valor para barra HP 
  POKEMON_SPRITE_Z_BOSS = 200     # Valor para sprite del Pokémon (adelante)
  
  # Position offsets for different side sizes
  SIDE_SIZE_2_X_OFFSETS = [-12, 12, 0, 0].freeze
  SIDE_SIZE_2_Y_OFFSETS_BOSS = [-20, -39, 34, 25].freeze
  SIDE_SIZE_2_Y_OFFSETS_NORMAL = [-25, -39, 39, 25].freeze
  
  SIDE_SIZE_3_X_OFFSETS = [-12, 12, -6, 6, 0, 0].freeze
  SIDE_SIZE_3_Y_OFFSETS_BOSS = [-42, -51, 4, 5, 50, 51].freeze
  SIDE_SIZE_3_Y_OFFSETS_NORMAL = [-47, -51, 9, 5, 59, 51].freeze
end

alias __boss__pbStartOver pbStartOver unless defined?(__boss__pbStartOver)
def pbStartOver(gameover = false)
  $game_switches[BossBattleConstants::BOSS_BATTLE_SWITCH] = false
  $game_switches[NO_EXP_SWITCH] = false
  return __boss__pbStartOver(gameover)
end

# NUEVO: Modificar BattlerSprite solo para subir su z en batallas de boss
class Battle::Scene::BattlerSprite < RPG::Sprite
  include BossBattleConstants
  
  alias __pbSetPosition_boss pbSetPosition unless method_defined?(:__pbSetPosition_boss)
  
  def pbSetPosition
    __pbSetPosition_boss
    
    # Si es una batalla de jefe y es un enemigo, usar z más alto
    if $game_switches[BossBattleConstants::BOSS_BATTLE_SWITCH] && @index && @index.odd?
      self.z = BossBattleConstants::POKEMON_SPRITE_Z_BOSS
    end
  end
end

class Battle::Scene::PokemonDataBox < Sprite
  include BossBattleConstants
  
  alias __initializeDataBoxGraphic_boss initializeDataBoxGraphic unless method_defined?(:__initializeDataBoxGraphic_boss)
  
  def initializeDataBoxGraphic(sideSize)
    return __initializeDataBoxGraphic_boss(sideSize) unless boss_battle_active?
    
    @is_boss_battle = boss_battle_active?
    @on_player_side = @battler.index.even?
    
    setup_databox_bitmap(sideSize)
    configure_sprite_properties(sideSize)
    apply_side_size_adjustments(sideSize)
  end
  
  private
  
  def boss_battle_active?
    $game_switches[BossBattleConstants::BOSS_BATTLE_SWITCH] ? true : false
  end
  
  def setup_databox_bitmap(sideSize)
    bg_filename = get_background_filename(sideSize)
    @databoxBitmap&.dispose
    @databoxBitmap = AnimatedBitmap.new(bg_filename)
  end
  
  def get_background_filename(sideSize)
    base_name = if @is_boss_battle
                  sideSize == 1 ? DATABOX_SPECIAL : DATABOX_SPECIAL_THIN
                else
                  sideSize == 1 ? DATABOX_NORMAL : DATABOX_THIN
                end
    
    foe_suffix = @battler.index.odd? ? "_foe" : ""
    _INTL("#{GRAPHICS_PATH}#{base_name}#{foe_suffix}")
  end
  
  def configure_sprite_properties(sideSize)
    @show_hp_numbers = @on_player_side
    @show_exp_bar = @on_player_side && sideSize == 1
    @hpBarWidth = @is_boss_battle ? HP_BAR_WIDTH_BOSS : HP_BAR_WIDTH_NORMAL
    
    if @on_player_side
      setup_player_side_properties
    else
      setup_enemy_side_properties
    end
  end
  
  def setup_player_side_properties
    @spriteX = Graphics.width - 244
    @spriteY = Graphics.height - 192
    @spriteBaseX = 34
  end
  
  def setup_enemy_side_properties
    if @is_boss_battle
      @spriteX = (Graphics.width - @databoxBitmap.width) / 2
      @spriteY = 0
      @spriteBaseX = (@databoxBitmap.width - 180) / 2
    else
      @spriteX = -16
      @spriteY = 36
      @spriteBaseX = 16
    end
    @show_hp_percent = true
  end
  
  def apply_side_size_adjustments(sideSize)
    case sideSize
    when 2
      @spriteX += SIDE_SIZE_2_X_OFFSETS[@battler.index]
      y_offsets = @is_boss_battle ? SIDE_SIZE_2_Y_OFFSETS_BOSS : SIDE_SIZE_2_Y_OFFSETS_NORMAL
      @spriteY += y_offsets[@battler.index]
    when 3
      @spriteX += SIDE_SIZE_3_X_OFFSETS[@battler.index]
      y_offsets = @is_boss_battle ? SIDE_SIZE_3_Y_OFFSETS_BOSS : SIDE_SIZE_3_Y_OFFSETS_NORMAL
      @spriteY += y_offsets[@battler.index]
    end
  end
  
  alias __initializeOtherGraphics_boss initializeOtherGraphics unless method_defined?(:__initializeOtherGraphics_boss)
  def initializeOtherGraphics(viewport)
    __initializeOtherGraphics_boss(viewport)
    setup_boss_hp_bar(viewport) if enemy_boss_battle?
  end
  
  private
  
  def enemy_boss_battle?
    @battler.index.odd? && boss_battle_active?
  end
  
  def setup_boss_hp_bar(viewport)
    @hpBarBitmap = AnimatedBitmap.new("#{GRAPHICS_PATH}overlay_hp_special")
    @hpBar = Sprite.new(viewport)
    @hpBar.bitmap = @hpBarBitmap.bitmap
    @hpBar.src_rect.height = @hpBarBitmap.height / 3
    @hpBar.z = HP_BAR_Z_BEHIND_POKEMON  # Z más bajo que el Pokémon
    @sprites["hpBar"] = @hpBar
  end

  alias __draw_special_form_icon_boss draw_special_form_icon unless method_defined?(:__draw_special_form_icon_boss)
  def draw_special_form_icon
    return __draw_special_form_icon_boss if !boss_battle_active? || !@battler.opposes?(0)
    
    # Draw the special form icon only for boss battles
    # Mega Evolution/Primal Reversion icon
    nameWidth = self.bitmap.text_size(@battler.name).width
    nameOffset = 0
    nameOffset = nameWidth - 127 if nameWidth > 116
    if @battler.mega?
      pbDrawImagePositions(self.bitmap, [["Graphics/UI/Battle/icon_mega", @spriteBaseX - 30, 8]])
    elsif @battler.primal?
      filename = nil
      if @battler.isSpecies?(:GROUDON)
        filename = "Graphics/UI/Battle/icon_primal_Groudon"
      elsif @battler.isSpecies?(:KYOGRE)
        filename = "Graphics/UI/Battle/icon_primal_Kyogre"
      end
      primalX = (@battler.opposes?) ? 208 : -28   # Foe's/player's
      pbDrawImagePositions(self.bitmap, [[filename, @spriteBaseX - 30, 8]]) if filename
    end
  end

  
  alias __x__boss x= unless method_defined?(:__x__boss)
  public
  def x=(value)
    return __x__boss(value) unless boss_battle_active?
    super
    
    if enemy_boss_battle?
      setup_enemy_boss_x_position(value)
    else
      setup_standard_x_position(value)
    end
    
    setup_common_x_positions(value)
  end
  
  private
  
  def setup_enemy_boss_x_position(value)
    @hpBar.x = value + (@databoxBitmap.width - @hpBarBitmap.width) / 2 if @hpBar
    @hpPercent.x = 206 if @hpPercent
  end
  
  def setup_standard_x_position(value)
    @hpBar.x = value + @spriteBaseX + 102 if @hpBar
  end
  
  def setup_common_x_positions(value)
    @expBar.x = value + @spriteBaseX + 6 if @expBar
    @hpNumbers.x = value + @spriteBaseX + 80 if @hpNumbers
  end

  public
  alias __draw_status_boss draw_status unless method_defined?(:__draw_status_boss)
  def draw_status
    return __draw_status_boss unless boss_battle_active?
    return if @battler.status == :NONE
    
    icon_x_offset = enemy_boss_battle? ? 264 : 0
    status_icon_position = get_status_icon_position
    
    return if status_icon_position < 0
    
    draw_status_icon(icon_x_offset, status_icon_position)
  end
  
  private
  
  def get_status_icon_position
    if @battler.status == :POISON && @battler.statusCount > 0
      GameData::Status.count - 1
    else
      GameData::Status.get(@battler.status).icon_position
    end
  end
  
  def draw_status_icon(icon_x_offset, status_icon_position)
    pbDrawImagePositions(self.bitmap, [
      [
        _INTL("Graphics/UI/Battle/icon_statuses"),
        @spriteBaseX + 24 + icon_x_offset,
        36,
        0,
        status_icon_position * STATUS_ICON_HEIGHT,
        -1,
        STATUS_ICON_HEIGHT
      ]
    ])
  end

  alias __draw_owned_icon_boss draw_owned_icon unless method_defined?(:__draw_owned_icon_boss)
  def draw_owned_icon
    return __draw_owned_icon_boss unless boss_battle_active?
    return if !@battler.owned? || !@battler.opposes?(0)
    
    x_position = @spriteBaseX + 8
    x_position -= 168 if boss_battle_active?
    
    pbDrawImagePositions(self.bitmap, [["Graphics/UI/Battle/icon_own", x_position, 36]])
  end
end

if PluginManager.installed?("Type Icons in Battle")
  class Battle::Scene::PokemonDataBox < Sprite
    include BossBattleConstants
    
    # Additional constants for type icons
    TYPE_ICON_SEPARATION = 2
    TYPE_ICON_PLAYER_X = -40
    TYPE_ICON_ENEMY_X = 210
    
    alias __initializeOtherGraphics_boss initializeOtherGraphics unless method_defined?(:__initializeOtherGraphics_boss)
    def initializeOtherGraphics(viewport)
      __initializeOtherGraphics_boss(viewport)
      return unless boss_battle_active?
      initialize_basic_bitmaps
      initialize_hp_and_exp_sprites(viewport)
      initialize_type_icons(viewport)
      initialize_main_sprite
    end
    
    private
    
    def initialize_basic_bitmaps
      @numbersBitmap = AnimatedBitmap.new("#{GRAPHICS_PATH}icon_numbers")
      
      @hpBarBitmap = if enemy_boss_battle?
                       AnimatedBitmap.new("#{GRAPHICS_PATH}overlay_hp_special")
                     else
                       AnimatedBitmap.new("#{GRAPHICS_PATH}overlay_hp")
                     end
      
      @expBarBitmap = AnimatedBitmap.new("#{GRAPHICS_PATH}overlay_exp")
    end
    
    def initialize_hp_and_exp_sprites(viewport)
      # HP and percentage number sprites
      @hpNumbers = BitmapSprite.new(124, 16, viewport)
      @sprites["hpNumbers"] = @hpNumbers
      @hpPercent = BitmapSprite.new(124, 16, viewport)
      @sprites["hpPercent"] = @hpPercent
      
      # HP bar sprite
      @hpBar = Sprite.new(viewport)
      @hpBar.bitmap = @hpBarBitmap.bitmap
      @hpBar.src_rect.height = @hpBarBitmap.height / 3
      @hpBar.z = HP_BAR_Z_BEHIND_POKEMON if enemy_boss_battle?
      @sprites["hpBar"] = @hpBar
      
      # Experience bar sprite
      @expBar = Sprite.new(viewport)
      @expBar.bitmap = @expBarBitmap.bitmap
      @sprites["expBar"] = @expBar
    end
    
    def initialize_type_icons(viewport)
      @types_x = @battler.opposes?(0) ? TYPE_ICON_ENEMY_X : TYPE_ICON_PLAYER_X
      @types_bitmap = AnimatedBitmap.new("Graphics/UI/Battle/types_ico")
      @types_sprite = Sprite.new(viewport)
      
      # Calculate dimensions once
      @height_per_icon = @types_bitmap.height / GameData::Type.count
      @icon_spacing = 2
      @max_types = 3
      
      # Pre-calculate total height for maximum types to avoid recreation
      total_height = (@height_per_icon + @icon_spacing) * @max_types
      begin
        @types_sprite.bitmap = Bitmap.new(@databoxBitmap.width - @types_x, total_height)
      rescue
        @types_sprite = nil  # Disable type display if bitmap creation fails
      end

      
      # Initialize cache variables
      reset_type_cache if @types_sprite
      
      @sprites["types_sprite"] = @types_sprite if @types_sprite
    end
    
    def setup_type_sprite_dimensions
      height_per_icon = @types_bitmap.height / GameData::Type.count
      total_height = calculate_total_type_height(height_per_icon)
      @types_y = -total_height + 68
      
      @types_sprite.bitmap = Bitmap.new(@databoxBitmap.width - @types_x, total_height)
      @types_sprite.x = @types_x
      @types_sprite.y = @types_y
    end
    
    def calculate_total_type_height(height_per_icon)
      type_count = @battler.types.size
      type_count * height_per_icon + (type_count - 1) * TYPE_ICON_SEPARATION
    end
    
    def initialize_main_sprite
      @contents = Bitmap.new(@databoxBitmap.width, @databoxBitmap.height)
      self.bitmap = @contents
      self.visible = false
      self.z = 150 + ((@battler.index / 2) * 5)
      pbSetSystemFont(self.bitmap)
    end

    public
    alias __x__boss x= unless method_defined?(:__x__boss)
    def x=(value)
      super
      __x__boss(value)
      return unless enemy_boss_battle? && @battler.opposes?(0)
      setup_hp_bar_position(value) 
      setup_type_sprite_position(value)
    end
    
    private
    
    def setup_hp_bar_position(value)
      return unless @hpBar && @databoxBitmap && @hpBarBitmap
      @hpBar.x = value + (@databoxBitmap.width - @hpBarBitmap.width) / 2
      @hpPercent.x = 206 if @hpPercent
    end
    
    def setup_type_sprite_position(value)
      return unless @types_sprite
      @types_sprite.x = value - 10 + @types_x
    end
    
    public
    if method_defined?(:draw_type_icons) || private_method_defined?(:draw_type_icons)
      alias draw_type_icons_boss draw_type_icons unless method_defined?(:draw_type_icons_boss)
    else
      def draw_type_icons_boss; end
    end
    def draw_type_icons
      if boss_battle_active? && @battler.opposes?(0)
        # Draw horizontally for boss enemies
        draw_boss_horizontal_types rescue nil
      else
        # Use original method for all other cases
        draw_type_icons_boss rescue nil
      end
    end
    
    private
    
    def draw_boss_horizontal_types
      return unless @types_sprite
      
      types = get_current_pokemon_state[:types]
      @types_sprite.bitmap.clear
      
      width = @types_bitmap.width
      height = @height_per_icon
      
      types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * height, width, height)
        x_position = i * (width + @icon_spacing) + 223  # Boss-specific horizontal offset
        @types_sprite.bitmap.blt(x_position, 0, @types_bitmap.bitmap, type_rect)
      end
    end

    public
  end
end