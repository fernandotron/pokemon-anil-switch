class PokemonSummary_Scene
  #-----------------------------------------------------------------------------
  # Used to draw the relevant page icons in the heading of each page
  # (Changed from Modular UI Scenes to match SV layout).
  #-----------------------------------------------------------------------------
    def drawPageIcons
    setPages if !@page_list || @page_list.empty?
    iconPos    = 0
    imagepos   = [] 
    xpos, ypos = PAGE_ICONS_POSITION
    w, h       = PAGE_ICON_SIZE
    spacing    = 4
    size       = MAX_PAGE_ICONS - 1
    range      = [@page_list.length, MAX_PAGE_ICONS]
    page       = @page_list.find_index(@page_id)
    startPage  = (page > size) ? page - size : 0
    endPage    = [startPage + size, @page_list.length - 1].min
    case PAGE_ICONS_ALIGNMENT
    when :left   then offset = 0
    when :right  then offset = (Graphics.width - xpos + 4) - ((w + spacing) * range.min)
    when :center then offset = (Graphics.width - xpos + 4) / 2 - (range.min * ((w + spacing) / 2))
    end
    for i in startPage..endPage
      suffix = UIHandlers.get_info(:summary, @page_list[i], :suffix)
      path = "Graphics/UI/Summary/page_#{suffix}"
      iconRectX = (page == i) ? w : 0
      imagepos.push([path, xpos + offset + (iconPos * (w + spacing)), ypos, iconRectX, 0, w, h])
      iconPos += 1
    end
    if PAGE_ICONS_SHOW_ARROWS
      path = "Graphics/UI/Summary/page_arrows"
      if page > size
        imagepos.push([path, xpos + offset - 24, ypos + 4, 0, 0, 20, 20])
      end
      if endPage < @page_list.length - 1
        imagepos.push([path, xpos + offset + (iconPos * (w + spacing)), ypos + 4, 20, 0, 20, 20])
      end
    end
    pbDrawImagePositions(@sprites["overlay"].bitmap, imagepos)
  end
end