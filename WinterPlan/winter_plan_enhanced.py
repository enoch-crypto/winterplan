import streamlit as st
import pandas as pd
import json
import os
import shutil
from datetime import datetime, timedelta
from typing import Dict, List, Any

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
# 2. 核心数据配置
# ==========================================
DATA_FILE = "my_study_plan.json"
BACKUP_DIR = "backups"
TOTAL_DAYS = 25

# 时间段定义
TIME_SLOTS = {
    "morning": {"name": "上午 (8:00-12:00)", "icon": "🌅", "color": "#FFEAA7"},
    "afternoon": {"name": "下午 (14:00-18:00)", "icon": "☀️", "color": "#74B9FF"},
    "evening": {"name": "晚上 (19:00-22:00)", "icon": "🌙", "color": "#A29BFE"},
    "flexible": {"name": "灵活时间", "icon": "⏰", "color": "#55EFC4"}
}

# 默认计划数据 - 支持时间段和自定义名称
DEFAULT_PLAN = {
    "start_date": datetime.now().strftime("%Y-%m-%d"),
    "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "time_slots": {
        "morning": [
            {"name": "数学几何思考题", "total": 5, "done": 0, "unit": "题", "icon": "📐", "custom": True},
            {"name": "物理压轴大题", "total": 6, "done": 0, "unit": "题", "icon": "⚡", "custom": True}
        ],
        "afternoon": [
            {"name": "化学二模卷", "total": 1, "done": 0, "unit": "套", "icon": "🧪", "custom": True},
            {"name": "英语二模卷D篇", "total": 1, "done": 0, "unit": "套", "icon": "🔤", "custom": True}
        ],
        "evening": [
            {"name": "历史道法笔记", "total": 1, "done": 0, "unit": "项", "icon": "📜", "custom": True},
            {"name": "英语作文", "total": 1, "done": 0, "unit": "篇", "icon": "📝", "custom": True}
        ],
        "flexible": [
            {"name": "钢琴/阅读", "total": 1, "done": 0, "unit": "小时", "icon": "🎹", "custom": True},
            {"name": "足球/运动", "total": 1, "done": 0, "unit": "小时", "icon": "⚽", "custom": True}
        ]
    }
}

# ==========================================
# 3. 逻辑处理函数
# ==========================================
def load_data() -> Dict:
    """加载学习计划数据"""
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'w', encoding='utf-8') as f:
            json.dump(DEFAULT_PLAN, f, ensure_ascii=False, indent=4)
        return DEFAULT_PLAN.copy()
    else:
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # 确保数据结构兼容
            if "time_slots" not in data:
                data = migrate_old_format(data)
            return data

def migrate_old_format(old_data: Dict) -> Dict:
    """迁移旧格式数据到新格式"""
    new_data = DEFAULT_PLAN.copy()
    new_data["start_date"] = old_data.get("start_date", datetime.now().strftime("%Y-%m-%d"))
    
    # 将旧任务分配到时间段
    if "tasks" in old_data:
        tasks = list(old_data["tasks"].items())
        for i, (task_name, task_info) in enumerate(tasks):
            slot_key = list(TIME_SLOTS.keys())[i % len(TIME_SLOTS)]
            new_task = {
                "name": task_name,
                "total": task_info["total"],
                "done": task_info["done"],
                "unit": task_info["unit"],
                "icon": task_info["icon"],
                "custom": False
            }
            new_data["time_slots"][slot_key].append(new_task)
    
    return new_data

def save_data(data: Dict) -> None:
    """保存学习计划数据并创建备份"""
    # 更新最后修改时间
    data["last_updated"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 创建备份目录
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)
    
    # 每日备份
    backup_file = os.path.join(BACKUP_DIR, f"backup_{datetime.now().strftime('%Y%m%d')}.json")
    if not os.path.exists(backup_file):
        shutil.copy2(DATA_FILE, backup_file) if os.path.exists(DATA_FILE) else None
    
    # 保存数据
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def calculate_daily_target(total: float, done: float, remaining_days: int) -> float:
    """计算每日目标量"""
    if remaining_days <= 0 or total <= done:
        return 0
    remaining_load = total - done
    return round(remaining_load / remaining_days, 1)

def calculate_progress_percentage(done: float, total: float) -> float:
    """计算进度百分比"""
    if total == 0:
        return 0
    return round(done / total * 100, 1)

def get_daily_completion_rate(data: Dict) -> float:
    """计算全天任务完成率"""
    total_tasks = 0
    completed_tasks = 0
    
    for slot_tasks in data["time_slots"].values():
        for task in slot_tasks:
            total_tasks += 1
            if task["done"] >= task["total"]:
                completed_tasks += 1
    
    return round(completed_tasks / total_tasks * 100, 1) if total_tasks > 0 else 0

def reset_today_progress(data: Dict) -> Dict:
    """重置当天进度（将done设为0）"""
    for slot_key in data["time_slots"]:
        for task in data["time_slots"][slot_key]:
            task["done"] = 0
    return data

def reset_all_data() -> Dict:
    """重置所有数据（恢复默认）"""
    if os.path.exists(DATA_FILE):
        os.remove(DATA_FILE)
    return DEFAULT_PLAN.copy()

# ==========================================
# 4. 界面 UI 设计
# ==========================================
st.set_page_config(
    page_title="寒假逆袭作战指挥部", 
    page_icon="🚀", 
    layout="wide",
    initial_sidebar_state="expanded"
)

# --- 侧边栏 ---
st.sidebar.title("⚙️ 设 置")
plan_data = load_data()
start_date = datetime.strptime(plan_data["start_date"], "%Y-%m-%d")
today = datetime.now()
day_diff = (today - start_date).days + 1
days_left = TOTAL_DAYS - day_diff + 1

st.sidebar.info(f"📅 当前进度: 第 {day_diff} 天 / 共 {TOTAL_DAYS} 天")
st.sidebar.warning(f"⏳ 剩余天数: {days_left} 天")

# 数据管理选项
st.sidebar.subheader("📊 数据管理")

# 导出数据
export_data = json.dumps(plan_data, ensure_ascii=False, indent=4)
st.sidebar.download_button(
    label="📥 导出数据",
    data=export_data,
    file_name=f"study_plan_{today.strftime('%Y%m%d_%H%M%S')}.json",
    mime="application/json",
    help="下载当前学习计划数据备份"
)

# 查看备份
if os.path.exists(BACKUP_DIR):
    backup_files = [f for f in os.listdir(BACKUP_DIR) if f.endswith('.json')]
    if backup_files:
        st.sidebar.markdown(f"📁 备份文件: {len(backup_files)} 个")

# 重置选项
st.sidebar.subheader("🔄 重置选项")
reset_option = st.sidebar.radio(
    "选择重置类型:",
    ["当天进度重置", "全部数据重置"],
    help="当天重置只清零今日完成量，全部重置会恢复默认设置"
)

if st.sidebar.button("确认重置", type="secondary"):
    if reset_option == "当天进度重置":
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

# 任务管理
st.sidebar.subheader("📝 任务管理")
if st.sidebar.button("➕ 添加新任务"):
    st.session_state.show_add_task = True

if "show_add_task" in st.session_state and st.session_state.show_add_task:
    with st.sidebar.form("add_task_form"):
        st.write("### 添加新任务")
        task_name = st.text_input("任务名称", placeholder="例如：数学练习题")
        task_total = st.number_input("总量", min_value=1, value=10)
        task_unit = st.text_input("单位", placeholder="例如：题、页、套")
        task_icon = st.selectbox("图标", ["📚", "✏️", "📖", "🔬", "🔢", "🌍", "🎵", "⚽", "🎨", "💻"])
        task_slot = st.selectbox("时间段", list(TIME_SLOTS.keys()), 
                                format_func=lambda x: TIME_SLOTS[x]["name"])
        
        if st.form_submit_button("添加任务"):
            new_task = {
                "name": task_name,
                "total": task_total,
                "done": 0,
                "unit": task_unit,
                "icon": task_icon,
                "custom": True
            }
            plan_data["time_slots"][task_slot].append(new_task)
            save_data(plan_data)
            st.session_state.show_add_task = False
            st.rerun()

# --- 主界面 ---
st.title("🚀 初三寒假逆袭作战指挥部")
st.markdown("### *Target: Shanghai High School Entrance Exam (580+)*")

# 顶部统计信息
daily_completion = get_daily_completion_rate(plan_data)

col1, col2, col3, col4 = st.columns(4)
with col1:
    st.metric("📅 学习天数", f"{day_diff}/{TOTAL_DAYS}")
with col2:
    st.metric("⏳ 剩余天数", days_left)
with col3:
    st.metric("📊 全天完成率", f"{daily_completion}%")
with col4:
    last_updated = plan_data.get("last_updated", "未知")
    st.metric("🔄 最后更新", last_updated.split()[0])

st.progress(daily_completion / 100)

st.markdown("---")
st.subheader("📋 今日时间段任务列表")

# 按时间段显示任务
for slot_key, slot_info in TIME_SLOTS.items():
    slot_tasks = plan_data["time_slots"].get(slot_key, [])
    if not slot_tasks:
        continue
    
    with st.container():
        # 时间段标题
        st.markdown(f"""
        <div style="background-color:{slot_info['color']}20; padding:10px; border-radius:10px; margin-bottom:15px;">
            <h4 style="margin:0;">{slot_info['icon']} {slot_info['name']}</h4>
        </div>
        """, unsafe_allow_html=True)
        
        # 该时间段的任务
        cols = st.columns(3)
        for i, task in enumerate(slot_tasks):
            with cols[i % 3]:
                with st.container():
                    # 任务卡片
                    st.markdown(f"##### {task['icon']} {task['name']}")
                    
                    # 进度信息
                    progress_percent = calculate_progress_percentage(task["done"], task["total"])
                    daily_target = calculate_daily_target(task["total"], task["done"], days_left)
                    
                    st.progress(progress_percent / 100)
                    st.caption(f"进度: {progress_percent}% ({task['done']}/{task['total']} {task['unit']})")
                    
                    # 今日目标
                    if daily_target > 0:
                        st.info(f"🎯 今日目标: **{daily_target}** {task['unit']}")
                    else:
                        st.success("✅ 今日目标: 已完成！")
                    
                    # 完成度滑块
                    percent = st.slider(
                        f"完成度",
                        min_value=0,
                        max_value=120,
                        value=0,
                        step=10,
                        key=f"slider_{slot_key}_{task['name']}",
                        help="100%为达标，120%为超额完成"
                    )
                    
                    # 打卡按钮
                    if st.button(f"打卡 {task['icon']}", key=f"btn_{slot_key}_{task['name']}", type="primary"):
                        if percent > 0:
                            try:
                                # 计算实际完成量
                                actual_done = daily_target * (percent / 100.0)
                                if actual_done <= 0:
                                    st.warning("完成量必须大于0")
                                    st.stop()
                                
                                # 更新数据
                                task["done"] += actual_done
                                task["done"] = round(task["done"], 2)
                                
                                # 确保不超过总量
                                if task["done"] > task["total"]:
                                    task["done"] = task["total"]
                                
                                save_data(plan_data)
                                
                                if percent >= 100:
                                    st.balloons()
                                    st.success(f"🎉 太棒了！完成度 {percent}%")
                                else:
                                    st.warning(f"💪 加油，完成度 {percent}%")
                                
                                st.info(f"✅ 本次完成: {actual_done:.1f} {task['unit']}")
                                
                                # 刷新页面
                                import time
                                time.sleep(1.5)
                                st.rerun()
                                
                            except Exception as e:
                                st.error(f"提交失败: {str(e)}")
                        else:
                            st.warning("请先设置完成度百分比")

st.markdown("---")

# --- 数据统计与可视化 ---
st.subheader("📈 学习数据统计")

# 创建统计表格
stats_data = []
total_tasks_count = 0
total_done_count = 0

for slot_key, slot_info in TIME_SLOTS.items():
    slot_tasks = plan_data["time_slots"].get(slot_key, [])
    for task in slot_tasks:
        total_tasks_count += task["total"]
        total_done_count += task["done"]
        progress = calculate_progress_percentage(task["done"], task["total"])
        
        stats_data.append({
            "时间段": slot_info["name"],
            "任务名称": task["name"],
            "总量": task["total"],
            "已完成": task["done"],
            "进度%": progress,
            "图标": task["icon"]
        })

df = pd.DataFrame(stats_data)

# 显示数据表格
st.dataframe(df, use_container_width=True)

# 总体统计
overall_progress = total_done_count / total_tasks_count if total_tasks_count > 0 else 0

col1, col2 = st.columns(2)
with col1:
    st.metric("📚 总任务量", f"{total_tasks_count} 单位")
    st.metric("✅ 总完成量", f"{total_done_count} 单位")
with col2:
    st.metric("📊 总体进度", f"{overall_progress:.1%}")
    st.metric("🌟 全天完成率", f"{daily_completion}%")

st.markdown("---")

# --- 今日总结 ---
st.subheader("📝 今日学习总结")

completed_today = 0
total_today = 0
for slot_tasks in plan_data["time_slots"].values():
    for task in slot_tasks:
        daily_target = calculate_daily_target(task["total"], task["done"], days_left)
        if daily_target > 0:
            total_today += 1
            if task["done"] >= task["total"]:
                completed_today += 1

today_ratio = round(completed_today / total_today * 100, 1) if total_today > 0 else 0

st.success(f"""
**📊 今日学习报告 ({today.strftime('%Y年%m月%d日')}):**
- **全天任务完成率**: {daily_completion}% ({completed_today}/{total_today} 项任务)
- **今日建议**: {"继续保持高效学习节奏！" if daily_completion > 70 else "需要加快进度，合理分配时间！"}
- **数据安全**: 数据已自动备份，最后更新于 {plan_data.get('last_updated', '未知')}
- **明日计划**: 根据今日完成情况，系统已自动调整明日任务分配
""")

# --- 页脚 ---
st.markdown("---")
st.caption("© 2024 初三寒假逆袭作战指挥部 | 版本 2.0 | 设计理念：科学规划 + 动态调整 + 可视化追踪 + 时间段管理")
