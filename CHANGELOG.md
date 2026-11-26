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
- Workflow `unit`: the ABAP Unit tests of `src/core` run off-stack on every pull request.
- Probe program `Z_CCR_PROBE` that confirms the ATC and SUSG interfaces of a system.
- Guide to the method: `docs/guide.md`.
