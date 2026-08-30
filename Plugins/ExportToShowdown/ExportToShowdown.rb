SDWN_ALOLAN = {
  :RATTATA   => 1, :RATICATE  => 1, :RAICHU    => 1, :SANDSHREW  => 1,
  :SANDSLASH => 1, :VULPIX    => 1, :NINETALES => 1, :DIGLETT => 1,
  :DUGTRIO   => 1, :MEOWTH    => 1, :PERSIAN   => 1, :GEODUDE => 1,
  :GRAVELER  => 1, :GOLEM     => 1, :GRIMER    => 1, :MUK     => 1,
  :EXEGGUTOR => 1, :MAROWAK   => 1
}

SDWN_GALAR = {
  :PONYTA    => 1, :RAPIDASH   => 1, :SLOWPOKE   => 1, :SLOWBRO  => 1, :SLOWKING  => 1, 
  :FARFETCHD => 1, :WEEZING    => 1, :MRMIME     => 1, :ARTICUNO => 1, :ZAPDOS    => 1,
  :MOLTRES   => 1, :MEOWTH     => 2, :CORSOLA    => 1, :STUNFISK => 1, :ZIGZAGOON => 1, 
  :LINOONE   => 1, :DARUMAKA   => 2, :DARMANITAN => 2, :YAMASK   => 1, :MAROWAK   => 1
}

SDWN_HISUI = {
  :GOODRA       => 1, :AVALUGG   => 1, :LILLIGANT   => 1, :ZOROARK      => 1,
  :TYPHLOSION   => 1, :SAMUROTT  => 1, :DECIDUEYE   => 1, :ELECTRODE    => 1
}
 
SDWN_MOVES = { # Turns the left move into the right move. This for compatibility with custom moves.
  :CUSTOM1 => :TACKLE,
  :CUSTOM2 => :POUND,
  :CUSTOM3 => :SLAM
}

SDWN_ITEMS = { # Turns the left item into the right item. This for compatibility with custom items.
  :CUSTOM1 => :SITRUS_BERRY,
}

SDWN_ABS = { # Turns the left move into the right move. This for compatibility with custom moves.
  :REALEZA => :ADAPTABILITY,
  :ICEHEAD => :ROCKHEAD,
  :PODERGELIDO => :SLUSHRUSH,
  :BURNTOUCH => :FLAMEBODY
}

NATURES_MAP = {
    :HARDY => "Hardy",
    :LONELY => "Lonely",
    :BRAVE => "Brave",
    :ADAMANT => "Adamant",
    :NAUGHTY => "Naughty",
    :BOLD => "Bold",
    :DOCILE => "Docile",
    :RELAXED => "Relaxed",
    :IMPISH => "Impish",
    :LAX => "Lax",
    :TIMID => "Timid",
    :HASTY => "Hasty",
    :SERIOUS => "Serious",
    :JOLLY => "Jolly",
    :NAIVE => "Naive",
    :MODEST => "Modest",
    :MILD => "Mild",
    :QUIET => "Quiet",
    :BASHFUL => "Bashful",
    :RASH => "Rash",
    :CALM => "Calm",
    :GENTLE => "Gentle",
    :SASSY => "Sassy",
    :CAREFUL => "Careful",
    :QUIRKY => "Quirky"
}

def get_showdown_name(pokemon)
  species_name = GameData::Species.get(pokemon.species).name
  alolan_form = SDWN_ALOLAN[pokemon.species]
  galar_form = SDWN_GALAR[pokemon.species]
  hisui_form = SDWN_HISUI[pokemon.species]
  custom_poke = defined?(SDWN_PKMN) ? SDWN_PKMN[pokemon.species] : nil

  return "#{species_name}-Alola" if alolan_form && pokemon.form == alolan_form
  return "#{species_name}-Galar" if galar_form && pokemon.form == galar_form
  return "#{species_name}-Hisui" if hisui_form && pokemon.form == hisui_form
  return GameData::Species.get(custom_poke).name if custom_poke && GameData::Species.exists?(custom_poke)

  species_name
end

def get_showdown_move(move, moves_en)
  SDWN_MOVES[move.id] ? moves_en[SDWN_MOVES[move.id]] : moves_en[move.id]
end

def get_showdown_item(item, items_en)
  SDWN_ITEMS[item] ? items_en[SDWN_ITEMS[item]] : items_en[item]
end

def get_showdown_ability(ability, abs_en)
  SDWN_ABS[ability] ? abs_en[SDWN_ABS[ability]] : abs_en[ability] || 'Illuminate'
end

def format_stat_line(label, values)
  stats_map = {
    :HP => 'HP',
    :ATTACK => 'Atk',
    :DEFENSE => 'Def',
    :SPECIAL_ATTACK => 'SpA',
    :SPECIAL_DEFENSE => 'SpD',
    :SPEED => 'Spe'
  }
  return '' if label == 'IVs' && values.all? { |_, value| value == 0 }
  parts = values.each_pair.map do |key, value|
    next if value == 0 && label == 'IVs'
    "#{value.to_i == 0 ? 1 : value} #{stats_map[key]}"
  end.compact
  "#{label}: #{parts.join(' / ')}"
end

def values_to_hash(filename)
  hash = {}
  File.foreach(filename) do |line|
    key, value = line.strip.split(',', 2)
    next unless key && value && !value.empty?
    hash[key.to_sym] = value
  end
  hash
rescue Errno::ENOENT
  {}
end

def get_translations
  data_dir = File.join('Data', 'data_for_showdown')
  moves = values_to_hash(File.join(data_dir, 'moves_en.txt'))
  abs   = values_to_hash(File.join(data_dir, 'abs_en.txt'))
  items = values_to_hash(File.join(data_dir, 'items_en.txt'))
  [moves, abs, items]
end

def overwrite_showdown?
  return true unless FileTest.exist?('showdown.txt')

  pbConfirmMessage("Ya existe un archivo showdown.txt en la carpeta del juego.\n¿Desea sobreescribirlo?")
end

def pbShowdown
  return unless overwrite_showdown?
  moves_en, abs_en, items_en = get_translations

  ret = $player.party.compact.reject(&:egg?).map do |p|
    name_part = p.name != '' && p.name != GameData::Species.get(p.species).name ? "#{p.name} (#{get_showdown_name(p)})" : get_showdown_name(p)
    gender_part = case p.gender
                  when 0 then "(M)"
                  when 1 then "(F)"
                  else ""
                  end
    item_part = p.hasItem? ? " @ #{get_showdown_item(p.item.id, items_en)}" : ''
    ability_part = "Ability: #{get_showdown_ability(p.ability.id, abs_en)}"
    level_part = p.level < 100 ? "Level: #{p.level}" : ''
    shiny_part = p.shiny? ? 'Shiny: Yes' : ''
    happiness_part = p.happiness < 255 ? "Happiness: #{p.happiness}" : ''
    evs_part = format_stat_line('EVs', p.ev)
    ivs_part = format_stat_line('IVs', p.iv)
    nature_part = "#{NATURES_MAP[p.nature.id]} Nature"
    moves_part = p.moves.compact.reject { |m| !GameData::Move.exists?(m.id) }.map { |m| "- #{get_showdown_move(m, moves_en)}" }.join("\n")
    name_full = gender_part.empty? ? "#{name_part}#{item_part}" : "#{name_part} #{gender_part}#{item_part}"
    [
      name_full, ability_part, level_part, shiny_part, happiness_part,
      evs_part, ivs_part, nature_part, moves_part
    ].reject(&:empty?).join("\n") + "\n"
  end.join("\n")

  File.write('showdown.txt', ret)
  pbMessage("Se ha creado el archivo showdown.txt en la carpeta del juego.\nPuede usar este archivo para crear su equipo en Pokémon Showdown.")
end