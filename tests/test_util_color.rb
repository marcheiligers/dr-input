require_relative 'test_helpers'

def test_parse_color_integer_rgb(_args, assert)
  assert.equal! Input::Util.parse_color({ test_color: 0 }, 'test'), { r: 0, g: 0, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: 0xFF0000 }, 'test'), { r: 255, g: 0, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: 0x00FF00 }, 'test'), { r: 0, g: 255, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: 0x0000FF }, 'test'), { r: 0, g: 0, b: 255, a: 255 }
end

def test_parse_color_integer_rgba(_args, assert)
  # NOTE: For Integer (hex) rgba to work, there has to be a red component > 0
  assert.equal! Input::Util.parse_color({ test_color: 0x01000000 }, 'test'), { r: 1, g: 0, b: 0, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: 0xFF000000 }, 'test'), { r: 255, g: 0, b: 0, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: 0x01FF0000 }, 'test'), { r: 1, g: 255, b: 0, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: 0x0100FF00 }, 'test'), { r: 1, g: 0, b: 255, a: 0 }
end

def test_parse_color_array_rgb(_args, assert)
  assert.equal! Input::Util.parse_color({ test_color: [255, 0, 0] }, 'test'), { r: 255, g: 0, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: [0, 255, 0] }, 'test'), { r: 0, g: 255, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: [0, 0, 255] }, 'test'), { r: 0, g: 0, b: 255, a: 255 }
end

def test_parse_color_array_rgb_da(_args, assert)
  assert.equal! Input::Util.parse_color({ test_color: [255, 0, 0] }, 'test', da: 1), { r: 255, g: 0, b: 0, a: 1 }
  assert.equal! Input::Util.parse_color({ test_color: [0, 255, 0] }, 'test', da: 1), { r: 0, g: 255, b: 0, a: 1 }
  assert.equal! Input::Util.parse_color({ test_color: [0, 0, 255] }, 'test', da: 1), { r: 0, g: 0, b: 255, a: 1 }
end

def test_parse_color_array_rgba(_args, assert)
  assert.equal! Input::Util.parse_color({ test_color: [255, 0, 0, 0] }, 'test'), { r: 255, g: 0, b: 0, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: [0, 255, 0, 0] }, 'test'), { r: 0, g: 255, b: 0, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: [0, 0, 255, 0] }, 'test'), { r: 0, g: 0, b: 255, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: [0, 0, 0, 0] }, 'test'), { r: 0, g: 0, b: 0, a: 0 }
end

def test_parse_color_hash_rgba(_args, assert)
  assert.equal! Input::Util.parse_color({ test_color: { r: 255, g: 0, b: 0, a: 0 } }, 'test'), { r: 255, g: 0, b: 0, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: { r: 0, g: 255, b: 0, a: 0 } }, 'test'), { r: 0, g: 255, b: 0, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: { r: 0, g: 0, b: 255, a: 0 } }, 'test'), { r: 0, g: 0, b: 255, a: 0 }
  assert.equal! Input::Util.parse_color({ test_color: { r: 0, g: 0, b: 0, a: 0 } }, 'test'), { r: 0, g: 0, b: 0, a: 0 }
end

def test_parse_color_hash_component(_args, assert)
  assert.equal! Input::Util.parse_color({ test_color: { r: 255 } }, 'test'), { r: 255, g: 0, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: { g: 255 } }, 'test'), { r: 0, g: 255, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: { b: 255 } }, 'test'), { r: 0, g: 0, b: 255, a: 255 }
  assert.equal! Input::Util.parse_color({ test_color: { a: 0 } }, 'test'), { r: 0, g: 0, b: 0, a: 0 }
end

def test_parse_color_nil(_args, assert)
  assert.equal! Input::Util.parse_color({}, 'test'), { r: 0, g: 0, b: 0, a: 255 }
  assert.equal! Input::Util.parse_color_nilable({}, 'test'), nil
end