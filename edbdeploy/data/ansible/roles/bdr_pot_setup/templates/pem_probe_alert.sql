BEGIN;

UPDATE
    pem.probe
SET
    enabled_by_default = TRUE
WHERE
    internal_name NOT IN ('slony_replication', 'xdb_smr_mmr_replication', 'sql_protect')
    AND target_type_id = 200
    AND enabled_by_default = FALSE;

UPDATE
    pem.alert a
SET
    enabled = FALSE
FROM
    pem.alert_template t
WHERE
    a.template_id = t.id
    AND (t.display_name ~ '^Last'
        OR t.display_name ~ '^Largest index'
        OR t.display_name = 'Database size in server'
        OR t.display_name ~ 'Alert Errors')
    AND t.is_auto_create = TRUE
    AND a.enabled;

UPDATE pem.probe
SET    probe_code = $SQL$
SELECT node_group_name,
       origin_name,
       target_name,
       slot_name,
       active,
       state,
       (extract(epoch FROM (
       CASE
              WHEN write_lag = '' THEN '00:00:00'
              ELSE write_lag
       END)::interval))::DECIMAL AS write_lag,
       (extract(epoch FROM (
       CASE
              WHEN flush_lag = '' THEN '00:00:00'
              ELSE flush_lag
       END)::interval))::DECIMAL AS flush_lag,
       (extract(epoch FROM (
       CASE
              WHEN replay_lag = '' THEN '00:00:00'
              ELSE replay_lag
       END)::interval))::DECIMAL AS replay_lag,
       sent_lag_bytes::NUMERIC,
       write_lag_bytes::NUMERIC,
       flush_lag_bytes::NUMERIC,
       replay_lag_bytes::NUMERIC
FROM   bdr.group_replslots_details
WHERE  slot_name != '';$SQL$
WHERE internal_name = 'bdr_group_replslots_details';

UPDATE pem.probe
SET    enabled_by_default = FALSE
WHERE  internal_name IN ( 'efm_cluster_node_status',
                          'bdr_node_replication_rates',
                          'efm_cluster_info');
UPDATE pem.alert
SET    enabled = FALSE
WHERE  template_id IN (SELECT id
                       FROM   pem.alert_template
                       WHERE  display_name ~* '^connections in idle state');

UPDATE pem.server_option
SET username = '{{ pg_owner }}'
WHERE server_id = 1;
END;
