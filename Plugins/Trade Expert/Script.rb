#===============================================================================
#  The Trade Expert
#    by Luka S.J.
#
#  Provides an emulated experience of Wonder Trade, but uses the base stat total
#  of a Pokemon species to determine which Pokemon you'll obtain from the trade.
#  Includes dialogues to make the event more interesting when trading your Pokemon.
#  To use, simply call it in an event via the script command:
#      tradeExpert(margin)
#  where margin is a percentage value (from 0.0 to 1.0) that determines the
#  increase in upper and lower base stat total values for the traded Pokemon.
#  By default, it is set to 0.1; meaning that the Pokemon you recieve will be
#  in the base stat total range of within 90% - 110% of the base stat total of
#  the Pokemon you're giving up for trade. The 'margin' parameter can be
#  omitted.
#  Look at the 'def tradePokemon' if you want to customize the Pokemon you're
#  getting from the trade even further.
#
#  Enjoy the script, and make sure to give credit!
#===============================================================================
# Main class for handling the Trade Expert
#===============================================================================
module TradeExpert
  #-----------------------------------------------------------------------------
  # starts up the Trade Expert
  #-----------------------------------------------------------------------------
  def self.start(margin = 0.1, skip_intro = false)
    # flavour text displaying a little intro for the Trade Expert
    self.displayMsg("intro") if !skip_intro
    # confirmation for the trade
    if self.confirmMsg("asktrade")
      chosen = self.givePokemon
      if chosen.nil?
        self.displayMsg("invalid")
        return false
      end
      give = $PokemonStorage[chosen[0], chosen[1]]
      if give.nil?
        self.displayMsg("invalid")
        return false
      end
      giveBST = self.calcBST(give.species)
      # protects trading from abuse
      if !$cachedTrade["#{giveBST}"].nil?
        recv = $cachedTrade["#{giveBST}"]
      else
        recv = self.fetchEqualSpecies(give.species, margin)
        # cancels the trade if the Trade Expert cannot offer you anything in return
        if recv.length < 1
          self.displayMsg("notrade", GameData::Species.get(give.species).real_name)
          return false
        end
        recv = recv[rand(recv.length - 1)]
      end
      self.displayMsg("thinking")
      bst = self.calcBST(recv)
      # flavour text displayed when evaluating the offered Pokemon species
      if bst <= 200
        self.displayMsg("trade0", GameData::Species.get(give.species).real_name)
      elsif bst <= 300
        self.displayMsg("trade1", GameData::Species.get(give.species).real_name)
      elsif bst <= 400
        self.displayMsg("trade2", GameData::Species.get(give.species).real_name)
      elsif bst <= 500
        self.displayMsg("trade3", GameData::Species.get(give.species).real_name)
      elsif bst <= 600
        self.displayMsg("trade4", GameData::Species.get(give.species).real_name)
      else
        self.displayMsg("trade5", GameData::Species.get(give.species).real_name)
      end
      # protects trading from abuse
      $cachedTrade["#{giveBST}"] = recv
      # final confirmation for the trade
      recv_data = GameData::Species.get(recv)
      if self.confirmMsg("propose", recv_data.real_name, GameData::Species.get(give.species).real_name)
        $cachedTrade.delete("#{giveBST}")
        self.tradePoke(chosen, recv)
        self.displayMsg("accepttrade")
        self.saveCache
        return true
      else
        self.displayMsg("rejecttrade")
        self.saveCache
        return true
      end
    else
      # the trade was cancelled at the start
      self.displayMsg("canceltrade")
      return false
    end
  end
  #-----------------------------------------------------------------------------
  # method used to calculate the base stat total of a Pokemon
  #-----------------------------------------------------------------------------
  def self.calcBST(species)
    stats = GameData::Species.get(species).base_stats
    bst = 0
    for stat in stats.keys
      bst += stats[stat]
    end
    return bst
  end
  #-----------------------------------------------------------------------------
  # get all species keys
  #-----------------------------------------------------------------------------
  # def self.all_species
  #   keys = []
  #   GameData::Species.each { |species| keys.push(species.id) if species.form == 0 }
  #   return keys
  # end
  #-----------------------------------------------------------------------------
  # method used to return a list of Pokemon that would be of similar value to your Pokemon
  #-----------------------------------------------------------------------------
  def self.fetchEqualSpecies(poke, margin = 0.1)
    if defined?(RandomizedChallenge) && RandomizedChallenge.enabled?
      if defined?(MonotypeChallenge) && MonotypeChallenge.enabled?
        species = valid_random_species(nil, false, MonotypeChallenge.type)
        species = valid_random_species(nil, false, MonotypeChallenge.type) while species == poke
        return [species]
      end
      species = valid_random_species
      species = valid_random_species while species == poke
      return [species]
    end
    bst = self.calcBST(poke)
    upper = bst*(1 + margin)
    lower = bst*(1 - margin)
    potential = []
    species_list = GameData::Species.all_species
    if defined?(MonotypeChallenge) && MonotypeChallenge.enabled?
      species_list = species_list.select { |s| MonotypeChallenge.valid_monotype?(s) }
    end
    for spec in species_list
      stats = self.calcBST(spec)
      potential.push(spec) if stats >= lower && stats <= upper && !TradeExpert::TRADING_BLACKLIST.include?(spec) && spec != poke
    end
    return potential
  end
  #-----------------------------------------------------------------------------
  # brings up the UI to select a Pokemon to give to the Trade Expert
  #-----------------------------------------------------------------------------
  def self.givePokemon
    # decides the parameters that determine Pokemon trade elegibility
    ableProc = proc{|poke| !poke.egg? && !poke.shadowPokemon? && !poke.fainted? && !TradeExpert::GIVING_BLACKLIST.include?(poke.species)}
    give = pbChooseTradeExpertPokemonPC(ableProc)
    return give
  end
  #-----------------------------------------------------------------------------
  # brings up the trading UI (you can further customize the traded Pokemon here)
  #-----------------------------------------------------------------------------
  def self.tradePoke(give, recv)
    myPokemon = give.is_a?(Integer) ? $player.party[give] : $PokemonStorage[give[0], give[1]]
    # name of the Trade Expert is decided here
    opponent = NPCTrainer.new("Don Prodigio","DONPRODIGIO")
    # custom trainer ID of the Trade Expert
    opponent.id = 1204
    # generates the Pokemon
    if defined?(RandomizedChallenge) && RandomizedChallenge.enabled?
      RandomizedChallenge.pause_random_species
      yourPokemon = Pokemon.new(recv, myPokemon.level, opponent) 
      RandomizedChallenge.resume_random_species
    else
      yourPokemon = Pokemon.new(recv, myPokemon.level, opponent) 
    end
    
    # Aumentar la probabilidad de Shiny
    # Si vos le das un shiny es 1/20 y sino 1/300
    chance = myPokemon.shiny? ? TradeExpert::SHINY_CHANCE_MAX_GIVING_SHINY : TradeExpert::SHINY_CHANCE_MAX
    yourPokemon.make_shiny if rand(chance) == 0

    # sets the Pokemon's mode to be traded
    yourPokemon.obtain_method = 2
    # handles moves
    yourPokemon.reset_moves
    yourPokemon.record_first_moves
    # registers Pokemon in the Pokedex
    $player.pokedex.register(yourPokemon)
    $player.pokedex.set_owned(recv)
    # starts trading sequence
    pbFadeOutInWithMusic(99999){
      evo = PokemonTrade_Scene.new
      evo.pbStartScreen(myPokemon, yourPokemon, $player.name, opponent.name)
      evo.pbTrade
      evo.pbEndScreen
    }
    # sets traded Pokemon
    $player.party[give] = yourPokemon if give.is_a?(Integer)
    $PokemonStorage[give[0], give[1]] = yourPokemon if give.is_a?(Array)
  end
  #-----------------------------------------------------------------------------
  # saves cached trades
  #-----------------------------------------------------------------------------
  def self.saveCache
    File.open(RTP.getSaveFileName("trexpert"),"wb"){|f|
       Marshal.dump($cachedTrade,f)
    }
  end
  #-----------------------------------------------------------------------------
  # display message
  #-----------------------------------------------------------------------------
  def self.displayMsg(msg, *args)
    msg = TradeExpert::TEXT[msg]
    msg = [msg] if !msg.is_a?(Array)
    for m in msg
      pbMessage(_INTL(m, *args)) if m.is_a?(String)
    end
  end
  def self.confirmMsg(msg, *args)
    msg = TradeExpert::TEXT[msg]
    msg = [msg] if !msg.is_a?(Array)
    if msg.length > 1
      for m in msg[0...-1]
        pbMessage(_INTL(m, *args)) if m.is_a?(String)
      end
    end
    return pbConfirmMessage(_INTL(msg[-1], *args))
  end
  #-----------------------------------------------------------------------------
end
#-------------------------------------------------------------------------------
# Method used to call the Trade Expert in event
#-------------------------------------------------------------------------------
def tradeExpert(margin = 0.1, skip_intro = false)
  return TradeExpert.start(margin, skip_intro)
end
#-------------------------------------------------------------------------------
# Used so that the Player can't infinitely reject and get whatever new Pokemon
# before completing an old trade first
#-------------------------------------------------------------------------------
if FileTest.exist?(RTP.getSaveFileName("trexpert"))
  File.open(RTP.getSaveFileName("trexpert")){|f|
    $cachedTrade = Marshal.load(f)
  }
else
  $cachedTrade = {}
end

def pbChooseTradeExpertPokemonPC(ableProc = nil)
  chosen = nil
  pbFadeOutIn {
    scene = PokemonStorageScene.new
    screen = PokemonStorageScreen.new(scene, $PokemonStorage)
    chosen = screen.pbChoosePokemonFromPC(nil, ableProc)
  }
  return nil if chosen.nil?
  return chosen
end