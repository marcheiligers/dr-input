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

# REVIEW: Are these still needed?
# def test_find_word_breaks_empty_value(_args, assert)
#   assert.equal! Input::Multiline.new.find_word_breaks(''), ['']
# end

# def test_find_word_breaks_single_space(_args, assert)
#   assert.equal! Input::Multiline.new.find_word_breaks(' '), [' ']
# end

# def test_find_word_breaks_single_char(_args, assert)
#   assert.equal! Input::Multiline.new.find_word_breaks('a'), ['a']
# end

def test_multiline_word_breaks_two_words(_args, assert)
  multiline = build_ten_letter_wide_multiline
  multiline.insert 'Hello, world'

  assert.equal! multiline.lines.map(&:text), ['Hello, ', 'world']
end

# REVIEW: This one doesn't work anymore when used on the actual Multiline instance
# def test_find_word_breaks_leading_and_trailing_white_space(_args, assert)
#   assert.equal! Input::Multiline.new.find_word_breaks(" \t  hello \t "), [" \t  hello \t "]
# end

# REVIEW: Is this still needed?
# def test_find_word_breaks_leading_and_trailing_white_space_multiple_words(_args, assert)
#   assert.equal! Input::Multiline.new.find_word_breaks(" \t  hello, \t  world \t"), [" \t  hello, \t  ", "world \t"]
# end

def test_multiline_word_breaks_new_line(_args, assert)
  multiline = build_ten_letter_wide_multiline
  multiline.insert "hello, \n  world"

  assert.equal! multiline.lines.map(&:text), ['hello, ', "\n  world"]
end

def test_multiline_word_breaks_double_new_line(_args, assert)
  multiline = build_ten_letter_wide_multiline
  multiline.insert "hello, \n\n  world"

  assert.equal! multiline.lines.map(&:text), ['hello, ', "\n", "\n  world"]
end

def test_multiline_word_breaks_multiple_new_lines(_args, assert)
  multiline = build_ten_letter_wide_multiline
  multiline.insert "hello, \n\n\n  world"

  assert.equal! multiline.lines.map(&:text), ['hello, ', "\n", "\n", "\n  world"]
end

def test_multiline_word_breaks_trailing_new_line(_args, assert)
  multiline = build_ten_letter_wide_multiline
  multiline.insert "hello, \n"

  assert.equal! multiline.lines.map(&:text), ['hello, ', "\n"]
end

# REVIEW: Are these still needed?
# def test_perform_word_wrap_multiple_new_lines(_args, assert)
#   assert.equal! Input::Multiline.new.perform_word_wrap(['1', "\n", "\n", "\n2"]).map(&:text), ['1', "\n", "\n", "\n2"]
# end

# def test_perform_word_wrap_trailing_new_line(_args, assert)
#   assert.equal! Input::Multiline.new.perform_word_wrap(['1', "\n"]).map(&:text), ['1', "\n"]
# end

# def test_find_word_breaks_trailing_new_line_after_wrap(_args, assert)
#   assert.equal! Input::Multiline.new.find_word_breaks("1234567890 1234567890 1234567890\n"), ['1234567890 ', '1234567890 ', '1234567890', "\n"]
# end

# def test_perform_word_wrap_trailing_new_line_after_wrap(_args, assert)
#   assert.equal! Input::Multiline.new.perform_word_wrap(['1234567890 ', '1234567890 ', '1234567890', "\n"]).map(&:text), ['1234567890 1234567890 ', '1234567890', "\n"]
# end

# def test_find_word_breaks_trailing_new_line_after_wrap_with_space(_args, assert)
#   assert.equal! Input::Multiline.new.find_word_breaks("1234567890 1234567890 \n"), ['1234567890 ', '1234567890 ', "\n"]
# end

# def test_perform_word_wrap_trailing_new_line_after_wrap(args, assert)
#   assert.equal! Input::Multiline.new.perform_word_wrap(['', '']), ["1\n", '']
# end

def test_multiline_word_breaks_doesnt_break_very_long_word(_args, assert)
  multiline = build_ten_letter_wide_multiline
  multiline.insert 'Supercalifragilisticexpialidocious'

  # REVIEW: This breaks and actually returns ["", "Supercalifragilisticexpialidocious"] - is this behavior as intended?
  assert.equal! multiline.lines.map(&:text), ['Supercalifragilisticexpialidocious']
end

def build_ten_letter_wide_multiline(value = nil)
  ten_letters_width, _ = $gtk.calcstringbox('1234567890', 0)
  Input::Multiline.new(w: ten_letters_width, value: value || '')
end
