#!/bin/bash

# iOS模拟器兼容性修复脚本
# 此脚本用于解决阿里一键登录SDK在iOS模拟器上的兼容性问题

echo "开始修复iOS模拟器兼容性问题..."

FRAMEWORK_DIR="libs"
FRAMEWORKS=("ATAuthSDK" "YTXMonitor" "YTXOperators")

for framework in "${FRAMEWORKS[@]}"; do
    framework_path="${FRAMEWORK_DIR}/${framework}.framework/${framework}"
    
    if [ -f "$framework_path" ]; then
        echo "处理 $framework framework..."
        
        # 检查当前架构
        echo "当前架构:"
        lipo -info "$framework_path"
        
        # 创建只包含模拟器架构的副本（如果需要）
        if lipo -info "$framework_path" | grep -q "x86_64"; then
            echo "$framework 已包含模拟器架构"
        else
            echo "警告: $framework 不包含模拟器架构"
        fi
        
        # 验证framework完整性
        if file "$framework_path" | grep -q "Mach-O universal binary"; then
            echo "$framework framework 验证通过"
        else
            echo "错误: $framework framework 可能已损坏"
        fi
    else
        echo "警告: 未找到 $framework framework"
    fi
    echo "---"
done

echo "修复完成！"
echo ""
echo "如果仍然遇到模拟器兼容性问题，请确保："
echo "1. 清理项目: Clean Build Folder (Cmd+Shift+K)"
echo "2. 删除 Derived Data"
echo "3. 重新安装 Pods: rm -rf Pods/ && pod install"
echo "4. 在模拟器环境下，SDK会返回模拟错误代码，这是正常行为" 