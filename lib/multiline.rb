module Input
  class Multiline < Base
    attr_reader :lines

    def initialize(**params)
      value = params[:value]

      super

      word_wrap_chars = @word_chars.merge(@punctuation_chars)
      @value = MultilineValue.new(value, word_wrap_chars, @crlf_chars, @font, @size_enum, @w)
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
        @path, 0,
        255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        0, 0, @w, @h
      )
      super # handles focus
    end

    def handle_keyboard
      text_keys = $args.inputs.text
      # On a Mac:
      # Home is Cmd + ↑ / Fn + ←
      # End is Cmd + ↓ / Fn + →
      # PageUp is Fn + ↑
      # PageDown is Fn + ↓
      if @meta || @ctrl
        # TODO: undo/redo
        if @down_keys.include?(:a)
          select_all
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:c)
          copy
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:x)
          cut
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:v)
          paste
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:g)
          @shift ? find_prev : find_next
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:left)
          @shift ? select_to_line_start : move_to_line_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:right)
          @shift ? select_to_line_end : move_to_line_end
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif text_keys.empty?
        if (@down_keys & DEL_KEYS).any?
          delete_back
          @ensure_cursor_visible = true
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
        # TODO: Retain a original_cursor_x when moving up/down to try stay generally in the same x range
        elsif @down_keys.include?(:up)
          if @shift
            select_line_up
            @ensure_cursor_visible = true
          else
            # TODO: beginning of previous paragraph with alt
            move_line_up
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:down)
          if @shift
            select_line_down
            @ensure_cursor_visible = true
          else
            # TODO: end of next paragraph with alt
            move_line_down
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:enter)
          insert("\n")
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:pageup)
          @shift ? select_page_up : move_page_up
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:pagedown)
          @shift ? select_page_down : move_page_down
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      else
        insert(text_keys.join(''))
        @ensure_cursor_visible = true
      end
    end

    def select_to_line_start
      line = @value.lines.line_at(@selection_end)
      index = line.new_line? ? line.start + 1 : line.start
      @selection_end = index
    end

    def move_to_line_start
      line = @value.lines.line_at(@selection_end)
      index = line.new_line? ? line.start + 1 : line.start
      @selection_start = @selection_end = index
    end

    def find_line_end
      line = @value.lines.line_at(@selection_end)
      if line.wrapped?
        if @selection_end == line.end
          if @value.lines.length > line.number
            line = @value.lines[line.number + 1]
            line.wrapped? ? line.end - 1 : line.end
          else
            line.end
          end
        else
          line.end - 1
        end
      else
        line.end
      end
    end

    def select_to_line_end
      @selection_end = find_line_end
    end

    def move_to_line_end
      @selection_start = @selection_end = find_line_end
    end

    def select_line_up
      @selection_end = selection_end_up_index
    end

    def move_line_up
      @selection_end = @selection_start = selection_end_up_index
    end

    def select_line_down
      @selection_end = selection_end_down_index
    end

    def move_line_down
      @selection_end = @selection_start = selection_end_down_index
    end

    def selection_end_up_index
      return 0 if selection_end == 0

      line = @value.lines.line_at(@selection_end)
      if line.wrapped? && line.end == @selection_end
        line.new_line? ? line.start + 1 : line.start
      elsif line.number == 0
        @selection_end
      elsif line.new_line? && @selection_end == line.start + 1
        line = @value.lines[line.number - 1]
        line.new_line? ? line.start + 1 : line.start
      elsif @selection_end == line.start
        @value.lines[line.number - 1].start
      else
        @value.lines[line.number - 1].index_at(@cursor_x + @content_x)
      end
    end

    def selection_end_down_index
      # BUG: If the first line has only one char, down moves right from the first column
      line = @value.lines.line_at(@selection_end)
      if line.number == @value.lines.length - 1
        @selection_end
      elsif line.new_line? && @selection_end == line.start + 1
        line = @value.lines[line.number + 1]
        line.new_line? ? line.start + 1 : line.start
      elsif @selection_end == line.start
        @value.lines[line.number + 1].start
      elsif line.wrapped? && line.end == @selection_end && line.number < @value.lines.length - 2
        line = @value.lines[line.number + 2]
        line.new_line? ? line.start + 1 : line.start
      else
        @value.lines[line.number + 1].index_at(@cursor_x + @content_x)
      end
    end

    def move_page_up
      (@h / @font_height).floor.times { @selection_start = @selection_end = selection_end_up_index }
    end

    def move_page_down
      (@h / @font_height).floor.times { @selection_start = @selection_end = selection_end_down_index }
    end

    def select_page_up
      (@h / @font_height).floor.times { @selection_end = selection_end_up_index }
    end

    def select_page_down
      (@h / @font_height).floor.times { @selection_end = selection_end_down_index }
    end

    def current_line
      @value.lines&.line_at(@selection_end)
    end

    # TODO: Word selection (double click), All selection (triple click)
    def handle_mouse # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      mouse = $args.inputs.mouse
      inside = mouse.inside_rect?(self)

      if mouse.wheel && inside
        @content_y += mouse.wheel.y * @mouse_wheel_speed
        @ensure_cursor_visible = false
      end

      return unless @mouse_down || (mouse.down && inside)

      relative_y = @scroll_h - (mouse.y - @y + @content_y)
      line = @value.lines[relative_y.idiv(@font_height).cap_min_max(0, @value.lines.length - 1)]
      index = line.index_at(mouse.x - @x + @content_x)

      if @mouse_down # dragging
        @selection_end = index
        @mouse_down = false if mouse.up
      else # clicking
        @on_clicked.call(mouse, self)
        return unless (@focussed || @will_focus) && mouse.button_left

        if @shift
          @selection_end = index
        else
          @selection_start = @selection_end = index
        end
        @mouse_down = true
      end

      @ensure_cursor_visible = true
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
      if @focussed || @will_focus
        bg = @background_color
        sc = @selection_color
      else
        bg = @blurred_background_color
        sc = @blurred_selection_color
      end

      # TODO: Implement line spacing
      lines = @value.lines
      @scroll_w = @content_w = @w
      @scroll_h = lines.length * @font_height + 2 * @padding
      @content_h = @h.lesser(@scroll_h)

      rt = $args.outputs[@path]
      rt.w = @w
      rt.h = @h
      rt.background_color = bg
      # TODO: implement sprite background
      rt.transient!

      if @value.empty?
        @cursor_line = 0
        @cursor_x = 0
        @cursor_y = @h - @font_height
        @content_x = 0
        rt.primitives << { x: 0, y: @h - @font_height, text: @prompt, size_enum: @size_enum, font: @font }.label!(@prompt_color)
      else
        # CURSOR AND SCROLL LOCATION
        @cursor_line = lines.line_at(@selection_end)
        @cursor_index = @selection_end - @cursor_line.start
        # Move the cursor to the beginning of the next line if the line is wrapped and we're at the end of the line
        if @cursor_index == @cursor_line.length && @cursor_line.wrapped? && lines.length > @cursor_line.number
          @cursor_line = lines[@cursor_line.number + 1]
          @cursor_index = 0
        end

        @cursor_y = @scroll_h - (@cursor_line.number + 1) * @font_height
        @cursor_y += @h - @content_h if @content_h < @h
        if @scroll_h <= @h # total height is less than height of the control
          @content_y = 0
        elsif @ensure_cursor_visible
          if @cursor_y + @font_height > @content_y + @content_h
            @content_y = @cursor_y + @font_height - @content_h
          elsif @cursor_y < @content_y
            @content_y = @cursor_y
          end
        else
          @content_y = @content_y.cap_min_max(0, @scroll_h - @h)
        end
        # TODO: Ensure cursor_x doesn't go past the line width
        @cursor_x = @cursor_line.measure_to(@cursor_index).lesser(@w)

        selection_start = @selection_start.lesser(@selection_end)
        selection_end = @selection_start.greater(@selection_end)
        selection_visible = selection_start != selection_end

        content_bottom = @content_y - @font_height # internal use only, includes font_height, used for draw
        content_top = @content_y + @content_h # internal use only, used for draw
        selection_h = @font_height + @padding * 2

        i = (@scroll_h - content_top).idiv(@font_height).greater(0) - 1
        l = (@scroll_h - content_bottom).idiv(@font_height).lesser(lines.length)
        b = @scroll_h - @padding - @content_y
        b += @h - @content_h if @content_h < @h
        while (i += 1) < l
          line = lines[i]
          y = b - (i + 1) * @font_height

          # SELECTION
          if selection_visible && selection_start <= line.end && selection_end >= line.start
            left = line.measure_to((selection_start - line.start).greater(0))
            right = line.measure_to((selection_end - line.start).lesser(line.length))
            rt.primitives << { x: left, y: y + @padding, w: right - left, h: selection_h }.solid!(sc)
          end

          # TEXT FOR LINE
          rt.primitives << { x: 0, y: y, text: line.clean_text, size_enum: @size_enum, font: @font }.label!(@text_color)
        end
      end

      draw_cursor(rt)
    end
  end
end
