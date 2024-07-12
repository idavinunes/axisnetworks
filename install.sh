#!/bin/bash

# Função para verificar a existência do Docker e Docker Compose, e instalar se necessário
check_and_install_docker() {
    if ! command -v docker &> /dev/null
    then
        echo "Docker não está instalado. Instalando Docker..."
        # Comando para instalar o Docker (ajuste conforme a distribuição)
        sudo apt-get update
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
    fi

    if ! command -v docker-compose &> /dev/null
    then
        echo "Docker Compose não está instalado. Instalando Docker Compose..."
        # Comando para instalar o Docker Compose (ajuste conforme a distribuição)
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

# Função para sanitizar o nome do projeto
sanitize_project_name() {
    local project_name=$1
    sanitized_name=$(echo "$project_name" | tr -cs '[:alnum:]-_' '_')
    echo "$sanitized_name"
}

# Função para solicitar ou manter o valor padrão de uma variável de ambiente
ask_env_variable() {
    local var_name=$1
    local default_value=$2
    read -p "Defina o valor para $var_name [$default_value]: " input_value
    if [ -z "$input_value" ]; then
        echo "$default_value"
    else
        echo "$input_value"
    fi
}

# Solicitar o nome do projeto ao usuário
read -p "Informe o nome do projeto: " PROJECT_NAME

# Sanitizar o nome do projeto
SANITIZED_PROJECT_NAME=$(sanitize_project_name "$PROJECT_NAME")

# Criar uma pasta com o nome do projeto
mkdir -p "$SANITIZED_PROJECT_NAME"

# Entrar na pasta do projeto
cd "$SANITIZED_PROJECT_NAME"

# Definir e solicitar as variáveis de ambiente
INSTALLATION_NAME=$(ask_env_variable "INSTALLATION_NAME" "chatwoot")
NODE_ENV=$(ask_env_variable "NODE_ENV" "production")
RAILS_ENV=$(ask_env_variable "RAILS_ENV" "production")
INSTALLATION_ENV=$(ask_env_variable "INSTALLATION_ENV" "docker")
SECRET_KEY_BASE=$(ask_env_variable "SECRET_KEY_BASE" "123458bb7ef6402f6a8bcf5d3be54321")
FRONTEND_URL=$(ask_env_variable "FRONTEND_URL" "https://simpleschat.axisnetworks.com.br")
DEFAULT_LOCALE=$(ask_env_variable "DEFAULT_LOCALE" "pt_BR")
FORCE_SSL=$(ask_env_variable "FORCE_SSL" "true")
ENABLE_ACCOUNT_SIGNUP=$(ask_env_variable "ENABLE_ACCOUNT_SIGNUP" "false")
REDIS_URL=$(ask_env_variable "REDIS_URL" "redis://redis:6379")
POSTGRES_HOST=$(ask_env_variable "POSTGRES_HOST" "postgres")
POSTGRES_USERNAME=$(ask_env_variable "POSTGRES_USERNAME" "postgres")
POSTGRES_PASSWORD=$(ask_env_variable "POSTGRES_PASSWORD" "AdminAdmin")
POSTGRES_DATABASE=$(ask_env_variable "POSTGRES_DATABASE" "chatwoot")
ACTIVE_STORAGE_SERVICE=$(ask_env_variable "ACTIVE_STORAGE_SERVICE" "local")
RAILS_LOG_TO_STDOUT=$(ask_env_variable "RAILS_LOG_TO_STDOUT" "true")
USE_INBOX_AVATAR_FOR_BOT=$(ask_env_variable "USE_INBOX_AVATAR_FOR_BOT" "true")
MAILER_SENDER_EMAIL=$(ask_env_variable "MAILER_SENDER_EMAIL" "Chatwoot <scantechrio@gmail.com>")
SMTP_DOMAIN=$(ask_env_variable "SMTP_DOMAIN" "gmail.com")
SMTP_ADDRESS=$(ask_env_variable "SMTP_ADDRESS" "smtp.gmail.com")
SMTP_PORT=$(ask_env_variable "SMTP_PORT" "587")
SMTP_USERNAME=$(ask_env_variable "SMTP_USERNAME" "scantechrio@gmail.com")
SMTP_PASSWORD=$(ask_env_variable "SMTP_PASSWORD" "ifosqkvspofxmmvh")
SMTP_AUTHENTICATION=$(ask_env_variable "SMTP_AUTHENTICATION" "login")
SMTP_ENABLE_STARTTLS_AUTO=$(ask_env_variable "SMTP_ENABLE_STARTTLS_AUTO" "true")
SMTP_OPENSSL_VERIFY_MODE=$(ask_env_variable "SMTP_OPENSSL_VERIFY_MODE" "peer")
MAILER_INBOUND_EMAIL_DOMAIN=$(ask_env_variable "MAILER_INBOUND_EMAIL_DOMAIN" "scantechrio@gmail.com")

# Criar o arquivo docker-compose.yml com o conteúdo fornecido
cat <<EOL > docker-compose.yml
version: "3.7"

##############
#
# Execute o comando para migrar o banco:
#
# bundle exec rails db:chatwoot_prepare
#
#############

services:
  chatwoot_app:
    image: sendingtk/chatwoot:v3.7.0
    command: bundle exec rails s -p 3000 -b 0.0.0.0
    entrypoint: docker/entrypoints/rails.sh
    volumes:
      - chatwoot_data:/app/storage 
      - chatwoot_public:/app 
    networks:
      - minha_rede
    environment:
      INSTALLATION_NAME: "$INSTALLATION_NAME"
      NODE_ENV: "$NODE_ENV"
      RAILS_ENV: "$RAILS_ENV"
      INSTALLATION_ENV: "$INSTALLATION_ENV"
      SECRET_KEY_BASE: "$SECRET_KEY_BASE"
      FRONTEND_URL: "$FRONTEND_URL"
      DEFAULT_LOCALE: "$DEFAULT_LOCALE"
      FORCE_SSL: "$FORCE_SSL"
      ENABLE_ACCOUNT_SIGNUP: "$ENABLE_ACCOUNT_SIGNUP"
      REDIS_URL: "$REDIS_URL"
      POSTGRES_HOST: "$POSTGRES_HOST"
      POSTGRES_USERNAME: "$POSTGRES_USERNAME"
      POSTGRES_PASSWORD: "$POSTGRES_PASSWORD"
      POSTGRES_DATABASE: "$POSTGRES_DATABASE"
      ACTIVE_STORAGE_SERVICE: "$ACTIVE_STORAGE_SERVICE"
      RAILS_LOG_TO_STDOUT: "$RAILS_LOG_TO_STDOUT"
      USE_INBOX_AVATAR_FOR_BOT: "$USE_INBOX_AVATAR_FOR_BOT"
      MAILER_SENDER_EMAIL: "$MAILER_SENDER_EMAIL"
      SMTP_DOMAIN: "$SMTP_DOMAIN"
      SMTP_ADDRESS: "$SMTP_ADDRESS"
      SMTP_PORT: "$SMTP_PORT"
      SMTP_USERNAME: "$SMTP_USERNAME"
      SMTP_PASSWORD: "$SMTP_PASSWORD"
      SMTP_AUTHENTICATION: "$SMTP_AUTHENTICATION"
      SMTP_ENABLE_STARTTLS_AUTO: "$SMTP_ENABLE_STARTTLS_AUTO"
      SMTP_OPENSSL_VERIFY_MODE: "$SMTP_OPENSSL_VERIFY_MODE"
      MAILER_INBOUND_EMAIL_DOMAIN: "$MAILER_INBOUND_EMAIL_DOMAIN"
    ports:
      - "3000:3000"

  chatwoot_sidekiq:
    image: sendingtk/chatwoot:v3.7.0
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - chatwoot_data:/app/storage
      - chatwoot_public:/app
    networks:
      - minha_rede
    environment:
      INSTALLATION_NAME: "$INSTALLATION_NAME"
      NODE_ENV: "$NODE_ENV"
      RAILS_ENV: "$RAILS_ENV"
      INSTALLATION_ENV: "$INSTALLATION_ENV"
      SECRET_KEY_BASE: "$SECRET_KEY_BASE"
      FRONTEND_URL: "$FRONTEND_URL"
      DEFAULT_LOCALE: "$DEFAULT_LOCALE"
      FORCE_SSL: "$FORCE_SSL"
      ENABLE_ACCOUNT_SIGNUP: "$ENABLE_ACCOUNT_SIGNUP"
      REDIS_URL: "$REDIS_URL"
      POSTGRES_HOST: "$POSTGRES_HOST"
      POSTGRES_USERNAME: "$POSTGRES_USERNAME"
      POSTGRES_PASSWORD: "$POSTGRES_PASSWORD"
      POSTGRES_DATABASE: "$POSTGRES_DATABASE"
      ACTIVE_STORAGE_SERVICE: "$ACTIVE_STORAGE_SERVICE"
      RAILS_LOG_TO_STDOUT: "$RAILS_LOG_TO_STDOUT"
      USE_INBOX_AVATAR_FOR_BOT: "$USE_INBOX_AVATAR_FOR_BOT"
      MAILER_SENDER_EMAIL: "$MAILER_SENDER_EMAIL"
      SMTP_DOMAIN: "$SMTP_DOMAIN"
      SMTP_ADDRESS: "$SMTP_ADDRESS"
      SMTP_PORT: "$SMTP_PORT"
      SMTP_USERNAME: "$SMTP_USERNAME"
      SMTP_PASSWORD: "$SMTP_PASSWORD"
      SMTP_AUTHENTICATION: "$SMTP_AUTHENTICATION"
      SMTP_ENABLE_STARTTLS_AUTO: "$SMTP_ENABLE_STARTTLS_AUTO"
      SMTP_OPENSSL_VERIFY_MODE: "$SMTP_OPENSSL_VERIFY_MODE"
      MAILER_INBOUND_EMAIL_DOMAIN: "$MAILER_INBOUND_EMAIL_DOMAIN"

  redis:
    image: redis:6.0
    volumes:
      - redis_data:/data
    networks:
      - minha_rede

  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: "$POSTGRES_DATABASE"
      POSTGRES_USER: "$POSTGRES_USERNAME"
      POSTGRES_PASSWORD: "$POSTGRES_PASSWORD"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - minha_rede

volumes:
  chatwoot_data:
  chatwoot_public:
  redis_data:
  postgres_data:

networks:
  minha_rede:
    external: true
    name: minha_rede
EOL

# Verificar e instalar Docker e Docker Compose, se necessário
check_and_install_docker

# Criar rede, se não existir
if ! docker network inspect minha_rede >/dev/null 2>&1; then
    echo "Criando a rede minha_rede..."
    docker network create minha_rede
else
    echo "A rede minha_rede já existe. Prosseguindo..."
fi

# Criar volumes, se não existirem
for volume in chatwoot_data chatwoot_public redis_data postgres_data; do
    if ! docker volume inspect $volume >/dev/null 2>&1; then
        echo "Criando o volume $volume..."
        docker volume create $volume
    else
        echo "O volume $volume já existe. Prosseguindo..."
    fi
done

# Executar o comando docker-compose up -d
docker-compose up -d

echo "Implantação concluída com sucesso!"
