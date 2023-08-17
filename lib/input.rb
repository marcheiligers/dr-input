# Initially based loosely on code from Zif
class Input
  attr_sprite
  attr_reader :value, :clipboard

  SIZE_ENUM = {
    small: -1,
    normal: 0,
    large: 1
  }.freeze

  CURSOR_FULL_TICKS = 30
  CURSOR_FLASH_TICKS = 20

  @@id = 0

  def initialize(**params)
    @x = params[:x] || 0
    @y = params[:y] || 0

    @font = nil
    @size_enum = SIZE_ENUM.fetch(params[:size_enum] || :normal, :size_enum)

    @word_chars = params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']
    _, @font_height = $gtk.calcstringbox(@word_chars.join(''), @size_enum, @font.to_s)
    @punctuation_chars = params[:punctuation_chars] || %w[! % , . ; : ' " ` ) \] } * &]
    @crnl_chars = ["\r", "\n"]
    @word_wrap_chars = @word_chars + @punctuation_chars

    @padding = params[:padding] || 2

    @w = params[:w] || 256
    @h = params[:h] || @font_height + @padding * 2

    @text_color = {
      r: params[:r] || 0,
      g: params[:g] || 0,
      b: params[:b] || 0,
      a: params[:a] || 255
    }

    @value = params[:value] || ''

    @selection_start = params[:selection_start] || @value.length
    @selection_end = params[:selection_end] || @selection_start

    @selection_color = {
      r: params[:selection_r] || 102,
      g: params[:selection_g] || 178,
      b: params[:selection_b] || 255,
      a: params[:selection_a] || 128
    }

    # To manage the flashing cursor
    @cursor_ticks = 0
    @cursor_dir = 1

    # TODO: implement key repeat for cursor movement
    @key_repeat_delay = params[:key_repeat_delay] = 20
    @key_repeat_debounce = params[:key_repeat_debounce] = 5
    @key_repeat_ticks = 0

    # Mouse focus for seletion
    @mouse_down = false

    # Render target for text scrolling
    @path = "__input_#{@@id += 1}"
    @source_x = 0

    # TODO: make clipboard global for if there's more than one input (0)
    @clipboard = nil

    @word_wrap = params[:word_wrap] || false
  end

  def draw_override(ffi)
    if @word_wrap
      ffi.draw_sprite_3(
        @x, @y, @w, @h,
        @path,
        0,
        255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        0, 0, @w, @h
      )

      # TODO: cursor for wrap-text
    else
      cursor_x = $gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font.to_s)[0].ceil

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

      ffi.draw_sprite_3(
        @x, @y, @source_w, @h,
        @path,
        0,
        255, 255, 255, 255,
        nil, nil, nil, nil,
        false, false,
        0, 0,
        @source_x, 0, @source_w, @h
      )

      # CURSOR
      # TODO: Cursor renders outside of the bounds of the control
      @cursor_ticks += @cursor_dir
      alpha = if @cursor_ticks == CURSOR_FULL_TICKS
                @cursor_dir = -1
                255
              elsif @cursor_ticks == 0
                @cursor_dir = 1
                0
              elsif @cursor_ticks < CURSOR_FULL_TICKS
                $args.easing.ease(0, @cursor_ticks, CURSOR_FLASH_TICKS, :quad) * 255
              else
                255
              end
      ffi.draw_solid(@x + cursor_x - @source_x, @y, @padding, @h + @padding * 2, 0, 0, 0, alpha)

# str = "source_x: #{@source_x} source_w: #{@source_w} relative_cursor_x: #{relative_cursor_x} cursor_x: #{cursor_x} text_width: #{@text_width}"
# putz str
# ffi.draw_label(100, 300, str, 0, 0, 0, 0, 0, 255, '')
    end
  end
  META_KEYS = %i[meta_left meta_right] # and `meta`
  SHIFT_KEYS = %i[shift_left shift_right]
  ALT_KEYS = %i[alt_left alt_right]
  CTRL_KEYS = %i[control_left control_right]
  DEL_KEYS = %i[delete backspace]

  def tick
    prepare_special_keys
    handle_keyboard
    handle_mouse
    prepare_render_target
  end

  def prepare_special_keys
    keyboard = $args.inputs.keyboard

    @down_keys = keyboard.key_down.truthy_keys

    # Find special keys
    special_keys = keyboard.key_down.truthy_keys + keyboard.key_held.truthy_keys
    @meta = (special_keys & META_KEYS).any?
    @alt = (special_keys & ALT_KEYS).any?
    @shift = (special_keys & SHIFT_KEYS).any?
    @ctrl = (special_keys & CTRL_KEYS).any?
  end

  def handle_keyboard
    text_keys = $args.inputs.text

    if @meta || @ctrl
      # TODO: undo/redo
      if @down_keys.include?(:a)
        @selection_start = 0
        @selection_end = @value.length
      end

      if @down_keys.include?(:c) && @selection_start != @selection_end
        @clipboard = if @selection_start < @selection_end
                       @value.slice(@selection_start, @selection_end - @selection_start)
                     else
                       @value.slice(@selection_end, @selection_start - @selection_end)
                     end
      end

      if @down_keys.include?(:x) && @selection_start != @selection_end
        @clipboard = if @selection_start < @selection_end
                       @value.slice(@selection_start, @selection_end - @selection_start)
                     else
                       @value.slice(@selection_end, @selection_start - @selection_end)
                     end
        @value = @value.slice(0, @selection_start.lesser(@selection_end)) + @value.slice(@selection_end.greater(@selection_start), @value.length)
        @selection_start = @selection_end = @selection_start.lesser(@selection_end)
      end

      if @down_keys.include?(:v)
        @value = @value.slice(0, @selection_start.lesser(@selection_end)) + @clipboard + @value.slice(@selection_end.greater(@selection_start), @value.length)
        @selection_start = @selection_end = @selection_start.lesser(@selection_end) + @clipboard.length
      end

      if @down_keys.include?(:left)
        if @shift
          @selection_end = 0
        else
          @selection_start = @selection_end = 0
        end
      end

      if @down_keys.include?(:right)
        if @shift
          @selection_end = @value.length
        else
          @selection_start = @selection_end = @value.length
        end
      end
    elsif text_keys.empty?
      if (@down_keys & DEL_KEYS).any?
        if @selection_start == @selection_end
          @value = @value.slice(0, @selection_start - 1).to_s + @value.slice(@selection_start, @value.length).to_s
          @selection_start = (@selection_start - 1).greater(0)
          @selection_end = @selection_start
        elsif @selection_start < @selection_end
          @value = @value.slice(0, @selection_start).to_s + @value.slice(@selection_end, @value.length).to_s
          @selection_end = @selection_start
        else
          @value = @value.slice(0, @selection_end).to_s + @value.slice(@selection_start, @value.length).to_s
          @selection_start = @selection_end
        end
      elsif @down_keys.include?(:left)
        if @shift
          @selection_end = if @alt
                             find_word_break_left
                           else
                             (@selection_end - 1).greater(0)
                           end
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
          @selection_end = if @alt
                             find_word_break_right
                           else
                             (@selection_end + 1).lesser(@value.length)
                           end
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
      end
    else
      # BUG: Something is wrong with inserting at the end
      text_keys.each do |key|
        if @selection_start == @selection_end
          @value = @value.slice(0, @selection_start).to_s + key + @value.slice(@selection_start, @value.length).to_s
          @selection_start += 1
        elsif @selection_start < @selection_end
          @value = @value.slice(0, @selection_start).to_s + key + @value.slice(@selection_end, @value.length).to_s
          @selection_start += 1
        elsif @selection_start > @selection_end
          @value = @value.slice(0, @selection_end).to_s + key + @value.slice(@selection_start, @value.length).to_s
          @selection_start = @selection_end + 1
        end
        @selection_end = @selection_start
      end
    end
  end

  # TODO: Word selection (double click), All selection (triple click)
  def handle_mouse
    mouse = $args.inputs.mouse

    if !@mouse_down && mouse.down && mouse.inside_rect?(self)
      @mouse_down = true

      index = find_index_at_x(mouse.x - @x + @source_x)
      if @shift
        @selection_end = index
      else
        @selection_start = @selection_end = index
      end
    elsif @mouse_down
      @selection_end = find_index_at_x(mouse.x - @x + @source_x)
      @mouse_down = false if mouse.up
    end
  end

  # BUG: Single character words are busted
  # TODO: Improve walking words
  def find_word_break_left
    return 0 if @selection_end == 0

    index = @selection_end
    found_word_char = false
    while !found_word_char
      index -= 1
      return 0 if index == 0
      found_word_char = true if @word_chars.include?(@value[index, 1])
    end

    while true
      index -= 1
      return 0 if index == 0
      return index + 1 unless @word_chars.include?(@value[index, 1])
    end
  end

  def find_word_break_right(index = @selection_end)
    length = @value.length
    return length if index == length

    found_word_char = false
    while !found_word_char
      index += 1
      return length if index == length
      found_word_char = true if @word_chars.include?(@value[index, 1])
    end

    while true
      index += 1
      return length if index == length
      return index unless @word_chars.include?(@value[index, 1])
    end
  end

  def word_breaks(value = @value)
    # @word_chars = params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']
    # _, @font_height = $gtk.calcstringbox(@word_chars.join(''), @size_enum, @font.to_s)
    # @punctuation_chars = params[:punctuation_chars] || %w[! % , . ; : ' " ` ) \] } * &]
    # @crnl_chars = ["\r", "\n"]
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
          if @crnl_chars.include?(value[index])
            word << "\n"
            words << word
            word = ''
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
        elsif @crnl_chars.include?(value[index])
          word << "\n"
          words << word
          word = ''
          mode = :leading_white_space
        else
          word << value[index]
          mode = :trailing_white_space
        end
      when :trailing_white_space
        if value[index].strip == '' # trailing white-space
          if @crnl_chars.include?(value[index])
            word << "\n" # converting all new line chars to \n
            words << word
            word = ''
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

  def find_index_at_x(x)
    return 0 if x < @padding

    index = 0
    while index < @value.length
      index += 1
      width, = $gtk.calcstringbox(@value[0, index].to_s, @size_enum, @font.to_s)
      break if width > x
    end
    index
  end

  def prepare_render_target
    if @word_wrap
      # calculate lines
      lines = []
      index = 0
      prev_index = 0
      prev_line_index = 0
      while (index = find_word_break_right(index)) < @value.length
        # TODO: handle case where a single word is wider than the field (gotta break it somewhere)
        width, = $gtk.calcstringbox(@value[prev_line_index, index].to_s, @size_enum, @font.to_s)
        if width > @w
          lines << @value.slice(prev_line_index, prev_index)
          prev_line_index = prev_index
        end
        prev_index = index
      end
      lines << @value.slice(prev_line_index, prev_index)

      @h = lines.length * @font_height + 2 * @padding # TODO: Implement line spacing
      rt = $args.outputs[@path]
      rt.w = @w
      rt.h = @h
      rt.transient!

      puts lines
      puts @h

      # TODO: Multi-line selection
      lines.each_with_index do |line, i|
        puts "#{@h - @padding - i * @font_height}: #{line}"
        rt.primitives << { x: 0, y: @h - @padding - i * @font_height, text: line, size_enum: @size_enum, font: @font.to_s }.label!(@text_color)
      end
    else
      # TODO: handle padding correctly
      @text_width = $gtk.calcstringbox(@value, @size_enum, @font.to_s)[0].ceil
      rt = $args.outputs[@path]
      rt.w = @text_width
      rt.h = @h
      rt.transient!

      # SELECTION
      if @selection_start != @selection_end
        if @selection_start < @selection_end
          left, = $gtk.calcstringbox(@value[0, @selection_start].to_s, @size_enum, @font.to_s)
          right, = $gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font.to_s)
        elsif @selection_start > @selection_end
          left, = $gtk.calcstringbox(@value[0, @selection_end].to_s, @size_enum, @font.to_s)
          right, = $gtk.calcstringbox(@value[0, @selection_start].to_s, @size_enum, @font.to_s)
        end

        rt.primitives << { x: left, y: @padding, w: right - left, h: @font_height + @padding * 2 }.solid!(@selection_color)
      end

      # TEXT
      rt.primitives << { x: 0, y: @h - @padding, text: @value, size_enum: @size_enum, font: @font.to_s }.label!(@text_color)
    end
  end
end
