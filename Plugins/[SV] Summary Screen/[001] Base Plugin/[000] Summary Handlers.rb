#-------------------------------------------------------------------------------
# Pokemon Summary handlers.
# (Decapitalises and changes page names from Modular UI Scenes)
#-------------------------------------------------------------------------------

# Info page.
UIHandlers.add(:summary, :page_info, { 
  "name"      => "Información",
  "suffix"    => "info",
  "order"     => 10,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageOne }
})

# Memo page.
UIHandlers.add(:summary, :page_memo, {
  "name"      => "Notas Entrenador",
  "suffix"    => "memo",
  "order"     => 20,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageTwo }
})

# Stat page.
UIHandlers.add(:summary, :page_skills, {
  "name"      => "Estadísticas",
  "suffix"    => "skills",
  "order"     => 30,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageThree }
})

# Moves page.
UIHandlers.add(:summary, :page_moves, {
  "name"      => "Movimientos",
  "suffix"    => "moves",
  "order"     => 40,
  "options"   => [:moves, :tms],
  "layout"    => proc { |pkmn, scene| scene.drawPageFour }
})

# Ribbons page.
# UIHandlers.add(:summary, :page_ribbons, {
#   "name"      => "Cintas",
#   "suffix"    => "ribbons",
#   "order"     => 50,
#   "layout"    => proc { |pkmn, scene| scene.drawPageFive }
# })

#-------------------------------------------------------------------------------
# Egg Summary handlers.
#-------------------------------------------------------------------------------

# Info page.
UIHandlers.add(:summary, :page_egg, {
  "name"      => "Notas Entrenador",
  "suffix"    => "egg",
  "order"     => 10,
  "onlyEggs"  => true,
  "options"   => [:mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageOneEgg }
})

UIHandlers.add(:summary, :page_allstats, {
  "name"      => "Estadísticas",
  "suffix"    => "allstats", 
  "order"     => 35,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageAllStats }
})