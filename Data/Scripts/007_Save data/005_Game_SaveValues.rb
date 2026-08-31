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
  def self.save_options
    return if !$PokemonSystem
    begin
      opts = {
        :screensize => $PokemonSystem.screensize,
        :textspeed => $PokemonSystem.textspeed,
        :volume => ($PokemonSystem.volume rescue 80),
        :sevolume => ($PokemonSystem.sevolume rescue 80),
        :bgmvolume => ($PokemonSystem.bgmvolume rescue 80),
        :textskin => $PokemonSystem.textskin,
        :salvajes_visibles_en_ow => ($PokemonSystem.salvajes_visibles_en_ow rescue 0),
        :vsync => $PokemonSystem.vsync,
        :autotile_animations => $PokemonSystem.autotile_animations,
        :battlescene => ($PokemonSystem.battlescene rescue 0),
        :battlestyle => ($PokemonSystem.battlestyle rescue 0),
        :show_pokemon_on_change => ($PokemonSystem.show_pokemon_on_change rescue 0)
      }
      File.open("Data/options.dat", "wb") do |f|
        Marshal.dump(opts, f)
      end
    rescue Exception => e
    end
  end

  def self.load_options
    return if !File.exist?("Data/options.dat") || !$PokemonSystem
    begin
      opts = File.open("Data/options.dat", "rb") { |f| Marshal.load(f) }
      if opts.is_a?(Hash)
        $PokemonSystem.screensize = opts[:screensize] if opts.key?(:screensize)
        $PokemonSystem.textspeed = opts[:textspeed] if opts.key?(:textspeed)
        $PokemonSystem.volume = opts[:volume] if opts.key?(:volume) && $PokemonSystem.respond_to?(:volume=)
        $PokemonSystem.sevolume = opts[:sevolume] if opts.key?(:sevolume) && $PokemonSystem.respond_to?(:sevolume=)
        $PokemonSystem.bgmvolume = opts[:bgmvolume] if opts.key?(:bgmvolume) && $PokemonSystem.respond_to?(:bgmvolume=)
        $PokemonSystem.textskin = opts[:textskin] if opts.key?(:textskin)
        $PokemonSystem.salvajes_visibles_en_ow = opts[:salvajes_visibles_en_ow] if opts.key?(:salvajes_visibles_en_ow) && $PokemonSystem.respond_to?(:salvajes_visibles_en_ow=)
        $PokemonSystem.vsync = opts[:vsync] if opts.key?(:vsync)
        $PokemonSystem.autotile_animations = opts[:autotile_animations] if opts.key?(:autotile_animations)
        $PokemonSystem.battlescene = opts[:battlescene] if opts.key?(:battlescene) && $PokemonSystem.respond_to?(:battlescene=)
        $PokemonSystem.battlestyle = opts[:battlestyle] if opts.key?(:battlestyle) && $PokemonSystem.respond_to?(:battlestyle=)
        $PokemonSystem.show_pokemon_on_change = opts[:show_pokemon_on_change] if opts.key?(:show_pokemon_on_change) && $PokemonSystem.respond_to?(:show_pokemon_on_change=)
        pbSetResizeFactor($PokemonSystem.screensize) rescue nil
      end
    rescue Exception => e
    end
  end
end