#!/bin/bash

# 悦音播放器编译发布脚本（快捷入口）
# 完整功能请使用: ./scripts/build-release-push.sh

set -e

cd "$(dirname "$0")"

# 调用完整脚本
./scripts/build-release-push.sh "$@"
