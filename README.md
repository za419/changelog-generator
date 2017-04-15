# changelog-generator
Generates a changelog in HTML from a git log

Requires: bash

Usage: changelog-generator [options]
 - -o output-file: Sets the file to send output to
   - If omitted, will output to stdout
 - -t target-dir: The path to the target repository
   - If omitted will expect input formatted like a git log on stdin

Will output as an HTML file with no styling, header/footer, or adherence to convention.

This file will look something like:

    <div>
    <h3>
    DATE
    </h3>
    <br>
    <p>
    MESSAGE
    </p>
    ...
    </div>

Repeated. That is, one `div` will contain everything for one date. Its first element child is an `<h3>` tag, whose content will be the date on which operations take place. This will be followed by a line break, then a set of paragraphs, each one containing a commit message.
