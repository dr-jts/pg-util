WITH input AS (
  SELECT 'MULTIPOINT ((50 50), (50 120), (100 100), (130 70), (130 150), (70 160), (160 110), (70 80))'::geometry geom
),
result AS (
  SELECT (ST_Dump( ST_DelaunayTriangles( geom ) )).geom AS geom FROM input
)
SELECT svgDoc(
  array_agg( svgPath( geom ) ),
  ST_Expand( ST_Extent(geom), 5),
  style => svgStyleProp('stroke', '#0000ff',
        'stroke-width', 1::text,
        'fill', '#a0a0ff',
        'stroke-linejoin', 'round' )
  ) AS svg FROM result;
