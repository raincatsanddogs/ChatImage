#!/bin/bash

set -euo pipefail

project_path="${1:?Usage: prefetch_modmenu.sh <project-path>}"
properties_file="$project_path/gradle.properties"

if [[ ! -f "$properties_file" ]]; then
  echo "Error: $properties_file does not exist." >&2
  exit 1
fi

modmenu_version=$(sed -n 's/^modmenu_version=//p' "$properties_file" | tr -d '\r')
if [[ -z "$modmenu_version" ]]; then
  echo "Error: modmenu_version is missing from $properties_file." >&2
  exit 1
fi

repository_root="${MAVEN_LOCAL_REPOSITORY:-$HOME/.m2/repository}"
artifact_dir="$repository_root/com/terraformersmc/modmenu/$modmenu_version"
artifact_file="$artifact_dir/modmenu-$modmenu_version.jar"
partial_file="$artifact_file.part"
artifact_url="https://maven.terraformersmc.com/releases/com/terraformersmc/modmenu/$modmenu_version/modmenu-$modmenu_version.jar"

mkdir -p "$artifact_dir"

if [[ ! -f "$artifact_file" ]]; then
  touch "$partial_file"
  downloaded=false

  for attempt in {1..20}; do
    if curl --fail --location --http1.1 --continue-at - --output "$partial_file" "$artifact_url"; then
      mv "$partial_file" "$artifact_file"
      downloaded=true
      break
    fi

    partial_size=$(wc -c < "$partial_file")
    echo "::warning::ModMenu $modmenu_version download attempt $attempt was interrupted after $partial_size bytes; resuming."
    sleep 2
  done

  if [[ "$downloaded" != "true" ]]; then
    echo "Error: failed to download ModMenu $modmenu_version after 20 resumable attempts." >&2
    exit 1
  fi
fi

if command -v jar >/dev/null 2>&1; then
  archive_is_valid() { jar tf "$artifact_file" >/dev/null; }
elif command -v unzip >/dev/null 2>&1; then
  archive_is_valid() { unzip -tqq "$artifact_file"; }
else
  echo "Error: jar or unzip is required to validate ModMenu." >&2
  exit 1
fi

if ! archive_is_valid; then
  echo "Error: downloaded ModMenu $modmenu_version is not a valid JAR." >&2
  exit 1
fi

pom_file="$artifact_dir/modmenu-$modmenu_version.pom"
printf '%s\n' \
  '<?xml version="1.0" encoding="UTF-8"?>' \
  '<project xmlns="http://maven.apache.org/POM/4.0.0">' \
  '  <modelVersion>4.0.0</modelVersion>' \
  '  <groupId>com.terraformersmc</groupId>' \
  '  <artifactId>modmenu</artifactId>' \
  "  <version>$modmenu_version</version>" \
  '</project>' > "$pom_file"

echo "Prefetched ModMenu $modmenu_version to Maven Local."
