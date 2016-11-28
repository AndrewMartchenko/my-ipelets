# fillet

Creates circular fillets in polylines and polygons.

![examples](fillet_example.png)

## Download and Installation

Download [fillet.lua](fillet.lua) and copy to ~/.ipe/ipelets/ (or to some other directory for ipelets)

## Usage

* Select one or more polygons/polylines then click "Ipelets->Fillet" or use the short cut Shift-F.
* Specify the radius of the fillets and hit enter.

## Note
* Grouped paths will be ignored.
* If a selected path contains non-liner segments, then those segments will be ignored and fillets will only be created between two linear segments.
* If a fillet does not fit on a line segment (when angle between segments is too small), then it will not be created

## Author

* Andrew Martchenko
