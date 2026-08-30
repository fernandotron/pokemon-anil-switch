class PokemonGlobalMetadata
    attr_accessor :max_party_size

    alias init_permalocke_party_size initialize
    def initialize
        init_permalocke_party_size
        @max_party_size = Settings::MAX_PARTY_SIZE
    end
end

module Kernel
  def max_party_size
    return Settings::MAX_PARTY_SIZE rescue 6 if !defined?(ChallengeModes) || !defined?(ChallengeModes.on?) || !ChallengeModes.on?(:PERMALOCKE)
    if defined?($PokemonGlobal) && $PokemonGlobal
      $PokemonGlobal.max_party_size ||= (Settings::MAX_PARTY_SIZE rescue 6)
      return $PokemonGlobal.max_party_size
    end
    return (Settings::MAX_PARTY_SIZE rescue 6)
  end
  module_function :max_party_size
end

class Module
  def max_party_size
    Kernel.max_party_size
  end
end

class Object
  def max_party_size
    Kernel.max_party_size
  end
end