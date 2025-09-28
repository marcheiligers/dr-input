require_relative 'test_helpers'

def test_delete_back(_args, assert)
  input = build_text_input('1234567890', 10, 10)
  input.delete_back

  assert.equal! input.value.to_s, '123456789'
  assert.equal! input.selection_end, 9
  assert.equal! input.selection_start, 9
end

def test_delete_back_empty_value(_args, assert)
  input = build_text_input('', 0, 0)
  input.delete_back

  assert.equal! input.value.to_s, ''
  assert.equal! input.selection_end, 0
  assert.equal! input.selection_start, 0
end