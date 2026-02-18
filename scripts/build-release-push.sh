#!/bin/bash

# 悦音播放器编译上传脚本（仅上传OSS，不调用接口）
# 使用方法:
#   ./scripts/build-release-push.sh [提交信息]
#
# 示例:
#   ./scripts/build-release-push.sh "修复播放问题"

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="悦音播放器"
APP_NAME_EN="melody_player"
APK_OUTPUT_DIR="build/app/outputs/flutter-apk"
CONSTANTS_FILE="lib/utils/constants.dart"

# OSS 配置
CONFIG_FILE="$HOME/my_blog/_config.yml"
OSS_BUCKET="file201503"
OSS_ENDPOINT="oss-cn-shanghai.aliyuncs.com"
OSS_DIR="music"
DOWNLOAD_BASE_URL="https://file.awen.me"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP $1]${NC} $2"; }

# 加载 YAML 配置
parse_yaml() {
    local file=$1
    # 提取 ali-oss 下的 accessKeyId 和 accessKeySecret
    OSS_ACCESS_KEY_ID=$(grep -A 10 "type: ali-oss" "$file" | grep "accessKeyId:" | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'" | tr -d ' ')
    OSS_ACCESS_KEY_SECRET=$(grep -A 10 "type: ali-oss" "$file" | grep "accessKeySecret:" | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'" | tr -d ' ')
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "加载配置: $CONFIG_FILE"
        parse_yaml "$CONFIG_FILE"
    else
        log_warn "配置文件不存在: $CONFIG_FILE"
        log_warn "将尝试使用环境变量"
        
        if [ -z "$OSS_ACCESS_KEY_ID" ] || [ -z "$OSS_ACCESS_KEY_SECRET" ]; then
            log_error "请设置 OSS_ACCESS_KEY_ID 和 OSS_ACCESS_KEY_SECRET 环境变量"
            exit 1
        fi
    fi
}

# 获取当前版本号
get_version() {
    grep "appVersion = " "$PROJECT_DIR/$CONSTANTS_FILE" | cut -d"'" -f2
}

# 设置环境
setup_environment() {
    log_info "设置编译环境..."
    
    # Flutter
    if [ -d "$HOME/flutter/bin" ]; then
        export PATH="$HOME/flutter/bin:$PATH"
    fi
    
    # Android SDK
    if [ -d "$HOME/android-sdk" ]; then
        export ANDROID_HOME="$HOME/android-sdk"
        export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
    fi
    
    # 验证环境
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter 未找到"
        exit 1
    fi
    
    log_info "环境设置完成"
}

# 编译 APK
build_apk() {
    log_step "1" "编译 Release APK"
    
    cd "$PROJECT_DIR"
    
    # 清理
    log_info "清理旧构建..."
    flutter clean
    flutter pub get
    
    # 编译
    log_info "开始编译..."
    flutter build apk --release
    
    if [ $? -ne 0 ]; then
        log_error "编译失败!"
        exit 1
    fi
    
    log_success "编译成功"
}

# 准备 APK（带版本号）
prepare_apk() {
    local version_name=$1
    
    local src_file="${APK_OUTPUT_DIR}/app-release.apk"
    # 使用英文名
    local dest_file="${APK_OUTPUT_DIR}/${APP_NAME_EN}_v${version_name}.apk"
    
    cp "$src_file" "$dest_file"
    echo "$dest_file"
}

# 上传到 OSS
upload_to_oss() {
    local file=$1
    local version_name=$2
    
    log_step "2" "上传到阿里云 OSS"
    
    local filename=$(basename "$file")
    local remote_path="$OSS_DIR/$filename"
    
    log_info "文件: $filename"
    log_info "目标: oss://$OSS_BUCKET/$remote_path"
    
    local py_script=$(mktemp)
    cat > "$py_script" << PYEOF
import oss2
import sys

auth = oss2.Auth('$OSS_ACCESS_KEY_ID', '$OSS_ACCESS_KEY_SECRET')
bucket = oss2.Bucket(auth, '$OSS_ENDPOINT', '$OSS_BUCKET')

local_file = '$file'
remote_path = '$remote_path'

print(f'上传中...')
bucket.put_object_from_file(remote_path, local_file)
print(f'✓ 上传成功')
print(f'URL: $DOWNLOAD_BASE_URL/{remote_path}')
PYEOF
    
    python3 "$py_script"
    rm -f "$py_script"
    
    echo "$filename"
}

# 显示发布信息
show_release_info() {
    local apk_file=$1
    local version_name=$2
    local remote_filename=$3
    
    echo ""
    echo "========================================"
    echo "     $APP_NAME 编译上传完成!"
    echo "========================================"
    echo ""
    echo -e "${CYAN}版本信息:${NC}"
    echo "  版本名: $version_name"
    echo ""
    echo -e "${CYAN}APK 信息:${NC}"
    echo "  文件: $(basename "$apk_file")"
    echo "  大小: $(du -h "$apk_file" | cut -f1)"
    echo "  MD5:  $(md5sum "$apk_file" | cut -d' ' -f1)"
    echo ""
    echo -e "${CYAN}下载链接:${NC}"
    echo "  $DOWNLOAD_BASE_URL/$OSS_DIR/$remote_filename"
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "  $APP_NAME 编译上传脚本"
    echo "========================================"
    echo ""
    
    # 获取版本
    VERSION_NAME=$(get_version)
    log_info "当前版本: $VERSION_NAME"
    
    # 加载配置
    load_config
    
    # 设置环境
    setup_environment
    
    # 切换到项目目录
    cd "$PROJECT_DIR"
    log_info "工作目录: $(pwd)"
    
    # 步骤1: 编译
    build_apk
    
    # 步骤2: 准备 APK
    RELEASE_APK=$(prepare_apk "$VERSION_NAME")
    REMOTE_FILENAME=$(basename "$RELEASE_APK")
    
    # 步骤3: 上传
    upload_to_oss "$RELEASE_APK" "$VERSION_NAME"
    
    # 显示发布信息
    show_release_info "$RELEASE_APK" "$VERSION_NAME" "$REMOTE_FILENAME"
    
    log_success "上传完成！"
}

# 执行主函数
main "$@"
