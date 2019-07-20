# PostGIS SVG Functions

A collection of PostgreSQL functions which allow easily converting PostGIS geometries into styled SVG documents.

## Installion

```
psql < ../svg-lib.sql
```

## Functions

### SVGDoc

Creates an SVG doc element from an array of content elements.  

* `content` - an array of strings output as the content of the `<svg>` element
* `extent` - a `geometry` providing the bounding box of the geometries being output.
    Used to construct the SVG `viewbox` attribute.  
* `width` (opt) - width of view
* `height` (opt) - height of view
* `style` (opt) - specifies CSS styling at the document level (see `SVGStyle` function)
  
