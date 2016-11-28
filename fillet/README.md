# fillet

Creates circular fillets in polylines and polygons.

![examples](fillet_example.png)

## Download and Installation

Download [fillet.lua](fillet.lua) and copy to ~/.ipe/ipelets/ (or to some other directory for ipelets)

## Usage

* Select one or more polygons/polylines then click "Ipelets->Fillet" or use the short cut Shift-F.
* Specify the radius of the fillets and hit enter.
* jhg
* Tangent lines will be drawn from the primary selection to all other selected objects.
* To change the primary selection, go into selection mode (hit "s" on the keyboard) then while holding the Shift key double click on the object which you would like as your primary selection.
* If there are any intersecting tangent line segments, they will remain selected so that you can easily delete them withs the "Delete" key.

## Note
* Grouped paths will be ignored.
* Fillets will only be created between two linear segments. Non-linear segments are ignored.
* If a fillet does not fit on a line segment (when angle between segments is too small), then it will not be created

## Author

* Andrew Martchenko
