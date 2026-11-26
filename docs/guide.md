# Clean Core Readiness: a short guide

## What readiness means

A system is clean core ready when you know, for every custom object, its clean core level and whether anyone still uses it. The level comes from ATC; the usage comes from SUSG. Everything below serves those two answers.

SAP sorts custom code into four levels by what it touches in the SAP standard:

| Level | The custom code uses | ATC reports |
| --- | --- | --- |
| A | Released APIs only (ABAP Cloud) | No finding |
| B | Classic APIs that SAP has classified as such | Information, priority 3 |
| C | SAP internal objects with no classification, for example a direct read of an SAP table | Warning, priority 2 |
| D | Not recommended techniques: modifications, writes to SAP tables, objects marked noAPI | Error, priority 1 |

An object takes the level of its worst finding. The guide treats this as the working rule; see the open points.

## What you need

The checks run locally from S/4HANA 2023 upward; below that, the only route is a central ATC on SAP BTP.

| Release | Clean core checks | Check variant |
| --- | --- | --- |
| S/4HANA 2025 FPS01 and above | Delivered | `ABAP_CLEAN_CORE_DEVELOPMENT`, delivered |
| S/4HANA 2025 initial stack | Delivered | Copy `ABAP_CLOUD_DEVELOPMENT_DEFAULT` and add the four checks |
| S/4HANA 2023 | [SAP Note 3565942](https://me.sap.com/notes/3565942), including its manual steps | Copy `ABAP_CLOUD_DEVELOPMENT_DEFAULT` and add the four checks |
| Below 2023 (SAP\_BASIS below 758) | Not available locally | Central ATC on SAP BTP with `ABAP_CLEAN_CORE_READINESS` |

The four checks sit in the ATC category Clean Core: Usage of APIs, Allowed SAP enhancement technologies, Search for customer modifications, Critical statements.

Three more things must be in place before the first run:

- **Note Analyzer.** Run the analyzer files from [SAP Note 3627152](https://me.sap.com/notes/3627152) on 2023 and 2025. Without the dependent notes, findings can be incomplete while the main note looks implemented.
- **Classification file.** Usage of APIs reads SAP's list of classic APIs, `objectClassifications_SAP.json`, from the [Cloudification Repository](https://github.com/SAP/abap-atc-cr-cv-s4hc). The check parameter `classicAPIDataSource` must point to it. The check still runs when the parameter is empty, but classic APIs are then not evaluated correctly.
- **No internet from the system.** Download the file on another machine, upload it with program `SYCM_API_CLASSIFICATION_MANAGR`, and set `classicAPIDataSource` to `file(<file name>)`.

On S/4HANA 2025 the second parameter, `releasedAPIDataSource`, defaults to `checkedSystem` and needs no change.

## Run the assessment

Run ATC as a run series: it leaves a stored central result that covers many packages and can be read again later.

1. **Prove the setup on one object.** In ADT, right-click a class that calls SAP standard, then Run As, ABAP Test Cockpit With, and pick the variant. Expect at least one information or warning finding.
2. **Create the run series.** Transaction `ATC`, Runs, Schedule Runs, Create. Enter the check variant and the packages to check.
3. **Include subpackages.** The Package field selects objects assigned directly to that package. Use a pattern such as `Z_SALES*` to reach the packages below it.
4. **Leave the baseline out.** Clear Consider Baseline for an assessment run, so that earlier accepted findings are counted.
5. **Schedule and wait.** Start the series and follow it under Monitor and Control Runs.
6. **Open the result.** Runs, Manage Results, Display. Note the number of checked objects next to the findings.

Start with one small package whose content you know. Widen to all custom code only when that result looks right.

## Read the result

You derive the level from the priority of the findings; the sources show no separate field for it in the result.

1. Keep only the findings of the four clean core checks. The variant also carries the general ABAP Cloud checks, and their findings say nothing about the level.
2. Group the findings by custom object.
3. Take the highest priority per object: priority 1 gives D, priority 2 gives C, priority 3 gives B.
4. An object that was checked and has no clean core finding is A.

Two totals describe the system: the number of objects per level, and the same count for objects in use. The second one is the number that matters for planning.

Read a few findings by hand before trusting the totals. A call to a BAPI that SAP lists as classic API should show as information, a `SELECT` on an SAP table as warning, an `UPDATE` on an SAP table as error.

## Add usage and decide

A level alone does not say what to do; unused code is retired, not remediated.

Usage comes from transaction `SUSG`, which aggregates the call records of the ABAP Call Monitor (`SCMON`) in the production system. Two conditions apply:

- It must have been collecting long enough to cover a full business year, year-end closing included. Shorter periods mark periodic programs as unused.
- The data lives in production, the ATC result usually in development. Bring the usage data to the system where you assess.

Join usage and level per object, then apply one rule:

|  | Level A or B | Level C | Level D |
| --- | --- | --- | --- |
| **Used** | Keep | Remediate | Remediate first |
| **Not used** | Retire | Retire | Retire |

This rule is the proposal of this project, not an SAP rule. Treat Retire as a candidate list: confirm with the owner before anything is deleted.

## Pitfalls

A result with zero findings on classic code usually means nothing was checked, not that the code is clean.

| What you see | Likely cause | What to check |
| --- | --- | --- |
| 0 findings, 0 checked objects | The namespace is not checkable in this system | Role of the namespace in `SE03`, Display/Change Namespaces |
| 0 findings, 0 checked objects | The code sits in subpackages | Use a package pattern in the run series |
| Findings in ADT, none in the run | A baseline hides them | Clear Consider Baseline |
| Errors only, or no information findings | The classification file is not read | `classicAPIDataSource` in the Usage of APIs check |
| Priority 1 on data elements and domains | The old three-tier checks are still in the variant | Rebuild the variant from the four clean core checks |
| Findings look incomplete | Dependent notes are missing | Rerun the Note Analyzer, also after each support package |

## Open points

On a system, only the delivered variant and the run series screen have been seen so far; the rest of this guide rests on SAP and community sources. These points decide the method and are still marked verify:

- [ ] The ATC result has no field for the clean core level, so priority is the only carrier.
- [ ] Priority 1, 2 and 3 map to D, C and B for all four checks, not only for Usage of APIs.
- [ ] SUSG keeps usage per procedure (method, function module) and not only per program.
- [ ] How SUSG data from production reaches the assessment system: snapshot, export or remote API.
- [ ] The menu names in transaction `ATC` on S/4HANA 2025.
- [ ] Whether the delivered variant lets you change `classicAPIDataSource`, or a copy is needed.
- [ ] Which namespaces a system treats as checkable.

## Sources

Opened and read:

- [Configuring the ABAP Test Cockpit and Transport Gate in SAP S/4HANA](https://blog.sap-press.com/configuring-the-abap-test-cockpit-and-transport-gate-in-sap-s4hana), SAP PRESS: notes, check parameters, offline upload, priority per level.
- [SAP/abap-atc-cr-cv-s4hc](https://github.com/SAP/abap-atc-cr-cv-s4hc), SAP on GitHub: the classification files and the notes they need.

- [ABAP test cockpit (ATC) recommendations for governance of clean core ABAP development](https://community.sap.com/t5/technology-blog-posts-by-sap/abap-test-cockpit-atc-recommendations-for-governance-of-clean-core-abap/ba-p/14186130), SAP: the four checks, the delivered variant, the message type per kind of usage.
- [Project Kernseife](https://community.sap.com/t5/technology-blog-posts-by-sap/project-kernseife-improving-the-measurement-of-clean-core-in-abap/ba-p/14099819), SAP: when the check and the levels were released.
- [How Komatsu Accelerated S/4HANA 2023 with Clean Core](https://community.sap.com/t5/enterprise-resource-planning-blog-posts-by-members/how-komatsu-accelerated-s-4hana-2023-with-clean-core-and-sap-joule-for/ba-p/14496577), community: building the variant by hand on 2023.
- [SAP KBA 3781882](https://userapps.support.sap.com/sap/support/knowledge/en/3781882) and [SAP KBA 3703713](https://userapps.support.sap.com/sap/support/knowledge/en/3703713): the variant on SAP\_BASIS 816, and the lower limit of SAP\_BASIS 758.
- [Aggregate usage data in your production system with SUSG transaction](https://blogs.sap.com/2019/02/27/aggregate-usage-data-in-your-production-system-with-susg-transaction/), SAP: what SUSG collects and how it is read.
