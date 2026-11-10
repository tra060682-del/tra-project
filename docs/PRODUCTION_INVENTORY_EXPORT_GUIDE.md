# Production inventory export guide

## Purpose

`supabase/production_schema_complete_export.sql` is a read-only Supabase PostgreSQL inventory query. It returns exactly one result grid with four columns:

```text
section,object_schema,object_name,details
```

Complex metadata is encoded as JSON text in `details`. The query does not create temporary tables, functions, views, or other database objects and does not modify records.

## Run and export

1. Open the production project in the Supabase SQL Editor using the normal administrative context.
2. Create a new query and paste the complete contents of `supabase/production_schema_complete_export.sql`.
3. Confirm the editor contains only that query. Do not combine it with a migration.
4. Run the query once.
5. Confirm exactly one result grid appears and its headers are `section`, `object_schema`, `object_name`, and `details`.
6. Export that grid as CSV.
7. Save it at exactly:

   ```text
   docs/database-inventory/tra_production_full_inventory.csv
   ```

8. Check the actual filename in PowerShell or File Explorer with extensions visible. It must not end in `.csv.csv`.

## Expected sections

The CSV must contain these section values:

- `column`
- `primary_key_constraint`
- `unique_constraint`
- `foreign_key_constraint`
- `check_constraint`
- `index`
- `rls_table`
- `rls_policy`
- `trigger`
- `function`
- `enum`
- `table_grant`
- `column_grant`
- `function_grant`
- `object_catalog`
- `data_quality`
- `export_manifest`

The export always includes one `export_manifest` row for each expected metadata section. Its JSON details include `row_count`, `empty`, and `expected`. A section with no production rows is represented by an `__no_rows__` placeholder, so an empty but successfully queried section cannot be mistaken for a broken export.

## Validate before handing off

Run `supabase/validate_production_schema_complete_export.sql` separately. It is also read-only and returns one grid of source row counts. A zero count is permitted and means the complete export will contain an `__no_rows__` placeholder for that section.

Then inspect the exported CSV:

1. The first line must be:

   ```text
   section,object_schema,object_name,details
   ```

2. Filter `section` to `export_manifest` and confirm there is one manifest row for every expected section except `export_manifest` itself.
3. Confirm each manifest row has `"expected": true`.
4. Confirm the seven relevant production tables, including `artist_profiles`, appear under `rls_table` and `object_catalog`.
5. Confirm `auth.users` triggers appear under `trigger` when production has Auth provisioning triggers.
6. Do not edit JSON details in a spreadsheet before committing the inventory file.

## Safety

Both SQL scripts are SELECT/CTE-only. They read PostgreSQL catalogs, `information_schema`, the six relevant public tables for count-only integrity checks, and `auth.users` only for orphan counts. They return no email addresses, profile values, legal document bodies, or other row contents.
