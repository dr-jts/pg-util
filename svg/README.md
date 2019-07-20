# PostGIS SVG Functions

This is a collection of PostgreSQL functions which allow easily converting PostGIS geometries into styled SVG documents.

## Installion

```
psql < ../svg-lib.sql
```

## Functions

* **SVGDoc** - Creates an SVG doc element from an array of content elements.  The bounding box of the geometries is provided
  as a `geometry`, in order to construct the SVG `viewbox` attribute.  Optional `width` and `height` arguments can be supplied
  for the view.  An optional `style` argument allows specifying CSS styling at the document level (see `SVGStyle` function)
  
