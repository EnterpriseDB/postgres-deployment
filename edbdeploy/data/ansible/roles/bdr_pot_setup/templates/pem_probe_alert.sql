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

UPDATE pem.probe
SET probe_code = $SQL$SELECT node_name,
       node_group_name,
       peer_state_name,
       peer_target_state_name,
       (SELECT ARRAY_AGG(set_name)
        FROM   bdr.replication_set) AS sub_repsets
FROM   bdr.node_summary;$SQL$
WHERE internal_name = 'bdr_node_summary';

UPDATE pem.probe
SET probe_code = $SQL$SELECT node_name,
       postgres_version,
       bdr_version AS pglogical_version,
       bdr_version,
       bdr_edition
FROM   bdr.group_versions_details;$SQL$
WHERE internal_name = 'bdr_group_versions_details';

UPDATE pem.probe
SET probe_code = $SQL$SELECT     werr.werr_worker_pid AS worker_pid,
           bs.node_group_name,
           bs.origin_name,
           bs.source_name,
           bs.target_name,
           bs.sub_name,
           werr.werr_worker_role                  AS worker_role,
           wrn.rolname                            AS worker_role_name,
           werr.werr_time                         AS error_time,
           Age(CURRENT_TIMESTAMP, werr.werr_time) AS error_age,
           werr.werr_message                      AS error_message,
           werr.werr_context                      AS error_context_message,
           werr.werr_remoterelid                  AS remoterelid,
           bs.sub_id                              AS subwriter_id,
           bs.sub_name                            AS subwriter_name
FROM       bdr.worker_error werr
LEFT JOIN  bdr.subscription_summary bs
ON         werr.werr_subid = bs.sub_id
CROSS JOIN lateral bdr.worker_role_id_name(werr.werr_worker_role) wrn(rolname);$SQL$
WHERE internal_name = 'bdr_worker_errors';

UPDATE pem.probe
SET probe_code = $SQL$SELECT node_name,
       camo_partner AS camo_partner_of,
       node_name    AS camo_origin_for,
       is_camo_partner_connected,
       is_camo_partner_ready,
       camo_transactions_resolved,
       apply_lsn,
       receive_lsn,
       apply_queue_size
FROM   bdr.group_camo_details;$SQL$
WHERE intenal_name = 'bdr_group_camo_details';

UPDATE pem.alert
SET    enabled = FALSE
WHERE  template_id IN (SELECT id
                       FROM   pem.alert_template
                       WHERE  display_name ~* '^connections in idle state');

UPDATE pem.server_option
SET username = '{{ pg_owner }}'
WHERE server_id = 1;

UPDATE pem.probe
SET default_lifetime = 5
WHERE display_name ~* '^BDR'
 AND display_name != 'BDR Conflict History Summary';;

END;
