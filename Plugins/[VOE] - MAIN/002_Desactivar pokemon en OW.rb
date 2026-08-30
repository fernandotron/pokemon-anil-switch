MenuHandlers.add(:options_menu, :salvajes_visibles_en_ow, {
  "name"        => _INTL("Ver salvajes"),
  "order"       => 41,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Elige si quieres ver a los Pokémon salvajes por el mapa."),
  "get_proc"    => proc { next $PokemonSystem.salvajes_visibles_en_ow },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.salvajes_visibles_en_ow = value }
})


class PokemonSystem
    attr_accessor :salvajes_visibles_en_ow
    
    alias salvajes_visibles_en_ow_initialize initialize unless method_defined?(:salvajes_visibles_en_ow_initialize)
    def initialize
        salvajes_visibles_en_ow_initialize
        @salvajes_visibles_en_ow = 0
    end
    
    def salvajes_visibles_en_ow
        return @salvajes_visibles_en_ow || 0
    end

    def salvajes_visibles_en_ow?
        return salvajes_visibles_en_ow == 0
    end
    
    def salvajes_visibles_en_ow=(value)
        @salvajes_visibles_en_ow = value || 0
    end
end


def pb_salvajes_visibles_en_ow?
    return $PokemonSystem.salvajes_visibles_en_ow?
end