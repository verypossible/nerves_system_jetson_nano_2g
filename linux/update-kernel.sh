#!/bin/sh

set -e

OE4T_REPO=https://github.com/OE4T/linux-tegra-4.9
OE4T_BRANCH=oe4t-patches-l4t-r32.5

KERNEL_VERSION=4.9
KERNEL_SUBLEVEL=140
KERNEL_TARBALL=linux-$KERNEL_VERSION.$KERNEL_SUBLEVEL.tar.xz

WORK_PATH=$PWD/work

L4T_KERNEL_URL=git://nv-tegra.nvidia.com/linux-$KERNEL_VERSION.git
KERNEL_URL=https://www.kernel.org/pub/linux/kernel/v4.x/$KERNEL_TARBALL

clone() {
  local URL=$1
  local LOC=$2
  git clone $URL --branch $LINUX4TEGRA_VERSION --depth 1 $LOC
  mv $LOC/.git $LOC/.git_rm
  rm -rf $LOC/.git_rm
}


create_patches() {
  # Work in a temporary directory

  rm -fr $WORK_PATH
  mkdir -p $WORK_PATH
  cd $WORK_PATH

  wget $KERNEL_URL
  echo "Extracting..."
  tar -x -f $KERNEL_TARBALL && mv linux-$KERNEL_VERSION a

  echo "Syncing l4t kernel..."
  clone $OE4T_REPO $OE4T_BRANCH && mv linux-tegra-4.9 b
  cd $WORK_PATH/b

  git init
  git checkout -b upstream
  git add .
  git commit -m upstream
  cd $WORK_PATH

  echo "Assembling repo..."
  cd $WORK_PATH/l4t-linux

  grep -rl "/\.\./nvidia" . | xargs sed -i 's!/\.\./nvidia!/nvidia!g'
  grep -rl "/\.\./nvgpu" . | xargs sed -i 's!/\.\./nvgpu!/nvgpu!g'

  git checkout -b $LINUX4TEGRA_VERSION
  git add .
  git commit -m $LINUX4TEGRA_VERSION
  return 0
}

update_kernel

echo "Consolidated kernel"
