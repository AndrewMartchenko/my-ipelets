# polyfillet

Creates circular fillets in polylines or polygons

![examples](fillet_example.png)

## Download and Installation

Download [polyfillet.lua](polyfillet.lua) and copy to ~/.ipe/ipelets/ (or to some other directory for ipelets)

## Usage

* Select one or more polyline or polygon paths, then click "Ipelets->Polyfillet" or use the short cut Shift-f.
* Enter the fillet radius and hit enter.
* Fillets will be drawn between all linear line segments in the selected path.
* Non-linear line segments will be ignored.
* Line segments that are too small for the fillet will also be ignored

## Author

* Andrew Martchenko
