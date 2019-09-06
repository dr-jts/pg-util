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

### svgDoc

Creates an SVG doc element from an array of content elements.

* `content` - an array of strings output as the content of the `<svg>` element
* `extent` - a `geometry` providing the bounding box of the geometries being output.
    Used to construct the SVG `viewbox` attribute.
* `width` (opt) - width of view
* `height` (opt) - height of view
* `style` (opt) - specifies CSS styling at the document level (see `SVGStyle` function)

### svgViewbox

Returns an SVG viewBox value determine from the envelope of a geometry.

### svgShape

Encodes a PostGIS geometry as an SVG shape.

### svgPolygon

Encodes an array of ordinates as an SVG polygon.

### svgStyle

Encodes an array of name,value pairs as a string of SVG CSS name:value; properties

### svgHSL

Encodes H,S,L values a CSS HSL function

### svgRandInt

Returns a random integer from a range [lo, hi] (inclusive)

### svgRandPick

Returns a random item from an array of integers
