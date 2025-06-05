#!/bin/bash
# Wrapper script para o projeto Python gpu-temp.
# Este script 'sources' a lógica comum para ativar um ambiente virtual e executar main.py.

# Definir o nome único do repositório para este wrapper
REPO_NAME="gpu-temp"

# 'Source' a lógica comum do executor de script Python
# O caminho é onde temperature_monitor_service_manager.sh o copiará.
source "/usr/local/bin/python_script_runner.sh"

# Chamar a função do script 'sourced' para executar o projeto Python.
# Passar todos os argumentos recebidos por este script wrapper.
run_python_project "$@"
exit $? # Sair com o código de saída da função chamada