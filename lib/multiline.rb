module Input
  class Multiline < Base
    def initialize(**params)
      value = params[:value] || ''

      super

      @word_wrap_chars = @word_chars.merge(@punctuation_chars)
      @value = MultilineValue.new(value, @word_wrap_chars, @crlf_chars, @w, font_style: @font_style)
      @fill_from_bottom = params[:fill_from_bottom] || false
    end

    def lines
      @value.lines
    end

    def w=(val)
      return if @w == val

      @w = val
      @reflow_required = true
    end

    def size_enum=(val)
      return if @font_style.size_enum == val

      @font_style = FontStyle.from(word_chars: @word_chars.keys, font: @font_style.font, size_enum: val)
      @reflow_required = true
    end

    def size_px=(val)
      return if @font_style.size_px == val

      @font_style = FontStyle.from(word_chars: @word_chars.keys, font: @font_style.font, size_px: val)
      @reflow_required = true
    end

    def reflow!
      @ensure_line_visible = @value.lines.length - ((@scroll_y + @h) / @font_height).floor
      @font_height = @font_style.font_height
      @value.reflow(@w, @font_style)
      @reflow_required = false
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
          @readonly ? copy : cut
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:v)
          paste unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:g)
          @shift ? find_prev : find_next
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:left) || @down_keys.include?(:left_arrow)
          @shift ? select_to_line_start : move_to_line_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:right) || @down_keys.include?(:right_arrow)
          @shift ? select_to_line_end : move_to_line_end
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:up) || @down_keys.include?(:up_arrow)
          @shift ? select_to_start : move_to_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:down) || @down_keys.include?(:down_arrow)
          @shift ? select_to_end : move_to_end
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif @text_keys.empty?
        if @down_keys.include?(:delete)
          delete_forward unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:backspace)
          delete_back unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:left) || @down_keys.include?(:left_arrow)
          if @shift
            @alt ? select_word_left : select_char_left
            @ensure_cursor_visible = true
          else
            @alt ? move_word_left : move_char_left
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:right) || @down_keys.include?(:right_arrow)
          if @shift
            @alt ? select_word_right : select_char_right
            @ensure_cursor_visible = true
          else
            @alt ? move_word_right : move_char_right
            @ensure_cursor_visible = true
          end
        # TODO: Retain a original_cursor_x when moving up/down to try stay generally in the same x range
        elsif @down_keys.include?(:up) || @down_keys.include?(:up_arrow)
          if @shift
            select_line_up
            @ensure_cursor_visible = true
          else
            # TODO: beginning of previous paragraph with alt
            move_line_up
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:down) || @down_keys.include?(:down_arrow)
          if @shift
            select_line_down
            @ensure_cursor_visible = true
          else
            # TODO: end of next paragraph with alt
            move_line_down
            @ensure_cursor_visible = true
          end
        elsif @down_keys.include?(:enter)
          insert("\n") unless @readonly
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:pageup)
          @shift ? select_page_up : move_page_up
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:pagedown)
          @shift ? select_page_down : move_page_down
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:home)
          @shift ? select_to_start : move_to_start
          @ensure_cursor_visible = true
        elsif @down_keys.include?(:end)
          @shift ? select_to_end : move_to_end
          @ensure_cursor_visible = true
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      else
        insert(@text_keys.join('')) unless @readonly
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
        @value.lines[line.number - 1].index_at(@cursor_x + @scroll_x)
      end
    end

    def selection_end_down_index
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
        @value.lines[line.number + 1].index_at(@cursor_x + @scroll_x)
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
        @scroll_y += mouse.wheel.y * @mouse_wheel_speed
        @ensure_cursor_visible = false
      end

      return unless @mouse_down || (mouse.down && inside)

      if @fill_from_bottom
        relative_y = @content_h < @h ? @y - mouse.y + @content_h : @scroll_h - (mouse.y - @y + @scroll_y)
      else
        relative_y = @scroll_h - (mouse.y - @y + @scroll_y)
        relative_y += @h - @content_h if @content_h < @h
      end
      line = @value.lines[relative_y.idiv(@font_height).cap_min_max(0, @value.lines.length - 1)]
      index = line.index_at(mouse.x - @x + @scroll_x)

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
      reflow! if @reflow_required

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
        @scroll_x = 0
        if @fill_from_bottom
          @cursor_y = -@padding
          rt.primitives << @font_style.label(x: 0, y: 0, text: @prompt, **@prompt_color)
        else
          @cursor_y = @h - @font_height - @padding
          rt.primitives << @font_style.label(x: 0, y: @h - @font_height, text: @prompt, **@prompt_color)
        end
      else
        # CURSOR AND SCROLL LOCATION
        @cursor_line = lines.line_at(@selection_end)
        @cursor_index = @selection_end - @cursor_line.start
        # Move the cursor to the beginning of the next line if the line is wrapped and we're at the end of the line
        if @cursor_index == @cursor_line.length && @cursor_line.wrapped? && lines.length > @cursor_line.number
          @cursor_line = lines[@cursor_line.number + 1]
          @cursor_index = 0
        end

        @cursor_y = @scroll_h - (@cursor_line.number + 1) * @font_height - @padding
        @cursor_y += @fill_from_bottom ? @content_h : @h - @content_h if @content_h < @h
        if @scroll_h <= @h # total height is less than height of the control
          @scroll_y = @fill_from_bottom ? @scroll_h : 0
        elsif @ensure_line_visible
          # TODO: Line visibility
          @scroll_y = (@value.lines.length - @ensure_line_visible) * @font_height - @h + @padding
          @ensure_line_visible = nil
        elsif @ensure_cursor_visible
          if @cursor_y + @font_height > @scroll_y + @content_h
            @scroll_y = @cursor_y + @font_height - @content_h
          elsif @cursor_y < @scroll_y
            @scroll_y = @cursor_y
          end
        else
          @scroll_y = @scroll_y.cap_min_max(0, @scroll_h - @h)
        end
        @cursor_x = @cursor_line.measure_to(@cursor_index).lesser(@w)
        @ensure_cursor_visible = false

        selection_start = @selection_start.lesser(@selection_end)
        selection_end = @selection_start.greater(@selection_end)
        selection_visible = selection_start != selection_end

        content_bottom = @scroll_y - @font_height # internal use only, includes font_height, used for draw
        content_top = @scroll_y + @content_h # internal use only, used for draw
        selection_h = @font_height

        b = @scroll_h - @padding - @scroll_y
        if @content_h < @h
          i = -1
          l = lines.length
          b += @fill_from_bottom ? @content_h : @h - @content_h
        else
          i = (@scroll_h - content_top).idiv(@font_height).greater(0) - 1
          l = (@scroll_h - content_bottom).idiv(@font_height).lesser(lines.length)
        end
        while (i += 1) < l
          line = lines[i]
          y = b - (i + 1) * @font_height

          # SELECTION
          if selection_visible && selection_start <= line.end && selection_end >= line.start
            left = line.measure_to((selection_start - line.start).greater(0))
            right = line.measure_to((selection_end - line.start).lesser(line.length))
            rt.primitives << { x: left, y: y, w: right - left, h: selection_h }.solid!(sc)
          end

          # TEXT FOR LINE
          rt.primitives << @font_style.label(x: 0, y: y, text: line.clean_text, **@text_color)
        end
      end

      draw_cursor(rt)
    end
  end
end
