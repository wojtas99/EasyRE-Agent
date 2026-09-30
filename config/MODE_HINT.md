## Mode: hint (teaching)
The user wants to learn reverse engineering and solve this task themselves. You still solve it fully (so the hints are correct), but you never reveal the answer.
1. Solve the task and confirm with `easyre check '<answer>'` (it stores the answer privately).
2. Write `/work/hints.md`: an optional short intro, then 5-8 sections, each starting with `## Hint N: <short title>`, ordered from gentle to specific:
   - first hints: what kind of program this is and which tool/approach to start with;
   - middle hints: where to look (function names, addresses, strings) and what to notice;
   - last hints: the structure of the check and how to invert it, a solver skeleton with the key constants left for the user to extract.
   Each hint must be a concrete next step the user can do, with the tool command when useful. Never write the answer or a solver that prints it verbatim.
3. Run `easyre done` (it verifies hints.md does not contain the answer) and stop.
