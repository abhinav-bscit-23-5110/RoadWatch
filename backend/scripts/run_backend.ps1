# Simple helper to activate venv and run Django dev server bound to 0.0.0.0:8000
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force | Out-Null
. .\venv\Scripts\Activate.ps1
python manage.py runserver 0.0.0.0:8000
