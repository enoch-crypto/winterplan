import streamlit as st
import pandas as pd
import json
import os
from datetime import datetime, timedelta

# ==========================================
# 1. 环境自检与初始化 (System Check)
# ==========================================
def run_system_check():
    """检查必要的库是否安装，确保一次跑通"""
    try:
        import streamlit
        import pandas
        import altair
        # print("✅ 环境检测通过！")
    except ImportError as e:
        st.error(f"❌ 环境缺失: {e}")
        st.info("请运行: pip install -r requirements.txt")
        st.stop()

run_system_check()

# 显示欢迎信息
st.sidebar.success("✅ 环境检测通过！")

# ==========================================
# 2. 核心数据配置 (Data Configuration)
# ==========================================
DATA_FILE = "my_study_plan.json"
TOTAL_DAYS = 25

# 初始计划数据 (根据你的作业单)
DEFAULT_PLAN = {
    "start_date": datetime.now().strftime("%Y-%m-%d"),
    "tasks": {
        "物理 (压轴/大题)": {"total": 30, "done": 0, "unit": "题", "icon": "⚡"},
        "物理 (空中课堂)": {"total": 19, "done": 0, "unit": "个", "icon": "📺"},
        "化学 (二模卷)": {"total": 15, "done": 0, "unit": "套", "icon": "🧪"},
        "化学 (指导册/梳理)": {"total": 50, "done": 0, "unit": "页", "icon": "📘"},
        "数学 (几何/思考题)": {"total": 20, "done": 0, "unit": "题", "icon": "📐"},
        "数学 (指导册基础)": {"total": 22, "done": 0, "unit": "页", "icon": "✏️"},
        "英语 (二模卷/D篇)": {"total": 15, "done": 0, "unit": "套", "icon": "🔤"},
        "英语 (作文)": {"total": 5, "done": 0, "unit": "篇", "icon": "📝"},
        "历史/道法 (笔记作业)": {"total": 7, "done": 0, "unit": "项", "icon": "📜"},
        "钢琴/阅读 (艺术留白)": {"total": 25, "done": 0, "unit": "次", "icon": "🎹"},
        "足球/运动": {"total": 18, "done": 0, "unit": "次", "icon": "⚽"} 
    }
}

# ==========================================
# 3. 逻辑处理函数 (Business Logic)
# ==========================================
def load_data():
    """加载学习计划数据"""
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'w', encoding='utf-8') as f:
            json.dump(DEFAULT_PLAN, f, ensure_ascii=False, indent=4)
        return DEFAULT_PLAN
    else:
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)

def save_data(data):
    """保存学习计划数据"""
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

def calculate_daily_target(total, done, remaining_days):
    """计算每日目标量"""
    if remaining_days <= 0: 
        return 0
    remaining_load = total - done
    if remaining_load <= 0: 
        return 0
    # 计算每日平均任务量，向上取整保留一位小数
    daily_target = remaining_load / remaining_days
    return round(daily_target, 1)

def calculate_progress_percentage(done, total):
    """计算进度百分比"""
    if total == 0:
        return 0
    return round(done / total * 100, 1)

# ==========================================
# 4. 界面 UI 设计 (Streamlit UI)
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
    file_name=f"study_plan_backup_{today.strftime('%Y%m%d')}.json",
    mime="application/json",
    help="下载当前学习计划数据备份"
)

# 重置数据
st.sidebar.markdown("---")
reset_confirm = st.sidebar.checkbox("⚠️ 我确认要重置所有数据", key="reset_confirm")
if st.sidebar.button("🔄 重置所有数据", type="secondary", disabled=not reset_confirm):
    if os.path.exists(DATA_FILE):
        os.remove(DATA_FILE)
    st.sidebar.success("数据已重置！页面将自动刷新...")
    import time
    time.sleep(2)
    st.rerun()

# --- 主界面 ---
st.title("🚀 初三寒假逆袭作战指挥部")
st.markdown("### *Target: Shanghai High School Entrance Exam (580+)*")

# 顶部进度条
total_tasks_count = sum([t["total"] for t in plan_data["tasks"].values()])
total_done_count = sum([t["done"] for t in plan_data["tasks"].values()])
overall_progress = total_done_count / total_tasks_count if total_tasks_count > 0 else 0

col1, col2, col3 = st.columns(3)
with col1:
    st.metric("总任务量", f"{total_tasks_count} 项")
with col2:
    st.metric("已完成", f"{total_done_count} 项")
with col3:
    st.metric("总体进度", f"{overall_progress:.1%}")

st.progress(overall_progress)

st.markdown("---")
st.subheader("📝 今日任务看板 (Today's Mission)")

# 使用 columns 布局显示任务卡片
cols = st.columns(3)
task_keys = list(plan_data["tasks"].keys())

for i, task_name in enumerate(task_keys):
    task_info = plan_data["tasks"][task_name]
    
    # 动态计算今日目标
    daily_target = calculate_daily_target(task_info["total"], task_info["done"], days_left)
    progress_percent = calculate_progress_percentage(task_info["done"], task_info["total"])
    
    with cols[i % 3]:
        with st.container():
            st.markdown(f"#### {task_info['icon']} {task_name}")
            
            # 进度条
            st.progress(progress_percent / 100)
            st.caption(f"进度: {progress_percent}% ({task_info['done']}/{task_info['total']} {task_info['unit']})")
            
            # 如果该任务已经全部完成，显示完成状态
            if task_info["done"] >= task_info["total"]:
                st.success("✅ 已完成！")
                continue
            
            # 核心逻辑：今日目标展示
            if daily_target > 0:
                st.info(f"🎯 今日目标: **{daily_target}** {task_info['unit']}")
            else:
                st.info("🎯 今日目标: 已完成所有任务！")
            
            # 核心交互：0% - 120% 滑块
            percent = st.slider(
                f"完成度", 
                min_value=0, 
                max_value=120, 
                value=0, 
                step=10,
                key=f"slider_{task_name}",
                help="100%为达标，120%为超额完成（自动减少后续负担）"
            )
            
            if st.button(f"打卡提交 {task_info['icon']}", key=f"btn_{task_name}", type="primary"):
                if percent > 0:
                    try:
                        # 计算实际完成量
                        actual_done = daily_target * (percent / 100.0)
                        if actual_done <= 0:
                            st.warning("完成量必须大于0，请调整完成度百分比")
                            st.stop()
                        
                        # 检查是否超过总量
                        new_done = plan_data["tasks"][task_name]["done"] + actual_done
                        if new_done > task_info["total"]:
                            st.warning(f"完成量超过总量！已自动调整为剩余量。")
                            actual_done = task_info["total"] - plan_data["tasks"][task_name]["done"]
                        
                        # 更新数据
                        plan_data["tasks"][task_name]["done"] += actual_done
                        # 保持小数点后2位
                        plan_data["tasks"][task_name]["done"] = round(plan_data["tasks"][task_name]["done"], 2)
                        
                        # 确保不超过总量
                        if plan_data["tasks"][task_name]["done"] > task_info["total"]:
                            plan_data["tasks"][task_name]["done"] = task_info["total"]
                        
                        save_data(plan_data)
                        
                        if percent >= 100:
                            st.balloons()
                            st.success(f"🎉 太棒了！完成度 {percent}%，离580分又近了一步！")
                        else:
                            st.warning(f"💪 加油，完成度 {percent}%，剩余任务会自动顺延。")
                        
                        # 显示具体完成量
                        st.info(f"✅ 本次完成: {actual_done:.1f} {task_info['unit']}")
                        
                        # 刷新页面以更新计算
                        import time
                        time.sleep(2)
                        st.rerun()
                        
                    except Exception as e:
                        st.error(f"提交失败: {str(e)}")
                else:
                    st.warning("请先设置完成度百分比（大于0%）")

st.markdown("---")

# --- 进度可视化 ---
st.subheader("📈 学习进度可视化")

# 创建进度数据
progress_data = []
for task_name, task_info in plan_data["tasks"].items():
    progress_data.append({
        "科目": task_name,
        "总量": task_info["total"],
        "已完成": task_info["done"],
        "进度%": calculate_progress_percentage(task_info["done"], task_info["total"]),
        "图标": task_info["icon"]
    })

df = pd.DataFrame(progress_data)

# 显示数据表格
st.dataframe(df, use_container_width=True)

# --- 底部成就墙 (截图区) ---
st.subheader("🏆 今日成就墙 (Screenshot Here)")
st.markdown("把这里截图发给老师/班级群 👇")

with st.container():
    c1, c2, c3 = st.columns(3)
    
    # 计算今日简单统计
    completed_tasks = sum(1 for task in plan_data["tasks"].values() if task["done"] >= task["total"])
    total_tasks = len(plan_data["tasks"])
    
    c1.metric("距离中考目标", "560-580分", "冲刺中")
    c2.metric("已完成科目", f"{completed_tasks}/{total_tasks}", f"+{completed_tasks}")
    c3.metric("状态评估", "高效运行", "⭐⭐⭐⭐⭐")

    st.success(f"""
    **今日复盘 ({today.strftime('%Y年%m月%d日')}):**
    - 坚持了 "5-8小时" 黄金学习法
    - 足球/运动时间：已预留 ✅
    - 艺术留白：已预留 ✅
    - 动态算法：已根据今日 {today.strftime('%H:%M')} 状态自动调整后续计划。
    - 今日建议：{"继续保持高效学习节奏！" if overall_progress > 0.5 else "需要加快进度，合理分配时间！"}
    """)

# --- 页脚 ---
st.markdown("---")
st.caption("© 2024 初三寒假逆袭作战指挥部 | 版本 1.0 | 设计理念：科学规划 + 动态调整 + 可视化追踪")