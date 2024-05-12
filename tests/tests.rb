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
  assert.equal! omg_test_the_thing(''), ['']
end

def test_find_word_breaks_single_space(_args, assert)
  assert.equal! omg_test_the_thing(' '), [' ']
end

def test_find_word_breaks_single_char(_args, assert)
  assert.equal! omg_test_the_thing('a'), ['a']
end

def test_multiline_word_breaks_two_words(_args, assert)
  assert.equal! omg_test_the_thing('Hello, world'), ['Hello, ', 'world']
end

def test_find_word_breaks_leading_and_trailing_white_space(_args, assert)
  assert.equal! omg_test_the_thing(" \t  hello \t "), [" \t  hello \t "]
end

def test_find_word_breaks_leading_and_trailing_white_space_multiple_words(_args, assert)
  assert.equal! omg_test_the_thing(" \t  hello, \t  world \t"), [" \t  hello, \t  ", "world \t"]
end

def test_multiline_word_breaks_trailing_new_line(_args, assert)
  assert.equal! omg_test_the_thing("hello, \n"), ['hello, ', "\n"]
end

def test_multiline_word_breaks_new_line(_args, assert)
  assert.equal! omg_test_the_thing("hello, \n  world"), ['hello, ', "\n  world"]
end

def test_multiline_word_breaks_double_new_line(_args, assert)
  assert.equal! omg_test_the_thing("hello, \n\n  world"), ['hello, ', "\n", "\n  world"]
end

def test_multiline_word_breaks_multiple_new_lines(_args, assert)
  assert.equal! omg_test_the_thing("hello, \n\n\n  world"), ['hello, ', "\n", "\n", "\n  world"]
end

def test_perform_word_wrap_multiple_new_lines(_args, assert)
  assert.equal! omg_test_the_thing("1\n\n\n2"), ['1', "\n", "\n", "\n2"]
end

def test_perform_word_wrap_trailing_new_line(_args, assert)
  assert.equal! omg_test_the_thing("1\n"), ['1', "\n"]
end

def test_find_word_breaks_trailing_new_line_after_wrap(_args, assert)
  assert.equal! omg_test_the_thing("1234567890 1234567890 1234567890\n"), ['1234567890 ', '1234567890 ', '1234567890', "\n"]
end

def test_multiline_word_breaks_doesnt_break_very_long_word(_args, assert)
  # REVIEW: This breaks and actually returns ["", "Supercalifragilisticexpialidocious"] - is this behavior as intended?
  assert.equal! omg_test_the_thing('Supercalifragilisticexpialidocious'), ['Supercalifragilisticexpialidocious']
end

def build_multiline_input(width_in_letters)
  # This works because the default DR font is monospaced
  width, _ = $gtk.calcstringbox('1' * width_in_letters, 0)
  Input::Multiline.new(w: width)
end

def omg_test_the_thing(string, width_in_letters = 10)
  multiline = build_multiline_input(10)
  multiline.insert string
  multiline.lines.map(&:text)
end
