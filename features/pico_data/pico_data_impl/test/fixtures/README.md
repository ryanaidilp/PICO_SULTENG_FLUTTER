# API fixtures (recorded 2026-10-23, API 2.10.0)

Real responses from `https://pico-api.banuacoder.com/api/v1`, read-only GET. Large lists are trimmed to 1 or 2 rows (files named `*_sample.json`). The envelope and field names are unchanged. Copy them into `pico_data_impl/test/fixtures/` (task T09a, T09b).

Record again with the commands below. Use `| python3 -I -c` to trim long lists.

```bash
B=https://pico-api.banuacoder.com/api/v1
curl -s "$B/national/latest"                                           > national_latest.json
curl -s "$B/national?start_date=2023-07-01&end_date=2023-07-03"        > national_start_date_2023-07-01_end_date_2023-07-03.json
curl -s "$B/national?all=true"                                         > national_all_true_sample.json         # trim to last 2 rows
curl -s "$B/national/2020-03-02"                                       > national_2020-03-02.json              # error sample (400)
curl -s "$B/provinces"                                                 > provinces_per_page_2.json             # 34 items, pagination ignored
curl -s "$B/provinces/72"                                              > provinces_72.json
curl -s "$B/provinces/72/cases?start_date=2021-07-15&end_date=2021-07-16" > provinces_72_cases_start_date_2021-07-15_end_date_2021-07-16.json
curl -s "$B/provinces/72/cases?all=true"                               > provinces_72_cases_all_true_sample.json # trim to first 2 rows (descending)
curl -s "$B/provinces/cases?per_page=2"                                > provinces_cases_per_page_2.json
curl -s "$B/regencies?per_page=2"                                      > regencies_per_page_2.json
curl -s "$B/regencies/7271"                                            > regencies_7271.json
curl -s "$B/regencies/7271/cases"                                      > regencies_7271_cases_sample.json      # trim to 2 rows
curl -s "$B/hospitals?per_page=1"                                      > hospitals_per_page_1.json
curl -s "$B/task-forces?per_page=1"                                    > task-forces_per_page_1.json
curl -s "$B/vaccination/national?per_page=1"                           > vaccination_national_per_page_1.json
curl -s "$B/vaccination/province?per_page=1"                           > vaccination_province_per_page_1.json
curl -s "$B/vaccination/locations?per_page=1"                          > vaccination_locations_per_page_1.json
curl -s "$B/stats/test-types"                                          > stats_test-types.json
curl -s "$B/stats/tests"                                               > stats_tests_sample.json               # trim to last 2 rows
curl -s "$B/stats/gender"                                              > stats_gender_sample.json              # trim to last row
curl -s "$B/stats/gender/latest"                                       > stats_gender_latest.json
curl -s "$B/banners"                                                   > banners.json
curl -s "$B/banners?include_inactive=true"                             > banners_include_inactive_true.json
curl -s "$B/infographics?per_page=1"                                   > infographics_per_page_1.json
curl -s "$B/donations?per_page=1"                                      > donations_per_page_1.json
curl -s "$B/telemedicines?per_page=1"                                  > telemedicines_per_page_1.json
curl -s "$B/partners?per_page=2"                                       > partners_per_page_2.json
curl -s "$B/contacts?owner_type=hospital&owner_id=19"                  > contacts_owner_type_hospital_owner_id_19.json
```
