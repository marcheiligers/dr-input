require 'lib/input.rb'

def tick(args)
  Input.replace_console!

  # Create an input
  args.state.input ||= Input::Menu.new(
    x: 100,
    y: 600,
    focussed: true,
    background_color: 0xEEEFEF,
    items: %w[item1 item2 item3 longitem item5]
  )

  # Allow the input to process inputs and render text (render_target)
  args.state.input.tick

  # Get the value
  args.state.input_value = args.state.input.value

  # Output the input
  args.outputs.primitives << args.state.input

  # Output the value
  args.outputs.debug << { x: 100, y: 100, text: args.state.input_value }.label!
end
