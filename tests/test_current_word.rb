require_relative 'test_helpers'

def test_finds_current_word(_args, assert)
  assert_current_word(assert, '|word test', nil)
  assert_current_word(assert, 'w|ord test', 'word')
  assert_current_word(assert, 'wor|d test', 'word')
  assert_current_word(assert, 'word| test', 'word')
  assert_current_word(assert, 'word |test', nil)
end