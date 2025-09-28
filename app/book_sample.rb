require 'lib/input.rb'
require 'app/scroller.rb'
require 'app/sizer.rb'
require 'app/button.rb'
require 'tests/alice_in_wonderland.rb'

# FONT = ''
# FONT = 'fonts/Victorian Parlor_By Burntilldead_Free/Victorian Parlor Vintage Alternate_free.ttf'
FONT = 'fonts/day-roman/DAYROM__.ttf'.freeze
DEBUG_LABEL = { x: 20, r: 80, size_enum: -2, primitive_marker: :label }.freeze

def prep_doc
  ALICE_IN_WONDERLAND
    .gsub("\n\n", "__DOUBLEN__").gsub("\n", ' ').gsub("__DOUBLEN__", "\n\n")
    .gsub(' CHAPTER', "\n CHAPTER")
    .gsub('’', "'")
    .gsub('“', '"')
    .gsub('”', '"')
end

def tick(args)
  if args.tick_count == 0
    Input.replace_console!

    args.state.text ||= Input::Text.new(
      x: 20,
      y: 660,
      w: 1200,
      padding: 10,
      prompt: 'Title',
      value: nil,
      font: FONT,
      # size_enum: :xxxlarge,
      size_px: 39,
      text_color: { r: 20, g: 20, b: 90 },
      selection_color: { r: 122, g: 90, b: 90 },
      cursor_color: 0x333333,
      cursor_width: 3,
      background_color: [220, 220, 220],
      blurred_background_color: [192, 192, 192],
      on_unhandled_key: lambda do |key, input|
        if key == :tab
          input.blur
          args.state.multiline.focus
        end
      end,
      on_click: lambda do |_mouse, input|
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
      value: nil,
      font: FONT,
      # size_enum: :xxlarge,
      size_px: 16,
      selection_start: 0,
      background_color: [220, 220, 220],
      blurred_background_color: [192, 192, 192],
      cursor_color: 0x6a5acd,
      on_unhandled_key: lambda do |key, input|
        if key == :tab
          input.blur
          args.state.text.focus
        end
      end,
      on_click: lambda do |_mouse, input|
        input.focus
        args.state.text.blur
      end
    )
    args.state.text.focus

    args.state.scroller = Scroller.new(args.state.multiline)
    args.state.sizer = Sizer.new(args.state.multiline)
    args.state.dec_font_button = Button.new(1100, 635, 45, 20, '-Font', ->{ $args.state.multiline.size_px -= 1 })
    args.state.inc_font_button = Button.new(1170, 635, 45, 20, '+Font', ->{ $args.state.multiline.size_px += 1 })
    args.state.load_button = Button.new(1230, 665, 45, 60, 'A', ->{
      $args.state.text.value = "Alice's Adventures in Wonderland"
      $args.state.multiline.value = prep_doc
    })
  end

  args.state.text.tick
  args.state.sizer.tick
  args.state.multiline.tick
  args.state.scroller.tick
  args.state.inc_font_button.tick
  args.state.dec_font_button.tick
  args.state.load_button.tick
  args.outputs.primitives << [
    { r: 192, g: 192, b: 192 }.solid!(args.state.text.rect),
    { r: 192, g: 192, b: 192 }.solid!(args.state.multiline.rect),
    args.state.text,
    args.state.multiline,
    args.state.scroller,
    args.state.sizer,
    args.state.inc_font_button,
    args.state.dec_font_button,
    args.state.load_button
  ]

  nval = args.state.text.value
  nval = "#{nval[0, args.state.text.selection_end]}|#{nval[args.state.text.selection_end, nval.length]}"
  wval = args.state.multiline.value
  wval = "#{wval[0, args.state.multiline.selection_end]}|#{wval[args.state.multiline.selection_end, wval.length]}"
  args.outputs.primitives << { y: 700, text: "#{args.state.text.value.length}/40", **DEBUG_LABEL, x: 1180 }
  args.outputs.primitives << { y: 655, text: args.state.multiline.size_px.to_s, **DEBUG_LABEL, x: 1150 }
  args.outputs.primitives << { y: 140, text: "Simple Value: #{nval}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 110, text: "Wrapping Value (#{wval.length}): #{wval.gsub("\n", '\n')}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 90, text: "Current word: #{args.state.multiline.current_word}", **DEBUG_LABEL }
  args.outputs.primitives << { y: 70, text: "Current line: #{args.state.multiline.current_line.inspect}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 20, text: "Content rect: #{args.state.multiline.content_rect}, Scroll rect: #{args.state.multiline.scroll_rect}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 20, text: args.gtk.current_framerate,  **DEBUG_LABEL, x: 1240 }
end
