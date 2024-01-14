#!/bin/bash

PROJECT_ROOT_PATH=$1
while read FILENAME; do
  LCOV_INPUT_FILES="$LCOV_INPUT_FILES -a \"$PROJECT_ROOT_PATH/coverage/$FILENAME\""
done < <( ls "$1/coverage/" )

eval lcov "${LCOV_INPUT_FILES}" -o $PROJECT_ROOT_PATH/coverage_report/combined_lcov.info --ignore-errors empty,empty

lcov --remove $PROJECT_ROOT_PATH/coverage_report/combined_lcov.info \
  "lib/bootstrap.dart" \
  "lib/app.dart" \
  "lib/main_*.dart" \
  "*.gm.dart" \
  "*.gr.dart" \
  "*.g.dart" \
  "*.freezed.dart" \
  "*.config.dart" \
  "*.module.dart" \
  "**/*_http_module.dart" \
  "**/http_client.dart" \
  "**/http_module.dart" \
  "**/usecase.dart" \
  "*/generated/*" \
  "*.theme_extension.dart" \
  "**/register_module.dart" \
  "**/env.dart" \
  "**/*_page.dart" \
  "*/widgets/*" \
  "**/*_log_*.dart" \
   "**/*_serializer.dart" \
  -o $PROJECT_ROOT_PATH/coverage_report/cleaned_combined_lcov.info \
  --ignore-errors unused,unused

cp $PROJECT_ROOT_PATH/coverage_report/cleaned_combined_lcov.info $PROJECT_ROOT_PATH/coverage/lcov.info