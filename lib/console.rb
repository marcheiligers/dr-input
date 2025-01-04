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
      self.value = ''
    end

    def tick
      super

      # prevent keys from reaching game
      $args.inputs.text.clear
      $args.inputs.keyboard.key_down.clear
      $args.inputs.keyboard.key_up.clear
      $args.inputs.keyboard.key_held.clear
    end

    def delete_back
      @selection_start -= 1 if @selection_start == @selection_end
      @selection_end -= 1 if @shift_lock # override so delete behaves in a way that makes sense
      insert('')
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

      if @autocompleting
        # is the cursor before the period?
        if @autocomplete_period_index && @autocomplete_period_index >= @prompt.selection_end
          autocomplete_clear
        elsif @prompt.value_changed? || @prompt.selection_end != @autocomplete_selection_end
          autocomplete_prefix
          autocomplete_next(0)
        end

        @autocomplete_selection_end = @prompt.selection_end
      end
    end

    def on_unhandled_key(key, input)
      if @autocompleting && key == :escape
        autocomplete_clear
      elsif $args.inputs.keyboard.key_down.enter
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
        if @autocompleting
          autocomplete_next(+1)
        else
          if @command_history_index == -1
            @nonhistory_input = current_input_str
          end
          if @command_history_index < (@command_history.length - 1)
            @command_history_index += 1
            self.current_input_str = @command_history[@command_history_index].dup
          end
        end
      elsif $args.inputs.keyboard.key_down.down
        if @autocompleting
          autocomplete_next(-1)
        else
          if @command_history_index == 0
            @command_history_index = -1
            self.current_input_str = @nonhistory_input
            @nonhistory_input = ''
          elsif @command_history_index > 0
            @command_history_index -= 1
            self.current_input_str = @command_history[@command_history_index].dup
          end
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
        if @autocompleting
          autocomplete_accept
        else
          autocomplete
        end
      end
    end

    def prompt
      @prompt ||= Input::Prompt.new(
        x: 0,
        y: 0,
        w: 1280,
        prompt: 'Press CTRL+g or ESCAPE to clear the prompt. Press TAB for autocomplete.',
        text_color: 0xFFFFFF,
        background_color: 0x000000,
        cursor_color: [219, 182, 104],
        on_unhandled_key: method(:on_unhandled_key),
        focussed: true,
        draw_autocomplete_menu: false
      )
    end

    # the following methods are modified copies from console_prompt.rb
    # https://github.com/marcheiligers/dragonruby-game-toolkit-contrib/blob/master/dragon/console_prompt.rb
    def autocomplete
      @autocompleting = true
      @prompt.shift_lock = true

      @autocomplete_menu ||= Menu.new(
        focussed: false,
        text_color: 0xDDDDDD,
        background_color: 0x333333DD
      )

      autocomplete_prefix
      autocomplete_next(0)
    rescue Exception => e
      puts "* BUG: Tab autocompletion failed. Let us know about this.\n#{e}"
      puts e.backtrace
    end

    def autocomplete_prefix
      val = @prompt.value.to_s
      @autocomplete_period_index = lpi = val.rindex('.')
      prefix = lpi ? val[lpi + 1, @prompt.selection_end - lpi - 1] || '' : val
      if !@autocomplete_prefix || @autocomplete_prefix != prefix
        @autocomplete_prefix = prefix

        items = autocomplete_items(@autocomplete_prefix)
        if items.length.zero?
          autocomplete_clear
        else
          @autocomplete_menu.items = items
        end
      end
    end

    def autocomplete_next(dir)
      return unless @autocompleting

      @autocomplete_menu.selected_index -= dir
      @prompt.value = display_autocomplete_candidate(@autocomplete_menu.value)
      @prompt.selection_start = @prompt.value.length
    rescue => e
      puts "Error in #autocomplete_next(#{dir}): <#{e.class.name}> #{e.message}"
    end

    def autocomplete_object
      return GTK::ConsoleEvaluator unless @autocomplete_period_index

      GTK::ConsoleEvaluator.eval(@prompt.value[0, @autocomplete_period_index])
    rescue => e # probably a RuntimeError
      puts "Error in #autocomplete_object: <#{e.class.name}> #{e.inspect}"
      nil
    end

    def autocomplete_items(prefix)
      autocomplete_object.autocomplete_methods.map(&:to_s).select { |m| m.start_with? prefix }
    end

    def display_autocomplete_candidate(candidate)
      candidate = candidate[0..-2] + " = " if candidate.end_with? '='
      if @autocomplete_period_index
        @prompt.value[0, @autocomplete_period_index + 1] + candidate.to_s
      else
        candidate.to_s
      end
    end

    def autocomplete_accept
      @prompt.selection_end = @prompt.selection_start
      autocomplete_clear
    end

    def autocomplete_clear
      @autocompleting = false
      @autocomplete_prefix = nil
      @prompt.shift_lock = false
    end

    def render args
      super

      # Add the autocomplete menu last so it renders on top
      if @autocompleting
        @autocomplete_menu.prepare_render_target
        @autocomplete_menu.x = @prompt.cursor_x
        @autocomplete_menu.y = @prompt.cursor_y + @prompt.font_height
        args.outputs.reserved << @autocomplete_menu
      end
    end


    def current_input_str
      prompt.value.to_s
    end

    def current_input_str=(str)
      prompt.value = str
      prompt.move_to_end
    end
  end
end

# TODO: Enable auto complete on `.` at the end (as well as TAB)
# TODO: Filter while typing
# TODO: Filter when moving
