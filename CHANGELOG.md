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

## BUG (2)
1. lib/input.rb:240   Something is wrong with inserting at the end
2. lib/input.rb:276   Single character words are busted

## TODO (7)
1. lib/input.rb:67    make clipboard global for if there's more than one input (0)
2. lib/input.rb:55    implement key repeat for cursor movement
3. lib/input.rb:98    Cursor renders outside of the bounds of the control
4. lib/input.rb:148   undo/redo
5. lib/input.rb:257   Word selection (double click), All selection (triple click)
6. lib/input.rb:277   Improve walking words
7. lib/input.rb:328   handle padding correctly
