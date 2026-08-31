#===============================================================================
# Main body to handle the the construction and animation of title screen
#===============================================================================
# Main title screen script
# handles the logic of constructing and animating the title screen visuals
class ModularTitleScreen
  # class constructor
  # additively adds new visual elements based on the presence of valid symbol
  # entries in the ModularTitle::MODIFIERS array

  # Desplazamientos de posición para sprites en forma Mega
  MEGA_POSITION_OFFSETS = {
    "poke_sprite"  => [0, -4],  # Mega Venusaur
    "poke_sprite3" => [0, 20],  # Mega Pikachu
    "poke_sprite2" => [-20, 10],  # Mega Charizard
    "poke_sprite4" => [-8, 0],  # Mega Blastoise
  }

  def random?
    @random
  end


  def initialize
    # defines viewport
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    # defines sprite hash
    @sprites = {}
    @intro = nil
    @currentFrame = 0
    @mods = ModularTitle::MODIFIERS
    @mods = ["background5", "logo:sparkle", "overlay:static004", "effect1"] if defined?(firstApr?) && firstApr?
    bg = "BG0"
    backdrop = "nil"
    bg_selected = false
    
    # Mega evolution animation variables
    @mega_timer = 0
    @mega_interval = 60 * 6 # 6 seconds at 60 FPS
    @mega_animation_frame = 0
    @mega_animation_duration = 60 * 2 # 2 seconds animation
    @animating_sprite = nil
    @mega_pokemon_sprites = ["poke_sprite", "poke_sprite2", "poke_sprite3", "poke_sprite4"]
    @original_pokemon = {}
    @mega_pokemon = {}
    @last_evolved_sprite = nil # Track the last sprite that evolved
    
    # Full loop cycle tracking
    @evolved_sprites_in_cycle = [] # Track which sprites have evolved in current cycle
    @current_cycle_complete = false # Flag to check if current cycle is complete
    
    # Revert animation variables
    @revert_timer = 0
    @revert_animation_frame = 0
    @revert_animation_duration = 60 * 1 # seconds animation
    @reverting_sprite = nil
    
    #---------------------------------------------------------------------------
    # setting up Pokemon Sprites
    @random = RandomizedChallenge.enabled? if defined?(RandomizedChallenge) 
    RandomizedChallenge.pause_random_species if random? && defined?(RandomizedChallenge)

    pokemon = Pokemon.new(:VENUSAUR,1)
    @sprites["poke_sprite"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite"]&.setPokemonBitmap(pokemon)
    @sprites["poke_sprite"]&.setOffset(PictureOrigin::BOTTOM)
    @sprites["poke_sprite"]&.z = 100
    @sprites["poke_sprite"]&.x = 90
    @sprites["poke_sprite"]&.y = @viewport.rect.height - 80 + 30 + 10
    @sprites["poke_sprite"]&.zoom_x = 0.97
    @sprites["poke_sprite"]&.zoom_y = 0.97
    @original_pokemon["poke_sprite"] = pokemon
    
    # Randomly choose between Mega Venusaur X and Y
    mega_venusaur_form = rand(2) == 0 ? :VENUSAUR_1 : :VENUSAUR_2
    mega_pokemon = Pokemon.new(mega_venusaur_form,1)
    mega_pokemon.make_shiny if pokemon.shiny?
    @mega_pokemon["poke_sprite"] = mega_pokemon # Mega Venusaur
    
    # Add shadow sprite
    @sprites["poke_sprite_shadow"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite_shadow"].setShadowBitmap(@sprites["poke_sprite"])
    @sprites["poke_sprite_shadow"].z = 99
    @sprites["poke_sprite_shadow"].x = @sprites["poke_sprite"].x
    @sprites["poke_sprite_shadow"].y = @sprites["poke_sprite"].y
    @sprites["poke_sprite_shadow"].zoom_x = @sprites["poke_sprite"].zoom_x
    @sprites["poke_sprite_shadow"].zoom_y = @sprites["poke_sprite"].zoom_y
    @sprites["poke_sprite_shadow"].opacity = 100
    @sprites["poke_sprite_shadow"].y -= 40
    
    pokemon = Pokemon.new(:CHARIZARD,1)
    @sprites["poke_sprite2"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite2"].setPokemonBitmap(pokemon)
    @sprites["poke_sprite2"].setOffset(PictureOrigin::BOTTOM)
    @sprites["poke_sprite2"].z = 101
    @sprites["poke_sprite2"].x = @viewport.rect.width/2 + 40
    @sprites["poke_sprite2"].y = @viewport.rect.height - 90 + 10
    @sprites["poke_sprite2"].zoom_x = 0.97
    @sprites["poke_sprite2"].zoom_y = 0.97
    @original_pokemon["poke_sprite2"] = pokemon

    # Randomly choose between Mega Charizard X and Y
    mega_charizard_form = rand(2) == 0 ? :CHARIZARD_1 : :CHARIZARD_2
    mega_pokemon = Pokemon.new(mega_charizard_form,1)
    mega_pokemon.make_shiny if pokemon.shiny?
    @mega_pokemon["poke_sprite2"] = mega_pokemon
    
    # # Add shadow sprite
    @sprites["poke_sprite2_shadow"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite2_shadow"].setShadowBitmap(@sprites["poke_sprite2"])
    @sprites["poke_sprite2_shadow"].z = 100
    @sprites["poke_sprite2_shadow"].x = @sprites["poke_sprite2"].x
    @sprites["poke_sprite2_shadow"].y = @sprites["poke_sprite2"].y
    @sprites["poke_sprite2_shadow"].zoom_x = @sprites["poke_sprite2"].zoom_x
    @sprites["poke_sprite2_shadow"].zoom_y = @sprites["poke_sprite2"].zoom_y
    @sprites["poke_sprite2_shadow"].opacity = 100
    @sprites["poke_sprite2_shadow"].y -= 28

    @sprites["poke_sprite3"] = PokemonSprite.new(@viewport)
    pokemon = Pokemon.new(:PIKACHU_16,1)
    @sprites["poke_sprite3"].setPokemonBitmap(pokemon)
    @sprites["poke_sprite3"].setOffset(PictureOrigin::BOTTOM)
    @sprites["poke_sprite3"].z = 105
    @sprites["poke_sprite3"].x = @viewport.rect.width/2 + 10
    @sprites["poke_sprite3"].y = @viewport.rect.height - 20
    @sprites["poke_sprite3"].zoom_x = 0.97
    @sprites["poke_sprite3"].zoom_y = 0.97
    @original_pokemon["poke_sprite3"] = pokemon
    mega_pokemon = Pokemon.new(:PIKACHU_17,1)
    mega_pokemon.make_shiny if pokemon.shiny?
    @mega_pokemon["poke_sprite3"] = mega_pokemon # Mega Pikachu
   
    # # Add shadow sprite
    @sprites["poke_sprite3_shadow"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite3_shadow"].setShadowBitmap(@sprites["poke_sprite3"])
    @sprites["poke_sprite3_shadow"].z = 104
    @sprites["poke_sprite3_shadow"].x = @sprites["poke_sprite3"].x
    @sprites["poke_sprite3_shadow"].y = @sprites["poke_sprite3"].y
    @sprites["poke_sprite3_shadow"].zoom_x = @sprites["poke_sprite3"].zoom_x
    @sprites["poke_sprite3_shadow"].zoom_y = @sprites["poke_sprite3"].zoom_y
    @sprites["poke_sprite3_shadow"].opacity = 100
    @sprites["poke_sprite3_shadow"].y -= 20

    pokemon = Pokemon.new(:BLASTOISE,1)
    @sprites["poke_sprite4"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite4"].setPokemonBitmap(pokemon)
    @sprites["poke_sprite4"].setOffset(PictureOrigin::BOTTOM)
    @sprites["poke_sprite4"].z = 100
    @sprites["poke_sprite4"].x = @viewport.rect.width - 70
    @sprites["poke_sprite4"].y = @viewport.rect.height - 100 + 40 + 10
    @sprites["poke_sprite4"].zoom_x = 0.97
    @sprites["poke_sprite4"].zoom_y = 0.97
    @original_pokemon["poke_sprite4"] = pokemon

    # Randomly choose between Mega Blastoise X and Y
    mega_blastoise_form = rand(2) == 0 ? :BLASTOISE_1 : :BLASTOISE_2
    mega_pokemon = Pokemon.new(mega_blastoise_form,1)
    mega_pokemon.make_shiny if pokemon.shiny?
    @mega_pokemon["poke_sprite4"] = mega_pokemon # Mega Blastoise
   
    # Add shadow sprite
    @sprites["poke_sprite4_shadow"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite4_shadow"].setShadowBitmap(@sprites["poke_sprite4"])
    @sprites["poke_sprite4_shadow"].z = 99
    @sprites["poke_sprite4_shadow"].x = @sprites["poke_sprite4"].x
    @sprites["poke_sprite4_shadow"].y = @sprites["poke_sprite4"].y
    @sprites["poke_sprite4_shadow"].zoom_x = @sprites["poke_sprite4"].zoom_x
    @sprites["poke_sprite4_shadow"].zoom_y = @sprites["poke_sprite4"].zoom_y
    @sprites["poke_sprite4_shadow"].opacity = 100
    @sprites["poke_sprite4_shadow"].y -= 30

    pokemon = Pokemon.new(:MEW,1)
    @sprites["poke_sprite5"] = PokemonSprite.new(@viewport)
    @sprites["poke_sprite5"].setPokemonBitmap(pokemon)
    @sprites["poke_sprite5"].setOffset(PictureOrigin::TOP)
    @sprites["poke_sprite5"].z = 101
    @sprites["poke_sprite5"].x = @viewport.rect.width - 40
    @sprites["poke_sprite5"].y = 10
    @sprites["poke_sprite5"].zoom_x = 0.3
    @sprites["poke_sprite5"].zoom_y = 0.3
    @sprites["poke_sprite5"].opacity = 70

    # Creamos ahora los sprites de los entrenadores, leyéndolos de Graphics/Trainers
    @sprites["trainer1"] = Sprite.new(@viewport)
    @sprites["trainer1"].bitmap = pbBitmap("Graphics/Trainers/ROJO1")
    @sprites["trainer1"].x = @viewport.rect.width/2 - 100 - 60
    @sprites["trainer1"].y = @viewport.rect.height - @sprites["trainer1"].bitmap.height - 40
    @sprites["trainer1"].z = 102

    @sprites["trainer1_shw"] = Sprite.new(@viewport)
    @sprites["trainer1_shw"].bitmap = @sprites["trainer1"].bitmap.clone
    @sprites["trainer1_shw"].zoom_y = 0.3
    @sprites["trainer1_shw"].x = @sprites["trainer1"].x + 6
    @sprites["trainer1_shw"].y = @sprites["trainer1"].y + 6
    @sprites["trainer1_shw"].y += @sprites["trainer1_shw"].bitmap.height * (1 - @sprites["trainer1_shw"].zoom_y) - 10
    @sprites["trainer1_shw"].z = 99
    @sprites["trainer1_shw"].color = Color.black
    @sprites["trainer1_shw"].opacity = 100

    @sprites["trainer2"] = Sprite.new(@viewport)
    @sprites["trainer2"].bitmap = pbBitmap("Graphics/Trainers/HOJA1")
    @sprites["trainer2"].x = @viewport.rect.width/2 - 100 + 110
    @sprites["trainer2"].y = @viewport.rect.height - @sprites["trainer2"].bitmap.height - 40
    @sprites["trainer2"].z = 102

    @sprites["trainer2_shw"] = Sprite.new(@viewport)
    @sprites["trainer2_shw"].bitmap = @sprites["trainer2"].bitmap.clone
    @sprites["trainer2_shw"].zoom_y = 0.3
    @sprites["trainer2_shw"].x = @sprites["trainer2"].x + 6
    @sprites["trainer2_shw"].y = @sprites["trainer2"].y + 6
    @sprites["trainer2_shw"].y += @sprites["trainer2_shw"].bitmap.height * (1 - @sprites["trainer2_shw"].zoom_y) - 10
    @sprites["trainer2_shw"].z = 99
    @sprites["trainer2_shw"].color = Color.black
    @sprites["trainer2_shw"].opacity = 100

    #---------------------------------------------------------------------------

    i = 0; o = 0; m = 0
    for mod in @mods
      arg = mod.to_s.upcase
      x = nil; y = nil; z = nil; zoom = nil; file = nil; speed = nil
      #-------------------------------------------------------------------------
      # setting up background
      # uses first available background element
      # if no background modifier has been defined, defaults to stock Essentials
      if arg.include?("BACKGROUND:") # loads specific BG graphic
        next if bg_selected
        cmd = arg.split("_").compact
        backdrop = cmd[0].gsub("BACKGROUND:","")
        bg_selected = true
      elsif arg.include?("BACKGROUND") # loads modifier as object
        next if bg_selected
        cmd = arg.split("_").compact
        s = "BG" + cmd[0].gsub("BACKGROUND","")
        if Object.const_defined?("MTS_Element_#{s}")
          bg = s
          bg_selected = true
        end
      #-------------------------------------------------------------------------
      # setting up intro animation
      # uses first available element
      elsif arg.include?("INTRO:")
        next if !@intro.nil?
        cmd = arg.split("_").compact
        @intro = cmd[0].gsub("INTRO:","")
      #-------------------------------------------------------------------------
      # setting up background overlay
      # multiple overlays can be added
      # order in which they are defined matters for their Z index
      elsif arg.include?("OVERLAY:") # loads specific overlay graphic
        cmd = arg.split("_").compact
        file = cmd[0].gsub("OVERLAY:","")
        # applies positioning modifiers
        for j in 1...cmd.length
          next if cmd.length < 2
          if cmd[j].include?("Z")
            z = cmd[j].gsub("Z","").to_i
          end
        end
        @sprites["ol#{o}"] = MTS_Element_OLX.new(@viewport,file,z)
        o += 1
      elsif arg.include?("OVERLAY")
        cmd1 = mod.split("_").compact
        cmd2 = cmd1[0].split(":").compact
        s = "OL" + cmd2[0].upcase.gsub("OVERLAY","")
        f = cmd2.length > 1 ? cmd2[1] : nil
        # applies positioning modifiers
        for j in 1...cmd1.length
          next if cmd1.length < 2
          if cmd1[j].upcase.include?("Z")
            z = cmd1[j].upcase.gsub("Z","").to_i
          elsif cmd1[j].upcase.include?("S")
            speed = cmd1[j].upcase.gsub("S","").to_i
          end
        end
        if Object.const_defined?("MTS_Element_#{s}")
          klass = Object.const_get("MTS_Element_#{s}")
          @sprites["ol#{o}"] = klass.new(@viewport,f,z,speed)
          o += 1
        end
      #---------------------------------------------------------------------------
      # setting up additional particle effects
      # multiple overlays can be added
      # order in which they are defined matters for their Z index
      elsif arg.include?("EFFECT")
        cmd = arg.split("_").compact
        s = "FX" + cmd[0].gsub("EFFECT","")
        # applies positioning modifiers
        for j in 1...cmd.length
          next if cmd.length < 2
          if cmd[j].include?("X")
            x = cmd[j].gsub("X","").to_i
          elsif cmd[j].include?("Y")
            y = cmd[j].gsub("Y","").to_i
          elsif cmd[j].include?("Z")
            z = cmd[j].gsub("Z","").to_i
          end
        end
        # loads the sprite class
        if Object.const_defined?("MTS_Element_#{s}")
          klass = Object.const_get("MTS_Element_#{s}")
          @sprites["fx#{i}"] = klass.new(@viewport,x,y,z)
          i += 1
        end
      #---------------------------------------------------------------------------
      # setting up additional particle effects
      # multiple overlays can be added
      # order in which they are defined matters for their Z index
      elsif arg.include?("MISC")
        cmd = mod.split("_").compact
        mfx = cmd[0].split(":").compact
        s = "MX" + mfx[0].upcase.gsub("MISC","")
        file = mfx[1] if mfx.length > 1
        # applies positioning modifiers
        for j in 1...cmd.length
          next if cmd.length < 2
          if cmd[j].upcase.include?("X")
            x = cmd[j].upcase.gsub("X","").to_i
          elsif cmd[j].upcase.include?("Y")
            y = cmd[j].upcase.gsub("Y","").to_i
          elsif cmd[j].upcase.include?("Z")
            z = cmd[j].upcase.gsub("Z","").to_i
          elsif cmd[j].upcase.include?("S")
            zoom = cmd[j].upcase.gsub("S","").to_f
          end
        end
        # loads the sprite class
        if Object.const_defined?("MTS_Element_#{s}")
          klass = Object.const_get("MTS_Element_#{s}")
          @sprites["mx#{m}"] = klass.new(@viewport,x,y,z,zoom,file)
          m += 1
        end
      end
    end
    bg_klass = Object.const_defined?("MTS_Element_#{bg}") ? Object.const_get("MTS_Element_#{bg}") : MTS_Element_BG0
    @sprites["bg"] = bg_klass.new(@viewport, backdrop == "nil" ? nil : backdrop)

    #---------------------------------------------------------------------------
    # setting up game logo
    @sprites["logo"] = MTS_Element_Logo.new(@viewport)
    @sprites["logo"].position
    #---------------------------------------------------------------------------
    # setting up gstart splash text
    @sprites["start"] = Sprite.new(@viewport)
    @sprites["start"].bitmap = pbBitmap("Graphics/Titles/start")
    @sprites["start"].center!
    @sprites["start"].x = @viewport.rect.width/2
    @sprites["start"].x = ModularTitle::START_POS[0] if ModularTitle::START_POS[0].is_a?(Numeric)
    @sprites["start"].y = @viewport.rect.height*0.85
    @sprites["start"].y = ModularTitle::START_POS[1] if ModularTitle::START_POS[1].is_a?(Numeric)
    @sprites["start"].z = 999
    @sprites["start"].visible = false

    @fade = 8

    # Actualizar sombras después de que los sprites han sido correctamente renderizados
    @sprites.each do |key, sprite|
      next unless key.include?("_shadow")
      base_key = key.gsub("_shadow", "")
      next unless @sprites[base_key]
      sprite.setShadowBitmap(@sprites[base_key])
    end
  end
  
  # Method to start mega evolution animation
  def start_mega_evolution
    return if @animating_sprite || @reverting_sprite # Don't start if already animating
    
    # Check if all sprites have evolved in current cycle
    if @evolved_sprites_in_cycle.length >= @mega_pokemon_sprites.length
      # Reset cycle - all sprites have evolved once
      @evolved_sprites_in_cycle.clear
      @current_cycle_complete = false
      @last_evolved_sprite = nil
    end
    
    # Create list of available sprites (those not yet evolved in current cycle)
    available_sprites = @mega_pokemon_sprites - @evolved_sprites_in_cycle
    
    # If no sprites available (shouldn't happen with above logic, but safety check)
    if available_sprites.empty?
      @evolved_sprites_in_cycle.clear
      available_sprites = @mega_pokemon_sprites.dup
    end
    
    # Select random sprite from the available ones
    sprite_key = available_sprites.sample
    @last_evolved_sprite = sprite_key
    
    # Add this sprite to the evolved list for current cycle
    @evolved_sprites_in_cycle << sprite_key

    current_shiny = @original_pokemon[sprite_key].shiny?

    case sprite_key
    when "poke_sprite"
      mega_venusaur_form = rand(2) == 0 ? :VENUSAUR_1 : :VENUSAUR_2
      @mega_pokemon[sprite_key] = Pokemon.new(mega_venusaur_form, 1)
    when "poke_sprite2"
      mega_charizard_form = rand(2) == 0 ? :CHARIZARD_1 : :CHARIZARD_2
      @mega_pokemon[sprite_key] = Pokemon.new(mega_charizard_form, 1)
    when "poke_sprite4"
      mega_blastoise_form = rand(2) == 0 ? :BLASTOISE_1 : :BLASTOISE_2
      @mega_pokemon[sprite_key] = Pokemon.new(mega_blastoise_form, 1)
    end

    @mega_pokemon[sprite_key].make_shiny if current_shiny

    @animating_sprite = sprite_key
    # Guardar posición original antes de modificarla
    sprite = @sprites[sprite_key]
    sprite.instance_variable_set(:@original_x, sprite.x)
    sprite.instance_variable_set(:@original_y, sprite.y)

    @mega_animation_frame = 0
  end
  
  # Method to update mega evolution animation
  def update_mega_evolution
    return if @animating_sprite.nil?
    
    sprite = @sprites[@animating_sprite]
    progress = @mega_animation_frame.to_f / @mega_animation_duration
    
    if @mega_animation_frame < @mega_animation_duration / 2
      # First half: fade to white
      white_intensity = (progress * 2 * 255).to_i
      sprite.tone.red = white_intensity
      sprite.tone.green = white_intensity
      sprite.tone.blue = white_intensity
    elsif @mega_animation_frame == @mega_animation_duration / 2
      # Middle point: change to mega form
      sprite.setPokemonBitmap(@mega_pokemon[@animating_sprite])
      # Aplicar desplazamiento fijo de Mega si está definido
      if MEGA_POSITION_OFFSETS[@animating_sprite]
        dx, dy = MEGA_POSITION_OFFSETS[@animating_sprite]
        sprite.x = sprite.instance_variable_get(:@original_x) + dx
        sprite.y = sprite.instance_variable_get(:@original_y) + dy
      end
      # Also update the shadow sprite
      shadow_sprite = @sprites[@animating_sprite + "_shadow"]
      if shadow_sprite
        shadow_sprite.setShadowBitmap(sprite)
        #shadow_sprite.x = sprite.x
        #shadow_sprite.y = sprite.y
        #case @animating_sprite
        #when "poke_sprite3" then shadow_sprite.y -= 20
        #when "poke_sprite2" then shadow_sprite.y -= 28
        #when "poke_sprite4" then shadow_sprite.y -= 30
        #when "poke_sprite"  then shadow_sprite.y -= 40
        #end
      end
    elsif @mega_animation_frame < @mega_animation_duration
      # Second half: fade from white back to normal
      white_intensity = ((1 - (progress - 0.5) * 2) * 255).to_i
      sprite.tone.red = white_intensity
      sprite.tone.green = white_intensity
      sprite.tone.blue = white_intensity
    else
      # Animation complete - reset tone and schedule revert
      sprite.tone.red = 0
      sprite.tone.green = 0
      sprite.tone.blue = 0
      
      # Schedule revert back to normal form after 3 seconds
      @revert_timer = 5 * 60 # 5 seconds
      @reverting_sprite = @animating_sprite
      @animating_sprite = nil
      @revert_animation_frame = 0
    end
    
    @mega_animation_frame += 1
  end
  
  # Method to handle reverting back to normal form
  def update_revert_animation
    return if @reverting_sprite.nil?
    
    if @revert_timer > 0
      @revert_timer -= 1
    else
      # Start revert animation
      sprite = @sprites[@reverting_sprite]
      progress = @revert_animation_frame.to_f / @revert_animation_duration
      
      if @revert_animation_frame < @revert_animation_duration / 2
        # First half: fade to white (similar to mega evolution)
        white_intensity = (progress * 2 * 255).to_i
        sprite.tone.red = white_intensity
        sprite.tone.green = white_intensity
        sprite.tone.blue = white_intensity
      elsif @revert_animation_frame == @revert_animation_duration / 2
        # Middle point: change back to original form
        sprite.setPokemonBitmap(@original_pokemon[@reverting_sprite])
        # Restaurar posición original
        if sprite.instance_variable_defined?(:@original_x) && sprite.instance_variable_defined?(:@original_y)
          sprite.x = sprite.instance_variable_get(:@original_x)
          sprite.y = sprite.instance_variable_get(:@original_y)
        end
         # Also update the shadow sprite
        shadow_sprite = @sprites[@reverting_sprite + "_shadow"]
        if shadow_sprite
          shadow_sprite.setShadowBitmap(sprite)
        end
      elsif @revert_animation_frame < @revert_animation_duration
        # Second half: fade from white back to normal
        white_intensity = ((1 - (progress - 0.5) * 2) * 255).to_i
        sprite.tone.red = white_intensity
        sprite.tone.green = white_intensity
        sprite.tone.blue = white_intensity
      else
        # Revert animation complete
        sprite.tone.red = 0
        sprite.tone.green = 0
        sprite.tone.blue = 0
        @reverting_sprite = nil
        @revert_animation_frame = 0
        return
      end
      
      @revert_animation_frame += 1
    end
  end
  
  # trigger for playing the intro animation
  def intro
    begin
      if @intro && Object.const_defined?("MTS_INTRO_ANIM#{@intro}")
        intro = Object.const_get("MTS_INTRO_ANIM#{@intro}").new(@viewport,@sprites)
      elsif Object.const_defined?("MTS_INTRO_ANIM")
        intro = MTS_INTRO_ANIM.new(@viewport,@sprites)
      end
      @currentFrame = intro.currentFrame rescue 0
    rescue Exception => e
      log_compat("[ModularTitle intro error] #{e.class}: #{e.message}") rescue nil
    ensure
      @sprites.each_value { |s| s.visible = true rescue nil } if @sprites
    end
    @sprites["start"].visible = true if @sprites && @sprites["start"]
  end
  # main update for all the visual elements
  def updateElements
    for key in @sprites.keys
      @sprites[key].update if @sprites[key].respond_to?(:update)
    end
    if @sprites["start"]
      @sprites["start"].opacity -= @fade
      @fade *= -1 if @sprites["start"].opacity <= 0 || @sprites["start"].opacity >= 255
    end
  end
  # update for title screen functionality
  def update
    @currentFrame += 1
    
    # Update mega evolution timer
    @mega_timer += 1
    if @mega_timer >= @mega_interval
      start_mega_evolution rescue nil
      @mega_timer = 0
    end
    
    # Update mega evolution animation
    update_mega_evolution rescue nil
    update_revert_animation rescue nil
    
    self.updateElements rescue nil
  end
  # disposes of all visual elements
  def dispose
    if @sprites
      @sprites.each_key do |key|
        begin
          @sprites[key].dispose if @sprites[key] && !@sprites[key].disposed?
        rescue Exception
        end
      end
      @sprites.clear
    end
    begin
      @viewport.dispose if @viewport && !@viewport.disposed?
    rescue Exception
    end
  end
  # plays appropriate BGM
  def playBGM
    #---------------------------------------------------------------------------
    # setting up BGM
    # uses first available BGM modifier
    # if no BGM modifier has been defined, defaults to stock system
    bgm = nil
    for mod in @mods
      arg = mod.to_s.upcase
      if arg.include?("BGM:") # loads specific BG graphic
        bgm = arg.gsub("BGM:","")
        break
      end
    end
    # loads data
    bgm = $data_system.title_bgm.name if bgm.nil?
    @totalFrames = (getPlayTime("Audio/BGM/"+bgm).floor - 1) * Graphics.frame_rate
    pbBGMPlay(bgm)
  end
  # function to restart the game when BGM times out
  def restart
    pbBGMStop(0)
    51.times do
      @viewport.tone.red-=5
      @viewport.tone.green-=5
      @viewport.tone.blue-=5
      self.updateElements
      Graphics.update
    end
    raise Reset.new
  end
end
#===============================================================================