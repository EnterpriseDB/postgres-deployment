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
SET    enabled_by_default = FALSE
WHERE  internal_name ~* '^bdr';

UPDATE pem.alert
SET enabled = FALSE
WHERE  template_id IN (SELECT id
                       FROM  pem.alert_template
                       WHERE display_name ~* '^BDR'
                             OR
                             display_name ~* '^connections in idle state');

UPDATE pem.server_option
SET username = '{{ pg_owner }}'
WHERE server_id = 1;

UPDATE
   pem.server
   SET description = split_part(description,':',1);
END;
