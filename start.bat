@echo off
echo Starting Backend Server...

cd backend
start cmd /k npm start

echo Starting Flutter Frontend...

cd ..\frontend
flutter run

pause