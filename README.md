# Clean Core Readiness

Open-source ABAP tool that shows where the custom code of an SAP S/4HANA system stands on the clean core levels A–D, and which of that code is still in use.

> **Status: pre-release.** There is no installable version yet. The SAP interfaces the tool reads are being confirmed on a real system first; see [Roadmap](#roadmap).

## What it does

1. Reads the result of an ATC run made with the clean core check variant.
2. Reads the aggregated usage data of the system (transaction `SUSG`).
3. Joins both per custom object.
4. Reports every object with its clean core level and a proposal: **retire**, **keep** or **remediate**.

The tool is read-only. It changes no custom code and deletes nothing.

## How an object gets its level

An object takes the level of its worst clean core finding.

| Level | The custom code uses | ATC finding |
|---|---|---|
| A | Released APIs only | None |
| B | Classic APIs | Priority 3 |
| C | SAP internal objects without classification | Priority 2 |
| D | Not recommended techniques | Priority 1 |

## How the proposal is made

| | Level A or B | Level C | Level D |
|---|---|---|---|
| **Used** | Keep | Remediate | Remediate first |
| **Not used** | Retire | Retire | Retire |

This rule is a draft. *Retire* marks a candidate; the owner of the code decides.

## Requirements

- SAP S/4HANA 2023 or higher, private cloud or on-premise. The clean core ATC checks are delivered with S/4HANA 2025; on 2023 they come with SAP Note 3565942.
- An ATC result of a run with the clean core check variant (`ABAP_CLEAN_CORE_DEVELOPMENT` or your own copy).
- Usage data collected with `SCMON` and aggregated with `SUSG`.
- [abapGit](https://abapgit.org) to install.

The tool is written in Standard ABAP because it reads ATC and SUSG objects that are not released. It does not run in ABAP Cloud or in S/4HANA Cloud Public Edition. Development and testing happen on S/4HANA 2025 Private Edition.

## Installation

Not available yet. From the first release on:

- **Online:** clone this repository with abapGit into package `Z_CCR`.
- **Offline:** download the repository as ZIP and import it with an abapGit offline repository. Use this when the system cannot reach the internet.

## Design

- The join, the classification and the proposal are plain ABAP behind interfaces, covered by ABAP Unit.
- The unit tests also run off-stack in GitHub Actions, on every pull request.
- ATC and SUSG are reached through two reader interfaces with one adapter each, so the SAP internals stay in two classes.
- User interface of the first version: a classic report with ALV and Excel export.

## Roadmap

| Step | State |
|---|---|
| Probe program that confirms the ATC and SUSG interfaces on a system | In progress |
| Core logic with unit tests | Planned |
| ATC reader | Planned |
| SUSG reader | Planned |
| Report with ALV and Excel export | Planned |

## Documentation

- [Clean Core Readiness: a short guide](docs/guide.md) describes the method by hand: set up the checks, run ATC, read the result, add usage, decide.

## Contributing

Issues and pull requests are welcome. Results of the probe program from other releases are especially useful.

## License

[MIT](LICENSE). Built and maintained by [Nexform Consulting](https://github.com/Nexform).
