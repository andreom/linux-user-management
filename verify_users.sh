#!/bin/bash

# Linux User Management - Verify Users Script
# 
# Script para verificar usuários criados com GID 10000
# Uso: ./verify_users.sh [user1] [user2] ...
# Sem argumentos: verifica todos os usuários com GID 10000
#
# Autor: Sistema de Gerenciamento de Usuários  
# Versão: 1.0

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
readonly PRIMARY_GID=10000
readonly HOME_GROUP="sas"
readonly LOG_FILE="/var/log/user_management.log"

# Tratamento de sinais para limpeza
cleanup() {
    echo -e "${YELLOW}[AVISO]${NC} Script interrompido" >&2
    exit 130
}

trap cleanup SIGINT SIGTERM

# Função para logging em arquivo
log_to_file() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [[ -w "$LOG_FILE" ]] || [[ -w "$(dirname "$LOG_FILE")" ]]; then
        echo "[$timestamp] $message" >> "$LOG_FILE" 2>/dev/null
    fi
}

echo -e "${BLUE}=== VERIFICAÇÃO DE USUÁRIOS COM GID $PRIMARY_GID ===${NC}"
echo ""

# Função para verificar usuário
verify_user() {
    local username="$1"
    local user_info=$(getent passwd "$username" 2>/dev/null)
    
    if [[ -z "$user_info" ]]; then
        echo -e "${RED}✗ Usuário '$username' não existe${NC}"
        return 1
    fi
    
    local uid=$(echo "$user_info" | cut -d: -f3)
    local gid=$(echo "$user_info" | cut -d: -f4)
    local home=$(echo "$user_info" | cut -d: -f6)
    local shell=$(echo "$user_info" | cut -d: -f7)
    
    echo -e "${GREEN}✓ Usuário: $username${NC}"
    echo "  UID: $uid"
    echo "  GID: $gid $([ "$gid" = "$PRIMARY_GID" ] && echo -e "${GREEN}(correto)${NC}" || echo -e "${RED}(incorreto - esperado: $PRIMARY_GID)${NC}")"
    echo "  Home: $home"
    echo "  Shell: $shell"
    
    # Verificar diretório home
    if [[ -d "$home" ]]; then
        local dir_info=$(ls -ld "$home" 2>/dev/null)
        local dir_group=$(stat -c %G "$home" 2>/dev/null)
        echo "  Dir existe: ${GREEN}Sim${NC}"
        echo "  Dir grupo: $dir_group $([ "$dir_group" = "$HOME_GROUP" ] && echo -e "${GREEN}(correto)${NC}" || echo -e "${RED}(incorreto - esperado: $HOME_GROUP)${NC}")"
        echo "  Permissões: $(stat -c %a "$home" 2>/dev/null)"
    else
        echo -e "  Dir existe: ${RED}Não${NC}"
    fi
    echo ""
}

# Se argumentos forem fornecidos, verifica usuários específicos
if [[ $# -gt 0 ]]; then
    for username in "$@"; do
        verify_user "$username"
    done
else
    # Verifica todos os usuários com GID 10000
    echo "Verificando todos os usuários com GID $PRIMARY_GID:"
    echo ""
    
    getent passwd | while IFS=: read -r username _ uid gid _ _ home shell; do
        if [[ "$gid" = "$PRIMARY_GID" ]]; then
            verify_user "$username"
        fi
    done
fi

# Verificar grupos
echo -e "${BLUE}=== VERIFICAÇÃO DE GRUPOS ===${NC}"
echo ""

group_info=$(getent group "$PRIMARY_GID" 2>/dev/null)
if [[ -n "$group_info" ]]; then
    echo -e "${GREEN}✓ Grupo GID $PRIMARY_GID existe${NC}"
    echo "  Informações: $group_info"
else
    echo -e "${RED}✗ Grupo GID $PRIMARY_GID não existe${NC}"
fi

sas_info=$(getent group "$HOME_GROUP" 2>/dev/null)
if [[ -n "$sas_info" ]]; then
    echo -e "${GREEN}✓ Grupo '$HOME_GROUP' existe${NC}"
    echo "  Informações: $sas_info"
else
    echo -e "${RED}✗ Grupo '$HOME_GROUP' não existe${NC}"
fi