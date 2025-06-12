#!/bin/bash

echo "🚨 [RNAliOnepass] 紧急修复脚本 v3.5.6"
echo "========================================"
echo "修复编译错误: linker command failed with exit code 1"
echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 查找主项目目录
MAIN_PROJECT=""
if [ -d "../../../AllSpirit" ]; then
    MAIN_PROJECT="../../../AllSpirit"
elif [ -d "../../AllSpirit" ]; then
    MAIN_PROJECT="../../AllSpirit"
elif [ -d "../AllSpirit" ]; then
    MAIN_PROJECT="../AllSpirit"
else
    echo -e "${YELLOW}⚠️  请手动输入你的主项目路径:${NC}"
    read -p "主项目路径: " MAIN_PROJECT
fi

if [ ! -d "${MAIN_PROJECT}" ]; then
    echo -e "${RED}❌ 找不到主项目目录: ${MAIN_PROJECT}${NC}"
    exit 1
fi

echo -e "${BLUE}📁 主项目目录: ${MAIN_PROJECT}${NC}"

IOS_DIR="${MAIN_PROJECT}/ios"
if [ ! -d "${IOS_DIR}" ]; then
    echo -e "${RED}❌ 找不到iOS目录: ${IOS_DIR}${NC}"
    exit 1
fi

echo -e "${BLUE}📱 iOS目录: ${IOS_DIR}${NC}"
echo

# 步骤1: 清理项目
echo -e "${YELLOW}🧹 步骤1: 清理项目${NC}"
echo "----------------------------------------"

cd "${IOS_DIR}"

echo "删除 Pods 目录..."
rm -rf Pods/

echo "删除 Podfile.lock..."
rm -f Podfile.lock

echo "清理 Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/AllSpirit*

echo "清理 node_modules..."
cd "${MAIN_PROJECT}"
rm -rf node_modules/

echo -e "${GREEN}✅ 清理完成${NC}"
echo

# 步骤2: 重新安装依赖
echo -e "${YELLOW}📦 步骤2: 重新安装依赖${NC}"
echo "----------------------------------------"

echo "重新安装 npm 依赖..."
npm install
# 或者使用 yarn install 如果项目使用 yarn

echo "重新安装 iOS 依赖..."
cd "${IOS_DIR}"
pod install --repo-update

echo -e "${GREEN}✅ 依赖安装完成${NC}"
echo

# 步骤3: 检查 Podfile 配置
echo -e "${YELLOW}⚙️  步骤3: 检查 Podfile 配置${NC}"
echo "----------------------------------------"

PODFILE_PATH="${IOS_DIR}/Podfile"
if [ -f "${PODFILE_PATH}" ]; then
    echo "检查 Podfile 中的架构设置..."
    
    if ! grep -q "EXCLUDED_ARCHS" "${PODFILE_PATH}"; then
        echo -e "${YELLOW}⚠️  建议在 Podfile 中添加以下配置:${NC}"
        echo
        cat << 'EOF'
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
EOF
        echo
        read -p "是否要自动添加这个配置? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 备份原文件
            cp "${PODFILE_PATH}" "${PODFILE_PATH}.backup"
            
            # 检查是否已有 post_install
            if grep -q "post_install" "${PODFILE_PATH}"; then
                echo "发现已有 post_install 配置，请手动添加架构设置"
            else
                cat >> "${PODFILE_PATH}" << 'EOF'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
EOF
                echo -e "${GREEN}✅ 配置已添加到 Podfile${NC}"
                echo "重新运行 pod install..."
                pod install
            fi
        fi
    else
        echo -e "${GREEN}✅ Podfile 配置正常${NC}"
    fi
else
    echo -e "${RED}❌ 找不到 Podfile${NC}"
fi

echo

# 步骤4: 构建测试
echo -e "${YELLOW}🔨 步骤4: 构建测试${NC}"
echo "----------------------------------------"

echo "现在请尝试以下步骤:"
echo "1. 在 Xcode 中打开 ${IOS_DIR}/AllSpirit.xcworkspace"
echo "2. 选择模拟器设备"
echo "3. 执行 Product -> Clean Build Folder (Cmd+Shift+K)"
echo "4. 执行 Product -> Build (Cmd+B)"
echo

echo -e "${BLUE}🔍 如果仍有问题，请检查:${NC}"
echo "- Xcode 控制台中的具体错误信息"
echo "- 是否有其他依赖库的冲突"
echo "- React Native 版本兼容性"
echo

echo -e "${GREEN}✅ 紧急修复脚本完成${NC}"
echo "如果问题持续，请提供完整的错误日志以便进一步诊断" 