# BidNile Database Assignment — Notes

## 1. The 4 Schemas, Their Tables, and Why

* **`Accounts`** (`City`, `Member`, `Wallet`): Groups user identity, geographic location, and personal financial balances together.
* **`Operations`** (`Warehouse`): Isolates physical logistics, storage facilities, and staff management.
* **`Catalog`** (`Category`, `Item`, `ItemPhoto`): Holds everything related to merchandise classification, item listings, and media assets.
* **`Sales`** (`Auction`, `Bid`, `AuctionFollow` — later moved to `Marketing` in Task 3.12): Separates live commercial activity, bidding transactions, and auction engagement from static catalog data.

Grouping tables into domain-driven schemas avoids cluttering `dbo`, clarifies business boundaries, and allows granular security permissions per team.

---

## 2. Relationship Types and How They Were Mapped

* **1:1 (`Member` ↔ `Wallet`):** Mapped using a shared primary key — `Wallet.MemberId` is both the `PK` and a `FK` referencing `Accounts.Member(MemberId)`, ensuring one wallet per member and no shared wallets.
* **1:N (e.g., `City` → `Member`, `Category` → `Item`, `Item` → `Auction`):** Mapped by placing the parent's `PK` as a `FK` column in the child ("many") table.
* **M:N (`Member` ↔ `Auction` via `AuctionFollow`):** Resolved into a junction table (`Sales.AuctionFollow`, later `Marketing.AuctionFollow`) with a composite `PK (MemberId, AuctionId)` and two `FK`s referencing `Member` and `Auction`, preventing duplicate follows.
* **Recursive (Self-Referencing):**
  * `Accounts.Member.ReferredByMemberId` references `Accounts.Member(MemberId)` to track member invitations.
  * `Catalog.Category.ParentCategoryId` references `Catalog.Category(CategoryId)` to form the category hierarchy tree.
* **Circular (`Member` ↔ `Warehouse`):** `Accounts.Member.WarehouseId` references `Operations.Warehouse(WarehouseId)` (employee's workplace), while `Operations.Warehouse.ManagerId` (with a `UNIQUE` constraint) references `Accounts.Member(MemberId)` (warehouse manager).
* **Weak Entity (`ItemPhoto`):** Depends entirely on `Catalog.Item`. Mapped with a composite `PK (ItemId, Position)` and a `FK` to `Catalog.Item(ItemId)` configured with `ON DELETE CASCADE` so photos disappear when their item is deleted.

---

## 3. Data Type Justifications

* **`UNIQUEIDENTIFIER` (GUID) for `Member`:** Member IDs are generated offline on mobile devices before requests hit the server, so sequential numbers cannot work. GUIDs guarantee global uniqueness across distributed clients without server coordination.
* **`BIGINT` for `Bid`:** Bid volume is expected to exceed 2.1 billion (the max limit of a 32-bit `INT`, which is 2,147,483,647) within a few years. `BIGINT` handles up to $9.22 \times 10^{18}$ while remaining compact and fast for indexing.
* **`FLOAT` for GPS vs. `DECIMAL` for Money:** GPS coordinates are approximate scientific measurements with many decimal places where binary floating-point rounding is acceptable. Money requires exact base-10 precision (`DECIMAL(12, 2)`) because even tiny floating-point rounding errors are unacceptable in financial balances and bids.
* **`DATETIMEOFFSET` for `Auction`:** BidNile operates across multiple time zones (Cairo `+02:00`, Riyadh `+03:00`, Dubai `+04:00`). `DATETIMEOFFSET` preserves the exact local time and UTC offset so auction start/end times are unambiguous for all users.

---

## 4. Why the Circular Relationship Cannot Be Created Inside `CREATE TABLE`

In a circular relationship (`Member` references `Warehouse` and `Warehouse` references `Member`), whichever table is created first cannot declare a `FOREIGN KEY` referencing the second table because the second table does not exist yet in the database catalog. Both tables must be created first, and at least one (or both) `FK` constraints must be added afterward using `ALTER TABLE ... ADD CONSTRAINT`.

---

## 5. Table Population Order and Why

Because Foreign Key constraints are active, parent tables must be populated before child tables:

1. **`Accounts.City`** — No FK dependencies.
2. **`Accounts.Member`** — Depends on `City` (and self-references earlier members for `ReferredByMemberId`). `WarehouseId` is initially left `NULL` to break the circular dependency.
3. **`Accounts.Wallet`** — Depends on `Member`.
4. **`Operations.Warehouse`** — Depends on `City` and `Member` (`ManagerId`). *(After inserting warehouses, employee rows in `Accounts.Member` are updated with their `WarehouseId`.)*
5. **`Catalog.Category`** — Self-referencing; top-level categories (`ParentCategoryId = NULL`) are inserted before sub-categories.
6. **`Catalog.Item`** — Depends on `Member` (`SellerId`, `InspectorId`), `Category`, and `Warehouse`.
7. **`Catalog.ItemPhoto`** — Depends on `Item`.
8. **`Sales.Auction`** — Depends on `Item`.
9. **`Sales.Bid`** — Depends on `Auction` and `Member`.
10. **`Marketing.AuctionFollow`** — Depends on `Member` and `Auction`.

---

## 6. Errors in Tasks 3.6 and 3.11 (and 3.4) and How They Were Fixed

* **Task 3.4 (`sp_rename` on `Capacity`) & Task 3.6 (`ALTER COLUMN MaxItems` to `SMALLINT`):**
  * **Error:** SQL Server blocks renaming a column or changing its data type when a `CHECK` constraint (`CK_Warehouse_Capacity` / `CK_Warehouse_MaxItems`) depends on it (enforced dependency).
  * **Fix:** Drop the `CHECK` constraint first (`ALTER TABLE ... DROP CONSTRAINT`), execute the rename / `ALTER COLUMN`, and then re-add the `CHECK (MaxItems > 0)` constraint.
* **Task 3.11 (`DROP COLUMN IsVerified`):**
  * **Error:** SQL Server refuses to drop `IsVerified` because the `DEFAULT` constraint `DF_Member_IsVerified` is bound to it.
  * **Fix:** Drop the default constraint first (`ALTER TABLE Accounts.Member DROP CONSTRAINT DF_Member_IsVerified`), then drop the `IsVerified` column.

---

## 7. Hand Trace for Task 5 — LeetCode 238 (`[1, 2, 3, 4]`)

For `nums = [1, 2, 3, 4]`:

* `prefix[i]` = product of all elements to the **left** of index `i` (starts at `1` for `i = 0`).
* `suffix[i]` = product of all elements to the **right** of index `i` (starts at `1` for `i = n - 1`).
* `result[i] = prefix[i] * suffix[i]`.

| Index (`i`) | `nums[i]` | `prefix[i]` | `suffix[i]` | `result[i] = prefix[i] * suffix[i]` |
| :---: | :---: | :---: | :---: | :---: |
| **0** | `1` | `1` | `24` (`2 * 3 * 4`) | **`24`** |
| **1** | `2` | `1` (`1`) | `12` (`3 * 4`) | **`12`** |
| **2** | `3` | `2` (`1 * 2`) | `4` (`4`) | **`8`** |
| **3** | `4` | `6` (`1 * 2 * 3`) | `1` | **`6`** |

**Final Output:** `[24, 12, 8, 6]`