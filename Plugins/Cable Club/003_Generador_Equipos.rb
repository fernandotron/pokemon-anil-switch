class RandomTeamGenerator

  class << self
    attr_accessor :allow_mega,
                  :allow_mega_item,
                  :allow_singulars,
                  :allow_major_legendaries,
                  :allow_minor_legendaries,
                  :allow_ultra_beasts,
                  :allow_paradoxes
  end

  def self.reset_to_defaults
    @allow_mega              = true
    @allow_mega_item         = true
    @allow_singulars         = false
    @allow_major_legendaries = false
    @allow_minor_legendaries = false
    @allow_ultra_beasts      = false
    @allow_paradoxes         = false
  end


  # ===== CONFIGURACIÓN =====
  @allow_mega              = true
  @allow_mega_item         = true
  @allow_singulars         = false
  @allow_major_legendaries = false
  @allow_minor_legendaries = false
  @allow_ultra_beasts      = false
  @allow_paradoxes         = false

  # =========================


  SINGULARS = [
    :MEW, :CELEBI, :JIRACHI, :DEOXYS, :PHIONE, :MANAPHY, :DARKRAI,
    :SHAYMIN, :ARCEUS, :VICTINI, :KELDEO, :MELOETTA, :GENESECT,
    :DIANCIE, :HOOPA, :VOLCANION, :MAGEARNA, :MARSHADOW,
    :ZERAORA, :MELTAN, :MELMETAL, :ZARUDE, :PECHARUNT
  ]

  MAJOR_LEGENDARIES = [
    :LUGIA, :HOOH,
    :KYOGRE, :GROUDON, :RAYQUAZA,
    :DIALGA, :PALKIA, :GIRATINA,
    :RESHIRAM, :ZEKROM, :KYUREM,
    :XERNEAS, :YVELTAL, :ZYGARDE,
    :COSMOG, :COSMOEM,
    :SOLGALEO, :LUNALA, :NECROZMA,
    :ZACIAN, :ZAMAZENTA, :ETERNATUS,
    :CALYREX,
    :KORAIDON, :MIRAIDON, :TERAPAGOS
  ]

  MINOR_LEGENDARIES = [
    :ARTICUNO, :ZAPDOS, :MOLTRES,
    :RAIKOU, :ENTEI, :SUICUNE,
    :REGIROCK, :REGICE, :REGISTEEL, :REGIGIGAS,
    :LATIAS, :LATIOS,
    :UXIE, :MESPRIT, :AZELF,
    :HEATRAN, :CRESSELIA,
    :TORNADUS, :THUNDURUS, :LANDORUS,
    :KOBALION, :TERRAKION, :VIRIZION,
    :TAPUKOKO, :TAPULELE, :TAPUBULU, :TAPUFINI,
    :TYPENULL, :SILVALLY,
    :GLASTRIER, :SPECTRIER,
    :KUBFU, :URSHIFU, :REGIELEKI, :REGIDRAGO, :ENAMORUS,
    :TINGLU, :CHIENPAO, :WOCHIEN, :CHIYU,
    :OGERPON, :OKIDOGI, :MUNKIDORI, :FEZANDIPITI
  
  ]

  ULTRA_BEASTS = [
    :NIHILEGO, :BUZZWOLE, :PHEROMOSA,
    :XURKITREE, :CELESTEELA, :KARTANA, :GUZZLORD,
    :POIPOLE, :NAGANADEL, :STAKATAKA, :BLACEPHALON
  ]

  PARADOXES = [
    :GREATTUSK, :SCREAMTAIL, :BRUTEBONNET,
    :FLUTTERMANE, :SLITHERWING, :SANDYSHOCKS, :ROARINGMOON,
    :IRON_TREADS, :IRON_BUNDLE, :IRON_HANDS,
    :IRON_JUGULIS, :IRON_MOTH, :IRON_THORNS, :IRON_VALIANT
  ]

  # Para nombres en los sets que no se traducen bien
  ONLINE_SETS_NAME_CORRECTIONS = {
    "HP"   => :HP,
    "ATK"  => :ATTACK,
    "DEF"  => :DEFENSE,
    "SPA"  => :SPECIAL_ATTACK,
    "SPD"  => :SPECIAL_DEFENSE,
    "SPE"  => :SPEED,
    "BLASTOISINITE" => :BLASTOISINITEX,

    # Formas regionales
    "ARCANINE-HISUI"        => [:ARCANINE, 1],
    "AVALUGG-HISUI"         => [:AVALUGG, 1],
    "BASCULIN-WHITE-STRIPED"=> [:BASCULIN, 2],
    "BRAVIARY-HISUI"        => [:BRAVIARY, 1],
    "CORSOLA-GALAR"         => [:CORSOLA, 1],
    "CUBONE-ALOLA"          => [:CUBONE, 1],
    "DARUMAKA-GALAR"        => [:DARUMAKA, 2],
    "DARMANITAN-GALAR"      => [:DARMANITAN, 2],
    "DARMANITAN-GALAR-ZEN"  => [:DARMANITAN, 3],
    "DECIDUEYE-HISUI"       => [:DECIDUEYE, 1],
    "DIGLETT-ALOLA"         => [:DIGLETT, 1],
    "DUGTRIO-ALOLA"         => [:DUGTRIO, 1],
    "ELECTRODE-HISUI"       => [:ELECTRODE, 1],
    "EXEGGUTOR-ALOLA"       => [:EXEGGUTOR, 1],
    "FARFETCHD-GALAR"       => [:FARFETCHD, 1],
    "GEODUDE-ALOLA"         => [:GEODUDE, 1],
    "GOLEM-ALOLA"           => [:GOLEM, 1],
    "GOODRA-HISUI"          => [:GOODRA, 1],
    "GROWLITHE-HISUI"       => [:GROWLITHE, 1],
    "GRAVELER-ALOLA"        => [:GRAVELER, 1],
    "GRIMER-ALOLA"          => [:GRIMER, 1],
    "LILLIGANT-HISUI"       => [:LILLIGANT, 1],
    "LINOONE-GALAR"         => [:LINOONE, 1],
    "MAROWAK-ALOLA"         => [:MAROWAK, 1],
    "MEOWTH-ALOLA"          => [:MEOWTH, 1],
    "MEOWTH-GALAR"          => [:MEOWTH, 2],
    "MOLTRES-GALAR"         => [:MOLTRES, 1],
    "MRMIME-GALAR"          => [:MRMIME, 1],
    "MUK-ALOLA"             => [:MUK, 1],
    "NINETALES-ALOLA"       => [:NINETALES, 1],
    "PERSIAN-ALOLA"         => [:PERSIAN, 1],
    "PIKACHU-AMARILLO"      => [:PIKACHU, 16],
    "PIKACHU-ROQUERA"       => [:PIKACHU, 7],
    "PONYTA-GALAR"          => [:PONYTA, 1],
    "QWILFISH-HISUI"        => [:QWILFISH, 1],
    "RAICHU-ALOLA"          => [:RAICHU, 1],
    "RAPIDASH-GALAR"        => [:RAPIDASH, 1],
    "RATICATE-ALOLA"        => [:RATICATE, 1],
    "RATTATA-ALOLA"         => [:RATTATA, 1],
    "SANDSHREW-ALOLA"       => [:SANDSHREW, 1],
    "SANDSLASH-ALOLA"       => [:SANDSLASH, 1],
    "SAMUROTT-HISUI"        => [:SAMUROTT, 1],
    "SLOWBRO-GALAR"         => [:SLOWBRO, 1],
    "SLOWKING-GALAR"        => [:SLOWKING, 1],
    "SLOWPOKE-GALAR"        => [:SLOWPOKE, 1],
    "SNEASEL-HISUI"         => [:SNEASEL, 1],
    "STUNFISK-GALAR"        => [:STUNFISK, 1],
    "TAUROS-PALDEA-AQUA"    => [:TAUROS, 3],
    "TAUROS-PALDEA-BLAZE"   => [:TAUROS, 2],
    "TAUROS-PALDEA-COMBAT"  => [:TAUROS, 1],
    "TYPHLOSION-HISUI"      => [:TYPHLOSION, 1],
    "VULPIX-ALOLA"          => [:VULPIX, 1],
    "VOLTORB-HISUI"         => [:VOLTORB, 1],
    "WEEZING-GALAR"         => [:WEEZING, 1],
    "WOOPER-PALDEA"         => [:WOOPER, 1],
    "YAMASK-GALAR"          => [:YAMASK, 1],
    "ZAPDOS-GALAR"          => [:ZAPDOS, 1],
    "ZIGZAGOON-GALAR"       => [:ZIGZAGOON, 1],
    "ZOROARK-HISUI"         => [:ZOROARK, 1],
    "ZORUA-HISUI"           => [:ZORUA, 1],
  }



  def self.translate_name(raw)
    return nil if raw.nil?
    cleaned = raw.strip.upcase
    return ONLINE_SETS_NAME_CORRECTIONS[cleaned] if ONLINE_SETS_NAME_CORRECTIONS.key?(cleaned)
    cleaned.gsub(/[\s_-]/, "").to_sym
  end


  def self.banned_species
    banned = []
    banned += SINGULARS           unless @allow_singulars
    banned += MAJOR_LEGENDARIES   unless @allow_major_legendaries
    banned += MINOR_LEGENDARIES   unless @allow_minor_legendaries
    banned += ULTRA_BEASTS        unless @allow_ultra_beasts
    banned += PARADOXES           unless @allow_paradoxes
    banned.uniq
  end


  def self.generate_team
    species_pool = valid_final_species
    raise "No hay suficientes Pokémon válidos para generar un equipo." if species_pool.length < (@allow_mega ? 6 : 6)

    # ============================
    # FORZAR EQUIPO CON ABOMASNOW
    #species_pool = [:ABOMASNOW] * 10  # ← LÍNEA TEMPORAL PARA TESTEO
    # ============================
    
    team_species = []
    while team_species.length < (@allow_mega ? 5 : 6)
      candidate = species_pool.sample
      next if team_species.include?(candidate) ##
      team_species << candidate
    end

    team = team_species.map do |species|
      form = get_random_non_mega_form(species)
      pokemon = Pokemon.new(species, 100)
      pokemon.form = form
      pokemon
    end

    if @allow_mega
      mega_species = get_mega_capable_species
      raise "No se encontró ninguna especie con forma Mega válida." if mega_species.nil?
      form = get_random_non_mega_form(mega_species)
      mega_pokemon = Pokemon.new(mega_species, 100, form)
      mega_item = get_mega_item(mega_species)
      mega_pokemon.item = mega_item if @allow_mega_item && mega_item
      team << mega_pokemon
    end

    return team
  end


  def self.get_random_non_mega_form(species)
    forms = []
    GameData::Species.each do |data|
      next unless data.species == species
      next if data.form_name&.include?("Mega")
      forms << data.form
    end
    return 0 if forms.empty?
    return forms.uniq.sample
  end


  private

  def self.valid_final_species
    banned = banned_species
    valid = []
    GameData::Species.each_species do |species_data|
      next if species_data.form_name&.include?("Mega")
      # Solo consideramos especies que no evolucionan más (forma final)
      evo_data = species_data.get_evolutions
      next unless evo_data.empty?
      # Y que no estén baneadas
      next if banned.include?(species_data.species)
      valid << species_data.species
    end

    valid.uniq
  end

  def self.get_final_evolution(species)
    loop do
      evo_data = GameData::Species.get(species).get_evolutions
      break if evo_data.empty?
      species = evo_data.first[0]
    end
    return species
  end

  def self.get_mega_item(species)
    GameData::Species.each do |data|
      next unless data.species == species
      next if data.form == 0
      next unless data.mega_stone && data.mega_stone != :NONE
      return data.mega_stone
    end
    return nil
  end

  def self.get_mega_capable_species
    candidates = []
    GameData::Species.each do |data|
      next if data.form != 0
      next if banned_species.include?(data.species)

      GameData::Species.each do |form_data|
        next if form_data.species != data.species
        next unless form_data.mega_stone && form_data.mega_stone != :NONE
        candidates << data.species
        break
      end
    end
    return candidates.sample
  end
end

# Carga la base de datos si no está ya cargada
def load_smogon_sets
  return if defined?(SmogonSetData)
  require_relative "smogon_sets" # Asegúrate de que esté en el mismo directorio
end


# Aplica el set de Smogon si existe
def apply_smogon_set(pkmn)
  build_smogon_set_database unless defined?(SmogonSetData) && !SmogonSetData.empty?

  data = SmogonSetData[pkmn.species.to_sym.upcase]
  
  # Valores default
  GameData::Stat.each_main { |s| pkmn.iv[s.id] = 31 }
  pkmn.nature = :SERIOUS
  pkmn.happiness = 255

  return unless data

  # Determinar si usar el set mega según el ítem
  item_is_mega = pkmn.item && GameData::Item.get(pkmn.item).is_mega_stone?
  set = item_is_mega ? data[:mega] || data[:normal] : data[:normal]
  return unless set

  # Aplica forma si el set la tiene
  pkmn.form = set[:form] unless set[:form].nil?

  # Aplicar ítem del set si no es mega ya
  if set[:item]
    if !pkmn.item || !GameData::Item.get(pkmn.item).is_mega_stone?
      if GameData::Item.exists?(set[:item])
        pkmn.item = set[:item]
      else
        puts "[FALTA ITEM] No se encontró el item: #{set[:item]}"
      end
    end
  end

  if set[:ability]
    if GameData::Ability.exists?(set[:ability])
      pkmn.ability = set[:ability]
    else
      puts "[FALTA HABILIDAD] No se encontró la habilidad: #{set[:ability]}"
    end
  end

  # Nature
  if set[:nature]
    if GameData::Nature.exists?(set[:nature])
      pkmn.nature = set[:nature]
    else
      puts "[FALTA NATURALEZA] No se encontró la naturaleza: #{set[:nature]}"
    end
  end
  
  #pkmn.tera_type = set[:tera_type] if set[:tera_type]

  if set[:evs]
    set[:evs].each do |stat_sym, value|
      begin
        stat = GameData::Stat.get(stat_sym)
        pkmn.ev[stat.id] = value
      rescue
        puts "[ERROR] EV stat no válida: #{stat_sym}"
      end
    end
  end

  if set[:ivs]
    set[:ivs].each do |stat_sym, value|
      begin
        stat = GameData::Stat.get(stat_sym)
        pkmn.iv[stat.id] = value
      rescue
        puts "[ERROR] IV stat no válida: #{stat_sym}"
      end
    end
  end

  # Moves
  if set[:moves]
    pkmn.forget_all_moves
    set[:moves].each do |m|
      if GameData::Move.exists?(m)
        pkmn.learn_move(m)
      else
        puts "[FALTA MOVE] No se encontró el movimiento: #{m}"
      end
    end
  end

  pkmn.calc_stats
end




SmogonSetData = {}

def build_smogon_set_database
  current_block = []
  SHOWDOWN_RAW_SETS.each_line do |line|
    if line.strip.empty?
      process_showdown_block(current_block) unless current_block.empty?
      current_block = []
    else
      current_block << line
    end
  end
  process_showdown_block(current_block) unless current_block.empty?
end

def process_showdown_block(lines)
  parsed = parse_showdown_set(lines.join)
  return unless parsed

  species = parsed[:species]
  item_sym = parsed[:set][:item]
  is_mega_item = item_sym && GameData::Item.exists?(item_sym) && GameData::Item.get(item_sym).is_mega_stone?

  # Forzamos mega si el item es una mega piedra
  key = (parsed[:is_mega] || is_mega_item) ? :mega : :normal

  SmogonSetData[species] ||= {}
  SmogonSetData[species][key] = parsed[:set].merge({ form: parsed[:form] || 0 })
end

def parse_showdown_set(text)
  lines = text.strip.split("\n")
  return nil if lines.empty?

  species_line = lines.shift
  species = nil
  item = nil
  is_mega = false

  if species_line =~ /^(.+?)\s@\s(.+)$/
    raw_species = $1.strip
    item = RandomTeamGenerator.translate_name($2)

    is_mega = raw_species.upcase.include?("-MEGA")
    lookup = raw_species.strip.upcase.gsub(/-MEGA/, "")
    species_data = RandomTeamGenerator::ONLINE_SETS_NAME_CORRECTIONS[lookup] || lookup.gsub(/[\s_-]/, "").to_sym

    if species_data.is_a?(Array)
      species = species_data[0]
      form = species_data[1]
    else
      species = species_data
      form = 0
    end
  else
    return nil
  end

  ability = nil
  nature = nil
  tera_type = nil
  evs = {}
  ivs = {}
  moves = []

  lines.each do |line|
    case line
    when /^Ability:\s(.+)$/i
      ability = RandomTeamGenerator.translate_name($1)
    when /^Tera Type:\s(.+)$/i
      tera_type = RandomTeamGenerator.translate_name($1)
    when /^EVs:\s(.+)$/i
      $1.split("/").each do |part|
        if part.strip =~ /^(\d+)\s+(\w+)$/i
          val = $1.to_i
          stat = RandomTeamGenerator.translate_name($2)
          evs[stat] = val
        end
      end
    when /^IVs:\s(.+)$/i
      $1.split("/").each do |part|
        if part.strip =~ /^(\d+)\s+(\w+)$/i
          val = $1.to_i
          stat = RandomTeamGenerator.translate_name($2)
          ivs[stat] = val
        end
      end
    when /^(\w+)\sNature/i
      nature = RandomTeamGenerator.translate_name($1)
    when /^-\s(.+)$/
      move = RandomTeamGenerator.translate_name($1)
      moves << move
    end
  end

  {
    species: species,
    form: form,
    is_mega: is_mega,
    set: {
      item: item,
      ability: ability,
      nature: nature,
      tera_type: tera_type,
      evs: evs,
      ivs: ivs,
      moves: moves
    }
  }
end





# Guarda el equipo actual y genera uno nuevo aleatorio
def generate_temp_team
  $original_player_party = $player.party.map(&:clone)
  $player.party.clear
  random_on = RandomizedChallenge.enabled?
  RandomizedChallenge.pause if random_on
  team = RandomTeamGenerator.generate_team
  team.each do |pkmn|
    apply_smogon_set(pkmn)
    $player.party << pkmn
  end
  RandomizedChallenge.resume if random_on
end


# Restaura el equipo anterior si existe
def restore_original_team
  if $original_player_party
    $player.party.clear
    $original_player_party.each { |pkmn| $player.party << pkmn.clone }
    $original_player_party = nil
    return true
  end
  return false
end

