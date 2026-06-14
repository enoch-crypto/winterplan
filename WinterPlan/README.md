# 寒假逆袭作战指挥部 🚀

一个为初三学生设计的寒假学习计划管理应用，帮助科学规划、动态调整、可视化追踪学习进度。

## 功能特点

### 📊 核心功能
- **任务管理**: 11个学习科目/活动任务（物理、化学、数学、英语、历史/道法、艺术、运动）
- **动态目标计算**: 根据剩余天数自动计算每日任务量
- **进度追踪**: 实时显示每个任务的完成进度
- **数据持久化**: 自动保存学习数据到JSON文件

### 🎯 智能特性
- **自适应调整**: 超额完成自动减少后续负担
- **进度可视化**: 数据表格和进度条展示
- **成就系统**: 完成度评估和鼓励反馈
- **数据备份**: 支持数据导出和重置

### 🎨 用户体验
- **响应式布局**: 适配不同屏幕尺寸
- **直观界面**: 卡片式任务展示，图标辅助识别
- **即时反馈**: 提交后实时更新进度
- **移动友好**: 适合在手机端查看

## 快速开始

### 环境要求
- Python 3.8+
- Streamlit 1.28+

### 安装步骤

1. **克隆或下载项目**
   ```bash
   git clone <repository-url>
   cd WinterPlan
   ```

2. **安装依赖**
   ```bash
   pip install -r requirements.txt
   ```

3. **运行应用**
   ```bash
   streamlit run winter_plan_app.py
   ```

4. **访问应用**
   打开浏览器访问：`http://localhost:8501`

### 多种启动方式

#### 方式一：高端口启动（推荐，解决Windows权限问题）
```bash
python start_app_high_port.py
```
或
```bash
streamlit run winter_plan_app.py --server.port 10086
```

#### 方式二：标准启动
```bash
streamlit run winter_plan_app.py
```

#### 方式三：Python启动脚本
```bash
python start_app.py
```

#### 方式四：Windows批处理脚本
- 简单版：双击 `run_app_simple.bat`
- 完整版：双击 `run_app.bat`（可能有编码问题）

#### 方式五：指定其他端口
```bash
streamlit run winter_plan_app.py --server.port 8502
```

## 使用指南

### 首次使用
1. 应用会自动创建 `my_study_plan.json` 数据文件
2. 初始数据包含11个预设任务
3. 开始日期默认为当天

### 日常使用流程
1. **查看今日目标**: 主界面显示每个任务的今日建议完成量
2. **设置完成度**: 使用滑块设置完成百分比（0%-120%）
3. **提交打卡**: 点击"打卡提交"按钮记录完成情况
4. **查看进度**: 实时更新进度条和数据统计

### 数据管理
- **导出数据**: 侧边栏可下载JSON格式备份
- **重置数据**: 谨慎使用，会清除所有进度记录
- **自动保存**: 每次提交后自动保存到本地文件

## 任务配置

### 默认任务列表
| 任务名称 | 总量 | 单位 | 图标 |
|---------|------|------|------|
| 物理 (压轴/大题) | 30 | 题 | ⚡ |
| 物理 (空中课堂) | 19 | 个 | 📺 |
| 化学 (二模卷) | 15 | 套 | 🧪 |
| 化学 (指导册/梳理) | 50 | 页 | 📘 |
| 数学 (几何/思考题) | 20 | 题 | 📐 |
| 数学 (指导册基础) | 22 | 页 | ✏️ |
| 英语 (二模卷/D篇) | 15 | 套 | 🔤 |
| 英语 (作文) | 5 | 篇 | 📝 |
| 历史/道法 (笔记作业) | 7 | 项 | 📜 |
| 钢琴/阅读 (艺术留白) | 25 | 次 | 🎹 |
| 足球/运动 | 18 | 次 | ⚽ |

### 自定义配置
如需修改任务配置，可直接编辑 `winter_plan_app.py` 文件中的 `DEFAULT_PLAN` 字典。

## 技术架构

### 文件结构
```
WinterPlan/
├── winter_plan_app.py       # 主应用文件
├── requirements.txt         # 依赖包列表
├── README.md               # 说明文档
├── start_app_high_port.py  # 高端口启动脚本（推荐，解决权限问题）
├── start_app.py            # Python启动脚本
├── run_app_simple.bat      # Windows简单启动脚本
├── run_app.bat             # Windows完整启动脚本
├── test_app.py             # 功能测试脚本
└── my_study_plan.json      # 数据文件（运行时生成）
```

### 核心技术栈
- **前端**: Streamlit
- **数据处理**: Pandas
- **数据可视化**: Altair（预留）
- **数据存储**: JSON

### 核心算法
```python
# 每日目标计算
每日目标 = (任务总量 - 已完成量) / 剩余天数

# 进度计算
进度百分比 = 已完成量 / 任务总量 × 100%
```

## 故障排除

### 常见问题

1. **Windows端口权限错误**
   ```
   PermissionError: [WinError 10013] An attempt was made to access a socket...
   ```
   **原因**: Windows对低端口（<1024）有权限限制
   **解决方案**: 使用高端口启动
   ```bash
   # 方法1：使用高端口启动脚本
   python start_app_high_port.py
   
   # 方法2：手动指定高端口
   streamlit run winter_plan_app.py --server.port 10086
   ```

2. **端口占用错误**
   **解决方案**: 修改端口号
   ```bash
   streamlit run winter_plan_app.py --server.port 8502
   ```

3. **依赖安装失败**
   **解决方案**: 使用国内镜像源
   ```bash
   pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
   ```

4. **应用无法启动**
   **解决方案**: 检查Python版本和Streamlit安装
   ```bash
   python --version
   pip list | findstr streamlit
   ```

5. **编码问题（Windows批处理）**
   **解决方案**: 使用Python启动脚本
   ```bash
   python start_app_high_port.py
   ```

### 调试模式
```bash
# 显示详细日志
streamlit run winter_plan_app.py --logger.level=debug
```

## 开发说明

### 代码结构
```python
# 1. 环境自检与初始化
# 2. 核心数据配置
# 3. 逻辑处理函数
# 4. 界面UI设计
```

### 扩展建议
1. **添加图表可视化**: 使用Altair创建学习趋势图
2. **增加用户认证**: 支持多用户数据隔离
3. **添加提醒功能**: 每日学习提醒
4. **集成日历视图**: 显示每日完成情况
5. **添加分享功能**: 一键分享进度到社交平台

## 许可证

本项目仅供学习使用，遵循 MIT 许可证。

## 贡献指南

欢迎提交Issue和Pull Request来改进这个项目。

## 联系方式

如有问题或建议，请通过GitHub Issues提交。

---
**祝您寒假学习顺利，中考取得优异成绩！** 🎓✨