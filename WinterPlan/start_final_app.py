#!/usr/bin/env python3
"""
最终版应用启动脚本
包含完整时间表和所有功能
"""

import subprocess
import sys

def main():
    """主函数"""
    print("=" * 60)
    print("初三寒假作战指挥部 - 最终版启动脚本")
    print("=" * 60)
    print("版本: 3.0 (完整时间表 + 所有功能)")
    print("Author: EnochW cowork with Deepseek-V3.2")
    print()
    
    # 使用高端口启动
    port = 10086
    
    print(f"启动端口: {port}")
    print(f"访问地址: http://localhost:{port}")
    print()
    print("📅 完整时间表功能:")
    print("  08:30-09:00 ☀️ 启动 - 起床、早餐")
    print("  09:00-11:45 🧪 理化攻坚 - 物理压轴+化学二模")
    print("  11:45-12:30 🍲 午餐 - 午餐+简单活动")
    print("  12:30-13:00 💤 快速充电 - 午休30分钟")
    print("  13:00-16:00 📐 数英综合 - 数学几何+英语D篇")
    print("  16:00-18:00 ⚽ 激流勇进 - 足球/户外运动")
    print("  18:00-19:00 🍽️ 晚餐 - 晚餐+家庭交流")
    print("  19:00-20:30 📝 文科/复盘 - 历史道法+语文默写")
    print("  20:30-21:15 🎹 艺术留白 - 钢琴/电影/阅读")
    print("  21:15-21:45 🚿 洗漱睡觉 - 洗漱、准备就寝")
    print()
    print("✅ 核心功能:")
    print("  • 全天任务完成率统计")
    print("  • 详细时间表展示")
    print("  • 任务名称自定义")
    print("  • 两种重置方式")
    print("  • 自动数据备份")
    print()
    print("按 Ctrl+C 停止应用")
    print("=" * 60)
    
    try:
        # 启动最终版应用
        cmd = [sys.executable, "-m", "streamlit", "run", "winter_plan_final.py", 
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
        print("2. 尝试其他端口: python -m streamlit run winter_plan_final.py --server.port 10087")
        print("3. 检查文件是否存在: ls winter_plan_final.py")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())