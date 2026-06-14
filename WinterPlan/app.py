import streamlit as st
import json
import os
import time
import pandas as pd
from datetime import datetime, timedelta

# ==========================================
# 1. 配置与常量 (Config)
# ==========================================
DATA_FILE = "enoch_study_data.json"
MAX_HISTORY = 20  # 最大撤销步数
AUTHOR_TAG = "Author: Enoch W 2026"

# 默认初始化数据
DEFAULT_STATE = {
    "start_date": datetime.now().strftime("%Y-%m-%d"),
    "daily_logs": {},  # 记录每天的综合评分 {"2026-01-30": {"score": 85, "hours": 4.5}}
    "tasks": {
        "物理 (压轴)": {"total": 30, "done": 0, "unit": "题", "icon": "⚡", "target_min": 45},
        "化学 (二模)": {"total": 15, "done": 0, "unit": "套", "icon": "🧪", "target_min": 60},
        "数学 (几何)": {"total": 20, "done": 0, "unit": "题", "icon": "📐", "target_min": 60},
        "英语 (D篇)": {"total": 15, "done": 0, "unit": "套", "icon": "🔤", "target_min": 40},
        "钢琴 (艺术)": {"total": 25, "done": 0, "unit": "次", "icon": "🎹", "target_min": 45},
        "足球 (运动)": {"total": 18, "done": 0, "unit": "次", "icon": "⚽", "target_min": 120}
    }
}

# ==========================================
# 2. 状态管理与 undo/redo (State & History)
# ==========================================

# 初始化 Session State
if 'data' not in st.session_state:
    # 尝试从文件加载
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            st.session_state.data = json.load(f)
    else:
        st.session_state.data = DEFAULT_STATE

if 'history' not in st.session_state:
    st.session_state.history = []
if 'history_pointer' not in st.session_state:
    st.session_state.history_pointer = -1
if 'active_timers' not in st.session_state:
    st.session_state.active_timers = {} # 记录正在计时的任务 {"TaskName": start_timestamp}

def save_state_to_history():
    """在修改数据前调用，保存当前快照"""
    import copy
    # 如果指针不在最后，说明有过撤销，切断后面的历史
    if st.session_state.history_pointer < len(st.session_state.history) - 1:
        st.session_state.history = st.session_state.history[:st.session_state.history_pointer+1]
    
    # 深拷贝当前数据
    snapshot = copy.deepcopy(st.session_state.data)
    st.session_state.history.append(snapshot)
    
    # 限制历史长度
    if len(st.session_state.history) > MAX_HISTORY:
        st.session_state.history.pop(0)
    else:
        st.session_state.history_pointer += 1

def persist_to_disk():
    """写入硬盘"""
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(st.session_state.data, f, ensure_ascii=False, indent=4)

def undo():
    if st.session_state.history_pointer >= 0:
        # 当前状态也是历史的一部分，如果需要恢复可以redo
        # 这里简化逻辑：直接取上一个快照
        prev_data = st.session_state.history[st.session_state.history_pointer]
        st.session_state.data = prev_data
        st.session_state.history_pointer -= 1
        persist_to_disk()
        st.rerun()

def redo():
    # 简易版Undo通常不需要Redo，为了简化代码，我们主要实现Undo
    # 如果要实现Redo，需要更复杂的指针管理，这里暂只提供“恢复到上一步”
    pass

# ==========================================
# 3. 核心计算逻辑 (Core Logic)
# ==========================================

def calculate_daily_score(today_tasks_data):
    """
    计算今日综合评分 (0-100)
    today_tasks_data 结构: { "TaskName": {"percent": 120, "stars": 5, "duration": 45} }
    """
    if not today_tasks_data:
        return 0, 0
    
    total_score = 0
    total_duration = 0
    count = 0
    
    for t_name, t_data in today_tasks_data.items():
        # 维度1: 完成度 (归一化: 100% = 100分, 150% = 120分封顶)
        p_score = min(t_data.get('percent', 0), 120) 
        
        # 维度2: 质量 (1-5星 -> 20-100分)
        q_score = t_data.get('stars', 0) * 20
        
        # 综合分 = 进度(50%) + 质量(50%)
        # 时长作为加分项体现在总览里，不直接影响单项分
        item_score = (p_score * 0.5) + (q_score * 0.5)
        
        total_score += item_score
        total_duration += t_data.get('duration', 0)
        count += 1
        
    avg_score = round(total_score / count, 1) if count > 0 else 0
    return avg_score, total_duration

def get_today_str():
    return datetime.now().strftime("%Y-%m-%d")

# 确保今日的数据结构存在
today_str = get_today_str()
if "daily_records" not in st.session_state.data:
    st.session_state.data["daily_records"] = {}
if today_str not in st.session_state.data["daily_records"]:
    st.session_state.data["daily_records"][today_str] = {} # 存放今日各任务详情

# ==========================================
# 4. 界面 UI (Streamlit)
# ==========================================

st.set_page_config(page_title="寒假作战指挥部", page_icon="⚔️", layout="wide")

# --- 侧边栏: 控制中心 ---
with st.sidebar:
    st.markdown(f"### ⚙️ 控制台")
    st.caption(AUTHOR_TAG)
    
    # 撤销按钮
    col_u1, col_u2 = st.columns(2)
    with col_u1:
        if st.button("↩️ 撤销操作"):
            undo()
            st.toast("已回退到上一步", icon="🔙")
    
    st.markdown("---")
    
    # 任务管理 CRUD
    with st.expander("🛠️ 任务管理 (自定义)", expanded=False):
        new_task_name = st.text_input("新任务名称", placeholder="例如: 物理错题")
        new_task_icon = st.text_input("图标 (Emoji)", value="📝")
        new_task_total = st.number_input("总目标量", value=10, step=1)
        new_task_unit = st.text_input("单位", value="页")
        
        if st.button("➕ 添加/更新任务"):
            if new_task_name:
                save_state_to_history()
                st.session_state.data["tasks"][new_task_name] = {
                    "total": new_task_total, 
                    "done": 0, 
                    "unit": new_task_unit,
                    "icon": new_task_icon,
                    "target_min": 45
                }
                persist_to_disk()
                st.rerun()
        
        st.markdown("---")
        task_to_del = st.selectbox("选择要删除的任务", options=list(st.session_state.data["tasks"].keys()))
        if st.button("🗑️ 删除选中任务"):
            save_state_to_history()
            del st.session_state.data["tasks"][task_to_del]
            persist_to_disk()
            st.rerun()

    # 全局进度
    st.markdown("---")
    st.markdown("**📊 整体进度快照**")
    all_tasks = st.session_state.data["tasks"]
    total_items = sum([t["total"] for t in all_tasks.values()])
    done_items = sum([t["done"] for t in all_tasks.values()])
    global_progress = done_items / total_items if total_items > 0 else 0
    st.progress(global_progress)
    st.caption(f"总进度: {global_progress:.1%}")

# --- 主界面 ---
st.title("⚔️ 寒假作战指挥部")
st.markdown("**目标：尽最大努力提高知识掌握和中考提分**")
st.caption(f"📅 今日: {today_str} | {AUTHOR_TAG}")

# 计算今日数据
today_record = st.session_state.data["daily_records"][today_str]
today_score, today_minutes = calculate_daily_score(today_record)
today_hours = round(today_minutes / 60, 2)

# 顶部 Tab 导航
tab1, tab2 = st.tabs(["📊 战况总览 (Dashboard)", "⏱️ 执行打卡 (Check-in)"])

# =========== Tab 1: 战况总览 ===========
with tab1:
    # 核心指标卡
    c1, c2, c3 = st.columns(3)
    c1.metric("今日综合评分", f"{today_score} 分", help="基于完成度与质量加权计算")
    c2.metric("今日专注时长", f"{today_hours} 小时", help="实际打卡记录的时间总和")
    c3.metric("当前总进度", f"{global_progress:.1%}", f"{int(done_items)}/{total_items}")

    st.markdown("---")
    
    # 图表区
    col_chart1, col_chart2 = st.columns(2)
    
    with col_chart1:
        st.markdown("#### 📈 综合得分趋势")
        # 构建图表数据
        chart_data = []
        for date_key, records in st.session_state.data["daily_records"].items():
            s, h = calculate_daily_score(records)
            chart_data.append({"Date": date_key, "Score": s})
        
        if chart_data:
            df_chart = pd.DataFrame(chart_data).set_index("Date")
            st.line_chart(df_chart)
        else:
            st.info("暂无历史数据，打卡后生成曲线。")

    with col_chart2:
        st.markdown("#### 🕸️ 学科进度分布")
        # 简单柱状图代替雷达图（Streamlit原生不支持雷达图，柱状图更直观）
        task_progress_data = {k: (v["done"]/v["total"]*100) for k,v in all_tasks.items()}
        st.bar_chart(pd.DataFrame.from_dict(task_progress_data, orient='index', columns=['进度%']))

    # 底部详情表
    with st.expander("查看各科详细数据表"):
        st.table(pd.DataFrame(all_tasks).T[["total", "done", "unit"]])


# =========== Tab 2: 执行打卡 ===========
with tab2:
    st.info("💡 操作指南：先点击 [开始] 计时，任务结束后点击 [结束]，然后评星打卡。")
    
    # 遍历任务生成卡片
    tasks = st.session_state.data["tasks"]
    
    for t_name, t_info in tasks.items():
        with st.container(border=True):
            col_a, col_b, col_c = st.columns([1, 2, 1])
            
            with col_a:
                st.markdown(f"### {t_info['icon']} {t_name}")
                st.caption(f"剩余: {t_info['total'] - t_info['done']} {t_info['unit']}")
                
                # 计时器逻辑
                is_running = t_name in st.session_state.active_timers
                
                if not is_running:
                    if st.button(f"▶️ 开始专注", key=f"start_{t_name}"):
                        st.session_state.active_timers[t_name] = time.time()
                        st.rerun()
                else:
                    start_time = st.session_state.active_timers[t_name]
                    elapsed = int(time.time() - start_time)
                    st.markdown(f"🔴 **计时中... {elapsed//60} 分钟**")
                    
                    if st.button(f"⏹️ 结束专注", key=f"stop_{t_name}"):
                        end_time = time.time()
                        duration_mins = int((end_time - start_time) / 60)
                        # 移除计时状态
                        del st.session_state.active_timers[t_name]
                        # 存入临时状态供打卡使用 (使用 session_state 传递给下面的表单)
                        st.session_state[f"last_duration_{t_name}"] = duration_mins
                        st.rerun()

            with col_b:
                # 获取刚刚结束的计时时长（如果有）
                default_duration = st.session_state.get(f"last_duration_{t_name}", 0)
                
                # 结果录入表单
                st.markdown("**本次产出评估：**")
                
                # 1. 时长显示与手动修正
                duration_input = st.number_input(
                    "专注时长 (分钟)", 
                    value=default_duration, 
                    min_value=0, 
                    step=5, 
                    key=f"dur_in_{t_name}"
                )
                
                # 2. 进度滑块 (0-150%)
                # 计算今日目标：简单逻辑，剩余总量/剩余天数 (假设20天)
                daily_target_raw = (t_info['total'] - t_info['done']) / max(1, (25 - 1)) # 简化
                
                completion_percent = st.slider(
                    f"完成度 (100% = 达标)", 
                    0, 150, 0, 10, 
                    key=f"slide_{t_name}",
                    help="超过100%代表超额完成"
                )
                
                # 3. 质量评分
                stars = st.feedback("stars", key=f"star_{t_name}")
                if stars is None: stars = 0 # st.feedback 返回 0-4 index, or None
                actual_stars = stars + 1 # 转换成 1-5 分

            with col_c:
                st.markdown("<br><br>", unsafe_allow_html=True) # 排版占位
                if st.button(f"✅ 确认打卡", key=f"submit_{t_name}", use_container_width=True):
                    if completion_percent > 0 or duration_input > 0:
                        save_state_to_history() # 记入历史以便撤销
                        
                        # 1. 更新总进度
                        # 假设 100% 完成度 = 1 个单位的今日目标 (这里做简化处理，直接按比例折算)
                        # 也可以让用户直接输入完成了多少 "页/题"
                        # 为了符合你的需求 "完成百分比"，我们反推完成量
                        # 这里我们简化：假设用户心里知道100%是多少，这里我们主要记录投入
                        # 如果需要精确扣减库存：
                        # 假设每天平均要修 2 个单位
                        daily_avg_need = max(1, t_info['total'] / 25) 
                        completed_amount = daily_avg_need * (completion_percent / 100.0)
                        
                        st.session_state.data["tasks"][t_name]["done"] += round(completed_amount, 2)
                        
                        # 2. 记录今日详情 (用于算分)
                        if today_str not in st.session_state.data["daily_records"]:
                            st.session_state.data["daily_records"][today_str] = {}
                        
                        # 累加今日数据
                        current_record = st.session_state.data["daily_records"][today_str].get(t_name, {"percent": 0, "stars": 0, "duration": 0})
                        # 这种累加逻辑：取最新的百分比？还是累加？
                        # 打卡通常是“增加”，所以百分比我们取“本次”，时长累加，星级取平均或最新
                        # 简化：记录本次打卡
                        new_duration = current_record["duration"] + duration_input
                        # 星级取本次，百分比取本次 (假设多次打卡是分段做)
                        
                        st.session_state.data["daily_records"][today_str][t_name] = {
                            "percent": completion_percent, # 这里记录的是单次完成度
                            "stars": actual_stars,
                            "duration": new_duration
                        }
                        
                        persist_to_disk()
                        st.toast(f"{t_name} 打卡成功！", icon="🎉")
                        time.sleep(1)
                        st.rerun()
                    else:
                        st.warning("请填写进度或时长")

# --- 底部版权 ---
st.markdown("---")
st.markdown(f"<div style='text-align: center; color: grey;'>{AUTHOR_TAG}</div>", unsafe_allow_html=True)

