module Input
  class Text < Base
    def initialize(**params)
      @value = TextValue.new(params[:value] || '')
      super
    end

    def draw_override(ffi)
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
        @x, @y, @w, @h,
        @path,
        0, 255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        0, 0, @w, @h
      )
      super # handles focus
    end

    def handle_keyboard
      text_keys = $args.inputs.text

      if @meta || @ctrl
        # TODO: undo/redo
        if @down_keys.include?(:a)
          select_all
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:c)
          copy
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:x)
          @readonly ? copy : cut
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:v)
          paste unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:left)
          @shift ? select_to_start : move_to_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:right)
          @shift ? select_to_end : move_to_end
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:g)
          @shift ? find_prev : find_next
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif text_keys.empty?
        if (@down_keys & DEL_KEYS).any?
          # TODO: Treat delete and backspace differently
          delete_back unless @readonly
        elsif @down_keys.include?(:left)
          if @shift
            @alt ? select_word_left : select_char_left
            @ensure_cursor_visible = true
          else
            @alt ? move_word_left : move_char_left
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:right)
          if @shift
            @alt ? select_word_right : select_char_right
            @ensure_cursor_visible = true
          else
            @alt ? move_word_right : move_char_right
            @ensure_cursor_visible = true
          end
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      else
        insert(text_keys.join('')) unless @readonly
        @ensure_cursor_visible = true
      end
    end

    # TODO: Word selection (double click), All selection (triple click)
    def handle_mouse # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      mouse = $args.inputs.mouse

      if mouse.wheel && mouse.inside_rect?(self)
        d = mouse.wheel.x == 0 ? mouse.wheel.y : mouse.wheel.x
        @content_x += d * @mouse_wheel_speed
        @ensure_cursor_visible = false
      end

      return unless @mouse_down || (mouse.down && mouse.inside_rect?(self))

      if @mouse_down # dragging
        index = find_index_at_x(mouse.x - @x + @content_x)
        @selection_end = index
        @mouse_down = false if mouse.up
      else
        @on_clicked.call(mouse, self)
        return unless @focussed || @will_focus

        @mouse_down = true

        index = find_index_at_x(mouse.x - @x + @content_x)
        if @shift
          @selection_end = index
        else
          @selection_start = @selection_end = index
        end
      end

      @ensure_cursor_visible = true
    end

    def find_index_at_x(x, str = @value) # rubocop:disable Metrics/MethodLength
      return 0 if x < @padding

      l = 0
      r = @value.length - 1
      loop do
        return l if l > r

        m = ((l + r) / 2).floor
        px = $gtk.calcstringbox(str[0, m].to_s, @size_enum, @font)[0]
        if px == x
          return m
        elsif px < x
          l = m + 1
        else
          r = m - 1
        end
      end
    end

    def prepare_render_target
      # TODO: handle padding correctly
      if @focussed || @will_focus
        bg = @background_color
        sc = @selection_color
      else
        bg = @blurred_background_color
        sc = @blurred_selection_color
      end

      @scroll_w = $gtk.calcstringbox(@value.to_s, @size_enum, @font)[0].ceil
      @content_w = @w.lesser(@scroll_w)
      @scroll_h = @content_h = @h

      rt = $args.outputs[@path]
      rt.w = @w
      rt.h = @h
      rt.background_color = bg
      # TODO: implement sprite background
      rt.transient!

      if @value.empty?
        @cursor_x = 0
        @cursor_y = 0
        @content_x = 0
        rt.primitives << { x: 0, y: @padding, text: @prompt, size_enum: @size_enum, font: @font }.label!(@prompt_color)
      else
        # CURSOR AND SCROLL LOCATION
        @cursor_x = $gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font)[0]
        @cursor_y = 0

        if @content_w < @w
          @content_x = 0
        elsif @ensure_cursor_visible
          if @cursor_x > @content_x + @content_w
            @content_x = @cursor_x - @content_w
          elsif @cursor_x < @content_x
            @content_x = @cursor_x
          end
        else
          @content_x = @content_x.cap_min_max(0, @scroll_w - @w)
        end

        # SELECTION
        if @selection_start != @selection_end
          if @selection_start < @selection_end
            left = ($gtk.calcstringbox(@value[0, @selection_start].to_s, @size_enum, @font)[0] - @content_x).cap_min_max(0, @w)
            right = ($gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font)[0] - @content_x).cap_min_max(0, @w)
          elsif @selection_start > @selection_end
            left = ($gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font)[0] - @content_x).cap_min_max(0, @w)
            right = ($gtk.calcstringbox(@value[0, @selection_start].to_s, @size_enum, @font)[0] - @content_x).cap_min_max(0, @w)
          end

          rt.primitives << { x: left, y: @padding, w: right - left, h: @font_height + @padding * 2 }.solid!(sc)
        end

        # TEXT
        f = find_index_at_x(@content_x)
        l = find_index_at_x(@content_x + @content_w) + 2
        rt.primitives << { x: 0, y: @padding, text: @value[f, l - f], size_enum: @size_enum, font: @font }.label!(@text_color)
      end

      draw_cursor(rt)
    end
  end
end
