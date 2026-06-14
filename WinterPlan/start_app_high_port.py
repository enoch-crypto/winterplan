#!/usr/bin/env python3
"""
Streamlit应用启动脚本 - 使用高端口避免权限问题
"""

import subprocess
import sys

def main():
    """主函数"""
    print("=" * 50)
    print("寒假逆袭作战指挥部 - 高端口启动脚本")
    print("=" * 50)
    print("使用高端口（10000+）避免Windows权限问题")
    print()
    
    # 直接使用高端口启动
    port = 10086  # 使用一个容易记住的高端口
    
    print(f"启动端口: {port}")
    print(f"访问地址: http://localhost:{port}")
    print()
    print("按 Ctrl+C 停止应用")
    print("=" * 50)
    
    try:
        # 直接启动Streamlit，不检查依赖（假设已安装）
        cmd = [sys.executable, "-m", "streamlit", "run", "winter_plan_app.py", 
               "--server.port", str(port),
               "--server.headless", "false",
               "--browser.serverAddress", "localhost"]
        
        subprocess.run(cmd)
        
    except KeyboardInterrupt:
        print("\n应用已停止")
    except Exception as e:
        print(f"启动失败: {e}")
        print("\n可能的解决方案:")
        print("1. 检查是否安装了Streamlit: pip install streamlit")
        print("2. 尝试其他端口: python -m streamlit run winter_plan_app.py --server.port 10087")
        print("3. 以管理员身份运行此脚本")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())