require_relative 'test_helpers'

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