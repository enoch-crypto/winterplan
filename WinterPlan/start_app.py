#!/usr/bin/env python3
"""
Streamlit应用启动脚本
避免批处理文件的编码问题
"""

import subprocess
import sys
import os

def check_dependencies():
    """检查依赖是否安装"""
    print("检查依赖包...")
    try:
        import streamlit
        import pandas
        import altair
        print(f"Streamlit版本: {streamlit.__version__}")
        print(f"Pandas版本: {pandas.__version__}")
        print(f"Altair版本: {altair.__version__}")
        return True
    except ImportError as e:
        print(f"依赖缺失: {e}")
        print("正在安装依赖包...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
            print("依赖安装完成")
            return True
        except subprocess.CalledProcessError:
            print("依赖安装失败，请手动运行: pip install -r requirements.txt")
            return False

def start_streamlit():
    """启动Streamlit应用"""
    print("\n启动Streamlit应用...")
    print("应用将在浏览器中打开")
    print("按Ctrl+C停止应用\n")
    
    # 尝试多个端口
    ports = [8501, 8502, 8503, 8504, 8505]
    
    for port in ports:
        print(f"尝试端口: {port}")
        try:
            # 启动Streamlit
            cmd = [sys.executable, "-m", "streamlit", "run", "winter_plan_app.py", 
                   "--server.port", str(port)]
            subprocess.run(cmd)
            return True
        except KeyboardInterrupt:
            print("\n应用已停止")
            return True
        except Exception as e:
            print(f"端口 {port} 失败: {e}")
            continue
    
    print("\n错误: 所有端口尝试失败")
    print("可能的原因:")
    print("1. 防火墙阻止了端口访问")
    print("2. 没有管理员权限")
    print("3. 端口范围被占用")
    print("\n建议:")
    print("1. 关闭其他Streamlit应用")
    print("2. 以管理员身份运行此脚本")
    print("3. 手动指定端口: streamlit run winter_plan_app.py --server.port 8506")
    return False

def main():
    """主函数"""
    print("=" * 50)
    print("寒假逆袭作战指挥部 - 启动脚本")
    print("=" * 50)
    
    # 检查Python版本
    if sys.version_info < (3, 8):
        print("错误: 需要Python 3.8或更高版本")
        return 1
    
    # 检查依赖
    if not check_dependencies():
        return 1
    
    # 启动应用
    if not start_streamlit():
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())