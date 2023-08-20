require 'lib/input.rb'

def tick(args)
  args.state.no_wrap ||= Input.new(x: 100, y: 600, w: 394, value: 'this is a non-wrapping input field')
  args.state.wrapping ||= Input.new(x: 600, y: 626, w: 394, value: 'this is a wrapping (multiline) input field', word_wrap: true)

  args.state.no_wrap.tick
  args.state.wrapping.tick
  args.state.wrapping.y = 626 - args.state.wrapping.h
  args.outputs.primitives << [
    { x: 100, y: 600, w: 394, h: args.state.no_wrap.h, r: 200, g: 200, b: 200 }.solid!,
    { x: 600, y: args.state.wrapping.y, w: 394, h: args.state.wrapping.h, r: 200, g: 200, b: 200 }.solid!,
    args.state.no_wrap,
    args.state.wrapping,
    # { x: 100, y: 600, w: 394, h: 2 }.solid!
  ]

  nval = args.state.no_wrap.value
  nval = nval.slice(0, args.state.no_wrap.selection_end) + '|' + nval.slice(args.state.no_wrap.selection_end, nval.length)
  wval = args.state.wrapping.value
  wval = wval.slice(0, args.state.wrapping.selection_end) + '|' + wval.slice(args.state.wrapping.selection_end, wval.length)
  args.outputs.primitives << { x: 100, y: 120, text: "Simple Value: #{nval}", r: 255 }.label!
  args.outputs.primitives << { x: 100, y: 100, text: "Wrapping Value: #{wval.gsub("\n", '\n')}", r: 255 }.label!
  args.outputs.primitives << { x: 100, y: 80, text: "Clipboard: #{$clipboard}", r: 255 }.label!
end
