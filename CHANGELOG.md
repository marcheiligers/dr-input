# v0.0.4 - X August 2023

* Added a background color property.
  * Having a background improves the rendering quality.
* Added some usage notes to the README.md
* Fixed: Inserting multiple characters (paste, or multiple characters) in a single tick
* Implement key repeat for cursor movement
* Fixed: At some point walking single character words was fixed
* Added focus state, `#focussed?`, `#focus!`, `#blur!`
* Added `on_clicked` and `on_unhandled_key` callbacks
* Added mouse selection for word wrapped control
* Added up and down (without `[alt]`) for word wrapped control

# v0.0.3 - 20 August 2023

* Word-wrap option and smart word breaks algorithm, with some tests
* Cursor for wrapping text
* Text selection for wrapping text, including multi-line selection
* Fixed: Something is wrong with inserting at the end
* Fixed: Rendering issue when deleting from non-wrapping field

# v0.0.2 - 14 August 2023

* Add cut, copy, paste
* Added (initial) Rubocop config
* Moved all known issues into TODO and BUG comments

# v0.0.1 - 13 August 2023

* First release
* Text entry (I mean, this is the very least it could do)
* Automatic height calc based on font and size (optional)
* Flashing cursor
* Cursor control
  * [Left], [Right]
  * [Alt]+[Left], [Alt]+[Right] to word boundaries
  * [Meta]+[Left], [Ctrl]+[Left], [Ctrl]+[Right], [Meta]+[Right] to beginning, end
* Selection with [Shift] and cursor control
* [Meta]+[A], [Ctrl]+[A] select all
* Mouse cursor positioning and selection
* Mouse selection with [Shift] and current cursor location
* Scrolling when the value is longer than the input

# Known Issues and TODO

## BUG (1)
1. lib/input.rb:288   Single character words are busted

## TODO (11)
1. lib/input.rb:61    implement key repeat for cursor movement
2. lib/input.rb:106   Cursor renders outside of the bounds of the control
3. lib/input.rb:152   undo/redo
4. lib/input.rb:269   Word selection (double click), All selection (triple click)
5. lib/input.rb:289   Improve walking words
6. lib/input.rb:342   prolly need to replace \r\n with \n up front
7. lib/input.rb:346   consider how to render TAB, maybe convert TAB into 4 spaces?
8. lib/input.rb:352   consider smarter handling. "something!)something" would be considered a word right now, theres an extra step needed
9. lib/input.rb:370   consider how to render TAB, maybe convert TAB into 4 spaces?
10. lib/input.rb:430  Implement line spacing
11. lib/input.rb:498  handle padding correctly
