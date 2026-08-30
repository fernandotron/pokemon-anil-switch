# =============================================================================
# SCRIPT PARA COMBATES CON LEGENDARIOS, LÓGICA DE REAPARECER TRAS COMBATE
# =============================================================================

class Player
  attr_accessor :defeated_combats
  attr_accessor :combats_to_reset
end

# Función a la que se llama tras cada combate con un legendario.
def registrar_legendario_derrotado(simbolo)
  $player.defeated_combats ||= []
  # Variable con el resultado del combate. 1 = derrotado.
  if $game_variables[1] == 1
    $player.defeated_combats << simbolo unless $player.defeated_combats.include?(simbolo)
  end
end

# Función a llamar al pasarse la liga.
def registrar_legendarios_para_reaparecer
  $player.defeated_combats ||= []
  $player.combats_to_reset ||= []
  $player.combats_to_reset |= $player.defeated_combats
  $player.defeated_combats.clear
end

# Función que llama un legendario derrotado para reaparecer tras la liga.
def reiniciar_legendario?(simbolo)
  $player.combats_to_reset ||= []
  if $player.combats_to_reset.include?(simbolo)
    $player.combats_to_reset.delete(simbolo)
    return true
  end
  return false
end

# =============================================================================
# SCRIPT PARA COMBATES CON LEGENDARIOS, COMBATE
# =============================================================================

# === Config: especie => { porcentaje => forma } ===
# IMPORTANTE: Los porcentajes deben ir de MAYOR a MENOR para que funcione la prioridad
FORM_CHANGE_RULES = {
  :MEWTWO   => { 66 => 2, 33 => 0 },            
  :LATIOS   => { 25 => 0 },             
  :LATIAS   => { 25 => 0 }, 
  :DEOXYS   => { 75 => 0, 50 => 1, 25 => 3 },
  :GROUDON  => { 25 => 0 },             
  :KYOGRE   => { 25 => 0 },   
  :DIALGA   => { 50 => 0 },     
  :PALKIA   => { 50 => 0 },     
  :GIRATINA => { 50 => 0 },                
  :SHAYMIN  => { 25 => 0 },
  :KYUREM   => { 66 => 2, 33 => 0 },     
  :TORNADUS => { 50 => 0 },   
  :THUNDURUS=> { 50 => 0 },   
  :LANDORUS => { 50 => 0 },   
  :ENAMORUS => { 50 => 0 },
  :NECROZMA => { 75 => 2, 50 => 3, 25 => 0},  
  :CALYREX => { 50 => 2 },   
  :OGERPON  => { 75 => 1, 50 => 2, 25 => 3 },
  :TERAPAGOS=> { 25 => 1 },
  :DIANCIE  => { 25 => 0 },
  :ZERAORA  => { 25 => 0 },
  :DARKRAI  => { 25 => 0 },
  :HEATRAN  => { 25 => 0 },
  :MAGEARNA => { 25 => 0 },
}



def combate_importante_legendario(pokemon, level)
  # Estructura para comprobar si derrotas al legendario para revancha tras la liga.
  $player.defeated_combats ||= []     # Combates derrotados (no capturados)
  $player.combats_to_reset ||= []     # Combates que deben resetearse tras la Liga

  Pokemon.play_cry(pokemon)
  pbWait(1)

  # Reglas del combate
  setBattleRule("cannotRun")
  setBattleRule("disablePokeBalls")
  setBattleRule("alwaysCapture")
  setBattleRule("2v1")
  setBattleRule("outcomevar", 1)
  setBattleRule("midbattleScript", :legends_postgame)

  musica  = ""
  clima   = nil # :Sun, :Rain, :Sandstorm, :Hail, :HarshSun, :HeavyRain, :StrongWinds
  terreno = nil # :Electric, :Grassy, :Psychic, :Misty
  moves = []

  # DEFINIR SEGÚN ESPECIES
  case pokemon
  # KANTO
  when :ZAPDOS # Central Energía
    musica  = "Legendario"
    moves   = [:THUNDERBOLT, :HURRICANE, :DISCHARGE, :HEATWAVE]
    terreno = :Electric
  when :MOLTRES # Volcán Isla Canela
    musica  = "Legendario"
    moves   = [:HURRICANE, :HEATWAVE, :SOLARBEAM, :FLAMETHROWER]
    clima   = :StrongWinds
  when :ARTICUNO # Islas Espuma
    musica  = "Legendario"
    moves   = [:BLIZZARD, :HURRICANE, :FREEZEDRY, :ROOST]
    clima   = :Hail
  when :ZAPDOS_1
    musica  = "Legendario"
    moves   = [:THUNDEROUSKICK, :CLOSECOMBAT, :ACROBATICS, :STOMPINGTANTRUM]
    terreno = :Misty
  when :MOLTRES_1
    musica  = "Legendario"
    moves   = [:FIERYWRATH, :HURRICANE, :HEATWAVE, :SNARL]
    clima   = :StrongWinds
  when :ARTICUNO_1
    musica  = "Legendario"
    moves   = [:FREEZINGGLARE, :PSYCHIC, :HURRICANE, :DAZZLINGGLEAM]
    terreno = :Psychic
  when :MEWTWO # Bosque Celeste
    musica  = "Legendario"
    moves   = [:PSYSTRIKE, :RECOVER, :FUTURESIGHT, :AURASPHERE]
    terreno = :Psychic
  when :MEW # Ciudad Carmín (camión)
    musica  = "Legendario"
    moves   = [:PSYCHIC, :FIREBLAST, :HYDROPUMP, :THUNDERBOLT]
    terreno = :Psychic
  # JOHTO
  when :RAIKOU # Ruta 11 (encima de Carril Bici)
    musica  = "Legendario"
    moves   = [:DISCHARGE, :EXTRASENSORY, :CRUNCH, :EXTREMESPEED]
    terreno = :Electric
  when :ENTEI  # Ruta 19 (bajando de Paleta)
    musica  = "Legendario"
    moves   = [:ERUPTION, :EXTRASENSORY, :LAVAPLUME, :FIRESPIN]
    clima   = :Sun
  when :SUICUNE # Ruta 10 Norte (lago en frente de central)
    musica  = "Legendario"
    moves   = [:HYDROPUMP, :EXTRASENSORY, :ICEBEAM, :WATERPULSE]
    terreno = :Misty
  when :LUGIA # Cima Cataratas Tohjo
    musica  = "Legendario"
    moves   = [:AEROBLAST, :EXTRASENSORY, :HYDROPUMP, :RECOVER]
    terreno = :Psychic
  when :HOOH # Cima Cataratas Tohjo
    musica  = "Legendario"
    moves   = [:SACREDFIRE, :ROOST, :EXTRASENSORY, :BRAVEBIRD]
    terreno = :StrongWinds
  when :CELEBI # Claro Secreto (Bosque Verde)
    musica  = "Legendario"
    moves   = [:PSYCHIC, :MAGICALLEAF, :RECOVER, :HEALBELL]
    terreno = :Grassy
  # HOENN
  when :REGIROCK # Túnel Roca
    musica  = "Legendario menor"
    moves   = [:STONEEDGE, :EARTHQUAKE, :CURSE, :BODYPRESS]
    clima   = :Sandstorm
  when :REGICE # Islas Espuma (cueva)
    musica  = "Legendario menor"
    moves   = [:ICEBEAM, :BLIZZARD, :THUNDERBOLT, :FOCUSBLAST]
    clima   = :Hail
  when :REGISTEEL # Monte Moon
    musica  = "Legendario menor"
    moves   = [:IRONHEAD, :BODYPRESS, :THUNDERWAVE, :CURSE]
    clima   = :Sandstorm
  when :LATIOS # Ruta 2 Norte
    musica  = "Legendario menor"
    moves   = [:DRAGONPULSE, :LUSTERPURGE, :SHADOWBALL, :ICEBEAM]
    terreno = :Psychic
  when :LATIAS  # Ruta 13 (bajando de Marengo)
    musica  = "Legendario menor"
    moves   = [:DRAGONPULSE, :MISTBALL, :THUNDERBOLT, :ICEBEAM]
    terreno = :Psychic
  when :GROUDON # Isla Canela
    musica  = "Legendario mayor"
    moves   = [:PRECIPICEBLADES, :FIREBLAST, :SOLARBEAM, :ROCKSLIDE]
    clima   = :HarshSun
  when :KYOGRE # Ruta 18 (derecha de Canela)
    musica  = "Legendario mayor"
    moves   = [:ORIGINPULSE, :THUNDER, :ICEBEAM, :SCALD]
    clima   = :HeavyRain
  when :RAYQUAZA # Monte Plateado
    musica  = "Legendario mayor"
    moves   = [:DRAGONASCENT, :DRACOMETEOR, :OUTRAGE, :EXTREMESPEED]
    clima   = :StrongWinds
  when :DEOXYS # Monte Moon (exterior)
    musica  = "Legendario mayor"
    moves   = [:PSYCHOBOOST, :RECOVER, :ICEBEAM, :DARKPULSE]
    terreno = :Psychic
  # SINNOH
  when :UXIE # Ciudad Plateada
    musica  = "Legendario menor"
    moves   = [:MYSTICALPOWER, :YAWN, :FUTURESIGHT, :REFLECT]
    terreno = :Psychic
  when :MESPRIT # Torre Pokémon (Lavanda)
    musica  = "Legendario menor"
    moves   = [:MYSTICALPOWER, :ICEBEAM, :THUNDERBOLT, :SHADOWBALL]
    terreno = :Psychic
  when :AZELF # Monte Plateado (exterior)
    musica  = "Legendario menor"
    moves   = [:MYSTICALPOWER, :FLAMETHROWER, :THUNDERBOLT, :SHADOWBALL]
    terreno = :Psychic
  when :DIALGA # Monte Plateado (interior)
    musica  = "Legendario mayor"
    moves   = [:ROAROFTIME, :FLASHCANNON, :EARTHPOWER, :DRACOMETEOR]
    clima   = :Sandstorm
  when :PALKIA # Interior Cataratas Johto
    musica  = "Legendario mayor"
    moves   = [:SPACIALREND, :HYDROPUMP, :SURF, :DRACOMETEOR]
    clima   = :HeavyRain
  when :GIRATINA # Túnel Diglett
    musica  = "Legendario mayor"
    moves   = [:SHADOWFORCE, :DRAGONPULSE, :AURASPHERE, :EARTHPOWER]
    #terreno = :Misty
  when :HEATRAN # Volcán de Isla Canela
    musica  = "Legendario mayor"
    moves   = [:MAGMASTORM, :LAVAPLUME, :EARTHPOWER, :FLASHCANNON]
    clima   = :HarshSun
  when :REGIGIGAS # Islas Espuma (cueva)
    musica  = "Legendario mayor"
    moves   = [:CRUSHGRIP, :GIGAIMPACT, :EARTHQUAKE, :DRAINPUNCH]
    terreno = :Misty
  when :CRESSELIA # Monte Moon (exterior)
    musica  = "Legendario mayor"
    moves   = [:PSYCHIC, :MOONLIGHT, :ICEBEAM, :DAZZLINGGLEAM]
    terreno = :Psychic
  when :DARKRAI # Túnel Roca
    musica  = "Legendario mayor"
    moves   = [:DARKVOID, :DARKPULSE, :SLUDGEBOMB, :FOCUSBLAST]
  when :SHAYMIN # Pueblo Paleta
    musica  = "Legendario mayor"
    moves   = [:SEEDFLARE, :AIRSLASH, :EARTHPOWER, :SYNTHESIS]
    terreno = :Grassy
  when :ARCEUS # Monte Plateado
    musica  = "Legendario mayor"
    moves   = [:JUDGMENT, :EXTREMESPEED, :RECOVER, :ICEBEAM]
  # TESELIA
  when :VIRIZION # Bosque Verde
    musica  = "Legendario menor"
    moves   = [:LEAFBLADE, :SACREDSWORD, :STONEEDGE, :XSCISSOR]
    terreno = :Grassy
  when :TERRAKION # Ruta 23 (entrada Calle Victoria)
    musica  = "Legendario menor"
    moves   = [:SACREDSWORD, :STONEEDGE, :EARTHQUAKE, :IRONHEAD]
    clima   = :Sandstorm
  when :COBALION # Ruta 4
    musica  = "Legendario menor"
    moves   = [:SACREDSWORD, :IRONHEAD, :CLOSECOMBAT, :STONEEDGE]
  when :KELDEO # Ruta 24 (Puentes hacia Tohjo)
    musica  = "Legendario menor"
    moves   = [:SECRETSWORD, :HYDROPUMP, :SCALD, :ICYWIND]
    clima   = :Rain
  when :TORNADUS # Ruta 6
    musica  = "Legendario menor"
    moves   = [:BLEAKWINDSTORM, :HURRICANE, :KNOCKOFF, :HEATWAVE]
    clima   = :StrongWinds
  when :THUNDURUS # Ruta 12 (puentes, bajando de Lavanda)
    musica  = "Legendario menor"
    moves   = [:WILDBOLTSTORM, :THUNDER, :AIRSLASH, :GRASSKNOT]
    clima   = :HeavyRain
  when :LANDORUS # Ruta 9
    musica  = "Legendario menor"
    moves   = [:SANDSEARSTORM, :EARTHQUAKE, :ROCKSLIDE, :KNOCKOFF]
    terreno = :Grassy
  when :ENAMORUS # Ruta 15
    musica = "Legendario menor"
    moves  = [:SPRINGTIDESTORM, :MOONBLAST, :EARTHPOWER, :MYSTICALFIRE]
  when :ZEKROM # Monte Moon
    musica = "Legendario mayor"
    moves  = [:BOLTSTRIKE, :FUSIONBOLT, :DRAGONCLAW, :IRONTAIL]
    terreno = :Electric
  when :RESHIRAM # Monte Plateado (interior)
    musica = "Legendario mayor"
    moves  = [:BLUEFLARE, :FUSIONFLARE, :DRACOMETEOR, :EARTHPOWER]
    clima  = :HarshSun
  when :KYUREM # Islas Espuma (cueva)
    musica = "Legendario mayor"
    moves  = [:FREEZESHOCK, :ICEBURN, :DRACOMETEOR, :EARTHPOWER]
    clima  = :Hail
  when :MELOETTA # Ruta 14 (derecha de Fucsia, ruta festiva)
    musica = "Legendario menor"
    moves  = [:RELICSONG, :HYPERVOICE, :PSYCHIC, :CLOSECOMBAT]
    terreno = :Psychic
  when :GENESECT # Mansión Quemada
    musica = "Legendario menor"
    moves  = [:TECHNOBLAST, :IRONHEAD, :XSCISSOR, :FLAMETHROWER]
    terreno = :Misty
  # KALOS
  when :XERNEAS # Bosque Verde
    musica = "Legendario mayor"
    moves  = [:MOONBLAST, :DAZZLINGGLEAM, :PSYCHIC, :GRASSKNOT]
    terreno = :Misty
  when :YVELTAL # Torre Pokémon (Azotea)
    musica = "Legendario mayor"
    moves  = [:OBLIVIONWING, :DARKPULSE, :HEATWAVE, :HURRICANE]
    clima  = :Rain
  when :ZYGARDE # Túnel Diglett
    musica = "Legendario mayor"
    moves  = [:COREENFORCER, :THOUSANDARROWS, :THOUSANDWAVES, :DRAGONPULSE]
    terreno = :Grassy
  when :VOLCANION # Volcán de Isla Canela
    musica = "Legendario mayor"
    moves  = [:STEAMERUPTION, :FIREBLAST, :EARTHPOWER, :SLUDGEBOMB]
    clima  = :Sun
  when :DIANCIE # Cueva Celeste
    musica = "Legendario mayor"
    moves  = [:DIAMONDSTORM, :MOONBLAST, :EARTHPOWER, :PSYCHIC]
    clima  = :Sandstorm
  when :HOOPA # Laboratorio Oak
    musica = "Legendario mayor"
    moves  = [:HYPERSPACEFURY, :HYPERSPACEHOLE, :SHADOWBALL, :DAZZLINGGLEAM]
    terreno = :Psychic
  # ALOLA
  when :TAPUKOKO # Ruta 19 (bajando de Paleta)
    musica = "Legendario menor"
    moves  = [:THUNDERBOLT, :DAZZLINGGLEAM, :GRASSKNOT, :NATURESMADNESS]
  when :TAPULELE # Ruta 18 (derecha de Canela)
    musica = "Legendario menor"
    moves  = [:PSYCHIC, :MOONBLAST, :SHADOWBALL, :NATURESMADNESS]
  when :TAPUBULU # Ruta 13 (bajando de Marengo)
    musica = "Legendario menor"
    moves  = [:WOODHAMMER, :HORNLEECH, :PLAYROUGH, :NATURESMADNESS]
  when :TAPUFINI # Ruta 17 (bajando de Fucsia)
    musica = "Legendario menor"
    moves  = [:MOONBLAST, :SURF, :ICEBEAM, :NATURESMADNESS]
  when :SOLGALEO # Ruta 16 (Izquierda de Fucsia)
    musica = "Legendario mayor"
    moves  = [:SUNSTEELSTRIKE, :FLAREBLITZ, :EARTHQUAKE, :PSYCHICFANGS]
    clima  = :HarshSun
  when :LUNALA # Monte Moon (exterior)
    musica = "Legendario mayor"
    moves  = [:MOONGEISTBEAM, :MOONBLAST, :PSYCHIC, :SHADOWBALL]
    terreno = :Misty
  when :NECROZMA # Cueva Celeste
    musica = "Legendario mayor"
    moves  = [:PRISMATICLASER, :PHOTONGEYSER, :EARTHPOWER, :SHADOWBALL]
    terreno = :Psychic
  when :NIHILEGO # Ruta 22 (izda ciudad verde)
    musica = "Legendario menor"
    moves  = [:POWERGEM, :SLUDGEWAVE, :THUNDERBOLT, :GRASSKNOT]
    clima  = :Sandstorm
  when :BUZZWOLE # Ruta 3
    musica = "Legendario menor"
    moves  = [:LUNGE, :SUPERPOWER, :LEECHLIFE, :ICEPUNCH]
    terreno = :Grassy
  when :PHEROMOSA # Ruta 4
    musica = "Legendario menor"
    moves  = [:LUNGE, :HIGHJUMPKICK, :POISONJAB, :TRIPLEAXEL]
    terreno = :Grassy
  when :XURKITREE # Ruta 10 Norte (exterior de la central)
    musica = "Legendario menor"
    moves  = [:THUNDERBOLT, :DISCHARGE, :ENERGYBALL, :DAZZLINGGLEAM]
    terreno = :Electric
  when :CELESTEELA # Ruta 7 (derecha de Azulona)
    musica = "Legendario menor"
    moves  = [:HEAVYSLAM, :AIRSLASH, :FLAMETHROWER, :GIGADRAIN]
  when :KARTANA # Ruta 12 (puentes, bajando de Lavanda)
    musica = "Legendario menor"
    moves  = [:LEAFBLADE, :SMARTSTRIKE, :KNOCKOFF, :XSCISSOR]
    terreno = :Grassy
  when :GUZZLORD # Ruta 14 (derecha de Fucsia, ruta festiva)
    musica = "Legendario menor"
    moves  = [:DRAGONTAIL, :CRUNCH, :DRAGONCLAW, :EARTHQUAKE]
  when :STAKATAKA # Ruta 23 (entrada Calle Victoria)
    musica = "Legendario menor"
    moves  = [:GYROBALL, :ROCKSLIDE, :STONEEDGE, :TRICKROOM]
    clima  = :Sandstorm
  when :BLACEPHALON # Monte Plateado (interior)
    musica = "Legendario menor"
    moves  = [:MINDBLOWN, :SHADOWBALL, :FIREBLAST, :FLAMETHROWER]
    clima  = :Sun
  when :MAGEARNA # Central Energía
    musica = "Legendario menor"
    moves  = [:FLEURCANNON, :FLASHCANNON, :AURASPHERE, :THUNDERBOLT]
    terreno = :Misty
  when :ZERAORA # Ruta 25 sur (pre Monte Plateado)
    musica = "Legendario menor"
    moves  = [:PLASMAFISTS, :CLOSECOMBAT, :KNOCKOFF, :PLAYROUGH]
    terreno = :Electric
  when :MARSHADOW # Ruta 8 (Cementerio)
    musica = "Legendario menor"
    moves  = [:SPECTRALTHIEF, :CLOSECOMBAT, :SHADOWSNEAK, :ICEPUNCH]
    terreno = :Misty
  when :MELMETAL # -
    musica = "Legendario menor"
    moves  = [:DOUBLEIRONBASH, :EARTHQUAKE, :THUNDERPUNCH, :ICEPUNGH]
  # GALAR
  when :ZACIAN # Ruta 3
    musica = "Legendario mayor"
    moves  = [:BEHEMOTHBLADE, :PLAYROUGH, :SACREDSWORD, :CRUNCH]
    terreno = :Misty
  when :ZAMAZENTA # Ruta 4
    musica = "Legendario mayor"
    moves  = [:BEHEMOTHBASH, :BODYPRESS, :CRUNCH, :STONEEDGE]
    terreno = :Misty
  when :ETERNATUS # Bosque Celeste
    musica = "Legendario mayor"
    moves  = [:DYNAMAXCANNON, :SLUDGEBOMB, :FLAMETHROWER, :EARTHPOWER]
  when :REGIELEKI # Central Energía
    musica = "Legendario menor"
    moves  = [:THUNDERCAGE, :THUNDERBOLT, :EXTREMESPEED, :THUNDERWAVE]
    terreno = :Electric
  when :REGIDRAGO # Monte Plateado (interior)
    musica = "Legendario menor"
    moves  = [:DRAGONENERGY, :DRAGONPULSE, :FIREFANG, :CRUNCH]
    terreno = :Misty
  when :ZARUDE # Bosque Verde
    musica = "Legendario mayor"
    moves  = [:JUNGLEHEALING, :POWERWHIP, :DARKESTLARIAT, :CLOSECOMBAT]
    terreno = :Grassy
  when :GLASTRIER # Islas Espuma (cueva)
    musica = "Legendario mayor"
    moves  = [:GLACIALLANCE, :ICICLECRASH, :HIGHHORSEPOWER, :BODYPRESS]
    clima  = :Hail
  when :SPECTRIER # Ruta 8 (Cementerio)
    musica = "Legendario mayor"
    moves  = [:ASTRALBARRAGE, :SHADOWBALL, :DARKPULSE, :SNARL]
    terreno = :Misty
  when :CALYREX # Monte Plateado (exterior)
    musica = "Legendario mayor"
    moves  = [:PSYCHIC, :ENERGYBALL, :GIGADRAIN, :RECOVER]
    terreno = :Grassy
  # PALDEA
  when :WOCHIEN # Bosque Verde
    musica = "Legendario menor"
    moves  = [:RUINATION, :GIGADRAIN, :KNOCKOFF, :EARTHQUAKE]
    terreno = :Grassy
  when :CHIENPAO # Ruta 25 Norte (pre Liga Pokémon)
    musica = "Legendario menor"
    moves  = [:RUINATION, :ICICLECRASH, :CRUNCH, :THROATCHOP]
    clima  = :Hail
  when :TINGLU # Ruta 25 sur (pre Monte Plateado)
    musica = "Legendario menor"
    moves  = [:RUINATION, :EARTHQUAKE, :HEAVYSLAM, :STONEEDGE]
    clima  = :Sandstorm
  when :CHIYU # Volcán de Isla Canela
    musica = "Legendario menor"
    moves  = [:RUINATION, :LAVAPLUME, :DARKPULSE, :SOLARBEAM]
    clima  = :Sun
  when :KORAIDON # Camino de Bicis (parte de arriba)
    musica = "Legendario mayor"
    moves  = [:COLLISIONCOURSE, :FLAREBLITZ, :CLOSECOMBAT, :DRAGONCLAW]
    clima  = :HarshSun
  when :MIRAIDON # Ruta 22 (izda ciudad verde)
    musica = "Legendario mayor"
    moves  = [:ELECTRODRIFT, :DRACOMETEOR, :DRAGONPULSE, :PARABOLICCHARGE]
    terreno = :Electric
  when :WALKINGWAKE # Bosque Celeste
    musica = "Legendario mayor"
    moves  = [:HYDROSTEAM, :DRACOMETEOR, :DRAGONPULSE, :ICEBEAM]
    clima  = :HarshSun
  when :GOUGINGFIRE # Bosque Celeste
    musica = "Legendario mayor"
    moves  = [:BURNINGBULWARK, :FLAREBLITZ, :BREAKINGSWIPE, :DRAGONDANCE]
    clima  = :HarshSun
  when :RAGINGBOLT # Bosque Celeste
    musica = "Legendario mayor"
    moves  = [:THUNDERCLAP, :DRACOMETEOR, :DRAGONPULSE, :WEATHERBALL]
    clima  = :HarshSun
  when :IRONCROWN # Bosque Celeste
    musica = "Legendario mayor"
    moves  = [:TACHYONCUTTER, :FLASHCANNON, :PSYCHIC, :AURASPHERE]
    terreno = :Electric
  when :IRONLEAVES # Bosque Celeste
    musica = "Legendario mayor"
    moves  = [:PSYBLADE, :LEAFBLADE, :SACREDSWORD, :NIGHTSLASH]
    terreno = :Electric
  when :IRONBOULDER # Bosque Celeste
    musica = "Legendario mayor"
    moves  = [:MIGHTYCLEAVE, :ROCKSLIDE, :EARTHQUAKE, :PSYCHOCUT]
    terreno = :Electric
  when :OKIDOGI # Isla Canela (zona del volcán)
    musica = "Legendario menor"
    moves  = [:MALIGNANTCHAIN, :CLOSECOMBAT, :POISONJAB, :GUNKSHOT]
  when :MUNKIDORI # Ruta 11 (encima de Carril Bici)
    musica = "Legendario menor"
    moves  = [:MALIGNANTCHAIN, :SLUDGEBOMB, :PSYCHIC, :SHADOWBALL]
  when :FEZANDIPITI # Ruta 16 (Izquierda de Fucsia)
    musica = "Legendario menor"
    moves  = [:MALIGNANTCHAIN, :PLAYROUGH, :ACROBATICS, :POISONJAB]
  when :OGERPON # Ruta 25 sur (pre Monte Plateado)
    musica = "Legendario menor"
    moves  = [:IVYCUDGEL, :POWERWHIP, :HORNLEECH, :LOWKICK]
  when :PECHARUNT # Ruta 14 (derecha de Fucsia, ruta festiva)
    musica = "Legendario menor"
    moves  = [:MALIGNANTCHAIN, :SLUDGEBOMB, :HEX, :SHADOWBALL]
    terreno = :Grassy
  when :TERAPAGOS # Cueva Celeste
    musica = "Legendario mayor"
    moves  = [:TERASTARSTORM, :EARTHPOWER, :ICEBEAM, :RECOVER]
    terreno = :Misty
  end

  rules = {
    :immunities => [:ALLSTATUS, :FLINCH, :STATDROPS, :PPLOSS, :OHKO,
                    :ESCAPE, :INDIRECT, :SELFKO, :TRANSFORM],
    :hp_level => 4
  }
  rules[:moves] = moves if moves.any? && !RandomizedChallenge.enabled?
  
  if $game_switches[SHINYZADOR_SWTICH]
    rules[:shiny] = true
    rules[:super_shiny] = false # if rand(10) == 0
    $game_switches[SHINYZADOR_SWTICH] = false
  end

  setBattleRule("battleBGM", musica)
  setBattleRule("weather", clima)   if clima
  setBattleRule("terrain", terreno) if terreno
  setBattleRule("editWildPokemon", rules)
  setBattleRule("outcomevar", 1)
  setBattleRule("raidstylecapture",
    { :capture_chance => 100,
      :flee_msg       => "¡El Pokémon Legendario ha huido!"}
  )
  
  #Graphics.transition(70, "minorlegendary")
  WildBattle.start(pokemon, level)
end

def get_legendary_capture_form(pokemon)
  form_0_species = [:KYOGRE, :GROUDON, :OGERPON, :NECROZMA, :SHAYMIN, :TORNADUS, :THUNDURUS, :LANDORUS,
                    :ENAMORUS, :KYUREM, :HOOPA, :CALYREX]
  form_0_species.include?(pokemon.species) ? 0 : pokemon.form
end


module PBEffects
    Endure_boss  = 1000
    LastFormChange = 1001  # Trackear último cambio de forma
    FormChangeThresholds = 1002  # Trackear qué thresholds ya han sido activados
end

class Battle::Battler
  alias batallas_legends_postgame_pbInitEffects pbInitEffects
  def pbInitEffects(batonPass)
    batallas_legends_postgame_pbInitEffects(batonPass)
    @effects[PBEffects::Endure_boss]  = false
    @effects[PBEffects::LastFormChange] = -1  # -1 significa que no ha cambiado aún
    @effects[PBEffects::FormChangeThresholds] = []  # Array de thresholds ya activados
  end
end

MidbattleHandlers.add(:midbattle_scripts, :legends_postgame,
  proc { |battle, idxBattler, idxTarget, trigger|
    # scene = battle.scene
    battler = battle.battlers[idxBattler]
    # logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    
    case trigger
    #---------------------------------------------------------------------------
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("¡El {1} rival te mira fijamente!", battler.name))

      # CAMBIO DE FONDO PARA GIRATINA
      if battler.species == :GIRATINA
        battle.scene.pbFadeOutInWhite  {
          battle.backdrop = "MundoDistorsion" 
          battle.scene.pbRefreshEverything if battle.scene.respond_to?(:pbRefreshEverything)
        } 
        battle.pbDisplayPaused(_INTL("¡El mundo se distorsiona a tu alrededor!"))
      elsif [:SHAYMIN].include?(battler.species)
        battle.scene.pbFadeOutInWhite  {
          battle.backdrop = "PraderaFlores" 
          battle.scene.pbRefreshEverything if battle.scene.respond_to?(:pbRefreshEverything)
        } 
        battle.pbDisplayPaused(_INTL("¡Te sientes como si estuvieses en otro sitio!"))
      elsif [:DEOXYS, :NECROZMA].include?(battler.species)
        battle.scene.pbFadeOutInWhite  {
          battle.backdrop = "Espacio" 
          battle.scene.pbRefreshEverything if battle.scene.respond_to?(:pbRefreshEverything)
        } 
        battle.pbDisplayPaused(_INTL("¡Te sientes como si estuvieses en otro sitio!"))
      elsif [:DIALGA, :PALKIA].include?(battler.species)
        battle.scene.pbFadeOutInWhite  {
          battle.backdrop = "ColumnaLanza" 
          battle.scene.pbRefreshEverything if battle.scene.respond_to?(:pbRefreshEverything)
        } 
        battle.pbDisplayPaused(_INTL("¡Te sientes como si estuvieses en otro sitio!"))
      elsif [:NIHILEGO, :BUZZWOLE, :PHEROMOSA, :XURKITREE, :CELESTEELA, :KARTANA, :GUZZLORD, :STAKATAKA,
        :BLACEPHALON].include?(battler.species)
        battle.scene.pbFadeOutInWhite  {
          battle.backdrop = "Ultraespacio" 
          battle.scene.pbRefreshEverything if battle.scene.respond_to?(:pbRefreshEverything)
        } 
        battle.pbDisplayPaused(_INTL("¡Te sientes como si estuvieses en otro sitio!"))
      end
      
      # CAMBIOS DE FORMAS AL EMPEZAR
      # forma_inicial_distinta = true
      # forma_cambio = 0
      num_forma_cambio = nil
      # Pokémon que cambian a forma 1
      form_changes = {
        :MEWTWO   => 1, 
        :LATIOS   => 1,  :LATIAS    => 1, 
        :GROUDON  => 1,  :KYOGRE    => 1,  :RAYQUAZA => 1,
        :GIRATINA => 1,  :DIALGA    => 1,  :PALKIA   => 1,
        :KELDEO   => 1,  :KYUREM    => 1, 
        :TORNADUS => 1,  :THUNDURUS => 1,  :LANDORUS => 1, :ENAMORUS => 1, 
        :DIANCIE  => 1,  :HOOPA     => 1,
        :NECROZMA => 1, 
        :ZACIAN   => 1,  :ZAMAZENTA => 1, 
        :CALYREX  => 1,  :SHAYMIN   => 1,
        :DEOXYS   => 2,  :TERAPAGOS => 2, :ZYGARDE => 2,
        :ZERAORA  => 1,  :DARKRAI   => 1, :HEATRAN  => 1, :MAGEARNA => 2
      }
      # forma_1_especies = [:MEWTWO, :LATIOS, :LATIAS, :GROUDON, :KYOGRE, :RAYQUAZA, :GIRATINA, :DIALGA, :PALKIA,
      #                     :KELDEO, :KYUREM, :TORNADUS, :THUNDURUS, :LANDORUS, :ENAMORUS, :DIANCIE, :HOOPA,
      #                     :NECROZMA, :ZACIAN, :ZAMAZENTA, :CALYREX, :SHAYMIN]

      # forma_2_especies = [:DEOXYS, :TERAPAGOS, :ZYGARDE]

      # if form_changes.key?(battler.species)
      #   num_forma_cambio = form_changes[battler.species]
      # else
      #   forma_inicial_distinta = false
      # end

      num_forma_cambio = form_changes.fetch(battler.species, nil)

      # if forma_1_especies.include?(battler.species)
      #   num_forma_cambio = 1
      # elsif forma_2_especies.include?(battler.species)
      #   num_forma_cambio = 2
      # else
      #   forma_inicial_distinta = false
      # end

      if num_forma_cambio
        if battler.respond_to?(:pbChangeForm)
          battler.pbChangeForm(num_forma_cambio, _INTL("¡{1} ha cambiado de forma!", battler.name))
        else
          battler.form = num_forma_cambio
          battler.pbUpdate(true)
          battle.scene.pbChangePokemon(battler, battler.pokemon) if battle.scene.respond_to?(:pbChangePokemon)
          battle.pbDisplayPaused(_INTL("¡{1} ha cambiado de forma!", battler.name))
        end
      end

      # CAMBIOS DE ESTADÍSTICAS
      battle.pbCommonAnimation("StatUp", battler)
      # Aumentamos las estadísticas del Pokémon rival
      #[:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
      #  next if !battler.pbCanRaiseStatStage?(stat, battler)
      #  battler.pbRaiseStatStageBasic(stat, 2)
      #end
      [:ATTACK, :SPECIAL_ATTACK, :SPEED].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStageBasic(stat, 2)
      end
      battle.pbDisplayPaused(_INTL("¡Las estadísticas de {1} han aumentado! ¡Ten cuidado!", battler.name))
      #battler.effects[PBEffects::Endure_boss] = true

    # Verificar cambios de forma después de cada ataque/daño
    when "AfterMove"
      # Verificar todos los battlers enemigos para cambios de forma
      battle.battlers.each do |b|
        next if !b || b.fainted?
        next if b.pbOwnedByPlayer? # Solo verificar enemigos
        apply_hp_form_change(battle, b)
      end

    # También verificar al final de cada turno como respaldo
    when "RoundEnd"
      # Verificar todos los battlers enemigos para cambios de forma
      battle.battlers.each do |b|
        next if !b || b.fainted?
        next if b.pbOwnedByPlayer? # Solo verificar enemigos
        apply_hp_form_change(battle, b)
      end

    #when "RoundEnd_foe"
    #    # El código original del endure
    #    if battler.hp > 1 && !battler.fainted? && !battler.effects[PBEffects::Endure_boss]
    #        battler.effects[PBEffects::Endure_boss] = true
    #    elsif battler.hp == 1 && battler.effects[PBEffects::Endure_boss]
    #        battler.effects[PBEffects::Endure_boss] = false
    #        battle.pbDisplayPaused(_INTL("¡Parece que el {1} salvaje está débil! ¡Es el momento de capturarlo o derrotarlo!", battler.name))
    #        MidbattleHandlers.trigger(:midbattle_triggers, "disableBalls", battle, idxBattler, idxTarget, false)
    #    end
    end
  }  
)


def apply_hp_form_change(battle, battler)
  return if !battler || battler.fainted?
  rules = FORM_CHANGE_RULES[battler.species]
  return if !rules
  # Calcular porcentaje de HP actual
  hp_percentage = (battler.hp * 100.0 / battler.totalhp).round
  # Inicializar array de thresholds si no existe
  battler.effects[PBEffects::FormChangeThresholds] ||= []
  activated_thresholds = battler.effects[PBEffects::FormChangeThresholds]
  # Determinar qué forma debería tener según el HP actual
  # Evaluamos en orden de MENOR a MAYOR threshold para priorizar el más restrictivo
  desired_form = nil
  threshold_to_activate = nil
  # Ordenar thresholds de menor a mayor para evaluar el más restrictivo primero
  sorted_thresholds = rules.keys.sort
  sorted_thresholds.each do |threshold|
    if hp_percentage <= threshold && !activated_thresholds.include?(threshold)
      desired_form = rules[threshold]
      threshold_to_activate = threshold
      break  # Usar el primer threshold que coincida (el más restrictivo disponible)
    end
  end
  # Si no hay cambio necesario, salir
  if desired_form.nil?
    return
  end
  # Si ya está en la forma correcta, solo marcar el threshold como activado y salir
  if battler.form == desired_form
    activated_thresholds << threshold_to_activate
    return
  end
  # Marcar este threshold como activado
  activated_thresholds << threshold_to_activate
  # Realizar el cambio de forma
  battler.effects[PBEffects::LastFormChange] = desired_form
  if battler.respond_to?(:pbChangeForm)
    battler.pbChangeForm(desired_form, _INTL("¡{1} ha cambiado de forma!", battler.name))
  else
    battler.form = desired_form
    battler.pbUpdate(true)
    battle.scene.pbChangePokemon(battler, battler.pokemon) if battle.scene.respond_to?(:pbChangePokemon)
    battle.pbDisplayPaused(_INTL("¡{1} ha cambiado de forma!", battler.name))
  end
  
end