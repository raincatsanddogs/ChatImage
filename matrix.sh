#!/bin/bash

while [[ $# -gt 0 ]]; do
  case $1 in
    -path)
      IFS=',' read -r -a paths <<< "$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# 用于存储所有文件夹的数组
allFolderObjects=()

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required to generate the build matrix." >&2
  exit 1
fi

# 遍历每个路径
for path in "${paths[@]}"; do
  # 获取指定路径下的文件夹
  folders=$(find "$path" -mindepth 1 -maxdepth 1 -type d)

  # 过滤掉名为 "origin" 的文件夹
  for folder in $folders; do
    folderName=$(basename "$folder")
    if [[ "$folderName" != "origin" ]]; then
      skipFile="$folder/.ci-skip"
      if [[ -f "$skipFile" ]]; then
        skipReason=$(tr '\r\n' ' ' < "$skipFile")
        echo "Skipping $folderName: ${skipReason:-CI skip marker found}" >&2
        continue
      fi

      # 提取 mc-version 和 mc-loader 信息
      mcVersion="${folderName//$path-/}"
      mcLoader="$path"
      supportVersionFile="$mcLoader/$mcLoader-$mcVersion/support_version.txt"
      if [[ -f "$supportVersionFile" ]]; then
        supportVersion=$(cat "$supportVersionFile")
      else
        supportVersion="$mcVersion"
      fi

      if [ "$mcLoader" == "fabric" ]; then
        publishLoaders="fabric quilt"
      else
        publishLoaders="$mcLoader"
      fi
      allFolderObjects+=("$(jq -cn \
        --arg mcVersion "$mcVersion" \
        --arg mcLoader "$mcLoader" \
        --arg publishLoaders "$publishLoaders" \
        --arg publishVersion "$supportVersion" \
        '{
          "mc-version": $mcVersion,
          "mc-loader": $mcLoader,
          "publish-loaders": $publishLoaders,
          "publish-version": $publishVersion
        }')")
    fi
  done
done

# 创建并校验 JSON 格式的输出
if ((${#allFolderObjects[@]} == 0)); then
  json='{"config":[]}'
else
  json=$(printf '%s\n' "${allFolderObjects[@]}" | jq -sc '{config: .}')
fi

# 输出最终的 JSON 结果
printf 'matrix=%s\n' "$json" >> "$GITHUB_OUTPUT"
