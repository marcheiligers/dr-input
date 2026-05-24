require_relative 'test_helpers'

# Mock GTK::Console for testing
class MockConsole
  attr_accessor :visible, :log_offset
  attr_reader :autocompleting, :autocomplete_prefix, :autocomplete_selection_end

  def initialize
    @visible = true
    @log_offset = 0
    @command_history = []
    @command_history_index = -1
  end

  def mouse_wheel_scroll(args); end
  def console_toggle_key_down?(args); false; end
  def slide_progress; 1.0; end

  # Override autocomplete_items to return mock data
  def autocomplete_items(prefix)
    %w[inputs outputs state passes_remaining].select { |m| m.start_with?(prefix) }
  end
end

# Prepend after class definition so MockConsole methods still override
MockConsole.prepend(Input::Console)

def test_console_autocomplete_after_dot_tab(args, assert)
  console = MockConsole.new

  # Simulate typing "$args."
  console.prompt.value = "$args."
  console.prompt.selection_start = 6
  console.prompt.selection_end = 6

  # Simulate pressing TAB
  console.autocomplete

  # After tab, we should be autocompleting
  autocompleting = console.instance_variable_get(:@autocompleting)
  assert.true! autocompleting, "Should be autocompleting"

  # The menu should have items
  menu = console.instance_variable_get(:@autocomplete_menu)
  items = menu.items
  assert.false! items.empty?, "Menu should have items, got #{items.inspect}, menu=#{menu.inspect}"

  # The prompt value should be updated to show the first autocomplete option
  value = console.prompt.value.to_s
  assert.true! value.start_with?("$args."), "Value should start with '$args.': got #{value.inspect}"
  assert.true! value.length > 6, "Value should be longer than '$args.': got #{value.inspect}"
  assert.equal! value, "$args.inputs", "First autocomplete option should be 'inputs'"

  # The selection should highlight the autocompleted part
  sel_start = console.prompt.selection_start
  sel_end = console.prompt.selection_end
  assert.equal! sel_start, 6, "Selection start should be at position 6 (after dot)"
  assert.true! sel_end > 6, "Selection end should be after position 6"
  assert.equal! sel_end, value.length, "Selection end should be at end of value"

  # The autocomplete prefix should be empty (nothing typed after the dot yet)
  prefix = console.instance_variable_get(:@autocomplete_prefix)
  assert.equal! prefix, "", "Autocomplete prefix should be empty"

  # shift_lock should be enabled to maintain selection
  assert.true! console.prompt.shift_lock, "shift_lock should be enabled"

  # @value_changed should be false (reset after autocomplete_next)
  value_changed = console.prompt.instance_variable_get(:@value_changed)
  assert.false! value_changed, "@value_changed should be false after autocomplete"
end
