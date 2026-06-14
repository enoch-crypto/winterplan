@echo off
echo ========================================
echo   寒假逆袭作战指挥部 - 启动脚本
echo ========================================
echo.

REM 检查Python是否安装
python --version > nul 2>&1
if errorlevel 1 (
    echo 错误: 未检测到Python，请先安装Python 3.8+
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查依赖
echo 检查依赖包...
python -c "import streamlit" > nul 2>&1
if errorlevel 1 (
    echo 正在安装依赖包...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo 依赖安装失败，请手动安装:
        echo pip install streamlit pandas altair
        pause
        exit /b 1
    )
    echo 依赖安装完成
) else (
    echo 依赖已安装
)

echo.
echo 启动Streamlit应用...
echo 应用将在浏览器中打开
echo 如果端口被占用，请按Ctrl+C终止后重试
echo.

REM 尝试多个端口
for %%p in (8501 8502 8503 8504 8505) do (
    echo 尝试端口: %%p
    streamlit run winter_plan_app.py --server.port %%p
    if not errorlevel 1 exit /b 0
)

echo.
echo 错误: 所有端口尝试失败，请检查网络或防火墙设置
pause