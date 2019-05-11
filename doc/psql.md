## psql Commands

### Formatting

* `\pset format aligned` - show table formatting
* `\pset format unaligned` - do not show table formatting

### Command-line usage

Run SQL file sending raw output to another file
```
psql -A -t -o file.out  < query.sql
```
