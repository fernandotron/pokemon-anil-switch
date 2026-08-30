#===============================================================================
# Panorama Mover 1.1
#===============================================================================
# The Sleeping Leonhart
# Version 1.0
# 23-8-2007
#===============================================================================
# This little script allow you to move the Panorama.
# You can move the panorama with this command
# $game_map.move_panorama(x,y).
# Else you can compile the AUTOSCROLL_MAP hash for an auto movement in
# specificated map.
#===============================================================================
module Panorama_Mover
    # AUTOSCROLL_MAP = {map_id => [x movement, y movement]
    AUTOSCROLL_MAP = { 1 => [2,1]
    }
    # this is for the map not declarated in the hash don't touch if you dont know
    # what are you doing
    AUTOSCROLL_MAP.default = [0,0]
end


class Game_Map
  attr_reader   :panorama_ox
  attr_reader   :panorama_oy

  alias tsl_game_map_setup setup

  def setup(map_id)
    tsl_game_map_setup(map_id)
    @panorama_ox = 0
    @panorama_oy = 0
  end

  def move_panorama(x,y)
    @panorama_ox += x
    @panorama_oy += y
  end

  alias tsl_game_map_update update
  def update
    tsl_game_map_update
    move_panorama(Panorama_Mover::AUTOSCROLL_MAP[@map_id][0],Panorama_Mover::AUTOSCROLL_MAP[@map_id][1])
  end
end


class Spriteset_Map
  
  alias tsl_spriteset_map_update update
  def update
    tsl_spriteset_map_update
    @panorama.ox += $game_map.panorama_ox
    @panorama.oy += $game_map.panorama_oy
  end
end