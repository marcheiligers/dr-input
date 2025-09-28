require_relative 'test_helpers'

def test_menu_constrains_selected_index(args, assert)
  menu = Input::Menu.new(items: %w[1 2 3])

  menu.selected_index = 0
  assert.equal! menu.selected_index, 0

  menu.selected_index = 1
  assert.equal! menu.selected_index, 1

  menu.selected_index = 2
  assert.equal! menu.selected_index, 2

  menu.selected_index = 3
  assert.equal! menu.selected_index, 0

  menu.selected_index = -1
  assert.equal! menu.selected_index, 2
end

def test_menu_calculates_menu_items_to_show_short_odd(args, assert)
  menu = Input::Menu.new(items: %w[1 2 3])

  menu.selected_index = 0
  assert.equal! menu.items_to_show(110), [0, 3], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 1
  assert.equal! menu.items_to_show(110), [0, 3], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 2
  assert.equal! menu.items_to_show(110), [0, 3], "with selected_index: #{menu.selected_index}"
end

def test_menu_calculates_menu_items_to_show_short_even(args, assert)
  menu = Input::Menu.new(items: %w[1 2 3 4])

  menu.selected_index = 0
  assert.equal! menu.items_to_show(110), [0, 4], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 1
  assert.equal! menu.items_to_show(110), [0, 4], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 2
  assert.equal! menu.items_to_show(110), [0, 4], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 3
  assert.equal! menu.items_to_show(110), [0, 4], "with selected_index: #{menu.selected_index}"
end

def test_menu_calculates_menu_items_to_show_long(args, assert)
  menu = Input::Menu.new(items: (0..999).to_a.map(&:to_s))

  menu.selected_index = 0
  assert.equal! menu.items_to_show(110), [0, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 1
  assert.equal! menu.items_to_show(110), [0, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 2
  assert.equal! menu.items_to_show(110), [0, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 3
  assert.equal! menu.items_to_show(110), [1, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 4
  assert.equal! menu.items_to_show(110), [2, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 5
  assert.equal! menu.items_to_show(110), [3, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 150
  assert.equal! menu.items_to_show(110), [148, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 995
  assert.equal! menu.items_to_show(110), [993, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 996
  assert.equal! menu.items_to_show(110), [994, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 997
  assert.equal! menu.items_to_show(110), [995, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 998
  assert.equal! menu.items_to_show(110), [995, 5], "with selected_index: #{menu.selected_index}"

  menu.selected_index = 999
  assert.equal! menu.items_to_show(110), [995, 5], "with selected_index: #{menu.selected_index}"
end