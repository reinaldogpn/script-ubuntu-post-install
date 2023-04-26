#!/usr/bin/env bash
# ------------------------------------------------------------------------ #
# O QUE ELE FAZ?
#
# - Esse script instala os programas que utilizo no Ubuntu de forma 100% automática e com 0 interação com o usuário, faz upgrade
#   e limpeza do sistema e é de fácil manutenção. Funciona no Ubuntu 20.04 LTS (ou superior).
#
# COMO USAR?
#
#   - Dar permissões ao arquivo script: chmod +x nome_do_arquivo: ```chmod +x ubuntu-post-install.sh```
#
#   - Executar o script: ```./ubuntu-post-install.sh```
#
# ------------------------------------------------------------------------ #
# Changelog:
#
#   v1.0 11/11/2021, reinaldogpn:
#     - Inclusão de novos programas e adaptação do script para o meu uso pessoal.
#   v2.0 27/05/2022, reinaldogpn:
#     - Correções, adaptações e adição de novos programas, além de pequenos aperfeiçoamentos.
#   v3.0 31/05/2022, reinaldogpn:
#     - Adicionado suporte a pacotes flatpak; pacotes snap e .deb removidos; correções e melhorias.
#   v3.1 19/06/2022, reinaldogpn:
#     - Remoção de pacotes desnecessários e atualização geral do script.
#   v3.2 31/10/2022, reinaldogpn:
#     - (Re)Adição de alguns pacotes .deb e adição do flatpak Bottles em substituição ao Wine.
#   v3.3 26/04/2023, reinaldogpn:
#     - Reestruturação da função que instala pacotes .deb e inclusão de pacotes; adição de pacotes apt; remoção de alguns pacotes flatpak, adição de preferências de customização da dock do Ubuntu; 
#     atualização da função que realiza testes iniciais; pequenas correções e remoção de comandos desnecessários.
#
# ------------------------------------------------------------------------ #
# Extra tips:
#
# Disable 2K Louncher on Steam's Civilization VI init options:
# - eval $( echo "%command%" | sed "s/2KLauncher\/LauncherPatcher.exe'.*/Base\/Binaries\/Win64Steam\/CivilizationVI.exe'/" )
#
# Steam's Counter Strike Global Offensive init options:
# - -tickrate 128 +fps_max 0 -nojoy -novid -fullscreen -r_emulate_gl -limitvsconst -forcenovsync -softparticlesdefaultoff +mat_queue_mode 2 +mat_disable_fancy_blending 1 +r_dynamic 0 -refresh 75
#
# Bottles's permission to add programs shortcut to desktop:
# - flatpak override com.usebottles.bottles --user --filesystem=xdg-data/applications
#
# VBox Extension Pack:
# - https://download.virtualbox.org/virtualbox/7.0.2/Oracle_VM_VirtualBox_Extension_Pack-7.0.2.vbox-extpack
#
# Woeusb requirements & use:
# - sudo apt install libxml2-dev libfuse-dev ntfs-3g-dev
# - Download and compile Wimlib (https://wimlib.net); extrair; ./configure; make; sudo make install;
# - sudo ldconfig -v
# - Download Woeusb (https://github.com/WoeUSB/WoeUSB/releases)
# - sudo ./woeusb --device path/Windows.iso /dev/sdX
#
# ---------------------------- VARIÁVEIS --------------------------------- #

# ***** PROGRAMAS *****
PACOTES_APT=(
  audacity
  calibre
  codeblocks
  dconf-editor
  flatpak
  filezilla
  gimp
  gnome-calendar
  gnome-extensions
  gnome-photos
  gnome-software
  gnome-software-plugin-flatpak
  gnome-sushi
  gnome-tweaks
  gnome-weather
  inkscape
  nautilus-dropbox
  neofetch
  pinhole
  plocate
  qbittorrent
  rhythmbox
  spotify
  virtualbox
  vlc
  zotero
)

PACOTES_DEB=(
  "https://discord.com/api/download?platform=linux&format=deb" # Discord
  "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" # Visual Studio Code
  "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" # Google Chrome
  "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb?_ga=2.220914843.2087402065.1682524928-1166232706.1682524928" # OnlyOffice
  "https://updates.getmailspring.com/download?platform=linuxDeb" # Mailspring
)

PACOTES_DEB_SIZE=${#PACOTES_DEB[@]}

PACOTES_FLATPAK=(
  "io.github.mimbrero.WhatsAppDesktop"    # Whatsapp
  "org.gtk.Gtk3theme.Yaru-dark"           # Yaru-dark theme
  "org.gnome.Epiphany"                    # Epiphany (Gnome Web)
  "com.rafaelmardojai.Blanket"            # Blanket
)

PACOTES_GAMES=(
  libvulkan1
  libvulkan1:i386
  lutris
  steam-installer
  steam-devices
  steam:i386
  wine
)

# ***** CORES *****
AMARELO='\e[1;93m'
VERMELHO='\e[1;91m'
VERDE='\e[1;92m'
SEM_COR='\e[0m'

# ***** PATHS *****
DIRETORIO_DOWNLOAD_DEB="/home/$USER/Downloads/PACOTES_DEB"
FILE="/home/$USER/.config/gtk-3.0/bookmarks"

# Adicionar o diretório e o alias respectivamente
DIRETORIOS=(
  "/home/$USER/Projetos"
)

ALIASES=(
  "/home/$USER/Projetos Projetos"
  "/home/$USER/Dropbox Dropbox"
)

# ------------------------------ FUNÇÕES --------------------------------- #
realizar_testes()
{
  # Internet conectando?
  if ! ping -c 1 8.8.8.8 -q ; then
    echo -e "${VERMELHO}[ERROR] - Seu computador não tem conexão com a internet. Verifique os cabos e o modem.${SEM_COR}"
    exit 1
  else
    echo -e "${VERDE}[INFO] - Conexão com a internet funcionando normalmente.${SEM_COR}"
  fi
  
  # Instalar ferramentas necessárias
  echo -e "${AMARELO}[INFO] - Instalando ferramentas necessárias ...${SEM_COR}"
  sudo apt install curl dkms git wget -y
  echo -e "${VERDE}[INFO] - Pré-requisitos OK, prosseguindo com a execução do script.${SEM_COR}"
}

remover_locks() 
{
  echo -e "${AMARELO}[INFO] - Removendo locks...${SEM_COR}"
  sudo rm /var/lib/dpkg/lock-frontend 
  sudo rm /var/cache/apt/archives/lock 
  echo -e "${VERDE}[INFO] - Locks removidos.${SEM_COR}"
}

adicionar_arquitetura_i386() 
{
  wget -qO- https://raw.githubusercontent.com/retorquere/zotero-deb/master/install.sh
  echo -e "${AMARELO}[INFO] - Adicionando arquitetura i386...${SEM_COR}"
  sudo dpkg --add-architecture i386 
}

atualizar_repositorios()
{
  echo -e "${AMARELO}[INFO] - Atualizando repositórios ...${SEM_COR}"
  curl -sL https://raw.githubusercontent.com/retorquere/zotero-deb/master/install.sh | sudo bash  # Adds Zotero's deb repository
  curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg # Adds Spotify's deb repository
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt update -y 
}

instalar_pacotes_apt()
{
  echo -e "${AMARELO}[INFO] - Instalando pacotes apt ...${SEM_COR}"
  for pacote in ${PACOTES_APT[@]}; do
    if ! dpkg -l | grep -q $pacote; then
      echo -e "${AMARELO}[INFO] - Instalando o pacote $pacote ...${SEM_COR}"
      sudo apt install $pacote -y 
      if dpkg -l | grep -q $pacote; then
        echo -e "${VERDE}[INFO] - O pacote $pacote foi instalado.${SEM_COR}"
      else
        echo -e "${VERMELHO}[ERROR] - O pacote $pacote não foi instalado.${SEM_COR}"
      fi
    else
      echo -e "${VERDE}[INFO] - O pacote $pacote já está instalado.${SEM_COR}"
    fi
  done
}

instalar_pacotes_deb()
{
  # Download dos pacotes
  echo -e "${AMARELO}[INFO] - Baixando pacotes .deb ...${SEM_COR}"
  mkdir $DIRETORIO_DOWNLOAD_DEB
  for (( i = 0; i < PACOTES_DEB_SIZE; i++ )); do
    url=${PACOTES_DEB[i]}
    wget -O "$DIRETORIO_DOWNLOAD_DEB/package$i.deb" $url
  done
  # Instalação dos pacotes
  echo -e "${AMARELO}[INFO] - Instalando pacotes .deb baixados ...${SEM_COR}"
  sudo dpkg -i $DIRETORIO_DOWNLOAD_DEB/*.deb 
  sudo apt --fix-broken install -y 
}

instalar_dependencias_allegro()
{
  echo -e "${AMARELO}[INFO] - Instalando dependências do Allegro ...${SEM_COR}"
  sudo apt install -y liballegro5-dev cmake g++ freeglut3-dev libxcursor-dev libpng-dev libjpeg-dev libfreetype6-dev libgtk2.0-dev libasound2-dev libpulse-dev libopenal-dev libflac-dev libdumb1-dev libvorbis-dev libphysfs-dev 
}

adicionar_repositorios_flatpak()
{
  echo -e "${AMARELO}[INFO] - Adicionando repositórios flatpak com o remote-add...${SEM_COR}"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  echo -e "${VERDE}[INFO] - Nada mais a adicionar.${SEM_COR}"
}

instalar_pacotes_flatpak()
{
  echo -e "${AMARELO}[INFO] - Instalando pacotes flatpak...${SEM_COR}"
  for pacote in ${PACOTES_FLATPAK[@]}; do
    if ! flatpak list | grep -q $pacote; then
      echo -e "${AMARELO}[INFO] - Instalando o pacote $pacote...${SEM_COR}"
      sudo flatpak install -y flathub $pacote 
      if flatpak list | grep -q $pacote; then
        echo -e "${VERDE}[INFO] - O pacote $pacote foi instalado.${SEM_COR}"
      else
        echo -e "${VERMELHO}[ERROR] - O pacote $pacote não foi instalado.${SEM_COR}"
      fi
    else
      echo -e "${VERDE}[INFO] - O pacote $pacote já está instalado.${SEM_COR}"
    fi
  done
}

instalar_driver_TPLinkT2UPlus()
{
#  (Instalação opcional) Driver do adaptador wireless TPLink Archer T2U Plus
  echo -e "${AMARELO}[INFO] - Instalando driver wi-fi TPLink...${SEM_COR}"
  sudo apt install -y build-essential libelf-dev linux-headers-$(uname -r) 
  mkdir $HOME/Downloads/rtl8812au/
  git clone https://github.com/aircrack-ng/rtl8812au.git $HOME/Downloads/rtl8812au/ 
  cd $HOME/Downloads/rtl8812au/
  sudo make dkms_install 
#  se a instalação for abortada, executar o comando: "sudo dkms remove 8812au/5.6.4.2_35491.20191025 --all"
  echo -e "${VERDE}[INFO] - Driver wi-fi instalado!${SEM_COR}"
}

instalar_suporte_games()
{
  echo -e "${AMARELO}[INFO] - Instalando pacotes e drivers de suporte a games ...${SEM_COR}"
  for pacote in ${PACOTES_GAMES[@]}; do
    if ! dpkg -l | grep -q $pacote; then
      echo -e "${AMARELO}[INFO] - Instalando o pacote $pacote ...${SEM_COR}"
      sudo apt install $pacote -y 
      if dpkg -l | grep -q $pacote; then
        echo -e "${VERDE}[INFO] - O pacote $pacote foi instalado.${SEM_COR}"
      else
        echo -e "${VERMELHO}[ERROR] - O pacote $pacote não foi instalado.${SEM_COR}"
      fi
    else
      echo -e "${VERDE}[INFO] - O pacote $pacote já está instalado.${SEM_COR}"
    fi
  done
}

instalar_lol_snap()
{
  echo -e "${AMARELO}[INFO] - Instalando League of Legends (snap)...${SEM_COR}"
  sudo snap install --beta wine-platform-runtime
  sudo snap install --beta wine-platform-5-staging
  sudo snap install --beta wine-platform-7-staging-core20
  sudo snap install --edge leagueoflegends --devmode
  sudo snap refresh
  if snap list | grep -q "leagueoflegends"; then
    echo -e "${VERDE}[INFO] - O instalador de League of Legends está pronto, use 'snap run leagueoflegends' para concluir a instalação.${SEM_COR}"
  else
    echo -e "${VERMELHO}[ERROR] - Falha ao obter o instalador de League of Legends.${SEM_COR}"
  fi
}

extra_config()
{
#  Cria pastas úteis e adiciona atalhos ao Nautilus
  echo -e "${AMARELO}[INFO] - Criando diretórios pessoais...${SEM_COR}"
  if test -f "$FILE"; then
      echo -e "${VERDE}[INFO] - $FILE já existe.${SEM_COR}"
  else
      echo -e "${AMARELO}[INFO] - $FILE não existe. Criando...${SEM_COR}"
      touch /home/$USER/.config/gkt-3.0/bookmarks 
  fi
  for diretorio in ${DIRETORIOS[@]}; do
    mkdir $diretorio
  done
  for _alias in "${ALIASES[@]}"; do
    echo file://$_alias >> $FILE
  done
  # Configurações para o dock do sistema
  echo -e "${AMARELO}[INFO] - Aplicando as preferências à dock do sistema...${SEM_COR}"
  gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'
  gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
  gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
  # Instalando codecs extras
  echo -e "${AMARELO}[INFO] - Instalando codecs adicionais...${SEM_COR}"
  sudo apt install ubuntu-restricted-extras -y
}

upgrade_e_limpeza_sistema()
{
  echo -e "${AMARELO}[INFO] - Fazendo upgrade e limpeza do sistema ...${SEM_COR}"
  sudo apt dist-upgrade -y 
  sudo flatpak update -y 
  sudo snap refresh 
  sudo apt autoclean 
  sudo apt autoremove -y 
  rm -rf $HOME/Downloads/rtl8812au $DIRETORIO_DOWNLOAD_DEB 
  neofetch
  echo -e "${VERDE}[INFO] - Configuração concluída!${SEM_COR}"
  echo -e "${AMARELO}[INFO] - Reinicialização necessária, deseja reiniciar agora? [S/n]:${SEM_COR}"
  read opcao
  [ $opcao = "s" ] || [ $opcao = "S" ] && echo -e "${AMARELO}[INFO] - Fim do script! Reiniciando agora...${SEM_COR}" && reboot
  echo -e "${VERDE}[INFO] - Fim do script! ${SEM_COR}"
}

# ----------------------------- EXECUÇÃO --------------------------------- #
realizar_testes
remover_locks
adicionar_arquitetura_i386
atualizar_repositorios
instalar_pacotes_apt
instalar_pacotes_deb
instalar_dependencias_allegro
adicionar_repositorios_flatpak
instalar_pacotes_flatpak
instalar_driver_TPLinkT2UPlus
instalar_suporte_games
instalar_lol_snap
extra_config
upgrade_e_limpeza_sistema
