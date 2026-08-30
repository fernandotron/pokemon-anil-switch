#===============================================================================
# Adds Rock Climb to TerrainTag
#===============================================================================
module GameData
  class TerrainTag
    attr_reader :rockclimb   # The main part only, not the crest
    attr_reader :can_climb
    attr_reader :whirlpool

    attr_reader :can_lavasurf
    attr_reader :lavafall   # The main part only, not the crest
    attr_reader :lavafall_crest
    attr_reader :lavaswirl
    attr_reader :can_lavafish

    alias aifm_initialize initialize
    def initialize(hash)
      aifm_initialize(hash)
      @rockclimb              = hash[:rockclimb]              || false
      @can_climb              = hash[:can_climb]              || false
      @whirlpool              = hash[:whirlpool]              || false

      @can_lavasurf           = hash[:can_lavasurf]           || false
      @lavafall               = hash[:lavafall]               || false
      @lavafall_crest         = hash[:lavafall_crest]         || false
      @lavaswirl              = hash[:lavaswirl]              || false
      @can_lavafish           = hash[:can_lavafish]           || false

    end

    alias name real_name

    def can_surf_freely
      return @can_surf && !@waterfall && !@waterfall_crest && !@whirlpool
    end

    def can_lavasurf_freely
      return @can_lavasurf && !@lavafall && !@lavafall_crest && !@lavaswirl
    end

    def can_climb
      return @can_climb
    end
  end
end

#===============================================================================
# More TerrainTag
#===============================================================================
GameData::TerrainTag.register({
  :id                     => :RockClimb,
  :id_number              => AdvancedItemsFieldMoves::ROCKCLIMB_CONFIG[:number_rockclimb],
  :can_climb              => true,
  :rockclimb              => true
})

# GameData::TerrainTag.register({
#   :id                     => :Whirlpool,
#   :id_number              => AdvancedItemsFieldMoves::WHIRLPOOL_CONFIG[:number_whirlpool],
#   :can_surf               => true,
#   :whirlpool              => true
# })

# GameData::TerrainTag.register({
#   :id                     => :Lava,
#   :id_number              => AdvancedItemsFieldMoves::LAVASURF_CONFIG[:number_lavasurf],
#   :can_lavasurf           => true,
#   :can_lavafish           => true,
#   :battle_environment     => :MovingWater
# })

# GameData::TerrainTag.register({
#   :id                     => :Lavafall,
#   :id_number              => AdvancedItemsFieldMoves::LAVAFALL_CONFIG[:number_lavafall],
#   :can_lavasurf           => true,
#   :lavafall               => true
# })

# GameData::TerrainTag.register({
#   :id                     => :LavafallCrest,
#   :id_number              => AdvancedItemsFieldMoves::LAVAFALL_CONFIG[:number_lavafall_crest],
#   :can_lavasurf           => true,
#   :can_lavafish           => true,
#   :lavafall_crest         => true
# })

# GameData::TerrainTag.register({
#   :id                     => :"Lava Swirl",
#   :id_number              => AdvancedItemsFieldMoves::LAVASWIRL_CONFIG[:number_lavaswirl],
#   :can_lavasurf           => true,
#   :lavaswirl              => true
# })
