ItemHandlers::UseInField.add(:DIPLOMA, proc { |item|
  pbFadeOutIn(99999) {
    s = Sprite.new
    s.bitmap = Bitmap.new("Graphics/Pictures/diploma")
    s.z = 99999
    s.opacity = 0  # Empezar transparente
    
    # Fade in
    16.times do |i|
      s.opacity += 16
      Graphics.update
    end
    
    # Esperar input
    loop do
      Input.update
      Graphics.update
      
      if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        break
      end
    end
    
    # Fade out
    16.times do |i|
      s.opacity -= 16
      Graphics.update
    end
    
    s.dispose
  }
  
  next 1
})


ItemHandlers::UseOnPokemon.add(:TRUFA, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon? || pkmn.genderless?
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
  end
  if pkmn.changeGender
    scene.pbDisplay(_INTL("¡{1} ha cambiado a género {2}!", pkmn.name, pkmn.gender_name))
    next true
  end
  next false
})



def teleport_player(map_id, x, y, direction = 2)
  if $scene.is_a?(Scene_Map)
    $game_temp.player_new_map_id    = map_id
    $game_temp.player_new_x         = x
    $game_temp.player_new_y         = y
    $game_temp.player_new_direction = direction
    $scene.transfer_player
  else
    pbCancelVehicles
    $map_factory.setup(map_id)
    $game_player.moveto(x, y)
    $game_player.turn_down
    $game_map.update
    $game_map.autoplay
  end
  $game_player.through = false
  $game_player.always_on_top = false
  $game_map.refresh
end

DESBUGUEADOR_MAP_BLACKLIST = [172, 173, 208, 209, 210]
ItemHandlers::UseFromBag.add(:DESBUGUEADOR, proc { |_item|
  next 0 if DESBUGUEADOR_MAP_BLACKLIST.include?($game_map.map_id) || $game_map.metadata&.outdoor_map
  teleport_player(28, 29, 10)
  next 2
})

ItemHandlers::UseInField.add(:DESBUGUEADOR, proc { |_item|
  next false if DESBUGUEADOR_MAP_BLACKLIST.include?($game_map.map_id) || $game_map.metadata&.outdoor_map
  teleport_player(28, 29, 10)
  next true
})