## What and why

<!-- What changes for someone who runs the tool, and why. Link the issue: "Closes #12". -->

## Tested on

<!-- GitHub checks the syntax (abaplint) and runs the unit tests of src/core off-stack (unit).
     It cannot reach ATC or SUSG: the readers and the report run only in your system. -->

- SAP release: <!-- e.g. S/4HANA 2025 FPS01, SAP_BASIS 816 -->
- ATC check variant of the result that was read: <!-- e.g. ABAP_CLEAN_CORE_DEVELOPMENT -->
- Unit tests in the system: <!-- e.g. 42 run, 0 failed -->

## Checklist

- [ ] `npx @abaplint/cli@2.120.107 abaplint.json` reports 0 issues
- [ ] Unit tests are green off-stack and in my system, with a test for every new rule of the classification
- [ ] Every ATC or SUSG object the change reads was confirmed with a probe program first
- [ ] The change reads only: no change to custom code, no deletion
- [ ] Every public declaration has ABAP Doc
- [ ] `CHANGELOG.md` has an entry under `[Unreleased]`; README and guide follow the change

<!-- Docs or workflow change only? Tick what applies and say so above. -->
