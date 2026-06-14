#!/usr/bin/env python3
"""
增强版应用启动脚本
使用高端口避免Windows权限问题
"""

import subprocess
import sys

def main():
    """主函数"""
    print("=" * 50)
    print("寒假逆袭作战指挥部 - 增强版启动脚本")
    print("=" * 50)
    print("版本: 2.0 (时间段管理 + 任务自定义 + 数据备份)")
    print()
    
    # 使用高端口启动
    port = 10086
    
    print(f"启动端口: {port}")
    print(f"访问地址: http://localhost:{port}")
    print()
    print("增强版功能:")
    print("✅ 时间段任务管理 (上午/下午/晚上/灵活时间)")
    print("✅ 任务名称自定义")
    print("✅ 两种重置方式 (当天/全部)")
    print("✅ 自动数据备份")
    print("✅ 全天任务完成率统计")
    print()
    print("按 Ctrl+C 停止应用")
    print("=" * 50)
    
    try:
        # 启动增强版应用
        cmd = [sys.executable, "-m", "streamlit", "run", "winter_plan_enhanced.py", 
               "--server.port", str(port),
               "--server.headless", "false",
               "--browser.serverAddress", "localhost"]
        
        subprocess.run(cmd)
        
    except KeyboardInterrupt:
        print("\n应用已停止")
    except Exception as e:
        print(f"启动失败: {e}")
        print("\n可能的解决方案:")
        print("1. 检查依赖: pip install -r requirements.txt")
        print("2. 尝试其他端口: python -m streamlit run winter_plan_enhanced.py --server.port 10087")
        print("3. 运行原版应用: python start_app_high_port.py")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())