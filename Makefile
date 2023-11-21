# ========== 変数定義 ==========
# 問題に応じて変更すること

USER := isucon

GIT_EMAIL := isucon@example.com
GIT_USER := isucon

BIN_NAME := isucondition
SERVICE_NAME := $(BIN_NAME).go.service
BUILD_DIR := /home/isucon/webapp/go

SLOW_QUERY_LOG := /var/log/mysql/mysql-slow.log
NGNIX_LOG := /var/log/nginx/access.log

ALP_CONFIG_PATH := /home/isucon/tools-config/alp/config.yml

# ========== コマンド ==========

.PHONY: setup
setup: install-tools git-setup

.PHONY: slow-query
slow-query:
	sudo pt-query-digest $(SLOW_QUERY_LOG)

.PHONY: alp
alp: 
	sudo alp ltsv --file=$(NGINX_LOG) --config=$(ALP_CONFIG_PATH)

.PHONY: mysql
access-db:
	sudo mysql -h $(MYSQL_HOST) -P $(MYSQL_PORT) -u $(MYSQL_USER) -p $(MYSQL_PASS) $(MYSQL_DBNAME)
# ========== サブコマンド ==========

.PHONY: install-tools
install-tools:
	sudo apt update
	sudo apt upgrade
	sudo install -y percona-toolkit

	wget https://github.com/tkuchiki/alp/releases/download/v1.0.21/alp_linux_amd64.tar.gz
	tar xvf alp_linux_amd64.tar.gz
	sudo install alp /usr/local/bin/alp
	rm alp_linux_amd64.tar.gz alp

.PHONY: git-setup
git-setup:
	echo "GIT_EMAIL=$(GIT_EMAIL)"
	echo "GIT_EMAIL=$(GIT_USER)"
	git config --global user.email $(GIT_EMAIL)
	git config --global user.name $(GIT_USER)

	# ssh鍵作成
	ssh-keygen -t rsa

.PHONY: build
build:
	cd $(BUILD_DIR); \
	go build -o $(BIN_NAME)

.PHONY: restart
restart:
	sudo systemctl daemon-reload
	sudo systemctl restart $(SERVICE_NAME)
	sudo systemctl restart mysql
	sudo systemctl restart nginx

.PHONY: remove-logs
remove-logs:
	$(eval when = $(shell date "+%s"))
	mkdir -p ~/logs/$(when)
	sudo test -f $(NGNIX_LOG) && sudo mv -f $(NGINX_LOG) ~/logs/$(when)/
	sudo test -f $(SLOW_QUERY_LOG) && sudo mv -f $(SLOW_QUERY_LOG) ~/logs/$(when)/
