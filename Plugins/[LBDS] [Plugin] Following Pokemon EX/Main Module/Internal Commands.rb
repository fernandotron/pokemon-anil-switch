module FollowingPkmn
  #-----------------------------------------------------------------------------
  @@can_refresh = false
  #-----------------------------------------------------------------------------
  # Checks if the Following Pokemon is active and following the player
  #-----------------------------------------------------------------------------
  def self.active?; return @@can_refresh; end
  #-----------------------------------------------------------------------------
  # Checks whether Following Pokemon data should be accessed or no
  #-----------------------------------------------------------------------------
  def self.can_check?
    return false if !$game_temp || !$PokemonGlobal || !$player
    return false if !$game_temp.respond_to?(:followers) || !$game_temp.followers
    return false if !$PokemonGlobal.respond_to?(:followers) || !$PokemonGlobal.followers
    return true
  end
  #-----------------------------------------------------------------------------
  # Refresh Following Pokemon's visibility when Following the player
  #-----------------------------------------------------------------------------
  def self.refresh_internal
    $PokemonGlobal.follower_toggled = true if $PokemonGlobal && $PokemonGlobal.follower_toggled.nil?
    if !FollowingPkmn.can_check? || !$player || !$player.first_able_pokemon || ($PokemonGlobal.follower_toggled == false)
      @@can_refresh = false
      return
    end
    old_refresh = @@can_refresh
    refresh     = true
    first_pkmn  = FollowingPkmn.get_pokemon
    if first_pkmn
      ret = EventHandlers.trigger_2(:following_pkmn_appear, first_pkmn)
      refresh = ret unless ret == -1 || ret.nil?
    end
    @@can_refresh = refresh
    $PokemonGlobal.call_refresh[1] = true if old_refresh != @@can_refresh && $PokemonGlobal.respond_to?(:call_refresh) && $PokemonGlobal.call_refresh
  end
  #-----------------------------------------------------------------------------
  # Raises The Current Following Pokemon's Happiness by 3-5 and
  # checks for hold item
  #-----------------------------------------------------------------------------
  def self.increase_time
    return if !FollowingPkmn.can_check?
    $PokemonGlobal.time_taken += 1
    friendship_time = FollowingPkmn::FRIENDSHIP_TIME_TAKEN * Graphics.frame_rate
    item_time = FollowingPkmn::ITEM_TIME_TAKEN * Graphics.frame_rate
    FollowingPkmn.get_pokemon&.changeHappiness("levelup") if ($PokemonGlobal.time_taken % friendship_time) == 0
    $PokemonGlobal.follower_hold_item = true if (($PokemonGlobal.time_taken > item_time) && FollowingPkmn::CAN_FIND_ITEMS)
  end
  #-----------------------------------------------------------------------------
  # Script Command for Following Pokémon finding an item in the field
  #-----------------------------------------------------------------------------
  def self.item(item, quantity = 1, message = nil)
    return false if !FollowingPkmn.can_check?
    return false if !$PokemonGlobal.follower_hold_item
    pokename = FollowingPkmn.get_pokemon&.name
    message = _INTL("{1} parece que lleva algo equipado...") if nil_or_empty?(message)
    pbMessage(_INTL(message, pokename))
    item = GameData::Item.get(item)
    return false if !item || quantity < 1
    itemname = (quantity > 1) ? item.name_plural : item.name
    pocket = item.pocket
    move   = item.move
    if $bag.add(item, quantity)   # If item can be picked up
      meName = (item.is_key_item?) ? "Key item get" : "Item get"
      if item == :LEFTOVERS
        pbMessage(_INTL("\\me[{1}]¡{3} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename))
      elsif item == :DNASPLICERS
        pbMessage(_INTL("\\me[{1}]¡{3} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename))
      elsif item.is_machine?   # TM or HM
        pbMessage(_INTL("\\me[{1}]¡{4} encontró \\c[1]{2} {3}\\c[0]!\\wtnp[30]", meName, itemname, GameData::Move.get(move).name, pokename))
      elsif quantity>1
        pbMessage(_INTL("\\me[{1}]¡{4} encontró {2} \\c[1]{3}\\c[0]!\\wtnp[30]", meName, quantity, itemname, pokename))
      elsif itemname.starts_with_vowel?
        pbMessage(_INTL("\\me[{1}]¡{3} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename))
      else
        pbMessage(_INTL("\\me[{1}]¡{3} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", meName, itemname, pokename))
      end
      pbMessage(_INTL("Has puesto {1} en el\\nbolsillo <icon=bagPocket{2}>\\c[1]{3}\\c[0].",
         itemname, pocket, PokemonBag.pocket_names[pocket]))
      $PokemonGlobal.follower_hold_item = false
      $PokemonGlobal.time_taken         = 0
      return true
    end
    # Can't add the item
    if item == :LEFTOVERS
      pbMessage(_INTL("¡{1} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname))
    elsif item == :DNASPLICERS
      pbMessage(_INTL("¡{1} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname))
    elsif item.is_machine?   # TM or HM
      pbMessage(_INTL("¡{1} encontró \\c[1]{2} {3}\\c[0]!\\wtnp[30]", pokename, itemname, GameData::Move.get(move).name))
    elsif quantity>1
      pbMessage(_INTL("¡{1} encontró {2} \\c[1]{3}\\c[0]!\\wtnp[30]", pokename, quantity, itemname))
    elsif itemname.starts_with_vowel?
      pbMessage(_INTL("¡{1} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname))
    else
      pbMessage(_INTL("¡{1} encontró \\c[1]{2}\\c[0]!\\wtnp[30]", pokename, itemname))
    end
    pbMessage(_INTL("Pero tu Mochila está llena..."))
    return false
  end
  #-----------------------------------------------------------------------------
  # Check if the Following Pokemon can be spoken to, or not
  #-----------------------------------------------------------------------------
  def self.can_talk?(interact = false)
    return false if !FollowingPkmn::CAN_TALK_WITH_POKEMON
    return false if !FollowingPkmn.can_check?
    return false if !$game_temp || $game_temp.in_battle || $game_temp.in_menu
    return false if FollowingPkmn.get_event.move_route_forcing
    return false if $game_player.move_route_forcing
    facing = pbFacingTile
    if !FollowingPkmn.active? || !$game_map.passable?(facing[1], facing[2], $game_player.direction, $game_player)
      if interact
        $game_player.straighten
        EventHandlers.trigger(:on_player_interact)
      end
      return false
    end
    return true
  end
  #-----------------------------------------------------------------------------
end
