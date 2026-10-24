# sulteng.json provenance

- **Source:** the old PICO boundary file `sulteng.json`, kept in
  `PICO/legacy-assets/web/geojson/` (in the old repository since 2020-05-23,
  edited 2021-08-18). Origin and licence are not recorded anywhere. This is
  open item O-7. Do not describe the data as open or credit an author until the
  owner names one or replaces the file with boundaries whose terms are known.
- **Changes** (`dart run tool/normalize_geojson.dart <old> assets/geojson/sulteng.json`):
  - added `properties.code` from the C02 name table (13 codes, both spellings of
    Parigi Moutong map to 7208);
  - simplified with Douglas-Peucker, the smallest tolerance that fits 60 KB
    (61,440 bytes), coordinates rounded to 4 decimals;
  - added `properties.labelPoint` (`[lon, lat]`, inside the largest ring);
  - features sorted by code, all geometries written as MultiPolygon.
- **Licence status:** unknown (O-7).
