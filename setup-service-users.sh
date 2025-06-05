#!/bin/bash

# --- Configuração ---
MONITOR_USER="temperature_monitor_user"
MONITOR_GROUP="temperature_monitor_group"

# Diretório para os registos operacionais do script (ex: out.log)
SERVICE_LOG_DIR="/var/log/temperature-monitor"

# Diretório para os registos de saída de dados de temperatura (usado por run.sh)
DATA_LOG_DIR="/var/lib/temperature-monitor/data"

# Diretório base onde os repositórios de projetos Python serão clonados
TOOLS_BASE_DIR="/usr/local/bin/tools"

# Repositórios dos projetos Python
declare -A PYTHON_REPOS
PYTHON_REPOS["cpu-temp"]="https://github.com/tugapse/cpu-temp.git"
PYTHON_REPOS["gpu-temp"]="https://github.com/tugapse/gpu-temp.git"

# --- Códigos de Cor ANSI ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m' # Adicionado amarelo para avisos/informações
COLOR_NC='\033[0m' # Sem Cor (reset)

# --- Funções ---

# Função para registar mensagens para stdout
log_info() {
    echo -e "${COLOR_GREEN}[INFO] $1${COLOR_NC}"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN] $1${COLOR_NC}"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR] $1${COLOR_NC}" >&2
}

# Função para verificar se um comando existe e fornecer orientação de instalação
check_tool_installed() {
    local tool_name="$1"
    local install_cmd="$2"
    if ! command -v "$tool_name" >/dev/null 2>&1; then
        log_error "Ferramenta necessária '$tool_name' não está instalada."
        log_error "Por favor, instale-a usando: $install_cmd"
        exit 1
    fi
    log_info "Ferramenta '$tool_name' está instalada."
}

# Função para criar um diretório e definir permissões
setup_directory() {
    local dir_path="$1"
    local dir_description="$2"

    log_info "A verificar e configurar o diretório $dir_description: '$dir_path'..."

    # Verificar se o diretório existe, caso contrário, tentar criá-lo
    if [ ! -d "$dir_path" ]; then
        log_info "Diretório '$dir_path' não encontrado. A tentar criar..."
        mkdir -p "$dir_path"
        if [ $? -eq 0 ]; then
            log_info "Diretório '$dir_path' criado com sucesso."
        else
            log_error "FALHA CRÍTICA: Falha ao criar o diretório '$dir_path'. Verifique as permissões dos diretórios pai."
            exit 1 # Sair se não for possível criar o diretório
        fi
    else
        log_warn "Diretório '$dir_path' já existe. A ignorar a criação."
    fi

    log_info "A definir propriedade e permissões para '$dir_path' para '$MONITOR_USER':'$MONITOR_GROUP'..."
    chown "$MONITOR_USER":"$MONITOR_GROUP" "$dir_path"
    if [ $? -ne 0 ]; then
        log_error "FALHA CRÍTICA: Falha ao definir propriedade para '$dir_path'. Verifique se o utilizador/grupo '$MONITOR_USER':'$MONITOR_GROUP' existe e se tem permissões para alterar a propriedade."
        exit 1 # Sair se não for possível definir a propriedade
    fi

    chmod 770 "$dir_path" # O proprietário (utilizador) e o Grupo têm acesso total
    if [ $? -ne 0 ]; then
        log_error "FALHA CRÍTICA: Falha ao definir permissões para '$dir_path'. Verifique as permissões atuais e se o utilizador tem privilégios suficientes."
        exit 1 # Sair se não for possível definir as permissões
    fi
    log_info "Permissões para '$dir_path' definidas com sucesso (proprietário: $MONITOR_USER, grupo: $MONITOR_GROUP, modo: 770)."
    log_info "Pode verificar as permissões com: ls -ld $dir_path"
}

# Função para clonar repositório e configurar venv
clone_and_setup_python_repo() {
    local repo_name="$1"
    local github_url="$2"
    local project_dir="$TOOLS_BASE_DIR/$repo_name"
    local venv_dir="$project_dir/.venv"
    local main_script="$project_dir/main.py" # Adicionado para chmod
    local requirements_file="$project_dir/requirements.txt"

    log_info "A verificar o repositório '$repo_name' em '$project_dir'..."
    if [ -d "$project_dir" ]; then
        log_warn "Repositório '$repo_name' já existe em '$project_dir'. A ignorar a clonagem."
    else
        log_info "A clonar '$github_url' para '$project_dir'..."
        unset GITHUB_TOKEN # Garantir que nenhum token GitHub persistente interfere
        unset GIT_SSH_COMMAND # Garantir que não tenta SSH
        env -i HOME="/tmp" GIT_ASKPASS="" GIT_TERMINAL_PROMPT=0 git clone "$github_url" "$project_dir"
        if [ $? -ne 0 ]; then
            log_error "Falha ao clonar o repositório '$github_url'. Verifique o acesso à rede e a URL."
            exit 1
        fi
        log_info "Repositório '$repo_name' clonado com sucesso."
    fi

    log_info "A configurar ambiente virtual para '$repo_name' em '$venv_dir'..."
    if [ -d "$venv_dir" ]; then
        log_warn "Ambiente virtual para '$repo_name' já existe em '$venv_dir'. A ignorar a criação."
    else
        python3 -m venv "$venv_dir"
        if [ $? -ne 0 ]; then
            log_error "Falha ao criar ambiente virtual para '$repo_name'. Garanta que 'python3-venv' ou pacote similar está instalado."
            exit 1
        fi
        log_info "Ambiente virtual para '$repo_name' criado."
    fi

    # Instalar dependências
    if [ -f "$requirements_file" ]; then
        log_info "A instalar dependências para '$repo_name' de '$requirements_file'..."
        source "$venv_dir/bin/activate" # Ativar temporariamente o venv para pip
        pip install -r "$requirements_file" --no-input --disable-pip-version-check
        if [ $? -ne 0 ]; then
            log_error "Falha ao instalar dependências para '$repo_name'. Verifique '$requirements_file' e o registo para erros detalhados do pip."
            deactivate
            exit 1
        fi
        deactivate # Desativar o venv
        log_info "Dependências para '$repo_name' instaladas."
    else
        log_warn "Ficheiro requirements.txt não encontrado para '$repo_name'. A ignorar a instalação de dependências."
    fi

    # Definir propriedade para o utilizador do serviço (MONITOR_USER) para o repositório e venv
    log_info "A definir propriedade para '$repo_name' e o seu ambiente virtual para '$MONITOR_USER':'$MONITOR_GROUP'..."
    chown -R "$MONITOR_USER":"$MONITOR_GROUP" "$project_dir"
    if [ $? -ne 0 ]; then
        log_error "Falha ao definir propriedade para '$project_dir'."
        exit 1
    fi

    # Ajuste de permissões mais específico:
    # 1. Definir permissões para todos os ficheiros e diretórios dentro do projeto clonado.
    #    Para diretórios, defina-os como 770. Para ficheiros, 660.
    find "$project_dir" -type d -exec chmod 770 {} +
    find "$project_dir" -type f -exec chmod 660 {} +

    # 2. Assegurar que os scripts Python (.py) e os executáveis do venv são executáveis para o grupo.
    #    Isto é crucial para o utilizador do serviço.
    chmod g+x "$project_dir"/main.py # Assegurar que main.py é executável para o grupo
    # Apenas se venv/bin existir e contiver ficheiros
    if [ -d "$venv_dir/bin" ]; then
        chmod g+x "$venv_dir"/bin/* # Assegurar que os executáveis do venv/bin são executáveis para o grupo
    fi


    if [ $? -ne 0 ]; then
        log_error "Falha ao definir permissões adicionais para '$project_dir'."
        exit 1
    fi
    log_info "Propriedade e permissões para '$repo_name' definidas."
}


# --- Lógica Principal do Script ---

# Verificar se o script é executado como root e se SUDO_USER está definido
if [[ $EUID -ne 0 ]]; then
   log_error "Este script deve ser executado como root. Por favor, use 'sudo ./setup-service-users.sh'"
   exit 1
fi
if [[ -z "$SUDO_USER" ]]; then
    log_error "Não foi possível determinar o utilizador que invocou o sudo. Por favor, execute este script com 'sudo ./setup-service-users.sh'."
    exit 1
fi

log_info "A iniciar a configuração para o utilizador '$MONITOR_USER' e diretórios de registo para o utilizador '$SUDO_USER'..."
log_info "Caminho de registo de dados principal: $DATA_LOG_DIR" # Refere-se agora ao caminho fixo do sistema

# Verificações prévias para ferramentas de sistema necessárias
check_tool_installed "git" "sudo pacman -S git"
check_tool_installed "python3" "sudo pacman -S python"


# 1. Criar o grupo dedicado
if getent group "$MONITOR_GROUP" > /dev/null; then
    log_info "Grupo '$MONITOR_GROUP' já existe. A ignorar a criação."
else
    log_info "A criar o grupo de sistema '$MONITOR_GROUP'..."
    groupadd --system "$MONITOR_GROUP"
    if [ $? -eq 0 ]; then
        log_info "Grupo '$MONITOR_GROUP' criado com sucesso."
    else
        log_error "Falha ao criar o grupo '$MONITOR_GROUP'."
        exit 1
    fi
fi

# 2. Criar o utilizador dedicado
if id -u "$MONITOR_USER" > /dev/null 2>&1; then
    log_info "Utilizador '$MONITOR_USER' já existe. A ignorar a criação."
else
    log_info "A criar o utilizador de sistema '$MONITOR_USER'..."
    useradd --system --no-create-home --shell /sbin/nologin -g "$MONITOR_GROUP" "$MONITOR_USER"
    if [ $? -eq 0 ]; then
        log_info "Utilizador '$MONITOR_USER' criado com sucesso."
    else
        log_error "Falha ao criar o utilizador '$MONITOR_USER'."
        exit 1
    fi
fi

# 3. Configurar Diretório de Registos do Serviço
setup_directory "$SERVICE_LOG_DIR" "Registo do Serviço"

# 4. Configurar Caminho de Registos de Dados Principal (agora sempre o sistema)
setup_directory "$DATA_LOG_DIR" "Registo de Dados do Sistema"

# 5. Configurar Diretório Base das Ferramentas
setup_directory "$TOOLS_BASE_DIR" "Base das Ferramentas"

# 6. Clonar e configurar repositórios Python para o diretório de ferramentas
for REPO_KEY in "${!PYTHON_REPOS[@]}"; do
    clone_and_setup_python_repo "$REPO_KEY" "${PYTHON_REPOS[$REPO_KEY]}"
done

log_info "Configuração concluída. O utilizador '$MONITOR_USER' deverá agora ter permissões para os diretórios de registo e ferramentas."
log_info "Os repositórios de projetos Python foram clonados para: '$TOOLS_BASE_DIR'"
log_info "Os registos de dados serão armazenados em '$DATA_LOG_DIR'."
log_info "Pode testar os scripts wrapper manualmente (após a instalação do serviço): sudo -u $MONITOR_USER /usr/local/bin/cpu-temp-wrapper.sh -s"
log_info "E: sudo -u $MONITOR_USER /usr/local/bin/gpu-temp-wrapper.sh -s"