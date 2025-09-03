#!/bin/bash
# Script para executar o projeto

source venv/bin/activate
cd backend
python manage.py runserver 0.0.0.0:8000
