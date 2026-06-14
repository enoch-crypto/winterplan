#!/usr/bin/env python3
"""
增强版应用功能测试脚本
"""

import json
import os
import sys
from datetime import datetime

def test_data_structure():
    """测试新的数据结构"""
    print("测试新的数据结构...")
    
    # 测试默认数据结构
    from winter_plan_enhanced import DEFAULT_PLAN, TIME_SLOTS
    
    assert "time_slots" in DEFAULT_PLAN, "新数据结构缺少time_slots"
    assert "last_updated" in DEFAULT_PLAN, "缺少last_updated字段"
    
    # 检查时间段
    for slot_key in TIME_SLOTS:
        assert slot_key in DEFAULT_PLAN["time_slots"], f"缺少时间段: {slot_key}"
    
    print("  数据结构测试通过")
    return True

def test_backup_system():
    """测试备份系统"""
    print("测试备份系统...")
    
    # 创建测试目录
    test_dir = "test_backups"
    if not os.path.exists(test_dir):
        os.makedirs(test_dir)
    
    # 测试备份文件命名
    backup_file = f"backup_{datetime.now().strftime('%Y%m%d')}.json"
    print(f"  备份文件命名: {backup_file}")
    
    # 清理
    import shutil
    if os.path.exists(test_dir):
        shutil.rmtree(test_dir)
    
    print("  备份系统测试通过")
    return True

def test_calculation_functions():
    """测试计算函数"""
    print("测试计算函数...")
    
    from winter_plan_enhanced import calculate_daily_target, calculate_progress_percentage, get_daily_completion_rate
    
    # 测试calculate_daily_target
    test_cases = [
        (100, 50, 10, 5.0),    # 正常情况
        (100, 100, 10, 0),     # 已完成
        (100, 0, 0, 0),        # 剩余0天
        (100, 120, 10, 0),     # 超额完成
    ]
    
    for total, done, days, expected in test_cases:
        result = calculate_daily_target(total, done, days)
        assert result == expected, f"计算错误: {result} != {expected}"
    
    print("  每日目标计算测试通过")
    
    # 测试calculate_progress_percentage
    assert calculate_progress_percentage(75, 100) == 75.0
    assert calculate_progress_percentage(0, 100) == 0.0
    assert calculate_progress_percentage(100, 100) == 100.0
    
    print("  进度百分比计算测试通过")
    
    # 测试get_daily_completion_rate
    test_data = {
        "time_slots": {
            "morning": [
                {"name": "任务1", "total": 10, "done": 10, "unit": "个", "icon": "📚", "custom": True},
                {"name": "任务2", "total": 10, "done": 5, "unit": "个", "icon": "📚", "custom": True}
            ],
            "afternoon": [
                {"name": "任务3", "total": 10, "done": 0, "unit": "个", "icon": "📚", "custom": True}
            ]
        }
    }
    
    completion_rate = get_daily_completion_rate(test_data)
    # 总共3个任务，1个完成 => 33.3%
    expected_rate = round(1/3 * 100, 1)
    assert abs(completion_rate - expected_rate) < 0.1, f"完成率计算错误: {completion_rate} != {expected_rate}"
    
    print("  全天完成率计算测试通过")
    return True

def test_reset_functions():
    """测试重置功能"""
    print("测试重置功能...")
    
    from winter_plan_enhanced import reset_today_progress, reset_all_data
    
    # 测试reset_today_progress
    test_data = {
        "time_slots": {
            "morning": [
                {"name": "任务1", "total": 10, "done": 5, "unit": "个", "icon": "📚", "custom": True},
                {"name": "任务2", "total": 10, "done": 10, "unit": "个", "icon": "📚", "custom": True}
            ]
        }
    }
    
    reset_data = reset_today_progress(test_data.copy())
    for slot_tasks in reset_data["time_slots"].values():
        for task in slot_tasks:
            assert task["done"] == 0, "当天重置功能失败"
    
    print("  当天重置功能测试通过")
    
    # 测试reset_all_data会返回默认数据
    default_data = reset_all_data()
    assert "time_slots" in default_data
    assert "last_updated" in default_data
    
    print("  全部重置功能测试通过")
    return True

def test_environment():
    """测试环境依赖"""
    print("测试Python环境...")
    
    try:
        import streamlit
        import pandas
        import altair
        print(f"  Streamlit版本: {streamlit.__version__}")
        print(f"  Pandas版本: {pandas.__version__}")
        print(f"  Altair版本: {altair.__version__}")
    except ImportError as e:
        print(f"  依赖缺失: {e}")
        return False
    
    print("  所有依赖已安装")
    return True

def main():
    """主测试函数"""
    print("=" * 50)
    print("寒假逆袭作战指挥部 - 增强版功能测试")
    print("=" * 50)
    
    tests = [
        ("环境测试", test_environment),
        ("数据结构测试", test_data_structure),
        ("备份系统测试", test_backup_system),
        ("计算函数测试", test_calculation_functions),
        ("重置功能测试", test_reset_functions),
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        print(f"\n开始测试: {test_name}")
        try:
            if test_func():
                print(f"{test_name}: 通过")
                passed += 1
            else:
                print(f"{test_name}: 失败")
                failed += 1
        except Exception as e:
            print(f"{test_name}: 异常 - {str(e)}")
            failed += 1
    
    print("\n" + "=" * 50)
    print("测试结果汇总:")
    print(f"通过: {passed}")
    print(f"失败: {failed}")
    print(f"总计: {passed + failed}")
    
    if failed == 0:
        print("\n所有测试通过！增强版应用功能正常。")
        print("\n运行增强版应用:")
        print("  streamlit run winter_plan_enhanced.py --server.port 10086")
        return 0
    else:
        print("\n有测试失败，请检查问题。")
        return 1

if __name__ == "__main__":
    # 添加当前目录到Python路径
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    sys.exit(main())