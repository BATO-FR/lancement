DROP VIEW IF EXISTS export;
CREATE VIEW export AS
SELECT
  osm_id,
  osm_type,
  tags->'train' AS train,
  tags->'subway' AS subway,
  tags->'tram' AS tram,
  tags->'bus' AS bus,
  tags->'highway' AS highway,
  tags->'line' AS line,
  tags->'trolleybus' AS trolleybus,
  tags->'public_transport' AS public_transport,
  tags->'amenity' AS amenity,
  tags->'name' AS name,
  tags->'ref' AS ref,
  tags->'route_ref' AS route_ref,
  tags->'uic_ref' AS uic_ref,
  tags->'uic_name' AS uic_name,
  tags->'operator' AS operator,
  tags->'railway' AS railway,
  tags->'network' AS network,
  tags->'shelter' AS shelter,
  tags->'STIF:zone' AS "STIF:zone",
  tags->'type:RATP' AS "type:RATP",
  tags->'bench' AS bench,
  tags->'tactile_paving' AS tactile_paving,
  tags->'source_date' AS source_date,
  tags->'wheelchair' AS wheelchair,
  tags->'website' AS website,
  tags->'note' AS note,
  tags->'description' AS description,
  tags->'source' AS source,
  geom,
  tags - ARRAY['train', 'subway', 'tram', 'bus', 'highway', 'line', 'trolleybus', 'public_transport', 'amenity', 'name', 'ref', 'route_ref', 'uic_ref', 'uic_name', 'operator', 'railway', 'network', 'shelter', 'STIF:zone', 'type:RATP', 'bench', 'tactile_paving', 'source_date', 'wheelchair', 'website', 'note', 'description', 'source'] AS tags,
  tstamp
FROM
((
  SELECT
    DISTINCT ON (nodes.id)
    nodes.id AS osm_id,
    CAST('n' AS TEXT) AS osm_type,
    nodes.tags,
    nodes.geom,
    nodes.tstamp
  FROM
    relations
    JOIN relation_members ON
      relations.id = relation_members.relation_id AND
      relation_members.member_type = 'N' AND
      relation_members.member_role IN ('stop', 'stop_entry_only', 'stop_exit_only', 'forward:stop', 'backward:stop')
    JOIN nodes ON
      relation_members.member_id = nodes.id AND
      nodes.tags->'public_transport' = 'stop_position'
  WHERE
    relations.tags->'type' = 'route'
) UNION (
  SELECT
    DISTINCT ON (ways.id)
    ways.id AS osm_id,
    CAST('w' AS TEXT) AS osm_type,
    ways.tags,
    way_locate(ways.linestring) AS geom,
    ways.tstamp
  FROM
    relations
    JOIN relation_members ON
      relations.id = relation_members.relation_id AND
      relation_members.member_type = 'W' AND
      relation_members.member_role IN ('stop', 'stop_entry_only', 'stop_exit_only', 'forward:stop', 'backward:stop')
    JOIN ways ON
      relation_members.member_id = ways.id AND
      ways.tags->'public_transport' = 'stop_position'
  WHERE
    relations.tags->'type' = 'route'
) UNION (
  SELECT
    nodes.id AS osm_id,
    CAST('n' AS TEXT) AS osm_type,
    nodes.tags,
    nodes.geom,
    nodes.tstamp
  FROM
    nodes
    LEFT JOIN relation_members ON
      relation_members.member_id = nodes.id AND
      relation_members.member_type = 'N'
    LEFT JOIN relations ON
      relations.id = relation_members.relation_id AND
      relations.tags->'type' = 'route'
  WHERE
    (
      nodes.tags->'highway' = 'bus_stop' OR
      nodes.tags->'railway' IN ('station', 'halt', 'tram_stop')
    )
) UNION (
  SELECT
    ways.id AS osm_id,
    CAST('w' AS TEXT) AS osm_type,
    ways.tags,
    way_locate(ways.linestring) AS geom,
    ways.tstamp
  FROM
    ways
    LEFT JOIN relation_members ON
      relation_members.member_id = ways.id AND
      relation_members.member_type = 'W'
    LEFT JOIN relations ON
      relations.id = relation_members.relation_id AND
      relations.tags->'type' = 'route'
  WHERE
    (
      ways.tags->'highway' = 'bus_stop' OR
      ways.tags->'railway' IN ('station', 'halt', 'tram_stop')
    )
)) AS t
;
