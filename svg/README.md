# SVG Functions

A collection of PostgreSQL functions which allow easily creating SVG graphics.
The main goal of the API is to allow converting PostGIS geometries into styled SVG documents.
But the functions are written to be modular enough to allow using them
for simple geometry generation without PostGIS.

## Installation

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
