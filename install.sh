#!/bin/bash

# Função para verificar se o Docker está instalado
function check_docker {
  if ! command -v docker &> /dev/null
  then
    echo "Docker não está instalado. Instalando Docker..."
    install_docker
  else
    echo "Docker já está instalado."
    check_docker_version
  fi
}

# Função para instalar o Docker
function install_docker {
  sudo apt-get update
  sudo apt-get install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
}

# Função para verificar a versão do Docker
function check_docker_version {
  local required_version="20.10.0"
  local installed_version=$(docker --version | awk -F '[ ,]+' '{ print $3 }')
  
  if [ "$(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1)" != "$required_version" ]; then 
    echo "Docker está desatualizado. Versão instalada: $installed_version. Versão necessária: $required_version."
    read -p "Deseja atualizar o Docker? (s/n): " update_docker
    if [ "$update_docker" == "s" ]; then
      install_docker
    fi
  else
    echo "Docker está atualizado. Versão instalada: $installed_version."
  fi
}

# Função para verificar se o Docker Compose está instalado
function check_docker_compose {
  if ! command -v docker-compose &> /dev/null
  then
    echo "Docker Compose não está instalado. Instalando Docker Compose..."
    install_docker_compose
  else
    echo "Docker Compose já está instalado."
  fi
}

# Função para instalar o Docker Compose
function install_docker_compose {
  sudo apt-get update
  sudo apt-get install -y docker-compose
}

# Verificar e instalar Docker se necessário
check_docker

# Verificar e instalar Docker Compose se necessário
check_docker_compose

# Solicitar informações ao usuário
read -p "Digite o nome do projeto: " PROJECT_NAME
read -p "Digite a URL do frontend (ex: https://chatw.axisnetworks.com.br): " FRONTEND_URL
read -p "Digite o domínio do SMTP (ex: gmail.com): " SMTP_DOMAIN
read -p "Digite o endereço do SMTP (ex: smtp.gmail.com): " SMTP_ADDRESS
read -p "Digite a porta do SMTP (ex: 587): " SMTP_PORT
read -p "Digite o email do remetente para o servidor de email Gmail (ex: scantechrio@gmail.com): " MAILER_SENDER_EMAIL
read -s -p "Digite a senha do email do remetente para o servidor de email Gmail: " SMTP_PASSWORD
echo

# Criar diretório do projeto
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Criar arquivo docker-compose.yml
cat <<EOF > docker-compose.yml
version: "3.7"

services:
  chatwoot_app:
    image: sendingtk/chatwoot:v3.7.0
    command: bundle exec rails s -p 3000 -b 0.0.0.0
    entrypoint: docker/entrypoints/rails.sh
    volumes:
      - "chatwoot_data_${PROJECT_NAME}:/app/storage"
      - "chatwoot_public_${PROJECT_NAME}:/app"
    networks:
      - minha_rede
    environment:
      - INSTALLATION_NAME=chatwoot
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=$(openssl rand -hex 64)
      - FRONTEND_URL="${FRONTEND_URL}"
      - DEFAULT_LOCALE=pt_BR
      - FORCE_SSL=true
      - ENABLE_ACCOUNT_SIGNUP=false
      - REDIS_URL=redis://redis:6379
      - POSTGRES_HOST=postgres
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=AdminAdmin
      - POSTGRES_DATABASE=chatwoot
      - ACTIVE_STORAGE_SERVICE=local
      - RAILS_LOG_TO_STDOUT=true
      - USE_INBOX_AVATAR_FOR_BOT=true
      # Servidor de Email Gmail
      - MAILER_SENDER_EMAIL="Chatwoot <${MAILER_SENDER_EMAIL}>"
      - SMTP_DOMAIN="${SMTP_DOMAIN}"
      - SMTP_ADDRESS="${SMTP_ADDRESS}"
      - SMTP_PORT="${SMTP_PORT}"
      - SMTP_USERNAME="${MAILER_SENDER_EMAIL}"
      - SMTP_PASSWORD="${SMTP_PASSWORD}"
      - SMTP_AUTHENTICATION=login
      - SMTP_ENABLE_STARTTLS_AUTO=true
      - SMTP_OPENSSL_VERIFY_MODE=peer
      - MAILER_INBOUND_EMAIL_DOMAIN="${MAILER_SENDER_EMAIL}"
    ports:
      - "3000:3000"

  chatwoot_sidekiq:
    image: sendingtk/chatwoot:v3.7.0
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - "chatwoot_data_${PROJECT_NAME}:/app/storage"
      - "chatwoot_public_${PROJECT_NAME}:/app"
    networks:
      - minha_rede
    environment:
      - INSTALLATION_NAME=chatwoot
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=$(openssl rand -hex 64)
      - FRONTEND_URL="${FRONTEND_URL}"
      - DEFAULT_LOCALE=pt_BR
      - FORCE_SSL=true
      - ENABLE_ACCOUNT_SIGNUP=false
      - REDIS_URL=redis://redis:6379
      - POSTGRES_HOST=postgres
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=AdminAdmin
      - POSTGRES_DATABASE=chatwoot
      - ACTIVE_STORAGE_SERVICE=local
      - RAILS_LOG_TO_STDOUT=true
      - USE_INBOX_AVATAR_FOR_BOT=true
      # Servidor de Email Gmail
      - MAILER_SENDER_EMAIL="Chatwoot <${MAILER_SENDER_EMAIL}>"
      - SMTP_DOMAIN="${SMTP_DOMAIN}"
      - SMTP_ADDRESS="${SMTP_ADDRESS}"
      - SMTP_PORT="${SMTP_PORT}"
      - SMTP_USERNAME="${MAILER_SENDER_EMAIL}"
      - SMTP_PASSWORD="${SMTP_PASSWORD}"
      - SMTP_AUTHENTICATION=login
      - SMTP_ENABLE_STARTTLS_AUTO=true
      - SMTP_OPENSSL_VERIFY_MODE=peer
      - MAILER_INBOUND_EMAIL_DOMAIN="${MAILER_SENDER_EMAIL}"

  redis:
    image: redis:6.0
    volumes:
      - "redis_data_${PROJECT_NAME}:/data"
    networks:
      - minha_rede

  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: chatwoot
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: AdminAdmin
    volumes:
      - "postgres_data_${PROJECT_NAME}:/var/lib/postgresql/data"
    networks:
      - minha_rede

volumes:
  chatwoot_data_${PROJECT_NAME}:
  chatwoot_public_${PROJECT_NAME}:
  redis_data_${PROJECT_NAME}:
  postgres_data_${PROJECT_NAME}:

networks:
  minha_rede:
    external: true
    name: minha_rede
EOF

# Criar a rede Docker se não existir
docker network create --attachable minha_rede &> /dev/null || true

# Criar os volumes Docker se não existirem
docker volume create chatwoot_data_${PROJECT_NAME} &> /dev/null || true
docker volume create chatwoot_public_${PROJECT_NAME} &> /dev/null || true
docker volume create redis_data_${PROJECT_NAME} &> /dev/null || true
docker volume create postgres_data_${PROJECT_NAME} &> /dev/null || true

# Executar o Docker Compose
docker-compose up -d

# Verificar os contêineres em execução
docker-compose ps

# Migrar o banco de dados
docker-compose exec chatwoot_app bundle exec rails db:chatwoot_prepare

# Exibir logs
docker-compose logs -f
