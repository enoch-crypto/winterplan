@echo off
chcp 65001 > nul
echo ========================================
echo   寒假逆袭作战指挥部 - 启动脚本
echo ========================================
echo.

REM 检查Python是否安装
python --version > nul 2>&1
if errorlevel 1 (
    echo ❌ 未检测到Python，请先安装Python 3.8+
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查依赖是否安装
echo 🔍 检查依赖包...
python -c "import streamlit" > nul 2>&1
if errorlevel 1 (
    echo 📦 正在安装依赖包...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ 依赖安装失败，请手动安装:
        echo pip install streamlit pandas altair
        pause
        exit /b 1
    )
    echo ✅ 依赖安装完成
) else (
    echo ✅ 依赖已安装
)

echo.
echo 🚀 启动Streamlit应用...
echo 📱 应用将在浏览器中打开
echo ⏳ 如果端口被占用，请按Ctrl+C终止后重试
echo.

REM 启动应用
streamlit run winter_plan_app.py --server.port 8501

if errorlevel 1 (
    echo.
    echo ⚠️  端口8501可能被占用，尝试其他端口...
    streamlit run winter_plan_app.py --server.port 8502
)

echo.
echo ========================================
echo   应用已关闭
echo ========================================
pause