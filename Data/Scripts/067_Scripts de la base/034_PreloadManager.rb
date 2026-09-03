#===============================================================================
# Smart Background Preload Manager for Nintendo Switch / MKXP-Z
# Precarga inteligente en segundo plano de menús, equipo, mapa, encuentros y combates
#===============================================================================

module SwitchPreloadManager
  @queue = []
  @preloaded_bitmaps = {}
  @last_map_id = -1
  @menu_preloaded = false

  class << self
    attr_reader :queue

    # 1. Precarga de los elementos visuales del menú de pausa
    def preload_pause_menu
      return if @menu_preloaded
      @menu_preloaded = true
      menu_bitmaps = [
        "bgTop", "bgMid", "bgBtm", "selector", "pokedexA", "pokedexB", "pokemonA", "pokemonB",
        "bagA", "bagBm", "bagBf", "PlayercardA", "PlayercardB", "saveA", "saveBm", "saveBf",
        "optionsA", "optionsB", "exitA", "exitB", "sun", "moon", "captured", "icon_own",
        "rider", "vial", "vial_empty", "radar", "repel", "repel_off", "fly", "pokevial"
      ]
      menu_bitmaps.each do |f|
        begin
          bm = RPG::Cache.load_bitmap("Graphics/Pictures/DP Pause Menu/", f)
          bm.never_dispose = true if bm.respond_to?(:never_dispose=)
        rescue
        end
      end
    end

    # 2. Precarga del equipo Pokémon actual del jugador y seguidor
    def preload_player_party
      return if !$player || !$player.party
      $player.party.each_with_index do |pkmn, idx|
        next if !pkmn || pkmn.egg?
        front = GameData::Species.front_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?) rescue nil
        back  = GameData::Species.back_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?) rescue nil
        icon  = GameData::Species.icon_filename_from_pokemon(pkmn) rescue nil
        ow    = GameData::Species.ow_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?) rescue nil if defined?(GameData::Species.ow_sprite_filename)
        RPG::Cache.load_bitmap("", front) if front rescue nil
        RPG::Cache.load_bitmap("", back) if back rescue nil
        RPG::Cache.load_bitmap("", icon) if icon rescue nil
        RPG::Cache.load_bitmap("Graphics/Characters/Followers/", pkmn.species.to_s) rescue nil
        if pkmn.respond_to?(:moves) && pkmn.moves
          pkmn.moves.each do |m|
            queue_move(m.id) if m && m.id
          end
        end
      end
    end

    # 3. Precarga ultrarrápida de los participantes, gritos, sprites y animaciones del combate
    def preload_battle_participants(battle)
      return if !battle
      return if @last_preloaded_battle_id == battle.object_id
      @last_preloaded_battle_id = battle.object_id
      # Preload battle sendout SEs into OpenAL buffers
      ["Audio/SE/Battle throw", "Audio/SE/Battle ball drop", "Audio/SE/Battle ball hit", "Audio/SE/pkmn_ball", "Audio/SE/Recall"].each do |se|
        ::Audio.se_play(se, 0, 100) rescue nil
      end
      [battle.pbParty(0), battle.pbParty(1)].each do |party|
        next if !party
        party.each do |pkmn|
          next if !pkmn || pkmn.egg?
          # Preload and warm up cry in RAM/OpenAL
          cry = GameData::Species.cry_filename_from_pokemon(pkmn) rescue nil
          if cry && !cry.empty?
            ::Audio.se_play(cry, 0, 100) rescue nil
          end
          # Preload battler sprites into RAM Cache
          front = GameData::Species.front_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?) rescue nil
          back  = GameData::Species.back_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?) rescue nil
          icon  = GameData::Species.icon_filename_from_pokemon(pkmn) rescue nil
          RPG::Cache.load_bitmap("", front) if front rescue nil
          RPG::Cache.load_bitmap("", back) if back rescue nil
          RPG::Cache.load_bitmap("", icon) if icon rescue nil
          if pkmn.respond_to?(:moves) && pkmn.moves
            pkmn.moves.each do |m|
              next if !m || !m.id
              queue_move(m.id)
            end
          end
        end
      end
    rescue Exception => e
    end

    # 4. Precarga de encuentros salvajes del mapa actual y mapas conectados
    def preload_map_encounters(map_id)
      return if !map_id || map_id <= 0 || !defined?($PokemonEncounters) || !$PokemonEncounters
      maps_to_check = [map_id]
      if defined?($MapFactory) && $MapFactory && $MapFactory.respond_to?(:map_connections) && $MapFactory.map_connections
        $MapFactory.map_connections.each do |con|
          maps_to_check.push(con[1]) if con[0] == map_id
          maps_to_check.push(con[0]) if con[1] == map_id
        end rescue nil
      end
      maps_to_check.uniq.each do |m_id|
        enc_data = GameData::Encounter.get(m_id, $PokemonGlobal&.encounter_version || 0) rescue nil
        next if !enc_data || !enc_data.types
        enc_data.types.each_value do |enc_list|
          next if !enc_list
          enc_list.each do |slot|
            species = slot[1]
            next if !species
            # Preload overworld follower/wild sprite directly into RAM
            AnimatedBitmap.new("Graphics/Characters/Followers/#{species}").deanimate rescue nil
            AnimatedBitmap.new("Graphics/Characters/Followers/#{species}_0").deanimate rescue nil
            RPG::Cache.load_bitmap("Graphics/Characters/Followers/", species.to_s) rescue nil
            # Preload battle sprites
            front = GameData::Species.front_sprite_filename(species) rescue nil
            back  = GameData::Species.back_sprite_filename(species) rescue nil
            icon  = GameData::Species.icon_filename(species) rescue nil
            RPG::Cache.load_bitmap("", front) if front rescue nil
            RPG::Cache.load_bitmap("", back) if back rescue nil
            RPG::Cache.load_bitmap("", icon) if icon rescue nil
          end
        end
      end
      # Precarga de gráficos comunes de mapa, animaciones y sombras
      RPG::Cache.load_bitmap("Graphics/Characters/Shadows/", "defaultShadow") rescue nil
      RPG::Cache.load_bitmap("Graphics/Characters/Shadows/", "smallShadow") rescue nil
      RPG::Cache.load_bitmap("Graphics/Characters/Shadows/", "mediumShadow") rescue nil
      RPG::Cache.load_bitmap("Graphics/Characters/Shadows/", "largeShadow") rescue nil
    rescue Exception
    end

    # 5. Precarga de entrenadores presentes en el mapa
    def preload_map_trainers
      return if !$game_map || !$game_map.events
      $game_map.events.each_value do |event|
        next if !event || !event.name
        if event.name[/^Trainer\((\d+)\)$/]
          event.list&.each do |cmd|
            if cmd.code == 355 || cmd.code == 655 # Script call
              if cmd.parameters[0][/pbTrainerBattle\s*\(\s*:?([A-Za-z0-9_]+)/]
                trainer_type = $1.to_sym rescue nil
                if trainer_type && GameData::TrainerType.exists?(trainer_type)
                  tr_file = GameData::TrainerType.front_sprite_filename(trainer_type) rescue nil
                  queue_bitmap(tr_file) if tr_file
                end
              end
            end
          end
        end
      end
    rescue Exception
    end

    # Encolar un bitmap para carga progresiva
    def queue_bitmap(path)
      return if path.nil? || path.to_s.empty?
      clean = pbResolveBitmap(path) || path
      return if @preloaded_bitmaps[clean]
      @queue.push([:bitmap, clean]) unless @queue.any? { |item| item[0] == :bitmap && item[1] == clean }
    end

    # Encolar una especie Pokémon para carga progresiva
    def queue_species(species)
      return if species.nil?
      @queue.push([:species, species]) unless @queue.any? { |item| item[0] == :species && item[1] == species }
    end

    # Encolar una habilidad/movimiento para precarga en segundo plano
    def queue_move(move_id)
      return if move_id.nil?
      @queue.push([:move, move_id]) unless @queue.any? { |item| item[0] == :move && item[1] == move_id }
    end

    # Procesar 1 tarea por fotograma durante tiempo ocioso en el mapa
    def update
      return if @queue.empty?
      task = @queue.shift
      return if !task

      case task[0]
      when :bitmap
        path = task[1]
        if path && !@preloaded_bitmaps[path]
          resolved = pbResolveBitmap(path) || path
          @preloaded_bitmaps[path] = true
          @preloaded_bitmaps[resolved] = true if resolved
        end
      when :species
        species = task[1]
        if species && GameData::Species.exists?(species)
          front = GameData::Species.front_sprite_filename(species) rescue nil
          back  = GameData::Species.back_sprite_filename(species) rescue nil
          icon  = GameData::Species.icon_filename(species) rescue nil
          cry   = GameData::Species.cry_filename(species) rescue nil
          pbResolveBitmap(front) if front rescue nil
          pbResolveBitmap(back) if back rescue nil
          pbResolveBitmap(icon) if icon rescue nil
          pbResolveAudioSE(cry) if cry rescue nil
        end
      when :move
        move_id = task[1]
        if move_id && GameData::Move.exists?(move_id)
          move2anim = pbLoadMoveToAnim rescue nil
          animations = (defined?($PokemonBattleAnimations) && $PokemonBattleAnimations) || pbLoadBattleAnimations rescue nil
          if move2anim && animations
            anim_id = nil
            if move2anim.is_a?(Array) && move2anim[0].is_a?(Hash)
              anim_id = (move2anim[0][move_id] rescue nil) || (move2anim[1][move_id] rescue nil)
            elsif move2anim.is_a?(Array)
              found = move2anim.find { |a| a && a[0] == move_id }
              anim_id = found[1] if found
            end
            if anim_id && animations && animations[anim_id]
              anim = animations[anim_id]
              if anim.graphic && !anim.graphic.empty?
                pbGetAnimation(anim.graphic, anim.hue || 0) rescue nil
              end
            end
          end
        end
      end
    rescue Exception
    end

    # Trigger al entrar o cambiar de mapa
    def on_map_change(map_id)
      return if map_id == @last_map_id
      @last_map_id = map_id
      preload_pause_menu
      preload_player_party
      preload_map_encounters(map_id)
    end

    def preload_map_encounters(map_id)
      return if !map_id || map_id <= 0 || !defined?($PokemonEncounters) || !$PokemonEncounters
      enc_data = GameData::Encounter.get(map_id, $PokemonGlobal&.encounter_version || 0) rescue nil
      return if !enc_data || !enc_data.types
      enc_data.types.each_value do |enc_list|
        next if !enc_list
        enc_list.each do |slot|
          species = slot[1]
          next if !species
          queue_species(species)
        end
      end
    rescue Exception
    end
  end
end

# Conectar al ciclo de vida del mapa
EventHandlers.add(:on_frame_update, :switch_smart_preload, proc {
  SwitchPreloadManager.update if $scene && $scene.is_a?(Scene_Map)
})

EventHandlers.add(:on_map_or_spriteset_change, :switch_smart_preload_map, proc { |sender, e|
  SwitchPreloadManager.on_map_change($game_map.map_id) if $game_map
})
