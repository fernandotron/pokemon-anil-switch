#===============================================================================
# Shortcut
#===============================================================================
AIFM_Option                               = AdvancedItemsFieldMoves::MENU_CONFIG
#Obstacle Smash
AIFM_RockSmash      = Show_RockSmash      = AdvancedItemsFieldMoves::ROCKSMASH_CONFIG
AIFM_Cut            = Show_Cut            = AdvancedItemsFieldMoves::CUT_CONFIG
# AIFM_IceSmash       = Show_IceSmash       = AdvancedItemsFieldMoves::ICESMASH_CONFIG
#Enocunters
AIFM_Headbutt       = Show_Headbutt       = AdvancedItemsFieldMoves::HEADBUTT_CONFIG
# AIFM_SweetScent     = Show_SweetScent     = AdvancedItemsFieldMoves::SWEETSCENT_CONFIG
#Environment Interactions
AIFM_Strength       = Show_Strength       = AdvancedItemsFieldMoves::STRENGTH_CONFIG
AIFM_Flash          = Show_Flash          = AdvancedItemsFieldMoves::FLASH_CONFIG
# AIFM_Defog          = Show_Defog          = AdvancedItemsFieldMoves::DEFOG_CONFIG
# AIFM_WPush                                = AdvancedItemsFieldMoves::WEATHERPUSH_CONFIG
# AIFM_Weather        = Show_Weather        = AdvancedItemsFieldMoves::WEATHER_CONFIG
# AIFM_Camouflage     = Show_Camouflage     = AdvancedItemsFieldMoves::CAMOUFLAGE_CONFIG
#Water Movement
AIFM_Surf           = Show_Surf           = AdvancedItemsFieldMoves::SURF_CONFIG
# AIFM_Dive           = Show_Dive           = AdvancedItemsFieldMoves::DIVE_CONFIG
# AIFM_Waterfall      = Show_Waterfall      = AdvancedItemsFieldMoves::WATERFALL_CONFIG
# AIFM_Whirlpool      = Show_Whirlpool      = AdvancedItemsFieldMoves::WHIRLPOOL_CONFIG
#Other Movement
# AIFM_Fly            = Show_Fly            = AdvancedItemsFieldMoves::FLY_CONFIG
# AIFM_Dig            = Show_Dig            = AdvancedItemsFieldMoves::DIG_CONFIG
# AIFM_Teleport       = Show_Teleport       = AdvancedItemsFieldMoves::TELEPORT_CONFIG
AIFM_RockClimb      = Show_RockClimb      = AdvancedItemsFieldMoves::ROCKCLIMB_CONFIG
#Other Items
# AIFM_LavaSurf       = Show_LavaSurf       = AdvancedItemsFieldMoves::LAVASURF_CONFIG
# AIFM_Lavafall       = Show_Lavafall       = AdvancedItemsFieldMoves::LAVAFALL_CONFIG
# AIFM_LavaSwirl      = Show_LavaSwirl      = AdvancedItemsFieldMoves::LAVASWIRL_CONFIG
# #Zelda Items
# AIFM_Lift           = Show_Lift           = AdvancedItemsFieldMoves::LIFT_CONFIG
# AIFM_SenseTruth     = Show_SenseTruth     = AdvancedItemsFieldMoves::SENSETRUTH_CONFIG
# #Music Pockets
# AIFM_Pocket1        = Show_WP1            = AdvancedItemsFieldMoves::WEATHER_P1_CONFIG
# AIFM_Pocket2        = Show_WP2            = AdvancedItemsFieldMoves::WEATHER_P2_CONFIG
# AIFM_Pocket3        = Show_WP3            = AdvancedItemsFieldMoves::WEATHER_P3_CONFIG
#Debug
AIFM_Debug                                = AdvancedItemsFieldMoves::DEBUG_MENU

#===============================================================================
# Utility
#===============================================================================
class MoveHandlerHash
  def delete(sym)
    @hash.delete(sym) if sym && @hash[sym]
  end
end

def pbCheckForBadge(badge = -1)
  return true if badge < 0   # No badge requirement
  if (AdvancedItemsFieldMoves::BADGE_COUNT) ? $player.badge_count >= badge : $player.badges[badge-1]
    return true
  end
end

def pbCheckForSwitch(required_switches)
  return true if required_switches.length <= 0
  required_switches.each { |switch|
    return false unless $game_switches[switch]
  }
  true
end

def pbCheckForMove(moves)
  move_names = moves[:move_name]
  uses_pp = moves[:uses_pp]
  # Variables to track Pokémon with moves
  pkmn_with_move = []
  pkmn_move_pp = {}
  pkmn_with_zero_pp = []
  # Iterate through the player's party
  $player.party.each do |pkmn|
    next unless pkmn&.moves # Skip invalid Pokémon or those without moves
    puts " #{"\e[35mTesting\e[0m".ljust(20)} #{pkmn.name.ljust(15)} \e[35mfor moves\e[0m #{move_names}" if $DEBUG
    # Check each move
    pkmn.moves.each do |move|
      next unless move && move_names.include?(move.id)
      move_name = GameData::Move.get(move.id).name
      move_pp = move.pp
      total_pp = move.total_pp
      if move_pp > 0 || !uses_pp
        # Pokémon has the move with sufficient PP (or PP is not required)
        pkmn_with_move << pkmn unless pkmn_with_move.include?(pkmn)
        pkmn_move_pp[pkmn] ||= {}
        pkmn_move_pp[pkmn][move.id] = move_pp
        puts " └►#{"\e[32m[Valid]\e[0m".ljust(18)} #{pkmn.name.ljust(15)} has \e[33m#{move_name}\e[0m with \e[32m#{move_pp}\e[0m/#{total_pp} PP" if $DEBUG
      else
        # Pokémon has the move but insufficient PP
        pkmn_with_zero_pp << pkmn unless pkmn_with_zero_pp.include?(pkmn)
        puts " └►#{"\e[31m[Zero PP]\e[0m".ljust(15)} #{pkmn.name.ljust(15)} has \e[33m#{move_name}\e[0m with \e[31m#{move_pp}\e[0m/#{total_pp} PP" if $DEBUG
      end
    end
  end
  # Handle results
  if !pkmn_with_move.empty?
    # Return Pokémon with valid moves and their PP
    $aifm_move = 1
    return (pkmn_with_move.size == 1 ? pkmn_with_move.first : pkmn_with_move), pkmn_move_pp
  elsif pkmn_with_zero_pp.size == 1
    # Notify about a single Pokémon with insufficient PP
    pkmn = pkmn_with_zero_pp.first
    #pbMessage(_INTL("{1} doesn't have enough PP to use this move!", pkmn.name))
    puts "Return False: Only one Pokémon with insufficient PP" if $DEBUG
    $aifm_move = 2
    return false
  elsif pkmn_with_zero_pp.size > 1
    # Notify about multiple Pokémon with insufficient PP
    #pbMessage(_INTL("None of your Pokémon have enough PP left!"))
    puts "Return False: Multiple Pokémon with insufficient PP" if $DEBUG
    $aifm_move = 2
    return false
  else
    # No valid Pokémon or moves found
    vaild_move_names = move_names.map { |move_id| "[#{GameData::Move.get(move_id).name}]" }.join(" ")
    puts "No Pokémon found with the required move#{move_names.size > 1 ? 's' : ''}: #{vaild_move_names}" if $DEBUG
    $aifm_move = 0
    return nil
  end
end

def pbCanUseMove(move)
  return true if move[:allow_move_debug] && $DEBUG
  pbCheckForBadge(move[:move_needed_badge]) && pbCheckForSwitch(move[:move_needed_switches])
end

def pbCheckForItem(item)
  pbCheckForBadge(item[:item_needed_badge]) && pbCheckForSwitch(item[:item_needed_switches])
end

def pbCanUseItem(item)
  return true if item[:allow_item_debug] && $DEBUG
  $bag.has?(item[:internal_name]) && pbCheckForBadge(item[:item_needed_badge]) && pbCheckForSwitch(item[:item_needed_switches])
end

def ow_mount(pkmn)
  return {pkmn: pkmn, species: pkmn.species, form: pkmn.form, gender: pkmn.gender, shiny: pkmn.shiny?, shadow: pkmn.shadow}
end

#==============================[Global Variable]================================
$animation_item_skip    = false
$animation_move_skip    = false
ASK_TEXT_SKIP           = true
$aifm_move              = 0      # Move Found within PKMN

#===============================================================================
# Rock Smash Effect
#===============================================================================
def pbRockSmashRandomEncounter
  if $PokemonEncounters.encounter_triggered?(:RockSmash, false, false)
    $stats.rock_smash_battles += 1
    pbEncounter(:RockSmash)
  end
end

def pbRockSmash
  config_name = AIFM_RockSmash
  item = config_name[:internal_name]
  item_name = GameData::Item.get(item).name
  
  if pbCanUseItem(config_name) && config_name[:item]
    if ASK_TEXT_SKIP || pbConfirmMessage(_INTL("{1}", config_name[:text_item_comfirm], item_name))
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó el \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
      $stats.rock_smash_count ||= 0
      $stats.rock_smash_count += 1
      $stats.item_rock_smash_count ||= 0
      $stats.item_rock_smash_count += 1
      return true
    end
    return false
  end
  
  failMessage(config_name, item_name, nil)
end

#===============================================================================
# Cut
#===============================================================================
def pbCut
  config_name = AIFM_Cut
  item = config_name[:internal_name]
  item_name = GameData::Item.get(item).name
  
  if pbCanUseItem(config_name) && config_name[:item]
    if ASK_TEXT_SKIP || pbConfirmMessage(_INTL("{1}", config_name[:text_item_comfirm], item_name))
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó el \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
      $stats.cut_count ||= 0
      $stats.cut_count += 1
      $stats.item_cut_count ||= 0
      $stats.item_cut_count += 1
      return true
    end
    return false
  end
  
  failMessage(config_name, item_name, nil)
end


#===============================================================================
# Smash Event - [Rock Smash || Cut || Ice Smash]
#===============================================================================
#Overwrites Essentials Stuff
def pbSmashEvent(event)
  return if !event
  if event.name[/cuttree/i]
    pbSEPlay("Cut", 80)
  elsif event.name[/smashrock/i]
    pbSEPlay("Rock Smash")
  # elsif event.name[/BreakIce/i]
  #   pbSEPlay("Ice Smash")
  #   if AIFM_IceSmash[:allow_drop]
  #     roll_and_loot(DROP_ICE_BLOCK, 1, 0)
  #   end
  end
  pbMoveRoute(event, [PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_LEFT, PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_RIGHT, PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_UP, PBMoveRoute::WAIT, 2])
  pbWait(0.42)
  event.erase
  $PokemonMap&.addErasedEvent(event.id)
end

#===============================================================================
# Headbutt
#===============================================================================
def pbHeadbutt(event = nil)
  config_name = AIFM_Headbutt
  item = config_name[:internal_name]
  item_name = GameData::Item.get(item).name
  
  if pbCanUseItem(config_name) && config_name[:item]
    if ASK_TEXT_SKIP || pbConfirmMessage(_INTL("{1}", config_name[:text_item_comfirm], item_name))
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó el \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
      $stats.headbutt_count += 1
      $stats.item_headbutt_count += 1
      pbHeadbuttEffect(event)
      return true
    end
    return false
  end
  
  failMessage(config_name, item_name, nil)
end

def pbHeadbuttEffect(event = nil)
  pbSEPlay("Headbutt")
  pbShakeEvent if AIFM_Headbutt[:allow_shake]
  pbWait(1.0)
  event = $game_player.pbFacingEvent(true) if !event
  a = (event.x + (event.x / 24).floor + 1) * (event.y + (event.y / 24).floor + 1)
  a = (a * 2 / 5) % 10   # Even 2x as likely as odd, 0 is 1.5x as likely as odd
  b = $player.public_ID % 10   # Practically equal odds of each value
  chance = 1                 # ~50%
  if a == b                    # 10%
    chance = 8
  elsif a > b && (a - b).abs < 5   # ~30.3%
    chance = 5
  elsif a < b && (a - b).abs > 5   # ~9.7%
    chance = 5
  end
  if rand(10) >= chance
    pbMessage(_INTL("No. Nada..."))
  else
    enctype = (chance == 1) ? :HeadbuttLow : :HeadbuttHigh
    if pbEncounter(enctype)
      $stats.headbutt_battles += 1
    else
      pbMessage(_INTL("No. Nada..."))
    end
  end
end

#===============================================================================
# Shake Event - [Headbutt Tree]
#===============================================================================
def pbShakeEvent
  event = get_self
  pbMoveRoute(event, [PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_LEFT, PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_UP, PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_RIGHT, PBMoveRoute::WAIT, 2,
                      PBMoveRoute::TURN_DOWN, PBMoveRoute::WAIT, 2]) if event
end

#===============================================================================
# Sweet Scent - Not Needed - Everything need are in 02_Handler
#===============================================================================

#===============================================================================
# Strength
#===============================================================================
def pbStrength
  config_name = AIFM_Strength
  item = config_name[:internal_name]
  item_name = GameData::Item.get(item).name
  
  if pbCanUseItem(config_name) && config_name[:item]
    if ASK_TEXT_SKIP || pbConfirmMessage(_INTL("{1}", config_name[:text_item_comfirm], item_name))
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó el \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
      $stats.strength_count += 1
      $stats.item_strength_count += 1
      $PokemonMap.strengthUsed = true
      return true
    end
    return false
  end
  
  failMessage(config_name, item_name, nil)
end

#===============================================================================
# Flash
#====================================[Area]====================================#
def pbFlashArea
  # darkness = $game_temp.darkness_sprite
  # $PokemonGlobal.flashUsed = true
  # $stats.flash_count += 1
  # duration = 0.7
  # pbWait(duration) do |delta_t|
  #   darkness.radius = lerp(darkness.radiusMin, darkness.radiusMax, duration, delta_t)
  # end
  darkness = $game_temp.darkness_sprite
  return false if !darkness || darkness.disposed?
  duration = 0.7
  $PokemonGlobal.flashUsed = true
  $stats.flash_count += 1
  old_rad = darkness.radius
  pbWait(duration) do |delta_t|
    darkness.radius = lerp(old_rad, Settings::FLASH_CIRCLE_RADIUS, duration, delta_t)
  end
  darkness.radius = Settings::FLASH_CIRCLE_RADIUS
end

#===============================================================================
# Defog
#===============================================================================
# def pbDefog
#   if $game_screen.weather_type==:Fog
#     $game_screen.weather(:None, 9, 20)
#     Graphics.update
#     Input.update
#     pbUpdateSceneMap
#     return true
#   end
#   return false
# end

#===============================================================================
# Weather Push
#===============================================================================
# def pbWeatherCheck(weather)
#   if ($DEBUG && Input.press?(Input::CTRL))
#     $game_player.through = false
#     return false
#   end
#   if $game_screen.weather_type == weather
#     if !$bag.has?(weather.to_s.upcase + "ITEM")
#       if pbWeatherMessage(weather)
#         return if weather == :None
#         case $game_player.direction
#         when 2 # facing down, player came from up
#           pbMoveRoute($game_player, [PBMoveRoute::UP])
#         when 4 # facing left, player came from right
#           pbMoveRoute($game_player, [PBMoveRoute::RIGHT])
#         when 6 # facing right, player came from left
#           pbMoveRoute($game_player, [PBMoveRoute::LEFT])
#         when 8 # facing up, player came from down
#           pbMoveRoute($game_player, [PBMoveRoute::DOWN])
#         end
#       end
#     end
#     return true
#   end
# end

# def pbWeatherMessage(weather)
#   pbMessage(_INTL("{1}", AIFM_WPush[weather]))
# end

#===============================================================================
# [Auto Weather]
# Weatername(Enable weather distance, Disable weather distance +1, Looking for player directional)
#===============================================================================
class Game_Map
  alias weather_update update
  def update
    weather_update
    $game_map.events.each_value do |event|
      match = event.name.match(/(\w+)\((\d+),(\d+),(\w+)\)/)
      if match
        weather_type = match[1].to_sym
        start_distance = match[2].to_i
        end_distance = match[3].to_i
        direction = match[4].downcase.to_sym
        # Calculate distance between event and player
        case direction
        when :up
          distance = event.y - $game_player.y
          in_range = ($game_player.x == event.x && distance >= 0 && distance <= start_distance)
          out_of_range = ($game_player.x == event.x && [end_distance, end_distance + 1].include?(distance.abs) && $game_player.direction == 8)
        when :left
          distance = event.x - $game_player.x
          in_range = ($game_player.y == event.y && distance >= 0 && distance <= start_distance)
          out_of_range = ($game_player.y == event.y && [end_distance, end_distance + 1].include?(distance.abs) && $game_player.direction == 4)
        when :right
          distance = $game_player.x - event.x
          in_range = ($game_player.y == event.y && distance >= 0 && distance <= start_distance)
          out_of_range = ($game_player.y == event.y && [end_distance, end_distance + 1].include?(distance.abs) && $game_player.direction == 6)
        when :down
          distance = $game_player.y - event.y
          in_range = ($game_player.x == event.x && distance >= 0 && distance <= start_distance)
          out_of_range = ($game_player.x == event.x && [end_distance, end_distance + 1].include?(distance.abs) && $game_player.direction == 2)
        end
        # Trigger weather effect
        if in_range
          if $game_screen.weather_type != weather_type
            $old_weather = [$game_screen.weather_type, $game_screen.weather_max, $game_screen.weather_type == :None ? 0 : 100]
            $game_screen.weather(weather_type,1,0)
          end
        elsif out_of_range
          # Restore weather if player is facing away from event
          $game_screen.weather($old_weather[0], $old_weather[1], 1) if $old_weather
          $old_weather = nil
        end
      end
    end
  end
end

#===============================================================================
# Weather Flutes / Gadget
#===============================================================================
# def pbWeatherMoveUse(move)
#   move_index = AIFM_Weather[:move_name].index(move)
#   if move_index
#     weather_type = AIFM_Weather[:weather_type][move_index]
#     $game_screen.weather(weather_type, 9, 20)
#   end
# end

#===============================================================================
# Camouflage
#===============================================================================
# def pbVanishCheck
#   wait_time = 1
#   percentage = $PokemonSystem.camouflaged
#   stage_count = 9
#   opacity_step = (100.0 - percentage) / stage_count
#   opacities = (1..stage_count).map do |i|
#     (100 - (opacity_step * i)).to_i
#   end
#   opacities.map! { |percentage| (percentage / 100.0) * 255 }
#   opacities = $PokemonGlobal.camouflage ? opacities.reverse : opacities

#   # Set the opacity of the player and following Pokémon
#   pbMoveRoute($game_player, opacities.map { |opacity| [PBMoveRoute::OPACITY, opacity, PBMoveRoute::WAIT, wait_time] }.flatten)
#   pbMoveRoute(FollowingPkmn.get_event, opacities.map { |opacity| [PBMoveRoute::OPACITY, opacity, PBMoveRoute::WAIT, wait_time] }.flatten) if PluginManager.findDirectory("Following Pokemon EX")

#   # Toggle camouflage
#   $PokemonGlobal.camouflage = !$PokemonGlobal.camouflage
#   pbWait(0.01 * stage_count)
# end

# def turnVisible
#   pbVanishCheck
# end

#===============================================================================
# Surf
#===============================================================================
def pbSurf
  config_name = AIFM_Surf
  item = config_name[:internal_name]
  item_name = GameData::Item.get(item).name
  move_basic = config_name[:move_name]
  pp_check = config_name[:uses_pp]
  # Check if the player can use the required item
  if pbCanUseItem(config_name) && config_name[:item]
    if ASK_TEXT_SKIP || pbConfirmMessage(_INTL("{1}", config_name[:text_item_comfirm], item_name))
      # pbCallItemAnimation(config_name) unless $PokemonSystem.animation_item == 1
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó la \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
      $stats.item_surf_count += 1
      pbStartSurfing
      return true
    end
    return false
    # Check if the player can use the required move
  elsif config_name[:move]
    moves = []
    pkmn, moves_and_pp = pbCheckForMove(config_name)
    if pkmn
      moves_and_pp.each do |pkmn, move_data|
        move_data.each do |move_id, pp|
          next unless move_id
          move_name = GameData::Move.get(move_id).name
          max_pp = GameData::Move.get(move_id).total_pp
          moves.push([move_id, move_name, $player.party.index(pkmn), { pp: pp, max_pp: max_pp }])
        end
      end
      if pbCanUseMove(config_name)
        # If there are multiple moves, use SelectMoveMenu
        if moves.length > 1 && ($PokemonSystem.moves_option == 0 || config_name[:uses_pp])
          pbMessage(_INTL("{1}", config_name[:text_move_confirm_plus]))
          # Call pbSelectMoveMenu and store the result in selected_move
          selected_pokemon, selected_move = pbSelectMoveMenu(moves, pp_check)
          # If no move is selected, return false
          return false unless selected_move
          # Extract the Pokémon and move ID from selected_move
          pkmn = selected_pokemon
          move_id = selected_move
          move_name = GameData::Move.get(move_id).name
        else
          # Handle the case where there is only one move available
          pkmn = pkmn.is_a?(Array) ? pkmn.first : pkmn
          move_id = moves.first[0]
          move_name = GameData::Move.get(move_id).name
          return false unless ASK_TEXT_SKIP || pbConfirmMessage(_INTL("{1}", config_name[:text_move_confirm], move_name))
        end
        pbCallMoveAnimation(pkmn) unless $PokemonSystem.animation_move == 1
        pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó \\c[1]{2}\\c[0]!", pkmn.name, move_name)) unless $PokemonSystem.animation_move == 1
        $stats.move_surf_count += 1
        mount = ow_mount(pkmn)
        $PokemonGlobal.base_pkmn_surf = mount
        move = pkmn.moves.find { |m| m.id == move_id}
        move.pp -= 1 if pp_check && move
        pbStartSurfing
        return true
      end
    end
  end
  move_id = ((moves.any? unless moves.nil?) ? moves.first[0] : move_basic[0])
  move_name = GameData::Move.get(move_id).name
  failMessage(config_name, item_name, move_name)
end

def pbSurfing
  pbCancelVehicles
  turnVisible
  surfbgm = GameData::Metadata.get.surf_BGM
  pbCueBGM(surfbgm, 0.5) if surfbgm
  pbStartSurfing
end

#===============================================================================
# Rock Climbing
#===============================================================================
def pbStartRockClimb
  pbCancelVehicles
  $PokemonGlobal.rockclimb = true
  $game_player.through = true
  $stats.rockclimb_count += 1
  pbUpdateVehicle
  if $game_player.direction == 2
    $game_player.always_on_top = true
  end
  $game_temp.rockclimb_base_coords = $map_factory.getFacingCoords($game_player.x, $game_player.y, $game_player.direction)
  $game_player.jumpForward
end

def pbTraverseRockClimb?
  terrain = $game_player.pbTerrainTag
  if ($DEBUG && Input.press?(Input::CTRL)) || !terrain.rockclimb
    $PokemonGlobal.rockclimb = false
    $game_player.through = false
    $game_temp.ending_rockclimb = false
    pbWait(0.12)
    $game_player.always_on_top = false
    return
  end
  x_offset = ($game_player.direction == 4) ? -1 : ($game_player.direction == 6) ? 1 : 0
  y_offset = ($game_player.direction == 8) ? -1 : ($game_player.direction == 2) ? 1 : 0
  case $game_player.direction
  when 2
    if terrain.rockclimb && $game_map.terrain_tag($game_player.x, $game_player.y + 1).rockclimb
      $game_player.move_down
      $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdDown], $game_player.x, $game_player.y - 1.3, true, 0)
      $scene.spriteset.addUserAnimation(AIFM_RockClimb[:DebrisId], $game_player.x, $game_player.y - 0.7, true, 0)
    else
      pbEndRockClimb(x_offset, y_offset)
    end
  when 4
    if $game_map.terrain_tag($game_player.x - 1, $game_player.y).rockclimb || $game_map.terrain_tag($game_player.x - 1, $game_player.y - 1).rockclimb || $game_map.terrain_tag($game_player.x - 1, $game_player.y + 1).rockclimb
      if $game_map.terrain_tag($game_player.x - 1, $game_player.y).rockclimb
        $game_player.move_left
        $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdLeft], $game_player.x + 0.8, $game_player.y, true, 1)
      elsif $game_map.terrain_tag($game_player.x - 1, $game_player.y - 1).rockclimb
        $game_player.move_upper_left
        $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdLeft], $game_player.x + 0.8, $game_player.y, true, 1)
      elsif $game_map.terrain_tag($game_player.x - 1, $game_player.y + 1).rockclimb
        $game_player.move_lower_left
        $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdLeft], $game_player.x + 1, $game_player.y - 0.5, true, 1)
      end
      $scene.spriteset.addUserAnimation(AIFM_RockClimb[:DebrisId], $game_player.x + 0.5, $game_player.y, true, 1)
    else
      pbEndRockClimb(x_offset, y_offset)
    end
    if terrain.rockclimb && $game_player.pbFacingTerrainTag.rockclimb
    end
  when 6
    if $game_map.terrain_tag($game_player.x + 1, $game_player.y).rockclimb || $game_map.terrain_tag($game_player.x + 1, $game_player.y - 1).rockclimb || $game_map.terrain_tag($game_player.x + 1, $game_player.y + 1).rockclimb
      if $game_map.terrain_tag($game_player.x + 1, $game_player.y).rockclimb
        $game_player.move_right
        $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdRight], $game_player.x - 0.8, $game_player.y, true, 1)
      elsif $game_map.terrain_tag($game_player.x + 1, $game_player.y - 1).rockclimb
        $game_player.move_upper_right
        $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdRight], $game_player.x - 0.8, $game_player.y, true, 1)
      elsif $game_map.terrain_tag($game_player.x + 1, $game_player.y + 1).rockclimb
        $game_player.move_lower_right
        $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdRight], $game_player.x - 1, $game_player.y - 0.5, true, 1)
      end
      $scene.spriteset.addUserAnimation(AIFM_RockClimb[:DebrisId], $game_player.x - 0.5, $game_player.y , true, 1)
    else
      pbEndRockClimb(x_offset, y_offset)
    end
  when 8
    if terrain.rockclimb && $game_map.terrain_tag($game_player.x, $game_player.y - 1).rockclimb
      $game_player.move_up
      $scene.spriteset.addUserAnimation(AIFM_RockClimb[:MoveIdUp], $game_player.x, $game_player.y + 1.3, true, 1)
      $scene.spriteset.addUserAnimation(AIFM_RockClimb[:DebrisId], $game_player.x, $game_player.y + 0.7, true, 1)
    else
      pbEndRockClimb(x_offset, y_offset)
    end
  end
end

def pbTraverseRockClimb
  terrain = $game_player.pbTerrainTag
  if ($DEBUG && Input.press?(Input::CTRL)) || !terrain.rockclimb
    $PokemonGlobal.rockclimb = false
    $game_player.through = false
    return
  end
  terrain = $game_player.pbTerrainTag
  if terrain.rockclimb
    $PokemonGlobal.rockclimb = true
    $game_player.through = true
  else
    $PokemonGlobal.rockclimb = false
    $game_player.through = false
    $game_temp.ending_rockclimb = false
    pbWait(0.12)
    $game_player.always_on_top = false
  end
end

def pbEndRockClimb(_xOffset, _yOffset)
  return false if !$PokemonGlobal.rockclimb
  return false if $game_player.pbFacingTerrainTag.can_climb
  base_coords = [$game_player.x, $game_player.y]
  if $game_player.jumpForward
        $game_temp.rockclimb_base_coords = base_coords
    $game_temp.ending_rockclimb = true
    $game_player.always_on_top = false
    return true
  end
  return false
end

def pbRockClimb
  config_name = AIFM_RockClimb
  item = config_name[:internal_name]
  item_name = GameData::Item.get(item).name
  
  if pbCanUseItem(config_name) && config_name[:item]
    if ASK_TEXT_SKIP || pbConfirmMessage(_INTL("{1}", config_name[:text_item_comfirm], item_name))
      pbMessage(_INTL("¡\\c[1]{1}\\c[0] usó el \\c[1]{2}\\c[0]!", $player.name, item_name)) unless $PokemonSystem.animation_item == 1
      $stats.item_rockclimb_count += 1
      pbStartRockClimb
      return true
    end
    return false
  end
  
  failMessage(config_name, item_name, nil)
end

# #===============================================================================
# # Error Message
# #===============================================================================
def failMessage(config_name, item_name, move_name, event_name = nil, extra = nil)
  item_badge = config_name[:text_item_badge].to_s + (config_name[:item_needed_badge] > 1 ? "s" : "")
  move_badge = config_name[:text_move_badge].to_s + (config_name[:move_needed_badge] > 1 ? "s" : "")
  suffix = extra ? "_#{extra}" : ""
  # Both item and move required
  if config_name[:item] && config_name[:move]
    if !$bag.has?(config_name[:internal_name]) && !pbCheckForItem(config_name) && $aifm_move == 0
      puts "Fail (Both - 1)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:"missing_element_both#{suffix}"], item_name, move_name, event_name))
      $aifm_move = -1
    elsif ($bag.has?(config_name[:internal_name]) && !pbCheckForItem(config_name))
      puts "Fail (Both - 2)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name))
    elsif $aifm_move == 1
      puts "Fail (Both - 3)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name))
      $aifm_move = -1
    elsif $aifm_move == 2
      puts "Fail (Both - 4)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:missing_PP]))
      $aifm_move = -1
    end
    return false
  end

  # Only item required
  if config_name[:item] && !config_name[:move]
    if !$bag.has?(config_name[:internal_name]) && !pbCheckForItem(config_name)
      puts "Fail (Item - 1)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:"missing_element_item#{suffix}"], item_name, event_name)) if config_name[:show_message]
    else
      puts "Fail (Item - 2)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:missing_bagde_item], config_name[:item_needed_badge], item_badge, item_name)) if config_name[:show_message]
    end
    return false
  end

  # Only move required
  if !config_name[:item] && config_name[:move]
    if $aifm_move == 0
      puts "Fail (Move - 3)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:"missing_element_move#{suffix}"], move_name, event_name))
      $aifm_move = -1
    elsif $aifm_move == 1
      puts "Fail (Move - 1)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:missing_bagde_move], config_name[:move_needed_badge], move_badge, move_name))
      $aifm_move = -1
    elsif $aifm_move == 2
      puts "Fail (Move - 2)" if $DEBUG
      pbMessage(_INTL("{1}", config_name[:missing_PP]))
      $aifm_move = -1
    end
    return false
  end
  puts "Fail (Nothing - 1)" if $DEBUG
  pbMessage(_INTL("{1}", config_name[:"both_disable#{suffix}"], event_name))
  return false # Default return value
end
