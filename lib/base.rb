module Input
  class Base
    attr_sprite
    attr_reader :value, :selection_start, :selection_end, :cursor_x, :cursor_y,
                :content_w, :content_h, :scroll_w, :scroll_h
    attr_accessor :readonly, :scroll_x, :scroll_y

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

    NOOP = ->(*_args) {}

    # BUG: Modifier keys are broken on the web ()
    META_KEYS = %i[meta_left meta_right meta].freeze
    SHIFT_KEYS = %i[shift_left shift_right shift].freeze
    ALT_KEYS = %i[alt_left alt_right alt].freeze
    CTRL_KEYS = %i[control_left control_right control].freeze
    IGNORE_KEYS = (%i[raw_key char] + META_KEYS + SHIFT_KEYS + ALT_KEYS + CTRL_KEYS).freeze

    @@id = 0

    def initialize(**params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      @x = params[:x] || 0
      @y = params[:y] || 0

      @font = params[:font].to_s
      @size_enum = SIZE_ENUM.fetch(params[:size_enum] || :normal, :size_enum)

      word_chars = (params[:word_chars] || ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['_', '-'])
      _, @font_height = $gtk.calcstringbox(word_chars.join(''), @size_enum, @font)
      @word_chars = Hash[word_chars.map { [_1, true] }]
      @punctuation_chars = Hash[(params[:punctuation_chars] || %w[! % , . ; : ' " ` ) \] } * &]).map { [_1, true] }]
      @crlf_chars = { "\r" => true, "\n" => true }

      @padding = params[:padding] || 2

      @w = params[:w] || 256
      @h = params[:h] || @font_height + @padding * 2

      @text_color = (parse_color_nilable(params, :text) || {
        r: params[:r] || 0,
        g: params[:g] || 0,
        b: params[:b] || 0,
        a: params[:a] || 255,
      }).merge(vertical_alignment_enum: 0)
      @background_color = parse_color_nilable(params, :background)
      @blurred_background_color = parse_color_nilable(params, :blurred) || @background_color

      @prompt = params[:prompt] || ''
      @prompt_color = parse_color(params, :prompt, 128, 128, 128).merge(vertical_alignment_enum: 0)

      @max_length = params[:max_length] || false

      @selection_start = params[:selection_start] || params.fetch(:value, '').length
      @selection_end = params[:selection_end] || @selection_start

      @selection_color = parse_color(params, :selection, 102, 178, 255, 128)
      @blurred_selection_color = parse_color(params, :blurred_selection, 112, 128, 144, 128)

      # To manage the flashing cursor
      @cursor_color = parse_color(params, :cursor)
      @cursor_width = params[:cursor_width] || 2
      @cursor_ticks = 0
      @cursor_dir = 1
      @ensure_cursor_visible = true

      @key_repeat_delay = params[:key_repeat_delay] || 20
      @key_repeat_debounce = params[:key_repeat_debounce] || 4

      # Mouse focus for seletion
      @mouse_down = false
      @mouse_wheel_speed = params[:mouse_wheel_speed] || @font_height

      # Render target for text scrolling
      @path = "__input_#{@@id += 1}"

      @scroll_x = 0
      @scroll_y = 0
      @content_w = @w
      @content_h = @h

      @scroll_x = 0
      @scroll_y = 0
      @scroll_w = @w
      @scroll_h = @h

      @readonly = params[:readonly] || false
      @focussed = params[:focussed] || false
      @will_focus = false # Get the focus at the end of the tick

      @on_clicked = params[:on_clicked] || NOOP
      @on_unhandled_key = params[:on_unhandled_key] || NOOP

      @value_changed = true
    end

    def parse_color(params, name, dr = 0, dg = 0, db = 0, da = 255)
      cp = params["#{name}_color".to_sym]
      if cp
        case cp
        when Array
          { r: cp[0] || dr, g: cp[1] || dg, b: cp[2] || db, a: cp[3] || da }
        when Hash
          { r: cp.r || dr, g: cp.g || dg, b: cp.b || db, a: cp.a || da }
        when Integer
          puts "cp = #{cp}"
          if cp > 0xFFFFFF
            c = { r: (cp & 0xFF000000) >> 24, g: (cp & 0xFF0000) >> 16, b: (cp & 0xFF00) >> 8, a: cp & 0xFF }
            puts "big #{c}"
            c
          else
            c = { r: (cp & 0xFF0000) >> 16, g: (cp & 0xFF00) >> 8, b: cp & 0xFF, a: da }
            puts "little #{c}"
            c
          end
        else
          raise ArgumentError, "Color #{name} should be an Array or Hash"
        end
      else
        {
          r: params["#{name}_r".to_sym] || dr,
          g: params["#{name}_g".to_sym] || dg,
          b: params["#{name}_b".to_sym] || db,
          a: params["#{name}_a".to_sym] || da,
        }
      end
    end

    def parse_color_nilable(params, name)
      return parse_color(params, name) if params["#{name}_color".to_sym] || params["#{name}_r".to_sym] || params["#{name}_g".to_sym] || params["#{name}_b".to_sym] || params["#{name}_a".to_sym]

      nil
    end

    def draw_override(_ffi)
      return unless @will_focus

      @will_focus = false
      @focussed = true
      @ensure_cursor_visible = true
    end

    def draw_cursor(rt)
      return unless @focussed || @will_focus
      return if @readonly

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
      rt.primitives << {
        x: (@cursor_x - 1).greater(0) - @scroll_x,
        y: @cursor_y - @padding - @scroll_y,
        w: @cursor_width,
        h: @font_height + @padding * 2
      }.solid!(**@cursor_color, a: alpha)
    end

    def tick
      if @focussed
        prepare_special_keys
        handle_keyboard
      end
      handle_mouse
      prepare_render_target
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

    def value=(text)
      text = text[0, @max_length] if @max_length
      @value.replace(text)
      @selection_start = @selection_start.lesser(text.length)
      @selection_end = @selection_end.lesser(text.length)
    end

    def selection_start=(index)
      @selection_start = index.cap_min_max(0, @value.length)
    end

    def selection_end=(index)
      @selection_end = index.cap_min_max(0, @value.length)
    end

    def insert(str)
      @selection_end, @selection_start = @selection_start, @selection_end if @selection_start > @selection_end
      insert_at(str, @selection_start, @selection_end)

      @selection_start += str.length
      @selection_end = @selection_start
    end
    alias replace insert

    def insert_at(str, start_at, end_at = start_at)
      end_at, start_at = start_at, end_at if start_at > end_at
      if @max_length && @value.length - (end_at - start_at) + str.length > @max_length
        str = str[0, @max_length - @value.length + (end_at - start_at) - str.length]
        return if str.nil? # too long
      end

      @value.insert(start_at, end_at, str)
    end
    alias replace_at insert_at

    def append(str)
      insert_at(str, @value.length)
    end

    def find(text)
      index = @value.index(text)
      return unless index

      @selection_start = index
      @selection_end = index + text.length
    end

    def current_selection
      return nil if @selection_start == @selection_end

      if @selection_start < @selection_end
        @value[@selection_start, @selection_end - @selection_start]
      else
        @value[@selection_end, @selection_start - @selection_end]
      end
    end

    def current_word
      left = @word_chars.include?(@value[@selection_end - 1, 1]) ? find_word_break_left : @selection_end
      right = @word_chars.include?(@value[@selection_end, 1]) ? find_word_break_right : @selection_end
      @value[left, right - left]
    end

    def find_next
      text = current_selection
      return if text.nil?

      index = @value.index(text, @selection_end.greater(@selection_start)) || @value.index(text)

      @selection_start = index
      @selection_end = index + text.length
    end

    def find_prev
      text = current_selection
      return if text.nil?

      index = @value.rindex(text, (@selection_start - 1).lesser(@selection_end - 1)) ||
              @value.rindex(text, @value.length)

      @selection_start = index
      @selection_end = index + text.length
    end

    # TODO: Improve walking words
    def find_word_break_left # rubocop:disable Metrics/MethodLength
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

    def find_word_break_right(index = @selection_end) # rubocop:disable Metrics/MethodLength
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

      $clipboard = current_selection
    end

    def cut
      copy
      insert('')
    end

    def delete_back
      @selection_start -= 1 if @selection_start == @selection_end
      insert('')
    end

    def delete_forward
      @selection_start += 1 if @selection_start == @selection_end
      insert('')
    end

    def paste
      insert($clipboard)
    end

    def prepare_special_keys # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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

    def rect
      { x: @x, y: @y, w: @w, h: @h }
    end

    def content_rect
      { x: @scroll_x, y: @scroll_y, w: @content_w, h: @content_h }
    end

    def scroll_rect
      { x: @scroll_x, y: @scroll_y, w: @scroll_w, h: @scroll_h }
    end
  end
end
