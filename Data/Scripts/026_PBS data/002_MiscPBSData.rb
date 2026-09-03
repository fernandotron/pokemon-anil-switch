#===============================================================================
# Data caches.
#===============================================================================
class Game_Temp
  attr_accessor :regional_dexes_data
  attr_accessor :battle_animations_data
  attr_accessor :move_to_battle_animation_data
  attr_accessor :map_infos
end

def pbClearData
  if $game_temp
    $game_temp.regional_dexes_data           = nil
    $game_temp.battle_animations_data        = nil
    $game_temp.move_to_battle_animation_data = nil
    $game_temp.map_infos                     = nil
  end
  MapFactoryHelper.clear
  $PokemonEncounters.setup($game_map.map_id) if $game_map && $PokemonEncounters
  if pbRgssExists?("Data/Tilesets.rxdata")
    $data_tilesets = load_data("Data/Tilesets.rxdata")
  end
end

#===============================================================================
# Method to get Regional Dexes data.
#===============================================================================
def pbLoadRegionalDexes
  $game_temp = Game_Temp.new if !$game_temp
  if !$game_temp.regional_dexes_data
    $game_temp.regional_dexes_data = load_data("Data/regional_dexes.dat")
  end
  return $game_temp.regional_dexes_data
end

#===============================================================================
# Methods relating to battle animations data.
#===============================================================================
def pbLoadBattleAnimations
  return $PokemonBattleAnimations if $PokemonBattleAnimations && ($PokemonBattleAnimations.is_a?(PBAnimations) || $PokemonBattleAnimations.is_a?(Array)) && $PokemonBattleAnimations.length > 0
  begin
    data = load_data("Data/PkmnAnimations.rxdata")
    if data && (data.is_a?(PBAnimations) || data.is_a?(Array)) && data.length > 0
      $PokemonBattleAnimations = data
      if defined?($game_temp) && $game_temp
        $game_temp.battle_animations_data = $PokemonBattleAnimations
      end
      log_compat("[Animaciones] PkmnAnimations.rxdata cargado con exito: #{data.length} animaciones.") rescue nil
      return $PokemonBattleAnimations
    end
  rescue Exception => e
    log_compat("[Animaciones] Fallo al cargar PkmnAnimations.rxdata: #{e.class}: #{e.message}") rescue nil
  end
  $PokemonBattleAnimations ||= PBAnimations.new(0)
  return $PokemonBattleAnimations
end

def pbLoadMoveToAnim
  return $PokemonMoveToAnim if $PokemonMoveToAnim && !$PokemonMoveToAnim.empty?
  $PokemonMoveToAnim = (load_data("Data/move2anim.dat") rescue nil) || []
  if defined?($game_temp) && $game_temp
    $game_temp.move_to_battle_animation_data = $PokemonMoveToAnim
  end
  return $PokemonMoveToAnim
end

#===============================================================================
# Method relating to map infos data.
#===============================================================================
def pbLoadMapInfos
  $game_temp = Game_Temp.new if !$game_temp
  if !$game_temp.map_infos
    $game_temp.map_infos = load_data("Data/MapInfos.rxdata")
  end
  return $game_temp.map_infos
end

