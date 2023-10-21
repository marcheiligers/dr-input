# v0.0.7 - 21 October 2023

* Multiline Performance
  * Draw only the lines in the view
  * Speed up word break finding with Hashes
  * Update edits to use data model instead or reparsing entire value
* Text Performance
  * Draw text in the view
  * Change `find_index_at_x` to use Binary search
* Speed up key repeat slight (4 ticks instead of 5 default)

# v0.0.6 - 10 September 2023

* Added `rect` method
* Fixed: Cursor renders outside of the bounds of the control
* Adjusted index finding for up/down cursor movement in `Multiline`
* Added scrolling for `Multiline` and exposed `#content_h` getter to help with building scroll bars
* Added `#find`, `#find_next` (`[meta|ctrl]+[g]`), `#find_prev` (`[meta|ctrl]+[shift]+[g]`) methods
* Added `#move_page_up`, `#move_page_down`, `#select_page_up`, `#select_page_down` methods and keyboard short cuts


# v0.0.5 - 2 September 2023

* Refactored to use `module Input` and classes `Text` and `Multiline`
* Fixed: move to start and end of line for Multiline
* Updated multiline selection to stop at text end
* Up and down for multiline no longer move to start and end on the first and last lines respectively anymore
* Fixed: up and down not working from the start of the line in multiline
* Refactored to use methods in response to keyboard, and documented methods
* Renamed `#focus!` to `focus`, and `blur!` to `blur`
* Added blurred colors
* Documented accessors

# v0.0.4 - 27 August 2023

* Added a background color property.
  * Having a background improves the rendering quality.
* Added some usage notes to the README.md
* Fixed: Inserting multiple characters (paste, or multiple characters) in a single tick
* Implement key repeat for cursor movement
* Fixed: At some point walking single character words was fixed
* Added focus state, `#focussed?`, `#focus`, `#blur`
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

// Saturday 09/02/23 at 04:45PM - 33 files in 0.1 secs

## BUG (1)
1. lib/base.rb:20         Modifier keys are broken on the web ()

## TODO (20)
1. lib/base.rb:107        Cursor renders outside of the bounds of the control
2. lib/base.rb:291        Improve walking words
3. lib/text.rb:12         undo/redo
4. lib/text.rb:30         Treat delete and backspace differently
5. lib/text.rb:52         Word selection (double click), All selection (triple click)
6. lib/text.rb:69         handle scrolling to the right with mouse
7. lib/text.rb:92         handle padding correctly
8. lib/text.rb:106        implement sprite background
9. lib/multiline.rb:20    undo/redo
10. lib/multiline.rb:51   Retain a original_cursor_x when moving up/down to try stay generally in the same x range
11. lib/multiline.rb:56   beginning of previous paragraph with alt
12. lib/multiline.rb:63   end of next paragraph with alt
13. lib/multiline.rb:169  Word selection (double click), All selection (triple click)
14. lib/multiline.rb:210  prolly need to replace \r\n with \n up front
15. lib/multiline.rb:214  consider how to render TAB, maybe convert TAB into 4 spaces?
16. lib/multiline.rb:220  consider smarter handling. "something!)something" would be considered a word right now, theres an extra step needed
17. lib/multiline.rb:238  consider how to render TAB, maybe convert TAB into 4 spaces?
18. lib/multiline.rb:289  Implement line spacing
19. lib/multiline.rb:294  implement sprite background
20. lib/multiline.rb:312  Ensure cursor_x doesn't go past the line width
