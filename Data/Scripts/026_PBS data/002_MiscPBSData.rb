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
  $LAST_ANIM_LOAD_FRAME ||= 0
  current_frame = (Graphics.frame_count rescue 0)
  if current_frame > 0 && (current_frame - $LAST_ANIM_LOAD_FRAME).abs < 40 && $LAST_ANIM_LOAD_FRAME > 0
    fallback = PBAnimations.new(0)
    fallback.array.clear if fallback.respond_to?(:array) && fallback.array
    return fallback
  end
  $LAST_ANIM_LOAD_FRAME = current_frame

  begin
    $PokemonBattleAnimations = load_data("Data/PkmnAnimations.rxdata")
  rescue Exception => e
    log_compat("[Animaciones] Fallo al cargar PkmnAnimations.rxdata: #{e.class}: #{e.message}") rescue nil
    $PokemonBattleAnimations = nil
  end
  if !$PokemonBattleAnimations.is_a?(PBAnimations) || $PokemonBattleAnimations.length <= 0
    log_compat("[Animaciones] Tipo inesperado o vacio: #{$PokemonBattleAnimations.class}") rescue nil
    $PokemonBattleAnimations = nil
    fallback = PBAnimations.new(0)
    fallback.array.clear if fallback.respond_to?(:array) && fallback.array
    return fallback
  end
  if defined?($game_temp) && $game_temp
    $game_temp.battle_animations_data = $PokemonBattleAnimations
  end
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

