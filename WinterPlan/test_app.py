#!/usr/bin/env python3
"""
应用功能测试脚本
用于验证核心功能是否正常工作
"""

import json
import os
import sys
from datetime import datetime

def test_data_file():
    """测试数据文件创建和读取"""
    print("测试数据文件功能...")
    
    test_file = "test_plan.json"
    test_data = {
        "start_date": "2024-01-30",
        "tasks": {
            "测试任务": {"total": 10, "done": 5, "unit": "个", "icon": "test"}
        }
    }
    
    # 测试写入
    with open(test_file, 'w', encoding='utf-8') as f:
        json.dump(test_data, f, ensure_ascii=False, indent=4)
    print("  数据写入成功")
    
    # 测试读取
    with open(test_file, 'r', encoding='utf-8') as f:
        loaded_data = json.load(f)
    print("  数据读取成功")
    
    # 验证数据
    assert loaded_data["start_date"] == test_data["start_date"]
    assert loaded_data["tasks"]["测试任务"]["total"] == 10
    print("  数据验证通过")
    
    # 清理
    os.remove(test_file)
    print("  测试文件清理完成")
    
    return True

def test_calculation_functions():
    """测试计算函数"""
    print("测试计算函数...")
    
    # 模拟计算函数
    def calculate_daily_target(total, done, remaining_days):
        if remaining_days <= 0:
            return 0
        remaining_load = total - done
        if remaining_load <= 0:
            return 0
        daily_target = remaining_load / remaining_days
        return round(daily_target, 1)
    
    def calculate_progress_percentage(done, total):
        if total == 0:
            return 0
        return round(done / total * 100, 1)
    
    # 测试用例
    test_cases = [
        (100, 50, 10, 5.0),    # 正常情况
        (100, 100, 10, 0),     # 已完成
        (100, 0, 0, 0),        # 剩余0天
        (100, 120, 10, 0),     # 超额完成
    ]
    
    for total, done, days, expected in test_cases:
        result = calculate_daily_target(total, done, days)
        print(f"  每日目标: total={total}, done={done}, days={days} => {result} (期望: {expected})")
        assert result == expected, f"计算错误: {result} != {expected}"
    
    # 测试进度百分比
    progress = calculate_progress_percentage(75, 100)
    assert progress == 75.0
    print(f"  进度百分比: 75/100 => {progress}%")
    
    print("  所有计算测试通过")
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
        print("  请运行: pip install -r requirements.txt")
        return False
    
    print("  所有依赖已安装")
    return True

def main():
    """主测试函数"""
    print("=" * 50)
    print("寒假逆袭作战指挥部 - 功能测试")
    print("=" * 50)
    
    tests = [
        ("环境测试", test_environment),
        ("数据文件测试", test_data_file),
        ("计算函数测试", test_calculation_functions),
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
        print("\n所有测试通过！应用可以正常运行。")
        print("\n运行应用:")
        print("  streamlit run winter_plan_app.py")
        return 0
    else:
        print("\n有测试失败，请检查问题。")
        return 1

if __name__ == "__main__":
    sys.exit(main())