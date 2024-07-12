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

# Solicitar o nome do projeto ao usuário
read -p "Informe o nome do projeto: " PROJECT_NAME

# Criar uma pasta com o nome do projeto
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

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
      - INSTALLATION_NAME=chatwoot
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=123458bb7ef6402f6a8bcf5d3be54321
      - FRONTEND_URL=https://simpleschat.axisnetworks.com.br
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
      - MAILER_SENDER_EMAIL=Chatwoot <scantechrio@gmail.com>
      - SMTP_DOMAIN=gmail.com
      - SMTP_ADDRESS=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_USERNAME=scantechrio@gmail.com
      - SMTP_PASSWORD=ifosqkvspofxmmvh
      - SMTP_AUTHENTICATION=login
      - SMTP_ENABLE_STARTTLS_AUTO=true
      - SMTP_OPENSSL_VERIFY_MODE=peer
      - MAILER_INBOUND_EMAIL_DOMAIN=scantechrio@gmail.com
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
      - INSTALLATION_NAME=chatwoot
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=123458bb7ef6402f6a8bcf5d3be54321
      - FRONTEND_URL=https://simpleschat.axisnetworks.com.br
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
      - MAILER_SENDER_EMAIL=Chatwoot <scantechrio@gmail.com>
      - SMTP_DOMAIN=gmail.com
      - SMTP_ADDRESS=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_USERNAME=scantechrio@gmail.com
      - SMTP_PASSWORD=ifosqkvspofxmmvh
      - SMTP_AUTHENTICATION=login
      - SMTP_ENABLE_STARTTLS_AUTO=true
      - SMTP_OPENSSL_VERIFY_MODE=peer
      - MAILER_INBOUND_EMAIL_DOMAIN=scantechrio@gmail.com

  redis:
    image: redis:6.0
    volumes:
      - redis_data:/data
    networks:
      - minha_rede

  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: chatwoot
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: AdminAdmin
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
