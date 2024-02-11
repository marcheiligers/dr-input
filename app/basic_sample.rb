require 'lib/input.rb'

def tick(args)
  # Create an input
  args.state.input ||= Input::Text.new(x: 100, y: 600, w: 300, focussed: true)

  # Allow the input to process inputs and render text (render_target)
  args.state.input.tick

  # Get the value
  args.state.input_value = args.state.input.value

  # Output the input
  args.outputs.primitives << args.state.input

  # Output the value
  args.outputs.debug << { x: 100, y: 100, text: args.state.input_value }.label!
end
