require_relative 'test_helpers'

def test_default_height_is_calculated_from_padding_and_font_height(_args, assert)
  _, font_height = $gtk.calcstringbox('A', 0)
  text_input = Input::Text.new(padding: 10, size_enum: 0)

  assert.equal! text_input.h, font_height + 20
end

def test_multiline_scrolls_in_font_height_steps_by_default(args, assert)
  $args = args
  _, font_height = $gtk.calcstringbox('A', 0)
  input = Input::Multiline.new(x: 100, y: 100, w: 100, size_enum: 0)
  input.insert "line 1\n"
  input.insert "line 2\n"
  input.insert "line 3\n"

  assert.equal! input.scroll_y, 0

  mouse_is_inside(input)
  args.inputs.mouse.wheel = { y: 1 }
  input.tick

  assert.equal! input.scroll_y, font_height
end

def test_text_click_inside_sets_selection(args, assert)
  $args = args
  three_letters_wide, _ = $gtk.calcstringbox('ABC', 0)
  input = Input::Text.new(x: 100, y: 100, w: 100, size_enum: 0, value: 'ABCDEF', focussed: true)

  mouse_is_inside(input, x: 100 + three_letters_wide)
  mouse_down
  input.tick

  mouse_up
  input.tick

  assert.equal! input.selection_start, 3
  assert.equal! input.selection_end, 3
end

def test_text_drag_inside_sets_selection(args, assert)
  $args = args
  three_letters_wide, _ = $gtk.calcstringbox('ABC', 0)
  six_letters_wide, _ = $gtk.calcstringbox('ABCDEF', 0)
  input = Input::Text.new(x: 100, y: 100, w: 100, size_enum: 0, value: 'ABCDEFGH', focussed: true)

  mouse_is_inside(input, x: 100 + three_letters_wide)
  mouse_down
  input.tick
  mouse_is_inside(input, x: 100 + six_letters_wide)
  mouse_up
  input.tick

  assert.equal! input.selection_start, 3
  assert.equal! input.selection_end, 6
end

def test_multiline_click_inside_sets_selection(args, assert)
  $args = args
  three_letters_wide, font_height = $gtk.calcstringbox('ABC', 0)
  input = Input::Multiline.new(x: 100, y: 100, w: 100, h: font_height * 2, size_enum: 0, value: "ABCDEF\nGHIJKL", focussed: true)
  inside_second_line_y = input.y + font_height.half

  mouse_is_at(100 + three_letters_wide, inside_second_line_y)
  mouse_down
  input.tick
  mouse_up
  input.tick


  # 10 = ABCDEF\nGHI
  assert.equal! input.selection_start, 10
  assert.equal! input.selection_end, 10
end

def test_text_drag_inside_sets_selection(args, assert)
  $args = args
  three_letters_wide, font_height = $gtk.calcstringbox('ABC', 0)
  input = Input::Multiline.new(x: 100, y: 100, w: 100, h: font_height * 2, size_enum: 0, value: "ABCDEF\nGHIJKL", focussed: true)
  inside_second_line_y = input.y + font_height.half
  inside_first_line_y = inside_second_line_y + font_height

  mouse_is_at(100 + three_letters_wide, inside_first_line_y)
  mouse_down
  input.tick

  mouse_is_at(100 + three_letters_wide, inside_second_line_y)
  mouse_up
  input.tick

  assert.equal! input.selection_start, 3
  assert.equal! input.selection_end, 10
end

# Two representative test cases using size_px instead of size_enum

def test_default_height_is_calculated_from_padding_and_font_height_size_px(_args, assert)
  _, font_height = $gtk.calcstringbox('A', size_px: 30)
  text_input = Input::Text.new(padding: 10, size_px: 30)

  assert.equal! text_input.h, font_height + 20
end

def test_text_drag_inside_sets_selection_size_px(args, assert)
  $args = args
  three_letters_wide, _ = $gtk.calcstringbox('ABC', size_px: 44)
  six_letters_wide, _ = $gtk.calcstringbox('ABCDEF', size_px: 44)
  input = Input::Text.new(x: 100, y: 100, w: 200, size_px: 44, value: 'ABCDEFGH', focussed: true)

  mouse_is_inside(input, x: 100 + three_letters_wide)
  mouse_down
  input.tick
  mouse_is_inside(input, x: 100 + six_letters_wide)
  mouse_up
  input.tick

  assert.equal! input.selection_start, 3
  assert.equal! input.selection_end, 6
end