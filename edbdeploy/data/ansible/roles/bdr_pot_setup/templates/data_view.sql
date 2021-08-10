WITH data_chart AS
(
   SELECT cid, tbl AS table_name, metrices FROM pem.data_chart
   WHERE cid = (%(chart_id)s)::int4 AND cid>=257
),
probe_columns AS
(
    SELECT internal_name AS internal_name, display_name AS display_name
    FROM pem.probe_column, data_chart
    WHERE probe_id = (SELECT id FROM pem.probe, data_chart
        WHERE internal_name = table_name AND NOT is_graphable)
    AND internal_name = ANY(metrices)
    UNION ALL
    SELECT internal_name AS internal_name, display_name AS display_name
    FROM pem.probe_column, data_chart
    WHERE probe_id = (SELECT id FROM pem.probe, data_chart
        WHERE internal_name = table_name AND is_graphable AND pit_by_default AND NOT calculate_pit)
    AND internal_name = ANY(metrices)
    UNION ALL
    SELECT internal_name AS internal_name, display_name||'+' AS display_name
    FROM pem.probe_column, data_chart
    WHERE probe_id = (SELECT id FROM pem.probe, data_chart
        WHERE internal_name = table_name AND is_graphable AND NOT pit_by_default AND calculate_pit)
    AND internal_name = ANY(metrices)
    UNION ALL
    SELECT internal_name||'_pit' AS internal_name, display_name AS display_name
    FROM pem.probe_column, data_chart
    WHERE probe_id = (SELECT id FROM pem.probe, data_chart
        WHERE internal_name = table_name AND is_graphable AND NOT pit_by_default AND calculate_pit)
    AND internal_name = ANY(metrices)
    UNION ALL
    SELECT internal_name AS internal_name, display_name||'+' AS display_name
    FROM pem.probe_column, data_chart
    WHERE probe_id = (SELECT id FROM pem.probe, data_chart
        WHERE internal_name = table_name AND is_graphable AND NOT pit_by_default AND NOT calculate_pit)
    AND internal_name = ANY(metrices)
)
SELECT
    d.tbl, d.metrices,
    (
    SELECT
        array_agg(display_name)
    FROM
        (
        SELECT
            generate_series(
                array_lower(metrices, 1),
                array_upper(metrices, 1)
            ) as idx
        FROM
            data_chart
        ) AS FOO,
        data_chart,
        probe_columns
    WHERE metrices[idx] = internal_name
   ) AS display_labels,
   d.orderby, d.orderdir, d.glimit, d.r_sys_obj, p.applies_to_id, p.target_type_id,
   p.deleted
FROM
   pem.data_chart d
   JOIN pem.probe p ON (d.tbl = p.internal_name)
WHERE
   d.cid = (%(chart_id)s)::int4
