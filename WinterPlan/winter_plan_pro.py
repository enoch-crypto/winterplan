import streamlit as st
import pandas as pd
import json
import os
import shutil
from datetime import datetime, timedelta
from typing import Dict, List, Any, Tuple
import altair as alt

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
DATA_FILE = "my_study_plan_pro.json"
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

# 默认计划数据 - 增强版
DEFAULT_PLAN = {
    "start_date": datetime.now().strftime("%Y-%m-%d"),
    "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "tasks": [
        {"id": 1, "name": "物理压轴大题", "total": 6, "done": 0, "unit": "题", "icon": "⚡", "module": "理化攻坚", "self_rating": 0},
        {"id": 2, "name": "化学二模卷", "total": 1, "done": 0, "unit": "套", "icon": "🧪", "module": "理化攻坚", "self_rating": 0},
        {"id": 3, "name": "数学几何思考题", "total": 5, "done": 0, "unit": "题", "icon": "📐", "module": "数英综合", "self_rating": 0},
        {"id": 4, "name": "英语D篇专练", "total": 2, "done": 0, "unit": "篇", "icon": "🔤", "module": "数英综合", "self_rating": 0},
        {"id": 5, "name": "历史道法笔记", "total": 1, "done": 0, "unit": "项", "icon": "📜", "module": "文科/复盘", "self_rating": 0},
        {"id": 6, "name": "语文默写", "total": 1, "done": 0, "unit": "篇", "icon": "📖", "module": "文科/复盘", "self_rating": 0},
        {"id": 7, "name": "App打卡", "total": 1, "done": 0, "unit": "次", "icon": "📱", "module": "文科/复盘", "self_rating": 0},
    ],
    "history": [],  # 用于撤销/恢复
    "time_logs": [],  # 打卡时间记录
    "daily_scores": []  # 每日评分记录
}

# ==========================================
# 3. 逻辑处理函数 - 增强版
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
            if "tasks" not in data:
                data = migrate_to_pro_format(data)
            return data

def migrate_to_pro_format(old_data: Dict) -> Dict:
    """将旧格式数据迁移到专业版格式"""
    new_data = DEFAULT_PLAN.copy()
    
    # 保留原有数据
    if "start_date" in old_data:
        new_data["start_date"] = old_data["start_date"]
    
    if "last_updated" in old_data:
        new_data["last_updated"] = old_data["last_updated"]
    
    # 迁移任务数据
    new_data["tasks"] = []
    task_id = 1
    
    # 迁移study_tasks
    if "study_tasks" in old_data:
        for module_name, tasks in old_data["study_tasks"].items():
            for task in tasks:
                new_task = {
                    "id": task_id,
                    "name": task.get("name", f"任务{task_id}"),
                    "total": task.get("total", 1),
                    "done": task.get("done", 0),
                    "unit": task.get("unit", "个"),
                    "icon": task.get("icon", "📚"),
                    "module": module_name,
                    "self_rating": 0
                }
                new_data["tasks"].append(new_task)
                task_id += 1
    
    # 迁移custom_tasks
    if "custom_tasks" in old_data:
        for task in old_data["custom_tasks"]:
            new_task = {
                "id": task_id,
                "name": task.get("name", f"自定义任务{task_id}"),
                "total": task.get("total", 1),
                "done": task.get("done", 0),
                "unit": task.get("unit", "个"),
                "icon": task.get("icon", "📚"),
                "module": "自定义",
                "self_rating": 0
            }
            new_data["tasks"].append(new_task)
            task_id += 1
    
    return new_data

def save_data(data: Dict, save_history: bool = True) -> None:
    """保存学习计划数据并创建备份"""
    # 更新最后修改时间
    data["last_updated"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 保存历史记录（用于撤销）
    if save_history and "history" in data:
        # 只保留最近20次历史记录
        if len(data["history"]) > 20:
            data["history"] = data["history"][-20:]
    
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
    
    for task in data.get("tasks", []):
        total_tasks += 1
        if task["done"] >= task["total"]:
            completed_tasks += 1
    
    return round(completed_tasks / total_tasks * 100, 1) if total_tasks > 0 else 0

def get_daily_self_rating(data: Dict) -> float:
    """计算每日自评平均分"""
    total_rating = 0
    rated_tasks = 0
    
    for task in data.get("tasks", []):
        if task.get("self_rating", 0) > 0:
            total_rating += task["self_rating"]
            rated_tasks += 1
    
    return round(total_rating / rated_tasks, 1) if rated_tasks > 0 else 0

def reset_today_progress(data: Dict) -> Dict:
    """重置当天进度（将done设为0）"""
    for task in data.get("tasks", []):
        task["done"] = 0
        task["self_rating"] = 0
    
    return data

def reset_all_data() -> Dict:
    """重置所有数据（恢复默认）"""
    if os.path.exists(DATA_FILE):
        os.remove(DATA_FILE)
    return DEFAULT_PLAN.copy()

def add_history_record(data: Dict, action: str) -> Dict:
    """添加历史记录"""
    if "history" not in data:
        data["history"] = []
    
    # 保存当前状态快照
    snapshot = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "action": action,
        "tasks": json.loads(json.dumps(data.get("tasks", []))),  # 深拷贝
        "time_logs": json.loads(json.dumps(data.get("time_logs", []))),
        "daily_scores": json.loads(json.dumps(data.get("daily_scores", [])))
    }
    
    data["history"].append(snapshot)
    
    # 只保留最近20次记录
    if len(data["history"]) > 20:
        data["history"] = data["history"][-20:]
    
    return data

def undo_last_action(data: Dict) -> Tuple[Dict, bool]:
    """撤销上一次操作"""
    if "history" not in data or len(data["history"]) < 2:
        return data, False
    
    # 移除当前状态，恢复到上一次状态
    data["history"].pop()  # 移除当前状态
    if data["history"]:
        last_state = data["history"][-1]
        data["tasks"] = last_state["tasks"]
        data["time_logs"] = last_state.get("time_logs", [])
        data["daily_scores"] = last_state.get("daily_scores", [])
        return data, True
    
    return data, False

def redo_action(data: Dict) -> Tuple[Dict, bool]:
    """重做操作（简化版，实际需要更复杂的实现）"""
    # 简化实现：提示用户刷新页面
    return data, False

# ==========================================
# 4. 界面 UI 设计 - 增强版
# ==========================================
st.set_page_config(
    page_title="初三寒假作战指挥部 Pro", 
    page_icon="🚀", 
    layout="wide",
    initial_sidebar_state="expanded"
)

# --- 作者信息 ---
st.markdown("""
<div style="text-align: center; padding: 10px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; margin-bottom: 20px;">
    <h3 style="color: white; margin: 0;">Author: EnochW cowork with Deepseek-V3.2 | 专业版</h3>
</div>
""", unsafe_allow_html=True)

# --- 侧边栏 ---
st.sidebar.title("⚙️ 专业版设置")
plan_data = load_data()
start_date = datetime.strptime(plan_data["start_date"], "%Y-%m-%d")
today = datetime.now()
day_diff = (today - start_date).days + 1
days_left = TOTAL_DAYS - day_diff + 1

st.sidebar.info(f"📅 当前进度: 第 {day_diff} 天 / 共 {TOTAL_DAYS} 天")
st.sidebar.warning(f"⏳ 剩余天数: {days_left} 天")

# 撤销/恢复功能
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

# 数据管理选项
st.sidebar.subheader("📊 数据管理")

# 导出数据
export_data = json.dumps(plan_data, ensure_ascii=False, indent=4)
st.sidebar.download_button(
    label="📥 导出数据",
    data=export_data,
    file_name=f"study_plan_pro_{today.strftime('%Y%m%d_%H%M%S')}.json",
    mime="application/json",
    help="下载当前学习计划数据备份"
)

# 重置选项
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

# 任务管理
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
