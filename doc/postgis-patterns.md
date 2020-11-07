# PostGIS Patterns #

A collection of interesting PostGIS patterns / solutions / problems.


## Query - Point in Polygon
### Find polygon containing points
https://gis.stackexchange.com/questions/354319/how-to-extract-attributes-of-polygons-at-specific-points-into-new-point-layer-in

Solution
A simple query to do this is:
```
SELECT pt.id, poly.*
  FROM grid pt
  JOIN polygons poly ON ST_Intersects(poly.geom, pt.geom);
```
Caveat: this will return multiple records if a point lies in multiple polygons. To ensure only a single record is returned per point, and also to include points which do not lie in any polygon, use:
```
SELECT pt.id, poly.*
  FROM grid pt
  LEFT OUTER JOIN LATERAL 
    (SELECT * FROM polygons poly 
       WHERE ST_Intersects(poly.geom, pt.geom) LIMIT 1) AS poly ON true;
```

### Count kinds of Points in Polygons
https://gis.stackexchange.com/questions/356976/postgis-count-number-of-points-by-name-within-distinct-polygons
```
SELECT
  polyname,
  count(pid) FILTER (WHERE pid='w') AS "w",
  count(pid) FILTER (WHERE pid='x') AS "x",
  count(pid) FILTER (WHERE pid='y') AS "y",
  count(pid) FILTER (WHERE pid='z') AS "z"
FROM polygons
    LEFT JOIN points ON st_intersects(points.geom, polygons.geom)
GROUP BY polyname;
```
### Optimizing Point-in-Polygon query
https://gis.stackexchange.com/questions/83615/optimizing-st-within-query-to-count-lightning-occurrences-inside-country

### Find smallest polygon containing point
https://gis.stackexchange.com/questions/220313/point-within-a-polygon-within-another-polygon
#### Solution
Choose containing polygon with smallest area 
```
SELECT DISTINCT ON (compequip.id), compequip.*, a.*
FROM compequip
LEFT JOIN a
ON ST_within(compequip.geom, a.geom)
ORDER BY compequip.id, ST_Area(a.geom)
```
### Finding points NOT in Polygons
https://gis.stackexchange.com/questions/139880/postgis-st-within-or-st-disjoint-performance-issues?rq=1

https://gis.stackexchange.com/questions/26156/updating-attribute-values-of-points-outside-area-using-postgis

https://gis.stackexchange.com/questions/313517/postgresql-postgis-spatial-join-but-keep-all-features-that-dont-intersect?rq=1

This is not PiP, but the solution of using NOT EXISTS might be applicable?

https://gis.stackexchange.com/questions/162651/looking-for-boolean-intersection-of-small-table-with-huge-table

### Finding highest point in polygons
Given 2 tables:

* `obstacles` (point layer) with a column height_m (INTEGER) 
  * has obstacles all over the map
* `polyobstacles` (polygon layer)
  * has some polygons containing some of the obstacle points.

Select the highest obstacle in each polygon. If there are several points with the same highest height a random obstacle of those highest shall be selected.

#### Solution - JOIN LATERAL
```
SELECT poly.id, obs_max.*
FROM polyobstacle poly 
JOIN LATERAL (SELECT * FROM obstacles o
  WHERE ST_Contains(poly.geom, o.geom) 
 ORDER BY height_m LIMIT 1
  ) AS obs_max ON true;
```
#### Solution - DISTINCT ON
Do a spatial join between polygon and points and use `DISTINCT ON (poly.id) poly.id, o.height` etc.

#### Solution - ARRAY_AGG
```
select p.id, (array_agg(o.id order by height_m))[1] as heighest_id
from polyobstacles p join obstacles o on st_contains(p.geom, o.geom)
group by p.id;
```
### Find polygon containing point
Basic query - with tables of address points and US census blocks, find state for each point
Discusses required indexes, and external parallelization
https://lists.osgeo.org/pipermail/postgis-users/2020-May/044161.html

### Count Points in Polygons with two Point tables
https://gis.stackexchange.com/questions/377741/find-count-of-multiple-tables-that-st-intersect-a-main-table
```
SELECT  ply.polyname, SUM(pnt1.cnt) AS pointtable1count, SUM(pnt2.cnt) AS pointtable2count
FROM    polytable AS ply,
        LATERAL (
          SELECT COUNT(pt.*) AS cnt
          FROM   pointtable1 AS pt
          WHERE  ST_Intersects(ply.geom, pt.geom)
        ) AS pnt1,
        LATERAL (
          SELECT COUNT(c.*) AS cnt
          FROM   pointtable2 AS pt
          WHERE  ST_Intersects(ply.geom, pt.geom)
        ) AS pnt2
GROUP BY 1;
```


## Query - Lines

### Find lines which have a given angle of incidence
https://gis.stackexchange.com/questions/134244/query-road-shape?noredirect=1&lq=1

### Find Line Intersections
https://gis.stackexchange.com/questions/20835/identifying-road-intersections-using-postgis?rq=1

### Find Lines which intersect N Polygons
https://gis.stackexchange.com/questions/349994/st-intersects-with-multiple-geometries

Solution
Straightforward and nice application of counting using HAVING clause
SQL given is not general but should generalize easily
```
SELECT lines.id, lines.geom 
FROM lines
 JOIN polygons ON st_intersects(lines.geom,polygons.geom)
WHERE polygons.id in (1,2)
GROUP BY lines.id, lines.geom 
HAVING count(*) = 2;
```
### Count number of intersections between line segments
https://gis.stackexchange.com/questions/365575/counting-geometry-intersections-between-two-linestrings
### Find Begin/End of circular sublines
https://gis.stackexchange.com/questions/206815/seeking-algorithm-to-detect-circling-and-beginning-and-end-of-circle

### Find Longest Line Segment
https://gis.stackexchange.com/questions/359825/get-the-maximum-distance-between-two-consecutive-points-in-a-linestring

### Find non-monotonic Z ordinates in a LineString
https://gis.stackexchange.com/questions/374459/postgis-validate-the-z-continuity

Assuming the LineStrings are digitized in the correct order (start point is most elevated), running
```
SELECT ln_id,
       vtx_id,
       geom
FROM   (
  SELECT ln.<id> AS ln_id,
         dmp.path[1] AS vtx_id,
         dmp.geom,
         ST_Z(dmp.geom) < LAG(ST_Z(dmp.geom)) OVER(PARTITION BY ln.<id> ORDER BY dmp.path[1]) AS is_valid
  FROM   <lines> AS ln,
         LATERAL ST_DumpPoints(ln.geom) AS dmp
) q
WHERE NOT is_valid;
```
returns all vertices geom, their respective line <id>, and their position in the vertices array of that line, for all vertices with higher Z value as their predecessor.
## Query - Polygons
### Find polygons intersecting other table of polygons using ST_Subdivide
https://gis.stackexchange.com/questions/224138/postgis-st-intersects-vs-arcgis-select-by-location
## Query - Intersection
### Find geometries in a table which do NOT intersect another table
https://gis.stackexchange.com/questions/162651/looking-for-boolean-intersection-of-small-table-with-huge-table

Use NOT EXISTS:
```
SELECT * FROM polygons
WHERE NOT EXISTS (SELECT 1 FROM streets WHERE ST_Intersects(polygons.geom, streets.geom))
## Query - Spatial Relationship

### Find Polygons not contained by other Polygons
https://gis.stackexchange.com/questions/185308/find-polygons-that-does-not-contain-any-polygons-with-postgis?rq=1
Solution
Uses the LEFT JOIN on ST_Contains with NULL result pattern

### Find Polygons not contained by union of other Polygons
https://gis.stackexchange.com/questions/313039/find-what-polygons-are-not-fully-covered-by-union-of-polygons-from-another-layer?rq=1

### FInd Polygons that are islands
https://gis.stackexchange.com/questions/291824/determine-if-a-polygon-is-not-enclosed-by-other-polygons


### Find polygons not surrounded by other polygons in a coverage
https://gis.stackexchange.com/questions/291824/determine-if-a-polygon-is-not-enclosed-by-other-polygons

Solution
Find polygons with total length of intersection with others is less than length of boundary

A couple of others as well.
```
SELECT a.id
FROM my_data a 
INNER JOIN my_data b ON (ST_Intersects(a.geom, b.geom) AND a.id != b.id) 
GROUP BY a.id
HAVING 1e-6 > 
  abs(ST_Length(ST_ExteriorRing(a.geom)) - 
  sum(ST_Length(ST_Intersection(ST_Exteriorring(a.geom), ST_ExteriorRing(b.geom)))));
```
### Find Polygons covered by a set of other polygons
https://gis.stackexchange.com/questions/212543/compare-row-to-all-others-in-postgis

Solution
For each polygon, compute union of polygons which intersect it, then test if the union covers the polygon

### Find polygons which touch in a line
```
WITH 
data(id, geom) AS (VALUES
    ( 1, 'POLYGON ((100 200, 200 200, 200 100, 100 100, 100 200))'::geometry ),
    ( 2, 'POLYGON ((250 150, 200 150, 200 250, 250 250, 250 150))'::geometry ),
    ( 3, 'POLYGON ((300 100, 250 100, 250 150, 300 150, 300 100))'::geometry )
)
SELECT a.id, b.id, 
    ST_Relate(a.geom, b.geom),
    ST_Relate(a.geom, b.geom, '****1****') AS is_line_touch
    FROM data a CROSS JOIN data b WHERE a.id < b.id;
```
### Test if Point is on a Line
https://gis.stackexchange.com/questions/11510/st-closestpointline-point-does-not-intersect-line?rq=1

Also https://gis.stackexchange.com/questions/350461/find-path-containing-point

### Find Start Points of Rivers and Headwater polygons
https://gis.stackexchange.com/questions/131806/find-start-of-river?rq=1
https://gis.stackexchange.com/questions/132266/find-headwater-polygons?noredirect=1&lq=1


### Find routes which terminate in Polygons but do not cross them
https://gis.stackexchange.com/questions/254051/selecting-lines-with-start-and-end-points-inside-polygons-but-do-not-cross-them


### Find Lines that touch Polygon at both ends
https://gis.stackexchange.com/questions/299319/select-only-lines-that-touch-both-sides-of-polygon-postgis

### Find Lines that touch but do not cross Polygons
https://gis.stackexchange.com/questions/160142/intersection-between-line-polygon-in-postgis
```
SELECT lines.geom
 FROM lines, polygons
 WHERE ST_Touches(lines.geom, polygons.geom) AND
                 NOT EXISTS (SELECT 1 FROM polygons p2 WHERE ST_Crosses(lines.geom, p2.geom));
### Determine hierarchy of a spatial coverage
https://gis.stackexchange.com/questions/343100/intersecting-polygons-to-build-boundary-hierearchy-using-postgis
Problem
Have a table of polygons which are known to form a hierarchical coverage, but coverage is not explicitly represented.
Solution
Should be straightforward.  Determine containing relationship based on interior points and areas. Then can use a recursive query on that to extract paths if needed. 
## Query - Spatial Statistics
### Count points which lie inside polygons
Solution - LATERAL
Good use case for JOIN LATERAL
```
SELECT bg.geoid, bg.geom,  bg.total_pop AS total_population, 
bg.med_inc AS median_income,
       	t.numbirds
FROM bg_pop_income bg
JOIN LATERAL
        (SELECT COUNT(1) as numbirds 
FROM  bird_loc bl 
WHERE ST_within(bl.loc, bg.geom)) AS t ON true;
```
Solution using GROUP BY
Almost certainly less performant
```
SELECT bg.geoid, bg.geom, bg.total_pop, bg.med_inc, 
COUNT(bl.global_unique_identifier) AS num_bird_counts
FROM  bg_pop_income bg 
LEFT OUTER JOIN bird_loc bl ON ST_Contains(bg.geom, bl.loc)
GROUP BY bg.geoid, bg.geom, bg.total_pop, bg.med_inc;
```
### Count points from two tables which lie inside polygons
https://stackoverflow.com/questions/59989829/count-number-of-points-from-two-datasets-contained-by-neighbourhood-polygons-u
### Count polygons which lie within two layers of polygons
https://gis.stackexchange.com/questions/115881/how-many-a-features-that-fall-both-in-the-b-polygons-and-c-polygons-are-for-each

Q is for ArcGIS; would be interesting to provide a PostGIS answer

### Find Median of values in a polygon neighbourhood
https://gis.stackexchange.com/questions/349251/finding-median-of-polygons-that-share-boundaries
### Compute total length of lines in a Polygon
https://gis.stackexchange.com/questions/143438/calculating-total-line-lengths-within-polygon
## Use the Index, Luke
https://gis.stackexchange.com/questions/172266/improve-performance-of-a-postgis-st-dwithin-query?rq=1

https://gis.stackexchange.com/questions/162651/looking-for-boolean-intersection-of-small-table-with-huge-table?rq=1

### Use ST_Intersects instead of ST_DIsjoint
https://gis.stackexchange.com/questions/167945/delete-polygonal-features-in-one-layer-outside-polygon-feature-of-another-layer?noredirect=1&lq=1

### Spatial Predicate argument ordering important for indexing
https://gis.stackexchange.com/questions/209959/how-to-use-st-intersects-with-different-geometry-type

This may be due to indexing being used for first ST_Intersects arg, but not second?
### Clustering on the Index
https://gis.stackexchange.com/questions/240721/postgis-performance-increase-with-cluster

### Use an Index
https://gis.stackexchange.com/questions/237709/speeding-up-intersect-query-in-postgis
### Query - Distance
### Find points NOT within distance of lines
https://gis.stackexchange.com/questions/356497/select-points-falling-outside-of-buffer-and-count
https://gis.stackexchange.com/questions/367594/get-all-geom-points-that-are-more-than-3-meters-from-the-linestring-at-big-scal
Solution 1: EXCEPT with DWithin (Fastest)
```
SELECT locations.geom FROM locations
EXCEPT 
SELECT locations.geom FROM ways
JOIN locations
ON ST_DWithin(   ways.linestring,    locations.geom,    3)
```
Solution 2: LEFT JOIN for non-NULL with DWithin
2x SLOWER than #1
```
SELECT  inj.*
   FROM injuries inj 
   LEFT JOIN bike_routes br 
ON ST_DWithin(inj.geom, br.geom, 15) 
   WHERE br.gid IS NULL
```
Solution 3: NOT EXISTS with DWithin
Same performance as #2 ?
```
SELECT * 
FROM injuries AS inj 
WHERE NOT EXISTS 
(SELECT 1 FROM bike_routes br
WHERE ST_DWithin(br.geom, inj.geom, 15);
```
Solution 3: Buffer (Slow)
Buffer line, union, then find all point not in buffer polygon

### Find Points which have no point within distance
https://gis.stackexchange.com/questions/356663/postgis-finding-duplicate-label-within-a-radius

(Note: question title is misleading, question is actually asking for points which do NOT have a nearby point)
Solution
Best way is to use NOT EXISTS.
To select only records that have no other point with the same value within <threshold> distance:
```
SELECT  *
FROM    points AS a
WHERE   NOT EXISTS (
    SELECT  1
    FROM    points
    WHERE   a.cat = cat AND a.id <> id AND ST_DWithin(a.geom, geom, <threshold_in_CRS_units>)
);
```


### Find geometries close to centre of an extent
https://stackoverflow.com/questions/60218993/postgis-how-do-i-find-results-within-a-given-bounding-box-that-are-close-to-the
### Find Farthest Point from a Polygon
https://gis.stackexchange.com/questions/332073/is-there-any-function-that-can-calculate-the-maximum-minimum-distance-from-a-geo/334260#334260

### Find farthest vertex from polygon centroid
https://stackoverflow.com/questions/31497071/farthest-distance-of-a-polygon-point-from-its-centroid?rq=1
### Remove Duplicate Points within given Distance
https://gis.stackexchange.com/questions/24818/remove-duplicate-points-based-on-a-specified-distance?rq=1
### Find Distance and Bearing from Point to Polygon
https://gis.stackexchange.com/questions/27564/how-to-get-distance-bearing-between-a-point-and-the-nearest-part-of-a-polygon?rq=1


### Use DWithin instead of Buffer
https://gis.stackexchange.com/questions/297317/st-intersects-returns-true-while-st-contains-returns-false-for-a-point-located-o

### Find closest point on boundary of a union of polygons
https://gis.stackexchange.com/questions/124158/finding-outermost-border-of-set-of-geomertries-circles-using-postgis

### Find points returned by function within elliptical area
https://gis.stackexchange.com/questions/17857/finding-points-within-elliptical-area-using-postgis?rq=1

### Query Point with highest elevation along a transect through a point cloud
https://gis.stackexchange.com/questions/223154/find-highest-elevation-along-path
### Query a single point within a given distance of a road
https://gis.stackexchange.com/questions/361179/postgres-remove-duplicate-rows-returned-by-st-dwithin-query

## Spatial Predicates
### Test if two 3D geometries are equal
https://gis.stackexchange.com/questions/373978/how-to-check-two-3d-geometry-are-equal-in-postgis/373980#373980
## Query - KNN
### Nearest Point to each point in same table
https://gis.stackexchange.com/questions/287774/nearest-neighbor

### Nearest Point to each point in different table
https://gis.stackexchange.com/questions/340192/calculating-distance-between-every-entry-in-table-a-and-nearest-record-in-table

https://gis.stackexchange.com/questions/297208/efficient-way-to-find-nearest-feature-between-huge-postgres-tables
Very thorough explanation, including difference between geom and geog
```
SELECT g1.gid AS gref_gid,
       g2.gid AS gnn_gid,
       g2.code_mun,
       g1.codigo_mun,
       g2.text,
       g2.via AS igcvia1
FROM u_nomen_dom As g1
JOIN LATERAL (
  SELECT gid,
         code_mun,
         text,
         via
  FROM u_nomen_via AS g
  WHERE g1.codigo_mun = g.codigo_mun    
  ORDER BY g1.geom <-> g.geom
  LIMIT 1
) AS g2
ON true;
```
https://gis.stackexchange.com/questions/136403/postgis-nearest-points-with-st-distance-knn
Lots of obsolete options, dbastons answer is best

### Snap Points to closest Point on Line
https://gis.stackexchange.com/questions/279387/automatically-snapping-points-to-closest-part-of-line
### Find Shortest Line from Points to Roads (KNN, LATERAL)
https://gis.stackexchange.com/questions/332019/distinct-st-shortestline

https://gis.stackexchange.com/questions/283794/get-barrier-edge-id

### Matching points to nearest Line Segments
https://gis.stackexchange.com/questions/296445/get-closest-road-segment-to-segmentized-linestring-points
### Using KNN with JOIN LATERAL
http://www.postgresonline.com/journal/archives/306-KNN-GIST-with-a-Lateral-twist-Coming-soon-to-a-database-near-you.html

https://gis.stackexchange.com/questions/207592/postgis-osm-faster-query-to-find-nearest-line-of-points?rq=

https://gis.stackexchange.com/questions/278357/how-to-update-with-lateral-nearest-neighbour-query
https://gis.stackexchange.com/questions/338312/find-closest-polygon-from-point-and-get-its-attributes

https://carto.com/blog/lateral-joins/
### Compute point value as average of N nearest points
https://gis.stackexchange.com/questions/349754/calculate-average-of-the-temperature-value-from-4-surrounded-points-in-postgis

Solution
Uses LATERAL and KNN <->
```
SELECT a.id,
       a.geom,
       avg(c.temp_val) temp_val
FROM tablea a
CROSS JOIN LATERAL
  (SELECT temp_val
   FROM tableb b
   ORDER BY b.geom <-> a.geom
   LIMIT 4) AS c
GROUP BY a.id,a.geom
```
### Query Nearest Neighbours having record in temporal join table 
https://gis.stackexchange.com/questions/357237/find-knn-having-reference-in-a-table

### Snapping Points to Nearest Line
https://gis.stackexchange.com/questions/365070/update-points-geometry-in-postgis-database-snapping-them-to-nearest-line
```
UPDATE points
  SET  geom = (
    SELECT ST_ClosestPoint(lines.geom, points.geom)
    FROM lines
    WHERE ST_DWithin(points.geom, lines.geom, 5)
    ORDER BY lines.geom <-> points.geom
    LIMIT 1
  );
```
### Find near polygons to line
https://gis.stackexchange.com/questions/377674/find-nearest-polygons-of-a-multi-line-string


## Query - Geomemtric Shape
### Find narrow polygons
https://gis.stackexchange.com/questions/316128/identifying-long-and-narrow-polygons-in-with-postgis

Solution 1 - Negative Buffer
Detect thin polygons using a test: ST_Area(ST_Buffer(geom, -10)) = 0

Solution 2 - Thinness Ratio
Use the Thinness Ratio:  TR(A,p) = A * 4 * pi / (p^2)

See https://gis.stackexchange.com/questions/151939/explanation-of-the-thinness-ratio-formula


## Query - Invalid Geometries
Skip invalid geometries when querying
https://gis.stackexchange.com/questions/238748/compare-only-valid-polygon-geometries-in-postgis?rq=1


## Query - Relate
Finding LineStrings with Common Segments
https://gis.stackexchange.com/questions/268147/find-linestrings-with-common-segments-in-postgis-2-3

## Query - Duplicates
### Find and Remove duplicate geometry rows
https://gis.stackexchange.com/questions/124583/delete-duplicate-geometry-in-postgis-tables


## Query - Tolerance / Robustness
### Predicates with Tolerance
Example: https://gis.stackexchange.com/questions/176359/tolerance-in-postgis

This post is about needing ST_Equals to have a tolerance to accommodate small differences caused by reprojection
https://gis.stackexchange.com/questions/141790/postgis-st-equals-false-when-st-intersection-100-of-geometry?rq=1

This is about small coordinate differences defeating ST_Equals, and using ST_SnapToGrid to resolve the problem:
https://gis.stackexchange.com/questions/56617/st-equals-postgis-problems?rq=1

This says that copying geometries to another database causes them to fail ST_Equals (not sure why copy would change the geom - perhaps done using WKT?).  Says that using buffer is too slow
https://gis.stackexchange.com/questions/213240/st-equals-not-matching-with-exact-geometry?noredirect=1&lq=1

https://gis.stackexchange.com/questions/176359/tolerance-in-postgis

### ST_ClosestPoint does not intersect Line
https://gis.stackexchange.com/questions/11510/st-closestpointline-point-does-not-intersect-line?rq=1
Solution
### Use ST_DWithin
Discrepancy between GEOS predicates and PostGIS Intersects?
https://gis.stackexchange.com/questions/259210/how-can-a-point-not-be-within-or-touch-but-still-intersect-a-polygon?rq=1

Actually it doesn’t look like there is a discrepancy ATP.  But still a case where a distance tolerance might clarify things.

## Query - JOIN LATERAL

https://gis.stackexchange.com/questions/136403/postgis-nearest-points-with-st-distance-knn

https://gis.stackexchange.com/questions/291941/select-points-with-maximum-attribute-value-per-category-on-a-spatial-join-with-p

### Union of Polygons does not Cover original Polygons
https://gis.stackexchange.com/questions/376706/postgis-st-covers-doesnt-match-polygon-after-st-union
```
WITH data(id, pt) AS (VAlUES 
( 1, 'POINT ( 30.2833756 50.4419441) '::geometry )
,( 2, 'POINT( 30.2841370 50.4419441 ) '::geometry )
)
,poly AS (
  SELECT ST_Transform(ST_Expand( ST_Transform(ST_SetSRID( pt, 4326) , 31997), 100), 3857) AS poly
  FROM data
)
SELECT * FROM poly;
SELECT ST_Union( poly ) FROM poly;
```

## Update / Delete
### Update a column by a spatial condition
https://gis.stackexchange.com/questions/364391/how-to-refer-to-another-table-in-a-case-when-statement-in-postgis
``
UPDATE table1
    SET column3 = (
      SELECT 
        CASE
         WHEN table2.column7 >15 THEN 1
          ELSE 0
        END
      FROM table2 
      WHERE ST_INTERSECTS(table1.geom, table2.geom)
     --LIMIT 1
);
``
Is LIMIT 1 needed?

### Delete Lines Contained in Polygons
https://gis.stackexchange.com/questions/372549/delete-lines-within-polygon

Use an EXISTS expression:
```
DELETE
FROM   <lines> AS ln
WHERE  EXISTS (
  SELECT 1
  FROM   <poly> AS pl
  WHERE  ST_Within(ln.geom, pl.geom)
);
```
If the ST_Within check hits the first TRUE (selecting a truthy 1), the sub-query terminates for the current row (no matter if there were more than one hit).

This is among the most efficient ways for when a table has to be traversed by row (as in an UPDATE/DELETE), or otherwise compared against a pre-selection (of e.g. ids).


## Geometry Creation
### Use ST_MakePoint or ST_PointFromText
https://gis.stackexchange.com/questions/122247/st-makepoint-or-st-pointfromtext-to-generate-points?rq=1
https://gis.stackexchange.com/questions/58605/which-function-for-creating-a-point-in-postgis/58630#58630

Solutions
ST_MakePoint is much faster

### Collect Lines into a MultiLine in a given order
https://gis.stackexchange.com/questions/166701/postgis-merging-linestrings-into-multilinestrings-in-a-particular-order


## Geometry Editing
### Remove Holes from Polygons
https://gis.stackexchange.com/questions/278154/polygons-have-holes-after-pgr-pointsaspolygon

### Remove Holes from MultiPolygons
https://gis.stackexchange.com/questions/348943/simplifying-a-multipolygon-into-one-polygon-respecting-its-outer-boundaries

Solution
https://gis.stackexchange.com/a/349016/14766

Similar
https://gis.stackexchange.com/questions/291374/cut-out-polygons-that-at-least-partially-fall-in-another-polygon

### Select every Nth point from a LineString
https://stackoverflow.com/questions/60319473/postgis-how-do-i-select-every-second-point-from-linestring


## Constructions
### Construct polygons filling gaps in a coverage
https://gis.stackexchange.com/questions/368406/postgis-create-new-polygons-in-between-existing

Solution
```
SELECT ST_DIFFERENCE(foo.geom, bar.geom)
FROM (SELECT ST_CONVEXHULL(ST_COLLECT(shape::geometry)) as geom FROM schema.polytable) as foo, 
(SELECT ST_BUFFER(ST_UNION(shape),0.5) as geom FROM schema.polytable) as bar
```
To scale this up/out, you could process batches of polygons using a rectangular grid defined over the data space. The constructed gap polygons can be clipped to grid cells. and optional unioned afterwards

### Create ellipses in WGS84
https://gis.stackexchange.com/questions/218159/postgis-ellipse-issue

### Create polygon joining two polygons
https://gis.stackexchange.com/questions/352884/how-can-i-get-a-polygon-of-everything-between-two-polygons-in-postgis

Solution
Form convex hull of both, subtract convex hull of each, union with original polygons, remove holes.
```
WITH data(geom) AS (VALUES
( 'POLYGON ((100 300, 200 300, 200 200, 100 200, 100 300))'::geometry )
,( 'POLYGON ((50 150, 100 150, 100 100, 50 100, 50 150))'::geometry )
)
SELECT ST_MakePolygon(ST_ExteriorRing(ST_Union(
  ST_Difference( 
      ST_ConvexHull( ST_Union(geom)), 
      ST_Union( ST_ConvexHull(geom))), 
  ST_Collect(geom))))
FROM data;
```
## Noding

### Node (Split) a table of lines by another table of lines
https://lists.osgeo.org/pipermail/postgis-users/2019-September/043617.html

### Node a table of lines with itself
https://gis.stackexchange.com/questions/368996/intersecting-line-at-junction-in-postgresql

### Node a table of Lines by a Set of Points
https://gis.stackexchange.com/questions/332213/split-lines-with-points-postgis

### Compute points of intersection for a LineString
https://gis.stackexchange.com/questions/16347/is-there-a-postgis-function-for-determining-whether-a-linestring-intersects-itse

### Determine location of noding failures
https://gis.stackexchange.com/questions/345341/get-location-of-postgis-geos-topology-exception

Using ST_Node on set of linestrings produces an error with no indication of where the problem occurs.  Currently ST_Node uses IteratedNoder, which nodes up to 6 times, ahd fails if intersections are still found.  
Solution
Would be possible to report the nodes found in the last pass, which wouild indicate where the problems occur.  

Would be better to eliminate noding errors via snap-rounding, or some other kind of snapping

### Clipping Set of LineString by intersection points
https://gis.stackexchange.com/questions/154833/cutting-linestrings-with-points

Uses ST_Split_Multi from here: https://github.com/Remi-C/PPPP_utilities/blob/master/postgis/rc_split_multi.sql

### Construct locations where LineStrings self-intersect
https://gis.stackexchange.com/questions/367120/getting-st-issimple-reason-and-detail-similar-to-st-isvaliddetail-in-postgis

Solution
SQL to compute LineString self-intersetions is provided


## Polygonization
### Form Polygons from OSM streets
https://gis.stackexchange.com/questions/331529/split-streets-to-create-polygons

### Form polygons from a set of lines
https://gis.stackexchange.com/questions/231237/making-linestrings-with-adjacent-lines-in-postgis?rq=1

### Polygonize a set of isolines with bounding box
https://gis.stackexchange.com/questions/127727/how-to-transform-isolines-to-isopolygons-with-postgis

### Find area enclosed by a set of lines
https://gis.stackexchange.com/questions/373933/polygon-covered-by-the-intersection-of-multiple-linestrings-postgis/373983#373983


## Clipping
### Clip Districts to Coastline
http://blog.cleverelephant.ca/2019/07/simple-sql-gis.html
https://gis.stackexchange.com/questions/331887/unioning-a-set-of-intersections

### Clip lines to a set of polygons
https://gis.stackexchange.com/questions/193217/st-difference-on-linestrings-and-polygons-slow-and-fails?rq=1

## Line Intersection
### Intersection of Lines which are not exactly coincident
https://stackoverflow.com/questions/60298412/wrong-result-using-st-intersection-with-postgis/60306404#60306404


## Line Merging
### Merge/Node Lines in a linear network
https://gis.stackexchange.com/questions/238329/how-to-break-multilinestring-into-constituent-linestrings-in-postgis
Solution
Use ST_Node, then ST_LineMerge

### Merge Lines and preserve direction
https://gis.stackexchange.com/questions/353565/how-to-join-linestrings-without-reversing-directions-in-postgis

SOLUTION 1
Use a recursive CTE to group contiguous lines so they can be merged

```
WITH RECURSIVE
data AS (SELECT
--'MULTILINESTRING((0 0, 1 1), (2 2, 1 1), (2 2, 3 3), (3 3, 4 4))'::geometry
'MULTILINESTRING( (0 0, 1 1), (1 1, 2 2), (3 3, 2 2), (4 4, 3 3), (4 4, 5 5), (5 5, 6 6) )'::geometry
 AS geom)
,lines AS (SELECT t.path[1] AS id, t.geom FROM data, LATERAL ST_Dump(data.geom) AS t)
,paths AS (
  SELECT * FROM
    (SELECT l1.id, l1.geom, l1.id AS startid, l2.id AS previd
      FROM lines AS l1 LEFT JOIN lines AS l2 ON ST_EndPoint(l2.geom) = ST_StartPoint(l1.geom)) AS t
    WHERE previd IS NULL
  UNION ALL
  SELECT l1.id, l1.geom, startid, p.id AS previd
    FROM paths p
    INNER JOIN lines l1 ON ST_EndPoint(p.geom) = ST_StartPoint(l1.geom)
)
SELECT ST_AsText( ST_LineMerge(ST_Collect(geom)) ) AS geom
  FROM paths
  GROUP BY startid;
```

SOLUTION 2
ST_LIneMerge merges lines irrespective of direction.  
Perhaps a flag could be added to respect direction?

See Also
https://gis.stackexchange.com/questions/74119/a-linestring-merger-algorithm

### Merging lines to simplify a road network
Merge lines with common attributes at degree-2 nodes

https://gis.stackexchange.com/questions/326433/st-linemerge-to-simplify-road-network?rq=1



## Polygon Intersection
### Find Intersection of all geometries in a set
https://gis.stackexchange.com/questions/271824/st-intersection-intersection-of-all-geometries-in-a-table

https://gis.stackexchange.com/questions/271941/looping-through-table-to-get-single-intersection-from-n2-geometries-using-postg

https://gis.stackexchange.com/questions/60281/query-to-find-the-intersection-coordinates-of-multiple-polyon

Solutions
Define an aggregate function (given in #2)
Define a function to do the looping
Use a recursive CTE (see SQL in #2)

Issues
How to find all groups of intersecting polygons.  DBSCAN maybe?  (This is suggested in an answer)
Intersection performance - Use Polygons instead of MultiPolygons
https://gis.stackexchange.com/questions/101425/using-multipolygon-or-polygon-features-for-large-intersect-operations

### Intersection performance - Check containment first
https://postgis.net/2014/03/14/tip_intersection_faster/

### Aggregated Intersection
https://gis.stackexchange.com/questions/269875/aggregate-version-of-st-intersection


## Polygon Difference
### Subtract large set of polygons from a surrounding box
https://gis.stackexchange.com/questions/330051/obtaining-the-geospatial-complement-of-a-set-of-polygons-to-a-bounding-box-in-po/333562#333562

Issues
conventional approach is too slow to use  (Note: user never actually completed processing, so might not have encountered geometry size issues, which could also occur)

### Subtract MultiPolygons from LineStrings
https://gis.stackexchange.com/questions/239696/subtract-multipolygon-table-from-linestring-table

https://gis.stackexchange.com/questions/193217/st-difference-on-linestrings-and-polygons-slow-and-fails

### Split Polygons by distance from a Polygon
https://gis.stackexchange.com/questions/78073/separate-a-polygon-in-different-polygons-depending-of-the-distance-to-another-po

### Cut detailed polygons into a base polygonal coverage
https://gis.stackexchange.com/questions/71461/using-st-difference-and-preserving-attributes-in-postgis

Solution
For each base polygon, union all detailed polygons which intersect it
Difference the detailed union from the each base polygon
UNION ALL:
The differenced base polygons
The detailed polygons
All remaining base polygons which were not changed

### Subtract Areas from a set of Polygons
https://gis.stackexchange.com/questions/250674/postgis-st-difference-similar-to-arcgis-erase

https://gis.stackexchange.com/questions/187406/how-to-use-st-difference-and-st-intersection-in-case-of-multipolygons-postgis

https://gis.stackexchange.com/questions/90174/postgis-when-i-add-a-polygon-delete-overlapping-areas-in-other-layers
### Find Part of Polygons not fully contained by union of other Polygons
https://gis.stackexchange.com/questions/313039/find-what-polygons-are-not-fully-covered-by-union-of-polygons-from-another-layer

## Polygon Symmetric Difference
### Construct symmetric difference of two tables
https://gis.stackexchange.com/questions/302458/symmetrical-difference-between-two-layers


## Overlay - Coverage / Polygon
https://gis.stackexchange.com/questions/109692/how-to-replicate-arcgis-intersect-in-postgis

http://blog.cleverelephant.ca/2019/07/postgis-overlays.html
### Flatten / Create coverage from Nested Polygons
https://gis.stackexchange.com/questions/266005/postgis-separate-nested-polygons
### Create Coverage from overlapping Polygons
https://gis.stackexchange.com/questions/83/separate-polygons-based-on-intersection-using-postgis
https://gis.stackexchange.com/questions/112498/postgis-overlay-style-union-not-dissolve-style
Solution
One answer suggests the standard Extract Lines > Node > Polygonize approach (although does not include the PIP parentage step).  But a comment says that this does not scale well (Pierre Racine…).
Also links to PostGIS wiki:  https://trac.osgeo.org/postgis/wiki/UsersWikiExamplesOverlayTables

### Improve performance of a coverage overlay
https://gis.stackexchange.com/questions/31310/acquiring-arcgis-like-speed-in-postgis/31562
Problem
Finding all intersections of a large set of parcel polygons against a set of jurisdiction polygons is slow
Solution
Reduce # calls to ST_Intersection by testing if parcel is wholly contained in polygon. 
```
INSERT INTO parcel_jurisdictions(parcel_gid,jurisdiction_gid,isect_geom) SELECT a.orig_gid AS parcel_gid, b.orig_gid AS jurisdiction_gid, CASE WHEN ST_Within(a.geom,b.geom) THEN a.geom ELSE ST_Multi(ST_Intersection(a.geom,b.geom)) END AS geom FROM valid_parcels a JOIN valid_jurisdictions b ON ST_Intersects(a.geom, b.geom);
```
References
https://postgis.net/2014/03/14/tip_intersection_faster/


### Find cells touched by a path
https://gis.stackexchange.com/questions/317401/maintaining-order-and-repetition-of-cell-names-using-postgis?atw=1
### Find non-covered polygons
https://gis.stackexchange.com/questions/333302/selecting-non-overlapping-polygons-from-a-one-layer-in-postgis/334217#334217
```
WITH
data AS (
    SELECT * FROM (VALUES
        ( 'A', 'POLYGON ((100 200, 200 200, 200 100, 100 100, 100 200))'::geometry ),
        ( 'B', 'POLYGON ((300 200, 400 200, 400 100, 300 100, 300 200))'::geometry ),
        ( 'C', 'POLYGON ((100 400, 200 400, 200 300, 100 300, 100 400))'::geometry ),
        ( 'AA', 'POLYGON ((120 380, 180 380, 180 320, 120 320, 120 380))'::geometry ),
        ( 'BA', 'POLYGON ((110 180, 160 180, 160 130, 110 130, 110 180))'::geometry ),
        ( 'BB', 'POLYGON ((170 130, 190 130, 190 110, 170 110, 170 130))'::geometry ),
        ( 'CA', 'POLYGON ((330 170, 380 170, 380 120, 330 120, 330 170))'::geometry ),
        ( 'AAA', 'POLYGON ((330 170, 380 170, 380 120, 330 120, 330 170))'::geometry ),
        ( 'BAA', 'POLYGON ((121 171, 151 171, 151 141, 121 141, 121 171))'::geometry ),
        ( 'CAA', 'POLYGON ((341 161, 351 161, 351 141, 341 141, 341 161))'::geometry ),
        ( 'CAB', 'POLYGON ((361 151, 371 151, 371 131, 361 131, 361 151))'::geometry )
    ) AS t(id, geom)
)
SELECT a.id
FROM data AS A
LEFT JOIN data AS b ON a.id <> b.id AND ST_CoveredBy(a.geom, b.geom)
WHERE b.geom IS NULL;
```
### Count Overlap Depth in set of polygons
https://gis.stackexchange.com/questions/159282/counting-overlapping-polygons-in-postgis-using-st-union-very-slow

Solution 1: 
Compute overlay of dataset using ST_Node and ST_Polygonize
Count overlap depth using ST_PointOnSurface and ST_Contains

### Identify Overlay Resultant Parentage

https://gis.stackexchange.com/questions/315368/listing-all-overlapping-polygons-using-postgis

### PostGIS Union of two polygon layers
Wants a coverage overlay (called “QGIS Union”)
https://gis.stackexchange.com/questions/302086/postgis-union-of-two-polygons-layers?rq=1

See also
https://gis.stackexchange.com/questions/179533/arcgis-union-equivalent-in-postgis?rq=1
https://gis.stackexchange.com/questions/115927/is-there-a-union-function-for-multiple-layers-comparable-to-arcgis-in-open-sourc

### Union Non-clean Polygons
https://gis.stackexchange.com/questions/31895/joining-lots-of-small-polygons-to-form-larger-polygon-using-postgis/31905#31905

### Sum area-weighted polygons (Overlay 2 coverages)
https://gis.stackexchange.com/questions/171333/weighting-amount-of-overlapping-polygons-in-postgis

### Compute area covered by overlapping polygons with attribute
https://gis.stackexchange.com/questions/90174/postgis-when-i-add-a-polygon-delete-overlapping-areas-in-other-layers

### Return only polygons from Overlay
https://gis.stackexchange.com/questions/89231/postgis-st-intersection-of-polygons-can-return-lines?rq=1

https://gis.stackexchange.com/questions/242741/st-intersection-returns-erroneous-polygons?noredirect=1&lq=1

### Compute Coverage from Overlapping Polygons
https://gis.stackexchange.com/questions/206473/obtaining-each-unique-area-of-overlapping-polygons-in-postgres-9-6-postgis-2-3

Problem
Reduce a dataset of highly overlapping polygons to a coverage (not clear if attribution is needed or not)

Issues
User implements a very complex overlay process, but can not get it to work, likely due to robustness problems

Solution
ST_Boundary -> ST_Union -> ST_Polygonize ??


## Overlay - Lines
https://gis.stackexchange.com/questions/186242/how-to-get-smallest-line-segments-from-intersection-difference-of-multiple-ove
### Count All Intersections Between 2 Linestrings
https://gis.stackexchange.com/questions/347790/splitting-self-overlapping-lines-with-points-using-postgis

### Remove Line Overlaps Hierarchically
https://gis.stackexchange.com/questions/372572/how-to-remove-line-overlap-hierachically-in-postgis-with-st-difference


## Polygon Union
### Union of Massive Number of Point Buffers
https://gis.stackexchange.com/questions/31880/memory-issue-when-trying-to-buffer-union-large-dataset-using-postgis?noredirect=1&lq=1

Union a massive number of buffers around points which have an uneven distribution (points are demographic data in the UK).
Using straight ST_Union runs out of memory
Solution
Implement a “SQL-level” cascaded union as follows:
Spatially sort data based on ST_GeoHash
union smaller partitions of the data (partition size = 100K)
union the partitions together 

### Polygon Coverage Union with slivers removed
https://gis.stackexchange.com/questions/71809/is-there-a-dissolve-st-union-function-that-will-close-gaps-between-features?rq=1

Solution - NOT SURE

### Polygon Coverage Union with gaps removed
https://gis.stackexchange.com/questions/356480/is-it-possible-create-a-polygon-from-more-polygons-that-are-not-overlapped-but-c

https://gis.stackexchange.com/questions/316000/using-st-union-to-combine-several-polygons-to-one-multipolygon-using-postgis/31612

Both of these have answers recommending using a small buffer outwards and then the inverse on the result.

### ST_Split creates invalid coverage (holes appear in Union)
https://gis.stackexchange.com/questions/344716/holes-after-st-split-with-postgis

Solution
??  Need some way to create a clean coverage


### Union Intersecting Polygons
https://gis.stackexchange.com/questions/187728/alternative-to-st-union-st-memunion-for-merging-overlapping-polygons-using-postg?rq=1

### Union groups of polygons
https://gis.stackexchange.com/questions/185393/what-is-the-best-way-to-merge-lots-of-small-adjacents-polygons-postgis?noredirect=1&lq=1

### Union Edge-Adjacent Polygons
Only union polygons which share an edge (not just touch)
https://gis.stackexchange.com/questions/1387/is-there-a-dissolve-function-in-postgis-other-than-st-union?rq=1
https://gis.stackexchange.com/questions/24634/merging-polygons-that-intersect-by-more-than-a-specified-amount?rq=1
https://gis.stackexchange.com/questions/127019/merge-any-and-all-adjacent-polygons?noredirect=1&lq=1
Problem
Union only polygons which intersect, keep non-intersecting ones unchanged.  Goal is to keep attributes on non-intersecting polygons, and improve performance by unioning only groups of intersecting polygons
Solution
Should be able to find equivalence classes of intersecting polygons and union each separately?
See Also

### Grouping touching Polygons
Can use ST_DBSCAN with very small distance to group touching polygons

### Enlarge Polygons to Fill Boundary
https://gis.stackexchange.com/questions/91889/adjusting-polygons-to-boundary-and-filling-holes?rq=1

### Boundary of Coverage of Polygons
https://gis.stackexchange.com/questions/324736/extracting-single-boundary-from-multipolygon-in-postgis

Solution
The obvious: Union, then extract boundary

### Union of cells grouped by ID
https://gis.stackexchange.com/questions/288880/finding-geometry-of-cluster-from-points-collection-using-postgis

### Union of set of geometry specified by IDs
SELECT ST_Union(geo)) FROM ( SELECT geom FROM table WHERE id IN ( … ) ) as foo;

### Union of polygons with equal or lower value
https://gis.stackexchange.com/questions/161849/postgis-sql-request-with-aggregating-st-union?rq=1
Solution
Nice use of window functions with PARTITION BY and ORDER BY.
Not sure what happens if there are two polygons with same value though.  Worth finding out

### Union Groups of Adjacent Polygon, keeping attribution for singletons
https://gis.stackexchange.com/questions/366374/how-to-use-dissolve-a-subset-of-a-postgis-table-based-on-a-value-in-a-column

Solution
Use ST_ClusterDBSCAN


## Polygon Splitting
https://gis.stackexchange.com/questions/299849/split-polygon-into-separate-polygons-using-a-table-of-individual-lines

https://gis.stackexchange.com/questions/215886/split-lines-by-polygons

### Split rectangles along North-South axis
https://gis.stackexchange.com/questions/239801/how-can-i-split-a-polygon-into-two-equal-parts-along-a-n-s-axis?rq=1

### Split rotated rectangles into equal parts
https://gis.stackexchange.com/questions/286184/splitting-polygon-in-equal-parts-based-on-polygon-area

See also next problem

### Split Polygons into equal parts
http://blog.cleverelephant.ca/2018/06/polygon-splitting.html

Hmm..  does this really result in equal-area subdivision? The Voronoi-of-centroid step is distance-based, not area based…. So may not always work?  Would be good to try this on a bunch of country outines

## Line Splitting
### Split Self-Overlapping Lines at Points not on the lines
https://gis.stackexchange.com/questions/347790/splitting-self-overlapping-lines-with-points-using-postgis


## Transformations
### Scale polygon around a given point
https://gis.stackexchange.com/questions/227435/postgis-scaling-for-polygons-at-a-fixed-center-location

No solution so far
Issues
SQL given is overly complex and inefficient.  But idea is right

## Constructions
### Expanding polygons contained inside a bounding polygon until one vertice touches
https://gis.stackexchange.com/questions/294163/sql-postgis-expanding-polygons-contained-inside-another-polygon-until-one-ver

### Bounding box of set of MULTILINESTRINGs
https://gis.stackexchange.com/questions/115494/bounding-box-of-set-of-multilinestrings-in-postgis?rq=1

### Generate Land-Constrained Point Grids
https://korban.net/posts/postgres/2019-10-17-generating-land-constrained-point-grids/

### Create Square Grids
https://gis.stackexchange.com/questions/16374/creating-regular-polygon-grid-in-postgis

https://gis.stackexchange.com/questions/4663/how-to-create-regular-point-grid-inside-a-polygon-in-postgis

https://gis.stackexchange.com/questions/271234/creating-a-grid-on-a-polygon-and-find-number-of-points-in-each-grid

### Create Polygon Centrelines
https://gis.stackexchange.com/questions/322392/average-of-two-lines?noredirect=1&lq=1

https://gis.stackexchange.com/questions/50668/how-can-i-merge-collapse-nearby-and-parallel-road-lines-eg-a-dual-carriageway

https://github.com/migurski/Skeletron


Idea: triangulate polygon, then connect midpoints of interior lines

Idea 2: find line segments for nearest points of each line vertex.  Order by distance along line (percentage?).  Discard any that have a retrograde direction.  Join centrepoints of segments.

### Straight Skeleton
https://github.com/twak/campskeleton

### Generate Well-spaced points within Polygon
https://gis.stackexchange.com/questions/377606/ensuring-all-points-are-a-certain-distance-from-polygon-boundary

Uses clustering on randomly generated points.  
Suggestion is to use neg-buffered polygon to ensure distance from polygon boundary


## Hulls / Covering Polygons
### Construct polygon containing lines
https://gis.stackexchange.com/questions/238/find-polygon-that-contains-all-linestring-records-in-postgis-table

### Construct lines between all points of a Polygon
https://gis.stackexchange.com/questions/58534/get-the-lines-between-all-points-of-a-polygon-in-postgis-avoid-nested-loop

Solution
Rework given SQL using CROSS JOIN and a self join
### Generating Regions from Points
https://gis.stackexchange.com/questions/92913/extra-detailed-bounding-polygon-from-many-geometric-points?rq=1

### Generate regions from large sets of points (100K) tagged with region attribute.

Could use ST_ConcaveHull, but results would overlap
Perhaps ST_Voronoi would be better?  How would this work, and what are limits on size of data?

### Construct a Star Polygon from a set of Points
https://gis.stackexchange.com/questions/349945/creating-precise-shapes-using-list-of-coordinates
Solution
```
WITH pts(pt) AS (VALUES
(st_transform(st_setsrid(st_makepoint(-97.5660461, 30.4894905), 4326),4269) ),
(st_transform(st_setsrid(st_makepoint(-97.5657216, 30.4902173), 4326),4269) ),
(st_transform(st_setsrid(st_makepoint(-97.5608779, 30.4896142), 4326),4269) ),
(st_transform(st_setsrid(st_makepoint(-97.5605001, 30.491422), 4326),4269) ),
(st_transform(st_setsrid(st_makepoint(-97.5588115, 30.4911697), 4326),4269) ),
(st_transform(st_setsrid(st_makepoint(-97.5588262, 30.4910204), 4326),4269) ),
(st_transform(st_setsrid(st_makepoint(-97.5588262, 30.4910204), 4326),4269)),
(st_transform(st_setsrid(st_makepoint(-97.5585742, 30.4909966), 4326),4269)),
(st_transform(st_setsrid(st_makepoint(-97.5578045, 30.4909263), 4326),4269)),
(st_transform(st_setsrid(st_makepoint(-97.5574653, 30.4908877), 4326),4269)),
(st_transform(st_setsrid(st_makepoint(-97.5571534, 30.4908375), 4326),4269)),
(st_transform(st_setsrid(st_makepoint(-97.5560964, 30.4907427), 4326),4269))
),
centroid AS (SELECT ST_Centroid( ST_Collect(pt) ) AS centroid FROM pts),
line AS (SELECT ST_MakeLine( pt ORDER BY ST_Azimuth( centroid, pt ) ) AS geom
    FROM pts CROSS JOIN centroid),
poly AS (SELECT ST_MakePolygon( ST_AddPoint( geom, ST_StartPoint( geom ))) AS geom
    FROM line)
SELECT geom FROM poly;
```

## Buffering
### Variable Width Buffer
https://gis.stackexchange.com/questions/340968/varying-size-buffer-along-a-line-with-postgis

### Expand a rectangular polygon
https://gis.stackexchange.com/questions/308333/expanding-polygon-by-distance-using-postgis

### Buffering Coastlines with inlet skeletons
https://gis.stackexchange.com/questions/300867/how-can-i-buffer-a-mulipolygon-only-on-the-coastline
### Removing Line Buffer artifacts
https://gis.stackexchange.com/questions/363025/how-to-run-a-moving-window-function-in-a-conditional-statement-in-postgis-for-bu

Quite bizarre, but apparently works.


## Measuring
### Find Median width of Road Polygons
https://gis.stackexchange.com/questions/364173/calculate-median-width-of-road-polygons

### Unbuffering - find average distance from a buffer and source polygon
https://gis.stackexchange.com/questions/33312/is-there-a-st-buffer-inverse-function-that-returns-a-width-estimation

Also: https://gis.stackexchange.com/questions/20279/calculating-average-width-of-polygon

### Compute Length and Width of an arbitrary rectangle
https://gis.stackexchange.com/questions/366832/get-dimension-of-rectangular-polygon-postgis


## Simplification
https://gis.stackexchange.com/questions/293429/decrease-polygon-vertices-count-maintaining-its-aspect

## Smoothing
https://gis.stackexchange.com/questions/313667/postgis-snap-line-segment-endpoint-to-closest-other-line-segment

Problem is to smooth a network of lines.  Network is not fully noded, so smoothing causes touching lines to become disconnected.
Solution
Probably to node the network before smoothing.
Not sure how to node the network and preserve IDs however!?

## Ordering Geometry
### Ordering a Square Grid
https://gis.stackexchange.com/questions/346519/sorting-polygons-into-a-n-x-n-spatial-array

https://gis.stackexchange.com/questions/255512/automatically-name-rectangles-by-spatial-order-or-position-to-each-other?noredirect=1&lq=1

### Serpentine Ordering
https://gis.stackexchange.com/questions/176197/seeking-tool-algorithm-for-assigning-code-to-enumeration-areas-polygons-using?noredirect=1&lq=1

No solution in the post!

Also
https://gis.stackexchange.com/questions/73978/numbering-polygons-according-to-their-spatial-relationships?noredirect=1&lq=1

### Ordering Polygons along a line
https://gis.stackexchange.com/questions/201306/numbering-adjacent-polygons-in-sequential-order?noredirect=1&lq=1

No explicit solution given, but suggestion is to compute adjacency graph and then do a graph traversal

### Connecting Circles Into a Polygonal Path
https://gis.stackexchange.com/questions/246521/connecting-circles-with-lines-cover-all-circles-using-postgis

### Ordered list of polygons intersecting a line
https://gis.stackexchange.com/questions/179061/find-all-intersections-of-a-linestring-and-a-polygon-and-the-order-in-which-it-i?rq=1


## Generating Point Distributions
### Generate Evenly-Distributed Points in a Polygon

https://gis.stackexchange.com/questions/8468/creating-evenly-distributed-points-within-an-irregular-boundary?rq=1

One solution: create a grid of points and then clip to polygon

See also: https://math.stackexchange.com/questions/15624/distribute-a-fixed-number-of-points-uniformly-inside-a-polygon
https://gis.stackexchange.com/questions/4663/how-to-create-regular-point-grid-inside-a-polygon-in-postgis

### Place Maximum Number of Points in a Polygon
https://gis.stackexchange.com/questions/4828/seeking-algorithm-to-place-maximum-number-of-points-within-constrained-area-at-m

### Thin out Points along lines
https://gis.stackexchange.com/questions/131854/spacing-a-set-of-points?rq=1

## Contouring
### Generate contours from evenly-spaced weighted points
https://gis.stackexchange.com/questions/85968/clustering-points-in-postgresql-to-create-contour-map?rq=1
NO SOLUTION

### Contouring Irregularly spaced points
https://abelvm.github.io/sql/contour/

Solution
An impressive PostGIS-only solution using a Delaunay with triangles cut by contour lines.
Uses the so-called Meandering Triangles method for isolines.

## Clustering
See https://gis.stackexchange.com/questions/11567/spatial-clustering-with-postgis for a variety of approaches that predate a lot of the PostGIS clustering functions.

### Grid-Based Clustering
https://gis.stackexchange.com/questions/352562/is-it-possible-to-get-one-geometry-per-area-box-in-postgis

Solution 1
Use ST_SnapToGrid to compute a cell id for each point, then bin the points based on that.  Can use aggregate function to count points in grid cell, or use DISTINCT ON as a cheesy way to pick one representative point.  Need to use representative point rather than average, for better visual results (perhaps?)

Solution 2
Generate grid of cells covering desired area, then JOIN LATERAL to points to aggregate.  Not sure how to select a representative point doing this though - perhaps MIN or MAX?  Requires a grid-generating function, which is coming in PostGIS 3.1

### Non-spatial clustering by distance
https://stackoverflow.com/questions/49250734/sql-window-function-that-groups-values-within-selected-distance

### Find Density Centroids Within Polygons
https://gis.stackexchange.com/questions/187256/finding-density-centroids-within-polygons-in-postgis?rq=1

### Group touching Polygons
https://gis.stackexchange.com/questions/343514/postgis-recursively-finding-intersections-of-polygons-to-determine-clusters
Solution: Use ST_DBSCAN which provides very good performance

This problem has a similar recommended solution:
https://gis.stackexchange.com/questions/265137/postgis-union-geometries-that-intersect-but-keep-their-original-geometries-info

A worked example:
https://gis.stackexchange.com/questions/366374/how-to-use-dissolve-a-subset-of-a-postgis-table-based-on-a-value-in-a-column

Similar problem in R
https://gis.stackexchange.com/questions/254519/group-and-union-polygons-that-share-a-border-in-r?rq=1

Issues
DBSCAN uses distance. This will also cluster polygons which touch only at a point, not just along an edge.  Is there a way to improve this?  Allow a different distance metric perhaps - say length of overlap?

### Group connected LineStrings
https://gis.stackexchange.com/questions/94203/grouping-connected-linestrings-in-postgis

Presents a recursive CTE approach, but ultimately recommends using ST_ClusterDBCSAN

https://gis.stackexchange.com/questions/189091/postgis-how-to-merge-contiguous-features-sharing-same-attributes-values

### Kernel Density
https://gist.github.com/AbelVM/dc86f01fbda7ba24b5091a7f9b48d2ee

### Group Polygon Coverage into similar-sized Areas
https://gis.stackexchange.com/questions/350339/how-to-create-polygons-of-a-specific-size

More generally: how to group adjacent polygons into sets with similar sum of a given attribute.

See Also
https://gis.stackexchange.com/questions/123289/grouping-village-points-based-on-distance-and-population-size-using-arcgis-deskt

Solution
Build adjacency graph and aggregate based on total, and perhaps some distance criteria?
Note: posts do not provide a PostGIS solution for this.  Not known if such a solution exists.
Would need a recursive query to do this.
How to keep clusters compact?

### Bottom-Up Clustering Algorithm
Not sure if this is worthwhile or not.  Possibly superseded by more recent standard PostGIS clustering functions

https://gis.stackexchange.com/questions/113545/get-a-single-cluster-from-cloud-of-points-with-specified-maximum-diameter-in-pos

### Using ClusterWithin VS ClusterDBSCAN
https://gis.stackexchange.com/questions/348484/clustering-points-in-postgis

Explains how DBSCAN is a superset of ClusterWithin, and provides simpler, more powerful SQL.

### Removing Clusters of Points
https://gis.stackexchange.com/questions/356663/postgis-finding-duplicate-label-within-a-radius

### Cluster with DBSCAN partitioned by polygons
https://gis.stackexchange.com/questions/284190/python-cluster-points-with-dbscan-keeping-into-account-polygon-boundaries?rq=1

### Compute centroid of a group of points
https://gis.stackexchange.com/questions/269407/centroid-of-point-cluster-points

### FInd polygons which are not close to any other polygon
https://gis.stackexchange.com/questions/312167/calculating-shortest-distance-between-polygons
Solution
Use `ST_GeometricMedian`

### Cluster with DBSCAN partitioned by record types
https://gis.stackexchange.com/questions/357838/how-to-cluster-points-with-st-clusterdbscan-taking-into-account-their-type-store

### Select evenly-distributed points of unevenly-distributed set, with priority
https://gis.stackexchange.com/questions/346412/select-evenly-distirbuted-points-of-unevenly-distributed-set

### Construct K-Means clusters for each Polygon
https://gis.stackexchange.com/questions/376563/cluster-points-in-each-polygon-into-n-parts 

Use window function PARTITION BY


## Surface Interpolation
### IDW Interpolation over a grid of points
https://gis.stackexchange.com/questions/373153/spatial-interpolation-in-postgis-without-outputting-raster


## Concave Hull
### Improve Concave Hull algorithm
https://carto.com/blog/calculating-catchment-human-mobility-data/

## Cleaning Data
### Validating Polygons
https://gis.stackexchange.com/questions/1060/what-are-the-implications-of-invalid-geometries?noredirect=1&lq=1

### Removing Ring Self-Intersections / MakeValid
https://gis.stackexchange.com/questions/15286/ring-self-intersections-in-postgis?rq=1
The question and standard answer (buffer(0) are fairly mundane. But note the answer where the user uses MakeValid and keeps only the result polygons with significant area.  Might be a good option to MakeValid?

### Removing Slivers
https://gis.stackexchange.com/questions/289717/fix-slivers-holes-between-polygons-generated-after-removing-spikes

### Spike Removing
https://trac.osgeo.org/postgis/wiki/UsersWikiExamplesSpikeRemover

https://gasparesganga.com/labs/postgis-normalize-geometry/


## Conflation / Matching
### Adjust polygons to fill a containing Polygon
https://gis.stackexchange.com/questions/91889/adjusting-polygons-to-boundary-and-filling-holes?rq=1

### Match Polygons by Shape Similarity 
https://gis.stackexchange.com/questions/362560/measuring-the-similarity-of-two-polygons-in-postgis

There are different ways to measure the similarity between two polygons such as average distance between the boundaries, Hausdorff distance, Turning Function, Comparing Fourier Transformation of the two polygons

Gives code for Average Boundary Distance

### Find Polygon with more accurate linework
https://gis.stackexchange.com/questions/257052/given-two-polygons-find-the-the-one-with-more-detailed-accurate-shoreline

### Match sets of LineStrings
https://gis.stackexchange.com/questions/347787/compare-two-set-of-linestrings

### Match paths to road network
https://gis.stackexchange.com/questions/349001/aligning-line-with-closest-line-segment-in-postgis

### Match paths
https://gis.stackexchange.com/questions/368146/matching-segments-within-tracks-in-postgis

### Polygon Averaging
https://info.crunchydata.com/blog/polygon-averaging-in-postgis

Solution: Overlay, count “depth” of each resultant, union resultants of desired depth.


## Coordinate Systems

### Find a good planar projection
https://gis.stackexchange.com/questions/275057/how-to-find-good-meter-based-projection-in-postgis

Also https://gis.stackexchange.com/questions/341243/postgis-buffer-in-meters-without-geography

### ST_Transform creates invalid geometry
https://gis.stackexchange.com/questions/341160/why-do-two-tables-with-valid-geometry-return-self-intersection-errors-when-inter

Also:  https://trac.osgeo.org/postgis/ticket/4755
Has an example geometry which becomes invalid under transform

## Miscellaneous

### Seaway Distances & Routes
https://www.ausvet.com.au/seaway-distances-with-postgresql/


## Linear Referencing/Line Handling
### Extrapolate Lines
https://gis.stackexchange.com/questions/33055/extrapolating-a-line-in-postgis

ST_LineInterpolatePoint should be enhanced to allow fractions outside [0,1].

### Extend a LineString to the boundary of a polygon
https://gis.stackexchange.com/questions/345463/how-can-i-extend-a-linestring-to-the-edge-of-an-enclosing-polygon-in-postgis

Ideas
A function ST_LineExtract(line, index1, index2) to extract a portion of a LineString between two indices

### Compute Angle at which Two Lines Intersect
https://gis.stackexchange.com/questions/25126/how-to-calculate-the-angle-at-which-two-lines-intersect-in-postgis?rq=1

### Compute Azimuth at a Point on a Line
https://gis.stackexchange.com/questions/178687/rotate-point-along-line-layer

Solution
Would be nice to have a ST_SegmentIndex function to get the index of the segment nearest to a point.  Then this becomes simple.

### Compute Perpendicular Distance to a Baseline (AKA “Width” of a curve)
https://gis.stackexchange.com/questions/54575/how-to-calculate-the-depth-of-a-linestring-using-postgis?rq=1

### Measure Length of every LineString segment
https://gis.stackexchange.com/questions/239576/measure-length-of-each-segment-for-a-polygon-in-postgis
Solution
Use CROSS JOIN LATERAL with generate_series and ST_MakeLine, ST_Length
ST_DumpSegments would make this much easier!

### Find Lines that form Rings
https://gis.stackexchange.com/questions/32224/select-the-lines-that-form-a-ring-in-postgis
Solutions
Polygonize all lines, then identify lines which intersect each polygon
Complicated recursive solution using ST_LineMerge!

### Add intersection points between sets of Lines (AKA Noding)
https://gis.stackexchange.com/questions/41162/adding-multiple-points-to-a-linestring-in-postgis?rq=1
Problem
Add nodes into a road network from access side roads

Solutions
One post recommends simply unioning (overlaying) all the linework.  This was accepted, but has obvious problems:
Hard to extract just the road network lines
If side road falls slightly short will not create a node

### Merge lines that touch at endpoints
https://gis.stackexchange.com/questions/177177/finding-and-merging-lines-that-touch-in-postgis?rq=1

Solution given uses ST_ClusterWithin, which is clever.  Can be improved slightly however (e.g. can use ST_Boundary to get endpoints?).  Would be much nicer if ST_ClusterWithin was a window function.  

Could also use a recursive query to do a transitive closure of the “touches at endpoints” condition.  This would be a nice example, and would scale better.

Can also use ST_LineMerge to do this very simply (posted).

Also:

https://gis.stackexchange.com/questions/360795/merge-linestring-that-intersects-without-making-them-multilinestring
```
WITH data(geom) AS (VALUES
( 'LINESTRING (50 50, 150 100, 250 75)'::geometry )
,( 'LINESTRING (250 75, 200 0, 130 30, 100 150)'::geometry )
,( 'LINESTRING (100 150, 130 170, 220 190, 290 190)'::geometry )
)
SELECT ST_AsText(ST_LineMerge(ST_Collect(geom))) AS line 
FROM data;
```
### Merge lines that touch at endpoints 2
https://gis.stackexchange.com/questions/16698/join-intersecting-lines-with-postgis

Solution
https://gis.stackexchange.com/a/80105/14766

### Merge lines which do not form a single line
https://gis.stackexchange.com/questions/83069/cannot-st-linemerge-a-multilinestring-because-its-not-properly-ordered
Solution
Not possible with ST_LineMerge
Error is not obvious from return value though

See Also
https://gis.stackexchange.com/questions/139227/st-linemerge-doesnt-return-linestring?rq=1

### Extract Line Segments
https://gis.stackexchange.com/questions/174472/in-postgis-how-to-split-linestrings-into-their-individual-segments?rq=1

Need an ST_DumpSegments to do this!

### Remove Longest Segment from a LineString
https://gis.stackexchange.com/questions/372110/postgis-removing-the-longest-segment-of-a-linestring-and-rejoining-segments

Solution (part)
Remove longest segment, splitting linestring into two parts if needed.

Useful patterns in this code:

JOIN LATERAL generate_series to extract the line segments
array slicing to extract a subline containing a section of the original line

It would be clearer if parts of this SQL were wrapped in functions (e.g. perhaps an ST_LineSlice function, and a ST_DumpSegments function - which perhaps will become part of PostGIS one day).
```
WITH data(id, geom) AS (VALUES
    ( 1, 'LINESTRING (0 0, 1 1, 2.1 2, 3 3, 4 4)'::geometry )
),
longest AS (SELECT i AS iLongest, geom,
    ST_Distance(  ST_PointN( data.geom, s.i ),
                  ST_PointN( data.geom, s.i+1 ) ) AS dist
   FROM data JOIN LATERAL (
        SELECT i FROM generate_series(1, ST_NumPoints( data.geom )-1) AS gs(i)
     ) AS s(i) ON true
   ORDER BY dist LIMIT 1
)
SELECT 
  CASE WHEN iLongest > 2 THEN ST_AsText( ST_MakeLine(
    (ARRAY( SELECT (ST_DumpPoints(geom)).geom FROM longest))[1 : iLongest - 1]
  )) ELSE null END AS line1,
  CASE WHEN iLongest < ST_NumPoints(geom) - 1 THEN ST_AsText( ST_MakeLine(
    (ARRAY( SELECT (ST_DumpPoints(geom)).geom FROM longest))[iLongest + 1: ST_NumPoints(geom)]
  )) ELSE null END AS line2
FROM longest;
```
### Split Lines into Equal-length portions
https://gis.stackexchange.com/questions/97990/break-line-into-100m-segments/334305#334305

Modern solution using LATERAL:
```
WITH
data AS (
    SELECT * FROM (VALUES
        ( 'A', 'LINESTRING( 0 0, 200 0)'::geometry ),
        ( 'B', 'LINESTRING( 0 100, 350 100)'::geometry ),
        ( 'C', 'LINESTRING( 0 200, 50 200)'::geometry )
    ) AS t(id, geom)
)
SELECT ST_LineSubstring( d.geom, substart, 
    CASE WHEN subend > 1 THEN 1 ELSE subend END ) geom
FROM (SELECT id, geom, ST_Length(geom) len, 100 sublen FROM data) AS d
CROSS JOIN LATERAL (
    SELECT i,  
            (sublen * i)/len AS substart,
            (sublen * (i+1)) / len AS subend
        FROM generate_series(0, 
            floor( d.len / sublen )::integer ) AS t(i)
        WHERE (sublen * i)/len <> 1.0  
    ) AS d2;
```
 Need to update PG doc:  https://postgis.net/docs/ST_LineSubstring.html

See also 
https://gis.stackexchange.com/questions/346196/split-a-linestring-by-distance-every-x-meters-using-postgis

https://gis.stackexchange.com/questions/338128/postgis-points-along-a-line-arent-actually-falling-on-the-line
This one contains a nice utlity function to segment a line by length, by using ST_LineSubstring.  Possible candidate for inclusion?

https://gis.stackexchange.com/questions/360670/how-to-break-a-linestring-in-n-parts-in-postgis

### Merge Lines That Don’t Touch
https://gis.stackexchange.com/questions/332780/merging-lines-that-dont-touch-in-postgis

Solution
No builtin function to do this, but one can be created in PL/pgSQL.


### Measure/4D relation querying within linestring using PostGIS
https://gis.stackexchange.com/questions/340689/measuring-4d-relation-querying-within-linestring-using-postgis

Solution
Uses DumpPoint and windowing functions

### Construct evenly-spaced points along a polygon boundary
https://gis.stackexchange.com/questions/360199/get-list-of-equidistant-points-on-polygon-border-postgis

### Find Segment of Line Closest to Point to allow Point Insertion
https://gis.stackexchange.com/questions/368479/finding-line-segment-of-point-on-linestring-using-postgis

Currently requires iteration.
Would be nice if the Linear Referencing functions could return segment index.
See https://trac.osgeo.org/postgis/ticket/892
```
CREATE OR REPLACE FUNCTION ST_LineLocateN( line geometry, pt geometry )
RETURNS integer
AS $$
    SELECT i FROM (
    SELECT i, ST_Distance(
        ST_MakeLine( ST_PointN( line, s.i ), ST_PointN( line, s.i+1 ) ),
        pt) AS dist
      FROM generate_series(1, ST_NumPoints( line )-1) AS s(i)
      ORDER BY dist
    ) AS t LIMIT 1;
$$
LANGUAGE sql STABLE STRICT;
```
### Insert LineString Vertices at Closest Point(s)
https://gis.stackexchange.com/questions/40622/how-to-add-vertices-to-existing-linestrings
https://gis.stackexchange.com/questions/370488/find-closest-index-in-line-string-to-insert-new-vertex-using-postgis
https://gis.stackexchange.com/questions/41162/adding-multiple-points-to-a-linestring-in-postgis

ST_Snap does this nicely

SELECT ST_AsText( ST_Snap('LINESTRING (0 0, 9 9, 20 20)',
  'MULTIPOINT( (1 1.1), (12 11.9) )', 0.2));

## Graphs
### Find Shortest Path through linear network
Input Parameters: linear network MultiLineString, start point, end point

Start and End point could be snapped to nearest endpoints if not already in network
Maybe also function to snap a network?

“Longest Shortest Path” - perhaps: construct Convex Hull, take longest diameter, find shortest path between those points


https://gis.stackexchange.com/questions/295199/how-do-i-select-the-longest-connected-lines-from-postgis-st-approximatemedialaxi

## Temporal Trajectories

### Find Coincident Paths
https://www.cybertec-postgresql.com/en/intersecting-gps-tracks-to-identify-infected-individuals/

### Remove Stationary Points
https://gis.stackexchange.com/questions/290243/remove-points-where-user-was-stationary

## Input

### Parse Error loading OSM Polygons
https://gis.stackexchange.com/questions/346641/postgis-parse-error-invalid-geometry-after-using-st-multi-but-st-isvalid

#### Solution
Problem is incorrect order of columns, so trying to load an integer into a geometry field.
Better error messages would make this more obvious.

### Parse Error from non-WKT format text
https://gis.stackexchange.com/questions/311955/error-parse-error-invalid-geometry-postgis?noredirect=1&lq=1

## Output

### Generate GeoJSON Feature
https://gis.stackexchange.com/questions/112057/sql-query-to-have-a-complete-geojson-feature-from-postgis


