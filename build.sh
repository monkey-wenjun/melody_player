#!/bin/bash

# 悦音播放器编译脚本（快捷入口）
# 完整功能请使用: ./scripts/build-release-push.sh

set -e

cd "$(dirname "$0")"

# 如果没有参数，只编译不上传
if [ $# -eq 0 ]; then
    echo "使用方式:"
    echo "  ./build.sh           # 仅编译 APK"
    echo "  ./build.sh '更新说明' # 编译并上传到 OSS"
    echo ""
    
    # 设置环境
    export PATH="$HOME/flutter/bin:$PATH"
    export ANDROID_HOME="$HOME/android-sdk"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
    
    # 获取版本
    VERSION=$(grep "appVersion = " lib/utils/constants.dart | cut -d"'" -f2)
    echo "开始编译 悦音播放器 v${VERSION}..."
    
    # 编译
    flutter clean
    flutter pub get
    flutter build apk --release
    
    # 复制到 release 目录
    mkdir -p build/release
    cp "build/app/outputs/flutter-apk/app-release.apk" "build/release/melody_player_v${VERSION}.apk"
    
    echo ""
    echo "✓ 编译完成!"
    echo "APK: build/release/melody_player_v${VERSION}.apk"
    ls -lh "build/release/"
else
    # 有参数，调用完整脚本
    ./scripts/build-release-push.sh "$@"
fi
