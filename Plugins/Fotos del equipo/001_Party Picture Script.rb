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
    folder_path = File.join(System.data_directory, DIRECTORY)
    folder_path = folder_path.gsub("\\", "/")
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
    isSnapEdges = GameData::MapMetadata.try_get($game_map.map_id).snap_edges
    @can_move_camera = true #(isSnapEdges ? false : true)

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
          pbSEPlay("Player bump")
          pbWait(0.25)
        else
          pbScrollMap(8,1)
          currentY += 1
        end
      elsif Input.press?(Input::DOWN) && @can_move_camera
        if currentY == minY
          pbSEPlay("Player bump")
          pbWait(0.25)
        else
          pbScrollMap(2,1)
          currentY -= 1
        end
      elsif Input.press?(Input::RIGHT) && @can_move_camera
        if currentX == maxX
          pbSEPlay("Player bump")
          pbWait(0.25)
        else
          pbScrollMap(6,1)
          currentX += 1
        end
      elsif Input.press?(Input::LEFT) && @can_move_camera
        if currentX == minX
          pbSEPlay("Player bump")
          pbWait(0.25)
        else
          pbScrollMap(4,1)
          currentX -= 1
        end
      # elsif Input.trigger?(Input::ACTION)

      elsif Input.trigger?(Input::USE)

        choice = pbMessage(_INTL("\\l[2]¿Qué quieres hacer?"), [
          _INTL("Tomar foto"),
          _INTL("Efectos"),
          _INTL("Información"),
          _INTL("Nada")
        ])
        ############################
        #   TOMAR FOTO
        ############################
        if choice == 0    
                  # Displays a choice message if you want to take a picture or not
          choice = pbMessage(_INTL("\\l[2]¿Quieres hacer ya la foto?"), [
            _INTL("Sí"),
            _INTL("No")
          ])
          if choice == 0 #if Yes
            pbTakePicture
            $actualizarCacheAlbum = true
            return true
          else # if No
            pbMessage(_INTL("\\l[2]No te preocupes, tómate tu tiempo."))
          end

        ############################
        #   EFECTOS
        ############################
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
              pbSEPlay("GUI naming tab swap start")
            end    
          end

        ############################
        #   INFORMACIÓN
        ############################
        elsif choice == 2 
          pbMessage(_INTL("\\l[2]Tienes varias opciones y controles que puedes usar a la hora de tomarte la foto."))
          pbMessage(_INTL("\\l[2]Si pulsas las flechas de dirección podrás desplazar el objetivo y enfocar a lo que más te interese."))
          pbMessage(_INTL("\\l[2]Tienes además la opción de añadir tanto efectos como filtros. Puedes combinar ambos para tomar tu foto."))
          pbMessage(_INTL("\\l[2]Cuando tengas claro cómo quieres la foto, elige la opción de tomar foto."))
        end  
        
      #elsif Input.trigger?(Input::BACK)
      #  # Displays a choice message if you want to stop or not
      #  choice = pbMessage("\\l[2]¿Quieres dejarlo?", [
      #    _INTL("Sí"),
      #    _INTL("No")
      #  ])
      #  if choice == 0 # if yes
      #    pbMessage("¡Ok!")
      #    pbEndPictureScene
	    #    return false
      #  end
      end

      break if @picture_taken
    end
  end
  
  def pbTakePicture
    # Picture taken effects
    @sprites["overlay"].visible = false
    pbSEPlay("Battle catch click")
    pbFlash(Color.new(255, 255, 255, 255), 10)
    pbWait(11.0/20)

    # Specify the folder path where you want to save the images
    folder_path = self.class.get_directory
    create_folder_if_not_exist(folder_path)
    
    # Checks if an image of the same name already exists, if so adds a (x) to its name
    counter = 0

    tiempo_actual = pbGetTimeNow
    dia  = tiempo_actual.day
    mes  = tiempo_actual.month
    anyo = tiempo_actual.year

    # Buscamos el primer archivo.
    file_pattern = File.join(folder_path, "capture000*.png")
    matching_files = Dir.glob(file_pattern)
    while !matching_files.empty?
      counter += 1
      num_captura_base = sprintf("%03d",counter)
      # Buscamos el archivo que se llame así.
      file_pattern = File.join(folder_path, "capture#{num_captura_base}*.png")
      matching_files = Dir.glob(file_pattern)
    end

    # Hemos encontrado un counter que no tiene imagen.
    num_captura_base = sprintf("%03d",counter)
    exporter_filename = "capture#{num_captura_base}_#{dia}_#{mes}_#{anyo}.png"

    # Take a screenshot and save it
    bmp = Graphics.snap_to_bitmap
    bmp.save_to_png(File.join(folder_path, exporter_filename))
    bmp.dispose
    #@sprites["overlay"].visible = true
    pbWait(6.0/20)
    pbEndPictureScene
    # Hago esto de nuevo para volver a copiar las fotos y así tener la última en la carpeta del juego.
    create_folder_if_not_exist(folder_path)
  end
  
  def pbStartPictureScene(ev1, ev2, ev3, ev4, ev5, ev6)
    # Fades the screen and runs the code
    pbFadeOutIn do
      # Loop through the Player Party to change event's character sprites
      # Stores the events sprites and then make every event in the map invisible
      #if !@visible_npcs
      #  $game_map.store_event_character_names
      #  $game_map.clear_event_character_names
      #end
      party = $player.party
      party.each_with_index do |pkmn, i|
        next if pkmn.egg?
        shiny = pkmn.shiny?
        ev_id = eval("ev#{i+1}")
        next unless ev_id
        file = GameData::Species.ow_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, shiny, pkmn.shadow)
        file.gsub!("Graphics/Characters/", "")
        $game_map.events[ev_id].character_name = file
        pbMoveRoute($game_map.events[ev_id], [PBMoveRoute::STEP_ANIME_ON], false)
      end
      
      # Toggles Following Pokémon if it's currently active
      if FollowingPkmn.active?
        @toggle = true
        FollowingPkmn.toggle_off(false)
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
      $scene.miniupdate
      pbWait(0.5)
    end
  end
  
  def pbEndPictureScene
=begin
    pbScrollMapToPlayer(4) if @can_move_camera
    pbFadeOutIn do
      # Returns the camera back to the player in case it's not currently there
      # Restore all events previously made invisible
      #$game_map.restore_event_character_names if !@visible_npcs
      # Make all events characters invisible again

      [@ev1, @ev2, @ev3, @ev4, @ev5, @ev6].each do |i|
        $game_map.events[i].character_name = '' if $game_map.events[i] # Reset character name to make it invisible
        pbMoveRoute($game_map.events[i], [PBMoveRoute::STEP_ANIME_OFF], false)
      end
          
      # Returns Following Pokémon in case it was active before
      if @toggle
        FollowingPkmn.toggle_on#(false)
      end
=end
      # Removes any active filters
      pbToneChangeAll(Tone.new(0, 0, 0, 0), 4)
      # Disposes all sprites and viewports
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
      # Refreshes the map before fading in
      $game_map.need_refresh = true
      pbWait(0.5)
      $scene.miniupdate
      @picture_taken = true # breaks the loop
#    end
  end

  def create_folder_if_not_exist(folder_path)
    # Check if the folder already exists
    unless FileTest.exist?(folder_path)
        Dir.mkdir(folder_path)
    end
    # Copiamos las fotos de la carpeta del save a la del juego
    # (hago esto porque soy incapaz de leer las fotos directamente de la carpeta del save)
    copiar_fotos_de_carpeta_sistema_a_juego
    echoln "Copia de Fotos hecha en la carepeta Fotos."
  end  

  def pbUpdateSceneMap
    $scene.miniupdate if $scene.is_a?(Scene_Map) && !pbIsFaded?
  end
end



def terminarFoto(ev1, ev2, ev3, ev4, ev5, ev6)
  [ev1, ev2, ev3, ev4, ev5, ev6].each do |i|
    $game_map.events[i].character_name = '' if $game_map.events[i] # Reset character name to make it invisible
    pbMoveRoute($game_map.events[i], [PBMoveRoute::STEP_ANIME_OFF], false)
  end
      
  # Returns Following Pokémon in case it was active before
  if true #@toggle
    FollowingPkmn.toggle_on#(false)
  end
  
  # Refreshes the map before fading in
  $game_map.need_refresh = true
  pbWait(0.5)
  $scene.miniupdate
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