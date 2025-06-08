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
| `create_users_gid.sh` | Cria usuários com GID 10000 e grupo 'sas' nos diretórios |
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
sudo ./create_users_gid.sh "user1;user2;user3"

# Com senha padrão
sudo ./create_users_gid.sh -p "MinhaSenh@123" "user1;user2;user3"

# Teste sem criar (dry-run)
sudo ./create_users_gid.sh -d "user1;user2;user3"
```

#### Via arquivo:
```bash
# Criar arquivo de usuários
echo "user1;user2;user3" > users.txt

# Executar
sudo ./create_users_gid.sh -f users.txt -p "MinhaSenh@123"
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
- **Permissões home**: 750

### Validações:
- ✅ Nomes de usuário válidos (a-z, 0-9, _, -)
- ✅ Máximo 32 caracteres
- ✅ Senha mínima de 4 caracteres
- ✅ Verificação de usuários existentes
- ✅ Proteção contra usuários do sistema

## 🎯 Exemplos Completos

### Exemplo 1: Criar usuários corporativos
```bash
# Criar arquivo
cat > funcionarios.txt << EOF
sas_joao;sas_maria;sas_pedro
sas_ana
sas_carlos;sas_lucia
EOF

# Executar
sudo ./create_users_gid.sh -f funcionarios.txt -p "Empresa@2025" -v

# Verificar
sudo ./verify_users.sh
```

### Exemplo 2: Gerenciamento completo
```bash
# 1. Teste primeiro
sudo ./create_users_gid.sh -d "teste1;teste2;teste3"

# 2. Criar usuários
sudo ./create_users_gid.sh "user1;user2;user3" -p "MinhaSenh@123"

# 3. Verificar
sudo ./verify_users.sh user1 user2 user3

# 4. Excluir se necessário
sudo ./delete_users.sh -rb user1 user2 user3
```

## 📋 Opções dos Scripts

### create_users_gid.sh
```
-f, --file           Lê usuários de arquivo
-p, --password       Define senha padrão
-s, --shell          Define shell personalizado
-d, --dry-run        Teste sem executar
-v, --verbose        Modo verboso
-h, --help           Ajuda
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

- **Sistema**: RHEL/CentOS/Fedora/Ubuntu/Debian
- **Permissões**: Executar como root (sudo)
- **Grupos**: Grupo 'sas' deve existir ou ser criado

### Criar grupo SAS:
```bash
sudo groupadd sas
```

## 🔍 Solução de Problemas

### Erro "Grupo 'sas' não existe":
```bash
sudo groupadd sas
```

### Verificar configuração atual:
```bash
# Ver grupos existentes
getent group | grep -E "(10000|sas)"

# Ver usuários com GID 10000
getent passwd | awk -F: '$4==10000 {print $1, $3, $4, $6}'

# Verificar diretórios
ls -la /home/ | grep sas
```

### Logs e debug:
```bash
# Usar modo verboso
sudo ./create_users_gid.sh -v -d "user1;user2"

# Verificar logs do sistema
sudo tail -f /var/log/messages
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

- ✅ **Seguro**: Validações completas e proteções
- ✅ **Flexível**: Múltiplos formatos de entrada
- ✅ **Informativo**: Logs coloridos e detalhados
- ✅ **Testável**: Modo dry-run em todos os scripts
- ✅ **Robusto**: Tratamento de erros e casos extremos