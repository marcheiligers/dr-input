require 'tests/test_helpers.rb'

def test_value_changed_on_insert(args, assert)
  input = build_text_input('hello')

  # tick resets @value_changed to false
  input.tick
  assert.false! input.value_changed?, 'value_changed should be false after tick'

  # insert sets @value_changed to true
  input.insert('world')
  assert.true! input.value_changed?, 'value_changed should be true after insert'
end

def test_value_changed_on_value_setter(args, assert)
  input = build_text_input('hello')

  # tick resets @value_changed to false
  input.tick
  assert.false! input.value_changed?, 'value_changed should be false after tick'

  # value= sets @value_changed to true
  input.value = 'goodbye'
  assert.true! input.value_changed?, 'value_changed should be true after value='
end
