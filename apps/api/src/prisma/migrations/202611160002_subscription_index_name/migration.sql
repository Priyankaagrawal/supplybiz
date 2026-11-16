-- Keep the applied T-072 migration intact; PostgreSQL truncated its 65-character name.
ALTER INDEX subscription_revisions_subscription_id_effective_from_version_i
 RENAME TO subscription_revisions_effective_idx;
