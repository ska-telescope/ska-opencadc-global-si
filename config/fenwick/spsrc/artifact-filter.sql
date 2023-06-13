-- When org.opencadc.fenwick.artifactSelector=filter is specified, this config file
-- specifying the included Artifacts is required. The single clause in the SQL file
-- MUST begin with the WHERE keyword.
-- ex:
-- WHERE uri LIKE '%SOME CONDITION%'
where split_part(uri,'/',1) in (
    'cadc:CGPS',
    'cadc:VGPS',
    'cadc:VLASS',
    'cadc:WALLABY',
    'casda:RACS',
    'nrao:VLASS'
)
