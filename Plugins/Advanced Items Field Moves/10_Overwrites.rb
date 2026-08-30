#===============================================================================
# Overworld Line [157-170] Overwrites
#===============================================================================
# Auto-move the player over waterfalls and ice
EventHandlers.add(:on_step_taken, :auto_move_player,
  proc { |event|
    next if !$scene.is_a?(Scene_Map)
    next if event != $game_player
    currentTag = $game_player.pbTerrainTag
    if currentTag.waterfall_crest || currentTag.waterfall ||
       $PokemonGlobal.descending_waterfall || $PokemonGlobal.ascending_waterfall
      pbTraverseWaterfall
    elsif currentTag.whirlpool || $PokemonGlobal.crossing_whirlpool
      pbTraverseWhirlpool
    elsif currentTag.lavafall_crest || currentTag.lavafall ||
       $PokemonGlobal.descending_lavafall || $PokemonGlobal.ascending_lavafall
      pbTraverseLavafall
    elsif currentTag.lavaswirl || $PokemonGlobal.crossing_lavaswirl
      pbTraverseLavaSwirl
    elsif currentTag.ice || $PokemonGlobal.ice_sliding
      pbSlideOnIce
    elsif currentTag.rockclimb || $PokemonGlobal.rockclimb
      pbTraverseRockClimb
    end
  }
)

#===============================================================================
# Scene_Map Line [165-230] Interact with events (Camoflage)
#===============================================================================
# class Scene_Map
#   def update
#     loop do
#       pbMapInterpreter.update
#       $game_player.update
#       updateMaps
#       $game_system.update
#       $game_screen.update
#       break if !$game_temp.player_transferring
#       transfer_player(false)
#       break if $game_temp.transition_processing
#     end
#     updateSpritesets
#     if $game_temp.title_screen_calling
#       SaveData.mark_values_as_unloaded
#       $scene = pbCallTitle
#       return
#     end
#     if $game_temp.transition_processing
#       $game_temp.transition_processing = false
#       if $game_temp.transition_name == ""
#         Graphics.transition
#       else
#         Graphics.transition(40, "Graphics/Transitions/" + $game_temp.transition_name)
#       end
#     end
#     return if $game_temp.message_window_showing
#     if !pbMapInterpreterRunning? && !$PokemonGlobal.forced_movement?
#       if Input.trigger?(Input::USE)
#         $game_temp.interact_calling = true
#       elsif Input.trigger?(Input::BACK)
#         if !$game_system.menu_disabled && !$game_player.moving?
#           $game_temp.menu_calling = true
#           $game_temp.menu_beep = true
#         end
#       elsif Input.trigger?(Input::SPECIAL)
#         $game_temp.ready_menu_calling = true if !$game_player.moving?
#       elsif Input.press?(Input::F9)
#         $game_temp.debug_calling = true if $DEBUG
#       end
#     end
#     if !$game_player.moving?
#       if $game_temp.menu_calling
#         call_menu
#       elsif $game_temp.debug_calling
#         call_debug
#       elsif $game_temp.ready_menu_calling
#         $game_temp.ready_menu_calling = false
#         $game_player.straighten
#         pbUseKeyItem
#       elsif $game_temp.interact_calling
#         $game_temp.interact_calling = false
#         triggered = false
#         # Try to trigger an event the player is standing on, and one in front of
#         # the player
#         if !$game_temp.in_mini_update
#           triggered ||= $game_player.check_event_trigger_here([0])
#           triggered ||= $game_player.check_event_trigger_there([0, 2]) if !triggered
#         end
#         # Try to trigger an interaction with a tile
# #        if !triggered
#           $game_player.straighten
#           EventHandlers.trigger(:on_player_interact)
# #        end
#       end
#     end
#   end
# end

#===============================================================================
# PlayerMetadata adding lifting animation
#===============================================================================
module GameData
  class PlayerMetadata
    SCHEMA["WalkLiftingCharset"] = [:walk_lifting_charset, "s"]

    class << self
      alias original_editor_properties editor_properties
      def editor_properties
        original_editor_properties + [
          ["WalkLiftingCharset",  CharacterProperty, _INTL("Charset used while the player is lifting. Uses WalkCharset if undefined.")],
        ]
      end
    end

    alias aifm_initialize initialize
    def initialize(hash)
      aifm_initialize(hash)
      @walk_lifting_charset = hash[:walk_lifting_charset]
    end

    def walk_lifting_charset
      return @walk_lifting_charset || @walk_charset
    end

  end
end
#===============================================================================
# Game_Event Line[133-140] added SenseTruth and Lift Keywords
#===============================================================================
# class Game_Event < Game_Character
#   def over_trigger?
#     return false if @character_name != "" && !@through
#     config_name = AIFM_SenseTruth
#     hiddenKeywords    = config_name[:senseHidden]
#     illionsKeywords   = config_name[:senseIllusion]
#     pkmnKeyword       = config_name[:sensePKMN]
#     check             = @event.name[/hiddenitem/i] ||
#                         @event.name[/pickup/i] ||
#                         @event.name[/#{pkmnKeyword}/i] ||
#                         hiddenKeywords.any? { |keyword| @event.name[/#{keyword}/i] }
#     if @trigger == 0 # Action Button trigger
#       check ||= illionsKeywords.any? { |keyword| @event.name[/#{keyword}/i] }
#     end
#     return false if check unless $PokemonGlobal.lifting
#     each_occupied_tile do |i, j|
#       return true if self.map.passable?(i, j, 0, $game_player)
#     end
#     return false
#   end
# end

#===============================================================================
# Music Sheets to Music Book when fill
#===============================================================================
# MenuHandlers.add(:debug_menu, :fill_bag, {
#   "name"        => _INTL("Fill Bag"),
#   "parent"      => :items_menu,
#   "description" => _INTL("Empties the Bag and then fills it with a certain number of every item."),
#   "effect"      => proc {
#     params = ChooseNumberParams.new
#     params.setRange(1, Settings::BAG_MAX_PER_SLOT)
#     params.setInitialValue(1)
#     params.setCancelValue(0)
#     qty = pbMessageChooseNumber(_INTL("Choose the number of items."), params)
#     if qty > 0
#       $bag.clear
#       # NOTE: This doesn't simply use $bag.add for every item in turn, because
#       #       that's really slow when done in bulk.
#       pocket_sizes = Settings::BAG_MAX_POCKET_SIZE
#       bag = $bag.pockets   # Called here so that it only rearranges itself once
#       GameData::Item.each do |i|
#         next if !pocket_sizes[i.pocket - 1] || pocket_sizes[i.pocket - 1] == 0
#         next if pocket_sizes[i.pocket - 1] > 0 && bag[i.pocket].length >= pocket_sizes[i.pocket - 1]
#         if i.flags.include?("MusicSheet")
#           $bag.music_book.add(i.id, qty)
#         else
#           item_qty = (i.is_important?) ? 1 : qty
#           bag[i.pocket].push([i.id, item_qty])
#         end
#       end
#       # NOTE: Auto-sorting pockets don't need to be sorted afterwards, because
#       #       items are added in the same order they would be sorted into.
#       pbMessage(_INTL("The Bag was filled with {1} of each item.", qty))
#     end
#   }
# })

# MenuHandlers.add(:debug_menu, :empty_bag, {
#   "name"        => _INTL("Empty Bag"),
#   "parent"      => :items_menu,
#   "description" => _INTL("Remove all items from the Bag."),
#   "effect"      => proc {
#     $bag.clear
#     $bag.music_book.clear
#     pbMessage(_INTL("The Bag was cleared."))
#   }
# })
#===============================================================================
# Add a ButtonOption functions to the option menu to have a sub menu
#===============================================================================
# class Window_PokemonOption < Window_DrawableCommand
#   def drawItem(index, _count, rect)
#     rect = drawCursor(index, rect)
#     sel_index = self.index
#     # Draw option's name
#     optionname = (index == @options.length) ? ($Back ? _INTL("Atrás") : _INTL("Cerrar")) : @options[index].name
#     optionwidth = (@options[index].is_a?(EnumOption) ||
#                    @options[index].is_a?(NumberOption) ||
#                    @options[index].is_a?(SliderOption)) ? rect.width * 9 / 20 : rect.width

#     pbDrawShadowText(self.contents, rect.x, rect.y, optionwidth, rect.height, optionname,
#                      (index == sel_index) ? SEL_NAME_BASE_COLOR : self.baseColor,
#                      (index == sel_index) ? SEL_NAME_SHADOW_COLOR : self.shadowColor)
#     return if index == @options.length
#     # Draw option's values
#     case @options[index]
#     when EnumOption
#       if @options[index].values.length > 1
#         totalwidth = 0
#         @options[index].values.each do |value|
#           totalwidth += self.contents.text_size(value).width
#         end
#         spacing = (rect.width - rect.x - optionwidth - totalwidth) / (@options[index].values.length - 1)
#         spacing = 0 if spacing < 0
#         xpos = optionwidth + rect.x
#         ivalue = 0
#         @options[index].values.each do |value|
#           pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
#                            (ivalue == self[index]) ? SEL_VALUE_BASE_COLOR : self.baseColor,
#                            (ivalue == self[index]) ? SEL_VALUE_SHADOW_COLOR : self.shadowColor)
#           xpos += self.contents.text_size(value).width
#           xpos += spacing
#           ivalue += 1
#         end
#       else
#         pbDrawShadowText(self.contents, rect.x + optionwidth, rect.y, optionwidth, rect.height,
#                          optionname, self.baseColor, self.shadowColor)
#       end
#     when NumberOption
#       value = _INTL("Tipo {1}/{2}", @options[index].lowest_value + self[index],
#                     @options[index].highest_value - @options[index].lowest_value + 1)
#       xpos = optionwidth + (rect.x * 2)
#       pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
#                        SEL_VALUE_BASE_COLOR, SEL_VALUE_SHADOW_COLOR, 1)
#     when SliderOption
#       value = sprintf(" %d", @options[index].highest_value)
#       sliderlength = rect.width - rect.x - optionwidth - self.contents.text_size(value).width
#       xpos = optionwidth + rect.x
#       self.contents.fill_rect(xpos, rect.y - 2 + (rect.height / 2), sliderlength, 4, self.baseColor)
#       self.contents.fill_rect(
#         xpos + ((sliderlength - 8) * (@options[index].lowest_value + self[index]) / @options[index].highest_value),
#         rect.y - 8 + (rect.height / 2),
#         8, 16, SEL_VALUE_BASE_COLOR
#       )
#       value = (@options[index].lowest_value + self[index]).to_s
#       xpos += (rect.width - rect.x - optionwidth) - self.contents.text_size(value).width
#       pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
#                        SEL_VALUE_BASE_COLOR, SEL_VALUE_SHADOW_COLOR)
#     else
#       value = @options[index].values[self[index]]
#       xpos = optionwidth + rect.x
#       pbDrawShadowText(self.contents, xpos, rect.y, optionwidth, rect.height, value,
#                        SEL_VALUE_BASE_COLOR, SEL_VALUE_SHADOW_COLOR)
#     end
#   end

#   def update
#     oldindex = self.index
#     @value_changed = false
#     super
#     dorefresh = (self.index != oldindex)
#     if self.active && self.index < @options.length
#       if @options[self.index].is_a?(ButtonOption)
#         if Input.trigger?(Input::USE)
#           self[self.index] = @options[self.index].prev(self[self.index])
#           dorefresh = true
#           @value_changed = true
#         end
#       else
#         if Input.repeat?(Input::LEFT)
#           self[self.index] = @options[self.index].prev(self[self.index])
#           dorefresh = true
#           @value_changed = true
#         elsif Input.repeat?(Input::RIGHT)
#           self[self.index] = @options[self.index].next(self[self.index])
#           dorefresh = true
#           @value_changed = true
#         end
#       end
#     end
#     refresh if dorefresh
#   end
# end
