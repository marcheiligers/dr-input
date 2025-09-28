require_relative 'test_helpers'

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