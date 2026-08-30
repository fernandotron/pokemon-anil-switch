#===============================================================================
# Summary scene edits to primarily visuals to match the SV Summary Screen.
#===============================================================================
class MoveSelectionSprite < Sprite 
  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 264
    self.y = 46 + (self.index * 64)
    self.y += 4 if @fifthmove && self.index == Pokemon::MAX_MOVES   # Add a gap
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end
end
#===============================================================================
#
#===============================================================================
class RibbonSelectionSprite < MoveSelectionSprite
  def refresh
    w = @movesel.width
    h = @movesel.height / 2
    self.x = 228 + ((self.index % 4) * 68)
    self.y = 64 + ((self.index / 4).floor * 68)
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0, h, w, h)
    else
      self.src_rect.set(0, 0, w, h)
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSummary_Scene
  PAGE_ICONS_POSITION = [216, 2]
  PAGE_ICONS_ALIGNMENT = :center
  PAGE_ICON_SIZE = [28, 28]

  MARK_WIDTH  = 22
  MARK_HEIGHT = 22
  # Colors used for messages in this scene
  BLUE_TEXT_BASE     = Color.new(108, 168, 216)
  BLUE_TEXT_SHADOW   = Color.new(32, 88, 165)
  WHITE_TEXT_BASE   = Color.new(248, 248, 248)
  WHITE_TEXT_SHADOW = Color.new(74, 112, 175)

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def gray_out_fainted_pokemon
    @sprites["pokeicon"].make_grey_if_fainted = @pokemon.perma_faint
  end

  # FIXED: Modificado para aceptar argumentos variables y mantener compatibilidad
  def pbStartScene(party, partyindex, inbattle = false, page = 1, allow_learn_moves = true)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page = page  # Usar el parámetro page que se pasa
    @allow_learn_moves = allow_learn_moves  # Añadir este parámetro
    @num_icons = party.length() >= 3 ? 2 : party.length - 1
    @typebitmap        = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @typeminibitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types_mini")) # Small Type Icons used in SV
    @markingbitmap     = AnimatedBitmap.new("Graphics/UI/Summary/markings")
    @numbersBitmap = AnimatedBitmap.new("Graphics/UI/Summary/icon_numbers")
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].make_grey_if_fainted = @pokemon&.perma_faint || false
    @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon"].x = 110
    @sprites["pokemon"].y = 166
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].make_grey_if_fainted = @pokemon.perma_faint
    @sprites["pokeicon"].x       = 48
    @sprites["pokeicon"].y       = 86
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"] = ItemIconSprite.new(480, 280, @pokemon.item_id, @viewport)
    @sprites["itemicon"].blankzero = true
    @sprites["itemicon"].visible = false
    # Stat Hexagons
    @sprites["hexagon_stats"] = Sprite.new(@viewport)
    @sprites["hexagon_stats"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["hexagon_stats"].zoom_x = 2
    @sprites["hexagon_stats"].zoom_y = 2
    @sprites["hexagon_base_stats"] = Sprite.new(@viewport)
    @sprites["hexagon_base_stats"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["hexagon_base_stats"].zoom_x = 2
    @sprites["hexagon_base_stats"].zoom_y = 2
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    for i in 0..@num_icons do
      @sprites["pokeicon_#{i}"] = PokemonIconSprite.new(@pokemon, @viewport)
      @sprites["pokeicon_#{i}"].setOffset(PictureOrigin::CENTER)
      @sprites["pokeicon_#{i}"].visible = false
    end
    @party_sprites = true #Party Sprites are defined
    @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonpresel"].visible     = false
    @sprites["ribbonpresel"].preselected = true
    @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonsel"].visible = false
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/UI/up_arrow", 8, 28, 40, 2, @viewport)
    @sprites["uparrow"].x = 350
    @sprites["uparrow"].y = 44
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/UI/down_arrow", 8, 28, 40, 2, @viewport)
    @sprites["downarrow"].x = 350
    @sprites["downarrow"].y = 248
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["markingbg"] = IconSprite.new(260, 88, @viewport)
    @sprites["markingbg"].setBitmap("Graphics/UI/Summary/overlay_marking")
    @sprites["markingbg"].visible = false
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["markingoverlay"].visible = false
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
    @sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
    @sprites["markingsel"].setBitmap("Graphics/UI/Summary/cursor_marking")
    @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height / 2
    @sprites["markingsel"].visible = false
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    # Ability Prompt
    @sprites["abilitybg"] = IconSprite.new(38, 70, @viewport)
    @sprites["abilitybg"].setBitmap("Graphics/UI/Summary/overlay_ability")
    @sprites["abilitybg"].visible = false
    # Item Prompt
    @sprites["itembg"] = IconSprite.new(38, 70, @viewport)
    @sprites["itembg"].setBitmap("Graphics/UI/Summary/overlay_item")
    @sprites["itembg"].visible = false
    @sprites["itemicondesc"] = ItemIconSprite.new(438, 112, @pokemon.item_id, @viewport)
    @sprites["itemicondesc"].blankzero = true
    @sprites["itemicondesc"].visible = false
    # Common for all prompts
    @sprites["promptoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["promptoverlay"].visible = false
    pbSetSystemFont(@sprites["promptoverlay"].bitmap)
    pbBottomLeftLines(@sprites["messagebox"], 2)
    @nationalDexList = [:NONE]
    GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartForgetScene(party, partyindex, move_to_learn)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @page = 4
	  @party_sprites = false #Party Sprites are not defined
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @typeminibitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types_mini"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["pokeicon"].make_grey_if_fainted = @pokemon.perma_faint
    @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokeicon"].x       = 48
    @sprites["pokeicon"].y       = 86
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport, !move_to_learn.nil?)
    @sprites["movesel"].visible = false
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
    drawSelectedMove(new_move, @pokemon.moves[0])
    pbFadeInAndShow(@sprites)
  end

  # Applies a lower bound on each item of the passed array; Used for the stat hexagons
  def applyLowerBound(array, lowerbdd)
    array2 = []
    array.each_with_index do |stat, idx|
      array2[idx] = (stat <= lowerbdd) ? lowerbdd : stat
    end
    return (array2)
  end

  # Draw number icons
  def drawNumber(number, btmp, startX, startY, align = :left)
    # -1 means draw the / character
    n = (number == -1) ? [10] : number.to_i.digits.reverse
    charWidth  = @numbersBitmap.width / 11
    charHeight = @numbersBitmap.height
    startX -= charWidth * n.length if align == :right
    n.each do |i|
      btmp.blt(startX, startY, @numbersBitmap.bitmap, Rect.new(i * charWidth, 0, charWidth, charHeight))
      startX += charWidth
    end
  end
  #===============================================================================
  # Draw button prompts
  # Type: 0 - C (Use)
  # 1 - X (Back)
  # 2 - D (Special)
  #===============================================================================
  def drawButton(overlay, x, y, text, type = 0)
    textpos = [[_INTL("{1}", text), x + 92, y + 4, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)]]
    imagepos = [["Graphics/UI/Summary/button_desc", x, y, 0, type * 28, 154, 28]]
    # Draws the button.
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
  end

  def drawMarkings(bitmap, x, y)
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    markings = @pokemon.markings
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
      markrect.x = i * MARK_WIDTH
      markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
      bitmap.blt(x + (i * (MARK_WIDTH + 4)), y, @markingbitmap.bitmap, markrect)
    end
  end

  #===============================================================================
  # getIndexArray(); getXPos(); drawPartyIcons(); These three functions are 
  # responsible for displaying the Pokémon party icons in Summary.
  #===============================================================================
  def getIndexArray()
    left_array = []
    right_array = []
    idx = 1
    loop do
      right = (@partyindex + idx < @party.length()) && !@party[@partyindex + idx].nil?
      left = (@partyindex - idx >= 0) && !@party[@partyindex - idx].nil?
      if (left && right)
        right_array.push(idx) if right_array.length <= left_array.length
        left_array.unshift(-idx) if right_array.length > left_array.length
      else
        right_array.push(idx) if right
        left_array.unshift(-idx) if left
      end
      idx += 1
      break if (right_array.length() + left_array.length() >= 4) || (!(@partyindex + idx < @party.length()) && !(@partyindex - idx >= 0))
    end
    left_array.push(0)
    array = left_array.concat(right_array)
    return(array)
  end

  def getXPos(array)
    diff = (array.index(0) == 0 || array.index(0) == array.length() - 1) ? 2 : 1
    width = 0
    array.each_with_index do |x, i|
      idx_diff = (array.index(0) - i)
      if (idx_diff.abs > diff)
        width += 20
      else
        if (idx_diff == 0)
          width += 64
        elsif (idx_diff.abs <= diff)
          width += 32
        end
      end
    end
    width += 2 * (array.length() - 1)
    return ((220 - width) / 2)
  end

  def drawPartyIcons(overlay)
    # Creates an arraw to get the relative indexes of the visible pokemon icons
    array = getIndexArray()
    # Draws the icons
    imagepos = []
    xpos = getXPos(array)
    diff = (array.index(0) == 0 || array.index(0) == array.length() - 1) ? 2 : 1
    j = 0
    imagepos.push(["Graphics/UI/Summary/icon_party", xpos - 20, 338, 0, 0, 20, 20])
    array.each_with_index do |x, i|
      idx_diff = (array.index(0) - i)
      if (idx_diff.abs > diff)
        ypos = (x < 0) ? 338 : 354
        imagepos.push(["Graphics/UI/Summary/icon_party", xpos, ypos, 20, 0, 20, 20])
        xpos += 22
      else
        @sprites["pokeicon_#{j}"].visible = true
        @sprites["pokeicon_#{j}"].pokemon = @party[@partyindex + x]
        @sprites["pokeicon_#{j}"].make_grey_if_fainted = @party[@partyindex + x].perma_faint
        if (idx_diff == 0)
          scale = 1
          ypos = 326
          imagepos.push(["Graphics/UI/Summary/party_panel_big", xpos, ypos + 2])
        elsif (idx_diff.abs <= diff)
          scale = 0.5
          ypos = (x < 0) ? 332 : 348
          imagepos.push(["Graphics/UI/Summary/party_panel_small", xpos, ypos])
        end
        @sprites["pokeicon_#{j}"].x = xpos + (scale * 32)
        @sprites["pokeicon_#{j}"].y = ypos + (scale * 38)
        @sprites["pokeicon_#{j}"].zoom_x = scale
        @sprites["pokeicon_#{j}"].zoom_y = scale
        xpos += (scale * 64) + 2
        j += 1
      end
    end  
    imagepos.push(["Graphics/UI/Summary/icon_party", xpos - 2, 354, 40, 0, 20, 20])
    pbDrawImagePositions(overlay, imagepos)
  end

  def drawPage(page)
    setPages # Gets the list of pages and current page ID.
    suffix = UIHandlers.get_info(:summary, @page_id, :suffix)
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_#{suffix}")
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokemon"].make_grey_if_fainted = @pokemon.perma_faint
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].make_grey_if_fainted = @pokemon.perma_faint
    @sprites["itemicon"].visible = @page_id == :page_info
    # Changes visibility of stat hexagons
    @sprites["hexagon_stats"].visible = (@page_id == :page_skills || @page_id == :page_allstats)
    @sprites["hexagon_stats"].bitmap.clear unless !@sprites["hexagon_stats"]
    @sprites["hexagon_base_stats"].visible = (@page_id == :page_skills || @page_id == :page_allstats)
    @sprites["hexagon_base_stats"].bitmap.clear unless !@sprites["hexagon_stats"]

    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(248, 248, 248)
    shadow = Color.new(74, 112, 175)
    drawPageIcons # Draws the page icons.
    drawPartyIcons(overlay)
    imagepos = []
    # Draws general page info.
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 8, 262])
    pagename = UIHandlers.get_info(:summary, @page_id, :name)
    textpos = [
      [pagename, 14, 6, :left, base, shadow],
      [@pokemon.name, 42, 268, :left, base, shadow],
    ]
    # Draws additional info for non-Egg Pokemon.
    if !@pokemon.egg?
      status = -1
      if @pokemon.fainted?
        status = GameData::Status.count - 1
      elsif @pokemon.status != :NONE
        status = GameData::Status.get(@pokemon.status).icon_position
      elsif @pokemon.pokerusStage == 1
        status = GameData::Status.count
      end
      if status >= 0
        imagepos.push(["Graphics/UI/statuses", 10, 44, 0, 16 * status, 44, 16])
      end
      if @pokemon.pokerusStage == 2
        xpos = status >= 0 ? 58 : 10
        imagepos.push(["Graphics/UI/Summary/icon_pokerus", xpos, 42])
      end
      
      if @pokemon.super_shiny?
        imagepos.push(["Graphics/UI/Summary/icon_super_shiny", 182, 40])
      elsif @pokemon.shiny?
        imagepos.push(["Graphics/UI/Summary/icon_shiny", 182, 40])
      end
      # Draws level numbers
      drawNumber(@pokemon.level.to_s, overlay, 36, 306)
      if @pokemon.male?
        imagepos.push(["Graphics/UI/Summary/icon_genders", 188, 266, 0, 0, 22, 22])
      elsif @pokemon.female?
        imagepos.push(["Graphics/UI/Summary/icon_genders", 188, 266, 22, 0, 22, 22])
      end
    end
    # Draws the page.
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
    # Draw Pokémon mini type icon(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(type_number * 24, 0, 24, 24)
      type_x = (@pokemon.types.length == 1) ? 186 : 158 + (28 * i)
      diff = PluginManager.installed?("[DBK] Terastallization") && @pokemon.tera_type ? 36 : 0
      overlay.blt(type_x - diff, 298, @typeminibitmap.bitmap, type_rect)
    end
    evivPage = PluginManager.installed?("[MUI] Enhanced Pokemon UI") && @page_id == :page_skills && @statToggle
    dynamaxMetre = PluginManager.installed?("[DBK] Dynamax") && @page_id == :page_skills && @pokemon.dynamax_able?
    drawMarkings(overlay, 352, 354) if !evivPage && !dynamaxMetre && @page_id != :page_info
    UIHandlers.call(:summary, @page_id, "layout", @pokemon, self)
  end

  def drawPageOne
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(246, 198, 6)
    shadow = Color.new(74, 97, 103)
    @sprites["itemicon"].item = @pokemon.item_id
    imagepos = []
    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heart_gauge.to_f / @pokemon.max_gauge_size
      imagepos.push(["Graphics/UI/Summary/overlay_shadow", 220, 168])
      imagepos.push(["Graphics/UI/Summary/overlay_shadowbar", 240, 236, 0, 0, (shadowfract * 248).floor, -1])
    end
    pbDrawImagePositions(overlay, imagepos)
    # Write various bits of text
    textpos = [
      [_INTL("Especie"), 222, 44, :left, base, shadow],
      [@pokemon.speciesName, 352, 44, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)],
      [_INTL("Tipo"), 222, 76, :left, base, shadow],
      [_INTL("EO"), 222, 108, :left, base, shadow],
      [_INTL("ID No."), 222, 140, :left, base, shadow],
      [_INTL("Objeto Equipado"), 222, 254, :left, base, shadow]
    ]
    # Write Held Item Name
    if @pokemon.hasItem?
      drawButton(overlay, 286, 314, "Detalles", 1) # Show item description button
      textpos.push([@pokemon.item.name, 222, 286, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)])
    else
      textpos.push([_INTL("Ninguno"), 222, 286, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)])
    end
    # Write Original Trainer's name and ID number
    if @pokemon.owner.name.empty?
      textpos.push([_INTL("PRÉSTAMO"), 352, 108, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)])
      textpos.push(["?????", 352, 140, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)])
    else
      ownerbase   = Color.new(248, 248, 248)
      ownershadow = Color.new(74, 112, 175)
      case @pokemon.owner.gender
      when 0
        ownerbase = Color.new(60, 120, 252)
        ownershadow = Color.new(18, 73, 176)
      when 1
        ownerbase = Color.new(228, 66, 66)
        ownershadow = Color.new(68, 57, 121)
      end
      textpos.push([@pokemon.owner.name, 352, 108, :left, ownerbase, ownershadow])
      textpos.push([sprintf("%05d", @pokemon.owner.public_id), 352, 140, :left,
                    Color.new(248, 248, 248), Color.new(74, 112, 175)])
    end
    # Write Exp text OR heart gauge message (if a Shadow Pokémon)
    if @pokemon.shadowPokemon?
      white_text_tag = shadowc3tag(WHITE_TEXT_BASE, WHITE_TEXT_SHADOW)
      heartmessage = [_INTL("¡La puerta de su corazón está abierta! ¡Desbloquea el último cerrojo!"),
                      _INTL("La puerta de su corazón está casi completamente abierta."),
                      _INTL("La puerta de su corazón está casi abierta."),
                      _INTL("La puerta de su corazón se está abriendo más."),
                      _INTL("La puerta de su corazón se está abriendo."),
                      _INTL("La puerta de su corazón está firmemente cerrada.")][@pokemon.heartStage]
      memo = white_text_tag + heartmessage
      drawFormattedTextEx(overlay, 222, 176, 264, memo)
    else
      endexp = @pokemon.growth_rate.minimum_exp_for_level(@pokemon.level + 1)
      remexp = (endexp - @pokemon.exp).to_s_formatted
      textpos.push([_INTL("Puntos Exp."), 222, 172, :left, base, shadow])
      textpos.push([@pokemon.exp.to_s_formatted, 504, 172, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)])
      textpos.push([_INTL("Siguiente Nv.: {1}", remexp), 504, 220, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw Pokémon type(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      type_x = (@pokemon.types.length == 1) ? 352 : 352 + (68 * i)
      overlay.blt(type_x, 74, @typebitmap.bitmap, type_rect)
    end
    # Draw Exp bar
    if @pokemon.level < GameData::GrowthRate.max_level
      w = @pokemon.exp_fraction * 144
      w = ((w / 2).round) * 2
      pbDrawImagePositions(overlay,
                           [["Graphics/UI/Summary/overlay_exp", 356, 206, 0, 0, w, 4]])
    end
  end

  # Displays a prompt to show the Pokémon's held item desription
  def pbItemPrompt
    @sprites["promptoverlay"].bitmap.clear
    @sprites["promptoverlay"].visible = true
    @sprites["itembg"].visible = true
    @sprites["itemicondesc"].item = @pokemon.item_id
    @sprites["itemicondesc"].visible = true
    overlay = @sprites["promptoverlay"].bitmap
    base   = Color.new(246, 198, 6)
    shadow = Color.new(74, 97, 103)
    textpos = [
      [_INTL("Objeto Equipado"), 232, 86, :center, base, shadow],
      [@pokemon.item.name, 232, 118, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)],
    ]
    drawButton(overlay, 180, 276, "Cerrar", 2) # Show close button
    pbDrawTextPositions(overlay, textpos)
    desc = PluginManager.installed?("[DBK] Z-Power") ? GameData::Item.get(@pokemon.item).held_description : GameData::Item.get(@pokemon.item).description
    drawTextEx(overlay, 50, 152, 416, 4, desc, Color.new(248, 248, 248), Color.new(74, 112, 175))
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
    @sprites["itembg"].visible = false
    @sprites["itemicondesc"].visible = false
    @sprites["promptoverlay"].visible = false
  end

  # Gets compressed or smaller format of the passed time
  def pbGetDateDisplay(time = nil)
    time = Time.now if !time
    day = time.day
    month = time.month
    year = time.year
    case System.user_language[3..4]
    # Countries that use the date format Y/M/D.
    when "CN", "JP", "KP", "KR", "MN", "TW", "HU", "LT", "BT", "SE"
      return sprintf("%s/%02d/%02d", year.to_s[2..3], month, day)
    # Countries that use the date format M/D/Y.
    when "US", "AS", "FM", "GU", "MH", "MP", "VI", "UM", "PR", "PH", "TO"
      return sprintf("%02d/%02d/%s", month, day, year.to_s[2..3])
    # Defaults to the date format D/M/Y for all other unlisted countries.
    else
      return sprintf("%02d/%02d/%s", day, month, year.to_s[2..3])
    end
  end

  def drawPageOneEgg
    @sprites["itemicon"].item = @pokemon.item_id
    @sprites["itemicon"].visible = false
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base   = Color.new(246, 198, 6)
    shadow = Color.new(74, 97, 103)
    drawPartyIcons(overlay)
    # Set background image
    @sprites["background"].setBitmap("Graphics/UI/Summary/bg_egg")
    imagepos = []
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
    imagepos.push([ballimage, 8, 262])
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
    # Write various bits of text
    textpos = [
      [_INTL("Notas Entrenador"), 14, 6, :left, base, shadow],
      [@pokemon.name, 42, 268, :left, base, shadow],
    ]
    blue_text_tag = shadowc3tag(BLUE_TEXT_BASE, BLUE_TEXT_SHADOW)
    white_text_tag= shadowc3tag(WHITE_TEXT_BASE, WHITE_TEXT_SHADOW)
    textpos.push([_INTL("Encuentro"), 226, 44, :left, base, shadow])
    encounter_memo = ""
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      encounter_memo += white_text_tag + pbGetDateDisplay(@pokemon.timeReceived) + "\n"
    end
    # Write map name egg was received on
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    if mapname && mapname != ""
      mapname = blue_text_tag + mapname + white_text_tag
      encounter_memo += white_text_tag + _INTL("Un misterioso Huevo Pokémon recibido de {1}.", mapname) + "\n"
    else
      encounter_memo += white_text_tag + _INTL("Un misterioso Huevo Pokémon.") + "\n"
    end
    eggstate_memo = ""
    textpos.push([_INTL("\"El Observador de Huevos\""), 226, 234, :left, base, shadow])
    # Write Egg Watch blurb
    if !MOSTRAR_PASOS_HUEVO
      #memo += black_text_tag + _INTL("\"El huevo eclosionará...\"") + "\n"
      eggstate = _INTL("Parece que va a tardar un buen rato en eclosionar.")
      eggstate = _INTL("¿Qué eclosionará de esto? No parece estar cerca de eclosionar.") if @pokemon.steps_to_hatch < 10_200
      eggstate = _INTL("Parece moverse ocasionalmente. Puede estar cerca de eclosionar.") if @pokemon.steps_to_hatch < 2550
      eggstate = _INTL("¡Se escuchan sonido desde dentro! ¡eclosionará pronto!") if @pokemon.steps_to_hatch < 1275
      eggstate_memo += white_text_tag + eggstate
    else
      eggstate_memo += white_text_tag + _INTL("Faltan {1} pasos para que el huevo eclosione.", @pokemon.steps_to_hatch)
    end
    # eggstate = _INTL("Parece que este Huevo tardará mucho tiempo en eclosionar.")
    # eggstate = _INTL("¿Qué eclosionará de esto? No parece estar cerca de eclosionar.") if @pokemon.steps_to_hatch < 10_200
    # eggstate = _INTL("Parece moverse ocasionalmente. Puede estar cerca de eclosionar.") if @pokemon.steps_to_hatch < 2550
    # eggstate = _INTL("¡Se escuchan sonidos desde dentro! ¡Eclosionará pronto!") if @pokemon.steps_to_hatch < 1275
    # eggstate_memo += white_text_tag + eggstate
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    drawFormattedTextEx(overlay, 232, 80, 268, encounter_memo)
    drawFormattedTextEx(overlay, 232, 270, 268, eggstate_memo)
  end

  def drawPageTwo
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(246, 198, 6)
    shadow = Color.new(74, 97, 103)
    blue_text_tag = shadowc3tag(BLUE_TEXT_BASE, BLUE_TEXT_SHADOW)
    white_text_tag = shadowc3tag(WHITE_TEXT_BASE, WHITE_TEXT_SHADOW)
    textpos = []
    encounter_memo = ""
    # Write characteristic and nature
    textpos.push([_INTL("Características"), 226, 234, :left, base, shadow])
    characteristic_memo = ""
    # Write nature
    showNature = !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
    if showNature
      nature_name = blue_text_tag + @pokemon.nature.name + white_text_tag
      characteristic_memo += white_text_tag + _INTL("Naturaleza {1}.", nature_name) + "\n"
    end
    # Write characteristic
    if showNature
      best_stat = nil
      best_iv = 0
      stats_order = [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE]
      start_point = @pokemon.personalID % stats_order.length   # Tiebreaker
      stats_order.length.times do |i|
        stat = stats_order[(i + start_point) % stats_order.length]
        if !best_stat || @pokemon.iv[stat] > @pokemon.iv[best_stat]
          best_stat = stat
          best_iv = @pokemon.iv[best_stat]
        end
      end
      characteristics = {
        :HP              => [_INTL("Le encanta comer."),
                             _INTL("A menudo se duerme."),
                             _INTL("Suele desordenar cosas."),
                             _INTL("A veces se enfada."),
                             _INTL("Le gusta relajarse.")],
        :ATTACK          => [_INTL("Orgulloso de su fuerza."),
                             _INTL("Le gusta revolverse."),
                             _INTL("Un poco cabezota."),
                             _INTL("Le gusta luchar."),
                             _INTL("Tiene mal genio.")],
        :DEFENSE         => [_INTL("Cuerpo resistente."),
                             _INTL("Es buen fajador."),
                             _INTL("Muy persistente."),
                             _INTL("Muy resistente."),
                             _INTL("Muy perseverante.")],
        :SPECIAL_ATTACK  => [_INTL("Extremadamente curioso."),
                             _INTL("Le gusta hacer travesuras."),
                             _INTL("Muy astuto."),
                             _INTL("A menudo está en Babia."),
                             _INTL("Muy quisquilloso.")],
        :SPECIAL_DEFENSE => [_INTL("Voluntarioso."),
                             _INTL("Es algo orgulloso."),
                             _INTL("Muy insolente."),
                             _INTL("Odia perder."),
                             _INTL("Un poco cabezota.")],
        :SPEED           => [_INTL("Le gusta correr."),
                             _INTL("Siempre con el oído alerta."),
                             _INTL("Impetuoso y bobo."),
                             _INTL("Es un poco payaso."),
                             _INTL("Huye rápido.")]
      }
      characteristic_memo += white_text_tag + characteristics[best_stat][best_iv % 5]
    end
    if !showNature
      characteristic_memo += white_text_tag + _INTL("--")
    end
    # Write encounter
    textpos.push([_INTL("Encuentro"), 226, 44, :left, base, shadow])
    # Write map name Pokémon was received on
    mapname = pbGetMapNameFromId(@pokemon.obtain_map)
    mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
    mapname = _INTL("Lugar lejano") if nil_or_empty?(mapname)
    encounter_memo += blue_text_tag + mapname + "\n"
    # Write how Pokémon was obtained
    mettext = [
      _INTL("Encontrado con Nv. {1}", @pokemon.obtain_level),
      _INTL("Huevo recibido"),
      _INTL("Intercambiado a Nv. {1}", @pokemon.obtain_level),
      "",
      _INTL("Encuentro fatídico a Nv. {1}", @pokemon.obtain_level)
    ][@pokemon.obtain_method]
    encounter_memo += white_text_tag + mettext + (@pokemon.timeReceived ? _INTL(" el ") : _INTL(".")) if mettext && mettext != ""
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      encounter_memo += white_text_tag + pbGetDateDisplay(@pokemon.timeReceived) + _INTL(".") + "\n"
    end
    # If Pokémon was hatched, write when and where it hatched
    if @pokemon.obtain_method == 1
      mapname = pbGetMapNameFromId(@pokemon.hatched_map)
      mapname = _INTL("Lugar lejano") if nil_or_empty?(mapname)
      encounter_memo += blue_text_tag + mapname + "\n"
      encounter_memo += white_text_tag + _INTL("Huevo eclosionado") + (@pokemon.timeEggHatched ? _INTL(" el ") : _INTL("."))
      if @pokemon.timeEggHatched
        date  = @pokemon.timeEggHatched.day
        month = pbGetMonthName(@pokemon.timeEggHatched.mon)
        year  = @pokemon.timeEggHatched.year
        encounter_memo += white_text_tag + pbGetDateDisplay(@pokemon.timeEggHatched) + _INTL(".") + "\n"
      end
    end
    # Write all text
    drawFormattedTextEx(overlay, 226, 80, 274, encounter_memo)
    drawFormattedTextEx(overlay, 226, 270, 274, characteristic_memo)
    pbDrawTextPositions(overlay, textpos)
  end

  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(246, 198, 6)
    shadow = Color.new(74, 97, 103)
    # Draw Stat Hexagons
    stats_list = [
      @pokemon.totalhp, @pokemon.spatk, @pokemon.spdef, @pokemon.speed, @pokemon.defense, @pokemon.attack
    ]
    max_value = stats_list.max
    stats = applyLowerBound(stats_list, 30)
    @sprites["hexagon_stats"].bitmap.clear unless !@sprites["hexagon_stats"]
    @sprites["hexagon_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(72, 204, 240, 191), 300, stats, 12, true, false)
    bst_list = [
      @pokemon.baseStats[:HP], 
      @pokemon.baseStats[:SPECIAL_ATTACK], 
      @pokemon.baseStats[:SPECIAL_DEFENSE], 
      @pokemon.baseStats[:SPEED],
      @pokemon.baseStats[:DEFENSE], 
      @pokemon.baseStats[:ATTACK]]
    bst_max = bst_list.max
    basestats = applyLowerBound(bst_list, 30)
    @sprites["hexagon_base_stats"].bitmap.clear unless !@sprites["hexagon_base_stats"]
    @sprites["hexagon_base_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(210, 255, 168, 191), 300, basestats, 12, true, false)
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statbases = {}
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow; statbases[s.id] = base }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        if change[1] > 0
          statbases[change[0]] = Color.new(228, 66, 66)
          statshadows[change[0]] = Color.new(68, 57, 121)
        elsif change[1] < 0
          statbases[change[0]] = Color.new(102, 178, 255) 
          statshadows[change[0]] = Color.new(18, 73, 176)
        end
      end
    end
    # Write various bits of text
    textpos = [
      [_INTL("PS"), 364, 44, :center, base, shadow],
      [sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp), 364, 70, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)],
      [_INTL("Ataque"), 310, 102, :right, statbases[:ATTACK], statshadows[:ATTACK]], # CAMBIÓ: era 416, :left
      [@pokemon.attack.to_s, 310, 128, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ: era 416, :left
      [_INTL("Defensa"), 310, 162, :right, statbases[:DEFENSE], statshadows[:DEFENSE]], # CAMBIÓ: era 416, :left
      [@pokemon.defense.to_s, 310, 188, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ: era 416, :left
      [_INTL("At. Esp."), 416, 102, :left, statbases[:SPECIAL_ATTACK], statshadows[:SPECIAL_ATTACK]], # CAMBIÓ: era 310, :right
      [@pokemon.spatk.to_s, 416, 128, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ: era 310, :right
      [_INTL("Def. Esp."), 416, 162, :left, statbases[:SPECIAL_DEFENSE], statshadows[:SPECIAL_DEFENSE]], # CAMBIÓ: era 310, :right
      [@pokemon.spdef.to_s, 416, 188, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ: era 310, :right
      # VELOCIDAD (sin cambio)
      [_INTL("Velocidad"), 364, 220, :center, statbases[:SPEED], statshadows[:SPEED]],
      [@pokemon.speed.to_s, 364, 246, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)],
      [_INTL("Habilidad"), 222, 280, :left, base, shadow],
      [_INTL("Estad."), 468, 44, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)],
    ]
    # Draw ability name and description
    imagepos = []
    ability = @pokemon.ability
    if ability
      drawButton(overlay, 286, 308, "Detalles", 1) # Show ability description button
      textpos.push([ability.name, 322, 280, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)])
    end
    # Draw all text
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
  end
  
  # Displays a prompt to show the Pokémon's ability desription
  def pbAbilityPrompt
    @sprites["promptoverlay"].bitmap.clear
    @sprites["promptoverlay"].visible = true
    @sprites["abilitybg"].visible = true
    overlay = @sprites["promptoverlay"].bitmap
    base   = Color.new(246, 198, 6)
    shadow = Color.new(74, 97, 103)
    ability = @pokemon.ability
    textpos = [
      [_INTL("Habilidad"), Graphics.width/2, 86, :center, base, shadow],        # X cambiado de 256 a 232
      [ability.name, Graphics.width/2, 118, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)], # X cambiado de 256 a 232
    ]
    drawButton(overlay, 180, 276, "Cerrar", 2)
    pbDrawTextPositions(overlay, textpos)
    drawTextEx(overlay, 50, 152, 416, 4, ability.description, Color.new(248, 248, 248), Color.new(74, 112, 175))
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
    @sprites["abilitybg"].visible = false
    @sprites["promptoverlay"].visible = false
  end

  def drawPageFour
    overlay = @sprites["overlay"].bitmap
    moveBase   = Color.new(248, 248, 248)
    moveShadow = Color.new(74, 112, 175)
    ppBase   = [moveBase,                  # More than 1/2 of total PP
                Color.new(246, 198, 6),    # 1/2 of total PP or less
                Color.new(246, 136, 32),   # 1/4 of total PP or less
                Color.new(246, 72, 72)]    # Zero PP
    ppShadow = [moveShadow,               # More than 1/2 of total PP
                Color.new(74, 97, 103),   # 1/2 of total PP or less
                Color.new(74, 80, 111),   # 1/4 of total PP or less
                Color.new(74, 60, 123)]   # Zero PP
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    textpos  = []
    imagepos = []
    # Write move names, types and PP amounts for each known move
    #textpos.push([_INTL("Current Moves"), 224, 44, :left, moveBase, moveShadow2])
    yPos = 76
    Pokemon::MAX_MOVES.times do |i|
      move = @pokemon.moves[i]
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types_mini"), 248, yPos - 2, type_number * 24, 0, 24, 24])
        textpos.push([move.name, 276, yPos, :left, moveBase, moveShadow])
        if move.total_pp > 0
          textpos.push([_INTL("PP"), 356, yPos + 32, :left, moveBase, moveShadow])
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 474, yPos + 32, :right, ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", 276, yPos, :left, moveBase, moveShadow])
        textpos.push(["--", 474, yPos, :right, moveBase, moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawImagePositions(overlay, imagepos)
    pbDrawTextPositions(overlay, textpos)
  end

  def drawPageFourSelecting(move_to_learn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    drawPageIcons if !move_to_learn
    base   = Color.new(64, 64, 64)
    shadow = Color.new(162, 162, 162)
    moveBase   = Color.new(248, 248, 248)
    moveShadow = Color.new(74, 112, 175)
    ppBase   = [moveBase,                  # More than 1/2 of total PP
                Color.new(246, 198, 6),    # 1/2 of total PP or less
                Color.new(246, 136, 32),   # 1/4 of total PP or less
                Color.new(246, 72, 72)]    # Zero PP
    ppShadow = [moveShadow,               # More than 1/2 of total PP
                Color.new(74, 97, 103),   # 1/2 of total PP or less
                Color.new(74, 80, 111),   # 1/4 of total PP or less
                Color.new(74, 60, 123)]   # Zero PP
    # Set background image
    if move_to_learn
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_learnmove")
    else
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_movedetail")
    end
    # Write various bits of text
    textpos = [
      [_INTL("Movimientos"), 14, 6, :left, moveBase, moveShadow],
      [@pokemon.name, 84, 54, :left, base, shadow],
      [_INTL("Categoría"), 16, 118, :left, base, shadow],
      [_INTL("Poder"), 16, 150, :left, base, shadow],
      [_INTL("Precisión"), 16, 182, :left, base, shadow]
    ]
    textpos << [_INTL("[Z] Ver Datos"), 150, 6, :left, moveBase, moveShadow] if move_to_learn
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 54
    limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
    limit.times do |i|
      move = @pokemon.moves[i]
      if i == Pokemon::MAX_MOVES
        move = move_to_learn
        yPos += 4
      end
      if move
        type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types_mini"), 266, yPos - 2, type_number * 24, 0, 24, 24])
        textpos.push([move.name, 294, yPos, :left, moveBase, moveShadow])
        if move.total_pp > 0
          textpos.push([_INTL("PP"), 374, yPos + 32, :left, moveBase, moveShadow])
          ppfraction = 0
          if move.pp == 0
            ppfraction = 3
          elsif move.pp * 4 <= move.total_pp
            ppfraction = 2
          elsif move.pp * 2 <= move.total_pp
            ppfraction = 1
          end
          textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 492, yPos + 32, :right,
                        ppBase[ppfraction], ppShadow[ppfraction]])
        end
      else
        textpos.push(["-", 294, yPos, :left, moveBase, moveShadow])
        textpos.push(["--", 492, yPos + 32, :right, moveBase, moveShadow])
      end
      yPos += 64
    end
    # Draw Pokémon's gender icons
    if @pokemon.male?
      imagepos.push(["Graphics/UI/Summary/icon_genders", 84, 84, 0, 0, 22, 22])
    elsif @pokemon.female?
      imagepos.push(["Graphics/UI/Summary/icon_genders", 84, 84, 22, 0, 22, 22])
    end
    # Draw all text and images
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
    # Draw Pokémon's mini-type icon(s)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      type_rect = Rect.new(type_number * 24, 0, 24, 24)
      diff = PluginManager.installed?("[DBK] Terastallization") && @pokemon.tera_type ? 36 : 0
      type_x = (@pokemon.types.length == 1) ? 222 : 194 + (28 * i)
      overlay.blt(type_x - diff, 84, @typeminibitmap.bitmap, type_rect)
    end
  end

  def drawSelectedMove(move_to_learn, selected_move)
    # Draw all of page four, except selected move's details
    drawPageFourSelecting(move_to_learn)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base = Color.new(64, 64, 64)
    shadow = Color.new(162, 162, 162)
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon = @pokemon
    @sprites["pokeicon"].visible = true
    @sprites["itemicon"].visible = false if @sprites["itemicon"]
    if @party_sprites
      for i in 0..@num_icons do
        @sprites["pokeicon_#{i}"].visible = false
      end
    end
    textpos = []
    # Write power and accuracy values for selected move
    move = GameData::Move.get(selected_move.id)
    case move.display_power(@pokemon)
    when 0 then textpos.push(["---", 246, 150, :right, base, shadow])   # Status move
    when 1 then textpos.push(["???", 246, 150, :right, base, shadow])   # Variable power move
    else        textpos.push([move.display_power(@pokemon).to_s, 246, 150, :right, base, shadow])
    end
    if selected_move.display_accuracy(@pokemon) == 0
      textpos.push(["---", 246, 182, :right, base, shadow])
    else
      textpos.push(["#{selected_move.display_accuracy(@pokemon)}%", 234 + overlay.text_size("%").width, 182, :right, base, shadow])
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw selected move's damage category icon
    imagepos = [["Graphics/UI/category", 182, 114, 0, selected_move.display_category(@pokemon) * 28, 64, 28]]
    pbDrawImagePositions(overlay, imagepos)
    # Draw selected move's description
    drawTextEx(overlay, 16, 216, 230, 5, selected_move.description, base, shadow)
  end

  def drawPageFive
    overlay = @sprites["overlay"].bitmap
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
    # Write various bits of text
    textpos = [
      [_INTL("No. de Cintas:"), 222, 282, :left, Color.new(246, 198, 6), Color.new(74, 97, 103)],
      [@pokemon.numRibbons.to_s, 504, 282, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Show all ribbons
    imagepos = []
    coord = 0
    (@ribbonOffset * 4...(@ribbonOffset * 4) + 12).each do |i|
      break if !@pokemon.ribbons[i]
      ribbon_data = GameData::Ribbon.get(@pokemon.ribbons[i])
      ribn = ribbon_data.icon_position
      imagepos.push(["Graphics/UI/Summary/ribbons",
                     230 + (68 * (coord % 4)), 66 + (68 * (coord / 4).floor),
                     64 * (ribn % 8), 64 * (ribn / 8).floor, 64, 64])
      coord += 1
    end
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
  end

  def drawPageAllStats
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(246, 198, 6)
    shadow = Color.new(74, 97, 103)
    
    stats = applyLowerBound([@pokemon.totalhp, @pokemon.spatk, @pokemon.spdef, @pokemon.speed, @pokemon.defense, @pokemon.attack], 30)
    @sprites["hexagon_stats"].bitmap.clear unless !@sprites["hexagon_stats"]
    @sprites["hexagon_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(72, 204, 240, 191), 300, stats, 12, true, false)
    
    basestats = applyLowerBound([
      @pokemon.baseStats[:HP], 
      @pokemon.baseStats[:SPECIAL_ATTACK], 
      @pokemon.baseStats[:SPECIAL_DEFENSE], 
      @pokemon.baseStats[:SPEED],
      @pokemon.baseStats[:DEFENSE], 
      @pokemon.baseStats[:ATTACK]], 26
    )
    @sprites["hexagon_base_stats"].bitmap.clear unless !@sprites["hexagon_base_stats"]
    @sprites["hexagon_base_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(210, 255, 168, 191), 255, basestats, 12, true, false)
    
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statbases = {}
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow; statbases[s.id] = base }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        if change[1] > 0
          statbases[change[0]] = Color.new(228, 66, 66)
          statshadows[change[0]] = Color.new(68, 57, 121)
        elsif change[1] < 0
          statbases[change[0]] = Color.new(102, 178, 255)
          statshadows[change[0]] = Color.new(18, 73, 176)
        end
      end
    end
    
    # Calculate total EVs
    ev_total = 0
    GameData::Stat.each_main { |s| ev_total += @pokemon.ev[s.id] }
    
    # Write various bits of text
    textpos = [
      [_INTL("PS"), 364, 44, :center, base, shadow],
      [sprintf("%d/%d", @pokemon.ev[:HP], @pokemon.iv[:HP]), 364, 70, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)],
      [_INTL("Ataque"), 310, 102, :right, statbases[:ATTACK], statshadows[:ATTACK]], # CAMBIÓ
      [sprintf("%d/%d", @pokemon.ev[:ATTACK], @pokemon.iv[:ATTACK]), 310, 128, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ
      [_INTL("Defensa"), 310, 162, :right, statbases[:DEFENSE], statshadows[:DEFENSE]], # CAMBIÓ
      [sprintf("%d/%d", @pokemon.ev[:DEFENSE], @pokemon.iv[:DEFENSE]), 310, 188, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ
      [_INTL("At. Esp."), 416, 102, :left, statbases[:SPECIAL_ATTACK], statshadows[:SPECIAL_ATTACK]], # CAMBIÓ
      [sprintf("%d/%d", @pokemon.ev[:SPECIAL_ATTACK], @pokemon.iv[:SPECIAL_ATTACK]), 416, 128, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ
      [_INTL("Def. Esp."), 416, 162, :left, statbases[:SPECIAL_DEFENSE], statshadows[:SPECIAL_DEFENSE]], # CAMBIÓ
      [sprintf("%d/%d", @pokemon.ev[:SPECIAL_DEFENSE], @pokemon.iv[:SPECIAL_DEFENSE]), 416, 188, :left, Color.new(248, 248, 248), Color.new(74, 112, 175)], # CAMBIÓ
      [_INTL("Velocidad"), 364, 220, :center, statbases[:SPEED], statshadows[:SPEED]],
      [sprintf("%d/%d", @pokemon.ev[:SPEED], @pokemon.iv[:SPEED]), 364, 246, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)],
      # EVs totales en lugar de habilidad
      [_INTL("EVs totales"), 222, 280, :left, base, shadow],
      [sprintf("%d/510", ev_total), 504, 280, :right, Color.new(248, 248, 248), Color.new(74, 112, 175)],
      # Poder Oculto en lugar del botón de detalles
      [_INTL("Poder Oculto"), 222, 308, :left, base, shadow],
      [_INTL("EV/IV"), 468, 44, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)],
    ]
    
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    
    # Draw Hidden Power type icon
    if defined?(pbHiddenPower)
      hiddenpower = pbHiddenPower(@pokemon)
      type_number = GameData::Type.get(hiddenpower[0]).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      overlay.blt(428, 305, @typebitmap.bitmap, type_rect)
    end
  end

  def drawSelectedRibbon(ribbonid)
    # Draw all of page five
    drawPage(5)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248) 
    shadow = Color.new(74, 112, 175)
    nameBase   = Color.new(246, 198, 6) 
    nameShadow = Color.new(74, 97, 103)
    for i in 0..@num_icons do
      @sprites["pokeicon_#{i}"].visible = false
    end
    # Get data for selected ribbon
    name = ribbonid ? GameData::Ribbon.get(ribbonid).name : ""
    desc = ribbonid ? GameData::Ribbon.get(ribbonid).description : ""
    # Draw the description box
    imagepos = [
      ["Graphics/UI/Summary/overlay_ribbon", 4, 274]
    ]
    pbDrawImagePositions(overlay, imagepos)
    # Draw name of selected ribbon
    textpos = [
      [name, 16, 284, :left, nameBase, nameShadow]
    ]
    pbDrawTextPositions(overlay, textpos)
    # Draw selected ribbon's description
    drawTextEx(overlay, 16, 318, 480, 2, desc, base, shadow)
  end

  def pbMarking(pokemon)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    @sprites["markingsel"].visible     = true
    base   = Color.new(248, 248, 248) 
    shadow = Color.new(74, 112, 175)
    ret = pokemon.markings.clone
    markings = pokemon.markings.clone
    mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
    index = 0
    redraw = true
    markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
          markrect.x = i * MARK_WIDTH
          markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
          @sprites["markingoverlay"].bitmap.blt(296 + (58 * (i % 3)), 156 + (50 * (i / 3)),
                                                @markingbitmap.bitmap, markrect)
        end
        textpos = [
          [_INTL("Marcar a {1}", pokemon.name), 366, 104, :center, Color.new(246, 198, 6), Color.new(74, 97, 103)],
          [_INTL("OK"), 366, 258, :center, base, shadow],
          [_INTL("Cancelar"), 366, 308, :center, base, shadow]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
        redraw = false
      end
      # Reposition the cursor
      @sprites["markingsel"].x = 284 + (58 * (index % 3))
      @sprites["markingsel"].y = 148 + (50 * (index / 3))
      case index
      when 6   # OK
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 248
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      when 7   # Cancel
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 298
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
      else
        @sprites["markingsel"].src_rect.y = 0
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        case index
        when 6   # OK
          ret = markings
          break
        when 7   # Cancel
          break
        else
          markings[index] = ((markings[index] || 0) + 1) % mark_variants
          redraw = true
        end
      elsif Input.trigger?(Input::ACTION)
        if index < 6 && markings[index] > 0
          pbPlayDecisionSE
          markings[index] = 0
          redraw = true
        end
      elsif Input.trigger?(Input::UP)
        if index == 7
          index = 6
        elsif index == 6
          index = 4
        elsif index < 3
          index = 7
        else
          index -= 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        if index == 7
          index = 1
        elsif index == 6
          index = 7
        elsif index >= 3
          index = 6
        else
          index += 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        if index < 6
          index -= 1
          index += 3 if index % 3 == 2
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index < 6
          index += 1
          index -= 3 if index % 3 == 0
          pbPlayCursorSE
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    @sprites["markingsel"].visible     = false
    if pokemon.markings != ret
      pokemon.markings = ret
      return true
    end
    return false
  end

  def pbScene
    @pokemon.play_cry
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::ACTION)
        pbSEStop
        @pokemon.play_cry
        @show_back = !@show_back
        if PluginManager.installed?("[DBK] Animated Pokémon System")
          @sprites["pokemon"].setSummaryBitmap(@pokemon, @show_back)
          @sprites["pokemon"].make_grey_if_fainted = @pokemon.perma_faint
        else
          @sprites["pokemon"].setPokemonBitmap(@pokemon, @show_back)
          @sprites["pokemon"].make_grey_if_fainted = @pokemon.perma_faint
        end
      elsif Input.trigger?(Input::SPECIAL)
        hideAbility = PluginManager.installed?("[MUI] Enhanced Pokemon UI") && @statToggle
        if (@page_id == :page_info) && @pokemon.hasItem?
          pbPlayDecisionSE
          pbItemPrompt
          dorefresh = true
        elsif (@page_id == :page_skills) && @pokemon.ability && !hideAbility
          pbPlayDecisionSE
          pbAbilityPrompt 
          dorefresh = true
        end
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        dorefresh = pbPageCustomUse(@page_id)
        if !dorefresh
          case @page_id
          when :page_moves
            pbPlayDecisionSE
            dorefresh = pbOptions
          when :page_ribbons
            pbPlayDecisionSE
            pbRibbonSelection
            dorefresh = true
          else
            if !@inbattle
              pbPlayDecisionSE
              dorefresh = pbOptions
            end
          end
        end
      elsif Input.repeat?(Input::UP)
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.repeat?(Input::DOWN)
        oldindex = @partyindex
        pbGoToNext
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::JUMPUP) && !@party.is_a?(PokemonBox)
        oldindex = @partyindex
        @partyindex = 0
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::JUMPDOWN) && !@party.is_a?(PokemonBox)
        oldindex = @partyindex
        @partyindex = @party.length - 1
        if @partyindex != oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.repeat?(Input::LEFT)
        oldpage = @page
        numpages = @page_list.length
        @page -= 1
        @page = numpages if @page < 1
        @page = 1 if @page > numpages
        if @page != oldpage
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.repeat?(Input::RIGHT)
        oldpage = @page
        numpages = @page_list.length
        @page += 1
        @page = numpages if @page < 1
        @page = 1 if @page > numpages
        if @page != oldpage
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      end
      @show_back = false if dorefresh
      drawPage(@page) if dorefresh
    end
    return @partyindex
  end

#===============================================================================
# [DBK] Animated Pokemon System Compatibility for [SV] Summary Screen
#===============================================================================
  if PluginManager.installed?("[DBK] Animated Pokémon System")
    def pbFadeInAndShow(sprites, visiblesprites = nil)
      duration = 0.4
      col = Color.new(0, 0, 0, 0)
      if visiblesprites
        visiblesprites.each do |i|
          if i[1] && sprites[i[0]] && !pbDisposed?(sprites[i[0]])
            sprites[i[0]].visible = true
          end
        end
      end
      if @sprites["pokemon"]
        @sprites["pokemon"].display_values = [110, 166, 208, 192]
        @sprites["pokemon"].pbSetDisplay
        @sprites["pokemon"].make_grey_if_fainted = @pokemon.perma_faint
      end
      pbDeactivateWindows(sprites) do
        timer_start = System.uptime
        loop do
          col.alpha = lerp(255, 0, duration, timer_start, System.uptime)
          pbSetSpritesToColor(sprites, col)
          (block_given?) ? yield : pbUpdateSpriteHash(sprites)
          break if col.alpha == 0
        end
      end
    end
  end
end

class PokemonPartyPanel
  STATUS_ICON_HEIGHT = 16
  
  def draw_status
    return if @pokemon.egg? || (@text && @text.length > 0)
    status = -1
    if @pokemon.fainted?
      status = GameData::Status.count - 1
    elsif @pokemon.status != :NONE
      status = GameData::Status.get(@pokemon.status).icon_position
    elsif @pokemon.pokerusStage == 1
      status = GameData::Status.count
    end
    return if status < 0
    statusrect = Rect.new(0, STATUS_ICON_HEIGHT * status, STATUS_ICON_WIDTH, STATUS_ICON_HEIGHT)
    @overlaysprite.bitmap.blt(78, 66, @statuses.bitmap, statusrect)
  end
end


#===============================================================================
# Fix para PokemonSummaryScreen - Compatibilidad de argumentos
#===============================================================================
class PokemonSummaryScreen
  def initialize(scene, inbattle = false, allow_learn_moves = true)
    @scene = scene
    @inbattle = inbattle
    @allow_learn_moves = allow_learn_moves
  end

  # FIXED: Actualizado para pasar correctamente los argumentos a pbStartScene
  def pbStartScreen(party, partyindex, page = 1)
    @scene.pbStartScene(party, partyindex, @inbattle, page, @allow_learn_moves)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party, partyindex, move_to_learn)
    ret = -1
    @scene.pbStartForgetScene(party, partyindex, move_to_learn)
    ret = @scene.pbChooseMoveToForget(move_to_learn)
    @scene.pbEndScene
    return ret
  end

  def pbEndScreen
    @scene.pbEndScene
  end
end


