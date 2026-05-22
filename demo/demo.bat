@echo off
cd /d "%~dp0"
title AI Learning OS Demo
cls

echo =======================================
echo      AI Learning OS - Demo
echo =======================================
echo.
echo  This demo shows how the system works
echo  in 5 steps. Press Enter for each step.
echo.
pause

cls
echo =======================================
echo  STEP 1/5 : Launch Dashboard
echo =======================================
echo.
echo  Double-click dashboard.bat
echo.
echo  ----------------------------------------
echo   [~] Learning Dashboard  2026-05-02
echo.
echo   Today's Plan:
echo      [ ] CLIP Overview
echo      [ ] Contrastive Loss
echo      [ ] Mini Exercise
echo.
echo   Stage Progress:
echo     Main Goal    ########---   2/10
echo     Foundation   -----------   0/18
echo.
echo   Grade: A   Score: 82/100
echo   Streak: 1 day   Last: today
echo  ----------------------------------------
echo.
echo  Dashboard reads progress.json and journal/
echo  to show your learning progress in real time.
echo.
pause

cls
echo =======================================
echo  STEP 2/5 : Pick a Section
echo =======================================
echo.
echo  Inside dashboard, type a number:
echo.
echo    [1] Main Goal
echo    [2] Foundation
echo    [0] Exit
echo.
echo  - You type: 1
echo.
echo  - Result: current_session.md is auto-written
echo  - Now tell AI: "Start today's learning"
echo.
pause

cls
echo =======================================
echo  STEP 3/5 : AI Tutoring
echo =======================================
echo.
echo  You: "Start today's learning"
echo.
echo  AI reads progress.json + current_session.md
echo  and starts teaching:
echo.
echo   AI: Last time you learned CLIP architecture.
echo   AI: Today we go deeper into Contrastive Loss.
echo   AI: What do you already know about InfoNCE?
echo.
echo   (You learn. AI writes code, tests understanding,
echo    asks follow-up questions.)
echo.
pause

cls
echo =======================================
echo  STEP 4/5 : Auto-Logging
echo =======================================
echo.
echo  You: "That's enough for today"
echo.
echo  AI auto-executes (NO confirmation needed):
echo.
echo   1. progress.json   --  progress + 1
echo   2. journal/2026-05-02.md  --  write log
echo   3. current_session.md     --  mark [x] done
echo.
echo  New journal entry:
echo.
echo   ## 2026-05-02 10:30 - Contrastive Loss
echo    Stage: Main Goal
echo    Duration: 60 min
echo    Notes: InfoNCE loss, temperature parameter,
echo           PyTorch implementation
echo.
pause

cls
echo =======================================
echo  STEP 5/5 : Progress Updated
echo =======================================
echo.
echo  Re-open dashboard:
echo.
echo  ----------------------------------------
echo   [~] Learning Dashboard  2026-05-02
echo.
echo   Today's Plan:
echo      [V] CLIP Overview
echo      [V] Contrastive Loss
echo      [ ] Mini Exercise
echo.
echo   Stage Progress:
echo     Main Goal    #########---   3/10
echo     Foundation   -----------   0/18
echo.
echo   Grade: A   Score: 90/100
echo   Today learned   Last: today
echo  ----------------------------------------
echo.
echo  ============  CLOSED LOOP  ============
echo.
echo  Data flow:
echo    progress.json --^> dashboard
echo        --^> current_session.md
echo        --^> AI --^> journal
echo        --^> progress.json
echo.
echo  Every session auto-saves. Zero manual logging.
echo.
pause
exit
