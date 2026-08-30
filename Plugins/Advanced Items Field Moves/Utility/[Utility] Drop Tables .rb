#===============================================================================
# Can also be used in events, for custom drops
# └─► item = dropTableRoll(Drop table, rolls, luck)
# └─► dropped_loot(items)
#
#  add_drop
#    Item   = the item that drops
#           = if item is :NO_DROP it wont drop anything
#    Weight = chance for drop (all Weight is added together before the roll)
#             if weight = 0 it wount roll the drop
#    Minimun and Maximum drops that ot rolls between
#             so if [min 1] - [max 3] it drops 1-3 of the items
#    Luck Weight +/- = how much the Weight will be maniplued by pr luck
#    Allow Bonus Drop is either true or false, if not set is defualt false
#             if drop is rolled there is a 40% chance to get the another drop
#             it will guaranteed a extra drop pr 100%
#
#  add_drop_table_roll
#    When rolled will roll another table
#
#  add_guaranteed_drop
#    Will guaranteed a drop from the table
#
#   TABLE = createDropTable("Table Name") do |table|
#     table.add_drop(:Item, Weight, Minimun, Maximum, Luck Weight +/-, Allow bonus drop)
#     table.add_guaranteed_drop(:Item, Minimun, Maximum, Allow bonus drope)
#     table.add_drop(:NO_DROP, Weight, 0, 0, Luck Weight +/-, Allow bonus drop)
#     table.add_drop_table_roll(TABLE_2, Weight, Luck Weight +/-)
#   end
#
# => Math Behind Weight
#===============================================================================
#===============================================================================
# Drop table
#===============================================================================
class ItemDropTable
  attr_accessor :name
  def initialize
    @drops = []
    @guaranteed_drops = []
  end

  def add_drop(item_id, weight, min_quantity = 1, max_quantity = nil, luck_modifier = 0, luck_drops = false, multiplier = 0, pkmn = nil)
    max_quantity ||= min_quantity
    if item_id == "Nothing"
      @drops.push({type: :nothing, weight: weight, luck_modifier: luck_modifier})
    elsif item_id == "Money"
      @drops.push({type: :money, weight: weight, min_quantity: min_quantity, max_quantity: max_quantity, luck_modifier: luck_modifier, luck_drops: luck_drops, multiplier: multiplier})
    elsif item_id == "Battle Points"
      @drops.push({type: :battle_points, weight: weight, min_quantity: min_quantity, max_quantity: max_quantity, luck_modifier: luck_modifier, luck_drops: luck_drops, multiplier: multiplier})
    elsif item_id == "Coins"
      @drops.push({type: :coins, weight: weight, min_quantity: min_quantity, max_quantity: max_quantity, luck_modifier: luck_modifier, luck_drops: luck_drops, multiplier: multiplier})
    elsif item_id == "Pokemon"
      @drops.push({type: :pokemon, weight: weight, pkmn: pkmn})
    else
      @drops.push({item_id: item_id, weight: weight, min_quantity: min_quantity, max_quantity: max_quantity, luck_modifier: luck_modifier, luck_drops: luck_drops})
    end
  end

  def add_drop_table_roll(drop_table, weight, luck_modifier = 0)
    @drops.push({type: :drop_table_roll, drop_table: drop_table, drop_table_name: ItemDropTable.format_name(drop_table.name), weight: weight, luck_modifier: luck_modifier})
  end

  def add_guaranteed_drop(item_id, min_quantity, max_quantity, luck_drops = false)
    @guaranteed_drops.push({item_id: item_id, min_quantity: min_quantity, max_quantity: max_quantity, luck_drops: luck_drops})
  end

  def roll(luck = 0, details = AIFM_Debug[:showDrops])
    dropped_items = []
    puts "" if $DEBUG && details
    puts "DEBUG: Rolling with luck #{luck}" if $DEBUG && details
    # Roll guaranteed drops
    @guaranteed_drops.each do |drop|
      quantity = rand(drop[:max_quantity] - drop[:min_quantity] + 1) + drop[:min_quantity]
      dropped_items.push({item_id: drop[:item_id], quantity: quantity})
      puts "DEBUG: Guaranteed drop: #{quantity} #{drop[:item_id]}" if $DEBUG
    end
    # Roll normal drops
    adjusted_drops = @drops.map do |drop|
      weight = drop[:weight] + (drop[:luck_modifier] || 0) * luck
      if drop[:item_id] && drop[:item_id] != "Nothing" && weight < 1
        next
      elsif drop[:type] == :drop_table_roll && weight < 1
        next
      end
      drop
    end.compact
    total_weight = adjusted_drops.sum { |drop| drop[:weight] }
    roll = rand(total_weight)
    cumulative_weight = 0
    adjusted_drops.each do |drop|
      cumulative_weight += drop[:weight]
      if roll < cumulative_weight
        if drop[:item_id]
          quantity = rand(drop[:max_quantity] - drop[:min_quantity] + 1) + drop[:min_quantity]
          dropped_items.push({item_id: drop[:item_id], quantity: quantity})
          puts "DEBUG: Rolled item: #{quantity} #{drop[:item_id]}" if $DEBUG
          if drop[:luck_drops]
            extra_rolls = 0
            luck_chance = luck * 0.4
            extra_rolls += luck_chance.floor # guaranteed extra rolls
            if rand < luck_chance % 1 # check for fractional chance
              extra_rolls += 1
            end
            extra_rolls.times do
              extra_quantity = rand(drop[:max_quantity] - drop[:min_quantity] + 1) + drop[:min_quantity]
              dropped_items.push({item_id: drop[:item_id], quantity: extra_quantity})
              puts "DEBUG: Rolled extra #{extra_quantity} #{drop[:item_id]} due to luck" if $DEBUG
            end
          end
        elsif drop[:type] == :money
          quantity = rand(drop[:max_quantity] - drop[:min_quantity] + 1) + drop[:min_quantity]
          dropped_items.push({item_id: "Money", quantity: quantity * drop[:multiplier]})
          puts "DEBUG: Rolled #{quantity * drop[:multiplier]} Money" if $DEBUG
        elsif drop[:type] == :battle_points
          quantity = rand(drop[:max_quantity] - drop[:min_quantity] + 1) + drop[:min_quantity]
          dropped_items.push({item_id: "Battle Points", quantity: quantity * drop[:multiplier]})
          puts "DEBUG: Rolled #{quantity * drop[:multiplier]} Battle Points" if $DEBUG
        elsif drop[:type] == :coins
          quantity = rand(drop[:max_quantity] - drop[:min_quantity] + 1) + drop[:min_quantity]
          dropped_items.push({item_id: "Coins", quantity: quantity * drop[:multiplier]})
          puts "DEBUG: Rolled #{quantity * drop[:multiplier]} Coins" if $DEBUG
        elsif drop[:type] == :pokemon
          pkmn = drop[:pkmn]
          dropped_items.push({item_id: "Pokemon", quantity: 1, pkmn: pkmn})
          puts "DEBUG: Rolled Pokemon: #{pkmn[:species]}" if $DEBUG
        elsif drop[:type] == :nothing
          dropped_items.push({item_id: "Nothing"})
          puts "DEBUG: Rolled Nothing" if $DEBUG
        elsif drop[:type] == :drop_table_roll
          drop_table_name = drop[:drop_table_name]
          puts "DEBUG: Rolling drop table: #{drop_table_name}" if $DEBUG && details
          items = drop[:drop_table].roll(luck, false)
          dropped_items += items
          items.each do |item|
            puts "DEBUG: Rolled item from #{drop_table_name}: #{item[:quantity]} #{item[:item_id]}" if $DEBUG && details
          end
        end
        break
      end
    end
    puts "DEBUG: Final accumulated items to: #{dropped_items.inspect}" if $DEBUG && details
    ItemDropTable.accumulate_items(dropped_items)
  end

  def self.format_name(name)
    name.to_s.gsub(/([A-Z])/) { " #{$1}" }.strip.split.map(&:capitalize).join(' ')
  end
  # Methods for creating and rolling drop tables
  def dropTableRoll(drop_table, rolls, luck)
    ItemDropTable.dropTableRoll(drop_table, rolls, luck)
  end

  def self.createDropTable(name, &block)
    drop_table = ItemDropTable.new
    drop_table.name = name
    block.call(drop_table)
    drop_table
  end

  def self.dropTableRoll(drop_table, rolls = 1, luck = 0, bonus = true)
    dropped_items = []
    rolls.times do
      items = drop_table.roll(luck)
      dropped_items += items
    end
    ItemDropTable.accumulate_items(dropped_items)
  end

  def self.accumulate_items(dropped_items)
    pokemon_items = []
    other_items = []
    dropped_items.each do |item|
      if item[:item_id] == "Pokemon"
        pokemon_items << item
      else
        other_items << item
      end
    end

    accumulated_other_items = other_items.each_with_object({}) do |item, acc|
      if item[:item_id] == "Nothing"
        acc["Nothing"] ||= {item_id: "Nothing", quantity: 0}
        acc["Nothing"][:quantity] += 1
      else
        next unless item && item[:item_id] && item[:quantity]
        acc[item[:item_id]] ||= {item_id: item[:item_id], quantity: 0}
        acc[item[:item_id]][:quantity] += item[:quantity]
      end
    end.values

    accumulated_other_items + pokemon_items
  end

  def self.dropped_loot(items)
    puts "" if $DEBUG
    puts "DEBUG: Giving player the following items: #{items.map { |item| "#{item[:quantity]} #{item[:item_id]}" }.join(", ")}" if $DEBUG

    pokemon_items = []
    other_items = []
    items.each do |item|
      if item[:item_id] == "Pokemon"
        pokemon_items << item
      else
        other_items << item
      end
    end

    other_items.each do |item|
      if item[:item_id] == "Nothing"
        puts "Nothing dropped" if $DEBUG
      elsif item[:item_id] == "Money"
        $player.money += item[:quantity]
        pbMessage(_INTL("Encontraste #{item[:quantity]} Poké Dólares!"))
        puts "Dropped #{item[:quantity]} Money" if $DEBUG
      elsif item[:item_id] == "Battle Points"
        $player.battle_points += item[:quantity]
        pbMessage(_INTL("¡Ganaste #{item[:quantity]} Puntos de Batalla!"))
        puts "Dropped #{item[:quantity]} Battle Points" if $DEBUG
      elsif item[:item_id] == "Coins"
        $player.coins += item[:quantity]
        pbMessage(_INTL("Encontraste #{item[:quantity]} Monedas!"))
        puts "Dropped #{item[:quantity]} Coins" if $DEBUG
      elsif GameData::Item.exists?(item[:item_id])
        $bag.add(item[:item_id], item[:quantity])
        pbMessage(_INTL("Encontraste #{item[:quantity]} #{GameData::Item.get(item[:item_id]).name}!"))
        puts "Dropped #{item[:quantity]} #{GameData::Item.get(item[:item_id]).name}" if $DEBUG
      else
        puts "Unknown item: #{item[:item_id]}" if $DEBUG
      end
    end

    pokemon_items.each do |item|
      if item[:item_id] == "Pokemon" && item[:pkmn]
        pkmn = item[:pkmn]
        if pkmn[:is_egg]
          pokemon = Pokemon.new(pkmn[:species], Settings::EGG_LEVEL)
          pokemon.name = _INTL("Huevo")
          pokemon.steps_to_hatch = pokemon.species_data.hatch_steps
        else
          owner = Pokemon::Owner.new(pkmn[:id], pkmn[:ot], 0, 1)
          pokemon = Pokemon.new(pkmn[:species], pkmn[:level], owner)
          pokemon.name = pkmn[:nickname] if pkmn[:nickname]
          pokemon.item = pkmn[:held_item] if pkmn[:held_item]
        end
        pokemon.poke_ball = pkmn[:ball] if pkmn[:ball]
        pokemon.form = pkmn[:form] if pkmn[:form]
        pokemon.shiny = pkmn[:shiny] if pkmn[:shiny]
        if pkmn[:gender].is_a?(Symbol) && pokemon.respond_to?(pkmn[:gender])
          pokemon.send(pkmn[:gender])
        end
        pokemon.ability = pkmn[:ability] if pkmn[:ability]
        pokemon.nature = pkmn[:nature] if pkmn[:nature]
        if pkmn[:moves]
          pkmn[:moves].each do |move|
            pokemon.learn_move(move)
          end
        end
        pokemon.happiness = pkmn[:happiness] if pkmn[:happiness]
        pokemon.poke_ball = pkmn[:ball] if pkmn[:ball]
        if pkmn[:iv]
          [:hp, :attack, :defense, :spatk, :spdef, :speed].each do |stat|
            pkmn[:iv][stat] = 0 if pkmn[:iv][stat].nil?
          end
          pokemon.iv = {
            :HP => pkmn[:iv][:hp],
            :ATTACK => pkmn[:iv][:attack],
            :DEFENSE => pkmn[:iv][:defense],
            :SPECIAL_ATTACK => pkmn[:iv][:spatk],
            :SPECIAL_DEFENSE => pkmn[:iv][:spdef],
            :SPEED => pkmn[:iv][:speed]
          }
        end
        if pkmn[:iv_random]
          ivs = generate_ivs(pkmn[:iv_random][0], pkmn[:iv_random][1])
          pokemon.iv = {
            :HP => ivs[:hp],
            :ATTACK => ivs[:attack],
            :DEFENSE => ivs[:defense],
            :SPECIAL_ATTACK => ivs[:spatk],
            :SPECIAL_DEFENSE => ivs[:spdef],
            :SPEED => ivs[:speed]
          }
        end
        if pkmn[:ev]
          [:hp, :attack, :defense, :spatk, :spdef, :speed].each do |stat|
            pkmn[:ev][stat] = 0 if pkmn[:ev][stat].nil?
          end
          pokemon.ev = {
            :HP => pkmn[:ev][:hp],
            :ATTACK => pkmn[:ev][:attack],
            :DEFENSE => pkmn[:ev][:defense],
            :SPECIAL_ATTACK => pkmn[:ev][:spatk],
            :SPECIAL_DEFENSE => pkmn[:ev][:spdef],
            :SPEED => pkmn[:ev][:speed]
          }
        end
        pokemon.calc_stats
        pbAddPokemonSilent(pokemon)
        if pkmn[:is_egg]
          pbMessage(_INTL("¡Recibiste un Huevo!"))
        else
          pbMessage(_INTL("¡Recibiste un #{pokemon.species}!"))
        end
        puts "Dropped Pokemon: #{pokemon.species}" if $DEBUG && !pkmn[:is_egg]
        puts "Dropped Egg" if $DEBUG && pkmn[:is_egg]
      end
    end
    puts "" if $DEBUG
  end

  def self.debugDropTable(drop_table, luck = 0)
    table_name = drop_table.name
    puts "" if $DEBUG
    puts " #{"#{table_name}".ljust(37)} #{"Current".ljust(7)}|| #{"Luck / Procent".ljust(7)}" if $DEBUG
    puts "#{"=======Name=======".ljust(22)} #{"====Drops====".ljust(16)} #{"[#{luck}]".ljust(6)}||#{"".ljust(3)}#{"(0)".ljust(9)}#{"(1)".ljust(9)}#{"(2)".ljust(9)}#{"(3)".ljust(9)}#{"(4)".ljust(9)}" if $DEBUG
    drop_table.instance_variable_get(:@drops).each do |drop|
      item_name = ""
      if drop[:type] == :nothing
        item_name = _INTL("Nada")
      elsif drop[:type] == :money
        item_name = _INTL("Dinero")
      elsif drop[:type] == :battle_points
        item_name = _INTL("Puntos de Batalla")
      elsif drop[:type] == :coins
        item_name = _INTL("Monedas")
      elsif drop[:type] == :pokemon
        item_name = _INTL("Pokémon")
      elsif GameData::Item.exists?(drop[:item_id])
        item_name = ItemDropTable.format_name(GameData::Item.get(drop[:item_id]).name)
      elsif drop[:type] == :drop_table_roll
        item_name = drop_table.name
      else
        item_name = _INTL("Desconocido")
      end
      chances = [0, 1, 2, 3].map do |luck_value|
        weight = drop[:weight] + (drop[:luck_modifier] || 0) * luck_value
        weight = [weight, 0].max
        total_weight = drop_table.instance_variable_get(:@drops).sum do |d|
          d_weight = d[:weight] + (d[:luck_modifier] || 0) * luck_value
          [d_weight, 0].max
        end
        (weight.to_f / total_weight * 100).round(2)
      end
      current_chance = (drop[:weight] + (drop[:luck_modifier] || 0) * luck).to_f
      current_total_weight = drop_table.instance_variable_get(:@drops).sum do |d|
        d_weight = d[:weight] + (d[:luck_modifier] || 0) * luck
        [d_weight, 0].max
      end
      current_chance = (current_chance / current_total_weight * 100).round(2)
      if drop[:type] == :drop_table_roll
        puts "#{"".ljust(2)}#{drop_table.name.ljust(32)}#{format("%5.1f%%", current_chance).ljust(8)}|| #{format("%5.1f%%", chances[0]).ljust(9)}#{format("%5.1f%%", chances[0]).ljust(9)}#{format("%5.1f%%", chances[1]).ljust(9)}#{format("%5.1f%%", chances[2]).ljust(9)}#{format("%5.1f%%", chances[3]).ljust(9)}" if $DEBUG
      else
        if drop[:min_quantity] && drop[:max_quantity]
          min_width = [drop[:min_quantity].to_s.length, drop[:max_quantity].to_s.length].max
          formatted_drop = "[#{sprintf("%#{min_width}d", drop[:min_quantity])} - #{sprintf("%#{min_width}d", drop[:max_quantity])}]".ljust(14)
        elsif drop[:type] == :pokemon
          formatted_drop = "[1]".ljust(14)
        else
          formatted_drop = _INTL("[Nada]").ljust(14)
        end
        puts "#{"".ljust(2)}#{item_name.ljust(22)}#{formatted_drop}#{format("%5.1f%%", current_chance).ljust(8)}|| #{format("%5.1f%%", chances[0]).ljust(9)}#{format("%5.1f%%", chances[0]).ljust(9)}#{format("%5.1f%%", chances[1]).ljust(9)}#{format("%5.1f%%", chances[2]).ljust(9)}#{format("%5.1f%%", chances[3]).ljust(9)}" if $DEBUG
      end
    end
  end
end

def foreign?(trainer = $player)
  return (@trainer_id || 0) != trainer.id || (@ot || "") != trainer.name
end

def generate_ivs(iv, number)
  stats = [:hp, :attack, :defense, :spatk, :spdef, :speed]
  perfect_stats = stats.shuffle.take(number)
  ivs = {}
  stats.each do |stat|
    ivs[stat] = perfect_stats.include?(stat) ? iv : rand(32)
  end
  ivs
end

def debugDropTable(drop_table, luck = 0)
  ItemDropTable.debugDropTable(drop_table, luck)
end

def dropTableRoll(drop_table, rolls = 1, luck = 0)
  ItemDropTable.dropTableRoll(drop_table, rolls, luck)
end

def dropped_loot(items)
  ItemDropTable.dropped_loot(items)
end

def roll_and_loot(drop_table, rolls = 1, luck = 0, bonus = true)
  items = []
  rolls.times do
    items += drop_table.roll(luck)
  end
  ItemDropTable.dropped_loot(items)
end

#def roll_and_loot(drop_table, rolls = 1, luck = 0, bonus = true)
#  items = ItemDropTable.dropTableRoll(drop_table, rolls, luck, bonus)
#  dropped_quantity = items.reject { |item| item[:item_id] == "Nothing" }.sum { |item| item[:quantity] }
#  ItemDropTable.dropped_loot(items)
#end

#$stats.ice_drop_count += dropped_quantity if dropped_quantity > 0 && drop_table == DROP_ICE_BLOCK

#===============================================================================
# Ice Block (Smash) Drop Table
#===============================================================================
RARE_ICE_BLOCK = ItemDropTable.createDropTable("Rare Ice Block") do |table|
  table.add_drop(:NUGGET, 99, 1, 1, 0, false)       #99% to get this drop from the table
  table.add_drop(:COMETSHARD, 1, 1, 1, 0, false)    #1% to get this drop from the table
end

MAIN_ICE_BLOCK = ItemDropTable.createDropTable("Main Ice Block") do |table|
  table.add_drop(:ICYROCK, 15, 1, 1, 0, true)       #15% to get this drop from the table
  table.add_drop(:ICESTONE, 25, 1, 1, 0, true)      #25% to get this drop from the table
  table.add_drop(:NEVERMELTICE, 55, 1, 1, 0, true)  #55% to get this drop from the table
  table.add_drop_table_roll(RARE_ICE_BLOCK, 5, 0)   #5% to get this, then get a drop from rare
end

DROP_ICE_BLOCK = ItemDropTable.createDropTable("Drop Ice Block") do |table|
  table.add_drop(_INTL("Nada"), 95, 0, 0, -5, false)     #95% not to get a drop
  table.add_drop_table_roll(MAIN_ICE_BLOCK, 5, 5)   #5%to get this, then get a drop from Main
end

DROP_DEBUG_TEST = ItemDropTable.createDropTable("DEBUG Test Table") do |table|
  table.add_drop(_INTL("Nada"), 1, 0, 0, -5, false)
  table.add_drop(_INTL("Dinero"), 1, 10, 20, 0, false, 100)
  table.add_drop(_INTL("Puntos de Batalla"), 1, 1, 5, 0, false, 10)
  table.add_drop(_INTL("Monedas"), 1, 1, 5, 0, false, 10)
  table.add_drop(_INTL("Pokémon"), 100, 1, 1, 0, false, 0, {
    #is_egg: true,           # => Is it an Egg
    species: :MAGIKARP,     # => Pokemon species
    level: 10,              # => Level, if it is an egg is level is set to Settings::EGG_LEVEL
    form: 0,                # => Alternative from
    shiny: true,            # => If true is Guarantee Shiny, if false is Shiny Locked
    gender: :makeMale,      # => makeMale, makeFemale
    ability: :RATTLED,      # => Ability
    nature: :JOLLY,          # => Nature
    held_item: :SHARPBEAK,  # => Held Item
    nickname: "Ace",        # => Nickname of the pokemon if EGG then it can be nicknamed
    happiness: 255,         # => Happiness level
    ball: :CHERISHBALL,     # => In Pokeball
    moves: [:TACKLE,:BOUNCE,:DRAGONRAGE], # => Moves
    iv: { :hp => 31, :attack => 31, :defense => 31, :spatk => 31, :spdef => 31, :speed => 31 },
    #iv_random: [31, 3],     # => First number setting iv to (31) for (3) random ivs
    ev: { :hp => 0, :attack => 252, :defense => 6, :spatk => 0, :spdef => 0, :speed => 252 }, # => Max 510 in total
    ot: "Bergium",           # => Owner Name
    id: 1989,              # => ID Number

})
  # ...
end
