ADD_POKERIDER_SHORTCUT_IN_MENU = true

ItemHandlers::UseFromBag.add(:POKERIDER, proc { |_item|
  pokerider(true)
  next $game_temp.fly_destination ? 2 : 0
})

ItemHandlers::UseInField.add(:POKERIDER, proc { |_item|
  pokerider unless $game_temp.fly_destination
  pokerider_fly
  next true
})

def pb_can_fly_pokerider?(show_messages = false)
  return false unless $bag.has?(:POKERIDER)

  unless $game_player.can_map_transfer_with_follower?
    pbMessage(_INTL('No se puede usar cuando hay alguien contigo.')) if show_messages
    return false
  end
  unless $game_map.metadata&.outdoor_map
    pbMessage(_INTL('No se puede usar aquí.')) if show_messages
    return false
  end
  # if defined?($game_player.on_stair?) && $game_player.on_stair?
  #   pbMessage(_INTL('No se puede usar aquí.')) if show_messages
  #   return false
  # end
  true
end

def pokerider_fly
  return false unless pb_can_fly_pokerider?(true)
  return false if $game_temp.fly_destination.nil?

  name = $player.name
  # pbMessage(_INTL('¡{1} usó su {2}!', name, GameData::Item.get(:POKERIDER).name))
  $stats.fly_count += 1
  pbFadeOutIn do
    pbSEPlay('Fly')
    # Correccion para escaleras laterales
    if $game_player.respond_to?(:clear_stair_data)
      $game_player.clear_stair_data
      $game_player.instance_variable_set(:@view_offset_x, 0)
      $game_player.instance_variable_set(:@view_offset_y, 0)
    end
    $game_temp.fly_destination[0]   = 216 if $game_temp.fly_destination[0] == 19 && $game_switches[331]
    $game_temp.player_new_map_id    = $game_temp.fly_destination[0]
    $game_temp.player_new_x         = $game_temp.fly_destination[1]
    $game_temp.player_new_y         = $game_temp.fly_destination[2]
    $game_temp.player_new_direction = 2
    $game_temp.fly_destination = nil
    $game_player.through = false
    $game_player.always_on_top = false
    pbDismountBike
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
    pbMapInterpreter&.command_210
    yield if block_given?
    pbWait(0.25)
  end
  pbEraseEscapePoint
  true
end

def pokerider(bag = false)
  ret = false
  pbFadeOutIn do
    scene = PokemonRegionMap_Scene.new(-1, false)
    screen = PokemonRegionMapScreen.new(scene)
    ret = screen.pbStartFlyScreen
    $game_temp.fly_destination = ret if ret
    next 99_999 if ret && bag # Ugly hack to make Bag scene not reappear if flying
  end
  ret ? true : false
  # return pbFlyToNewLocation
end
