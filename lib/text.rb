module Input
  class Text < Base
    def draw_override(ffi)
      ffi.draw_sprite_3(@x, @y, @source_w, @h, @path, 0, 255, 255, 255, 255, nil, nil, nil, nil, false, false, 0, 0, @source_x, 0, @source_w, @h)
      super # handles focus and draws the cursor
    end

    def handle_keyboard
      text_keys = $args.inputs.text

      if @meta || @ctrl
        # TODO: undo/redo
        if @down_keys.include?(:a)
          @selection_start = 0
          @selection_end = @value.length
        elsif @down_keys.include?(:c) && @selection_start != @selection_end
          copy
        elsif @down_keys.include?(:x) && @selection_start != @selection_end
          cut
        elsif @down_keys.include?(:v)
          paste
        elsif @down_keys.include?(:left)
          if @shift
            @selection_end = 0
          else
            @selection_start = @selection_end = 0
          end
        elsif @down_keys.include?(:right)
          if @shift
            @selection_end = @value.length
          else
            @selection_start = @selection_end = @value.length
          end
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif text_keys.empty?
        if (@down_keys & DEL_KEYS).any?
          if @selection_start == @selection_end
            @value = @value[0, @selection_start - 1].to_s + @value[@selection_start, @value.length]
            @selection_start = (@selection_start - 1).greater(0)
            @selection_end = @selection_start
          elsif @selection_start < @selection_end
            @value = @value[0, @selection_start] + @value[@selection_end, @value.length]
            @selection_end = @selection_start
          else
            @value = @value[0, @selection_end] + @value[@selection_start, @value.length]
            @selection_start = @selection_end
          end
        elsif @down_keys.include?(:left)
          if @shift
            @selection_end = @alt ? find_word_break_left : (@selection_end - 1).greater(0)
          else
            @selection_start = if @alt
                                 find_word_break_left
                               elsif @selection_end > @selection_start
                                 @selection_start
                               elsif @selection_end < @selection_start
                                 @selection_end
                               else
                                 (@selection_start - 1).greater(0)
                               end
            @selection_end = @selection_start
          end
        elsif @down_keys.include?(:right)
          if @shift
            @selection_end = @alt ? find_word_break_right : (@selection_end + 1).lesser(@value.length)
          else
            @selection_start = if @alt
                                 find_word_break_right
                               elsif @selection_end > @selection_start
                                 @selection_end
                               elsif @selection_end < @selection_start
                                 @selection_start
                               else
                                 (@selection_start + 1).lesser(@value.length)
                               end
            @selection_end = @selection_start
          end
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      else
        insert(text_keys.join(''))
      end
    end

    # TODO: Word selection (double click), All selection (triple click)
    def handle_mouse
      mouse = $args.inputs.mouse

      if !@mouse_down && mouse.down && mouse.inside_rect?(self)
        @on_clicked.call(mouse, self)
        return unless @focussed || @will_focus

        @mouse_down = true

        index = find_index_at_x(mouse.x - @x + @source_x)
        if @shift
          @selection_end = index
        else
          @selection_start = @selection_end = index
        end
      elsif @mouse_down
        index = find_index_at_x(mouse.x - @x + @source_x) # TODO: handle scrolling to the right with mouse
        @selection_end = index
        @mouse_down = false if mouse.up
      end
    end

    # TODO: Improve walking words
    def find_word_break_left
      return 0 if @selection_end == 0

      index = @selection_end

      loop do
        index -= 1
        return 0 if index == 0
        break if @word_chars.include?(@value[index, 1])
      end

      loop do
        index -= 1
        return 0 if index == 0
        return index + 1 unless @word_chars.include?(@value[index, 1])
      end
    end

    def find_word_break_right(index = @selection_end)
      length = @value.length
      return length if index == length

      loop do
        index += 1
        return length if index == length
        break if @word_chars.include?(@value[index, 1])
      end

      loop do
        index += 1
        return length if index == length
        return index unless @word_chars.include?(@value[index, 1])
      end
    end

    def find_index_at_x(x, str = @value)
      return 0 if x < @padding

      index = -1
      width = 0
      while (index += 1) < str.length
        char_w = $gtk.calcstringbox(str[index, 1].to_s, @size_enum, @font)[0]
        return index if width + char_w / 2 > x
        return index + 1 if width + char_w > x

        width += char_w
      end

      index
    end

    def prepare_render_target
      # TODO: handle padding correctly
      @text_width = $gtk.calcstringbox(@value, @size_enum, @font)[0].ceil
      rt = $args.outputs[@path]
      rt.w = @text_width
      rt.h = @h
      rt.background_color = @background_color
      # TODO: implement sprite background
      rt.transient!

      # SELECTION
      if @selection_start != @selection_end
        if @selection_start < @selection_end
          left, = $gtk.calcstringbox(@value[0, @selection_start].to_s, @size_enum, @font)
          right, = $gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font)
        elsif @selection_start > @selection_end
          left, = $gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font)
          right, = $gtk.calcstringbox(@value[0, @selection_start].to_s, @size_enum, @font)
        end

        rt.primitives << { x: left, y: @padding, w: right - left, h: @font_height + @padding * 2 }.solid!(@selection_color)
      end

      # TEXT
      rt.primitives << { x: 0, y: @padding, text: @value, size_enum: @size_enum, font: @font }.label!(@text_color)

      # CURSOR LOCATION
      cursor_x = $gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font)[0]

      @source_w = @text_width < @w ? @text_width : @w
      if @source_w < @w
        @source_x = 0
      else
        relative_cursor_x = cursor_x - @source_x
        if relative_cursor_x <= 0
          @source_x = cursor_x.greater(0)
        elsif relative_cursor_x > @w
          @source_x = (cursor_x - @w).lesser(@text_width - @w)
        end
      end

      @source_x = @text_width - @w if @text_width - @source_x < @w && @text_width > @w

      @cursor_x = @x + cursor_x - @source_x
      @cursor_y = @y
    end
  end
end
