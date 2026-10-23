Update the existing Validation Master Flat JSON in place.

Add or update a field named development_status for each record.

Allowed statuses, in lifecycle order:

1. not_started
2. developing
3. developed
4. testing
5. dev_portfolio
6. prod_portfolio

For this update:

* Record IDs: 1, 19, 20, 21, 22, 23
* Set development_status to developed.

Requirements:

* Match records using record_id, not array position.
* For unnumbered continuation rows, inherit the status of their parent_record_id.
* For other records without an existing status, initialize development_status to null (unknown), not not_started.
* Preserve all existing data fields, values, and record ordering.
* Do not modify any other fields or create a separate status tracker.
* Validate that all requested record IDs exist.
* Create a backup before updating the existing JSON.
* Save the updated JSON and confirm the changed record IDs and their new statuses.

For future updates, accept a list of record IDs and one target status, and apply only that status change without rebuilding the dataset.