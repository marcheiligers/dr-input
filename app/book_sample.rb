require 'lib/input.rb'
require 'app/scroller.rb'
require 'tests/alice_in_wonderland.rb'

FONT = ''
# FONT = 'fonts/Victorian Parlor_By Burntilldead_Free/Victorian Parlor Vintage Alternate_free.ttf'
# FONT = 'fonts/day-roman/DAYROM__.ttf'.freeze
DEBUG_LABEL = { x: 20, r: 80, size_enum: -2, primitive_marker: :label }.freeze

def tick(args)
  if args.tick_count == 0
    Input.replace_console!

    args.state.text ||= Input::Text.new(
      x: 20,
      y: 660,
      w: 1240,
      prompt: 'Title',
      value: "Alice's Adventures in Wonderland 🐰",
      font: FONT,
      size_enum: :xxxlarge,
      text_color: { r: 20, g: 20, b: 90 },
      selection_color: { r: 122, g: 90, b: 90 },
      cursor_color: 0xFF2020,
      cursor_width: 3,
      background_color: [220, 220, 220],
      blurred_background_color: [192, 192, 192],
      on_unhandled_key: lambda do |key, input|
        if key == :tab
          input.blur
          args.state.multiline.focus
        end
      end,
      on_clicked: lambda do |_mouse, input|
        input.focus
        args.state.multiline.blur
      end,
      max_length: 40
    )
    args.state.multiline ||= Input::Multiline.new(
      x: 20,
      y: 220,
      w: 1200,
      h: 420,
      prompt: 'Content',
      value: ALICE_IN_WONDERLAND.gsub("\n\n", "__DOUBLEN__").delete("\n").gsub("__DOUBLEN__", "\n\n"),
      font: FONT,
      size_enum: :xxlarge,
      selection_start: 0,
      background_color: [220, 220, 220],
      blurred_background_color: [192, 192, 192],
      on_unhandled_key: lambda do |key, input|
        if key == :tab
          input.blur
          args.state.text.focus
        end
      end,
      on_clicked: lambda do |_mouse, input|
        input.focus
        args.state.text.blur
      end
    )
    args.state.text.focus

    args.state.scroller = Scroller.new(args.state.multiline)
  end

  args.state.text.tick
  args.state.multiline.tick
  args.state.scroller.tick
  args.outputs.primitives << [
    { r: 192, g: 192, b: 192 }.solid!(args.state.text.rect),
    { r: 192, g: 192, b: 192 }.solid!(args.state.multiline.rect),
    args.state.text,
    args.state.multiline,
    args.state.scroller
    # { x: 100, y: 600, w: 394, h: 2 }.solid!
  ]

  nval = args.state.text.value
  nval = "#{nval[0, args.state.text.selection_end]}|#{nval[args.state.text.selection_end, nval.length]}"
  wval = args.state.multiline.value
  wval = "#{wval[0, args.state.multiline.selection_end]}|#{wval[args.state.multiline.selection_end, wval.length]}"
  args.outputs.primitives << { y: 658, text: "#{args.state.text.value.length}/40", **DEBUG_LABEL, x: 1220 }
  args.outputs.primitives << { y: 140, text: "Simple Value: #{nval}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 110, text: "Wrapping Value (#{wval.length}): #{wval.gsub("\n", '\n')}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 90, text: "Current word: #{args.state.multiline.current_word}", **DEBUG_LABEL }
  args.outputs.primitives << { y: 70, text: "Current line: #{args.state.multiline.current_line.inspect}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 40, text: "Clipboard: #{$clipboard}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 20, text: "Content rect: #{args.state.multiline.content_rect}, Scroll rect: #{args.state.multiline.scroll_rect}" }.label!(DEBUG_LABEL)
end
