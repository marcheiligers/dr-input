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
          select_all
        elsif @down_keys.include?(:c) && @selection_start != @selection_end
          copy
        elsif @down_keys.include?(:x) && @selection_start != @selection_end
          cut
        elsif @down_keys.include?(:v)
          paste
        elsif @down_keys.include?(:left)
          @shift ? select_to_start : move_to_start
        elsif @down_keys.include?(:right)
          @shift ? select_to_end : move_to_end
        else
          @on_unhandled_key.call(@down_keys.first, self)
        end
      elsif text_keys.empty?
        if (@down_keys & DEL_KEYS).any?
          # TODO: Treat delete and backspace differently
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
