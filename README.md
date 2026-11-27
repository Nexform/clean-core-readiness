# Clean Core Readiness

Open-source ABAP tool that shows where the custom code of an SAP S/4HANA system stands on the clean core levels A–D, and which of that code is still in use.

> **Status: release candidate 0.1.** All parts run on S/4HANA 2025 Private Edition and are being tested on that system before the release. See [Limits of version 0.1](#limits-of-version-01).

## What it does

1. Reads the result of an ATC run made with the clean core check variant.
2. Reads the aggregated usage data of the system (transaction `SUSG`).
3. Joins both per custom object.
4. Reports every object with its clean core level and a proposal: **keep**, **remediate** or **retire**.

The tool is read-only. It changes no custom code and deletes nothing.

## How an object gets its level

The level comes from the ATC check "Usage of APIs" (`CL_YCM_CC_CHECK_API_USAGE`) and the message kind of its findings. The priority number is not used: it is configurable, and the clean core variant also holds checks that have nothing to do with the level.

| Level | The custom code uses | Finding of "Usage of APIs" |
|---|---|---|
| A | Released APIs only | None |
| B | Classic or deprecated APIs | Note (kind N) |
| C | SAP internal objects, direct reads of SAP tables, `SUBMIT` | Warning (kind W) |
| D | APIs that must not be used, writes to SAP tables, `PERFORM` in SAP programs | Error (kind E) |

An object takes the level of its worst finding. An object of the selected packages without any such finding is level A. Technical messages of the check (for example "object usage found") do not count.

## How the proposal is made

| | Level A or B | Level C | Level D |
|---|---|---|---|
| **Used** | Keep | Remediate | Remediate first |
| **Usage unknown** | Keep | Remediate | Remediate first |
| **Not used** | Retire | Retire | Retire |

SUSG measures classes, function groups and programs. Every other object (CDS views, behavior definitions, interfaces, enhancements) has usage "unknown" and is never proposed for retirement.

This rule is the proposal of this project, not an SAP rule. *Retire* marks a candidate; the owner of the code decides.

## Requirements

- SAP S/4HANA 2023 or higher, private cloud or on-premise, on SAP HANA. The clean core ATC checks are delivered with S/4HANA 2025; on 2023 they come with SAP Note 3565942.
- An ATC result of a run with the clean core check variant (`ABAP_CLEAN_CORE_DEVELOPMENT` or your own copy).
- Usage data collected with `SCMON` and aggregated with `SUSG`, best imported from the production system.
- [abapGit](https://abapgit.org) to install.

The tool is written in Standard ABAP because it reads ATC and SUSG objects that are not released. It does not run in ABAP Cloud or in S/4HANA Cloud Public Edition. Development and testing happen on S/4HANA 2025 Private Edition.

## Installation

- **Online:** clone this repository with abapGit into package `Z_CCR`.
- **Offline:** download the repository as ZIP (Code, Download ZIP) and import it into an abapGit offline repository for package `Z_CCR`. Use this when the system cannot reach the internet.

Then activate the objects. The package `Z_CCR_CORE` holds the logic and its ABAP Unit tests; run them once (in ADT: Run As, ABAP Unit Test on the package) to see that the installation is complete.

## Usage

Run the report `Z_CCR_READINESS`.

No ATC run yet? The two buttons at the top of the selection screen help: **How to run ATC** lists the steps to create a run series with the clean core variant, and **Open transaction ATC** goes there. The report itself starts no ATC run.

| Field | What to enter |
|---|---|
| Check variant | The variant of the ATC run, default `ABAP_CLEAN_CORE_DEVELOPMENT` |
| ATC run | F4 lists the complete runs of that variant with title, run series and time |
| Packages of the run | The packages the ATC run checked; their subpackages are included |
| Object types | Default CLAS, INTF, PROG, FUGR, DDLS, BDEF, ENHO. Other types carry no code and would all be level A |
| Usage data set | F4 lists the usage data sets of `SUSG` with system and period |

ATC run, packages and usage data set are required; the report says so when one is missing.

The ALV list shows one row per object: type, name, level, findings per level (B, C, D), usage state, executions, last use and proposal. Above the list: the ATC run and the period of the usage data. Export the list with the ALV toolbar (Export, Spreadsheet).

How to run ATC with the clean core variant and how to read the result by hand: [Clean Core Readiness: a short guide](docs/guide.md).

## Limits of version 0.1

- Only the check "Usage of APIs" decides the level. The other three clean core checks (allowed enhancement technologies, customer modifications, critical statements) are not counted yet: their check classes could not be confirmed on the test system.
- An ATC result does not list the objects it checked. The report takes the objects of the packages and object types you enter; they are the scope, and findings of objects outside them are left out. Enter the packages of the ATC run, or a part of them to assess that part.
- *Retire* is proposed per object. Some objects cannot be retired alone, for example the behavior pool class of a RAP business object, which belongs to its behavior definition. Check such candidates with their parent object.
- Local usage data of a development system says little about production. Use usage data imported from production, covering a full business year.
- Exempted ATC findings: not yet confirmed whether they are left out.

## Design

- The classification and the proposal are plain ABAP behind interfaces, covered by ABAP Unit (package `Z_CCR_CORE`). The unit tests also run off-stack in GitHub Actions, on every pull request.
- ATC and SUSG are reached through two reader interfaces with one adapter each (`ZCL_CCR_ATC_READER`, `ZCL_CCR_USAGE_READER`), so the SAP internals stay in two classes. Every SAP table and API they use was first confirmed on a system with the probe program in [`probes/`](probes).
- User interface: the classic report `Z_CCR_READINESS` with ALV.

## Roadmap

| Step | State |
|---|---|
| Probe program that confirms the ATC and SUSG interfaces on a system | Done |
| Core logic with unit tests | Done |
| ATC reader | Done |
| SUSG reader | Done |
| Report with ALV and spreadsheet export | Done |
| System test and release 0.1 | In progress |
| Start an ATC run from the report | Planned |
| The other three clean core checks | Planned |

## Contributing

Issues and pull requests are welcome. Results of the probe program from other releases are especially useful.

## License

[MIT](LICENSE). Built and maintained by [Nexform Consulting](https://github.com/Nexform).
