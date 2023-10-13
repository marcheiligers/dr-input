require 'lib/input.rb'

# FONT = ''
# FONT = 'fonts/Victorian Parlor_By Burntilldead_Free/Victorian Parlor Vintage Alternate_free.ttf'
FONT = 'fonts/day-roman/DAYROM__.ttf'.freeze
DEBUG_LABEL = { x: 20, r: 80, size_enum: -2 }.freeze

class Scroller
  attr_sprite

  def initialize(multiline)
    @multiline = multiline
    @mouse_down = false
    @x = @multiline.x + @multiline.w + 20
    @y = @multiline.y
    @w = 20
    @h = @multiline.h
  end

  def tick
    handle_mouse
  end

  def handle_mouse
    return if @multiline.content_h < @multiline.h

    mouse = $args.inputs.mouse
    th = thumb_rect

    if !@mouse_down && mouse.down && mouse.inside_rect?(self)
      @mouse_down = true
      @mouse_y = mouse.y
      if mouse.inside_rect?(th)
        # do nothing, we'll drag the rect
      else
        # jump the thumb to where we clicked
      end
    elsif @mouse_down
      @mouse_down = false if mouse.up
      # scroll inut
    end
  end

  def thumb_rect
    if @multiline.content_h < @h
      { x: @x, y: @y, w: @w, h: @h }
    else
      { x: @x, y: (@multiline.content_y / @multiline.scroll_h) * @h + @y, w: @w, h: (@h / @multiline.scroll_h) * @h }
    end
  end

  def draw_override(ffi)
    ffi.draw_solid(@x, @y, @w, @h, 220, 220, 220, 255)
    ffi.draw_solid(*thumb_rect.values, 192, 192, 192, 255)
  end
end

def tick(args)
  if args.tick_count == 0
    args.state.text ||= Input::Text.new(
      x: 20,
      y: 660,
      w: 1240,
      value: 'this is a text input field',
      font: FONT,
      size_enum: :xxxlarge,
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
      end
    )
    args.state.multiline ||= Input::Multiline.new(
      x: 20,
      y: 220,
      w: 1200,
      h: 400,
      value: 'this is a multiline input field',
      font: FONT,
      size_enum: :xxxlarge,
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
  args.outputs.primitives << { y: 140, text: "Simple Value: #{nval}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 110, text: "Wrapping Value: #{wval.gsub("\n", '\n')}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 90, text: "Selection: #{args.state.multiline.selection_start}, #{args.state.multiline.selection_end}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 70, text: "Current line: #{args.state.multiline.current_line.inspect}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 40, text: "Clipboard: #{$clipboard}" }.label!(DEBUG_LABEL)
  args.outputs.primitives << { y: 20, text: "Content rect: #{args.state.multiline.content_rect}, Scroll rect: #{args.state.multiline.scroll_rect}" }.label!(DEBUG_LABEL)
end
