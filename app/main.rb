require 'lib/input.rb'

def tick(args)
  args.state.text_box ||= Input.new(x: 100, y: 600, w: 394, value: 'this is an input field')

  args.state.text_box.tick
  args.outputs.primitives << [
    # { x: 100, y: 600, w: 394, h: args.state.text_box.h, r: 200, g: 200, b: 200 }.solid!,
    args.state.text_box,
    { x: 100, y: 600, w: 394, h: 2 }.solid!
  ]

  args.outputs.primitives << { x: 100, y: 100, text: "Value: #{args.state.text_box.value}", r: 255 }.label!
  args.outputs.primitives << { x: 100, y: 80, text: "Clipboard: #{args.state.text_box.clipboard}", r: 255 }.label!
end
