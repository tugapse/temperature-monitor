#!/bin/bash
# Script para reverter todas as alterações feitas por setup-service-users.sh.
# Isto inclui eliminar o utilizador/grupo dedicado e os diretórios associados.

# --- Configuração (DEVE corresponder a setup-service-users.sh) ---
MONITOR_USER="temperature_monitor_user"
MONITOR_GROUP="temperature_monitor_group"

SERVICE_LOG_DIR="/var/log/temperature-monitor"
DATA_LOG_DIR="/var/lib/temperature-monitor/data" # Agora apenas um caminho de dados
TOOLS_BASE_DIR="/usr/local/bin/tools" # Diretório base para as ferramentas

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

# --- Lógica Principal do Script ---

# Verificar se o script é executado como root e se SUDO_USER está definido
if [[ $EUID -ne 0 ]]; then
   log_error "Este script deve ser executado como root. Por favor, use 'sudo ./cleanup-setup-users.sh'"
   exit 1
fi
if [[ -z "$SUDO_USER" ]]; then
    log_error "Não foi possível determinar o utilizador que invocou o sudo. Por favor, execute este script com 'sudo ./cleanup-setup-users.sh'."
    exit 1
fi

log_info "A iniciar a limpeza da configuração para o utilizador '$MONITOR_USER' e diretórios associados..."

# 1. Remover Diretórios
log_info "A tentar remover os diretórios de registo e ferramentas..."

# Remover Diretório de Registos do Serviço
if [ -d "$SERVICE_LOG_DIR" ]; then
    log_info "A remover o diretório de registos do serviço: '$SERVICE_LOG_DIR'..."
    rm -rf "$SERVICE_LOG_DIR"
    if [ $? -eq 0 ]; then
        log_info "Diretório '$SERVICE_LOG_DIR' removido com sucesso."
    else
        log_error "Falha ao remover o diretório '$SERVICE_LOG_DIR'. Pode ser necessária remoção manual."
    fi
else
    log_warn "Diretório de registos do serviço '$SERVICE_LOG_DIR' não encontrado. A ignorar a remoção."
fi

# Removido: Lógica para DATA_LOG_DEFAULT_USER_PATH

# Remover Caminho Predefinido de Registos de Dados do Sistema
if [ -d "$DATA_LOG_DIR" ]; then
    log_info "A remover o diretório de registos de dados do sistema: '$DATA_LOG_DIR'..."
    rm -rf "$DATA_LOG_DIR"
    if [ $? -eq 0 ]; then
        log_info "Diretório '$DATA_LOG_DIR' removido com sucesso."
    else
        log_error "Falha ao remover o diretório '$DATA_LOG_DIR'. Pode ser necessária remoção manual."
    fi
else
    log_warn "Diretório de registos de dados do sistema '$DATA_LOG_DIR' não encontrado. A ignorar a remoção."
fi

# Remover Diretório Base das Ferramentas (onde os repositórios são clonados)
if [ -d "$TOOLS_BASE_DIR" ]; then
    log_info "A remover o diretório base das ferramentas: '$TOOLS_BASE_DIR'..."
    rm -rf "$TOOLS_BASE_DIR"
    if [ $? -eq 0 ]; then
        log_info "Diretório '$TOOLS_BASE_DIR' removido com sucesso."
    else
        log_error "Falha ao remover o diretório '$TOOLS_BASE_DIR'. Pode ser necessária remoção manual."
    fi
else
    log_warn "Diretório base das ferramentas '$TOOLS_BASE_DIR' não encontrado. A ignorar a remoção."
fi

# 2. Remover Utilizador Dedicado
if id -u "$MONITOR_USER" > /dev/null 2>&1; then
    log_info "A remover o utilizador de sistema '$MONITOR_USER'..."
    userdel "$MONITOR_USER"
    if [ $? -eq 0 ]; then
        log_info "Utilizador '$MONITOR_USER' removido com sucesso."
    else
        log_error "Falha ao remover o utilizador '$MONITOR_USER'. Pode ser necessária remoção manual."
    fi
else
    log_warn "Utilizador '$MONITOR_USER' não encontrado. A ignorar a remoção."
fi

# 3. Remover Grupo Dedicado
if getent group "$MONITOR_GROUP" > /dev/null; then
    log_info "A remover o grupo de sistema '$MONITOR_GROUP'..."
    groupdel "$MONITOR_GROUP"
    if [ $? -eq 0 ]; then
        log_info "Grupo '$MONITOR_GROUP' removido com sucesso."
    else
        log_error "Falha ao remover o grupo '$MONITOR_GROUP'."
        exit 1
    fi
else
    log_warn "Grupo '$MONITOR_GROUP' não encontrado. A ignorar a remoção."
fi

log_info "Limpeza concluída. O seu sistema deverá ter sido revertido das alterações de setup-service-users.sh."
log_info "Se ocorreram erros acima, pode ser necessária verificação/limpeza manual."