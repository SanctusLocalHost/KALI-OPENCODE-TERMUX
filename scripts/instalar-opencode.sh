#!/usr/bin/env bash
#
# instalar-opencode.sh
#
# Instala o Node.js, o NPM e o OpenCode CLI dentro do Kali NetHunter
# Rootless, no Termux.
#
# Uso:
#   1. Entre no Kali com: nh
#   2. Torne o script executável: chmod +x instalar-opencode.sh
#   3. Execute: ./instalar-opencode.sh
#
# O script não instala o Kali NetHunter. Ele deve ser executado depois
# que o ambiente Kali já estiver funcionando.

set -euo pipefail

info() {
    printf '[info] %s\n' "$1"
}

erro() {
    printf '[erro] %s\n' "$1" >&2
}

# ---------------------------------------------------------------------------
# 1. Confere se o script está sendo executado dentro do Kali
# ---------------------------------------------------------------------------
if [ ! -r /etc/os-release ] || ! grep -qi '^ID=kali' /etc/os-release; then
    erro "Este script deve ser executado dentro do Kali NetHunter."
    erro "No Termux, execute 'nh' primeiro e depois rode o script novamente."
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Define se será necessário usar sudo
# ---------------------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    SUDO=()
    info "Executando como root. O sudo não será necessário."
else
    if ! command -v sudo >/dev/null 2>&1; then
        erro "O comando sudo não foi encontrado. Execute o script como root com 'nh -r'."
        exit 1
    fi
    SUDO=(sudo)
fi

# ---------------------------------------------------------------------------
# 3. Instala o Node.js e o NPM
# ---------------------------------------------------------------------------
info "Atualizando a lista de pacotes do Kali..."
"${SUDO[@]}" apt update

info "Instalando Node.js e NPM..."
"${SUDO[@]}" apt install -y nodejs npm

info "Node.js: $(node --version)"
info "NPM: $(npm --version)"

# ---------------------------------------------------------------------------
# 4. Verifica onde o NPM instala pacotes globais e se há permissão de escrita
# ---------------------------------------------------------------------------
PREFIX="$(npm config get prefix)"
GLOBAL_LIB="$PREFIX/lib/node_modules"
INSTALL_CMD=(npm install -g @opencode/cli)

info "Prefixo global do NPM: $PREFIX"

if [ "$(id -u)" -ne 0 ]; then
    if [ -d "$GLOBAL_LIB" ] && [ ! -w "$GLOBAL_LIB" ]; then
        info "A pasta global pertence a outro usuário. A instalação usará sudo."
        INSTALL_CMD=("${SUDO[@]}" npm install -g @opencode/cli)
    elif [ ! -d "$GLOBAL_LIB" ] && [ ! -w "$PREFIX" ]; then
        info "Sem permissão de escrita em $PREFIX. A instalação usará sudo."
        INSTALL_CMD=("${SUDO[@]}" npm install -g @opencode/cli)
    fi
fi

# ---------------------------------------------------------------------------
# 5. Instala o OpenCode CLI
# ---------------------------------------------------------------------------
info "Instalando o OpenCode CLI..."
"${INSTALL_CMD[@]}"

# ---------------------------------------------------------------------------
# 6. Garante que a pasta de binários do NPM esteja no PATH
# ---------------------------------------------------------------------------
BIN_DIR="$PREFIX/bin"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        info "Adicionando $BIN_DIR ao PATH em ~/.bashrc..."
        printf '\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$HOME/.bashrc"
        export PATH="$BIN_DIR:$PATH"
        ;;
esac

# ---------------------------------------------------------------------------
# 7. Valida a instalação
# ---------------------------------------------------------------------------
if ! command -v opencode >/dev/null 2>&1; then
    erro "O comando opencode não foi encontrado após a instalação."
    erro "Confira o caminho com: npm root -g"
    erro "E o binário com: ls -l $GLOBAL_LIB/@opencode/cli/bin"
    exit 1
fi

info "OpenCode localizado em: $(command -v opencode)"
info "Versão instalada: $(opencode --version)"

printf '\n'
printf 'Instalação concluída.\n'
printf 'Para abrir a interface, execute: opencode\n'
printf 'Para sair da interface, use Ctrl+C.\n'
