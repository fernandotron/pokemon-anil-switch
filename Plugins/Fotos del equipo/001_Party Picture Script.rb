=begin

###### Ubicación de todas las fotos: ######

Ciudad Plateada
Monte Moon
Ruta 21 (faro)
SS Anne
Ruta 8 (cementerio)
Ciudad Azulona
Ciudad Fucsia
Ciudad Azafrán
Isla Canela
Cataratas Tohjo (cima campana)
Ruta 23 (pre liga)
Ciudad Añil (Liga Pkmn)
Villa Azabache
Bosque Arcoiris
Claro Secreto (Celebi)
Brock (Túnel Roca)
Misty (Ruta 12)
Surge (Central Eléctrica)
Erika (Ruta 11)
Koga y Sachiko (Safari)
Sabrina (Centro Comercial)
Blaine (Mansion quemada)
Urano (Torre Pokémon)
Oak (Laboratorio)
Azul (su casa)
Rojo/Hoja (su casa)
Ash (Monte Añil)

=end

class PartyPicture
  # To create a new one just add a new element to this array, the first one will
  # be its name, the second one will be the tone effect applied.
  # example: ["Blue", Tone.new(0, 0, 255, 0)]
  # Don't forget the commas. The last element should not have a comma!
  def self.filters
    [
      [_INTL("Rosa"), Tone.new(80, 10, 75, 0)],
      [_INTL("Sepia"), Tone.new(0, 0, -85, 100)],
      [_INTL("B&W"), Tone.new(-20, -20, -20, 255)],
      [_INTL("Brillo"), Tone.new(60, 60, 60, 0)],
      [_INTL("Oscuro"), Tone.new(-60, -60, -60, 40)]
    ]
  end
  
  # To create a new one just add a new element to this array, the first one will
  # be its name, the second one will be the file name. You should store your
  # overlays inside the Graphics/Pictures folder!
  # Don't forget the comma. The last element should not have a comma!
  def self.overlays
    [
      [_INTL("Marco Rosa"), "Pretty Pink Overlay"],
      [_INTL("Marco Azul"), "Pretty Blue Overlay"],
      [_INTL("Brillos"), "Sparkles Overlay"],
      [_INTL("Polaroid"), "Polaroid Overlay"],
      [_INTL("Viñeta"), "Vignette Overlay"]
    ]
  end
  
  # Defines how many tiles the camera can move to the left and right
  MAX_HORIZONTAL_MOVEMENT = 4
  # Defines how many tiles the camera can move up and down
  MAX_VERTICAL_MOVEMENT = 2

  # The directory where the Pictures will be saved, if the specified directory does not exist it will be automatically created.
  DIRECTORY = "Fotos"

  def self.get_directory
    "Fotos"
  end

  def initialize(ev1, ev2, ev3, ev4, ev5, ev6, keep_npcs_visible = true)
    @ev1 = ev1
    @ev2 = ev2
    @ev3 = ev3
    @ev4 = ev4
    @ev5 = ev5
    @ev6 = ev6
    @visible_npcs = keep_npcs_visible
    # Checks if the map has Snap Edges on, if so, locks the camera movement.
    isSnapEdges = GameData::MapMetadata.try_get($game_map.map_id).snap_edges rescue false
    @can_move_camera = true

    # Gets the names and effects of filters and overlays defined previously
    @filters_names   = self.class.filters.map { |filter| filter[0] }
    @filters_effects = self.class.filters.map { |filter| filter[1] }
    @overlays_names  = self.class.overlays.map { |overlay| overlay[0] }
    @overlays_images = self.class.overlays.map { |overlay| overlay[1] }
    
    # Starts a lot of the sprites
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @sprites = {}
    @sprites["filter_overlay"] = Sprite.new(@viewport)
    @sprites["filter_overlay"].visible = false
    @sprites["filter_overlay"].bitmap = Bitmap.new("Graphics/UI/Party Pictures/Polaroid Overlay")
    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].visible = false
    @sprites["overlay"].bitmap = Bitmap.new("Graphics/UI/Party Pictures/Camera Overlay.png")
    
    #Starts the scene
    pbStartPictureScene(ev1, ev2, ev3, ev4, ev5, ev6)

    pbWait(1)
    pbMessage(_INTL("\\l[2]Usa las flechas para elegir la posición y pulsa Enter para ver las distintas opciones."))
    pbMessage(_INTL("\\l[2]Es aconsejable desactivar el turbo para que la foto salga correctamente."))
    
    # Starts the commands such as movement, buttons being pressed...
    main
  end

  def main
    # defines some variables
    currentY = 0
    currentX = 0
    maxY = MAX_VERTICAL_MOVEMENT
    minY = -MAX_VERTICAL_MOVEMENT
    maxX = MAX_HORIZONTAL_MOVEMENT
    minX = -MAX_HORIZONTAL_MOVEMENT
    @picture_taken = false
    loop do
      pbUpdateSceneMap
      Graphics.update
      Input.update
      if Input.press?(Input::UP) && @can_move_camera
        if currentY == maxY
          pbSEPlay("Player bump") rescue nil
          pbWait(0.25)
        else
          pbScrollMap(8,1)
          currentY += 1
        end
      elsif Input.press?(Input::DOWN) && @can_move_camera
        if currentY == minY
          pbSEPlay("Player bump") rescue nil
          pbWait(0.25)
        else
          pbScrollMap(2,1)
          currentY -= 1
        end
      elsif Input.press?(Input::RIGHT) && @can_move_camera
        if currentX == maxX
          pbSEPlay("Player bump") rescue nil
          pbWait(0.25)
        else
          pbScrollMap(6,1)
          currentX += 1
        end
      elsif Input.press?(Input::LEFT) && @can_move_camera
        if currentX == minX
          pbSEPlay("Player bump") rescue nil
          pbWait(0.25)
        else
          pbScrollMap(4,1)
          currentX -= 1
        end
      elsif Input.trigger?(Input::USE)
        choice = pbMessage(_INTL("\\l[2]¿Qué quieres hacer?"), [
          _INTL("Tomar foto"),
          _INTL("Efectos"),
          _INTL("Información"),
          _INTL("Nada")
        ])
        if choice == 0    
          choice = pbMessage(_INTL("\\l[2]¿Quieres hacer ya la foto?"), [
            _INTL("Sí"),
            _INTL("No")
          ])
          if choice == 0
            pbTakePicture
            $actualizarCacheAlbum = true
            return true
          else
            pbMessage(_INTL("\\l[2]No te preocupes, tómate tu tiempo."))
          end
        elsif choice == 1
          choice = pbMessage(_INTL("\\l[2]¿Quieres usar algún filtro o marco?"), [
            _INTL("Filtros"),
            _INTL("Marcos"),
            _INTL("Nada")
          ])
          if choice == 0
            filter_choice = pbMessage(_INTL("\\l[2]¿Qué filtro quieres usar?"),
              @filters_names + [_INTL("Normal"), _INTL("Volver")
            ])
            if filter_choice != self.class.filters.size + 1
              if filter_choice != self.class.filters.size
                pbToneChangeAll(@filters_effects[filter_choice], 4)
              else
                pbToneChangeAll(Tone.new(0, 0, 0, 0), 4)
              end
            end
          elsif choice == 1
            overlay_choice = pbMessage(_INTL("\\l[2]¿Qué efecto quieres usar?"), 
              @overlays_names + [_INTL("Ninguno"), _INTL("Volver")
            ])
            if overlay_choice != self.class.overlays.size + 1
              if overlay_choice != self.class.overlays.size
                @sprites["filter_overlay"].bitmap = Bitmap.new("Graphics/UI/Party Pictures/" + @overlays_images[overlay_choice])
                @sprites["filter_overlay"].visible = true
              else
                @sprites["filter_overlay"].visible = false
              end
              pbSEPlay("GUI naming tab swap start") rescue nil
            end    
          end
        elsif choice == 2 
          pbMessage(_INTL("\\l[2]Tienes varias opciones y controles que puedes usar a la hora de tomarte la foto."))
          pbMessage(_INTL("\\l[2]Si pulsas las flechas de dirección podrás desplazar el objetivo y enfocar a lo que más te interese."))
          pbMessage(_INTL("\\l[2]Tienes además la opción de añadir tanto efectos como filtros. Puedes combinar ambos para tomar tu foto."))
          pbMessage(_INTL("\\l[2]Cuando tengas claro cómo quieres la foto, elige la opción de tomar foto."))
        end  
      end
      break if @picture_taken
    end
  end
  
  def pbTakePicture
    # Picture taken effects
    @sprites["overlay"].visible = false rescue nil
    pbSEPlay("Battle catch click") rescue nil
    pbFlash(Color.new(255, 255, 255, 255), 10) rescue nil
    pbWait(11.0/20)

    folder_path = self.class.get_directory
    Dir.mkdir(folder_path) unless Dir.exist?(folder_path) rescue nil
    
    tiempo_actual = pbGetTimeNow rescue Time.now
    dia  = tiempo_actual.day
    mes  = tiempo_actual.month
    anyo = tiempo_actual.year

    existing_count = (Dir.glob(File.join(folder_path, "capture*.png")).size rescue 0)
    counter = existing_count
    exporter_filename = sprintf("capture%03d_%d_%d_%d.png", counter, dia, mes, anyo)
    while File.exist?(File.join(folder_path, exporter_filename))
      counter += 1
      exporter_filename = sprintf("capture%03d_%d_%d_%d.png", counter, dia, mes, anyo)
    end

    # Take a screenshot and save it directly and instantly
    bmp = Graphics.snap_to_bitmap
    bmp.save_to_png(File.join(folder_path, exporter_filename)) rescue nil
    bmp.dispose rescue nil

    pbWait(6.0/20)
    pbEndPictureScene
  end
  
  def pbStartPictureScene(ev1, ev2, ev3, ev4, ev5, ev6)
    # Fades the screen and runs the code
    pbFadeOutIn do
      party = $player.party
      events = [ev1, ev2, ev3, ev4, ev5, ev6]
      party.each_with_index do |pkmn, i|
        next if pkmn.egg?
        shiny = pkmn.shiny?
        ev_id = events[i]
        next unless ev_id
        file = GameData::Species.ow_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, shiny, pkmn.shadow) rescue ""
        file = file.to_s.sub(/^Graphics\/Characters\//i, "")
        $game_map.events[ev_id].character_name = file if $game_map.events[ev_id]
        pbMoveRoute($game_map.events[ev_id], [PBMoveRoute::STEP_ANIME_ON], false) if $game_map.events[ev_id]
      end
      
      # Toggles Following Pokémon if it's currently active
      if FollowingPkmn.active?
        @toggle = true
        FollowingPkmn.toggle_off(false) rescue nil
      else
        @toggle = false
      end
      
      # Forces the player to face down
      $game_player.direction = 2
      # Turns on the Camera Overlay Guide
      @sprites["overlay"].visible = true
      # Refreshes the map before Fading In
      $game_map.need_refresh = true
      pbWait(0.5)
      $scene.miniupdate if defined?($scene) && $scene.respond_to?(:miniupdate)
      pbWait(0.5)
    end
  end
  
  def pbEndPictureScene
      # Removes any active filters
      pbToneChangeAll(Tone.new(0, 0, 0, 0), 4) rescue nil
      # Disposes all sprites and viewports
      pbDisposeSpriteHash(@sprites) rescue nil
      @viewport.dispose rescue nil
      # Refreshes the map before fading in
      $game_map.need_refresh = true if $game_map
      pbWait(0.5)
      $scene.miniupdate if defined?($scene) && $scene.respond_to?(:miniupdate)
      @picture_taken = true # breaks the loop
  end

  def create_folder_if_not_exist(folder_path)
    Dir.mkdir(folder_path) unless Dir.exist?(folder_path) || FileTest.exist?(folder_path) rescue nil
  end  

  def pbUpdateSceneMap
    $scene.miniupdate if $scene.is_a?(Scene_Map) && !pbIsFaded?
  end
end

def terminarFoto(ev1, ev2, ev3, ev4, ev5, ev6)
  [ev1, ev2, ev3, ev4, ev5, ev6].each do |i|
    if $game_map && $game_map.events && $game_map.events[i]
      $game_map.events[i].character_name = ''
      pbMoveRoute($game_map.events[i], [PBMoveRoute::STEP_ANIME_OFF], false) rescue nil
    end
  end
      
  # Returns Following Pokémon in case it was active before
  if defined?(FollowingPkmn)
    $PokemonGlobal.follower_toggle_locked = false if defined?($PokemonGlobal) && $PokemonGlobal
    $PokemonGlobal.follower_toggled = true if defined?($PokemonGlobal) && $PokemonGlobal
    FollowingPkmn.toggle_on(false) rescue nil
    FollowingPkmn.refresh(false) rescue nil
    ev = FollowingPkmn.get_event rescue nil
    if ev
      ev.transparent = false if ev.respond_to?(:transparent=)
      ev.opacity = 255 if ev.respond_to?(:opacity=)
    end
  end
  
  # Refreshes the map before fading in
  $game_map.need_refresh = true if $game_map
  pbWait(0.2)
  $scene.miniupdate if defined?($scene) && $scene.respond_to?(:miniupdate)
end




class Game_Map
  attr_accessor :event_character_names

  # Method to store all event character names
  def store_event_character_names
    @event_character_names = {}
    @events.each do |event_id, event|
      @event_character_names[event_id] = event.character_name
    end
  end

  # Method to set all event characters invisible
  def clear_event_character_names
    @events.each do |event_id, event|
      event.character_name = ""
    end
  end

  # Method to restore event character names
  def restore_event_character_names
    @event_character_names.each do |event_id, character_name|
      @events[event_id].character_name = character_name
    end
  end
end



MAX_FOTOS = 27

# Función para mejorar la tarjeta de Entrenador al conseguir todas las fotos.
def todas_fotos_hechas?
  if $game_variables[71] == MAX_FOTOS
    $player.stars += 1
    pbMEPlay("Voltorb Flip win")
    pbMessage("¡Has obtenido una <b>Estrella</b> en tu Tarjeta de Entrenador!")
  end
end