# Initially based loosely on code from Zif
$clipboard = nil

class Input
  attr_sprite
  attr_reader :value, :selection_start, :selection_end

  SIZE_ENUM = {
    small: -1,
    normal: 0,
    large: 1,
    xlarge: 2,
    xxlarge: 3,
    xxxlarge: 4
  }.freeze

  CURSOR_FULL_TICKS = 30
  CURSOR_FLASH_TICKS = 20

  @@id = 0

  def initialize(**params)
    @x = params[:x] || 0
    @y = params[:y] || 0

    @font = params[:font].to_s
    @size_enum = SIZE_ENUM.fetch(params[:size_enum] || :normal, :size_enum)

    @word_chars = params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']
    _, @font_height = $gtk.calcstringbox(@word_chars.join(''), @size_enum, @font)
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
      a: params[:a] || 255,
      vertical_alignment_enum: 0
    }
    @background_color = params[:background_color]

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

    # Mouse focus for seletion
    @mouse_down = false

    # Render target for text scrolling
    @path = "__input_#{@@id += 1}"
    @source_x = 0

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
    else
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

# str = "source_x: #{@source_x} source_w: #{@source_w} relative_cursor_x: #{relative_cursor_x} cursor_x: #{cursor_x} text_width: #{@text_width}"
# putz str
# ffi.draw_label(100, 300, str, 0, 0, 0, 0, 0, 255, '')
    end

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
    ffi.draw_solid(@cursor_x, @cursor_y, @padding, @font_height + @padding * 2, 0, 0, 0, alpha)
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
        $clipboard = if @selection_start < @selection_end
                       @value.slice(@selection_start, @selection_end - @selection_start)
                     else
                       @value.slice(@selection_end, @selection_start - @selection_end)
                     end
      end

      if @down_keys.include?(:x) && @selection_start != @selection_end
        $clipboard = if @selection_start < @selection_end
                       @value.slice(@selection_start, @selection_end - @selection_start)
                     else
                       @value.slice(@selection_end, @selection_start - @selection_end)
                     end
        @value = @value.slice(0, @selection_start.lesser(@selection_end)) + @value.slice(@selection_end.greater(@selection_start), @value.length)
        @selection_start = @selection_end = @selection_start.lesser(@selection_end)
      end

      if @down_keys.include?(:v)
        @value = @value.slice(0, @selection_start.lesser(@selection_end)) + $clipboard + @value.slice(@selection_end.greater(@selection_start), @value.length)
        @selection_start = @selection_end = @selection_start.lesser(@selection_end) + $clipboard.length
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
      elsif @down_keys.include?(:enter) && @word_wrap
        insert("\n")
      end
    else
      insert(text_keys.join(''))
    end
  end

  def insert(str)
    if @selection_start == @selection_end
      @value = @value.slice(0, @selection_start).to_s + str + @value.slice(@selection_start, @value.length).to_s
      @selection_start += str.length
    elsif @selection_start < @selection_end
      @value = @value.slice(0, @selection_start).to_s + str + @value.slice(@selection_end, @value.length).to_s
      @selection_start += str.length
    elsif @selection_start > @selection_end
      @value = @value.slice(0, @selection_end).to_s + str + @value.slice(@selection_start, @value.length).to_s
      @selection_start = @selection_end + str.length
    end
    @selection_end = @selection_start
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

  def find_word_breaks(value = @value)
    # @word_chars = params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']
    # _, @font_height = $gtk.calcstringbox(@word_chars.join(''), @size_enum, @font)
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
          if @crnl_chars.include?(value[index]) # TODO: prolly need to replace \r\n with \n up front
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
        elsif @crnl_chars.include?(value[index])
          words << word
          word = "\n"
          mode = :leading_white_space
        else
          word << value[index]
          mode = :trailing_white_space
        end
      when :trailing_white_space
        if value[index].strip == '' # trailing white-space
          if @crnl_chars.include?(value[index])
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
    lines = []
    line = ''
    i = -1
    l = words.length
    # ["1", "\n", "\n", "\n2"]
    while (i += 1) < l
      word = words[i]
      if word == "\n"
        lines << line
        line = word
      else
        width, = $gtk.calcstringbox((line + word).rstrip, @size_enum, @font)
        if width > @w
          lines << line
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
    # lines << '' if line.end_with?("\n")
    # lines
  end

  def find_index_at_x(x)
    return 0 if x < @padding

    index = 0
    while index < @value.length
      index += 1
      width, = $gtk.calcstringbox(@value[0, index].to_s, @size_enum, @font)
      break if width > x
    end
    index
  end

  def prepare_render_target
    if @word_wrap
      # calculate lines
      lines = perform_word_wrap

      @h = lines.length * @font_height + 2 * @padding # TODO: Implement line spacing
      rt = $args.outputs[@path]
      rt.w = @w
      rt.h = @h
      rt.background_color = @background_color
      # TODO: implement sprite background
      rt.transient!

      putz @value.gsub("\n", '\n')
      putz lines

      if @selection_start != @selection_end
        selection_start_count = @selection_start.lesser(@selection_end)
        selection_length_count = @selection_end.greater(@selection_start) - selection_start_count
      else
        selection_start_count = -1
        selection_length_count = -1
      end
      cursor_count = @selection_end

      lines.each_with_index do |line, i|
        y = @h - @padding - (i + 1) * @font_height
        puts "#{i}: #{line.gsub("\n", '\n')}"

        # SELECTION
        if selection_start_count >= 0
          if selection_start_count - line.length <= 0
            # selection starts here
            line_chars_left = line.length - selection_start_count
            left, = $gtk.calcstringbox(@value[0, selection_start_count].to_s, @size_enum, @font)
            if selection_length_count - line_chars_left <= 0
              # whole selection on this line
              right, = $gtk.calcstringbox(@value[0, selection_start_count + selection_length_count].to_s, @size_enum, @font)
              rt.primitives << { x: left, y: y + @padding, w: right - left, h: @font_height + @padding * 2 }.solid!(@selection_color)
              selection_length_count = -1
            else
              # selection to end of line and continues
              rt.primitives << { x: left, y: y + @padding, w: @w - left, h: @font_height + @padding * 2 }.solid!(@selection_color)
              selection_length_count -= line_chars_left
            end
            selection_start_count = -1
          else
            selection_start_count -= line.length
          end
        elsif selection_length_count >= 0
          if selection_length_count - line.length <= 0
            # selection ends in this line
            right, = $gtk.calcstringbox(line[0, selection_length_count].to_s, @size_enum, @font)
            rt.primitives << { x: 0, y: y + @padding, w: right, h: @font_height + @padding * 2 }.solid!(@selection_color)
            selection_length_count = -1
          else
            # whole line is part of the selection
            selection_length_count -= line.length
            rt.primitives << { x: 0, y: y + @padding, w: @w, h: @font_height + @padding * 2 }.solid!(@selection_color)
          end
        end

        # TEXT FOR LINE
        rt.primitives << { x: 0, y: y, text: line, size_enum: @size_enum, font: @font }.label!(@text_color)

        # CURSOR LOCATION
        if cursor_count >= 0 && cursor_count - line.length <= 0
          @cursor_y = y + @y
          @cursor_x = $gtk.calcstringbox(line[0, cursor_count].to_s, @size_enum, @font)[0] + @x
          cursor_count = -1
        else
          cursor_count -= line.length
        end
      end
    else
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
