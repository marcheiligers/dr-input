module Input
  module Keyboard
    META_KEYS = %i[meta_left meta_right meta].freeze
    SHIFT_KEYS = %i[shift_left shift_right shift].freeze
    ALT_KEYS = %i[alt_left alt_right alt].freeze
    CTRL_KEYS = %i[control_left control_right control].freeze
    IGNORE_KEYS = (%i[raw_key char] + META_KEYS + SHIFT_KEYS + ALT_KEYS + CTRL_KEYS).freeze

    attr_accessor :shift_lock

    def initialize_keyboard(params)
      @shift_lock = false

      @key_repeat_delay = params[:key_repeat_delay] || 20
      @key_repeat_debounce = params[:key_repeat_debounce] || 4
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
      @shift = @shift_lock || (special_keys & SHIFT_KEYS).any?
      @ctrl = (special_keys & CTRL_KEYS).any?

      @text_keys = $args.inputs.text
    end
  end
end
