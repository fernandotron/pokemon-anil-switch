=begin
module GameData
  class Item
    attr_reader :instrument

    SCHEMA["Instrument"] = [:instrument, "v"]

    class << self
      orig_editor_properties = instance_method(:editor_properties)
      define_method(:editor_properties) do
        ret = orig_editor_properties.bind(self).call
        ret.push(["Instrument", PocketProperty, _INTL("The instrument associated with this item.")])
        return ret
      end
    end

    alias aifm_initialize initialize
    def initialize(hash)
      aifm_initialize(hash)
      @instrument = hash[:instrument] || 1
    end

  end
end

class MusicBook
  attr_accessor :last_viewed_instrument
  attr_accessor :last_instrument_selections
  attr_reader   :favorited_items

  def self.instruments
    return [
      GameData::Item.exists?(AIFM_Pocket1[:internal_name]) && AIFM_Pocket1[:item] ? { name: GameData::Item.get(AIFM_Pocket1[:internal_name]).name, item: "#{AIFM_Pocket1[:internal_name]}" } : nil,
      GameData::Item.exists?(AIFM_Pocket2[:internal_name]) && AIFM_Pocket2[:item] ? { name: GameData::Item.get(AIFM_Pocket2[:internal_name]).name, item: "#{AIFM_Pocket2[:internal_name]}" } : nil,
      GameData::Item.exists?(AIFM_Pocket3[:internal_name]) && AIFM_Pocket3[:item] ? { name: GameData::Item.get(AIFM_Pocket3[:internal_name]).name, item: "#{AIFM_Pocket3[:internal_name]}" } : nil,
    ].compact
  end

  def self.instrument_names
    return self.instruments.map { |i| i[:name] }
  end

  def self.instrument_count
    return self.instruments.length
  end

  def initialize
    @instruments = []
    (0...MusicBook.instrument_count + 1).each { |i| @instruments[i] = [] }
    reset_last_selections
    @favorited_items = []
  end

  def reset_last_selections
    @last_viewed_instrument = 1
    @last_instrument_selections ||= []
    (0...MusicBook.instrument_count + 1).each { |i| @last_instrument_selections[i] = 0 }
  end

  def clear
    @instruments.each { |instrument| instrument.clear }
    MusicBook.instrument_count.times { |i| @last_instrument_selections[i] = 0 }
  end

  def instruments
    return @instruments
  end

  def last_viewed_index(instrument)
    return [@last_instrument_selections[instrument], @instruments[instrument].length].min || 0
  end

  def set_last_viewed_index(instrument, value)
    @last_instrument_selections[instrument] = value if value <= @instruments[instrument].length
  end
  #===============================================================================
  def quantity(item)
    item_data = GameData::Item.get(item)
    return 0 if !item_data
    instrument = item_data.instrument
    return MusicBookHelper.quantity(@instruments[instrument], item_data.id)
  end

  def has?(item, qty = 1)
    return @favorited_items.include?(item) if @favorited_items && !@favorited_items.empty?
    return quantity(item) >= qty
  end
  alias can_remove? has?

  def can_add?(item, qty = 1)
    item_data = GameData::Item.get(item)
    instrument = item_data.instrument
    max_size = 999
    return MusicBookHelper.can_add?(@instruments[instrument], max_size, item_data.id, qty)
  end

  def add(item, qty = 1)
    item_data = GameData::Item.get(item)
    instrument = item_data.instrument
    max_size = 999
    return MusicBookHelper.add(@instruments[instrument], max_size, item_data.id, qty)
  end

  def remove(item, qty = 1)
    item_data = GameData::Item.get(item)
    instrument = item_data.instrument
    return MusicBookHelper.remove(@instruments[instrument], item_data.id, qty)
  end
  #===============================================================================
  def favorited?(item)
    item_data = GameData::Item.get(item)
    return false if !item_data
    return @favorited_items.include?(item_data.id)
  end

  def favorite(item)
    item_data = GameData::Item.get(item)
    return if !item_data
    @favorited_items.push(item_data.id) if !@favorited_items.include?(item_data.id)
  end

  def unfavorite(item)
    item_data = GameData::Item.get(item)
    @favorited_items.delete(item_data.id) if item_data
  end
end

class PokemonBag
  attr_accessor :music_book

  alias aifm_initialize initialize
  def initialize
    aifm_initialize
    @music_book = MusicBook.new if !@music_book
  end
end

def pbCanFavoriteItem?(item)
  return !$bag.music_book.favorited?(item) && !ItemHandlers.hasUseInFieldHandler(item)
end

def pbGiveMusicSheet(item)
  $bag.music_book.add(item, 1)
  book = ""
  if !$bag.has?(AIFM_Weather[:sheetsbookitem])
    $bag.add(AIFM_Weather[:sheetsbookitem])
    book = "a Music Sheet Book and "
  end
  item_data = GameData::Item.get(item)
  pbMessage(_INTL("You Received {1}the song {2}!", book , item_data.name))
end

module MusicBookHelper
  def self.quantity(instruments, item)
    ret = 0
    instruments.each { |i| ret += i[1] if i && i[0] == item }
    return ret
  end

  def self.can_add?(instruments, max_size, item, qty)
    raise "Invalid value for qty: #{qty}" if qty < 0
    return true if qty == 0
    max_size.times do |i|
      item_slot = instruments[i]
      if !item_slot
        qty -= [qty, 999].min
        return true if qty == 0
      elsif item_slot[0] == item && item_slot[1] < 999
        new_amt = item_slot[1]
        new_amt = [new_amt + qty, 999].min
        qty -= (new_amt - item_slot[1])
        return true if qty == 0
      end
    end
    return false
  end

  def self.add(instruments, max_size, item, qty)
    raise "Invalid value for qty: #{qty}" if qty < 0
    return true if qty == 0
    max_size.times do |i|
      item_slot = instruments[i]
      if !item_slot
        instruments[i] = [item, [qty, 999].min]
        qty -= instruments[i][1]
        return true if qty == 0
      elsif item_slot[0] == item && item_slot[1] < 999
        new_amt = item_slot[1]
        new_amt = [new_amt + qty, 999].min
        qty -= (new_amt - item_slot[1])
        item_slot[1] = new_amt
        return true if qty == 0
      end
    end
    return false
  end

  def self.remove(instruments, item, qty)
    raise "Invalid value for qty: #{qty}" if qty < 0
    return true if qty == 0
    ret = false
    instruments.each_with_index do |item_slot, i|
      next if !item_slot || item_slot[0] != item
      amount = [qty, item_slot[1]].min
      item_slot[1] -= amount
      qty -= amount
      instruments[i] = nil if item_slot[1] == 0
      next if qty > 0
      ret = true
      break
    end
    instruments.compact!
    return ret
  end
end
#===============================================================================
#
#===============================================================================
class Window_MusicBook < Window_DrawableCommand
  attr_reader :music_book
  attr_reader :instrument
  attr_accessor :sorting

  def initialize(music_book, filterlist, instrument, x, y, width, height)
    @music_book     = music_book
    @filterlist     = filterlist
    @instrument     = instrument
    @sorting        = false
    super(x, y, width, height)
    @selarrow       = AnimatedBitmap.new("Graphics/UI/Bag/cursor")
    @swaparrow      = AnimatedBitmap.new("Graphics/UI/Bag/cursor_swap")
    self.windowskin = nil
  end

  def dispose
    @swaparrow.dispose
    super
  end

  def instrument=(value)
    @instrument = value
    @item_max = (@filterlist) ? @filterlist[@instrument].length + 1 : @music_book.instruments[@instrument].length + 1
    self.index = @music_book.last_viewed_index(@instrument)
  end


  def page_row_max; return MusicBook_Scene::ITEMSVISIBLE; end
  def page_item_max; return MusicBook_Scene::ITEMSVISIBLE; end

  def item
    return nil if @filterlist && !@filterlist[@instrument][self.index]
    thisinstrument = @music_book.instruments[@instrument]
    item = (@filterlist) ? thisinstrument[@filterlist[@instrument][self.index]] : thisinstrument[self.index]
    return (item) ? item[0] : nil
  end

  def itemCount
    return (@filterlist && @filterlist[@instrument]) ? @filterlist[@instrument].length + 1 : @music_book.instruments[@instrument].length + 1
  end

  def itemRect(item)
    if item < 0 || item >= @item_max || item < self.top_item - 1 ||
       item > self.top_item + self.page_item_max
      return Rect.new(0, 0, 0, 0)
    else
      cursor_width = (self.width - self.borderX - ((@column_max - 1) * @column_spacing)) / @column_max
      x = item % @column_max * (cursor_width + @column_spacing)
      y = (item / @column_max * @row_height) - @virtualOy
      return Rect.new(x, y, cursor_width, @row_height)
    end
  end

  def drawCursor(index, rect)
    if self.index == index
      bmp = (@sorting) ? @swaparrow.bitmap : @selarrow.bitmap
      pbCopyBitmap(self.contents, bmp, rect.x, rect.y + 2)
    end
  end

  def drawItem(index, _count, rect)
    textpos = []
    rect = Rect.new(rect.x + 16, rect.y + 16, rect.width - 16, rect.height)
    thisinstrument = @music_book.instruments[@instrument]
    if index == self.itemCount - 1
      textpos.push([_INTL("CLOSE BAG"), rect.x, rect.y + 2, :left, self.baseColor, self.shadowColor])
    else
      item = (@filterlist) ? thisinstrument[@filterlist[@instrument][index]][0] : thisinstrument[index][0]
      baseColor   = self.baseColor
      shadowColor = self.shadowColor
      if @sorting && index == self.index
        baseColor   = Color.new(224, 0, 0)
        shadowColor = Color.new(248, 144, 144)
      end
      textpos.push(
        [GameData::Item.get(item).name, rect.x, rect.y + 2, :left, baseColor, shadowColor]
      )
      item_data = GameData::Item.get(item)
      showing_favorite_icon = false
      if item_data.is_important?
        if @music_book.favorited?(item)
          pbDrawImagePositions(
            self.contents,
            [[_INTL("Graphics/UI/AIFM/icon_favorite"), rect.x + rect.width - 72, rect.y + 8, 0, 0, -1, 24]]
          )
          showing_favorite_icon = true
        elsif pbCanFavoriteItem?(item)
          pbDrawImagePositions(
            self.contents,
            [[_INTL("Graphics/UI/AIFM/icon_favorite"), rect.x + rect.width - 72, rect.y + 8, 0, 24, -1, 24]]
          )
          showing_favorite_icon = true
        end
      end
      if item_data.show_quantity? && !showing_favorite_icon
        qty = (@filterlist) ? thisinstrument[@filterlist[@instrument][index]][1] : thisinstrument[index][1]
        qtytext = _ISPRINTF("x{1: 3d}", qty)
        xQty    = rect.x + rect.width - self.contents.text_size(qtytext).width - 16
        textpos.push([qtytext, xQty, rect.y + 2, :left, baseColor, shadowColor])
      end
    end
    pbDrawTextPositions(self.contents, textpos)
  end

  def refresh
    @item_max = itemCount
    self.update_cursor_rect
    dwidth  = self.width - self.borderX
    dheight = self.height - self.borderY
    self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
    self.contents.clear
    @item_max.times do |i|
      next if i < self.top_item - 1 || i > self.top_item + self.page_item_max
      drawItem(i, @item_max, itemRect(i))
    end
    drawCursor(self.index, itemRect(self.index))
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end

#===============================================================================
# Bag visuals
#===============================================================================
class MusicBook_Scene
  ITEMLISTBASECOLOR     = Color.new(88, 88, 80)
  ITEMLISTSHADOWCOLOR   = Color.new(168, 184, 184)
  ITEMTEXTBASECOLOR     = Color.new(248, 248, 248)
  ITEMTEXTSHADOWCOLOR   = Color.new(0, 0, 0)
  INSTRUMENTNAMEBASECOLOR   = Color.new(88, 88, 80)
  INSTRUMENTNAMESHADOWCOLOR = Color.new(168, 184, 184)
  ITEMSVISIBLE          = 7

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(music_book, choosing = false, filterproc = nil, resetinstrument = true)
    @music_book = music_book
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @choosing   = choosing
    @filterproc = filterproc
    pbRefreshFilter
    lastinstrument = @music_book.last_viewed_instrument
    numfilledinstruments = @music_book.instruments.length - 1
    if @choosing
      numfilledinstruments = 0
      if @filterlist.nil?
        (1...@music_book.instruments.length).each do |i|
          numfilledinstruments += 1 if @music_book.instruments[i].length > 0
        end
      else
        (1...@music_book.instruments.length).each do |i|
          numfilledinstruments += 1 if @filterlist[i].length > 0
        end
      end
      lastinstrument = (resetinstrument) ? 1 : @music_book.last_viewed_instrument
      if (@filterlist && @filterlist[lastinstrument].length == 0) ||
         (!@filterlist && @music_book.instruments[lastinstrument].length == 0)
        (1...@music_book.instruments.length).each do |i|
          if @filterlist && @filterlist[i].length > 0
            lastinstrument = i
            break
          elsif !@filterlist && @music_book.instruments[i].length > 0
            lastinstrument = i
            break
          end
        end
      end
    end
    @music_book.last_viewed_instrument = lastinstrument
    @sliderbitmap = AnimatedBitmap.new("Graphics/UI/Bag/icon_slider")
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["bagsprite"] = IconSprite.new(30, 20, @viewport)

    @sprites["instrumenticon"] = ItemIconSprite.new(94, 95, nil, @viewport)
     if MusicBook.instrument_count > 1
        @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport)
        @sprites["leftarrow"].x       = -4 + 21
        @sprites["leftarrow"].y       = 76
        @sprites["leftarrow"].visible = (!@choosing || numfilledinstruments > 1)
        @sprites["leftarrow"].play
        @sprites["rightarrow"] = AnimatedSprite.new("Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport)
        @sprites["rightarrow"].x       = 150 - 21
        @sprites["rightarrow"].y       = 76
        @sprites["rightarrow"].visible = (!@choosing || numfilledinstruments > 1)
        @sprites["rightarrow"].play
    end
    @sprites["itemlist"] = Window_MusicBook.new(@music_book, @filterlist, lastinstrument, 168, -8, 314, 40 + 32 + (ITEMSVISIBLE * 32))
    @sprites["itemlist"].viewport    = @viewport
    @sprites["itemlist"].instrument      = lastinstrument
    @sprites["itemlist"].index       = @music_book.last_viewed_index(lastinstrument)
    @sprites["itemlist"].baseColor   = ITEMLISTBASECOLOR
    @sprites["itemlist"].shadowColor = ITEMLISTSHADOWCOLOR
    @sprites["itemicon"] = ItemIconSprite.new(48, Graphics.height - 48, nil, @viewport)
    @sprites["itemtext"] = Window_UnformattedTextPokemon.newWithSize(
      "", 72, 272, Graphics.width - 72 - 24, 128, @viewport
    )
    @sprites["itemtext"].baseColor   = ITEMTEXTBASECOLOR
    @sprites["itemtext"].shadowColor = ITEMTEXTSHADOWCOLOR
    @sprites["itemtext"].visible     = true
    @sprites["itemtext"].windowskin  = nil
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
    @sprites["helpwindow"].visible  = false
    @sprites["helpwindow"].viewport = @viewport
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible  = false
    @sprites["msgwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"], 1)
    pbDeactivateWindows(@sprites)
    pbRefresh
    pbFadeInAndShow(@sprites)
  end

  def pbFadeOutScene
    @oldsprites = pbFadeOutAndHide(@sprites)
  end

  def pbFadeInScene
    pbFadeInAndShow(@sprites, @oldsprites)
    @oldsprites = nil
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) if !@oldsprites
    @oldsprites = nil
    dispose
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @sliderbitmap.dispose
    @viewport.dispose
  end

  def pbDisplay(msg, brief = false)
    UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
  end

  def pbConfirm(msg)
    UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
  end

  def pbChooseNumber(helptext, maximum, initnum = 1)
    return UIHelper.pbChooseNumber(@sprites["helpwindow"], helptext, maximum, initnum) { pbUpdate }
  end

  def pbShowCommands(helptext, commands, index = 0)
    return UIHelper.pbShowCommands(@sprites["helpwindow"], helptext, commands, index) { pbUpdate }
  end

  def pbRefresh
    # Set the background image
    @sprites["background"].setBitmap(sprintf("Graphics/UI/AIFM/Book_BG"))
    # Set the bag sprite
    fbagexists = pbResolveBitmap(sprintf("Graphics/UI/Bag/bag_%d_f", @music_book.last_viewed_instrument))
    # Refresh the item window
    @sprites["itemlist"].refresh
    # Refresh more things
    pbRefreshIndexChanged
  end

  def pbRefreshIndexChanged
    itemlist = @sprites["itemlist"]
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Draw the instrument name
    instrument = MusicBook.instruments[@music_book.last_viewed_instrument - 1]
    instrument_item = GameData::Item.get(instrument[:item])
    instrument_name = $bag.has?(instrument_item.id) ? instrument[:name] : "???"
    pbDrawTextPositions(
      overlay,
      [[instrument_name, 94, 186 - 156 - 4, :center, INSTRUMENTNAMEBASECOLOR, INSTRUMENTNAMESHADOWCOLOR]]
    )
    item = AIFM_Weather[:sheetsbookitem]
    pbDrawTextPositions(
      overlay,
      [[GameData::Item.get(item).name, 94, 234, :center, INSTRUMENTNAMEBASECOLOR, INSTRUMENTNAMESHADOWCOLOR]]
    )
    # Draw slider arrows
    showslider = false
    if itemlist.top_row > 0
      overlay.blt(470, 16, @sliderbitmap.bitmap, Rect.new(0, 0, 36, 38))
      showslider = true
    end
    if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
      overlay.blt(470, 228, @sliderbitmap.bitmap, Rect.new(0, 38, 36, 38))
      showslider = true
    end
    # Draw slider box
    if showslider
      sliderheight = 174
      boxheight = (sliderheight * itemlist.page_row_max / itemlist.row_max).floor
      boxheight += [(sliderheight - boxheight) / 2, sliderheight / 6].min
      boxheight = [boxheight.floor, 38].max
      y = 54
      y += ((sliderheight - boxheight) * itemlist.top_row / (itemlist.row_max - itemlist.page_row_max)).floor
      overlay.blt(470, y, @sliderbitmap.bitmap, Rect.new(36, 0, 36, 4))
      i = 0
      while i * 16 < boxheight - 4 - 18
        height = [boxheight - 4 - 18 - (i * 16), 16].min
        overlay.blt(470, y + 4 + (i * 16), @sliderbitmap.bitmap, Rect.new(36, 4, 36, height))
        i += 1
      end
      overlay.blt(470, y + boxheight - 18, @sliderbitmap.bitmap, Rect.new(36, 20, 36, 18))
    end

    instrument = MusicBook.instruments[@music_book.last_viewed_instrument - 1]
    instrument_item = GameData::Item.get(instrument[:item])
    if instrument_item && $bag.has?(instrument_item.id)
      @sprites["instrumenticon"].item = instrument_item.id
      @sprites["instrumenticon"].tone = Tone.new(0, 0, 0)
      @sprites["instrumenticon"].opacity = 255
    else
      @sprites["instrumenticon"].item = instrument_item.id
      @sprites["instrumenticon"].tone = Tone.new(-255, -255, -255)
      @sprites["instrumenticon"].opacity = 128
    end

    # Set the selected item's icon
    @sprites["itemicon"].item = itemlist.item
    # Set the selected item's description
    @sprites["itemtext"].text =
      (itemlist.item) ? GameData::Item.get(itemlist.item).description : _INTL("Close Book.")
  end

  def pbRefreshFilter
    @filterlist = nil
    return if !@choosing
    return if @filterproc.nil?
    @filterlist = []
    (1...@music_book.instruments.length).each do |i|
      @filterlist[i] = []
      @music_book.instruments[i].length.times do |j|
        @filterlist[i].push(j) if @filterproc.call(@music_book.instruments[i][j][0])
      end
    end
  end

  # Called when the item screen wants an item to be chosen from the screen
  def pbChooseItem
    @sprites["helpwindow"].visible = false
    itemwindow = @sprites["itemlist"]
    thisinstrument = @music_book.instruments[itemwindow.instrument]
    swapinitialpos = -1
    pbActivateWindow(@sprites, "itemlist") do
      loop do
        oldindex = itemwindow.index
        Graphics.update
        Input.update
        pbUpdate
        if itemwindow.sorting && itemwindow.index >= thisinstrument.length
          itemwindow.index = (oldindex == thisinstrument.length - 1) ? 0 : thisinstrument.length - 1
        end
        if itemwindow.index != oldindex
          # Move the item being switched
          if itemwindow.sorting
            thisinstrument.insert(itemwindow.index, thisinstrument.delete_at(oldindex))
          end
          # Update selected item for current instrument
          @music_book.set_last_viewed_index(itemwindow.instrument, itemwindow.index)
          pbRefresh
        end
        if itemwindow.sorting
          if Input.trigger?(Input::ACTION) ||
             Input.trigger?(Input::USE)
            itemwindow.sorting = false
            pbPlayDecisionSE
            pbRefresh
          elsif Input.trigger?(Input::BACK)
            thisinstrument.insert(swapinitialpos, thisinstrument.delete_at(itemwindow.index))
            itemwindow.index = swapinitialpos
            itemwindow.sorting = false
            pbPlayCancelSE
            pbRefresh
          end
        else   # Change instruments
          if Input.trigger?(Input::LEFT)
            newinstrument = itemwindow.instrument
            loop do
              newinstrument = (newinstrument == 1) ? MusicBook.instrument_count : newinstrument - 1
              break if !@choosing || newinstrument == itemwindow.instrument
              if @filterlist
                break if @filterlist[newinstrument].length > 0
              elsif @music_book.instruments[newinstrument].length > 0
                break
              end
            end
            if itemwindow.instrument != newinstrument
              itemwindow.instrument = newinstrument
              @music_book.last_viewed_instrument = itemwindow.instrument
              thisinstrument = @music_book.instruments[itemwindow.instrument]
              pbPlayCursorSE
              pbRefresh
            end
          elsif Input.trigger?(Input::RIGHT)
            newinstrument = itemwindow.instrument
            loop do
              newinstrument = (newinstrument == MusicBook.instrument_count) ? 1 : newinstrument + 1
              break if !@choosing || newinstrument == itemwindow.instrument
              if @filterlist
                break if @filterlist[newinstrument].length > 0
              elsif @music_book.instruments[newinstrument].length > 0
                break
              end
            end
            if itemwindow.instrument != newinstrument
              itemwindow.instrument = newinstrument
              @music_book.last_viewed_instrument = itemwindow.instrument
              thisinstrument = @music_book.instruments[itemwindow.instrument]
              pbPlayCursorSE
              pbRefresh
            end
#          elsif Input.trigger?(Input::SPECIAL)   # Register/unregister selected item
#            if !@choosing && itemwindow.index<thisinstrument.length
#              if @bag.registered?(itemwindow.item)
#                @bag.unregister(itemwindow.item)
#              elsif pbCanRegisterItem?(itemwindow.item)
#                @bag.register(itemwindow.item)
#              end
#              pbPlayDecisionSE
#              pbRefresh
#            end
          elsif Input.trigger?(Input::ACTION)   # Start switching the selected item
            if !@choosing && thisinstrument.length > 1 && itemwindow.index < thisinstrument.length
              itemwindow.sorting = true
              swapinitialpos = itemwindow.index
              pbPlayDecisionSE
              pbRefresh
            end
          elsif Input.trigger?(Input::BACK)   # Cancel the item screen
            pbPlayCloseMenuSE
            return nil
          elsif Input.trigger?(Input::USE)   # Choose selected item
            (itemwindow.item) ? pbPlayDecisionSE : pbPlayCloseMenuSE
            return itemwindow.item
          end
        end
      end
    end
  end
end

#===============================================================================
# Bag mechanics
#===============================================================================
class MusicBookScreen
  def initialize(scene, music_book)
    @music_book = music_book
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene(@music_book)
    item = nil
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
#      cmdRead     = -1
#      cmdUse      = -1
      cmdFavorite = -1
#      cmdGive     = -1
      cmdToss     = -1
      cmdDebug    = -1
      commands = []
      # Generate command list
#      commands[cmdRead = commands.length] = _INTL("Read") if itm.is_mail?
#      if ItemHandlers.hasOutHandler(item) || (itm.is_machine? && $player.party.length > 0)
#        if ItemHandlers.hasUseText(item)
#          commands[cmdUse = commands.length]    = ItemHandlers.getUseText(item)
#        else
#          commands[cmdUse = commands.length]    = _INTL("Use")
#        end
#      end
#      commands[cmdGive = commands.length]       = _INTL("Give") if $player.pokemon_party.length > 0 && itm.can_hold?
      commands[cmdToss = commands.length]       = _INTL("Toss") if !itm.is_important? || $DEBUG
      if @music_book.favorited?(item)
        commands[cmdFavorite = commands.length] = _INTL("Unfavorite")
      elsif pbCanFavoriteItem?(item)
        commands[cmdFavorite = commands.length] = _INTL("Favorite")
      end
      commands[cmdDebug = commands.length]      = _INTL("Debug") if $DEBUG
      commands[commands.length]                 = _INTL("Cancel")
      # Show commands generated above
      itemname = itm.name
      command = @scene.pbShowCommands(_INTL("{1} is selected.", itemname), commands)
#      if cmdRead >= 0 && command == cmdRead   # Read mail
#        pbFadeOutIn do
#          pbDisplayMail(Mail.new(item, "", ""))
#        end
#      elsif cmdUse >= 0 && command == cmdUse   # Use item
#        ret = pbUseItem(@music_book, item, @scene)
        # ret: 0=Item wasn't used; 1=Item used; 2=Close Bag to use in field
#        break if ret == 2   # End screen
#        @scene.pbRefresh
#        next
#      elsif cmdGive >= 0 && command == cmdGive   # Give item to Pokémon
#        if $player.pokemon_count == 0
#          @scene.pbDisplay(_INTL("There is no Pokémon."))
#        elsif itm.is_important?
#          @scene.pbDisplay(_INTL("The {1} can't be held.", itm.portion_name))
#        else
#          pbFadeOutIn do
#            sscene = PokemonParty_Scene.new
#            sscreen = PokemonPartyScreen.new(sscene, $player.party)
#            sscreen.pbPokemonGiveScreen(item)
#            @scene.pbRefresh
#          end
#        end
      if cmdToss >= 0 && command == cmdToss   # Toss item
        qty = @music_book.quantity(item)
        if qty > 1
          helptext = _INTL("Toss out how many {1}?", itm.portion_name_plural)
          qty = @scene.pbChooseNumber(helptext, qty)
        end
        if qty > 0
          itemname = (qty > 1) ? itm.portion_name_plural : itm.portion_name
          if pbConfirm(_INTL("Is it OK to throw away {1} {2}?", qty, itemname))
            pbDisplay(_INTL("Threw away {1} {2}.", qty, itemname))
            qty.times { @music_book.remove(item) }
            @scene.pbRefresh
          end
        end
      elsif cmdFavorite >= 0 && command == cmdFavorite   # Favorite item
        if @music_book.favorited?(item)
          @music_book.unfavorite(item)
        else
          @music_book.favorite(item)
        end
        @scene.pbRefresh
      elsif cmdDebug >= 0 && command == cmdDebug   # Debug
        command = 0
        loop do
          command = @scene.pbShowCommands(_INTL("Do what with {1}?", itemname),
                                          [_INTL("Change quantity"),
                                           _INTL("Make Mystery Gift"),
                                           _INTL("Cancel")], command)
          case command
          ### Cancel ###
          when -1, 2
            break
          ### Change quantity ###
          when 0
            qty = @music_book.quantity(item)
            itemplural = itm.name_plural
            params = ChooseNumberParams.new
            params.setRange(0, 999)
            params.setDefaultValue(qty)
            newqty = pbMessageChooseNumber(
              _INTL("Choose new quantity of {1} (max. {2}).", itemplural, 999), params
            ) { @scene.pbUpdate }
            if newqty > qty
              @music_book.add(item, newqty - qty)
            elsif newqty < qty
              @music_book.remove(item, qty - newqty)
            end
            @scene.pbRefresh
            break if newqty == 0
          ### Make Mystery Gift ###
          when 1
            pbCreateMysteryGift(1, item)
          end
        end
      end
    end
    ($game_temp.fly_destination) ? @scene.dispose : @scene.pbEndScene
    return item
  end

  def pbDisplay(text)
    @scene.pbDisplay(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  # UI logic for the item screen for choosing an item.
  def pbChooseItemScreen(proc = nil)
    oldlastinstrument = @music_book.last_viewed_instrument
    oldchoices = @music_book.last_instrument_selections.clone
    @music_book.reset_last_selections if proc
    @scene.pbStartScene(@music_book, true, proc)
    item = @scene.pbChooseItem
    @scene.pbEndScene
    @music_book.last_viewed_instrument = oldlastinstrument
    @music_book.last_instrument_selections = oldchoices
    return item
  end

  # UI logic for withdrawing an item in the item storage screen.
  def pbWithdrawItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage)
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      qty = storage.quantity(item)
      if qty > 1 && !itm.is_important?
        qty = @scene.pbChooseNumber(_INTL("How many do you want to withdraw?"), qty)
      end
      next if qty <= 0
      if @music_book.can_add?(item, qty)
        if !storage.remove(item, qty)
          raise "Can't delete items from storage"
        end
        if !@music_book.add(item, qty)
          raise "Can't withdraw items from storage"
        end
        @scene.pbRefresh
        dispqty = (itm.is_important?) ? 1 : qty
        itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
        pbDisplay(_INTL("Withdrew {1} {2}.", dispqty, itemname))
      else
        pbDisplay(_INTL("There's no more room in the Bag."))
      end
    end
    @scene.pbEndScene
  end

  # UI logic for depositing an item in the item storage screen.
  def pbDepositItemScreen
    @scene.pbStartScene(@music_book)
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      qty = @music_book.quantity(item)
      if qty > 1 && !itm.is_important?
        qty = @scene.pbChooseNumber(_INTL("How many do you want to deposit?"), qty)
      end
      if qty > 0
        if storage.can_add?(item, qty)
          if !@music_book.remove(item, qty)
            raise "Can't delete items from Bag"
          end
          if !storage.add(item, qty)
            raise "Can't deposit items to storage"
          end
          @scene.pbRefresh
          dispqty  = (itm.is_important?) ? 1 : qty
          itemname = (dispqty > 1) ? itm.portion_name_plural : itm.portion_name
          pbDisplay(_INTL("Deposited {1} {2}.", dispqty, itemname))
        else
          pbDisplay(_INTL("There's no room to store items."))
        end
      end
    end
    @scene.pbEndScene
  end

  # UI logic for tossing an item in the item storage screen.
  def pbTossItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage)
    loop do
      item = @scene.pbChooseItem
      break if !item
      itm = GameData::Item.get(item)
      if itm.is_important?
        @scene.pbDisplay(_INTL("That's too important to toss out!"))
        next
      end
      qty = storage.quantity(item)
      itemname       = itm.portion_name
      itemnameplural = itm.portion_name_plural
      if qty > 1
        qty = @scene.pbChooseNumber(_INTL("Toss out how many {1}?", itemnameplural), qty)
      end
      next if qty <= 0
      itemname = itemnameplural if qty > 1
      next if !pbConfirm(_INTL("Is it OK to throw away {1} {2}?", qty, itemname))
      if !storage.remove(item, qty)
        raise "Can't delete items from storage"
      end
      @scene.pbRefresh
      pbDisplay(_INTL("Threw away {1} {2}.", qty, itemname))
    end
    @scene.pbEndScene
  end
end

def pbMusicBook
  $bag = PokemonBag.new if !$bag
  pbFadeOutIn do
    scene = MusicBook_Scene.new
    screen = MusicBookScreen.new(scene, $bag.music_book)
    screen.pbStartScreen
  end
end
=end