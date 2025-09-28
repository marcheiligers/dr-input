require_relative 'test_helpers'

def test_find_word_break_left(_args, assert)
  assert_finds_word_break_left(assert, '|word test', '|word test')
  assert_finds_word_break_left(assert, 'wo|rd test', '|word test')
  assert_finds_word_break_left(assert, 'word| test', '|word test')
  assert_finds_word_break_left(assert, 'word |test', '|word test')
  assert_finds_word_break_left(assert, 'word t|est', 'word |test')
  assert_finds_word_break_left(assert, 'word test|', 'word |test')
end

def test_find_word_break_right(_args, assert)
  assert_finds_word_break_right(assert, '|word test', 'word| test')
  assert_finds_word_break_right(assert, 'wo|rd test', 'word| test')
  assert_finds_word_break_right(assert, 'wor|d test', 'word| test')
  assert_finds_word_break_right(assert, 'word| test', 'word test|')
  assert_finds_word_break_right(assert, 'word |test', 'word test|')
  assert_finds_word_break_right(assert, 'word t|est', 'word test|')
  assert_finds_word_break_right(assert, 'word test|', 'word test|')
end