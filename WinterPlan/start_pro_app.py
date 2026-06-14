#!/usr/bin/env python3
"""
初三寒假作战指挥部 Pro - 启动脚本
Author: EnochW cowork with Deepseek-V3.2
"""

import subprocess
import sys
import os

def check_requirements():
    """检查依赖包"""
    try:
        import streamlit
        import pandas
        import altair
        print("✅ 所有依赖包已安装")
        return True
    except ImportError as e:
        print(f"❌ 缺少依赖包: {e}")
        print("正在安装依赖包...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
            print("✅ 依赖包安装完成")
            return True
        except subprocess.CalledProcessError:
            print("❌ 依赖包安装失败，请手动运行: pip install -r requirements.txt")
            return False

def main():
    """主函数"""
    print("=" * 60)
    print("初三寒假作战指挥部 Pro - 专业版")
    print("Author: EnochW cowork with Deepseek-V3.2")
    print("=" * 60)
    
    # 检查依赖
    if not check_requirements():
        print("❌ 依赖检查失败，无法启动应用")
        return
    
    # 检查应用文件
    if not os.path.exists("winter_plan_pro.py"):
        print("❌ 找不到 winter_plan_pro.py 文件")
        return
    
    print("🚀 正在启动专业版应用...")
    print("📱 请在浏览器中访问: http://localhost:10086")
    print("🔄 如果端口被占用，请按 Ctrl+C 停止后重试")
    print("-" * 60)
    
    try:
        # 使用高端口避免权限问题
        subprocess.run([
            sys.executable, "-m", "streamlit", "run", 
            "winter_plan_pro.py", 
            "--server.port", "10086",
            "--server.headless", "false",
            "--browser.serverAddress", "localhost"
        ])
    except KeyboardInterrupt:
        print("\n👋 应用已停止")
    except Exception as e:
        print(f"❌ 启动失败: {e}")

if __name__ == "__main__":
    main()