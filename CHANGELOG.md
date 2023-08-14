# v0.0.1

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

## Known issues

* Word boundaries are iffy based on a a-z, A-Z, 0-9, \_, and - being word characters
* Mouse selection scrolls the text very, very angrily
* Cursor control key combinations don't repeat
* Cursor renders outside the visible area of the input (overlaps)
* Padding isn't correctly taken into account on all edges (see :point_up:)
