module Input
  class Multiline < Base
    attr_reader :lines

    def initialize(**params)
      super

      @word_wrap_chars = @word_chars + @punctuation_chars
    end

    def draw_override(ffi)
      ffi.draw_sprite_3(@x, @y, @w, @h, @path, 0, 255, 255, 255, 255, nil, nil, nil, nil, false, false, 0, 0, 0, 0, @w, @h)
      super # handles focus and draws the cursor
    end

    def handle_keyboard
      text_keys = $args.inputs.text

      if @meta || @ctrl
        # TODO: undo/redo
        if @down_keys.include?(:a)
          select_all
        elsif @down_keys.include?(:c)
          copy
        elsif @down_keys.include?(:x)
          cut
        elsif @down_keys.include?(:v)
          paste
        elsif @down_keys.include?(:left)
          @shift ? select_to_line_start : move_to_line_start
        elsif @down_keys.include?(:right)
          @shift ? select_to_line_end : move_to_line_end
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif text_keys.empty?
        if (@down_keys & DEL_KEYS).any?
          delete_back
        elsif @down_keys.include?(:left)
          if @shift
            @alt ? select_word_left : select_char_left
          else
            @alt ? move_word_left : move_char_left
          end
        elsif @down_keys.include?(:right)
          if @shift
            @alt ? select_word_right : select_char_right
          else
            @alt ? move_word_right : move_char_right
          end
        # TODO: Retain a original_cursor_x when moving up/down to try stay generally in the same x range
        elsif @down_keys.include?(:up)
          if @shift
            select_line_up
          else
            # TODO: beginning of previous paragraph with alt
            move_line_up
          end
        elsif @down_keys.include?(:down)
          if @shift
            select_line_down
          else
            # TODO: end of next paragraph with alt
            move_line_down
          end
        elsif @down_keys.include?(:enter)
          insert("\n")
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      else
        insert(text_keys.join(''))
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
        @lines[line.number - 1].index_at(@cursor_x - @x + @source_x)
      end
    end

    def selection_end_down_index
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
        @lines[line.number + 1].index_at(@cursor_x - @x + @source_x)
      end
    end

    def current_line
      @lines&.line_at(@selection_end)
    end

    # TODO: Word selection (double click), All selection (triple click)
    def handle_mouse
      mouse = $args.inputs.mouse

      if !@mouse_down && mouse.down && mouse.inside_rect?(self)
        @on_clicked.call(mouse, self)
        return unless @focussed || @will_focus

        @mouse_down = true

        line = @lines[(@h + @y - mouse.y + @source_y).idiv(@font_height).cap_min_max(0, @lines.length - 1)]
        index = line.index_at(mouse.x - @x + @source_x)
        if @shift
          @selection_end = index
        else
          @selection_start = @selection_end = index
        end
      elsif @mouse_down
        line = @lines[(@h + @y - mouse.y + @source_y).idiv(@font_height).clamp(0, @lines.length - 1)]
        index = line.index_at(mouse.x - @x + @source_x)
        @selection_end = index
        @mouse_down = false if mouse.up
      end
    end

    def find_word_breaks(value = @value)
      # @word_chars = params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']
      # _, @font_height = $gtk.calcstringbox(@word_chars.join(''), @size_enum, @font)
      # @punctuation_chars = params[:punctuation_chars] || %w[! % , . ; : ' " ` ) \] } * &]
      # @crlf_chars = ["\r", "\n"]
      # @word_wrap_chars = @word_chars + @punctuation_chars
      words = []
      word = ''
      index = -1
      length = value.length
      mode = :leading_white_space

      while (index += 1) < length # mode = find a word-like thing
        case mode
        when :leading_white_space
          if value[index].strip == '' # leading white-space
            if @crlf_chars.include?(value[index]) # TODO: prolly need to replace \r\n with \n up front
              words << word
              word = "\n"
            else
              word << value[index] # TODO: consider how to render TAB, maybe convert TAB into 4 spaces?
            end
          else
            word << value[index]
            mode = :word_wrap_chars
          end
        when :word_wrap_chars # TODO: consider smarter handling. "something!)something" would be considered a word right now, theres an extra step needed
          if @word_wrap_chars.include?(value[index])
            word << value[index]
          elsif @crlf_chars.include?(value[index])
            words << word
            word = "\n"
            mode = :leading_white_space
          else
            word << value[index]
            mode = :trailing_white_space
          end
        when :trailing_white_space
          if value[index].strip == '' # trailing white-space
            if @crlf_chars.include?(value[index])
              words << word
              word = "\n" # converting all new line chars to \n
              mode = :leading_white_space
            else
              word << value[index] # TODO: consider how to render TAB, maybe convert TAB into 4 spaces?
            end
          else
            words << word
            word = value[index]
            mode = :word_wrap_chars
          end
        end
      end

      words << word
    end

    def perform_word_wrap(words = find_word_breaks)
      lines = LineCollection.new(@font, @size_enum)
      line = ''
      i = -1
      l = words.length
      while (i += 1) < l
        word = words[i]
        if word == "\n"
          lines << line
          line = word
        else
          width, = $gtk.calcstringbox((line + word).rstrip, @size_enum, @font)
          if width > @w
            lines.append(line, true)
            line = word
          elsif word.start_with?("\n")
            lines << line
            line = word
          else
            line << word
          end
        end
      end

      lines << line
    end

    def prepare_render_target
      if @focussed || @will_focus
        bg = @background_color
        sc = @selection_color
      else
        bg = @blurred_background_color
        sc = @blurred_selection_color
      end

      @lines = perform_word_wrap

      @h = @lines.length * @font_height + 2 * @padding # TODO: Implement line spacing
      rt = $args.outputs[@path]
      rt.w = @w
      rt.h = @h
      rt.background_color = bg
      # TODO: implement sprite background
      rt.transient!

      # putz @value.gsub("\n", '\n')
      # putz lines

      if @selection_start != @selection_end
        selection_start_count = @selection_start.lesser(@selection_end)
        selection_length_count = @selection_end.greater(@selection_start) - selection_start_count
      else
        selection_start_count = -1
        selection_length_count = -1
      end

      @lines.each_with_index do |line, i|
        y = @h - @padding - (i + 1) * @font_height

        # SELECTION
        # TODO: Ensure cursor_x doesn't go past the line width
        if selection_start_count >= 0
          if selection_start_count - line.length < 0
            # selection starts here
            line_chars_left = line.length - selection_start_count
            left = line.measure_to(selection_start_count)
            if selection_length_count - line_chars_left < 0
              # whole selection on this line
              right = line.measure_to(selection_start_count + selection_length_count)
              rt.primitives << { x: left, y: y + @padding, w: right - left, h: @font_height + @padding * 2 }.solid!(sc)
              selection_length_count = -1
            else
              # selection to end of line and continues
              right = line.measure_to(line.length)
              rt.primitives << { x: left, y: y + @padding, w: right - left, h: @font_height + @padding * 2 }.solid!(sc)
              selection_length_count -= line_chars_left
            end
            selection_start_count = -1
          else
            selection_start_count -= line.length
          end
        elsif selection_length_count >= 0
          if selection_length_count - line.length < 0
            # selection ends in this line
            right = line.measure_to(selection_length_count)
            rt.primitives << { x: 0, y: y + @padding, w: right, h: @font_height + @padding * 2 }.solid!(sc)
            selection_length_count = -1
          else
            # whole line is part of the selection
            right = line.measure_to(line.length)
            selection_length_count -= line.length
            rt.primitives << { x: 0, y: y + @padding, w: right, h: @font_height + @padding * 2 }.solid!(sc)
          end
        end

        # TEXT FOR LINE
        rt.primitives << { x: 0, y: y, text: line.clean_text, size_enum: @size_enum, font: @font }.label!(@text_color)
      end

      # CURSOR LOCATION
      line = @lines.line_at(@selection_end)
      cursor_index = @selection_end - line.start
      # Move the cursor to the beginning of the next line if the line is wrapped and we're at the end of the line
      if cursor_index == line.length && line.wrapped? && @lines.length > line.number
        line = @lines[line.number + 1]
        cursor_index = 0
      end
      @cursor_y = @y + @h - @padding - (line.number + 1) * @font_height
      @cursor_x = line.measure_to(cursor_index).lesser(@w) + @x
    end
  end
end
