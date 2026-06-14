"""
初三寒假作战指挥部 Pro - 主应用文件
整合 data_logic.py 和 ui_view.py 模块
Author: EnochW cowork with Deepseek-V3.2
"""

import streamlit as st
import pandas as pd
import altair as alt
from datetime import datetime, timedelta
from data_logic import *
from ui_view import *

# ==========================================
# 主应用逻辑
# ==========================================
def main():
    """主函数"""
    # 1. 设置页面
    setup_page()
    
    # 2. 加载数据
    plan_data = load_data()
    
    # 3. 渲染侧边栏
    day_diff, days_left = render_sidebar(plan_data)
    
    # 4. 侧边栏功能
    plan_data = render_undo_redo(plan_data)
    plan_data = render_data_management(plan_data)
    plan_data = render_reset_options(plan_data)
    plan_data = render_task_management(plan_data)
    
    # 5. 主界面内容
    render_time_schedule()
    plan_data = render_task_management_table(plan_data, days_left)
    plan_data = render_time_logging(plan_data)
    
    # 6. 渲染数据可视化
    render_data_visualization(plan_data)
    
    # 7. 渲染历史记录
    render_history_view(plan_data)

def render_data_visualization(plan_data):
    """渲染数据可视化"""
    st.markdown("---")
    st.markdown("### 📈 学习进度可视化")
    
    tab1, tab2, tab3 = st.tabs(["📊 日完成率曲线", "⭐ 自评分趋势", "📅 综合统计"])
    
    with tab1:
        # 日完成率曲线图
        st.subheader("日完成率曲线")
        
        # 模拟过去7天的数据
        dates = [(datetime.now() - timedelta(days=i)).strftime("%m-%d") for i in range(6, -1, -1)]
        completion_rates = [get_daily_completion_rate(plan_data)] * 7  # 简化处理
        
        chart_data = pd.DataFrame({
            "日期": dates,
            "完成率": completion_rates
        })
        
        line_chart = alt.Chart(chart_data).mark_line(point=True).encode(
            x=alt.X("日期", sort=None),
            y=alt.Y("完成率", scale=alt.Scale(domain=[0, 100])),
            tooltip=["日期", "完成率"]
        ).properties(
            title="过去7天完成率趋势",
            width=600,
            height=300
        )
        
        st.altair_chart(line_chart, use_container_width=True)
    
    with tab2:
        # 自评分趋势
        st.subheader("任务自评分分布")
        
        if plan_data["tasks"]:
            # 获取有自评分的任务
            rated_tasks = [task for task in plan_data["tasks"] if task.get("self_rating", 0) > 0]
            
            if rated_tasks:
                rating_data = pd.DataFrame({
                    "任务": [task["name"] for task in rated_tasks],
                    "自评分": [task["self_rating"] for task in rated_tasks],
                    "模块": [task["module"] for task in rated_tasks]
                })
                
                bar_chart = alt.Chart(rating_data).mark_bar().encode(
                    x=alt.X("任务", sort="-y"),
                    y="自评分",
                    color="模块",
                    tooltip=["任务", "自评分", "模块"]
                ).properties(
                    title="任务自评分分布",
                    width=600,
                    height=300
                )
                
                st.altair_chart(bar_chart, use_container_width=True)
            else:
                st.info("暂无任务自评分数据")
        else:
            st.info("暂无任务数据")
    
    with tab3:
        # 综合统计
        st.subheader("综合学习统计")
        
        if plan_data["tasks"]:
            # 计算各项统计
            total_progress = sum(calculate_progress_percentage(task["done"], task["total"]) for task in plan_data["tasks"]) / len(plan_data["tasks"])
            avg_self_rating = get_daily_self_rating(plan_data)
            daily_completion = get_daily_completion_rate(plan_data)
            
            col1, col2, col3 = st.columns(3)
            with col1:
                st.metric("📈 平均进度", f"{total_progress:.1f}%")
            with col2:
                st.metric("⭐ 平均自评分", f"{avg_self_rating:.1f}" if avg_self_rating > 0 else "暂无")
            with col3:
                st.metric("🎯 今日完成率", f"{daily_completion}%")
            
            # 模块进度统计
            module_progress = {}
            for task in plan_data["tasks"]:
                module = task["module"]
                progress = calculate_progress_percentage(task["done"], task["total"])
                if module not in module_progress:
                    module_progress[module] = {"total": 0, "count": 0}
                module_progress[module]["total"] += progress
                module_progress[module]["count"] += 1
            
            if module_progress:
                st.write("**模块进度对比:**")
                for module, stats in module_progress.items():
                    avg_progress = stats["total"] / stats["count"]
                    st.progress(avg_progress / 100, text=f"{module}: {avg_progress:.1f}%")
        else:
            st.info("暂无统计数据显示")

def render_history_view(plan_data):
    """渲染历史记录查看"""
    st.markdown("---")
    st.markdown("### 📜 操作历史记录")
    
    if "history" in plan_data and plan_data["history"]:
        # 显示最近10条历史记录
        recent_history = plan_data["history"][-10:] if len(plan_data["history"]) > 10 else plan_data["history"]
        
        for i, record in enumerate(reversed(recent_history)):
            with st.expander(f"{record['timestamp']} - {record['action']}"):
                st.write(f"**操作时间:** {record['timestamp']}")
                st.write(f"**操作类型:** {record['action']}")
                
                # 显示任务快照
                if record["tasks"]:
                    st.write("**任务状态:**")
                    task_df = pd.DataFrame(record["tasks"])
                    st.dataframe(task_df[["name", "total", "done", "unit", "self_rating"]], use_container_width=True)
    else:
        st.info("暂无历史记录")

def render_time_logging_stats(plan_data):
    """渲染时间统计"""
    st.markdown("---")
    st.markdown("### 📊 今日学习统计")
    
    today_str = datetime.now().strftime("%Y-%m-%d")
    today_logs = [log for log in plan_data.get("time_logs", []) 
                 if log.get("start_time", "").startswith(today_str) and log.get("duration")]
    
    if today_logs:
        total_duration = sum(log["duration"] for log in today_logs)
        module_stats = {}
        for log in today_logs:
            module = log["module"]
            module_stats[module] = module_stats.get(module, 0) + log["duration"]
        
        col1, col2 = st.columns(2)
        with col1:
            st.metric("⏱️ 总学习时长", f"{total_duration} 分钟")
        with col2:
            st.metric("📚 学习模块数", len(module_stats))
        
        # 显示模块分布
        if module_stats:
            st.write("**模块分布:**")
            for module, duration in module_stats.items():
                st.progress(duration / (total_duration if total_duration > 0 else 1), 
                           text=f"{module}: {duration} 分钟")
    else:
        st.info("今日暂无学习记录")

# ==========================================
# 应用入口
# ==========================================
if __name__ == "__main__":
    main()