require 'lib/input.rb'
require 'app/button.rb'

ADD_ITEM = lambda do
  if $args.state.text.value.length > 0
    val = $args.state.text.value.to_s
    $args.state.menu.items = $args.state.menu.items + [{ text: val, value: val }]
    $args.state.text.value = ''
  end
end

def tick(args)
  Input.replace_console!

  # Create a menu
  args.state.menu ||= Input::Menu.new(
    x: 100,
    y: 600,
    focussed: true,
    background_color: 0xEEEFEF,
    items: %w[item1 item2 item3 longitem item5],
    on_unhandled_key: lambda do |key, input|
      case key
      when :tab
        input.blur
        args.state.text.focus
      end
    end
  )
  args.state.text ||= Input::Text.new(
    x: 20,
    y: 40,
    w: 400,
    prompt: 'New menu item',
    value: '',
    size_px: 20,
    text_color: { r: 0, g: 0, b: 0 },
    selection_color: { r: 122, g: 90, b: 90 },
    cursor_color: 0x202040,
    cursor_width: 2,
    background_color: [220, 220, 220],
    blurred_background_color: [192, 192, 192],
    on_unhandled_key: lambda do |key, input|
      case key
      when :tab
        input.blur
        args.state.menu.focus
      when :enter
        ADD_ITEM.call
      end
    end,
    on_clicked: lambda do |_mouse, input|
      input.focus
      args.state.menu.blur
    end,
    max_length: 40
  )
  args.state.add_button ||= Button.new(430, 40, 45, 25, 'Add', ADD_ITEM)
  args.state.add_20_button ||= Button.new(485, 40, 55, 25, 'Add 20', lambda {
    if args.state.text.value.length > 0
      val = args.state.text.value.to_s
      args.state.menu.items = args.state.menu.items + Array.new(20) { |i| { text: "#{val} #{i}", value: "#{val} #{i}" } }
      args.state.text.value = ''
    end
  })

  # Move the menu around if clicks are on the background
  if args.inputs.mouse.up &&
    !args.inputs.mouse.inside_rect?(args.state.menu.content_rect) &&
    !args.inputs.mouse.inside_rect?(args.state.text) &&
    !args.inputs.mouse.inside_rect?(args.state.add_button) &&
    !args.inputs.mouse.inside_rect?(args.state.add_20_button)
    args.state.menu.x = args.inputs.mouse.x
    args.state.menu.y = args.inputs.mouse.y
    args.state.menu.focus
    args.state.text.blur
  end

  # Allow the inputs to process inputs and render (render_target)
  args.state.menu.tick
  args.state.text.tick
  args.state.add_button.tick
  args.state.add_20_button.tick

  # Get the value
  args.state.input_value = args.state.menu.value

  # Output the input
  args.outputs.primitives << args.state.menu
  args.outputs.primitives << args.state.text
  args.outputs.primitives << args.state.add_button
  args.outputs.primitives << args.state.add_20_button

  # Output the value
  args.outputs.debug << { x: 20, y: 100, text: "Current: #{args.state.input_value}" }.label!

  args.gtk.show_console if args.tick_count == 0
end
