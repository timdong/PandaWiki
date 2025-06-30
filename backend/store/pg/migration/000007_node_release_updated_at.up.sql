-- add updated_at to node_releases (with existence check)
ALTER TABLE node_releases ADD COLUMN IF NOT EXISTS updated_at timestamptz NULL;

-- update existing node_releases (only if column was just added or is null)
UPDATE node_releases SET updated_at = created_at WHERE updated_at IS NULL;
