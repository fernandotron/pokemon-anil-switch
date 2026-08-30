#-------------------------------------------------------------------------------
# Expose follower_sprites attribute of Spriteset_Map
#-------------------------------------------------------------------------------
class Spriteset_Global
  attr_reader :follower_sprites
end

#-------------------------------------------------------------------------------
# Add Reflections to Following Pokemon sprite
#-------------------------------------------------------------------------------
class Sprite_Character
  def set_reflection(viewport, event)
    @reflection = Sprite_Reflection.new(self, viewport) if !@reflection
  end
end



class FollowerSprites
  #-----------------------------------------------------------------------------
  # Updating the refresh method to allow clearing of base event in all maps,
  # add reflections and prevent crash when base map/event is deleted
  #-----------------------------------------------------------------------------
  alias __followingpkmn__refresh refresh unless method_defined?(:__followingpkmn__refresh)
  def refresh(*args)
    ret = __followingpkmn__refresh(*args)
    return ret if !FollowingPkmn.can_check?
    event = FollowingPkmn.get_event
    @sprites.each do |spr|
      next if !FollowingPkmn.get_data&.following_pkmn?
      spr.set_reflection(@viewport, event) rescue nil
    end
    data = FollowingPkmn.get_data
    if data && data.event_id && data.event_id > 0
      $map_factory.maps.each { |map|
        map&.events&.[](data.event_id)&.erase if data.original_map_id == map&.events&.[](data.event_id)&.map_id
      }
    end
    ret
  end

  #-----------------------------------------------------------------------------
  # Adding DayNight and Status condition pulsing effect to Following Pokemon
  # sprite
  #-----------------------------------------------------------------------------
  unless method_defined?(:__followingpkmn__update)
    alias __followingpkmn__update update rescue nil
  end

  def update(*args)
    if respond_to?(:__followingpkmn__update)
      __followingpkmn__update(*args) rescue nil
    else
      cur_update = $game_temp&.followers&.last_update rescue nil
      if cur_update != @last_update
        refresh rescue nil
        @last_update = cur_update
      end
      @sprites.each { |sprite| sprite.update rescue nil } if @sprites
    end
    return if !FollowingPkmn.active? rescue true
    return if !@sprites || !@sprites.is_a?(Array)
    @sprites.each_with_index do |sprite, i|
      next if !$PokemonGlobal || !$PokemonGlobal.followers || !$PokemonGlobal.followers[i] || !$PokemonGlobal.followers[i].following_pkmn?
      first_pkmn = FollowingPkmn.get_pokemon rescue nil
      next if !first_pkmn
      if first_pkmn.status == :NONE || !FollowingPkmn::APPLY_STATUS_TONES
        sprite.color.set(0, 0, 0, 0) rescue nil
        $game_temp.status_pulse = [50.0, 50.0, 150.0, (100/(Graphics.frame_rate * 2.0))] if $game_temp rescue nil
        next
      end
      status_tone = nil
      status_tone = FollowingPkmn.const_get("TONE_#{first_pkmn.status}") if FollowingPkmn.const_defined?("TONE_#{first_pkmn.status}")
      next if !status_tone || !status_tone.all? {|s| s > 0}
      if $game_temp && $game_temp.status_pulse
        $game_temp.status_pulse[0] += $game_temp.status_pulse[3]
        $game_temp.status_pulse[3] *= -1 if $game_temp.status_pulse[0] < $game_temp.status_pulse[1] ||
                                              $game_temp.status_pulse[0] > $game_temp.status_pulse[2]
        sprite.color.set(status_tone[0], status_tone[1], status_tone[2], $game_temp.status_pulse[0]) rescue nil
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Add emote animation to Following Pokemon
  #-----------------------------------------------------------------------------
  def set_animation(anim_id)
    return unless anim_id && anim_id > 0
    event = FollowingPkmn.get_event rescue nil
    return unless event
    @sprites.each do |spr|
      next if spr.character != event
      spr.character.animation_id = anim_id rescue nil
    end
  end

  def self.set_animation(anim_id)
    return unless anim_id && anim_id > 0
    event = FollowingPkmn.get_event rescue nil
    return unless event
    if defined?($scene) && $scene.respond_to?(:spriteset)
      spriteset = $scene.spriteset(event.map.map_id) rescue nil
      spriteset&.addUserAnimation(anim_id, event.x, event.y, true, 1) rescue nil
    end
    sprites = $scene.spritesetGlobal.follower_sprites rescue nil
    sprites&.set_animation(anim_id) if sprites rescue nil
  end
  #-----------------------------------------------------------------------------
end
