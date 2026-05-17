# Kitty Barrage — Project Instructions

## Language
This is a Godot 4 project written in GDScript. TypeScript/JavaScript rules do not apply. Do not suggest TypeScript.

## Wiki
All task plans, architecture notes, issue reports, design documents, and planning files live in `/Users/steven/dev/kittybarrage/wiki/`.

- When the user says "write a task plan", "create a task plan", "make a plan", or "plan this out", produce an HTML file saved to `/Users/steven/dev/kittybarrage/wiki/` with a descriptive kebab-case filename (e.g. `task-plan-look-around-refactor.html`).
- When asked to "add to the wiki", "update the wiki", or "document X", create or update an HTML file in that directory.
- All wiki pages must follow the established design system: dark theme, same CSS custom properties (`--bg`, `--green`, `--gold`, etc.), same card/table/pill components as existing pages.
- Link new pages from `wiki/index.html`.

## Code Style
- Match existing GDScript patterns exactly — naming conventions, indentation with tabs, signal connection style.
- States return the next `State` from `tick()` — never call `change_state()` from inside a state.
- All `State` subclasses must implement `name() -> Global.StateName`.
