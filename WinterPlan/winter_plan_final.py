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

# 新的详细时间表
TIME_SCHEDULE = [
    {"time": "08:30 - 09:00", "module": "☀️ 启动", "activity": "起床、早餐", "status": "", "color": "#FFEAA7"},
    {"time": "09:00 - 11:45", "module": "🧪 理化攻坚", "activity": "物理压轴 + 化学二模<br>*(2小时45分，保持高强度)*", "status": "🔥", "color": "#FF6B6B"},
    {"time": "11:45 - 12:30", "module": "🍲 午餐", "activity": "午餐 + 简单活动", "status": "", "color": "#FFD93D"},
    {"time": "12:30 - 13:00", "module": "💤 快速充电", "activity": "午休 (30分钟，睡醒后脑子最清醒)", "status": "🔋", "color": "#6BCF7F"},
    {"time": "13:00 - 16:00", "module": "📐 数英综合", "activity": "数学几何 + 英语D篇专练<br>*(3小时整，加量不加价)*", "status": "🧠", "color": "#4D96FF"},
    {"time": "16:00 - 18:00", "module": "⚽ 激流勇进", "activity": "足球 / 户外运动<br>*(2小时，雷打不动)*", "status": "🏃", "color": "#FF9A76"},
    {"time": "18:00 - 19:00", "module": "🍽️ 晚餐", "activity": "晚餐 + 家庭交流", "status": "", "color": "#B5B5B5"},
    {"time": "19:00 - 20:30", "module": "📝 文科/复盘", "activity": "历史道法、语文默写、App打卡", "status": "🔄", "color": "#9B59B6"},
    {"time": "20:30 - 21:15", "module": "🎹 艺术留白", "activity": "钢琴 / 电影 / 阅读<br>*(45分钟，奖赏时间)*", "status": "🎵", "color": "#F368E0"},
    {"time": "21:15 - 21:45", "module": "🚿 洗漱睡觉", "activity": "洗漱、准备就寝 (时间压缩，更紧凑)", "status": "🌙", "color": "#34495E"}
]

# 学习任务定义（对应时间表中的学习模块）
STUDY_TASKS = {
    "理化攻坚": [
        {"name": "物理压轴大题", "total": 6, "done": 0, "unit": "题", "icon": "⚡"},
        {"name": "化学二模卷", "total": 1, "done": 0, "unit": "套", "icon": "🧪"}
    ],
    "数英综合": [
        {"name": "数学几何思考题", "total": 5, "done": 0, "unit": "题", "icon": "📐"},
        {"name": "英语D篇专练", "total": 2, "done": 0, "unit": "篇", "icon": "🔤"}
    ],
    "文科/复盘": [
        {"name": "历史道法笔记", "total": 1, "done": 0, "unit": "项", "icon": "📜"},
        {"name": "语文默写", "total": 1, "done": 0, "unit": "篇", "icon": "📖"},
        {"name": "App打卡", "total": 1, "done": 0, "unit": "次", "icon": "📱"}
    ]
}

# 默认计划数据
DEFAULT_PLAN = {
    "start_date": datetime.now().strftime("%Y-%m-%d"),
    "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "study_tasks": STUDY_TASKS,
    "custom_tasks": []
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
            
            # 数据迁移：确保有study_tasks字段
            if "study_tasks" not in data:
                # 如果是旧格式数据，迁移到新格式
                data = migrate_to_new_format(data)
            
            # 确保有custom_tasks字段
            if "custom_tasks" not in data:
                data["custom_tasks"] = []
            
            return data

def migrate_to_new_format(old_data: Dict) -> Dict:
    """将旧格式数据迁移到新格式"""
    new_data = DEFAULT_PLAN.copy()
    
    # 保留原有数据
    if "start_date" in old_data:
        new_data["start_date"] = old_data["start_date"]
    
    if "last_updated" in old_data:
        new_data["last_updated"] = old_data["last_updated"]
    
    # 如果有tasks字段（旧格式），迁移到study_tasks
    if "tasks" in old_data:
        # 将旧任务分配到相应的模块
        for task_name, task_info in old_data["tasks"].items():
            # 根据任务名称判断属于哪个模块
            module_name = "理化攻坚"  # 默认
            if "数学" in task_name or "英语" in task_name:
                module_name = "数英综合"
            elif "历史" in task_name or "语文" in task_name or "App" in task_name:
                module_name = "文科/复盘"
            elif "钢琴" in task_name or "足球" in task_name:
                # 这些可能是自定义任务
                custom_task = {
                    "name": task_name,
                    "total": task_info.get("total", 1),
                    "done": task_info.get("done", 0),
                    "unit": task_info.get("unit", "次"),
                    "icon": task_info.get("icon", "📚")
                }
                new_data["custom_tasks"].append(custom_task)
                continue
            
            # 添加到对应模块
            if module_name not in new_data["study_tasks"]:
                new_data["study_tasks"][module_name] = []
            
            new_task = {
                "name": task_name,
                "total": task_info.get("total", 1),
                "done": task_info.get("done", 0),
                "unit": task_info.get("unit", "个"),
                "icon": task_info.get("icon", "📚")
            }
            new_data["study_tasks"][module_name].append(new_task)
    
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
    
    # 统计学习任务（确保study_tasks存在）
    if "study_tasks" in data:
        for module_tasks in data["study_tasks"].values():
            for task in module_tasks:
                total_tasks += 1
                if task["done"] >= task["total"]:
                    completed_tasks += 1
    
    # 统计自定义任务
    for task in data.get("custom_tasks", []):
        total_tasks += 1
        if task["done"] >= task["total"]:
            completed_tasks += 1
    
    return round(completed_tasks / total_tasks * 100, 1) if total_tasks > 0 else 0

def reset_today_progress(data: Dict) -> Dict:
    """重置当天进度（将done设为0）"""
    # 重置学习任务（确保study_tasks存在）
    if "study_tasks" in data:
        for module_key in data["study_tasks"]:
            for task in data["study_tasks"][module_key]:
                task["done"] = 0
    
    # 重置自定义任务
    for task in data.get("custom_tasks", []):
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
    page_title="寒假作战指挥部", 
    page_icon="🚀", 
    layout="wide",
    initial_sidebar_state="expanded"
)

# --- 作者信息 ---
st.markdown("""
<div style="text-align: center; padding: 10px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; margin-bottom: 20px;">
    <h3 style="color: white; margin: 0;">Author: EnochW cowork with Deepseek-V3.2</h3>
</div>
""", unsafe_allow_html=True)

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
if st.sidebar.button("➕ 添加自定义任务"):
    st.session_state.show_add_task = True

if "show_add_task" in st.session_state and st.session_state.show_add_task:
    with st.sidebar.form("add_task_form"):
        st.write("### 添加自定义任务")
        task_name = st.text_input("任务名称", placeholder="例如：额外练习题")
        task_total = st.number_input("总量", min_value=1, value=5)
        task_unit = st.text_input("单位", placeholder="例如：题、页、套")
        task_icon = st.selectbox("图标", ["📚", "✏️", "📖", "🔬", "🔢", "🌍", "🎵", "⚽", "🎨", "💻"])
        
        if st.form_submit_button("添加任务"):
            new_task = {
                "name": task_name,
                "total": task_total,
                "done": 0,
                "unit": task_unit,
                "icon": task_icon
            }
            if "custom_tasks" not in plan_data:
                plan_data["custom_tasks"] = []
            plan_data["custom_tasks"].append(new_task)
            save_data(plan_data)
            st.session_state.show_add_task = False
            st.rerun()

# --- 主界面 ---
st.title("🚀 初三寒假作战指挥部")

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
    last_updated = plan_data.get("last_updated", "未知").split()[0]
    st.metric("🔄 最后更新", last_updated)

st.progress(daily_completion / 100)

st.markdown("---")

# --- 详细时间表 ---
st.subheader("📅 每日时间安排表")

# 创建时间表HTML
schedule_html = """
<style>
.schedule-table {
    width: 100%;
    border-collapse: collapse;
    margin: 20px 0;
    font-family: Arial, sans-serif;
}
.schedule-table th {
    background-color: #2c3e50;
    color: white;
    padding: 12px;
    text-align: left;
    font-weight: bold;
}
.schedule-table td {
    padding: 12px;
    border-bottom: 1px solid #ddd;
}
.schedule-table tr:hover {
    background-color: #f5f5f5;
}
.time-cell { font-weight: bold; color: #2c3e50; }
.module-cell { font-weight: bold; }
.status-cell { text-align: center; font-size: 1.2em; }
</style>

<table class="schedule-table">
<tr>
    <th>时间段</th>
    <th>模块名称</th>
    <th>关键活动内容</th>
    <th>状态</th>
</tr>
"""

for item in TIME_SCHEDULE:
    schedule_html += f"""
<tr style="background-color: {item['color']}20;">
    <td class="time-cell">{item['time']}</td>
    <td class="module-cell">{item['module']}</td>
    <td>{item['activity']}</td>
    <td class="status-cell">{item['status']}</td>
</tr>
"""

schedule_html += "</table>"

st.markdown(schedule_html, unsafe_allow_html=True)

st.markdown("---")

# --- 学习任务打卡区 ---
st.subheader("📝 学习任务打卡区")

# 显示所有学习任务
all_tasks = []
if "study_tasks" in plan_data:
    for module_name, tasks in plan_data["study_tasks"].items():
        all_tasks.extend(tasks)

# 添加自定义任务
if "custom_tasks" in plan_data:
    all_tasks.extend(plan_data["custom_tasks"])

# 按列显示任务
cols = st.columns(3)
for i, task in enumerate(all_tasks):
    with cols[i % 3]:
        with st.container():
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
                key=f"slider_{task['name']}",
                help="100%为达标，120%为超额完成"
            )
            
            # 打卡按钮
            if st.button(f"打卡 {task['icon']}", key=f"btn_{task['name']}", type="primary"):
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

# --- 数据统计 ---
st.subheader("📊 学习数据统计")

# 创建统计表格
stats_data = []
total_tasks_count = 0
total_done_count = 0

# 统计学习任务
if "study_tasks" in plan_data:
    for module_name, tasks in plan_data["study_tasks"].items():
        for task in tasks:
            total_tasks_count += task["total"]
            total_done_count += task["done"]
            progress = calculate_progress_percentage(task["done"], task["total"])
            
            stats_data.append({
                "模块": module_name,
                "任务名称": task["name"],
                "总量": task["total"],
                "已完成": task["done"],
                "进度%": progress,
                "图标": task["icon"]
            })

# 统计自定义任务
for task in plan_data.get("custom_tasks", []):
    total_tasks_count += task["total"]
    total_done_count += task["done"]
    progress = calculate_progress_percentage(task["done"], task["total"])
    
    stats_data.append({
        "模块": "自定义",
        "任务名称": task["name"],
        "总量": task["total"],
        "已完成": task["done"],
        "进度%": progress,
        "图标": task["icon"]
    })

df = pd.DataFrame(stats_data)

# 显示数据表格
if not df.empty:
    st.dataframe(df, use_container_width=True)
else:
    st.info("暂无任务数据")

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
if "study_tasks" in plan_data:
    for module_tasks in plan_data["study_tasks"].values():
        for task in module_tasks:
            daily_target = calculate_daily_target(task["total"], task["done"], days_left)
            if daily_target > 0:
                total_today += 1
                if task["done"] >= task["total"]:
                    completed_today += 1

for task in plan_data.get("custom_tasks", []):
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
st.caption("© 2024 初三寒假作战指挥部 | 版本 3.0 | Author: EnochW cowork with Deepseek-V3.2")