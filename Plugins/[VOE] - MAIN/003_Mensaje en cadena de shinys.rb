MenuHandlers.add(:options_menu, :mensaje_shinys, {
  "name"        => _INTL("Mensaje cadenas"),
  "order"       => 42,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Que cada vez que derrotes a un Pokémon salvaje se te indique cuántos llevas para las cadenas de variocolor."),
  "get_proc"    => proc { next $PokemonSystem.mensaje_shinys },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.mensaje_shinys = value }
})


class PokemonSystem
    attr_accessor :mensaje_shinys
    
    alias mensaje_shinys_initialize initialize unless method_defined?(:mensaje_shinys_initialize)
    def initialize
        mensaje_shinys_initialize
        @mensaje_shinys = 1
    end
    
    def mensaje_shinys
        return @mensaje_shinys || 1
    end
    
    def mensaje_shinys=(value)
        @mensaje_shinys = 1 if !@mensaje_shinys
        @mensaje_shinys = value
    end
end