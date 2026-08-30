class Battle::Scene::PokemonDataBox

  alias __types__initializeOtherGraphics initializeOtherGraphics unless method_defined?(:__types__initializeOtherGraphics)  
  def initializeOtherGraphics(viewport)
    # Constants for positioning and spacing
    @types_x = (@battler.opposes?(0)) ? 200 : -40
    @types_bitmap = AnimatedBitmap.new("Graphics/UI/Battle/types_ico")
    @types_sprite = Sprite.new(viewport)
    
    # Calculate dimensions once
    @height_per_icon = @types_bitmap.height / GameData::Type.count
    @icon_spacing = 2
    @max_types = 3
    
    # Pre-calculate total height for maximum types to avoid recreation
    total_height = (@height_per_icon + @icon_spacing) * @max_types
    
    # Catch bitmap creation error and disable type display if it fails
    begin
      @types_sprite.bitmap = Bitmap.new(@databoxBitmap.width - @types_x, total_height)
    rescue
      @types_sprite = nil  # Disable type display if bitmap creation fails
    end
    
    # Initialize cache variables
    reset_type_cache if @types_sprite
    
    @sprites["types_sprite"] = @types_sprite if @types_sprite
    
    # Call original method
    __types__initializeOtherGraphics(viewport)
  end
  
  alias __types__dispose dispose unless method_defined?(:__types__dispose)  
  def dispose(*args)
    @types_bitmap.dispose if @types_bitmap && !@types_bitmap.disposed?
    __types__dispose(*args)
  end

  alias __types__set_x x= unless method_defined?(:__types__set_x)
  def x=(value)
    __types__set_x(value)
    if @types_sprite && !@types_sprite.disposed?
      extra_x = (@battler.opposes?(0)) ? 10 : 0
      nameWidth = self.bitmap.text_size(@battler.name).width
      if nameWidth > 116
        extra_x += @battler.opposes?(0) ? 14 : 0
      else
        extra_x += @battler.opposes?(0) ? 2 : 0
      end
      @types_sprite.x = value + 10 + extra_x + @types_x
    end
  end

  alias __types__set_y y= unless method_defined?(:__types__set_y)
  def y=(value)
    __types__set_y(value)
    if @types_sprite && !@types_sprite.disposed?
      extra_y = (@battler.opposes?(0)) ? 5 : 5
      @types_sprite.y = value + extra_y
    end
  end

  alias __types__set_z z= unless method_defined?(:__types__set_z)
  def z=(value)
    __types__set_z(value)
    if @types_sprite && !@types_sprite.disposed?
      @types_sprite.z = value + 1
    end
  end

  alias __databox__refresh refresh unless method_defined?(:__databox__refresh)
  def refresh
    return if !@battler.pokemon
    # Verificar que todos los bitmaps necesarios existen antes de continuar
    return if !self.bitmap || self.bitmap.disposed?
    return if !@types_sprite || @types_sprite.disposed?
    return if !@types_sprite.bitmap || @types_sprite.bitmap.disposed?
    
    __databox__refresh
    update_type_icons_if_needed
  end

  private
  
  def reset_type_cache
    @cached_pokemon_id = nil
    @cached_types = nil
    @cached_illusion_pokemon_id = nil
  end
  
  def get_current_pokemon_state
    illusion_pokemon = @battler.effects[PBEffects::Illusion]
    hash = {
      pokemon_id: @battler.pokemon.personalID,
      types: illusion_pokemon ? illusion_pokemon.types : @battler.pbTypes(true),
      illusion_id: illusion_pokemon ? illusion_pokemon.personalID : nil
    }
    if illusion_pokemon
      if @battler && @battler.effects[PBEffects::ExtraType]
        extra_type = @battler.effects[PBEffects::ExtraType]
        hash[:types] << extra_type if extra_type
      end
      if @battler.effects[PBEffects::BurnUp] && hash[:types].include?(:FIRE)
        hash[:types].delete(:FIRE)
      end
      if @battler.effects[PBEffects::DoubleShock] && hash[:types].include?(:ELECTRIC)
        hash[:types].delete(:ELECTRIC)
      end
      if @battler.effects[PBEffects::Roost]
        hash[:types].delete(:FLYING)
        hash[:types] << :NORMAL if hash[:types].empty?
      end
    end

    if hash[:types].empty?
      hash[:types] = [:QMARKS]
    end

    hash

  end
  
  def cache_changed?(current_state)
    # Check if the basic Pokemon or types changed
    pokemon_changed = @cached_pokemon_id != current_state[:pokemon_id]
    types_changed = @cached_types != current_state[:types]
    
    # Check if illusion state changed (started, ended, or switched to different Pokemon)
    illusion_changed = @cached_illusion_pokemon_id != current_state[:illusion_id]
    
    # Explicitly check if illusion has ended (was active, now inactive)
    illusion_ended = @cached_illusion_pokemon_id && current_state[:illusion_id].nil?
    
    pokemon_changed || types_changed || illusion_changed || illusion_ended
  end
  
  def update_cache(current_state)
    @cached_pokemon_id = current_state[:pokemon_id]
    @cached_types = current_state[:types].dup
    @cached_illusion_pokemon_id = current_state[:illusion_id]
  end

  def update_type_icons_if_needed
    return if !@battler.pokemon
    return if !@types_sprite || @types_sprite.disposed?
    return if !@types_sprite.bitmap || @types_sprite.bitmap.disposed?
    
    current_state = get_current_pokemon_state
    
    if cache_changed?(current_state)
      draw_type_icons
      update_cache(current_state)
    end
  end

  def draw_type_icons
    return if !@types_sprite || @types_sprite.disposed?
    return if !@types_sprite.bitmap || @types_sprite.bitmap.disposed?
    
    types = get_current_pokemon_state[:types]
    types.uniq!
    @types_sprite.bitmap.clear
    
    # Calculate actual height needed for current types
    actual_height = types.size * @height_per_icon + (types.size - 1) * @icon_spacing
    y_offset = -actual_height + 68
    
    # Update sprite position
    @types_sprite.x = @types_x
    @types_sprite.y = y_offset
    
    nameWidth = self.bitmap.text_size(@battler.name).width
    # x_offset = nameWidth > 116 ? 9 : 0
    if nameWidth <= 116
      x_offset = @battler.opposes?(0) ? 0 : 40
    else
      x_offset = @battler.opposes?(0) ? 0 : 40
    end

    if @battler.level >= 100 && @battler.opposes?(0)
      x_offset += 8
    end
    
    # Draw each type icon
    icon_width = @types_bitmap.width
    types.each_with_index do |type, index|
      type_data = GameData::Type.get(type)
      
      # Calculate source rectangle for the type icon
      source_rect = Rect.new(
        0, 
        type_data.icon_position * @height_per_icon, 
        icon_width, 
        @height_per_icon
      )
      
      # Calculate destination position
      dest_y = index * (@height_per_icon + @icon_spacing) + 5
      
      # Draw the icon
      @types_sprite.bitmap.blt(0 + x_offset, dest_y, @types_bitmap.bitmap, source_rect)
    end
  end

  public
  
  # Force refresh for special cases
  def force_type_icons_refresh
    return if !@types_sprite || @types_sprite.disposed?
    return if !@types_sprite.bitmap || @types_sprite.bitmap.disposed?
    
    reset_type_cache
    update_type_icons_if_needed
  end
  
end