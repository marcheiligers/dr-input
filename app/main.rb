require 'lib/input.rb'

# FONT = ''
# FONT = 'fonts/Victorian Parlor_By Burntilldead_Free/Victorian Parlor Vintage Alternate_free.ttf'
FONT = 'fonts/day-roman/DAYROM__.ttf'.freeze
DEBUG_LABEL = { x: 20, r: 80, size_enum: -2 }.freeze

def tick(args)
  if args.tick_count == 0
    args.state.no_wrap ||= Input::Text.new(
      x: 20,
      y: 660,
      w: 1240,
      value: 'this is a non-wrapping input field',
      font: FONT,
      size_enum: :xxxlarge,
      background_color: [200, 200, 200],
      on_unhandled_key: lambda do |key, input|
        if key == :tab
          input.blur!
          args.state.wrapping.focus!
        end
      end,
      on_clicked: lambda do |_mouse, input|
        input.focus!
        args.state.wrapping.blur!
      end
    )
    args.state.wrapping ||= Input::Multiline.new(
      x: 20,
      y: 620,
      w: 1240,
      value: 'this is a wrapping (multiline) input field',
      font: FONT,
      size_enum: :xxxlarge,
      background_color: [200, 200, 200],
      on_unhandled_key: lambda do |key, input|
        if key == :tab
          input.blur!
          args.state.no_wrap.focus!
        end
      end,
      on_clicked: lambda do |_mouse, input|
        input.focus!
        args.state.no_wrap.blur!
      end
    )
    args.state.no_wrap.focus!
  end

  args.state.no_wrap.tick
  args.state.wrapping.tick
  args.state.wrapping.y = 620 - args.state.wrapping.h
  args.outputs.primitives << [
    { x: 20, y: 660, w: 1240, h: args.state.no_wrap.h, r: 200, g: 200, b: 200 }.solid!,
    { x: 20, y: args.state.wrapping.y, w: 1240, h: args.state.wrapping.h, r: 200, g: 200, b: 200 }.solid!,
    args.state.no_wrap,
    args.state.wrapping,
    # { x: 100, y: 600, w: 394, h: 2 }.solid!
  ]

  nval = args.state.no_wrap.value
  nval = "#{nval[0, args.state.no_wrap.selection_end]}|#{nval[args.state.no_wrap.selection_end, nval.length]}"
  wval = args.state.wrapping.value
  wval = "#{wval[0, args.state.wrapping.selection_end]}|#{wval[args.state.wrapping.selection_end, wval.length]}"
  args.outputs.primitives << { y: 130, text: "Simple Value: #{nval}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 100, text: "Wrapping Value: #{wval.gsub("\n", '\n')}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 80, text: "Selection: #{args.state.wrapping.selection_start}, #{args.state.wrapping.selection_end}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 60, text: "Current line: #{args.state.wrapping.current_line.inspect}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 30, text: "Clipboard: #{$clipboard}" }.label!(DEBUG_LABEL)
end
