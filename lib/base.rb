module Input
  class Base
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

    NOOP = -> {}

    # BUG: Modifier keys are broken on the web ()
    META_KEYS = %i[meta_left meta_right meta]
    SHIFT_KEYS = %i[shift_left shift_right shift]
    ALT_KEYS = %i[alt_left alt_right alt]
    CTRL_KEYS = %i[control_left control_right control]
    DEL_KEYS = %i[delete backspace]
    IGNORE_KEYS = %i[raw_key char] + META_KEYS + SHIFT_KEYS + ALT_KEYS + CTRL_KEYS

    @@id = 0

    def initialize(**params)
      @x = params[:x] || 0
      @y = params[:y] || 0

      @font = params[:font].to_s
      @size_enum = SIZE_ENUM.fetch(params[:size_enum] || :normal, :size_enum)

      @word_chars = params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-']
      _, @font_height = $gtk.calcstringbox(@word_chars.join(''), @size_enum, @font)
      @punctuation_chars = params[:punctuation_chars] || %w[! % , . ; : ' " ` ) \] } * &]
      @crlf_chars = ["\r", "\n"]
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
      @blurred_background_color = params[:blurred_background_color] || @background_color

      @value = params[:value] || ''

      @selection_start = params[:selection_start] || @value.length
      @selection_end = params[:selection_end] || @selection_start

      @selection_color = {
        r: params[:selection_r] || 102,
        g: params[:selection_g] || 178,
        b: params[:selection_b] || 255,
        a: params[:selection_a] || 128
      }

      @blurred_selection_color = {
        r: params[:blurred_selection_r] || 112,
        g: params[:blurred_selection_g] || 128,
        b: params[:blurred_selection_b] || 144,
        a: params[:blurred_selection_a] || 128
      }

      # To manage the flashing cursor
      @cursor_ticks = 0
      @cursor_dir = 1

      @key_repeat_delay = params[:key_repeat_delay] = 20
      @key_repeat_debounce = params[:key_repeat_debounce] = 5

      # Mouse focus for seletion
      @mouse_down = false

      # Render target for text scrolling
      @path = "__input_#{@@id += 1}"
      @source_x = 0
      @source_y = 0

      @focussed = params[:focussed] || false
      @will_focus = false # Get the focus at the end of the tick

      @on_clicked = params[:on_clicked] || NOOP
      @on_unhandled_key = params[:on_unhandled_key] || NOOP
    end

    def draw_override(ffi)
      if @will_focus
        @will_focus = false
        @focussed = true
      end

      return unless @focussed

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

    def tick
      if @focussed
        prepare_special_keys
        handle_keyboard
      end
      handle_mouse
      prepare_render_target
    end

    def value=(text)
      @value = text
      @selection_start = @selection_start.lesser(@value.length)
      @selection_end = @selection_end.lesser(@value.length)
    end

    def selection_start=(index)
      @selection_start = index.cap_min_max(0, @value.length)
    end

    def selection_end=(index)
      @selection_end = index.cap_min_max(0, @value.length)
    end

    def focussed?
      @focussed
    end

    def focus
      @will_focus = true
    end

    def blur
      @focussed = false
    end

    def select_all
      @selection_start = 0
      @selection_end = @value.length
    end

    def select_to_start
      @selection_end = 0
    end

    def move_to_start
      @selection_start = @selection_end = 0
    end

    def select_to_end
      @selection_end = @value.length
    end

    def move_to_end
      @selection_start = @selection_end = @value.length
    end

    def delete_back
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
    end

    def select_word_left
      @selection_end = find_word_break_left
    end

    def select_word_right
      @selection_end = find_word_break_right
    end

    def select_char_left
      @selection_end = (@selection_end - 1).greater(0)
    end

    def select_char_right
      @selection_end = (@selection_end + 1).lesser(@value.length)
    end

    def move_word_left
      @selection_start = @selection_end = find_word_break_left
    end

    def move_word_right
      @selection_start = @selection_end = find_word_break_right
    end

    def move_char_left
      @selection_end = if @selection_end > @selection_start
                         @selection_start
                       elsif @selection_end < @selection_start
                         @selection_end
                       else
                         (@selection_start - 1).greater(0)
                       end
      @selection_start = @selection_end
    end

    def move_char_right
      @selection_end = if @selection_end > @selection_start
                         @selection_end
                       elsif @selection_end < @selection_start
                         @selection_start
                       else
                         (@selection_start + 1).lesser(@value.length)
                       end
      @selection_start = @selection_end
    end

    def copy
      return if @selection_start == @selection_end

      $clipboard = if @selection_start < @selection_end
                     @value[@selection_start, @selection_end - @selection_start]
                   else
                     @value[@selection_end, @selection_start - @selection_end]
                   end
    end

    def cut
      copy
      @value = @value[0, @selection_start.lesser(@selection_end)] + @value[@selection_end.greater(@selection_start), @value.length]
      @selection_start = @selection_end = @selection_start.lesser(@selection_end)
    end

    def paste
      @value = @value[0, @selection_start.lesser(@selection_end)] + $clipboard + @value[@selection_end.greater(@selection_start), @value.length]
      @selection_start = @selection_end = @selection_start.lesser(@selection_end) + $clipboard.length
    end

    def prepare_special_keys
      keyboard = $args.inputs.keyboard

      tick_count = $args.tick_count
      repeat_keys = keyboard.key_held.truthy_keys.select do |key|
        ticks = tick_count - keyboard.key_held.send(key).to_i
        ticks > @key_repeat_delay && ticks % @key_repeat_debounce == 0
      end
      @down_keys = keyboard.key_down.truthy_keys.concat(repeat_keys) - IGNORE_KEYS

      # Find special keys
      special_keys = keyboard.key_down.truthy_keys + keyboard.key_held.truthy_keys
      @meta = (special_keys & META_KEYS).any?
      @alt = (special_keys & ALT_KEYS).any?
      @shift = (special_keys & SHIFT_KEYS).any?
      @ctrl = (special_keys & CTRL_KEYS).any?
    end

    def insert(str)
      if @selection_start == @selection_end
        @value = @value[0, @selection_start].to_s + str + @value[@selection_start, @value.length].to_s
        @selection_start += str.length
      elsif @selection_start < @selection_end
        @value = @value[0, @selection_start].to_s + str + @value[@selection_end, @value.length].to_s
        @selection_start += str.length
      elsif @selection_start > @selection_end
        @value = @value[0, @selection_end].to_s + str + @value[@selection_start, @value.length].to_s
        @selection_start = @selection_end + str.length
      end
      @selection_end = @selection_start
    end
    alias replace insert

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
  end
end
