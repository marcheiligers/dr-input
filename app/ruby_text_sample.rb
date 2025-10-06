require 'lib/input.rb'

def tick(args)
  if args.tick_count == 0
    Input.replace_console!

    args.state.ruby_code ||= 'class Foo; def bar!(x); $gtk.args.outputs.labels << "hello #{x}"; end; end'

    args.state.ruby_input = Input::RubyText.new(
      x: 40,
      y: 600,
      w: 1200,
      h: 60,
      padding: 10,
      prompt: 'Enter Ruby code...',
      value: args.state.ruby_code,
      size_px: 20,
      selection_color: { r: 80, g: 80, b: 100 },
      cursor_color: 0xAAAAAA,
      cursor_width: 2,
      background_color: [40, 44, 52],
      blurred_background_color: [50, 54, 62]
    )
    args.state.ruby_input.focus
  end

  # Set background color (dark theme)
  args.outputs.background_color = [30, 34, 42]

  # Title
  args.outputs.labels << {
    x: 640,
    y: 680,
    text: 'Ruby Syntax Highlighter Input Demo',
    size_px: 30,
    alignment_enum: 1,
    r: 200, g: 200, b: 200
  }

  # Instructions
  args.outputs.labels << {
    x: 640,
    y: 640,
    text: 'Type or edit Ruby code to see syntax highlighting in real-time',
    size_px: 16,
    alignment_enum: 1,
    r: 150, g: 150, b: 150
  }

  args.state.ruby_input.tick
  args.outputs.primitives << args.state.ruby_input

  # Info text
  args.outputs.labels << {
    x: 40,
    y: 560,
    text: "Input supports: keywords, strings, symbols, numbers, constants, comments, interpolation, and more!",
    size_px: 14,
    r: 150, g: 150, b: 150
  }

  # Example code suggestions
  args.outputs.labels << {
    x: 40,
    y: 520,
    text: 'Try typing: def foo(bar) @baz = "hello #{bar}" end',
    size_px: 12,
    r: 120, g: 120, b: 120
  }

  # Footer
  args.outputs.labels << {
    x: 640,
    y: 40,
    text: "Press ESC to quit | FPS: #{args.gtk.current_framerate.to_i}",
    size_px: 16,
    alignment_enum: 1,
    r: 150, g: 150, b: 150
  }
end
