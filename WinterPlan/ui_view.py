"""
初三寒假作战指挥部 Pro - 用户界面模块
包含所有Streamlit界面代码
Author: EnochW cowork with Deepseek-V3.2
"""

import streamlit as st
import pandas as pd
import altair as alt
from datetime import datetime, timedelta
from data_logic import *

# ==========================================
# 1. 环境自检与初始化
# ==========================================
def run_system_check():
    """检查必要的库是否安装"""
    try:
        import streamlit
        import pandas
        import altair
    except ImportError as e:
        st.error(f"❌ 环境缺失: {e}")
        st.info("请运行: pip install -r requirements.txt")
        st.stop()

run_system_check()

# ==========================================
# 2. 主界面布局
# ==========================================
def setup_page():
    """设置页面配置"""
    st.set_page_config(
        page_title="初三寒假作战指挥部 Pro", 
        page_icon="🚀", 
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # 作者信息
    st.markdown("""
    <div style="text-align: center; padding: 10px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; margin-bottom: 20px;">
        <h3 style="color: white; margin: 0;">Author: EnochW cowork with Deepseek-V3.2 | 专业版</h3>
    </div>
    """, unsafe_allow_html=True)

def render_sidebar(plan_data):
    """渲染侧边栏"""
    st.sidebar.title("⚙️ 专业版设置")
    
    start_date = datetime.strptime(plan_data["start_date"], "%Y-%m-%d")
    today = datetime.now()
    day_diff = (today - start_date).days + 1
    days_left = TOTAL_DAYS - day_diff + 1
    
    st.sidebar.info(f"📅 当前进度: 第 {day_diff} 天 / 共 {TOTAL_DAYS} 天")
    st.sidebar.warning(f"⏳ 剩余天数: {days_left} 天")
    
    return day_diff, days_left

def render_undo_redo(plan_data):
    """渲染撤销/恢复功能"""
    st.sidebar.subheader("↩️ 撤销/恢复")
    col1, col2 = st.sidebar.columns(2)
    
    with col1:
        if st.button("撤销", help="撤销上一次操作"):
            plan_data, success = undo_last_action(plan_data)
            if success:
                save_data(plan_data, save_history=False)
                st.sidebar.success("已撤销！")
                st.rerun()
            else:
                st.sidebar.warning("无法撤销")
    
    with col2:
        if st.button("恢复", help="恢复被撤销的操作"):
            plan_data, success = redo_action(plan_data)
            if success:
                save_data(plan_data)
                st.sidebar.success("已恢复！")
                st.rerun()
            else:
                st.sidebar.info("请刷新页面查看历史状态")
    
    return plan_data

def render_data_management(plan_data):
    """渲染数据管理选项"""
    st.sidebar.subheader("📊 数据管理")
    
    # 导出数据
    export_data = json.dumps(plan_data, ensure_ascii=False, indent=4)
    today = datetime.now()
    st.sidebar.download_button(
        label="📥 导出数据",
        data=export_data,
        file_name=f"study_plan_pro_{today.strftime('%Y%m%d_%H%M%S')}.json",
        mime="application/json",
        help="下载当前学习计划数据备份"
    )
    
    return plan_data

def render_reset_options(plan_data):
    """渲染重置选项"""
    st.sidebar.subheader("🔄 重置选项")
    reset_option = st.sidebar.radio(
        "选择重置类型:",
        ["当天进度重置", "全部数据重置"],
        help="当天重置只清零今日完成量，全部重置会恢复默认设置"
    )
    
    if st.sidebar.button("确认重置", type="secondary"):
        if reset_option == "当天进度重置":
            # 添加历史记录
            plan_data = add_history_record(plan_data, "重置当天进度")
            plan_data = reset_today_progress(plan_data)
            save_data(plan_data)
            st.sidebar.success("当天进度已重置！")
            st.rerun()
        else:
            confirm = st.sidebar.checkbox("⚠️ 确认要重置所有数据？此操作不可撤销！")
            if confirm:
                plan_data = reset_all_data()
                save_data(plan_data)
                st.sidebar.success("所有数据已重置！")
                st.rerun()
    
    return plan_data

def render_task_management(plan_data):
    """渲染任务管理"""
    st.sidebar.subheader("📝 任务管理")
    task_action = st.sidebar.selectbox("选择操作", ["添加新任务", "编辑现有任务", "删除任务"])
    
    if task_action == "添加新任务":
        with st.sidebar.form("add_task_form"):
            st.write("### 添加新任务")
            task_name = st.text_input("任务名称", placeholder="例如：额外练习题")
            task_total = st.number_input("总量", min_value=1, value=5)
            task_unit = st.text_input("单位", placeholder="例如：题、页、套")
            task_icon = st.selectbox("图标", ["📚", "✏️", "📖", "🔬", "🔢", "🌍", "🎵", "⚽", "🎨", "💻"])
            task_module = st.selectbox("所属模块", ["理化攻坚", "数英综合", "文科/复盘", "自定义"])
            
            if st.form_submit_button("添加任务"):
                # 添加历史记录
                plan_data = add_history_record(plan_data, "添加任务: " + task_name)
                
                # 生成新任务ID
                max_id = max([task["id"] for task in plan_data["tasks"]]) if plan_data["tasks"] else 0
                new_task = {
                    "id": max_id + 1,
                    "name": task_name,
                    "total": task_total,
                    "done": 0,
                    "unit": task_unit,
                    "icon": task_icon,
                    "module": task_module,
                    "self_rating": 0
                }
                plan_data["tasks"].append(new_task)
                save_data(plan_data)
                st.sidebar.success(f"任务 '{task_name}' 已添加！")
                st.rerun()
    
    elif task_action == "编辑现有任务":
        if plan_data["tasks"]:
            task_options = {f"{task['id']}. {task['name']}": task for task in plan_data["tasks"]}
            selected_task_key = st.sidebar.selectbox("选择要编辑的任务", list(task_options.keys()))
            
            if selected_task_key:
                selected_task = task_options[selected_task_key]
                with st.sidebar.form("edit_task_form"):
                    st.write("### 编辑任务")
                    new_name = st.text_input("任务名称", value=selected_task["name"])
                    new_total = st.number_input("总量", min_value=1, value=selected_task["total"])
                    new_unit = st.text_input("单位", value=selected_task["unit"])
                    new_icon = st.selectbox("图标", ["📚", "✏️", "📖", "🔬", "🔢", "🌍", "🎵", "⚽", "🎨", "💻"], 
                                          index=["📚", "✏️", "📖", "🔬", "🔢", "🌍", "🎵", "⚽", "🎨", "💻"].index(selected_task["icon"]) if selected_task["icon"] in ["📚", "✏️", "📖", "🔬", "🔢", "🌍", "🎵", "⚽", "🎨", "💻"] else 0)
                    new_module = st.selectbox("所属模块", ["理化攻坚", "数英综合", "文科/复盘", "自定义"], 
                                            index=["理化攻坚", "数英综合", "文科/复盘", "自定义"].index(selected_task["module"]) if selected_task["module"] in ["理化攻坚", "数英综合", "文科/复盘", "自定义"] else 0)
                    
                    if st.form_submit_button("保存修改"):
                        # 添加历史记录
                        plan_data = add_history_record(plan_data, f"编辑任务: {selected_task['name']}")
                        
                        # 更新任务
                        for task in plan_data["tasks"]:
                            if task["id"] == selected_task["id"]:
                                task["name"] = new_name
                                task["total"] = new_total
                                task["unit"] = new_unit
                                task["icon"] = new_icon
                                task["module"] = new_module
                                break
                        
                        save_data(plan_data)
                        st.sidebar.success(f"任务 '{new_name}' 已更新！")
                        st.rerun()
        else:
            st.sidebar.warning("暂无任务可编辑")
    
    elif task_action == "删除任务":
        if plan_data["tasks"]:
            task_options = {f"{task['id']}. {task['name']}": task for task in plan_data["tasks"]}
            selected_task_key = st.sidebar.selectbox("选择要删除的任务", list(task_options.keys()))
            
            if selected_task_key:
                selected_task = task_options[selected_task_key]
                confirm = st.sidebar.checkbox(f"确认删除任务 '{selected_task['name']}'？")
                
                if confirm and st.sidebar.button("确认删除", type="primary"):
                    # 添加历史记录
                    plan_data = add_history_record(plan_data, f"删除任务: {selected_task['name']}")
                    
                    # 删除任务
                    plan_data["tasks"] = [task for task in plan_data["tasks"] if task["id"] != selected_task["id"]]
                    save_data(plan_data)
                    st.sidebar.success(f"任务 '{selected_task['name']}' 已删除！")
                    st.rerun()
        else:
            st.sidebar.warning("暂无任务可删除")
    
    return plan_data

# ==========================================
# 3. 主界面内容
# ==========================================
def render_time_schedule():
    """渲染时间表"""
    st.title("⏰ 初三寒假作战指挥部 Pro")
    st.markdown("### 📋 详细时间表")
    
    # 显示时间表
    cols = st.columns(3)
    for i, slot in enumerate(TIME_SCHEDULE):
        with cols[i % 3]:
            with st.container():
                st.markdown(f"""
                <div style="background-color: {slot['color']}; padding: 15px; border-radius: 10px; margin-bottom: 10px;">
                    <h4 style="margin: 0; color: {'white' if slot['color'] in ['#34495E', '#9B59B6'] else 'black'}">{slot['time']}</h4>
                    <h5 style="margin: 5px 0; color: {'white' if slot['color'] in ['#34495E', '#9B59B6'] else 'black'}">{slot['module']} {slot['status']}</h5>
                    <p style="margin: 0; color: {'white' if slot['color'] in ['#34495E', '#9B59B6'] else 'black'}">{slot['activity']}</p>
                </div>
                """, unsafe_allow_html=True)

def render_task_management_table(plan_data, days_left):
    """渲染任务管理表格"""
    st.markdown("---")
    st.markdown("### 📊 学习数据统计与任务管理")
    
    if plan_data["tasks"]:
        # 准备表格数据
        table_data = []
        for task in plan_data["tasks"]:
            progress_percent = calculate_progress_percentage(task["done"], task["total"])
            daily_target = calculate_daily_target(task["total"], task["done"], days_left)
            
            table_data.append({
                "ID": task["id"],
                "任务": f"{task['icon']} {task['name']}",
                "模块": task["module"],
                "总量": task["total"],
                "已完成": task["done"],
                "单位": task["unit"],
                "进度": f"{progress_percent}%",
                "每日目标": f"{daily_target} {task['unit']}/天",
                "自评分": task["self_rating"]
            })
        
        # 显示可编辑表格
        df = pd.DataFrame(table_data)
        edited_df = st.data_editor(
            df,
            column_config={
                "总量": st.column_config.NumberColumn("总量", min_value=1),
                "已完成": st.column_config.NumberColumn("已完成", min_value=0),
                "自评分": st.column_config.NumberColumn("自评分", min_value=0, max_value=5, step=1)
            },
            use_container_width=True,
            key="task_editor"
        )
        
        # 检查是否有修改
        if not edited_df.equals(df):
            # 添加历史记录
            plan_data = add_history_record(plan_data, "批量编辑任务")
            
            # 更新数据
            for idx, row in edited_df.iterrows():
                task_id = row["ID"]
                for task in plan_data["tasks"]:
                    if task["id"] == task_id:
                        # 更新总量
                        if row["总量"] != task["total"]:
                            task["total"] = int(row["总量"])
                        
                        # 更新已完成量
                        if row["已完成"] != task["done"]:
                            task["done"] = int(row["已完成"])
                        
                        # 更新自评分
                        if row["自评分"] != task["self_rating"]:
                            task["self_rating"] = int(row["自评分"])
                        break
            
            save_data(plan_data)
            st.success("任务数据已更新！")
            st.rerun()
        
        # 任务统计
        col1, col2, col3, col4 = st.columns(4)
        total_tasks = len(plan_data["tasks"])
        completed_tasks = sum(1 for task in plan_data["tasks"] if task["done"] >= task["total"])
        total_progress = sum(calculate_progress_percentage(task["done"], task["total"]) for task in plan_data["tasks"]) / total_tasks if total_tasks > 0 else 0
        
        with col1:
            st.metric("📋 总任务数", total_tasks)
        with col2:
            st.metric("✅ 已完成任务", completed_tasks)
        with col3:
            st.metric("📈 平均进度", f"{total_progress:.1f}%")
        with col4:
            daily_rate = get_daily_completion_rate(plan_data)
            st.metric("🎯 全天完成率", f"{daily_rate}%")
    else:
        st.info("暂无任务数据，请在侧边栏添加任务")
    
    return plan_data

def render_time_logging(plan_data):
    """渲染打卡功能"""
    st.markdown("---")
    st.markdown("### ⏱️ 学习打卡与时间统计")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("开始学习")
        start_module = st.selectbox("选择学习模块", ["理化攻坚", "数英综合", "文科/复盘", "自定义"])
        start_task = st.selectbox("选择具体任务", [task["name"] for task in plan_data["tasks"] if task["module"] == start_module] if plan_data["tasks"] else ["暂无任务"])
        
        if st.button("⏯️ 开始打卡", type="primary"):
            # 添加历史记录
            plan_data = add_history_record(plan_data, f"开始打卡: {start_module} - {start_task}")
            
            # 记录开始时间
            time_log = {
                "module": start_module,
                "task": start_task,
                "start_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "end_time": None,
                "duration": None
            }
            
            if "time_logs" not in plan_data:
                plan_data["time_logs"] = []
            plan_data["time_logs"].append(time_log)
            save_data(plan_data)
            st.success(f"已开始 {start_module} - {start_task} 的学习！")
    
    with col2:
        st.subheader("结束学习")
        # 查找未结束的打卡记录
        active_logs = [log for log in plan_data.get("time_logs", []) if log.get("end_time") is None]
        
        if active_logs:
            active_options = [f"{log['module']} - {log['task']} ({log['start_time']})" for log in active_logs]
            selected_log_key = st.selectbox("选择要结束的打卡", active_options)
            
            if selected_log_key and st.button("⏹️ 结束打卡", type="secondary"):
                idx = active_options.index(selected_log_key)
                log = active_logs[idx]
                
                # 添加历史记录
                plan_data = add_history_record(plan_data, f"结束打卡: {log['module']} - {log['task']}")
                
                # 计算持续时间
                end_time = datetime.now()
                start_time = datetime.strptime(log["start_time"], "%Y-%m-%d %H:%M:%S")
                duration_minutes = int((end_time - start_time).total_seconds() / 60)
                
                # 更新记录
                log["end_time"] = end_time.strftime("%Y-%m-%d %H:%M:%S")
                log["duration"] = duration_minutes
                
                save_data(plan_data)
                st.success(f"已结束 {log['module']} - {log['task']} 的学习！持续 {duration_minutes} 分钟")
                st.rerun()
        else:
            st.info("暂无进行中的打卡记录")
    
    # 显示时间统计
    st.markdown("---")
    st.subheader("📊 时间统计")
    
    if plan_data.get("time_logs"):
        completed_logs = [log for log in plan_data["time_logs"] if log.get("end_time") is not None]
        
        if completed_logs:
            # 按模块统计时间
            module_stats = {}
            for log in completed_logs:
                module = log["module"]
                duration = log.get("duration", 0)
                if module not in module_stats:
                    module_stats[module] = {"total_minutes": 0, "count": 0}
                module_stats[module]["total_minutes"] += duration
                module_stats[module]["count"] += 1
            
            # 显示统计
            cols = st.columns(len(module_stats))
            for i, (module, stats) in enumerate(module_stats.items()):
                with cols[i]:
                    st.metric(
                        label=f"{module}",
                        value=f"{stats['total_minutes']}分钟",
                        delta=f"{stats['count']}次"
                    )
            
            # 显示最近记录
            st.markdown("#### 📝 最近打卡记录")
            recent_logs = completed_logs[-5:]  # 显示最近5条
            for log in recent_logs:
                st.info(f"**{log['module']} - {log['task']}**: {log['start_time']} → {log['end_time']} ({log['duration']}分钟)")
        else:
            st.info("暂无已完成的打卡记录")
    else:
        st.info("暂无打卡记录")
    
    return plan_data