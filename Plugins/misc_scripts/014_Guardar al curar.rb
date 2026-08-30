MenuHandlers.add(:options_menu, :guardar_al_curar, {
"name"        => _INTL("Guardar al curar"),
"order"       => 33,
"type"        => EnumOption,
"parameters"  => [_INTL("Sí"), _INTL("No")],
"description" => _INTL("Elige si quieres guardar la partida al curar a tu equipo automáticamente."),
"get_proc"    => proc { next $PokemonSystem.guardar_al_curar },
"set_proc"    => proc { |value, _scene| $PokemonSystem.guardar_al_curar = value }
})


class PokemonSystem
	attr_accessor :guardar_al_curar
	
	alias guardar_al_curar_initialize initialize
	def initialize
		guardar_al_curar_initialize
		@guardar_al_curar = 1
	end
	
	def guardar_al_curar
		return @guardar_al_curar || 1
	end

	def guardar_al_curar?
		return @guardar_al_curar == 0
	end
	
	def guardar_al_curar=(value)
		@guardar_al_curar ||= 1
		@guardar_al_curar = value
	end
end