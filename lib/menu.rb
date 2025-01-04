module Input
  class Menu
    include Util
    include Keyboard

    attr_sprite
    attr_reader :selected_index, :content_w, :content_h, :scroll_w, :scroll_h, :items
    attr_accessor :readonly, :scroll_x, :scroll_y

    @@id = 0

    def initialize(**params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      @x = params[:x] || 0
      @y = params[:y] || 0

      @font_style = FontStyle.from(word_chars: ['W'], **params.slice(:font, :size_enum, :size_px))
      @font_height = @font_style.font_height

      @padding = params[:padding] || 2

      self.items = params[:items] # self.items so that items= is called

      @w = params[:w] || size_width_to_fit
      @h = params[:h] || size_height_to_fit

      @text_color = parse_color(params, :text).merge(vertical_alignment_enum: 0)
      @background_color = parse_color_nilable(params, :background)
      @blurred_background_color = parse_color_nilable(params, :blurred) || @background_color

      @selected_index = params[:selected_index] || 0

      @selection_color = parse_color(params, :selection, dr: 102, dg: 178, db: 255, da: 128)
      @blurred_selection_color = parse_color(params, :blurred_selection, dr: 112, dg: 128, db: 144, da: 128)

      # Mouse focus for selection
      @mouse_down = false
      @mouse_wheel_speed = params[:mouse_wheel_speed] || @font_height

      # Render target for text scrolling
      @path = "__input_m_#{@@id += 1}"

      @scroll_x = 0
      @scroll_y = 0
      @content_w = @w
      @content_h = @h

      @scroll_x = 0
      @scroll_y = 0
      @scroll_w = @w
      @scroll_h = @h

      @focussed = params[:focussed] || false
      @will_focus = false # Get the focus at the end of the tick

      @on_selected = params[:on_selected] || NOOP
      @on_unhandled_key = params[:on_unhandled_key] || NOOP

      initialize_keyboard(params)
    end

    def draw_override(ffi)
      return if @items.length == 0

      # The argument order for ffi_draw.draw_sprite_3 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h
      ffi.draw_sprite_3(
        @x, @y, @content_w, @content_h,
        @path,
        0, 255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        0, 0, @content_w, @content_h
      )

      return unless @will_focus

      @will_focus = false
      @focussed = true
    end

    def tick
      if @focussed
        prepare_special_keys
        handle_keyboard
      end
      handle_mouse
      prepare_render_target
    end

    def handle_keyboard
      # TODO: home, pgup, end, pgdn
      # TODO: optional find by text
      if @down_keys.include?(:up) || @down_keys.include?(:up_arrow)
        @selected_index = (@selected_index - 1).clamp_wrap(0, @items.length - 1)
      elsif @down_keys.include?(:down) || @down_keys.include?(:down_arrow)
        @selected_index = (@selected_index + 1).clamp_wrap(0, @items.length - 1)
      else
        @on_unhandled_key.call(@down_keys.first, self)
      end
    end

    def handle_mouse # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      return

      # mouse = $args.inputs.mouse
      # inside = mouse.inside_rect?(self)

      # @scroll_y += mouse.wheel.y * @mouse_wheel_speed if mouse.wheel && inside

      # return unless @mouse_down || (mouse.down && inside)

      # if @fill_from_bottom
      #   relative_y = @content_h < @h ? @y - mouse.y + @content_h : @scroll_h - (mouse.y - @y + @scroll_y)
      # else
      #   relative_y = @scroll_h - (mouse.y - @y + @scroll_y)
      #   relative_y += @h - @content_h if @content_h < @h
      # end
      # line = @value.lines[relative_y.idiv(@font_height).cap_min_max(0, @value.lines.length - 1)]
      # index = line.index_at(mouse.x - @x + @scroll_x)

      # if @mouse_down # dragging
      #   @selection_end = index
      #   @mouse_down = false if mouse.up
      # else # clicking
      #   @on_clicked.call(mouse, self)
      #   return unless (@focussed || @will_focus) && mouse.button_left

      #   if @shift
      #     @selection_end = index
      #   else
      #     @selection_start = @selection_end = index
      #   end
      #   @mouse_down = true
      # end

      # @ensure_cursor_visible = true
    end

    def focussed?
      @focussed
    end
    alias focused? focussed?

    def focus
      @will_focus = true
    end

    def blur
      @focussed = false
    end

    def items=(items)
      @items = case items
               when nil
                 []
               when Hash
                 items.map { |text, val| { text: item, value: item } }
               when Array
                 if items[0].is_a?(Hash)
                   items
                 else
                   items.map { |item| { text: item.to_s, value: item } }
                 end
               else
                 puts "Items should be an array of Strings or a Hash with text and value keys"
                 []
               end
      size_to_fit
      @selected_index = 0
    end

    def size_to_fit
      size_width_to_fit
      size_height_to_fit
    end

    def size_width_to_fit
      @w = @items.reduce(0) do |max, item|
        iw = @font_style.string_width(item.text) + @padding * 2
        iw > max ? iw : max
      end
    end

    def size_height_to_fit
      @h = @font_height * @items.length + @padding * 2
    end

    def value
      @items[@selected_index].value
    end

    # TODO: Fix menu value=
    def value=(text)
      # text = text[0, @max_length] if @max_length
      # @value.replace(text)
      # @selection_start = @selection_start.lesser(text.length)
      # @selection_end = @selection_end.lesser(text.length)
    end

    def selected_index=(index)
      @selected_index = index.clamp_wrap(0, @items.length - 1)
    end

    # @scroll_w - The `scroll_w` read-only property is a measurement of the width of an element's content,
    #             including content not visible on the screen due to overflow. For this control `scroll_w == w`
    # @content_w - The `content_w` read-only property is the inner width of the content in pixels.
    #              It includes padding. For this control `content_w == w`
    # @scroll_h - The `scroll_h` read-only property is a measurement of the height of an element's content,
    #             including content not visible on the screen due to overflow.
    #             http://developer.mozilla.org/en-US/docs/Web/API/Element/scrollHeight
    # @content_h - The `content_h` read-only property is the inner height of the content in pixels.
    #              It includes padding. It is the lesser of `h` and `scroll_h`
    # @cursor_line - The Line (Object) the cursor is on
    # @cursor_index - The index of the string on the @cursor_line that the cursor is found
    # @cursor_y - The y location of the cursor in relative to the scroll_h (all content)
    def prepare_render_target # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      l = @items.length
      return if l == 0

      if @focussed || @will_focus
        bg = @background_color
        sc = @selection_color
      else
        bg = @blurred_background_color
        sc = @blurred_selection_color
      end

      # TODO: Attach menu to another widget so we space above of below
      # TODO: A bounding box? Assuming grid for now
      grid = $args.grid
      avail_h = if @y - @h > 0 || @y + @h < grid.h # can we render fully below or above?
        @h
      else # ok, we gotta scroll
        @y.greater(grid.h - @y)
      end
      first_item, num_items = items_to_show(avail_h)
      @content_h = num_items * @font_height
      @content_w = @w

      rt = $args.outputs[@path]
      rt.w = @content_w
      rt.h = @content_h
      rt.background_color = bg
      rt.transient!

      # TODO: implement mouse scrolling
      @scroll_w = @content_w
      @scroll_h = @items.length * @font_height + 2 * @padding
      @scroll_x = 0
      @scroll_y = first_item * @font_height
      i = -1
      while (i += 1) < num_items
        y = (num_items - i - 1) * @font_height
        rt.primitives << { x: 0, y: y, w: @content_w, h: @font_height }.solid!(sc) if @selected_index == first_item + i
        rt.primitives << @font_style.label(x: @padding, y: y, text: @items[first_item + i].text, **@text_color)
      end

      position
    end

    def items_to_show(avail_h)
      # TODO: line spacing in menu
      num_items = (avail_h / @font_height).floor.lesser(@items.length) - 1
      half_num_items = num_items.idiv(2)
      if half_num_items > @selected_index
        [0, num_items + 1]
      elsif half_num_items > @items.length - @selected_index - (num_items.even? ? 1 : 2)
        [@items.length - num_items - 1, num_items + 1]
      else
        [@selected_index - half_num_items, num_items + 1]
      end
    end

    # TODO: implement positioning
    def position
      if @y + @content_h > $args.grid.h # over the top?
        if @y - @content_h < 0 # also down under?
          @y = $args.grid.h - @content_h # move down so we fit
        else
          @y -= @content_h # render down
        end
      end

      if @x + @content_w > $args.grid.w # too far?
        if @x - @content_w < 0 # also too left?
          @x = $args.grid.w - @content_w # move left so we fit
        else
          @x -= @content_w # render left
        end
      end
    end

    # TODO: update @w and @h with @content_*
    def rect
      { x: @x, y: @y, w: @content_w, h: @content_h }
    end

    def content_rect
      { x: @scroll_x, y: @scroll_y, w: @content_w, h: @content_h }
    end

    def scroll_rect
      { x: @scroll_x, y: @scroll_y, w: @scroll_w, h: @scroll_h }
    end
  end
end
