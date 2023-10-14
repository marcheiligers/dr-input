module Input
  class Multiline < Base
    attr_reader :lines

    def initialize(**params)
      super

      word_wrap_chars = @word_chars.merge(@punctuation_chars)
      @line_parser = LineParser.new(word_wrap_chars, @crlf_chars, @font, @size_enum)
      @lines = @line_parser.perform_word_wrap(@value, @w)
      @ensure_cursor_visible = true
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
        @x, @y + @h - @content_h, @content_w, @content_h,
        @path, 0,
        255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        0, 0, @content_w, @content_h
      )
      super # handles focus and draws the cursor
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
      line = @lines.line_at(@selection_end)
      index = line.new_line? ? line.start + 1 : line.start
      @selection_end = index
    end

    def move_to_line_start
      line = @lines.line_at(@selection_end)
      index = line.new_line? ? line.start + 1 : line.start
      @selection_start = @selection_end = index
    end

    def find_line_end
      line = @lines.line_at(@selection_end)
      if line.wrapped?
        if @selection_end == line.end
          if @lines.length > line.number
            line = @lines[line.number + 1]
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

      line = @lines.line_at(@selection_end)
      if line.wrapped? && line.end == @selection_end
        line.new_line? ? line.start + 1 : line.start
      elsif line.number == 0
        @selection_end
      elsif line.new_line? && @selection_end == line.start + 1
        line = @lines[line.number - 1]
        line.new_line? ? line.start + 1 : line.start
      elsif @selection_end == line.start
        @lines[line.number - 1].start
      else
        @lines[line.number - 1].index_at(@cursor_x + @content_x)
      end
    end

    def selection_end_down_index
      # BUG: If the first line has only one char, down moves right from the first column
      line = @lines.line_at(@selection_end)
      if line.number == @lines.length - 1
        @selection_end
      elsif line.new_line? && @selection_end == line.start + 1
        line = @lines[line.number + 1]
        line.new_line? ? line.start + 1 : line.start
      elsif @selection_end == line.start
        @lines[line.number + 1].start
      elsif line.wrapped? && line.end == @selection_end && line.number < @lines.length - 2
        line = @lines[line.number + 2]
        line.new_line? ? line.start + 1 : line.start
      else
        @lines[line.number + 1].index_at(@cursor_x + @content_x)
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
      @lines&.line_at(@selection_end)
    end

    # TODO: Word selection (double click), All selection (triple click)
    def handle_mouse
      mouse = $args.inputs.mouse
      return unless @mouse_down || (mouse.down && mouse.inside_rect?(self))

      relative_y = @scroll_h - (mouse.y - @y + @content_y)
      line = @lines[relative_y.idiv(@font_height).cap_min_max(0, @lines.length - 1)]
      index = line.index_at(mouse.x - @x + @content_x)

      if @mouse_down # dragging
        @selection_end = index
        @mouse_down = false if mouse.up
      else # clicking
        @on_clicked.call(mouse, self)
        return unless @focussed || @will_focus

        if @shift
          @selection_end = index
        else
          @selection_start = @selection_end = index
        end
        @mouse_down = true
      end

      @ensure_cursor_visible = true
    end

    def value=(text)
      @value = text
      @selection_start = @selection_start.lesser(@value.length)
      @selection_end = @selection_end.lesser(@value.length)
      @lines = @line_parser.perform_word_wrap(@value, @w)
      @value_changed = false
    end

    def insert(str)
      @selection_end, @selection_start = @selection_start, @selection_end if @selection_start > @selection_end
      @value = @value[0, @selection_start].to_s + str + @value[@selection_start, @value.length].to_s # TODO: remove @value

      modified_lines = @lines.modified(@selection_start, @selection_end)
      original_value = modified_lines.text
      first_modified_line = modified_lines.first
      original_index = first_modified_line.start
      modified_value = original_value[0, @selection_start - original_index].to_s + str + original_value[@selection_end - original_index, original_value.length].to_s
      new_lines = @line_parser.perform_word_wrap(modified_value, @w, first_modified_line.number, original_index)

      @lines.replace(modified_lines, new_lines)

      @selection_start += str.length
      @selection_end = @selection_start
    end
    alias replace insert

    def cut
      copy
      @selection_end, @selection_start = @selection_start, @selection_end if @selection_start > @selection_end

      @value = @value[0, @selection_start] + @value[@selection_end, @value.length] # TODO: remove @value

      delete_selection
    end

    def delete_selection
      modified_lines = @lines.modified(@selection_start, @selection_end)
      original_value = modified_lines.text
      first_modified_line = modified_lines.first
      original_index = first_modified_line.start
      modified_value = original_value[0, @selection_start - original_index].to_s + original_value[@selection_end - original_index, original_value.length].to_s
      new_lines = @line_parser.perform_word_wrap(modified_value, @w, first_modified_line.number, original_index)

      @lines.replace(modified_lines, new_lines)

      @selection_end = @selection_start
    end

    def delete_back
      @selection_end, @selection_start = @selection_start, @selection_end if @selection_start > @selection_end
      @selection_start -= 1 if @selection_start == @selection_end

      @value = @value[0, @selection_start] + @value[@selection_end, @value.length] # TODO: remove @value

      delete_selection
      @selection_end = @selection_start
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
      @scroll_w = @content_w = @w
      @scroll_h = @lines.length * @font_height + 2 * @padding
      @content_h = @h.lesser(@scroll_h)
      rt = $args.outputs[@path]
      rt.w = @content_w
      rt.h = @content_h
      rt.background_color = bg
      # TODO: implement sprite background
      rt.transient!

      # CURSOR AND SCROLL LOCATION
      @cursor_line = @lines.line_at(@selection_end)
      @cursor_index = @selection_end - @cursor_line.start
      # Move the cursor to the beginning of the next line if the line is wrapped and we're at the end of the line
      if @cursor_index == @cursor_line.length && @cursor_line.wrapped? && @lines.length > @cursor_line.number
        @cursor_line = @lines[@cursor_line.number + 1]
        @cursor_index = 0
      end

      @cursor_y = @scroll_h - (@cursor_line.number + 1) * @font_height
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
      @cursor_x = @cursor_line.measure_to(@cursor_index).lesser(@w)
      @ensure_cursor_visible = false

      if @selection_start != @selection_end
        selection_start_count = @selection_start.lesser(@selection_end)
        selection_length_count = @selection_end.greater(@selection_start) - selection_start_count
      else
        selection_start_count = -1
        selection_length_count = -1
      end

      content_bottom = @content_y - @font_height # internal use only, includes font_height, used for draw
      content_top = @content_y + @content_h # internal use only, used for draw
      selection_h = @font_height + @padding * 2

      @lines.each_with_index do |line, i| # rubocop:disable Metrics/BlockLength
        y = @scroll_h - @padding - (i + 1) * @font_height
        draw = y > content_bottom && y < content_top # Only draw things in the view

        # SELECTION
        # TODO: Ensure cursor_x doesn't go past the line width
        if selection_start_count >= 0
          if selection_start_count - line.length < 0
            # selection starts here
            line_chars_left = line.length - selection_start_count
            left = line.measure_to(selection_start_count)
            if selection_length_count - line_chars_left < 0
              # whole selection on this line
              if draw
                right = line.measure_to(selection_start_count + selection_length_count)
                rt.primitives << { x: left, y: y + @padding - @content_y, w: right - left, h: selection_h }.solid!(sc)
              end
              selection_length_count = -1
            else
              # selection to end of line and continues
              if draw
                right = line.measure_to(line.length)
                rt.primitives << { x: left, y: y + @padding - @content_y, w: right - left, h: selection_h }.solid!(sc)
              end
              selection_length_count -= line_chars_left
            end
            selection_start_count = -1
          else
            selection_start_count -= line.length
          end
        elsif selection_length_count >= 0
          if selection_length_count - line.length < 0
            # selection ends in this line
            if draw
              right = line.measure_to(selection_length_count)
              rt.primitives << { x: 0, y: y + @padding - @content_y, w: right, h: selection_h }.solid!(sc)
            end
            selection_length_count = -1
          else
            # whole line is part of the selection
            if draw
              right = line.measure_to(line.length)
              rt.primitives << { x: 0, y: y + @padding - @content_y, w: right, h: selection_h }.solid!(sc)
            end
            selection_length_count -= line.length
          end
        end

        # TEXT FOR LINE
        if draw
          rt.primitives << { x: 0, y: y - @content_y, text: line.clean_text, size_enum: @size_enum, font: @font }.label!(@text_color)
        end
      end

      draw_cursor(rt)
    end
  end
end
