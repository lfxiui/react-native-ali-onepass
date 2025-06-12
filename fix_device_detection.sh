#!/bin/bash

echo "🔍 [RNAliOnepass] 真机环境问题诊断与修复脚本 v3.5.5"
echo "================================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 查找项目根目录
PROJECT_ROOT=""
if [ -f "package.json" ]; then
    PROJECT_ROOT="."
elif [ -f "../package.json" ]; then
    PROJECT_ROOT=".."
elif [ -f "../../package.json" ]; then
    PROJECT_ROOT="../.."
else
    echo -e "${RED}❌ 错误：找不到项目根目录 (package.json)${NC}"
    exit 1
fi

echo -e "${BLUE}📁 项目根目录: ${PROJECT_ROOT}${NC}"

# 查找iOS项目目录
IOS_DIR=""
if [ -d "${PROJECT_ROOT}/ios" ]; then
    IOS_DIR="${PROJECT_ROOT}/ios"
elif [ -d "${PROJECT_ROOT}/example/ios" ]; then
    IOS_DIR="${PROJECT_ROOT}/example/ios"
else
    echo -e "${RED}❌ 错误：找不到iOS项目目录${NC}"
    exit 1
fi

echo -e "${BLUE}📱 iOS项目目录: ${IOS_DIR}${NC}"
echo

# 1. 检查库版本和podspec
echo -e "${YELLOW}🔍 1. 检查库版本和配置${NC}"
echo "----------------------------------------"

if [ -f "${PROJECT_ROOT}/node_modules/react-native-ali-onepass/RNAliOnepass.podspec" ]; then
    PODSPEC_VERSION=$(grep "s.version" "${PROJECT_ROOT}/node_modules/react-native-ali-onepass/RNAliOnepass.podspec" | head -1 | sed 's/.*"\(.*\)".*/\1/')
    echo -e "当前podspec版本: ${GREEN}${PODSPEC_VERSION}${NC}"
    
    if [[ "${PODSPEC_VERSION}" < "3.5.5" ]]; then
        echo -e "${RED}⚠️  版本过低，需要更新到3.5.5或更高版本${NC}"
    else
        echo -e "${GREEN}✅ 版本符合要求${NC}"
    fi
else
    echo -e "${RED}❌ 找不到podspec文件${NC}"
fi

# 2. 检查阿里SDK文件
echo
echo -e "${YELLOW}🔍 2. 检查阿里SDK框架文件${NC}"
echo "----------------------------------------"

SDK_PATH="${PROJECT_ROOT}/node_modules/react-native-ali-onepass/ios/libs"
if [ -d "${SDK_PATH}" ]; then
    echo -e "SDK路径: ${GREEN}${SDK_PATH}${NC}"
    
    # 检查各个framework
    FRAMEWORKS=("ATAuthSDK" "YTXMonitor" "YTXOperators")
    for framework in "${FRAMEWORKS[@]}"; do
        FRAMEWORK_PATH="${SDK_PATH}/${framework}.framework"
        HEADER_PATH="${FRAMEWORK_PATH}/Headers/${framework}.h"
        
        if [ -d "${FRAMEWORK_PATH}" ]; then
            echo -e "  ✅ ${framework}.framework 存在"
            
            if [ -f "${HEADER_PATH}" ]; then
                echo -e "     ✅ 头文件存在: ${framework}.h"
            else
                echo -e "     ${RED}❌ 头文件缺失: ${framework}.h${NC}"
            fi
        else
            echo -e "  ${RED}❌ ${framework}.framework 缺失${NC}"
        fi
    done
else
    echo -e "${RED}❌ SDK路径不存在: ${SDK_PATH}${NC}"
fi

# 3. 检查Podfile配置
echo
echo -e "${YELLOW}🔍 3. 检查Podfile配置${NC}"
echo "----------------------------------------"

PODFILE_PATH="${IOS_DIR}/Podfile"
if [ -f "${PODFILE_PATH}" ]; then
    echo -e "Podfile路径: ${GREEN}${PODFILE_PATH}${NC}"
    
    # 检查架构排除设置
    if grep -q "EXCLUDED_ARCHS" "${PODFILE_PATH}"; then
        echo -e "  ✅ 发现架构排除设置"
        grep -n "EXCLUDED_ARCHS" "${PODFILE_PATH}" | head -3
    else
        echo -e "  ${YELLOW}⚠️  未发现架构排除设置，可能需要添加${NC}"
    fi
    
    # 检查预处理器定义
    if grep -q "GCC_PREPROCESSOR_DEFINITIONS" "${PODFILE_PATH}"; then
        echo -e "  ✅ 发现预处理器定义"
    else
        echo -e "  ${YELLOW}⚠️  未发现预处理器定义${NC}"
    fi
else
    echo -e "${RED}❌ 找不到Podfile: ${PODFILE_PATH}${NC}"
fi

# 4. 检查构建设置
echo
echo -e "${YELLOW}🔍 4. 检查项目构建设置${NC}"
echo "----------------------------------------"

PBXPROJ_PATH="${IOS_DIR}"/*.xcodeproj/project.pbxproj
if ls ${PBXPROJ_PATH} 1> /dev/null 2>&1; then
    PBXPROJ_FILE=$(ls ${PBXPROJ_PATH} | head -1)
    echo -e "项目文件: ${GREEN}${PBXPROJ_FILE}${NC}"
    
    # 检查HEADER_SEARCH_PATHS
    if grep -q "HEADER_SEARCH_PATHS" "${PBXPROJ_FILE}"; then
        echo -e "  ✅ 发现头文件搜索路径配置"
    else
        echo -e "  ${YELLOW}⚠️  未发现头文件搜索路径配置${NC}"
    fi
else
    echo -e "${RED}❌ 找不到Xcode项目文件${NC}"
fi

# 5. 提供解决方案
echo
echo -e "${YELLOW}🛠️  解决方案${NC}"
echo "========================================"

echo -e "${BLUE}方案1: 清理并重新安装依赖${NC}"
echo "cd ${IOS_DIR}"
echo "rm -rf Pods"
echo "rm Podfile.lock"
echo "pod install --repo-update"
echo

echo -e "${BLUE}方案2: 手动添加Podfile配置${NC}"
cat << 'EOF'
在 iOS/Podfile 的 target 'YourApp' do 部分添加:

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 模拟器环境
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]'] = '$(inherited) RN_ALI_ONEPASS_SIMULATOR=1'
      
      # 真机环境
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS[sdk=iphoneos*]'] = '$(inherited) RN_ALI_ONEPASS_DEVICE=1'
    end
  end
end
EOF

echo
echo -e "${BLUE}方案3: 验证环境检测${NC}"
echo "1. 清理项目: Product -> Clean Build Folder"
echo "2. 真机运行前在 Xcode 控制台查看日志:"
echo "   搜索 '[RNAliOnepass]' 查看环境检测信息"
echo "3. 确认看到 '使用真机模式' 而不是 '使用模拟器模式'"

echo
echo -e "${GREEN}🎯 执行建议${NC}"
echo "========================================"
echo "1. 首先尝试方案1 (清理重装)"
echo "2. 如果问题仍存在，添加方案2的Podfile配置"
echo "3. 使用方案3验证修复结果"
echo

# 6. 自动修复选项
echo -e "${YELLOW}🔧 自动修复选项${NC}"
echo "========================================"
read -p "是否要自动执行清理和重新安装? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}开始自动修复...${NC}"
    
    cd "${IOS_DIR}"
    echo "1. 删除 Pods 目录..."
    rm -rf Pods
    
    echo "2. 删除 Podfile.lock..."
    rm -f Podfile.lock
    
    echo "3. 重新安装 Pods..."
    pod install --repo-update
    
    echo -e "${GREEN}✅ 自动修复完成!${NC}"
    echo "请在 Xcode 中重新构建项目并查看控制台日志"
else
    echo "跳过自动修复，请手动执行上述解决方案"
fi

echo
echo -e "${GREEN}📝 提示${NC}"
echo "如果问题仍然存在，请:"
echo "1. 检查控制台日志中的 [RNAliOnepass] 信息"
echo "2. 确认真机环境下预处理器定义是否正确"
echo "3. 验证阿里SDK框架是否正确链接" 