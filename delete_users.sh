#!/bin/bash

# Linux User Management - Delete Users Script
# 
# Script para excluir usuários no RHEL 9.6
# Uso: ./delete_users.sh [opções] <usuario1> [usuario2] [usuario3]...
# ou: ./delete_users.sh -f usuarios.txt
#
# Autor: Sistema de Gerenciamento de Usuários
# Versão: 1.0

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis globais
REMOVE_HOME=false
FORCE_DELETE=false
BACKUP_HOME=false
DRY_RUN=false
FROM_FILE=false
INTERACTIVE=true

# Usuários protegidos do sistema (não devem ser excluídos)
PROTECTED_USERS=(
    "root" "bin" "daemon" "adm" "lp" "sync" "shutdown" "halt" "mail"
    "operator" "games" "ftp" "nobody" "systemd-network" "dbus" "polkitd"
    "sshd" "postfix" "chrony" "tcpdump" "tss" "systemd-resolve"
    "systemd-timesync" "cockpit-ws" "cockpit-wsinstance"
)

# Função para exibir ajuda
show_help() {
    echo -e "${BLUE}=== Script para Excluir Usuários - RHEL 9.6 ===${NC}"
    echo ""
    echo -e "${CYAN}Uso:${NC}"
    echo "  $0 [opções] <usuario1> [usuario2] [usuario3]..."
    echo "  $0 -f <arquivo.txt>"
    echo ""
    echo -e "${CYAN}Opções:${NC}"
    echo "  -r, --remove-home    Remove o diretório home do usuário"
    echo "  -f, --force          Força a exclusão (mesmo se logado)"
    echo "  -b, --backup         Faz backup do diretório home antes de excluir"
    echo "  -d, --dry-run        Mostra o que seria feito sem executar"
    echo "  -y, --yes            Não pede confirmação (modo não-interativo)"
    echo "  -F, --file           Lê lista de usuários de um arquivo"
    echo "  -h, --help           Exibe esta ajuda"
    echo ""
    echo -e "${CYAN}Exemplos:${NC}"
    echo "  $0 usuario1                    # Exclui usuario1 (mantém home)"
    echo "  $0 -r usuario1 usuario2        # Exclui usuarios e seus homes"
    echo "  $0 -rb usuario1                # Exclui com backup do home"
    echo "  $0 -f -r usuario1              # Força exclusão com remoção do home"
    echo "  $0 -F usuarios.txt             # Lê usuários de arquivo"
    echo "  $0 -d -r usuario1              # Dry run (teste)"
    echo ""
    echo -e "${CYAN}Formato do arquivo (uma linha por usuário):${NC}"
    echo "  usuario1"
    echo "  usuario2"
    echo "  usuario3"
}

# Função para log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}
 
log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# Função para verificar se usuário existe
user_exists() {
    id "$1" &>/dev/null
}

# Função para verificar se usuário está logado
user_logged_in() {
    local username="$1"
    who | grep -q "^$username "
}

# Função para verificar se usuário é protegido
is_protected_user() {
    local username="$1"
    for protected in "${PROTECTED_USERS[@]}"; do
        if [[ "$username" == "$protected" ]]; then
            return 0
        fi
    done
    return 1
}

# Função para obter informações do usuário
get_user_info() {
    local username="$1"
    local uid=$(id -u "$username" 2>/dev/null)
    local home=$(getent passwd "$username" | cut -d: -f6)
    local shell=$(getent passwd "$username" | cut -d: -f7)
    local groups=$(groups "$username" 2>/dev/null | cut -d: -f2)
    
    echo "  UID: $uid"
    echo "  Home: $home"
    echo "  Shell: $shell"
    echo "  Grupos:$groups"
}

# Função para fazer backup do diretório home
backup_home_directory() {
    local username="$1"
    local home_dir=$(getent passwd "$username" | cut -d: -f6)
    
    if [[ ! -d "$home_dir" ]]; then
        log_warning "Diretório home '$home_dir' não encontrado para $username"
        return 1
    fi
    
    local backup_dir="/root/user_backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${username}_${timestamp}.tar.gz"
    
    # Cria diretório de backup se não existir
    mkdir -p "$backup_dir"
    
    log_info "Fazendo backup de $home_dir para $backup_file"
    
    if tar -czf "$backup_file" -C "$(dirname "$home_dir")" "$(basename "$home_dir")" 2>/dev/null; then
        log_success "Backup criado: $backup_file"
        return 0
    else
        log_error "Falha ao criar backup de $home_dir"
        return 1
    fi
}

# Função para excluir usuário
delete_user() {
    local username="$1"
    local options=""
    
    # Validações
    if [[ -z "$username" ]]; then
        log_error "Nome de usuário vazio"
        return 1
    fi
    
    if ! user_exists "$username"; then
        log_error "Usuário '$username' não existe"
        return 1
    fi
    
    if is_protected_user "$username"; then
        log_error "Usuário '$username' é protegido do sistema e não pode ser excluído"
        return 1
    fi
    
    # Mostra informações do usuário
    log_info "Informações do usuário '$username':"
    get_user_info "$username"
    
    # Verifica se está logado
    if user_logged_in "$username"; then
        log_warning "Usuário '$username' está atualmente logado"
        if [[ "$FORCE_DELETE" == "false" ]]; then
            log_error "Use -f para forçar a exclusão de usuário logado"
            return 1
        fi
    fi
    
    # Confirmação interativa
    if [[ "$INTERACTIVE" == "true" && "$DRY_RUN" == "false" ]]; then
        echo ""
        echo -e "${YELLOW}Confirma a exclusão do usuário '$username'?${NC}"
        if [[ "$REMOVE_HOME" == "true" ]]; then
            echo -e "${RED}ATENÇÃO: O diretório home será REMOVIDO!${NC}"
        fi
        read -p "Digite 'sim' para confirmar: " confirm
        if [[ "$confirm" != "sim" ]]; then
            log_info "Exclusão cancelada pelo usuário"
            return 1
        fi
    fi
    
    # Backup do home se solicitado
    if [[ "$BACKUP_HOME" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Faria backup do diretório home de '$username'"
        else
            backup_home_directory "$username"
        fi
    fi
    
    # Prepara opções do userdel
    if [[ "$REMOVE_HOME" == "true" ]]; then
        options="$options -r"
    fi
    
    if [[ "$FORCE_DELETE" == "true" ]]; then
        options="$options -f"
    fi
    
    # Executa a exclusão
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Executaria: userdel$options $username"
        return 0
    fi
    
    log_info "Excluindo usuário '$username'..."
    
    if userdel $options "$username" 2>/dev/null; then
        log_success "Usuário '$username' excluído com sucesso"
        
        # Remove arquivos de mail se existirem
        local mail_file="/var/spool/mail/$username"
        if [[ -f "$mail_file" ]]; then
            rm -f "$mail_file"
            log_info "Arquivo de mail removido: $mail_file"
        fi
        
        # Remove arquivos cron se existirem
        local cron_file="/var/spool/cron/$username"
        if [[ -f "$cron_file" ]]; then
            rm -f "$cron_file"
            log_info "Arquivo cron removido: $cron_file"
        fi
        
        return 0
    else
        log_error "Falha ao excluir usuário '$username'"
        return 1
    fi
}

# Função para processar lista de usuários
process_users() {
    local users=("$@")
    local total=${#users[@]}
    local success=0
    local failed=0
    local skipped=0
    
    log_info "Processando $total usuário(s)..."
    echo ""
    
    for username in "${users[@]}"; do
        # Remove espaços em branco
        username=$(echo "$username" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Pula linhas vazias
        if [[ -z "$username" ]]; then
            continue
        fi
        
        echo -e "${CYAN}=== Processando: $username ===${NC}"
        
        if delete_user "$username"; then
            ((success++))
        else
            if user_exists "$username"; then
                ((failed++))
            else
                ((skipped++))
            fi
        fi
        echo ""
    done
    
    # Resumo final
    echo -e "${BLUE}=== RESUMO FINAL ===${NC}"
    log_success "Usuários excluídos: $success"
    log_error "Falhas: $failed"
    log_warning "Ignorados: $skipped"
    log_info "Total processado: $total"
}

# Função principal
main() {
    local users=()
    local file_path=""
    
    # Parse dos argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--remove-home)
                REMOVE_HOME=true
                shift
                ;;
            -f|--force)
                FORCE_DELETE=true
                shift
                ;;
            -b|--backup)
                BACKUP_HOME=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -y|--yes)
                INTERACTIVE=false
                shift
                ;;
            -F|--file)
                FROM_FILE=true
                file_path="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
            *)
                users+=("$1")
                shift
                ;;
        esac
    done
    
    # Verifica se está executando como root
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado como root (use sudo)"
        exit 1
    fi
    
    # Processamento de arquivo
    if [[ "$FROM_FILE" == "true" ]]; then
        if [[ -z "$file_path" ]]; then
            log_error "Caminho do arquivo não especificado"
            show_help
            exit 1
        fi
        
        if [[ ! -f "$file_path" ]]; then
            log_error "Arquivo '$file_path' não encontrado"
            exit 1
        fi
        
        log_info "Lendo usuários do arquivo: $file_path"
        
        # Lê usuários do arquivo
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Pula comentários e linhas vazias
            if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            users+=("$line")
        done < "$file_path"
    fi
    
    # Verifica se há usuários para processar
    if [[ ${#users[@]} -eq 0 ]]; then
        log_error "Nenhum usuário especificado"
        show_help
        exit 1
    fi
    
    # Mostra configurações
    echo -e "${BLUE}=== CONFIGURAÇÕES ===${NC}"
    echo "Remover home: $([ "$REMOVE_HOME" = true ] && echo "SIM" || echo "NÃO")"
    echo "Forçar exclusão: $([ "$FORCE_DELETE" = true ] && echo "SIM" || echo "NÃO")"
    echo "Backup home: $([ "$BACKUP_HOME" = true ] && echo "SIM" || echo "NÃO")"
    echo "Modo teste: $([ "$DRY_RUN" = true ] && echo "SIM" || echo "NÃO")"
    echo "Modo interativo: $([ "$INTERACTIVE" = true ] && echo "SIM" || echo "NÃO")"
    echo ""
    
    # Processa os usuários
    process_users "${users[@]}"
}

# Executa a função principal
main "$@"