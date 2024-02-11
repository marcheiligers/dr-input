require 'lib/input.rb'
require 'app/scroller.rb'

FONT = ''.freeze
DEBUG_LABEL = { x: 20, r: 80, size_enum: -2, primitive_marker: :label }.freeze

class Button
  attr_sprite
  attr_reader :on_clicked

  def initialize(x, y, w, h, text, on_clicked)
    @mouse_over = false
    @x = x
    @y = y
    @w = w
    @h = h
    @text = text
    @on_clicked = on_clicked
  end

  def tick
    handle_mouse
  end

  def handle_mouse
    mouse = $args.inputs.mouse
    @mouse_over = mouse.inside_rect?(self)
    return unless @mouse_over

    @on_clicked.call if mouse.up
  end

  def draw_override(ffi)
    if @mouse_over
      ffi.draw_solid(@x, @y, @w, @h, 200, 200, 240, 255)
    else
      ffi.draw_solid(@x, @y, @w, @h, 220, 220, 220, 255)
    end
    # ffi.draw_label_5 x, y, text, size_enum, alignment_enum, r, g, b, a, font, vertical_alignment_enum, blendmode_enum, size_px, angle_anchor_x, angle_anchor_y
    ffi.draw_label_5 @x + @w / 2, @y + @h / 2, @text, nil, 1, 0, 0, 0, 255, FONT, 1, 1, @h - 10, 0.5, 0.5
  end
end

ROOMS = [
  'room',
  'hall',
  'chamber',
  'passage'
]
WALLS = [
  'wooden',
  'stone',
  'brick'
]
DECOR = [
  'paintings',
  'skulls',
  'clocks'
]

def add_text(text)
  ml = $args.state.multiline
  nl = ml.value.length != 0 ? "\n" : ''
  ml.append("#{nl}[#{ml.lines.length.to_s.rjust(5, '0')}] #{text} and enter a #{ROOMS.sample} with #{WALLS.sample} walls covered in #{DECOR.sample}.")
  ml.scroll_y = 0
end

def tick(args)
  if args.tick_count == 0
    args.state.multiline ||= Input::Multiline.new(
      x: 20,
      y: 100,
      w: 1200,
      h: 580,
      prompt: 'Click the buttons below',
      font: FONT,
      size_enum: :xlarge,
      background_color: [220, 220, 220],
      blurred_background_color: [192, 192, 192],
      on_clicked: lambda do |_mouse, input|
        input.focus
      end,
      readonly: true,
      fill_from_bottom: true
    )
    args.state.text.focus

    args.state.scroller = Scroller.new(args.state.multiline)
    args.state.buttons = [
      Button.new(20, 20, 200, 40, 'West', ->{ add_text('You go to the West') }),
      Button.new(240, 20, 200, 40, 'North', ->{ add_text('You go to the North') }),
      Button.new(460, 20, 200, 40, 'South', ->{ add_text('You go to the South') }),
      Button.new(680, 20, 200, 40, 'East', ->{ add_text('You go to the East') }),
      Button.new(900, 20, 40, 40, '^', ->{ 40.times { args.state.buttons.first(4).sample.on_clicked.call } }),
      Button.new(1060, 20, 200, 40, 'Clear', ->{ args.state.multiline.value = '' }),
    ]
  end

  args.state.multiline.tick
  args.state.buttons.each(&:tick)
  args.state.scroller.tick
  args.outputs.primitives << [
    { r: 192, g: 192, b: 192 }.solid!(args.state.multiline.rect),
    args.state.multiline,
    args.state.scroller,
    args.state.buttons
  ]
end
