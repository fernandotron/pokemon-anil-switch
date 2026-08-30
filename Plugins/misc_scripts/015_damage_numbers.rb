#-------------------------------------------------------------------------------
# Muestra y anima un número de daño o curación sobre el Pokémon
#-------------------------------------------------------------------------------
class PokemonSystem 
  alias_method :damage_numbers_initialize, :initialize unless method_defined?(:damage_numbers_initialize)

  def initialize
    damage_numbers_initialize
    @show_damage_numbers = 1 # 0 = on, 1 = off (default: OFF)
  end

  def show_damage_numbers
    # Default to OFF (1) only if never been set (nil)
    # If it was explicitly set to 0 or 1, keep that value
    @show_damage_numbers = 1 if @show_damage_numbers.nil?
    return @show_damage_numbers
  end

  def show_damage_numbers=(value)
    @show_damage_numbers = value
  end

  def show_damage_numbers?
    # Default to OFF (1) only if never been set
    @show_damage_numbers = 1 if @show_damage_numbers.nil?
    return @show_damage_numbers == 0
  end
end

MenuHandlers.add(:options_menu, :damage_numbers, {
  "name"        => _INTL("Mostrar Nº de daño"),
  "order"       => 90,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Cuando un Pokémon recibe daño, muestra el número de daño que ha recibido."),
  "get_proc"    => proc { 
    next $PokemonSystem.show_damage_numbers
  },
  "set_proc"    => proc { |value, _scene| 
    $PokemonSystem.show_damage_numbers = value 
  }
})

#-------------------------------------------------------------------------------
# Non-blocking damage number sprite that animates independently
#-------------------------------------------------------------------------------
class DamageNumberSprite
  def initialize(viewport, x0, y0, text, base_color, crit_color, border_color, 
                 initial_zoom, is_critical, gains_hp, duration_frames)
    @x0 = x0
    @y0 = y0
    @text = text
    @base_color = base_color
    @crit_color = crit_color
    @border_color = border_color
    @initial_zoom = initial_zoom
    @is_critical = is_critical
    @gains_hp = gains_hp
    @duration_frames = duration_frames
    @current_frame = 0
    @disposed = false
    
    # Animation parameters
    @flash_interval = 8
    @shake_amount = 6
    @shake_osc = 8
    
    # Measure text
    temp_bmp = Bitmap.new(1, 1)
    pbSetSystemFont(temp_bmp)
    temp_bmp.font.size = 24
    temp_bmp.font.bold = true
    @tw = temp_bmp.text_size(text).width
    @th = temp_bmp.text_size(text).height
    temp_bmp.dispose
    
    # Create sprite
    margin = 6
    @bmpw = @tw + margin * 2
    @bmph = @th + margin * 2
    @margin = margin
    
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99_999
    @sprite = BitmapSprite.new(@bmpw, @bmph, @viewport)
    @sprite.z = @viewport.z + 1
    @sprite.ox = @bmpw / 2
    @sprite.oy = @bmph / 2
    @sprite.x = x0
    @sprite.y = y0
    
    @bmp = @sprite.bitmap
    pbSetSystemFont(@bmp)
    @bmp.font.size = 24
    @bmp.font.bold = true
    
    # Initial draw
    pbDrawOutlineText(@bmp, @margin, @margin, @tw, @th, @text, @base_color, @border_color, 1)
  end
  
  def disposed?
    @disposed
  end
  
  def dispose
    return if @disposed
    @sprite.dispose if @sprite && !@sprite.disposed?
    @viewport.dispose if @viewport && !@viewport.disposed?
    @disposed = true
  end
  
  def update
    return if @disposed
    return if @current_frame >= @duration_frames
    
    t = @current_frame.to_f / @duration_frames
    
    # Easing for rising (ease-out-quad)
    ease = 1 - (1 - t)**2
    @sprite.y = (@y0 - 16 * ease).to_i
    @sprite.opacity = (255 * (1 - t)).to_i
    
    # Descending zoom
    z = @initial_zoom - 0.2 * t
    @sprite.zoom_x = @sprite.zoom_y = z
    
    # Critical shake
    if @is_critical && !@gains_hp
      offset = @shake_amount * Math.sin(t * 2 * Math::PI * @shake_osc)
      @sprite.x = (@x0 + offset).to_i
      col = ((@current_frame / @flash_interval).even?) ? @crit_color : @base_color
      @bmp.clear
      pbDrawOutlineText(@bmp, @margin, @margin, @tw, @th, @text, col, @border_color, 1)
    end
    
    @current_frame += 1
    
    # Auto-dispose when animation is complete
    dispose if @current_frame >= @duration_frames
  end
end



class Battle::Scene
  PLAYERBATTLERD1_X = Battle::Scene::PLAYER_BASE_X - 48
  PLAYERBATTLERD1_Y = Battle::Scene::PLAYER_BASE_Y
  PLAYERBATTLER_X   = Battle::Scene::PLAYER_BASE_X
  PLAYERBATTLER_Y   = Battle::Scene::PLAYER_BASE_Y
  FOEBATTLERD1_X    = Battle::Scene::FOE_BASE_X + 48
  FOEBATTLERD1_Y    = Battle::Scene::FOE_BASE_Y
  FOEBATTLER_X      = Battle::Scene::FOE_BASE_X
  FOEBATTLER_Y      = Battle::Scene::FOE_BASE_Y
  PLAYERBATTLERD2_X = Battle::Scene::PLAYER_BASE_X + 32
  PLAYERBATTLERD2_Y = Battle::Scene::PLAYER_BASE_Y + 16
  FOEBATTLERD2_X    = Battle::Scene::FOE_BASE_X - 32
  FOEBATTLERD2_Y    = Battle::Scene::FOE_BASE_Y - 16

  # Initialize damage number sprites array
  alias dmgnum_pbInitSprites pbInitSprites
  def pbInitSprites
    dmgnum_pbInitSprites
    @damage_number_sprites = []
  end

  # Update damage number sprites each frame
  alias dmgnum_pbGraphicsUpdate pbGraphicsUpdate
  def pbGraphicsUpdate
    dmgnum_pbGraphicsUpdate
    update_damage_number_sprites
  end

  def update_damage_number_sprites
    return unless @damage_number_sprites
    @damage_number_sprites.each(&:update)
    @damage_number_sprites.reject!(&:disposed?)
  end

  def dispose_damage_number_sprites
    return unless @damage_number_sprites
    @damage_number_sprites.each { |s| s.dispose unless s.disposed? }
    @damage_number_sprites.clear
  end

  # Clean up damage sprites when battle ends
  alias dmgnum_pbDisposeSprites pbDisposeSprites
  def pbDisposeSprites
    dispose_damage_number_sprites
    dmgnum_pbDisposeSprites
  end

  # Hook into pbHitAndHPLossAnimation instead of pbHPChanged for battle damage
  alias dmgnum_pbHitAndHPLossAnimation pbHitAndHPLossAnimation
  def pbHitAndHPLossAnimation(targets)
    # Always call original for sound effects and normal behavior
    dmgnum_pbHitAndHPLossAnimation(targets)
    
    # Add damage numbers on top if enabled
    if $PokemonSystem.show_damage_numbers?
      targets.each do |t|
        battler = t[0]
        oldHP = t[1]
        effectiveness = t[2]
        doublebattle = @battle.sideSizes == [2,2]
        totalDamage = battler.damageState.totalHPLost || 0
        
        # Create non-blocking damage number sprite
        pbCreateDamageNumberSprite(battler, oldHP, effectiveness, doublebattle, totalDamage)
      end
    end
  end

  # Keep the pbHPChanged override for non-battle HP changes (like healing items)
  alias dmgnum_pbHPChanged pbHPChanged
  def pbHPChanged(battler, oldHP, showAnim = false)
    # Always call original for normal behavior
    dmgnum_pbHPChanged(battler, oldHP, showAnim)
    
    # Add damage numbers on top if enabled
    if $PokemonSystem.show_damage_numbers? && battler.hp != oldHP
      effectiveness = 0
      if battler.damageState && Effectiveness.super_effective?(battler.damageState.typeMod)
        effectiveness = 2
      elsif battler.damageState && Effectiveness.not_very_effective?(battler.damageState.typeMod)
        effectiveness = 1
      end
      doublebattle = @battle.sideSizes == [2,2]
      totalDamage = battler.damageState ? (battler.damageState.totalHPLost || 0) : 0
      pbCreateDamageNumberSprite(battler, oldHP, effectiveness, doublebattle, totalDamage)
    end
  end

  # Creates a non-blocking damage number sprite that animates independently
  def pbCreateDamageNumberSprite(pkmn, oldhp, effectiveness = 0, doublebattle = false, totalDamage = 0)
    return unless $PokemonSystem.show_damage_numbers?
    
    @damage_number_sprites ||= []
    
    # Calculate amount and sign
    # Always use actual HP difference as the base
    actual_change = pkmn.hp - oldhp
    gainsHp = (actual_change > 0)
    
    # Only use totalDamage if it matches the actual HP change (meaning it's from the current damage event)
    # Otherwise use the actual HP difference (for weather, poison, etc.)
    if totalDamage != 0 && totalDamage == actual_change.abs
      amt = totalDamage
    else
      amt = actual_change.abs
    end
    
    text = sprintf("%s%d", (gainsHp ? "+" : "-"), amt)

    # Duration of 1.5 seconds
    duration_frames = (1.5 * Graphics.frame_rate).to_i

    # Battler base coordinates
    if doublebattle
      cx, cy = case pkmn.index
        when 0 then [PLAYERBATTLERD1_X, PLAYERBATTLERD1_Y]
        when 1 then [FOEBATTLERD1_X, FOEBATTLERD1_Y]
        when 2 then [PLAYERBATTLERD2_X, PLAYERBATTLERD2_Y]
        when 3 then [FOEBATTLERD2_X, FOEBATTLERD2_Y]
      end
    else
      if pkmn.index == 0
        cx = PLAYERBATTLER_X
        cy = PLAYERBATTLER_Y
      else
        cx = FOEBATTLER_X
        cy = FOEBATTLER_Y
      end
    end

    # Vertical adjustment to place above head
    poke_s   = @sprites["pokemon_#{pkmn.index}"]
    sprite_h = poke_s.bitmap.height
    x0       = cx
    y0       = cy - sprite_h/2 - sprite_h/10
    y0       = 40 if y0 < 40

    # Color selection based on effectiveness/healing
    base_color = case effectiveness
                when 1 then Color.new( 22,160,133)  # Not very effective
                when 2 then Color.new(231, 76, 60)  # Super effective
                else        Color.new(212,176, 23)  # Normal
                end
    base_color   = Color.new(0, 204, 35) if gainsHp # Healing
    
    crit_color   = case effectiveness
                when 1 then Color.new(181,247,234)  # Not very effective
                when 2 then Color.new(255,200,195)  # Super effective
                else        Color.new(255,230,119)  # Normal
                end           
    border_color = Color.new(255,255,255)
    
    # Calculate initial_zoom based on damage ratio and sprite zoom
    ratio = amt.to_f / pkmn.totalhp
    ratio = 0.0 if ratio < 0.0
    ratio = 1.0 if ratio > 1.0
    min_z, max_z = 1.4, 2
    base_zoom    = min_z + ratio*(max_z-min_z)
    depth_factor = poke_s.respond_to?(:zoom_x) ? poke_s.zoom_x : 1.0
    initial_zoom = base_zoom * depth_factor

    # Is it critical?
    is_critical = pkmn.damageState ? pkmn.damageState.critical : false

    # Create the non-blocking damage number sprite
    damage_sprite = DamageNumberSprite.new(
      nil, x0, y0, text, base_color, crit_color, border_color,
      initial_zoom, is_critical, gainsHp, duration_frames
    )
    @damage_number_sprites << damage_sprite
  end
end