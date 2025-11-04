# Linux User Management Scripts

Scripts para gerenciamento de usuários Linux com configurações específicas para ambientes corporativos.

## 📋 Funcionalidades 

- **Criar usuários** com GID primário 10000 e diretórios home pertencentes ao grupo 'sas'
- **Excluir usuários** com opções de backup e verificações de segurança
- **Verificar usuários** criados e suas configurações
- **Processamento em lote** via arquivo ou linha de comando
- **Modo dry-run** para testes
- **Logs coloridos** e informativos

## 🚀 Scripts Incluídos

| Script | Descrição |
|--------|-----------|
| `create_users.sh` | Cria usuários com GID 10000 e grupo 'sas' nos diretórios |
| `delete_users.sh` | Exclui usuários com opções avançadas |
| `verify_users.sh` | Verifica configurações dos usuários criados |

## 📦 Instalação

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/linux-user-management.git
cd linux-user-management

# Dar permissões de execução
chmod +x *.sh
```

## 🔧 Uso

### Criar Usuários

#### Via linha de comando:
```bash
# Criar usuários separados por ';'
sudo ./create_users.sh "user1;user2;user3"

# Com senha segura (solicita interativamente - mais seguro)
sudo ./create_users.sh -P "user1;user2;user3"

# Com senha via parâmetro (menos seguro, aparece no histórico)
sudo ./create_users.sh -p "MinhaSenh@123!" "user1;user2;user3"

# Forçar troca de senha no primeiro login
sudo ./create_users.sh -P -c "user1;user2;user3"

# Com descrição do usuário (GECOS)
sudo ./create_users.sh -g "João Silva" -P "joao"

# Com grupos secundários
sudo ./create_users.sh -G "docker,sudo" -P "user1"

# Teste sem criar (dry-run - mostra comandos exatos)
sudo ./create_users.sh -d "user1;user2;user3"
```

#### Via arquivo:
```bash
# Criar arquivo de usuários
echo "user1;user2;user3" > users.txt

# Executar com senha segura
sudo ./create_users.sh -f users.txt -P

# Com todas as opções
sudo ./create_users.sh -f users.txt -P -c -g "Funcionário SAS" -G "sas,docker" -v
```

### Verificar Usuários

```bash
# Verificar usuários específicos
sudo ./verify_users.sh user1 user2 user3

# Verificar todos os usuários com GID 10000
sudo ./verify_users.sh
```

### Excluir Usuários

```bash
# Excluir usuário mantendo home
sudo ./delete_users.sh user1

# Excluir com remoção do home
sudo ./delete_users.sh -r user1

# Excluir com backup do home
sudo ./delete_users.sh -rb user1

# Excluir múltiplos usuários
sudo ./delete_users.sh -r user1 user2 user3

# Excluir de arquivo
sudo ./delete_users.sh -F users_to_delete.txt -r
```

## 📝 Formato dos Arquivos

### Arquivo de usuários (users.txt):
```
# Comentários são ignorados
user1;user2;user3
user4
user5;user6
```

### Arquivo para exclusão:
```
# Um usuário por linha
user1
user2
user3
```

## ⚙️ Configurações

### Script de Criação:
- **Grupo primário**: GID 10000 (grupo 'users10000')
- **Grupo do diretório home**: 'sas'
- **Diretórios base**: /home/
- **Shell padrão**: /bin/bash
- **Permissões home**: 700
- **Log de operações**: /var/log/user_management.log

### Validações e Segurança:
- ✅ Nomes de usuário válidos (a-z, 0-9, _, -)
- ✅ Máximo 32 caracteres
- ✅ **Validação de complexidade de senha**:
  - Mínimo 8 caracteres
  - Pelo menos 1 letra maiúscula
  - Pelo menos 1 letra minúscula
  - Pelo menos 1 número
  - Pelo menos 1 caractere especial
- ✅ Verificação de usuários existentes
- ✅ Proteção contra usuários do sistema
- ✅ Verificação de espaço em disco (mínimo 100MB)
- ✅ Verificação de UID disponível
- ✅ Validação de sintaxe de arquivo antes de processar
- ✅ Tratamento de sinais (Ctrl+C) para limpeza adequada
- ✅ Logging de todas as operações em arquivo

### Segurança de Senhas:
- 🔒 **Recomendado**: Use `-P` para inserir senha de forma interativa (não aparece no histórico)
- ⚠️ **Não recomendado**: Usar `-p` (senha aparece no histórico do shell e em `ps`)
- 🔐 Opção de forçar troca de senha no primeiro login (`-c`)

### Script de Exclusão - Verificações Adicionais:
- ✅ Verificação de processos em execução do usuário
- ✅ Verificação de espaço em disco antes de backup
- ✅ Verificação de integridade do backup após criação
- ✅ Proteção contra exclusão de usuários do sistema

## 🎯 Exemplos Completos

### Exemplo 1: Criar usuários corporativos (modo seguro)
```bash
# Criar arquivo
cat > funcionarios.txt << EOF
sas_joao;sas_maria;sas_pedro
sas_ana
sas_carlos;sas_lucia
EOF

# Executar com senha segura e forçar troca no primeiro login
sudo ./create_users.sh -f funcionarios.txt -P -c -v

# Verificar
sudo ./verify_users.sh

# Ver logs
sudo tail -f /var/log/user_management.log
```

### Exemplo 2: Criar usuário com todas as opções
```bash
# Criar usuário completo
sudo ./create_users.sh \
  -g "João Silva - Desenvolvedor" \
  -G "docker,sudo,developers" \
  -P \
  -c \
  -v \
  "joao_silva"
```

### Exemplo 3: Gerenciamento completo
```bash
# 1. Teste primeiro (dry-run)
sudo ./create_users.sh -d "teste1;teste2;teste3"

# 2. Criar usuários com senha segura
sudo ./create_users.sh "user1;user2;user3" -P -c

# 3. Verificar
sudo ./verify_users.sh user1 user2 user3

# 4. Excluir se necessário (com backup)
sudo ./delete_users.sh -rb user1 user2 user3
```

## 📋 Opções dos Scripts

### create_users.sh
```
-f, --file             Lê usuários de arquivo
-p, --password         Define senha padrão (menos seguro - aparece no histórico)
-P, --prompt-password  Solicita senha de forma segura (recomendado)
-s, --shell            Define shell personalizado
-g, --gecos            Define descrição/GECOS do usuário
-G, --groups           Grupos secundários (separados por vírgula)
-c, --change-password  Força troca de senha no primeiro login
-d, --dry-run          Teste sem executar (mostra comandos exatos)
-v, --verbose          Modo verboso
-h, --help             Ajuda
```

### delete_users.sh
```
-r, --remove-home    Remove diretório home
-f, --force          Força exclusão (usuário logado)
-b, --backup         Backup do home antes de excluir
-d, --dry-run        Teste sem executar
-y, --yes            Não pede confirmação
-F, --file           Lê usuários de arquivo
-h, --help           Ajuda
```

### verify_users.sh
```
verify_users.sh [user1] [user2] ...
# Sem argumentos: verifica todos com GID 10000
```

## ⚠️ Pré-requisitos

### Sistema Operacional:
- **Sistemas suportados**: RHEL/CentOS/Fedora/Ubuntu/Debian
- **Versão mínima do Bash**: 4.0+
- **Permissões**: Executar como root (sudo)

### Dependências do Sistema:
Os seguintes comandos devem estar disponíveis:
- `useradd`, `userdel`, `usermod`
- `groupadd`, `getent`
- `chgrp`, `chmod`, `chage`, `chpasswd`
- `ps`, `who`, `df`, `du`, `tar`

### Grupos Necessários:
- Grupo 'sas' deve existir ou ser criado
- Grupo 'users10000' (GID 10000) será criado automaticamente

#### Criar grupo SAS:
```bash
sudo groupadd sas
```

### Permissões de Arquivo:
- Log file: `/var/log/user_management.log` (será criado automaticamente)
- Backups: `/root/user_backups/` (será criado automaticamente)

### Espaço em Disco:
- Mínimo 100MB livre em `/home` para cada usuário
- Espaço adicional para backups (se usar opção `-b`)

## 🔍 Solução de Problemas

### Erro "Grupo 'sas' não existe":
```bash
sudo groupadd sas
```

### Erro "Senha não atende aos requisitos":
A senha deve ter:
- Mínimo 8 caracteres
- 1 letra maiúscula, 1 minúscula, 1 número, 1 caractere especial
- Exemplo válido: `Senh@Forte123`

### Erro "Espaço em disco insuficiente":
```bash
# Verificar espaço disponível
df -h /home

# Limpar espaço se necessário
sudo apt clean  # Ubuntu/Debian
sudo dnf clean all  # RHEL/Fedora
```

### Erro "Usuário tem processos em execução":
```bash
# Ver processos do usuário
ps -u username

# Finalizar processos (use com cuidado)
sudo pkill -u username

# Ou forçar exclusão
sudo ./delete_users.sh -f -r username
```

### Verificar configuração atual:
```bash
# Ver grupos existentes
getent group | grep -E "(10000|sas)"

# Ver usuários com GID 10000
getent passwd | awk -F: '$4==10000 {print $1, $3, $4, $6}'

# Verificar diretórios
ls -la /home/ | grep sas

# Ver logs de operações
sudo tail -50 /var/log/user_management.log

# Ver logs do sistema
sudo journalctl -xe | grep -i user
```

### Debug e modo verboso:
```bash
# Usar modo verboso para mais detalhes
sudo ./create_users.sh -v -d "user1;user2"

# Verificar sintaxe de arquivo
sudo ./create_users.sh -d -f users.txt

# Ver o que seria executado (dry-run)
sudo ./delete_users.sh -d -r username
```

### Backup corrompido ou espaço insuficiente:
```bash
# Verificar integridade de backup
tar -tzf /root/user_backups/username_*.tar.gz

# Limpar backups antigos
sudo find /root/user_backups -mtime +30 -delete

# Verificar espaço disponível
df -h /root
```

## 📄 Estrutura dos Arquivos Criados

Após a execução, cada usuário terá:
```
/etc/passwd: usuario:x:UID:10000::/home/usuario:/bin/bash
/home/usuario/  (grupo: sas, permissões: 750)
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie sua feature branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para detalhes.

## ✨ Recursos

- ✅ **Seguro**: Validações completas, verificação de processos e proteções de sistema
- ✅ **Senhas fortes**: Validação de complexidade com requisitos configuráveis
- ✅ **Flexível**: Múltiplos formatos de entrada e opções avançadas
- ✅ **Informativo**: Logs coloridos, detalhados e persistentes em arquivo
- ✅ **Testável**: Modo dry-run mostra comandos exatos antes de executar
- ✅ **Robusto**: Tratamento de sinais, erros e casos extremos
- ✅ **Auditável**: Logging completo de todas as operações
- ✅ **Confiável**: Verificação de integridade de backups e espaço em disco

## 🆕 Melhorias Implementadas (v2.0)

### Segurança:
- ✨ Opção de senha segura via prompt interativo (`-P`)
- ✨ Validação de complexidade de senha (8+ chars, maiúsc/minúsc/num/especial)
- ✨ Opção de forçar troca de senha no primeiro login (`-c`)
- ✨ Verificação de processos em execução antes de excluir
- ✨ Proteção adicional contra exclusão de usuários do sistema

### Validações:
- ✨ Verificação de espaço em disco antes de criar usuário
- ✨ Verificação de espaço em disco antes de backup
- ✨ Validação de sintaxe de arquivo de entrada
- ✨ Verificação de UID disponível
- ✨ Verificação de integridade de backup após criação

### Funcionalidades:
- ✨ Suporte para GECOS (descrição do usuário) via `-g`
- ✨ Suporte para grupos secundários via `-G`
- ✨ Logging persistente em arquivo (`/var/log/user_management.log`)
- ✨ Modo dry-run melhorado mostra comandos exatos
- ✨ Tratamento de sinais (SIGINT/SIGTERM) para limpeza adequada

### Código:
- ✨ Variáveis de configuração como `readonly`
- ✨ Funções compartilhadas para melhor manutenção
- ✨ Mensagens de erro mais claras e informativas
- ✨ Correção de bugs (PRIMARY_GROUP_NAME, permissões, etc)