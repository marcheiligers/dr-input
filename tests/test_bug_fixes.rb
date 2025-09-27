require_relative 'test_helpers'

def test_assign_text_nil(_args, assert)
  input = build_text_input('1234567890', 10, 10)
  input.value = nil

  assert.equal! input.value.to_s, ''
  assert.equal! input.selection_end, 0
  assert.equal! input.selection_start, 0
end

def test_create_with_nil_value(_args, assert)
  input = build_text_input(nil)

  assert.equal! input.value.to_s, ''
  assert.equal! input.selection_end, 0
  assert.equal! input.selection_start, 0
end

def test_create_with_non_string_non_falsey_value(_args, assert)
  input = build_text_input(true)

  assert.equal! input.value.to_s, 'true'
  assert.equal! input.selection_end, 0
  assert.equal! input.selection_start, 0
end