#===============================================================================
# Additional Game Stats
#===============================================================================
class GameStats < GameStats

  #attr_accessor :rock_smash_count
  attr_accessor :item_rock_smash_count, :move_rock_smash_count
  #attr_accessor :cut_count
  attr_accessor :item_cut_count, :move_cut_count
  attr_accessor :ice_count, :item_ice_count, :move_ice_count, :ice_drop_count
  #attr_accessor :headbutt_count
  attr_accessor :item_headbutt_count, :move_headbutt_count
  attr_accessor :sweetscent_count, :item_sweetscent_count, :move_sweetscent_count
  #attr_accessor :strength_push_count
  attr_accessor :strength_count, :item_strength_count, :move_strength_count
  #attr_accessor :flash_count
  attr_accessor :item_flash_count, :move_flash_count
  attr_accessor :defog_count, :item_defog_count, :move_defog_count
  attr_accessor :camouflage_count, :item_camouflage_count, :move_camouflage_count
  #attr_accessor :surf_count
  attr_accessor :item_surf_count, :move_surf_count
  #attr_accessor :dive_count
  attr_accessor :item_dive_count, :move_dive_count
  attr_accessor :dive_ascend_count, :item_dive_ascend_count, :move_dive_ascend_count
  attr_accessor :dive_descend_count, :item_dive_descend_count, :move_dive_descend_count
  #attr_accessor :waterfall_count
  attr_accessor :item_waterfall_count, :move_waterfall_count
  attr_accessor :whirlpool_cross_count, :item_whirlpool_cross_count, :move_whirlpool_cross_count
  #attr_accessor :fly_count
  attr_accessor :item_fly_count, :move_fly_count
  attr_accessor :dig_count, :item_dig_count, :move_dig_count
  attr_accessor :teleport_count, :item_teleport_count, :move_teleport_count
  attr_accessor :rockclimb_count, :item_rockclimb_count, :move_rockclimb_count
  attr_accessor :rockclimb_ascend_count, :item_rockclimb_ascend_count, :move_rockclimb_ascend_count
  attr_accessor :rockclimb_descend_count, :item_rockclimb_descend_count, :move_rockclimb_descend_count

  attr_accessor :lavasurf_count, :item_lavasurf_count, :move_lavasurf_count, :distance_lavasurfed
  attr_accessor :lavafall_count, :item_lavafall_count, :move_lavafall_count, :lavafalls_descended
  attr_accessor :lavaswirl_cross_count, :item_lavaswirl_cross_count, :move_lavaswirl_cross_count

  attr_accessor :lift_count, :item_lift_count, :move_lift_count
  attr_accessor :sense_count, :item_sense_count, :move_sense_count

  attr_accessor :weather_count, :item_weather_count, :move_weather_count    #Count
  attr_accessor :weather_clear_count      #Clear Sky | None
  attr_accessor :weather_rain_count       #Rain
  attr_accessor :weather_storm_count      #Storm
  attr_accessor :weather_snow_count       #Snow
  attr_accessor :weather_blizzard_count   #Blizzard
  attr_accessor :weather_sandstorm_count  #Sandstorm
  attr_accessor :weather_heavyrain_count  #Heavy Rain
  attr_accessor :weather_sunny_count      #Sunny
  attr_accessor :weather_fog_count        #Fog

  attr_accessor :secret_power_count, :item_secret_power_count, :move_secret_power_count

  attr_accessor :temp_count

  alias aifm_initialize initialize
  def initialize
    aifm_initialize
#   Rocksmash
    @item_rock_smash_count                  = 0
    @move_rock_smash_count                  = 0
#   Cut
    @item_cut_count                         = 0
    @move_cut_count                         = 0
    # @ice_count                              = 0
    # @item_ice_count                         = 0
    # @move_ice_count                         = 0
    # @ice_drop_count                         = 0
#   Headbutt
    # @item_headbutt_count                    = 0
    @move_headbutt_count                    = 0
    # @sweetscent_count                       = 0
    # @item_sweetscent_count                  = 0
    @move_sweetscent_count                  = 0
    @strength_count                         = 0
    @item_strength_count                    = 0
    @move_strength_count                    = 0
#   Flash
    @item_flash_count                       = 0
    @move_flash_count                       = 0
    # @defog_count                            = 0
    # @item_defog_count                       = 0
    @move_defog_count                       = 0
    # @camouflage_count                       = 0
    # @item_camouflage_count                  = 0
    # @move_camouflage_count                  = 0
#   Surf
    @item_surf_count                        = 0
    @move_surf_count                        = 0
#   Dive
    @dive_ascend_count                      = 0
    # @item_dive_ascend_count                 = 0
    @move_dive_ascend_count                 = 0
    @dive_descend_count                     = 0
    # @item_dive_descend_count                = 0
    @move_dive_descend_count                = 0
#   Waterfall
    # @item_waterfall_count                   = 0
    @move_waterfall_count                   = 0
    # @whirlpool_cross_count                  = 0
    # @item_whirlpool_cross_count             = 0
    @move_whirlpool_cross_count             = 0
#   Fly
    # @item_fly_count                         = 0
    @move_fly_count                         = 0
    @dig_count                              = 0
    # @item_dig_count                         = 0
    @move_dig_count                         = 0
    @teleport_count                         = 0
    # @item_teleport_count                    = 0
    @move_teleport_count                    = 0
    @rockclimb_count                        = 0
    @item_rockclimb_count                   = 0
    @move_rockclimb_count                   = 0
    @rockclimb_ascend_count                 = 0
    @item_rockclimb_ascend_count            = 0
    @move_rockclimb_ascend_count            = 0
    @rockclimb_descend_count                = 0
    @item_rockclimb_descend_count           = 0
    @move_rockclimb_descend_count           = 0
    # @lavasurf_count                         = 0
    # @item_lavasurf_count                    = 0
    # @move_lavasurf_count                    = 0
    # @distance_lavasurfed                    = 0
    # @lavafall_count                         = 0
    # @item_lavafall_count                    = 0
    # @move_lavafall_count                    = 0
    # @lavaswirl_cross_count                  = 0
    # @lavafalls_descended                    = 0
    # @item_lavaswirl_cross_count             = 0
    # @move_lavaswirl_cross_count             = 0

    # @lift_count                             = 0
    # @item_lift_count                        = 0
    # @move_lift_count                        = 0
    # @sense_count                            = 0
    # @item_sense_count                       = 0
    # @move_sense_count                       = 0

    # @weather_count                          = 0
    # @item_weather_count                     = 0
    # @weather_clear_count                    = 0
    # @weather_rain_count                     = 0
    # @weather_storm_count                    = 0
    # @weather_snow_count                     = 0
    # @weather_blizzard_count                 = 0
    # @weather_sandstorm_count                = 0
    # @weather_heavyrain_count                = 0
    # @weather_sunny_count                    = 0
    # @weather_fog_count                      = 0
    # @move_weather_count                     = 0

    # @secret_power_count                     = 0
    # @item_secret_power_count                = 0
    # @move_secret_power_count                = 0

    @temp_count                             = 0
  end

  def distance_moved
    return @distance_walked + @distance_cycled + @distance_surfed + @distance_lavasurfed
  end
end
