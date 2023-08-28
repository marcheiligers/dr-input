# v0.0.4 - 27 August 2023

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
* Improved mouse selection (finding cursor index by x position) for word wrapped input
* Introduced `LineCollection` data structure for word wrap to centralize a lot of the line handling, measuring and so on
* Broke out classes for different input types
* Fixed (some) cursor start of line/end of line weirdnesses

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

// Sunday 08/27/23 at 05:15PM - 28 files in 0.11 secs

## BUG (2)
1. lib/word_wrap_input.rb:94    up from the first row is going to 0???
2. lib/word_wrap_input.rb:108   down from the first row isn't working???

## TODO (22)
1. lib/word_wrap_input.rb:271   Show cursor at start of next line if after the white space at the end of the current line (0)
2. lib/input.rb:74              Blurred colors
3. lib/input.rb:106             Cursor renders outside of the bounds of the control
4. lib/input.rb:194             Improve walking words
5. lib/word_wrap_input.rb:17    undo/redo
6. lib/word_wrap_input.rb:92    Retain a original_cursor_x when moving up/down to try stay generally in the same x range
7. lib/word_wrap_input.rb:100   beginning of previous paragraph
8. lib/word_wrap_input.rb:114   end of next paragraph
9. lib/word_wrap_input.rb:135   Word selection (double click), All selection (triple click)
10. lib/word_wrap_input.rb:176  prolly need to replace \r\n with \n up front
11. lib/word_wrap_input.rb:180  consider how to render TAB, maybe convert TAB into 4 spaces?
12. lib/word_wrap_input.rb:186  consider smarter handling. "something!)something" would be considered a word right now, theres an extra step needed
13. lib/word_wrap_input.rb:204  consider how to render TAB, maybe convert TAB into 4 spaces?
14. lib/word_wrap_input.rb:247  Implement line spacing
15. lib/word_wrap_input.rb:252  implement sprite background
16. lib/word_wrap_input.rb:272  Ensure cursor_x doesn't go past the line width
17. lib/simple_input.rb:11      undo/redo
18. lib/simple_input.rb:87      Word selection (double click), All selection (triple click)
19. lib/simple_input.rb:104     handle scrolling to the right with mouse
20. lib/simple_input.rb:110     Improve walking words
21. lib/simple_input.rb:163     handle padding correctly
22. lib/simple_input.rb:169     implement sprite background
