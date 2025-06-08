#!/bin/bash

# Script para criar usuários com configurações específicas:
# - Grupo principal GID 10000
# - Diretório home pertencente ao grupo 'sas'
# - Lista de usuários separados por ';'

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações 
PRIMARY_GID=10000
PRIMARY_GROUP_NAME="GROUP"
HOME_GROUP="GROUP"
HOME_BASE="/home"
DEFAULT_SHELL="/bin/bash"

# Função para exibir ajuda
show_help() {
    echo -e "${BLUE}=== Script para Criar Usuários com GID 10000 ===${NC}"
    echo ""
    echo -e "${CYAN}Uso:${NC}"
    echo "  $0 [opções] \"usuario1;usuario2;usuario3\""
    echo "  $0 [opções] -f arquivo.txt"
    echo ""
    echo -e "${CYAN}Opções:${NC}"
    echo "  -f, --file           Lê lista de usuários de arquivo"
    echo "  -p, --password       Define senha padrão para todos os usuários"
    echo "  -s, --shell          Define shell personalizado (padrão: /bin/bash)"
    echo "  -d, --dry-run        Executa sem criar usuários (apenas mostra o que seria feito)"
    echo "  -v, --verbose        Modo verboso (mais informações)"
    echo "  -h, --help           Exibe esta ajuda"
    echo ""
    echo -e "${CYAN}Configurações fixas:${NC}"
    echo "  • Grupo principal: $PRIMARY_GROUP_NAME (GID: $PRIMARY_GID)"
    echo "  • Grupo do diretório home: $HOME_GROUP"
    echo "  • Base dos diretórios: $HOME_BASE"
    echo ""
    echo -e "${CYAN}Exemplos:${NC}"
    echo "  $0 \"joao;maria;pedro\""
    echo "  $0 -f usuarios.txt"
    echo "  $0 -p \"senha123\" \"usuario1;usuario2\""
    echo "  $0 -d \"teste1;teste2\"                # Dry run"
    echo ""
    echo -e "${CYAN}Formato do arquivo (separado por ; ou uma linha por usuário):${NC}"
    echo "  usuario1;usuario2;usuario3"
    echo "  ou"
    echo "  usuario1"
    echo "  usuario2" 
    echo "  usuario3"
}

# Função para log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1" >&2
    fi
}

# Função para verificar se grupo existe
group_exists() {
    getent group "$1" >/dev/null 2>&1
}

# Função para verificar se usuário existe
user_exists() {
    id "$1" >/dev/null 2>&1
}

# Função para validar nome de usuário
validate_username() {
    local username="$1"
    
    # Verifica se o nome está vazio
    if [[ -z "$username" ]]; then
        return 1
    fi
    
    # Verifica se o nome contém apenas caracteres válidos
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        return 1
    fi
    
    # Verifica se o nome não é muito longo (máximo 32 caracteres)
    if [[ ${#username} -gt 32 ]]; then
        return 1
    fi
    
    return 0
}

# Função para criar grupo se não existir
ensure_group_exists() {
    local group_name="$1"
    local gid="$2"
    
    if group_exists "$group_name"; then
        local existing_gid=$(getent group "$group_name" | cut -d: -f3)
        if [[ -n "$gid" && "$existing_gid" != "$gid" ]]; then
            log_warning "Grupo '$group_name' existe mas com GID $existing_gid (esperado: $gid)"
        else
            log_verbose "Grupo '$group_name' já existe"
        fi
        return 0
    fi
    
    log_info "Criando grupo '$group_name'$([ -n "$gid" ] && echo " com GID $gid")"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Criaria grupo: $group_name$([ -n "$gid" ] && echo " (GID: $gid)")"
        return 0
    fi
    
    local cmd="groupadd"
    if [[ -n "$gid" ]]; then
        cmd="$cmd -g $gid"
    fi
    cmd="$cmd $group_name"
    
    if eval "$cmd" 2>/dev/null; then
        log_success "Grupo '$group_name' criado com sucesso"
        return 0
    else
        log_error "Falha ao criar grupo '$group_name'"
        return 1
    fi
}

# Função para criar usuário
create_user() {
    local username="$1"
    local password="$2"
    
    # Validações
    if ! validate_username "$username"; then
        log_error "Nome de usuário inválido: '$username'. Use apenas letras minúsculas, números, _ e -"
        return 1
    fi
    
    if user_exists "$username"; then
        log_warning "Usuário '$username' já existe, pulando..."
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Criaria usuário: $username"
        log_verbose "[DRY RUN] - GID primário: $PRIMARY_GID"
        log_verbose "[DRY RUN] - Home: $HOME_BASE/$username"
        log_verbose "[DRY RUN] - Grupo do home: $HOME_GROUP"
        return 0
    fi
    
    log_info "Criando usuário '$username'..."
    
    # Criar o usuário com grupo primário específico
    local cmd="useradd"
    cmd="$cmd -g $PRIMARY_GID"                    # Grupo primário
    cmd="$cmd -d $HOME_BASE/$username"            # Diretório home
    cmd="$cmd -m"                                 # Criar diretório home
    cmd="$cmd -s $DEFAULT_SHELL"                  # Shell padrão
    cmd="$cmd $username"
    
    log_verbose "Executando: $cmd"
    
    if eval "$cmd" 2>/dev/null; then
        log_success "Usuário '$username' criado com sucesso"
        
        # Verificar se o diretório home foi criado
        local home_dir="$HOME_BASE/$username"
        if [[ -d "$home_dir" ]]; then
            log_verbose "Diretório home criado: $home_dir"
            
            # Alterar grupo do diretório home para 'sas'
            log_info "Alterando grupo do diretório $home_dir para '$HOME_GROUP'"
            if chgrp "$HOME_GROUP" "$home_dir" 2>/dev/null; then
                log_success "Grupo do diretório alterado para '$HOME_GROUP'"
                
                # Verificar permissões e ajustar se necessário
                chmod 700 "$home_dir" 2>/dev/null
                log_verbose "Permissões do diretório ajustadas para 750"
            else
                log_error "Falha ao alterar grupo do diretório para '$HOME_GROUP'"
                log_warning "Verifique se o grupo '$HOME_GROUP' existe"
            fi
        else
            log_error "Diretório home não foi criado: $home_dir"
        fi
        
        # Definir senha se fornecida
        if [[ -n "$password" ]]; then
            log_info "Definindo senha para usuário '$username'"
            if echo "$username:$password" | chpasswd 2>/dev/null; then
                log_success "Senha definida para usuário '$username'"
            else
                log_error "Erro ao definir senha para usuário '$username'"
            fi
        fi
        
        # Mostrar informações do usuário criado
        if [[ "$VERBOSE" == "true" ]]; then
            log_verbose "Informações do usuário '$username':"
            local user_info=$(getent passwd "$username")
            log_verbose "  Entrada passwd: $user_info"
            local uid=$(echo "$user_info" | cut -d: -f3)
            local gid=$(echo "$user_info" | cut -d: -f4)
            log_verbose "  UID: $uid, GID: $gid"
            
            # Verificar grupo do diretório
            if [[ -d "$home_dir" ]]; then
                local dir_info=$(ls -ld "$home_dir")
                log_verbose "  Diretório: $dir_info"
            fi
        fi
        
        return 0
    else
        log_error "Erro ao criar usuário '$username'"
        return 1
    fi
}

# Função para processar lista de usuários
process_users() {
    local user_list="$1"
    local password="$2"
    
    # Debug: mostrar a string recebida
    log_verbose "Lista de usuários recebida: '$user_list'"
    
    # Converter string em array, preservando IFS original
    local OLD_IFS="$IFS"
    IFS=';'
    read -ra USERS <<< "$user_list"
    IFS="$OLD_IFS"
    
    # Debug: mostrar array criado
    log_verbose "Array de usuários: ${USERS[*]}"
    log_verbose "Número de usuários detectados: ${#USERS[@]}"
    
    local total=${#USERS[@]}
    local created=0
    local failed=0
    local skipped=0
    
    # Verificar se há usuários para processar
    if [[ $total -eq 0 ]]; then
        log_error "Nenhum usuário encontrado na lista"
        return 1
    fi
    
    log_info "Processando $total usuário(s)..."
    echo ""
    
    local index=1
    for username in "${USERS[@]}"; do
        # Remove espaços em branco
        username=$(echo "$username" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Pula entradas vazias
        if [[ -z "$username" ]]; then
            log_verbose "Entrada vazia encontrada, pulando..."
            continue
        fi
        
        echo -e "${CYAN}=== Processando ($index/$total): $username ===${NC}"
        
        if create_user "$username" "$password"; then
            ((created++))
        else
            if user_exists "$username"; then
                ((skipped++))
            else
                ((failed++))
            fi
        fi
        ((index++))
        echo ""
    done
    
    # Resumo final
    echo -e "${BLUE}=== RESUMO FINAL ===${NC}"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Usuários que seriam criados: $created"
    else
        log_success "Usuários criados: $created"
    fi
    log_warning "Usuários já existentes (pulados): $skipped"
    log_error "Usuários com erro: $failed"
    log_info "Total processado: $total"
}

# Função para ler usuários de arquivo
read_users_from_file() {
    local file_path="$1"
    local users_array=()
    
    log_info "Lendo usuários do arquivo: $file_path"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Remove espaços e pula comentários/linhas vazias
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
            continue
        fi
        
        log_verbose "Linha lida: '$line'"
        
        # Se a linha contém ';', processa como lista separada
        if [[ "$line" == *";"* ]]; then
            # Separar por ';' e adicionar cada usuário
            local OLD_IFS="$IFS"
            IFS=';'
            read -ra LINE_USERS <<< "$line"
            IFS="$OLD_IFS"
            
            for user in "${LINE_USERS[@]}"; do
                user=$(echo "$user" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [[ -n "$user" ]]; then
                    users_array+=("$user")
                    log_verbose "Usuário adicionado: '$user'"
                fi
            done
        else
            # Linha única, adiciona à lista
            if [[ -n "$line" ]]; then
                users_array+=("$line")
                log_verbose "Usuário adicionado: '$line'"
            fi
        fi
    done < "$file_path"
    
    # Converter array em string separada por ';'
    local users_string=""
    for user in "${users_array[@]}"; do
        if [[ -z "$users_string" ]]; then
            users_string="$user"
        else
            users_string="$users_string;$user"
        fi
    done
    
    log_verbose "String final de usuários: '$users_string'"
    log_verbose "Total de usuários lidos do arquivo: ${#users_array[@]}"
    
    echo "$users_string"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências do sistema..."
    
    # Verificar se está executando como root
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado como root (use sudo)"
        exit 1
    fi
    
    # Verificar comandos necessários
    local commands=("useradd" "groupadd" "chgrp" "chmod" "chpasswd" "getent")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Comando '$cmd' não encontrado"
            exit 1
        fi
    done
    
    log_verbose "Todas as dependências verificadas"
}

# Função para configurar grupos necessários
setup_groups() {
    log_info "Configurando grupos necessários..."
    
    # Criar grupo primário com GID específico
    if ! ensure_group_exists "$PRIMARY_GROUP_NAME" "$PRIMARY_GID"; then
        log_error "Falha ao configurar grupo primário"
        exit 1
    fi
    
    # Verificar se grupo 'sas' existe
    if ! group_exists "$HOME_GROUP"; then
        log_warning "Grupo '$HOME_GROUP' não existe"
        read -p "Deseja criar o grupo '$HOME_GROUP'? (s/N): " create_sas
        if [[ "$create_sas" =~ ^[Ss]$ ]]; then
            if ! ensure_group_exists "$HOME_GROUP"; then
                log_error "Falha ao criar grupo '$HOME_GROUP'"
                exit 1
            fi
        else
            log_error "Grupo '$HOME_GROUP' é necessário para definir propriedade dos diretórios home"
            exit 1
        fi
    else
        log_verbose "Grupo '$HOME_GROUP' já existe"
    fi
}

# Função principal
main() {
    local user_list=""
    local file_path=""
    local password=""
    local from_file=false
    
    # Variáveis globais
    DRY_RUN=false
    VERBOSE=false
    
    # Parse dos argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                from_file=true
                file_path="$2"
                shift 2
                ;;
            -p|--password)
                password="$2"
                shift 2
                ;;
            -s|--shell)
                DEFAULT_SHELL="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
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
                if [[ -z "$user_list" ]]; then
                    user_list="$1"
                else
                    log_error "Muitos argumentos"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Verificar dependências
    check_dependencies
    
    # Ler usuários de arquivo se especificado
    if [[ "$from_file" == "true" ]]; then
        if [[ -z "$file_path" ]]; then
            log_error "Caminho do arquivo não especificado"
            show_help
            exit 1
        fi
        
        if [[ ! -f "$file_path" ]]; then
            log_error "Arquivo '$file_path' não encontrado"
            exit 1
        fi
        
        user_list=$(read_users_from_file "$file_path")
    fi
    
    # Verificar se há usuários para processar
    if [[ -z "$user_list" ]]; then
        log_error "Nenhum usuário especificado"
        show_help
        exit 1
    fi
    
    # Mostrar configurações
    echo -e "${BLUE}=== CONFIGURAÇÕES ===${NC}"
    echo "Grupo primário: $PRIMARY_GROUP_NAME (GID: $PRIMARY_GID)"
    echo "Grupo do diretório home: $HOME_GROUP"
    echo "Base dos diretórios: $HOME_BASE"
    echo "Shell padrão: $DEFAULT_SHELL"
    echo "Senha padrão: $([ -n "$password" ] && echo "DEFINIDA" || echo "NÃO DEFINIDA")"
    echo "Modo teste: $([ "$DRY_RUN" = true ] && echo "SIM" || echo "NÃO")"
    echo "Modo verboso: $([ "$VERBOSE" = true ] && echo "SIM" || echo "NÃO")"
    echo ""
    
    # Configurar grupos necessários
    if [[ "$DRY_RUN" == "false" ]]; then
        setup_groups
        echo ""
    fi
    
    # Processar usuários
    log_info "Lista final de usuários para processar: '$user_list'"
    
    # Verificar se há pelo menos um usuário válido
    local OLD_IFS="$IFS"
    IFS=';'
    read -ra TEST_USERS <<< "$user_list"
    IFS="$OLD_IFS"
    
    local valid_users=0
    for test_user in "${TEST_USERS[@]}"; do
        test_user=$(echo "$test_user" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -n "$test_user" ]]; then
            ((valid_users++))
        fi
    done
    
    if [[ $valid_users -eq 0 ]]; then
        log_error "Nenhum usuário válido encontrado na lista"
        exit 1
    fi
    
    log_info "Usuários válidos detectados: $valid_users"
    
    process_users "$user_list" "$password"
}

# Executar função principal
main "$@"