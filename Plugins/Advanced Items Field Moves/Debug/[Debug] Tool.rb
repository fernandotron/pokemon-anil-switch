#===============================================================================
# Debug Testing Tool
#=================================[Show Stats]=================================#
def format_stat(value)
  if value.nil?
    "\e[31m [N/A]\e[0m" # Red color for N/A
  elsif value == 0
    "\e[33m#{format("%6d", value)}\e[0m" # Yellow color for 0
  else
    "\e[32m#{format("%6d", value)}\e[0m" # Green color for values greater than 0
  end
end

def showGameStats
  if $DEBUG
    configs = [
      { name: "Rock Smash", stat_name: "rock_smash", config_name: :Show_RockSmash, battle: "rock_smash_battles" },
      { name: "Cut", stat_name: "cut", config_name: :Show_Cut },
      { name: "Ice Block", stat_name: "ice", config_name: :Show_IceSmash, drop: "ice_drop_count"},
      { name: "Headbutt", stat_name: "headbutt", config_name: :Show_Headbutt },
      { name: "Sweetscent", stat_name: "sweetscent", config_name: :Show_SweetScent },
      { name: "Strength", stat_name: "strength", config_name: :Show_Strength, push: "strength_push_count"},
      { name: "Flash", stat_name: "flash", config_name: :Show_Flash },
      { name: "Defog", stat_name: "defog", config_name: :Show_Defog },
      { name: "Weather", stat_name: "weather", config_name: :Show_Weather },
      { name: "Camouflage", stat_name: "camouflage", config_name: :Show_Camouflage },
      { name: "Surf", stat_name: "surf", config_name: :Show_Surf, travel: "distance_surfed" },
      { name: "Dive", stat_name: "dive", config_name: :Show_Dive },
      { name: "Dive Ascend", stat_name: "dive_ascend", config_name: :Show_Dive },
      { name: "Dive Descend", stat_name: "dive_descend", config_name: :Show_Dive },
      { name: "Waterfall", stat_name: "waterfall", config_name: :Show_Waterfall },
      { name: "Whirlpool", stat_name: "whirlpool_cross", config_name: :Show_Whirlpool },
      { name: "Fly", stat_name: "fly", config_name: :Show_Fly },
      { name: "Dig", stat_name: "dig", config_name: :Show_Dig },
      { name: "Teleport", stat_name: "teleport", config_name: :Show_Teleport },
      { name: "Rockclimb Ascend", stat_name: "rockclimb_ascend", config_name: :Show_RockClimb },
      { name: "Rockclimb Descend", stat_name: "rockclimb_descend", config_name: :Show_RockClimb },
      { name: "Lifted", stat_name: "lift", config_name: :Show_Lift },
      { name: "Lava Surf", stat_name: "lavasurf", config_name: :Show_Surf, travel: "distance_lavasurfed" },
    ]

    configs.concat([{ name: "Secret Base", stat_name: "secret_power", config_name: :Show_SecretBase, moved: "moved_secret_base_count" }]) if PluginManager.installed?("Secret Bases Remade")

    if $DEBUG
      puts ""
      puts " [Game Stats] Advanced Items - Field Moves "
      configs.each do |config|
        next unless Object.const_defined?(config[:config_name])
        enable = Object.const_get(config[:config_name])
        status = (enable[:item] || enable[:move]) ? "\e[32m■\e[0m" : "\e[31m■\e[0m"
        stat_name = config[:stat_name]
        count_stat = format_stat($stats.send("#{stat_name}_count"))
        item_stat = format_stat($stats.send("item_#{stat_name}_count"))
        move_stat = format_stat($stats.send("move_#{stat_name}_count"))
        other_stat = []
        other_stat.push " \e[35m#{"Push:".ljust(9)}\e[0m #{format_stat($stats.send(config[:push]))} |" if config[:push]
        other_stat.push " \e[35m#{"Battle:".ljust(9)}\e[0m #{format_stat($stats.send(config[:battle]))} |" if config[:battle]
        other_stat.push " \e[35m#{"Traveled:".ljust(9)}\e[0m #{format_stat($stats.send(config[:travel]))} |" if config[:travel]
        other_stat.push " \e[35m#{"Drops:".ljust(9)}\e[0m #{format_stat($stats.send(config[:drop]))} |" if config[:drop]
        other_stat.push " \e[35m#{"Moved:".ljust(9)}\e[0m #{format_stat($stats.send(config[:moved]))} |" if config[:moved]
        formatted_name = config[:name].ljust(20) # Adjust the number for desired padding
        push_space = ("").ljust(1) # Adjust the number for desired padding
        other_stat = other_stat.compact
        puts "#{push_space} #{status} #{formatted_name} - \e[35mUses:\e[0m #{count_stat} | \e[35mItem:\e[0m #{item_stat} | \e[35mMove:\e[0m #{move_stat} |#{other_stat.empty? ? " ================ |" : other_stat.join}"
      end
    end
  end
end

#===============================================================================
# Debug Testing Tool
#==================================[Actived?]==================================#

def format_status(enabled, label)
  enabled ? "\e[35m[#{label}]\e[0m \e[32m☑\e[0m" : "\e[35m[#{label}]\e[0m \e[31m✖\e[0m"
end

def aifm_configurations
  ordered_configs = [
    :Show_RockSmash, :Show_Cut, #:Show_IceSmash,                                 # Obstacle Smash
    :Show_Headbutt, #:Show_SweetScent,                                           # Encounters
    :Show_Strength, :Show_Flash, :Show_Defog, :Show_Weather, :Show_Camouflage,  # Environment Interactions
    :Show_Surf, :Show_Dive, :Show_Waterfall, :Show_Whirlpool,                   # Water Movement
    :Show_Fly, :Show_Dig, :Show_Teleport, :Show_RockClimb,                      # Other Movement
    # :Show_LavaSurf, :Show_Lavafall, :Show_LavaSwirl,                            # Lava Movement
    # :Show_Lift, :Show_SenseTruth,                                               # Zelda Stuff
  ]

  ordered_configs.concat([:Show_SecretBase]) if PluginManager.installed?("Secret Bases Remade")

  puts "\e[33m     Advanced Items & Field Moves Configurations:\e[0m"
  ordered_configs.each do |config_name|
    next unless Object.const_defined?(config_name)

    config = Object.const_get(config_name)
    if config_name == :Show_Weather && [:Show_WP1, :Show_WP2, :Show_WP3].any? { |wp| Object.const_defined?(wp) && Object.const_get(wp)[:item] }
      item_status = "\e[35m[#{"Item"}]\e[0m \e[32m☑\e[0m"
    else
      item_status = format_status(config[:item], "Item")
    end
    move_status = format_status(config[:move], "Move")
    pp_status = format_status(config[:uses_pp], "Uses PP")
    overall_status = (config[:item] || config[:move]) ? "\e[32m■\e[0m" : "\e[31m■\e[0m"

    display_name = config_name.to_s.sub(/^Show_/, '')
    formatted_name = display_name.ljust(15)
    push_space = ("").ljust(20)
    puts "#{push_space}\e[33m└─►\e[0m #{overall_status} \e[33m#{formatted_name}\e[0m - #{item_status} | #{move_status} | #{pp_status}"
  end
end

def aifm_music_pockets
  puts "\e[33m     Advanced Items & Field Moves Pokcets:\e[0m"
  pocket_number = 1
  [:AIFM_Pocket1, :AIFM_Pocket2, :AIFM_Pocket3].each do |config_name|
    next unless Object.const_defined?(config_name)

    config = Object.const_get(config_name)
    overall_status = (config[:item]) ? "\e[32m■\e[0m" : "\e[31m■\e[0m"

    name = config[:internal_name].to_s
    display_name = config[:item] ? "Pocket #{pocket_number} (#{name})" : "(#{name})"
    formatted_name = display_name.ljust(25)
    push_space = ("").ljust(20)
    puts "#{push_space}\e[33m└─►\e[0m #{overall_status} \e[33m#{formatted_name}\e[0m"
    pocket_number += 1 if config[:item]
  end
end

# Call the method when the game starts up
if $DEBUG && AIFM_Debug[:boot]
  aifm_configurations
  aifm_music_pockets if AIFM_Debug[:showbootpocket]
end

# Call the method when pbShowAIFM is called
def pbShowAIFM
  aifm_configurations
end
