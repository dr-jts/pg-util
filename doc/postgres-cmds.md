## Postgres Queries

### List all functions

```
SELECT routines.routine_name, parameters.data_type, parameters.ordinal_position
FROM information_schema.routines
    LEFT JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
WHERE routines.specific_schema='public'
AND routines.routine_name LIKE 'svg%'
ORDER BY routines.routine_name, parameters.ordinal_position;
```
Or in psql:
```
\df [ pattern ]
```

### Drop function
```
DROP FUNCTION name(args, ...);
```


