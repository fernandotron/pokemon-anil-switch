#==============================================================================#
#                                   Footprints                                 #
#                                   por Marin                                  #
#                     Adaptado a LA BASE DE SKY por Skyflyer                   #
#==============================================================================#
#    Si un vento camina sobre el Tag de terreno 3 (Arena), producirá huellas   #
#                según camine. Funciona con el Follow Pokémon.                 #
#==============================================================================#

class Sprite_Character
  # Esta es la cantidad de opacidad que se reduce por frame. Necesita ir de 256 a 0,
  # lo que significa que establecer esto en 4 haría que cada par de pasos dure 64 frames (~1.5s)
  FADE_OUT_SPEED = 6
  
  # Un desplazamiento configurable X/Y para los sprites de los pasos, en caso de que no se alineen
  # bien con el gráfico del jugador.
  WALK_X_OFFSET = 0
  WALK_Y_OFFSET = 0
  
  # Un desplazamiento configurable X/Y para los sprites de las huellas de la bicicleta, en caso de que no se alineen
  # bien con el gráfico del jugador.
  BIKE_X_OFFSET = -8
  BIKE_Y_OFFSET = 0
  
  # Si es verdadero, tanto el jugador como el follower crearán huellas.
  # Si es falso, solo el follower creará huellas.
  DUPLICATE_FOOTSTEPS_WITH_FOLLOWER = false
  
  # Si el nombre del evento incluye alguna de estos textos, no producirá
  # huellas. Puedes añadir alguno a la lista si quieres.
  EVENTNAME_MAY_NOT_INCLUDE = [
    "SinHuellas",
    ".sinhuellas"
  ]
  
  # Si el nombre del archivo (gráfico) incluye alguna de estos textos, no producirá
  # huellas. Funciona además de la lista de nombres de eventos.
  FILENAME_MAY_NOT_INCLUDE = [
    # Aquí se pueden añadir más textos si es necesario
  ]
  
  attr_accessor :steps
  attr_reader :follower
     
  alias footsteps_initialize initialize
  def initialize(*args)
    footsteps_initialize(*args)
    if $PokemonTemp && $PokemonTemp.respond_to?(:followers) &&
       $game_temp.followers && $game_temp.followers.respond_to?(:realEvents) &&
       $game_temp.followers.realEvents.is_a?(Array) &&
       $game_temp.followers.realEvents.include?(@character)
      @follower = true
    end
    @steps = []
  end
  
  alias footsteps_dispose dispose
  def dispose
    @steps.each { |e| e[0].dispose }
    footsteps_dispose
  end
  
  alias footsteps_update update
  def update
    footsteps_update
    @old_x ||= @character.x
    @old_y ||= @character.y
    if (@character.x != @old_x || @character.y != @old_y) && !["", "nil"].include?(@character.character_name)
      if @character == $game_player && $game_temp.followers &&
         $game_temp.followers.respond_to?(:realEvents) &&
         $game_temp.followers.realEvents.select { |e| !["", "nil"].include?(e.character_name) }.size > 0 &&
         !DUPLICATE_FOOTSTEPS_WITH_FOLLOWER
        if !EVENTNAME_MAY_NOT_INCLUDE.include?($game_temp.followers.realEvents[0].name) &&
           !FILENAME_MAY_NOT_INCLUDE.include?($game_temp.followers.realEvents[0].character_name)
          make_steps = false
        else
          make_steps = true
        end
      elsif (!@character.respond_to?(:name) || !EVENTNAME_MAY_NOT_INCLUDE.include?(@character.name)) &&
             !FILENAME_MAY_NOT_INCLUDE.include?(@character.character_name)
        tilesetid = @character.map.instance_eval { @map.tileset_id }
        make_steps = [2,1,0].any? do |e|
          tile_id = @character.map.data[@old_x, @old_y, e]
          next false if tile_id.nil?
          tileset = $data_tilesets[tilesetid]
          next false if tileset.nil? || tileset.terrain_tags.nil?
          next tileset.terrain_tags[tile_id] == 3
        end
      end
      if make_steps
        fstep = Sprite.new(self.viewport)
        fstep.z = 0
        dirs = [nil,"DownLeft","Down","DownRight","Left","Still","Right","UpLeft",
            "Up", "UpRight"]
        if @character == $game_player && $PokemonGlobal.bicycle
          fstep.bmp("Graphics/Characters/steps#{dirs[@character.direction]}Bike")
        else
          fstep.bmp("Graphics/Characters/steps#{dirs[@character.direction]}")
        end
        @steps ||= []
        if @character == $game_player && $PokemonGlobal.bicycle
          x = BIKE_X_OFFSET
          y = BIKE_Y_OFFSET
        else
          x = WALK_X_OFFSET
          y = WALK_Y_OFFSET
        end
        @steps << [fstep, @character.map, @old_x + x / Game_Map::TILE_WIDTH.to_f, @old_y + y / Game_Map::TILE_HEIGHT.to_f]
      end
    end
    @old_x = @character.x
    @old_y = @character.y
    update_footsteps
  end
  
  def update_footsteps
    if @steps
      for i in 0...@steps.size
        next unless @steps[i]
        sprite, map, x, y, ox = @steps[i]
        sprite.x = -map.display_x / Game_Map::X_SUBPIXELS + x * Game_Map::TILE_WIDTH
        sprite.y = -map.display_y / Game_Map::Y_SUBPIXELS + (y + 1) * Game_Map::TILE_HEIGHT
        sprite.y -= Game_Map::TILE_HEIGHT
        sprite.opacity -= FADE_OUT_SPEED
        if sprite.opacity <= 0
          sprite.dispose
          @steps[i] = nil
        end
      end
      @steps.compact!
    end
  end
end

class DependentEventSprites
  attr_accessor :sprites
  
  def refresh
    steps = []
    for sprite in @sprites
      steps << sprite.steps
      if sprite.follower
        $FollowerSteps = sprite.steps
      end
      sprite.steps = []
      sprite.dispose
    end
    @sprites.clear
    $game_temp.followers.eachEvent do |event, data|
      if data[0] == @map.map_id # Check original map
        #@map.events[data[1]].erase
      end
      if data[2] == @map.map_id # Check current map
        spr = Sprite_Character.new(@viewport, event)
        if spr.follower
          spr.steps = $FollowerSteps
          $FollowerSteps = nil
        end
        @sprites.push(spr)
      end
    end
  end
end

class Spriteset_Map
  alias footsteps_update update
  def update
    footsteps_update
    # Only update events that are on-screen
    for sprite in @character_sprites
      if sprite.character.is_a?(Game_Event)
        sprite.update_footsteps
      end
    end
  end
end