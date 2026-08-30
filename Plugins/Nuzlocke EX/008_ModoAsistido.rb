class PokemonGlobalMetadata
    attr_accessor :sacred_ash_count
    alias init_sacred_ash initialize
    def initialize
        init_sacred_ash
        @sacred_ash_count ||= 0
    end
end