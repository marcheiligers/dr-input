class Scroller
  attr_sprite

  def initialize(multiline)
    @multiline = multiline
    @mouse_down = false
    @x = @multiline.x + @multiline.w + 20
    @y = @multiline.y
    @w = 20
    @h = @multiline.h
  end

  def tick
    handle_mouse
  end

  def handle_mouse
    return if @multiline.content_h < @multiline.h

    mouse = $args.inputs.mouse
    th = thumb_rect

    if !@mouse_down && mouse.down && mouse.inside_rect?(self)
      @mouse_down = true
      @mouse_y = mouse.y
      if mouse.inside_rect?(th)
        # do nothing, we'll drag the rect
      else
        # jump the thumb to where we clicked
      end
    elsif @mouse_down
      @mouse_down = false if mouse.up
      # scroll inut
    end
  end

  def thumb_rect
    if @multiline.content_h < @h
      { x: @x, y: @y, w: @w, h: @h }
    else
      { x: @x, y: (@multiline.content_y / @multiline.scroll_h) * @h + @y, w: @w, h: (@h / @multiline.scroll_h) * @h }
    end
  end

  def draw_override(ffi)
    ffi.draw_solid(@x, @y, @w, @h, 220, 220, 220, 255)
    ffi.draw_solid(*thumb_rect.values, 192, 192, 192, 255)
  end
end
