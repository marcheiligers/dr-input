class Sizer
  attr_sprite

  def initialize(multiline)
    @multiline = multiline
    @mouse_down = false
    @x = @multiline.x
    @y = @multiline.y
    @w = @multiline.w
    @h = @multiline.h
  end

  def tick
    handle_mouse
  end

  def handle_mouse
    mouse = $args.inputs.mouse
    th = thumb_rect
    @mouse_over = mouse.inside_rect?(th)

    if !@mouse_down && mouse.down && @mouse_over
      @mouse_offset_x = @w + @x - mouse.x
      @mouse_offset_y = @y - mouse.y
      @mouse_down = true
    elsif @mouse_down
      @w = mouse.x + @mouse_offset_x - @x
      @y = mouse.y - @mouse_offset_y - 10
      @h = @multiline.h + @multiline.y - @y
      if mouse.up
        @mouse_down = false
        @multiline.w = @w
        @multiline.y = @y
        @multiline.h = @h
      end
    end

    mouse.clear if @mouse_over
  end

  def thumb_rect
    { x: @x + @w - 10, y: @y, w: 10, h: 10 }
  end

  def draw_override(ffi)
    color = @mouse_down || @mouse_over ? [172, 172, 212, 255] : [192, 192, 192, 255]
    ffi.draw_solid(*thumb_rect.values, *color)
    ffi.draw_border_3(@x, @y, @w, @h, *color, 1, 0, 0)
  end
end
