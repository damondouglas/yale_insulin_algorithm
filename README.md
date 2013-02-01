yale_insulin_algorithm
======================

A pure Dart implementation of the Yale Insulin Algorithm as a Chrome Packaged App.

The application currently only runs on the Dartium browser that comes with the Dart editor install.  

To install:

1) Load Chromium browser  [DART_INSTALL]/Chromium

2) Open chrome://extensions/

3) Check "Developer mode"

4) Click Load unpacked extension...

5) Navigate to folder containing:

dartium
	dart.js
	images
		InsulinHexamer.jpg
	lib
		yale_insulin_algorithm.dart
	manifest.json
	yale_insulin.css
	yale_insulin.dart
	yale_insulin.html

6) Open new tab in Chromium and click the "Yale Insulin Algorithm"

7) The algorithm is intended for hourly blood glucose entries.  Enter, for example, 325 in the blood glucose field and press enter.  It will ask "are you sure" to validate your measurement.  Change the time hour to 0 and click "Yes"

8) Enter a second glucose value, for example, 350.  Change the time hour to 1 and click "Yes".

9) Follow with subsequent values changing the time to increasing hours.

10) Double click one of the comments in the table and for example type "Dexamethasone 5 mg every six hours"

11) Hover over each point on the graph to see the values and comments from the table.


The dart code has not yet been converted into pure javascript as I received the following error:
Internal error: continue to switch case not implemented
        continue follow;
        ^^^^^^^^^^^^^^^^
Error: Compilation failed.

Disclaimer:

This algorithm implements Goldberg et al. Diabetes Care 27(2):461-467 and is the sole interpretation of Damon Douglas.  This implementation has not been validated or tested and should not be used yet for clinical guidance.