def test_calcstringbox_works_in_tests(_args, assert)
  w, h = $gtk.calcstringbox('1234567890', 0, '')
  assert.true! w > 0
  assert.true! h > 0
end

def test_calcstringbox_new_line_has_no_width(_args, assert)
  w, h = $gtk.calcstringbox("\n", 0, '')
  assert.equal! w, 0.0
  assert.equal! h, 22.0 # Yep, it has a height
end

def test_calcstringbox_double_new_line_has_no_width(_args, assert)
  w, h = $gtk.calcstringbox("\n\n", 0, '')
  assert.equal! w, 0.0
  assert.equal! h, 22.0 # Yep, it has a height
end

def test_calcstringbox_with_day_roman_new_line_has_width(_args, assert)
  w, h = $gtk.calcstringbox("\n\n", 0, 'fonts/day-roman/DAYROM__.ttf')
  assert.false! w == 0.0 # :/
  assert.false! h == 0.0 # :/
end

def test_calcstringbox_tab_has_no_witdh(_args, assert)
  w, h = $gtk.calcstringbox("\t", 0, '')
  assert.equal! w, 0.0 # Yep, it has no width :/
  assert.equal! h, 22.0 # Yep, it has a height
end

def test_find_word_breaks_empty_value(_args, assert)
  assert.equal! word_wrap_result(''), ['']
end

def test_find_word_breaks_single_space(_args, assert)
  assert.equal! word_wrap_result(' '), [' ']
end

def test_find_word_breaks_single_char(_args, assert)
  assert.equal! word_wrap_result('a'), ['a']
end

def test_multiline_word_breaks_two_words(_args, assert)
  assert.equal! word_wrap_result('Hello, world'), ['Hello, ', 'world']
end

def test_find_word_breaks_leading_and_trailing_white_space(_args, assert)
  assert.equal! word_wrap_result(" \t  hello \t "), [" \t  hello \t "]
end

def test_find_word_breaks_leading_and_trailing_white_space_multiple_words(_args, assert)
  assert.equal! word_wrap_result(" \t  hello, \t  world \t"), [" \t  hello, \t  ", "world \t"]
end

def test_multiline_word_breaks_trailing_new_line(_args, assert)
  assert.equal! word_wrap_result("hello, \n"), ['hello, ', "\n"]
end

def test_multiline_word_breaks_new_line(_args, assert)
  assert.equal! word_wrap_result("hello, \n  world"), ['hello, ', "\n  world"]
end

def test_multiline_word_breaks_double_new_line(_args, assert)
  assert.equal! word_wrap_result("hello, \n\n  world"), ['hello, ', "\n", "\n  world"]
end

def test_multiline_word_breaks_multiple_new_lines(_args, assert)
  assert.equal! word_wrap_result("hello, \n\n\n  world"), ['hello, ', "\n", "\n", "\n  world"]
end

def test_perform_word_wrap_multiple_new_lines(_args, assert)
  assert.equal! word_wrap_result("1\n\n\n2"), ['1', "\n", "\n", "\n2"]
end

def test_perform_word_wrap_trailing_new_line(_args, assert)
  assert.equal! word_wrap_result("1\n"), ['1', "\n"]
end

def test_find_word_breaks_trailing_new_line_after_wrap(_args, assert)
  assert.equal! word_wrap_result("1234567890 1234567890 1234567890\n"), ['1234567890 ', '1234567890 ', '1234567890', "\n"]
end

def test_multiline_word_breaks_a_very_long_word(_args, assert)
  assert.equal! word_wrap_result('Supercalifragilisticexpialidocious'), ['Supercalif', 'ragilistic', 'expialidoc', 'ious']
end

def test_multiline_word_breaks_breaks_very_long_word_after_something_that_isnt(_args, assert)
  assert.equal! word_wrap_result('Super califragilisticexpialidocious'), ['Super ', 'califragil', 'isticexpia', 'lidocious']
end

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
  mosue_down
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

def build_multiline_input(width_in_letters)
  # This works because the default DR font is monospaced
  width, _ = $gtk.calcstringbox('1' * width_in_letters, 0)
  Input::Multiline.new(w: width)
end

def word_wrap_result(string, width_in_letters = 10)
  multiline = build_multiline_input(10)
  multiline.insert string
  multiline.lines.map(&:text)
end

def mouse_is_at(x, y)
  $args.inputs.mouse.x = x
  $args.inputs.mouse.y = y
end

def mouse_is_inside(rect, x: nil)
  mouse_is_at(
    x || rect.x + rect.w.half,
    rect.y + rect.h.half
  )
end

def mouse_down
  $args.inputs.mouse.button_left = true
  $args.inputs.mouse.click = GTK::MousePoint.new($args.inputs.mouse.x, $args.inputs.mouse.y)
  $args.inputs.mouse.up = false
end

def mouse_up
  $args.inputs.mouse.button_left = false
  $args.inputs.mouse.click = nil
  $args.inputs.mouse.up = true
end
