require_relative 'test_helpers'

def test_no_max_length(_args, assert)
  input = build_text_input('1234567890', 10, 10)
  input.insert('abc')

  assert.equal! input.value.to_s, '1234567890abc'
  assert.equal! input.selection_end, 13
  assert.equal! input.selection_start, 13
end

def test_max_length(_args, assert)
  input = build_text_input('1234567890', 10, 10, max_length: 10)
  input.insert('abc')

  assert.equal! input.value.to_s, '1234567890'
  assert.equal! input.selection_end, 10
  assert.equal! input.selection_start, 10
end

def test_max_length_inserts_as_much_as_possible(_args, assert)
  input = build_text_input('1234567890', 10, 10, max_length: 11)
  input.insert('abc')

  assert.equal! input.value.to_s, '1234567890a'
  assert.equal! input.selection_end, 11
  assert.equal! input.selection_start, 11
end

def test_max_length_inserts_as_much_as_possible_in_the_middle(_args, assert)
  input = build_text_input('1234567890', 5, 5, max_length: 11)
  input.insert('abc')

  assert.equal! input.value.to_s, '12345a67890'
  assert.equal! input.selection_end, 6
  assert.equal! input.selection_start, 6
end

def test_max_length_inserts_as_much_as_possible_in_the_middle_overwriting(_args, assert)
  input = build_text_input('1234567890', 5, 6, max_length: 11)
  input.insert('abc')

  assert.equal! input.value.to_s, '12345ab7890'
  assert.equal! input.selection_end, 7
  assert.equal! input.selection_start, 7
end