module Input
  class Manager
    def initialize
      @controls = []
      @focus_index = 0
    end

    def attach(control, keyboard_handler)
      @controls << [control, keyboard_handler]
    end

    def tick
      @controls.each do |control, keyboard_handler|
        if control.focussed?
          keyboard_handler.handle(control, prepare_keyboard)
        end
        control.tick
      end
    end

    # BUG: Modifier keys are broken on the web ()
    META_KEYS = %i[meta_left meta_right meta].freeze
    SHIFT_KEYS = %i[shift_left shift_right shift].freeze
    ALT_KEYS = %i[alt_left alt_right alt].freeze
    CTRL_KEYS = %i[control_left control_right control].freeze
    DEL_KEYS = %i[delete backspace].freeze
    IGNORE_KEYS = (%i[raw_key char] + META_KEYS + SHIFT_KEYS + ALT_KEYS + CTRL_KEYS).freeze

    def prepare_keyboard
      keyboard = $args.inputs.keyboard

      tick_count = $args.tick_count
      repeat_keys = keyboard.key_held.truthy_keys.select do |key|
        ticks = tick_count - keyboard.key_held.send(key).to_i
        ticks > @key_repeat_delay && ticks % @key_repeat_debounce == 0
      end

      # Find special keys
      special_keys = keyboard.key_down.truthy_keys + keyboard.key_held.truthy_keys

      {
        keys: keyboard.key_down.truthy_keys.concat(repeat_keys) - IGNORE_KEYS,
        meta: (special_keys & META_KEYS).any?,
        alt: (special_keys & ALT_KEYS).any?,
        shift: (special_keys & SHIFT_KEYS).any?,
        ctrl: (special_keys & CTRL_KEYS).any?,
        string: $args.inputs.text
      }
    end
  end

  class TextKeyboardHandler
    def initialize(text)
      @text = text
    end

    def handle(control, keyboard)
      if keyboard.meta || keyboard.ctrl
        handle_control_keys(control, keyboard)
      elsif keyboard.string.empty?
        handle_movement_keys(control, keyboard)
      else
        control.insert(keyboard.string.join(''))
      end
    end

    def handle_control_keys(control, keyboard)
      # TODO: undo/redo
      keys = keyboard.keys
      if keys.include?(:a)
        control.select_all
      elsif keys.include?(:c)
        control.copy
      elsif keys.include?(:x)
        control.cut
      elsif keys.include?(:v)
        control.paste
      elsif keys.include?(:left)
        keyboard.shift ? control.select_to_start : control.move_to_start
      elsif keys.include?(:right)
        keyboard.shift ? control.select_to_end : control.move_to_end
      elsif keys.include?(:g)
        keyboard.shift ? control.find_prev : control.find_next
      else
        @on_unhandled_key.call(keys.first, self)
      end
    end

    def handle_movement_keys
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
    end
  end
end
