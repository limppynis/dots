#!/bin/bash

# Check if superuser, otherwise run sudo and pass HOME path and username.
if [ "$(whoami)" != "root" ]; then
  echo '#  Superuser permission is required.'
  sudo "$0" "$@" -- "$HOME" "$(whoami)"
  exit $?
fi

# use the passed HOME path or use the environment variable if
# not specifies (ie. the script is run as root), same with username
home=${2:-"$HOME"}
user=${3:-"$(whoami)"}
dots=$(dirname $(realpath $0))

# Add sources
echo '#  Adding non-free sources and jessie-backports.'
# remove non-free if present and then
# append non-free to all lines starting with 'deb '.
sed -r 's/^(deb .*)non-free *$/\1/' -i /etc/apt/sources.list
sed -r 's/^deb .*/& non-free/' -i /etc/apt/sources.list

# removes backports if present and then append it to sources.list file-
sed -r 's/deb http:\/\/debian.jpleau.ca\/ jessie-backports main contrib non-free//'\
 -i /etc/apt/sources.list
echo 'deb http://debian.jpleau.ca/ jessie-backports main contrib non-free'\
 >> /etc/apt/sources.list

echo '#  Updating packages list.'
apt-get update -qq


# Install packages. May take long.
essential=(sudo zip xinit i3 i3blocks i3lock build-essential autoconf automake \
pkg-config libpango1.0-dev libpangocairo-1.0-0 libcairo2-dev libglib2.0-dev \
libxcb-xkb-dev libxcb-xinerama0-dev libxcb1-dev xutils-dev libtool libxcb-util0-dev \
libxcb-ewmh-dev libxcb-icccm4-dev libxcb-randr0-dev libstartup-notification0-dev \
libxkbcommon-dev libxkbcommon-x11-dev bison flex byacc)

recommended=(git vim alsa-utils scrot feh software-properties-common)
additional=(chromium pavucontrol vlc nautilus terminator wicd-gtk lxappearance)

echo '#  Installing essential packages (may take long).'
apt-get install ${essential[@]}

echo '#  Installing recommended packages (may take long).'
apt-get install ${recommended[@]}

echo '#  Installing additional packages (may take long).'
apt-get install ${additional[@]}

unset essential
unset recommended
unset additional


# Install fonts
echo '#  Downloading Roboto Mono font.'
wget -q https://fonts.google.com/download?family=Roboto%20Mono -O roboto-mono.zip
unzip roboto-mono.zip -d roboto-mono

echo '#  Downloading Raleway font.'
wget -q https://fonts.google.com/download?family=Raleway -O raleway.zip
unzip raleway.zip -d raleway

echo '#  Downloading Font Awesome font.'
wget -q http://fontawesome.io/assets/font-awesome-4.7.0.zip -O fontawesome.zip
unzip fontawesome.zip -d fontawesome

echo '#  Installing fonts.'
mkdir -p /usr/share/fonts/truetype
mkdir -p $home/.fonts/
chown -R $user $home/.fonts/

mv roboto-mono raleway /usr/share/fonts/truetype/
mv fontawesome/font-awesome-4.7.0/fonts/* $home/.fonts/
fc-cache -f

echo '#  Cleaning up.'
rm -r roboto-mono.zip raleway.zip fontawesome.zip fontawesome


# Install text editor
echo '#  Downloading and installing sublime text 3.'
wget -q https://download.sublimetext.com/sublime-text_build-3126_amd64.deb -O sublime_text3.deb
dpkg -i sublime_text3.deb
rm sublime_text3.deb


# Install i3 dependency
echo '# Cloning xcb-util-xrm repository from https://github.com/Airblader/xcb-util-xrm.'
git clone --recursive https://github.com/Airblader/xcb-util-xrm.git $home/xcb-util-xrm --quiet

echo '# Installing xcb-util-xrm.'
cd $home/xcb-util-xrm
autoreconf -i
mkdir build
../configure
make
make install
chown -R $user $home/xcb-util-xrm/


# Install Rofi
echo '#  Cloning Rofi repository from https://github.com/DaveDavenport/rofi.'
git clone https://github.com/DaveDavenport/rofi.git $home/rofi --quiet

echo '#  Installing Rofi.'
cd $home/rofi
git submodule update --init
autoreconf -i
mkdir build
cd build
../configure
make
make install

echo '#  Adding LIBDIR and LD_LIBRARY_PATH export in .bashrc'
echo "export LIBDIR='/usr/local/lib:$LIBDIR'" >> .bashrc
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LIBDIR" >> .bashrc

echo '#  Reload .bashrc'
source $home/.bashrc


# if there's an existing i3 configuration, back it up and delete the folder
if [ -d "$home/.i3" ]; then
  echo '#  Backing up  previous i3 configuration to $HOME/i3.back.zip'
  zip $home/i3.back.zip $home/.i3 -r
  rm -r $home/.i3
fi

echo '#  Linking i3 dots.'
ln -s  $dots/i3 $home/.i3

# if there's an existing terminator config, back it up.
if [ -d "$home/.config/terminator/config" ]; then
  echo '#  Backing up  previous terminator config to $HOME/.config/terminator/config.back'
  mv $home/.config/terminator/config $home/.config/terminator/config.back
fi

echo '# Linking terminator config.'
mkdir -p $home/.config/terminator
ln -s  $dots/terminator/config $home/.config/terminator/config

# https://snwh.org/paper/download
echo '#  Installing Paper icons.'
wget -q 'https://snwh.org/paper/download.php?owner=snwh&ppa=pulp&pkg=paper-icon-theme,16.04'\
 -O paper-icon.deb
wget -q 'https://snwh.org/paper/download.php?owner=snwh&ppa=pulp&pkg=paper-gtk-theme,16.04'\
 -O paper-gtk.deb
dpkg -i paper-icon.deb
dpkg -i paper-gtk.deb
apt-get install -f --force-yes -qq
rm paper-icon.deb
rm paper-gtk.deb


echo '#  Done, here is a couple of things you may want to do now:'
echo '#  - select arc-theme on lxappearance'
echo '#  - select paper icons on lxappearance'
echo '#  - install following packages for Sublime Text:'
echo '#     -Package Control'
echo '#     -Material Theme (blue accent)'
echo '#     -Emmet'
echo '#     -JSX'
echo '#  - install firmware-iwlwifi if on laptop'
echo '#  - run `adduser [username] sudo` to add user to sudoers.'
unset home user dots
# Todo:
#  - add sublime and GTK config linking
#  - test and update end message
#  - set up projects folder
#  - remove update.sh
#  - fix keypub
#  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <PUBKEY>