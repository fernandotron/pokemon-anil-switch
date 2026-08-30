# if PluginManager.installed?("Following Pokemon EX")
#   class Scene_Map
#     #-----------------------------------------------------------------------------
#     # Check for Toggle input and update Following Pokemon's time_taken for to
#     # track the happiness increase and hold item
#     #-----------------------------------------------------------------------------
#     alias __followingpkmn__update update unless method_defined?(:__followingpkmn__update)
#     def update(*args)
#       __followingpkmn__update(*args)
#       if defined?(FollowingPkmn::TOGGLE_FOLLOWER_KEY) && FollowingPkmn::TOGGLE_FOLLOWER_KEY &&
#          ((Input.const_defined?(FollowingPkmn::TOGGLE_FOLLOWER_KEY) &&
#           Input.trigger?(Input.const_get(FollowingPkmn::TOGGLE_FOLLOWER_KEY))) ||
#           Input.triggerex?(FollowingPkmn::TOGGLE_FOLLOWER_KEY))
#         FollowingPkmn.toggle
#         return
#       end
#       return if !FollowingPkmn.active?
#       FollowingPkmn.increase_time
#       if defined?(FollowingPkmn::CYCLE_PARTY_KEY) && FollowingPkmn::CYCLE_PARTY_KEY &&
#          ((Input.const_defined?(FollowingPkmn::CYCLE_PARTY_KEY) &&
#           Input.trigger?(Input.const_get(FollowingPkmn::CYCLE_PARTY_KEY))) ||
#           Input.triggerex?(FollowingPkmn::CYCLE_PARTY_KEY))
#         FollowingPkmn.toggle_off
#         loop do
#           pkmn = $player.party.shift
#    			  $player.party.push(pkmn)
#           $PokemonGlobal.follower_toggled = true
#           if FollowingPkmn.active?
#             $PokemonGlobal.follower_toggled = false
#             break
#           end
#           $PokemonGlobal.follower_toggled = false
#         end
#         FollowingPkmn.toggle_on
#         return
#       end
#     end
#   end
# end
