# BidNile Online Auctions — Database Design & SQL Server DDL

## Student Information
* **Name:**[Shams Ashraf Ali]
* **Group / ID:** [3]
* **Track:** Backend .NET — Simulation Academy (.NET Diploma Cycle 1)

---

## Project Overview
This repository contains the relational database design, SQL Server DDL scripts (`CREATE` & `ALTER`), sample dataset (populated via SSMS Wizard), and DSA solution for **BidNile Online Auctions**.

---

## Repository Structure

```text
├── docs/
│   ├── mapping.png             # Task 1: Relational schema mapping across 4 logical schemas
│   ├── erd.png                 # Bonus: Entity-Relationship Diagram (if included)
│   └── screenshots/            # Tasks 4 & 5: Constraint violation errors & LeetCode Accepted screenshot
├── database/
│   ├── BidNile.sql             # Tasks 2 & 3: Full CREATE + 12 ALTER statements (runs top-to-bottom with F5)
│   └── BidNile_Data.sql        # Task 4: Exported sample data (Data only) via SSMS Generate Scripts
├── dsa/
│   └── ProductExceptSelf.cs    # Task 5: LeetCode 238 (Prefix/Suffix arrays + O(1) space follow-up)
├── NOTES.md                    # Section 03: Design decisions, error fixes, and hand trace
└── README.md