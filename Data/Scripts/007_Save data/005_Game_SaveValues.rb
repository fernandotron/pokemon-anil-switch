# Contains the save values defined in Essentials by default.

SaveData.register(:player) do
  ensure_class :Player
  save_value { $player }
  load_value { |value| $player = value }
  new_game_value { Player.new("Unnamed", GameData::TrainerType.keys.first) }
end

# @deprecated This save data is slated to be removed in v22, as its use is
# replaced by $stats.play_time.
SaveData.register(:frame_count) do
  ensure_class :Integer
  save_value { Graphics.frame_count }
  load_value { |value| Graphics.frame_count = value }
  new_game_value { 0 }
end

SaveData.register(:game_system) do
  load_in_bootup
  ensure_class :Game_System
  save_value { $game_system }
  load_value { |value| $game_system = value }
  new_game_value { Game_System.new }
end

SaveData.register(:pokemon_system) do
  load_in_bootup
  ensure_class :PokemonSystem
  save_value { $PokemonSystem }
  load_value { |value| $PokemonSystem = value }
  new_game_value { PokemonSystem.new }
end

SaveData.register(:switches) do
  ensure_class :Game_Switches
  save_value { $game_switches }
  load_value { |value| $game_switches = value }
  new_game_value { Game_Switches.new }
end

SaveData.register(:variables) do
  ensure_class :Game_Variables
  save_value { $game_variables }
  load_value { |value| $game_variables = value }
  new_game_value { Game_Variables.new }
end

SaveData.register(:self_switches) do
  ensure_class :Game_SelfSwitches
  save_value { $game_self_switches }
  load_value { |value| $game_self_switches = value }
  new_game_value { Game_SelfSwitches.new }
end

SaveData.register(:game_screen) do
  ensure_class :Game_Screen
  save_value { $game_screen }
  load_value { |value| $game_screen = value }
  new_game_value { Game_Screen.new }
end

SaveData.register(:map_factory) do
  ensure_class :PokemonMapFactory
  save_value { $map_factory }
  load_value { |value| $map_factory = value }
end

SaveData.register(:game_player) do
  ensure_class :Game_Player
  save_value { $game_player }
  load_value { |value| $game_player = value }
  new_game_value { Game_Player.new }
end

SaveData.register(:global_metadata) do
  ensure_class :PokemonGlobalMetadata
  save_value { $PokemonGlobal }
  load_value { |value| $PokemonGlobal = value }
  new_game_value { PokemonGlobalMetadata.new }
end

SaveData.register(:map_metadata) do
  ensure_class :PokemonMapMetadata
  save_value { $PokemonMap }
  load_value { |value| $PokemonMap = value }
  new_game_value { PokemonMapMetadata.new }
end

SaveData.register(:bag) do
  ensure_class :PokemonBag
  save_value { $bag }
  load_value { |value| $bag = value }
  new_game_value { PokemonBag.new }
end

SaveData.register(:storage_system) do
  ensure_class :PokemonStorage
  save_value { $PokemonStorage }
  load_value { |value| $PokemonStorage = value }
  new_game_value { PokemonStorage.new }
end

SaveData.register(:essentials_version) do
  load_in_bootup
  ensure_class :String
  save_value { Essentials::VERSION }
  load_value { |value| $save_engine_version = value }
  new_game_value { Essentials::VERSION }
end

SaveData.register(:game_version) do
  load_in_bootup
  ensure_class :String
  save_value { Settings::GAME_VERSION }
  load_value { |value| $save_game_version = value }
  new_game_value { Settings::GAME_VERSION }
end

SaveData.register(:stats) do
  load_in_bootup
  ensure_class :GameStats
  save_value { $stats }
  load_value { |value| $stats = value }
  new_game_value { GameStats.new }
  reset_on_new_game
end

module SaveData
  OPTIONS_FILE_PATH = "options.dat"

  def self.save_options
    return if !$PokemonSystem
    begin
      opts = {}
      $PokemonSystem.instance_variables.each do |ivar|
        name = ivar.to_s.sub(/^@/, '').to_sym
        opts[name] = $PokemonSystem.instance_variable_get(ivar)
      end
      
      paths = [
        defined?($SavePath) && $SavePath ? "#{$SavePath}options.dat" : nil,
        OPTIONS_FILE_PATH,
        "Data/options.dat"
      ].compact.uniq

      paths.each do |file_path|
        begin
          tmp_path = file_path + ".tmp"
          File.open(tmp_path, "wb") { |f| Marshal.dump(opts, f) }
          if File.size(tmp_path) > 0
            File.rename(tmp_path, file_path) rescue (File.open(file_path, "wb") { |f| Marshal.dump(opts, f) } rescue nil)
            switch_invalidate_file_cache(file_path) rescue nil
            $SWITCH_FILE_EXIST_CACHE&.delete(file_path)
          end
          File.delete(tmp_path) if File.exist?(tmp_path) rescue nil
        rescue Exception
        end
      end
    rescue Exception => e
      log_compat("[SaveData.save_options] Error: #{e.class} - #{e.message}") rescue nil
    end
  end

  def self.load_options
    return if !$PokemonSystem
    paths = [
      defined?($SavePath) && $SavePath ? "#{$SavePath}options.dat" : nil,
      OPTIONS_FILE_PATH,
      "Data/options.dat"
    ].compact.uniq

    file_path = paths.find { |p| File.file?(p) }
    return if !file_path
    begin
      opts = File.open(file_path, "rb") { |f| Marshal.load(f) }
      if opts.is_a?(Hash)
        opts.each do |k, v|
          setter = "#{k}="
          if $PokemonSystem.respond_to?(setter)
            $PokemonSystem.send(setter, v)
          else
            $PokemonSystem.instance_variable_set("@#{k}", v)
          end
        end
        sz = ($PokemonSystem.screensize rescue 1)
        sz = 1 if sz.nil?
        pbSetResizeFactor([sz, 4].min) rescue nil
        if defined?(MessageConfig) && $PokemonSystem.respond_to?(:textspeed)
          MessageConfig.pbSetTextSpeed(MessageConfig.pbSettingToTextSpeed($PokemonSystem.textspeed)) rescue nil
        end
      end
    rescue Exception => e
      log_compat("[SaveData.load_options] Error: #{e.class} - #{e.message}") rescue nil
    end
  end
end