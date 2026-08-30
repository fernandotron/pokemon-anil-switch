module FollowingPkmn
  #-----------------------------------------------------------------------------
  # Script Command for getting the Following Pokemon event and corresponding
  # Follower Data
  #-----------------------------------------------------------------------------
  def self.get
    return nil if !FollowingPkmn.can_check?
    $game_temp.followers.each_follower do |event, follower|
      next if !follower || !follower.following_pkmn?
      return [event, follower]
    end
    if ($PokemonGlobal&.follower_toggled != false) && $player&.first_able_pokemon && $game_player
      $PokemonGlobal.followers.delete_if { |f| f.name == "FollowingPkmn" } if $PokemonGlobal&.followers
      $game_temp.followers.remove_follower_by_name("FollowingPkmn") rescue nil
      $game_temp.followers.add_follower($game_player, "FollowingPkmn", FollowingPkmn::FOLLOWER_COMMON_EVENT) rescue nil
      $game_temp.followers.each_follower do |event, follower|
        next if !follower || !follower.following_pkmn?
        return [event, follower]
      end
    end
    return nil
  end
  #-----------------------------------------------------------------------------
  # Script Command for getting the Following Pokemon event
  #-----------------------------------------------------------------------------
  def self.get_event
    return nil if !FollowingPkmn.can_check?
    ret = FollowingPkmn.get
    return ret.is_a?(Array) ? ret[0] : nil
  end
  #-----------------------------------------------------------------------------
  # Script Command for getting the Following Pokemon FollowerData
  #-----------------------------------------------------------------------------
  def self.get_data
    return nil if !FollowingPkmn.can_check?
    ret = FollowingPkmn.get
    return ret.is_a?(Array) ? ret[1] : nil
  end
  #-----------------------------------------------------------------------------
  # Script Command for getting the Pokemon Object of the Following Pokemon
  #-----------------------------------------------------------------------------
  def self.get_pokemon
    return nil if !FollowingPkmn.can_check?
    return $player.first_able_pokemon
  end
  #-----------------------------------------------------------------------------
  # Script Command for checking whether the current follower is airborne
  #-----------------------------------------------------------------------------
  def self.airborne_follower?
    return false if !FollowingPkmn.can_check?
    pkmn = FollowingPkmn.get_pokemon
    return false if !pkmn
    return true if pkmn.hasType?(:FLYING)
    return true if pkmn.hasAbility?(:LEVITATE)
    return true if FollowingPkmn::LEVITATING_FOLLOWERS.any? { |s| s == pkmn.species || s.to_s == "#{pkmn.species}_#{pkmn.form}" }
    return false
  end
  #-----------------------------------------------------------------------------
  # Script Command for checking if a swimming sprite exists for the Pokemon
  #-----------------------------------------------------------------------------
  def self.has_swimming_sprite?
    return false if !FollowingPkmn.can_check?
    pkmn = FollowingPkmn.get_pokemon
    return false if !pkmn
    
    # Check if swimming sprite exists
    shiny = pkmn.shiny?
    shiny = pkmn.superVariant if (pkmn.respond_to?(:superVariant) && !pkmn.superVariant.nil? && pkmn.superShiny?)
    
    # Check for swimming sprite first
    folder = shiny ? "Swimming Shiny" : "Swimming"
    ret = GameData::Species.check_graphic_file("Graphics/Characters/", pkmn.species, pkmn.form,
                                               pkmn.gender, shiny, pkmn.shadow, folder)
    return true if !nil_or_empty?(ret)
    
    # Check for levitate sprite (for airborne Pokemon over water)
    folder = shiny ? "Levitates Shiny" : "Levitates"
    ret = GameData::Species.check_graphic_file("Graphics/Characters/", pkmn.species, pkmn.form,
                                               pkmn.gender, shiny, pkmn.shadow, folder)
    return !nil_or_empty?(ret)
  end
  #-----------------------------------------------------------------------------
  # Script Command for checking whether the current follower is waterborne
  #-----------------------------------------------------------------------------
  def self.waterborne_follower?
    return false if !FollowingPkmn.can_check?
    pkmn = FollowingPkmn.get_pokemon
    return false if !pkmn
    
    # Always follow if Pokemon is water type
    return true if pkmn.hasType?(:WATER)
    
    # Always follow if the Pokemon has a swimming or levitate sprite available
    # This takes priority over the exceptions list
    return true if FollowingPkmn.has_swimming_sprite?
    
    # Check exceptions list before checking airborne
    return false if FollowingPkmn::SURFING_FOLLOWERS_EXCEPTIONS.any? do |s|
      s == pkmn.species || s.to_s == "#{pkmn.species}_#{pkmn.form}"
    end
    
    # Follow if the Pokemon flies or levitates (and not in exceptions)
    return true if FollowingPkmn.airborne_follower?
    
    return false
  end
  #-----------------------------------------------------------------------------
  # Script Command for checking whether the current follower should use swimming sprites
  #-----------------------------------------------------------------------------
  def self.should_use_swimming_sprites?
    return false if !FollowingPkmn.can_check? || !FollowingPkmn.active?
    # Use swimming sprites only when player is actually surfing AND the follower is on water
    return false if !$PokemonGlobal.surfing || !FollowingPkmn.waterborne_follower?
    
    # Check if the follower is actually on a water tile
    event = FollowingPkmn.get_event
    return false if !event
    
    # Check the terrain tag of the follower's current position
    terrain_tag = $map_factory.getTerrainTag(event.map.map_id, event.x, event.y)
    return terrain_tag.can_surf
  end
  #-----------------------------------------------------------------------------
  # Forcefully refresh Following Pokemon sprite with animation (if specified)
  #-----------------------------------------------------------------------------
  def self.refresh(anim = false)
    return if !FollowingPkmn.can_check?
    first_pkmn = FollowingPkmn.get_pokemon
    return if !first_pkmn
    FollowingPkmn.refresh_internal
    ret = FollowingPkmn.active?
    event = FollowingPkmn.get_event
    if ret
      FollowingPkmn.change_sprite(first_pkmn)
      if anim
        pbSEPlay("pkmn_ball") rescue nil
        if event
          anim_id = FollowingPkmn::ANIMATION_COME_OUT rescue 30
          if anim_id && anim_id > 0
            if defined?(FollowerSprites) && FollowerSprites.respond_to?(:set_animation)
              FollowerSprites.set_animation(anim_id)
            elsif defined?($scene) && $scene.respond_to?(:spriteset)
              $scene.spriteset(event.map.map_id)&.addUserAnimation(anim_id, event.x, event.y, true, 1) rescue nil
            end
          end
        end
      end
    else
      if anim && event
        anim_id = FollowingPkmn::ANIMATION_COME_IN rescue 29
        if anim_id && anim_id > 0
          if defined?(FollowerSprites) && FollowerSprites.respond_to?(:set_animation)
            FollowerSprites.set_animation(anim_id)
          elsif defined?($scene) && $scene.respond_to?(:spriteset)
            $scene.spriteset(event.map.map_id)&.addUserAnimation(anim_id, event.x, event.y, true, 1) rescue nil
          end
        end
        pbSEPlay("Recall") rescue nil
      end
      FollowingPkmn.remove_sprite
    end
    FollowingPkmn.move_route([(ret ? PBMoveRoute::STEP_ANIME_ON : PBMoveRoute::STEP_ANIME_OFF)]) if FollowingPkmn::ALWAYS_ANIMATE
    event&.calculate_bush_depth
    $PokemonGlobal.time_taken = 0 if !ret
    return ret
  end
  #-----------------------------------------------------------------------------
  # Forcefully refresh Following Pokemon sprite with animation (if specified)
  #-----------------------------------------------------------------------------
  def self.remove_sprite
    if FollowingPkmn.get_event
      FollowingPkmn.get_event.character_name = ""
      FollowingPkmn.get_event.character_hue  = 0
      FollowingPkmn.get_event.transparent   = true if FollowingPkmn.get_event.respond_to?(:transparent=)
      FollowingPkmn.get_event.opacity       = 0 if FollowingPkmn.get_event.respond_to?(:opacity=)
    end
    if FollowingPkmn.get_data
      FollowingPkmn.get_data.character_name  = ""
      FollowingPkmn.get_data.character_hue   = 0
      FollowingPkmn.get_data.visible         = false
    end
  end
  #-----------------------------------------------------------------------------
  # Set the Following Pokemon sprite to a different Pokemon
  #-----------------------------------------------------------------------------
  def self.change_sprite(pkmn)
    return if !pkmn
    shiny = pkmn.shiny?
    shiny = pkmn.superVariant if (pkmn.respond_to?(:superVariant) && !pkmn.superVariant.nil? && pkmn.superShiny?)
    swimming = FollowingPkmn.should_use_swimming_sprites?
    fname = nil
    if GameData::Species.respond_to?(:ow_sprite_filename)
      fname = GameData::Species.ow_sprite_filename(pkmn.species, pkmn.form, pkmn.gender, shiny, pkmn.shadow, swimming) rescue nil
    end
    if !fname || fname.empty? || fname.include?("/000")
      candidates = []
      prefix = shiny ? "Followers shiny" : "Followers"
      candidates << "#{prefix}/#{pkmn.species}_#{pkmn.form}" if pkmn.form && pkmn.form > 0
      candidates << "#{prefix}/#{pkmn.species}"
      candidates << "Followers/#{pkmn.species}_#{pkmn.form}" if pkmn.form && pkmn.form > 0
      candidates << "Followers/#{pkmn.species}"
      candidates << "#{pkmn.species}_#{pkmn.form}" if pkmn.form && pkmn.form > 0
      candidates << "#{pkmn.species}"
      
      candidates.each do |cand|
        if pbResolveBitmap("Graphics/Characters/" + cand) || pbResolveBitmap(cand)
          fname = cand
          break
        end
      end
      fname ||= "Followers/#{pkmn.species}"
    end
    fname = fname.to_s.sub(/^Graphics\/Characters\//i, "").sub(/\.(png|gif|bmp)$/i, "")
    
    event = FollowingPkmn.get_event
    data = FollowingPkmn.get_data
    changed = false
    if event
      changed = true if event.character_name != fname
      event.character_name = fname
      event.character_hue  = 0
      event.transparent   = false if event.respond_to?(:transparent=)
      event.opacity       = 255 if event.respond_to?(:opacity=)
      if (event.x == 0 && event.y == 0) || (event.x == $game_player.x && event.y == $game_player.y)
        behind_dir = 10 - $game_player.direction
        target = $map_factory.getFacingTile(behind_dir, $game_player) rescue nil
        tx = target ? target[1] : $game_player.x
        ty = target ? target[2] : $game_player.y
        event.moveto(tx, ty)
        event.direction = $game_player.direction
      end
    end
    if data
      changed = true if data.character_name != fname
      data.character_name  = fname
      data.character_hue   = 0
      data.visible         = true
      data.invisible_after_transfer = false
      data.x               = event.x if event
      data.y               = event.y if event
      data.direction       = event.direction if event
    end
    if event&.move_route_forcing
      hue = pkmn.respond_to?(:superHue) && pkmn.superShiny? ? pkmn.superHue : 0
      event.character_hue = hue
      data.character_hue  = hue if data
    end
    if changed && $game_temp&.followers
      $game_temp.followers.update_events rescue nil
    end
  end
  #-----------------------------------------------------------------------------
end
