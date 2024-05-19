module Input
  def self.replace_console!
    GTK::Console.prepend(Input::Console)
  end

  class Prompt < Text
    def render(args, x:, y:)
      @x = x
      @y = y
      args.outputs.reserved << self
    end

    def str_len
      101 # to short circuit hint logic
    end

    def clear
      value = ''
    end

    def autocomplete
    end

    def tick
      super

      # prevent keys from reaching game
      $args.inputs.text.clear
      $args.inputs.keyboard.key_down.clear
      $args.inputs.keyboard.key_up.clear
      $args.inputs.keyboard.key_held.clear
    end
  end

  module Console
    def process_inputs args
      if console_toggle_key_down? args
        args.inputs.text.clear
        toggle
        args.inputs.keyboard.clear if !@visible
      end

      return unless visible?

      mouse_wheel_scroll args

      @log_offset = 0 if @log_offset < 0

      # elsif args.inputs.keyboard.key_down.v
      #   if args.inputs.keyboard.key_down.control || args.inputs.keyboard.key_down.meta
      #     prompt << $gtk.ffi_misc.getclipboard
      #   end
    end

    def on_unhandled_key(key, input)
      if $args.inputs.keyboard.key_down.enter
        if slide_progress > 0.5
          # in the event of an exception, the console window pops up
          # and is pre-filled with $gtk.reset.
          # there is an annoying scenario where the exception could be thrown
          # by pressing enter (while playing the game). if you press enter again
          # quickly, then the game is reset which closes the console.
          # so enter in the console is only evaluated if the slide_progress
          # is atleast half way down the page.
          eval_the_set_command
        end
      elsif $args.inputs.keyboard.key_down.up
        if @command_history_index == -1
          @nonhistory_input = current_input_str
        end
        if @command_history_index < (@command_history.length - 1)
          @command_history_index += 1
          self.current_input_str = @command_history[@command_history_index].dup
        end
      elsif $args.inputs.keyboard.key_down.down
        if @command_history_index == 0
          @command_history_index = -1
          self.current_input_str = @nonhistory_input
          @nonhistory_input = ''
        elsif @command_history_index > 0
          @command_history_index -= 1
          self.current_input_str = @command_history[@command_history_index].dup
        end
      elsif inputs_scroll_up_full? $args
        scroll_up_full
      elsif inputs_scroll_down_full? $args
        scroll_down_full
      elsif inputs_scroll_up_half? $args
        scroll_up_half
      elsif inputs_scroll_down_half? $args
        scroll_down_half
      elsif inputs_clear_command? $args
        prompt.clear
        @command_history_index = -1
        @nonhistory_input = ''
      elsif $args.inputs.keyboard.key_down.tab
        prompt.autocomplete
      end
    end

    def prompt
      @prompt ||= Input::Prompt.new(
        x: 0,
        y: 00,
        w: 1280,
        prompt: 'Press CTRL+g or ESCAPE to clear the prompt.',
        text_color: 0xFFFFFF,
        background_color: 0x000000,
        cursor_color: [219, 182, 104],
        on_unhandled_key: method(:on_unhandled_key),
        focussed: true
      )
    end

    def current_input_str
      prompt.value.to_s
    end

    def current_input_str=(str)
      prompt.value = str
    end
  end
end
