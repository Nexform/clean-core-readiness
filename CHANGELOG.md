# Changelog

All notable changes to this project are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Repository skeleton: abapGit folder `src/` with the root package, abaplint configuration
  (On-Prem rules of [greltel/abap-llm-rulebook](https://github.com/greltel/abap-llm-rulebook))
  and the abaplint workflow.
- Core logic, package `Z_CCR_CORE`: `ZCL_CCR_LEVEL_RULES` gives a finding of the ATC check
  "Usage of APIs" its clean core level (note B, warning C, error D), `ZCL_CCR_CLASSIFIER`
  gives every object the worst level among its findings.
- Core logic: `ZCL_CCR_ASSESSOR` joins level and usage to a proposal. An object that can be
  measured and did not run is a candidate to retire; otherwise keep at level A or B,
  remediate at C, remediate first at D. Usage can be measured for classes, function groups
  and programs only; every other object has usage "unknown" and is never proposed to retire.
- ATC reader: `ZIF_CCR_ATC_READER` and its adapter `ZCL_CCR_ATC_READER` list the complete
  runs of a check variant, read the findings of one run through the classic ATC API and read
  the objects of the checked packages and their subpackages from TADIR (an ATC result does
  not list the objects it checked).
- Usage reader: `ZIF_CCR_USAGE_READER` and its adapter `ZCL_CCR_USAGE_READER` list the usage
  data sets of SUSG with their period and sum the executions and the last use of the checked
  objects in one data set, in the database.
- Report `Z_CCR_READINESS`: choose the ATC run of the check variant and the usage data set
  with value help, enter the packages of the run and the object types (default CLAS, INTF,
  PROG, FUGR, DDLS, BDEF, ENHO); the ALV list shows one row per object with level, findings
  per level, usage and proposal, and above it the run and the period of the usage data.
  Export to a spreadsheet from the ALV toolbar.
- `ZCL_CCR_CLASSIFIER` takes the checked objects too: an object without any finding is level A.
- Workflow `unit`: the ABAP Unit tests of `src/core` run off-stack on every pull request.
- Probe program `Z_CCR_PROBE` that confirms the ATC and SUSG interfaces of a system.
- Probe `Z_CCR_PROBE` 1.3, part D for the ATC reader: attributes of a finding (where the
  referenced object is kept), checks and message codes of the clean core check variant, and
  the stored content of a run (whether it lists the checked objects).
- Guide to the method: `docs/guide.md`.

### Changed

- `Z_CCR_READINESS`: two pushbuttons on the selection screen, "How to run ATC" (the steps to run
  ATC with the clean core variant, in a popup) and "Open transaction ATC". The input fields are
  no longer OBLIGATORY, so the buttons work on an empty screen; the report checks that run,
  packages and usage data set are filled in.
- README: installation, usage of `Z_CCR_READINESS`, the level from the message kind of "Usage
  of APIs", usage state "unknown", limits of version 0.1.
- Guide: level from the message kind instead of the priority, steps to read the result,
  usage per procedure and "usage unknown", new pitfalls, open points confirmed on S/4HANA 2025.

### Fixed

- `ZCL_CCR_CLASSIFIER` raised `CX_SY_DYN_CALL_ILLEGAL_TYPE` in a system: it passed a row of a
  sorted table to a CHANGING parameter. The row is now handed over as a reference. The
  off-stack tests had not shown it, because the transpiler does not protect table keys.
- `Z_CCR_PROBE` masks fields named `RESP*` as user names.
- `Z_CCR_READINESS`: the value helps of run and usage data set failed. Their ID column had a
  built-in type; the value help reads its columns from the dictionary, so the ID has the type
  `SYSUUID_C32` now. A failing value help shows its return code instead of "No values".
- `Z_CCR_READINESS`: the length of the selection texts in the program XML is the one the
  system writes (text plus 8), so abapGit shows no difference after a pull.
