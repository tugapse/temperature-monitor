# Este script foi concebido para ser 'sourced' por outros scripts wrapper.
# Ele fornece uma função para ativar um ambiente virtual e executar um script Python,
# assumindo que o projeto e o seu ambiente virtual já estão configurados em TOOLS_BASE_DIR.

# --- Configuração Comum ---
# Diretório base onde os repositórios Python são clonados.
# Este deve corresponder a TOOLS_BASE_DIR em setup-service-users.sh.
COMMON_TOOLS_BASE_DIR="/usr/local/bin/tools"

# --- Funções Comuns ---

# Função para registar mensagens (para o registo interno dos scripts wrapper que o 'sourcing')
# Requer que a variável 'REPO_NAME' esteja definida no script que o 'sourcing'.
log_wrapper_message() {
    local type="$1"
    local message="$2"
    # A saída para stderr pode ser capturada por run.sh e direcionada para out.log
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WRAPPER-${REPO_NAME}-$type] $message" >&2
}

# Função para verificar se um comando existe
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

# Função principal para executar um projeto Python
# Esta função deve ser chamada pelos scripts wrapper individuais.
# Requer que a variável 'REPO_NAME' seja definida no script que o 'sourcing' antes de chamar esta função.
# Argumentos: "$@" - todos os argumentos passados para o script wrapper original.
run_python_project() {
    # Caminhos derivados com base em REPO_NAME
    local project_dir="$COMMON_TOOLS_BASE_DIR/$REPO_NAME"
    local venv_dir="$project_dir/.venv"
    local main_script="$project_dir/main.py"

    log_wrapper_message "DEBUG" "Caminho do Projeto: $project_dir"
    log_wrapper_message "DEBUG" "Caminho do Venv: $venv_dir"
    log_wrapper_message "DEBUG" "Caminho do Script Principal: $main_script"
    log_wrapper_message "DEBUG" "Utilizador atual: $(whoami)"
    log_wrapper_message "DEBUG" "PATH atual: $PATH"

    # --- Verificações de Pré-execução ---
    # Garante que as ferramentas essenciais estão disponíveis (verificação extra de robustez)
    if ! command_exists python3; then
        log_wrapper_message "ERROR" "'python3' não está instalado. Por favor, instale o python para continuar (ex: sudo pacman -S python)."
        exit 1
    fi

    # Verificar se o diretório do projeto e o ambiente virtual existem
    if [ ! -d "$project_dir" ]; then
        log_wrapper_message "ERROR" "Diretório do projeto Python '$project_dir' não encontrado. Ele deveria ter sido clonado e configurado por 'setup-service-users.sh'."
        exit 1
    fi
    if [ ! -d "$venv_dir" ]; then
        log_wrapper_message "ERROR" "Ambiente virtual Python '$venv_dir' não encontrado dentro do projeto '$project_dir'. Ele deveria ter sido criado por 'setup-service-users.sh'."
        exit 1
    fi
    if [ ! -f "$main_script" ]; then
        log_wrapper_message "ERROR" "Script principal Python '$main_script' não encontrado. Verifique se o repositório foi clonado corretamente por 'setup-service-users.sh'."
        exit 1
    fi

    # Verificar permissões do venv e do script principal
    if [ ! -r "$venv_dir/bin/activate" ]; then
        log_wrapper_message "ERROR" "Ficheiro de ativação do ambiente virtual '$venv_dir/bin/activate' não é legível. Verifique as permissões."
        exit 1
    fi
    if [ ! -x "$venv_dir/bin/python" ]; then
        log_wrapper_message "ERROR" "Executável Python do ambiente virtual '$venv_dir/bin/python' não é executável. Verifique as permissões."
        exit 1
    fi
    if [ ! -r "$main_script" ]; then
        log_wrapper_message "ERROR" "Script Python principal '$main_script' não é legível. Verifique as permissões."
        exit 1
    fi


    # --- Ativar Ambiente Virtual ---
    log_wrapper_message "INFO" "A ativar o ambiente virtual para execução."
    # IMPORTANTE: Usar 'bash -c "source ... && command"' para garantir que a ativação acontece
    # dentro de um subshell que depois executa o Python, se houver problemas com 'source' direto.
    # No entanto, vamos tentar o 'source' direto primeiro para ver o erro exato se este continuar.
    source "$venv_dir/bin/activate"
    if [ $? -ne 0 ]; then
        log_wrapper_message "ERROR" "Falha CRÍTICA ao ativar o ambiente virtual em '$venv_dir/bin/activate'. Isto pode ser devido a permissões ou um ambiente bash limitado."
        exit 1
    fi

    # --- Executar Script Python Principal ---
    log_wrapper_message "INFO" "A executar '$main_script' com argumentos: '$@'"
    python "$main_script" "$@"
    local python_script_exit_code=$? # Capturar o código de saída do script Python

    # --- Desativar Ambiente Virtual ---
    deactivate
    log_wrapper_message "INFO" "Ambiente virtual desativado."

    return $python_script_exit_code # Retornar o código de saída do script Python
}