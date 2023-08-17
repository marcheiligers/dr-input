def test_word_breaks_empty_value(_args, assert)
  assert.equal! Input.new.word_breaks(''), ['']
end

def test_word_breaks_single_space(_args, assert)
  assert.equal! Input.new.word_breaks(' '), [' ']
end

def test_word_breaks_single_char(_args, assert)
  assert.equal! Input.new.word_breaks('a'), ['a']
end

def test_word_breaks_2_words(_args, assert)
  assert.equal! Input.new.word_breaks('hello, world'), ['hello, ', 'world']
end

def test_word_breaks_leading_and_trailing_white_space(_args, assert)
  assert.equal! Input.new.word_breaks(" \t  hello \t "), [" \t  hello \t "]
end

def test_word_breaks_leading_and_trailing_white_space_multiple_words(_args, assert)
  assert.equal! Input.new.word_breaks(" \t  hello, \t  world \t"), [" \t  hello, \t  ", "world \t"]
end

def test_word_breaks_new_line(_args, assert)
  assert.equal! Input.new.word_breaks("hello, \n  world"), ["hello, \n", '  world']
end

def test_word_breaks_double_new_line(_args, assert)
  assert.equal! Input.new.word_breaks("hello, \n\n  world"), ["hello, \n", "\n", '  world']
end
