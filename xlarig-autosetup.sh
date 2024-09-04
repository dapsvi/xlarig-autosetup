#!/data/data/com.termux/files/usr/bin/bash
apt update && apt install python python2 openssh -y
pkg install wget openssl-tool proot -y && hash -r


folder=debian-fs
if [ -d "$folder" ]; then
        first=1
        echo "skipping downloading"
fi
tarball="debian-rootfs.tar.xz"
if [ "$first" != 1 ];then
        if [ ! -f $tarball ]; then
                echo "Download Rootfs, this may take a while base on your internet speed."
                case `dpkg --print-architecture` in
                aarch64)
                        archurl="arm64" ;;
                arm)
                        archurl="armhf" ;;
                amd64)
                        archurl="amd64" ;;
                x86_64)
                        archurl="amd64" ;;        
                i*86)
                        archurl="i386" ;;
                x86)
                        archurl="i386" ;;
                *)
                        echo "unknown architecture"; exit 1 ;;
                esac
                wget "https://raw.githubusercontent.com/EXALAB/AnLinux-Resources/master/Rootfs/Debian/${archurl}/debian-rootfs-${archurl}.tar.xz" -O $tarball
        fi
        cur=`pwd`
        mkdir -p "$folder"
        cd "$folder"
        echo "Decompressing Rootfs, please be patient."
        proot --link2symlink tar -xJf ${cur}/${tarball}||:
        cd "$cur"
fi
mkdir -p debian-binds
bin=xlarig.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
pulseaudio --start
## For rooted user: pulseaudio --start --system
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A debian-binds)" ]; then
    for f in debian-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b debian-fs/root:/dev/shm"
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"



installationsh="apt update && apt upgrade && apt install git build-essential proot make cmake automake autoconf libssl-dev libcurl4-openssl-dev libtool zlib1g-dev libgmp-dev && git clone https://github.com/scala-network/XLArig && mv ./XLArig ./xlarig && mkdir xlarig/build && cd xlarig/scripts && chmod +x * && ./build_deps.sh && cd ../build && cmake .. -DXMRIG_DEPS=scripts/deps && make -j$(nproc)"



# Default values
solo=0
cores=2
donate=0
worker="worker"
address="SvkGewGw1tr4e8b4EMYGpTdTTPqdFgBovSPYo8rvWbmtK2PtdXjGt1R4J2UtSn3wHLebNUV8YNacN52F3Rb1aPZw2eUQuQjys"
installation=0

# Parse options
while getopts ":sc:d:a:w:" opt; do
  case \$opt in
    s) solo=1 ;;
    c) cores=\$OPTARG ;;
    d) donate=\$OPTARG ;;
    a) address=\$OPTARG ;;  # -a accepts a string argument (crypto address)
    w) worker=\$OPTARG ;;
    i) installation=1 ;;
    \?) echo "Invalid option -\$OPTARG" >&2; exit 1 ;;
    :) echo "Option -\$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Shift off processed options
shift \$((OPTIND -1))


rig="./xlarig -a panther a -u \$address -p \$WORKER --donate-level=\$donate -k"


xcommand+=" && \$rig"

# Use options
if [[ \$solo -eq 1 ]]; then
  echo "Solo mode enabled."
  xcommand+=" -o mine.scalaproject.io:8888"
else
  echo "Solo mode disabled."
  xcommand+=" -o mine.scalaproject.io:3333"
fi

if [[ \$cores -eq 2 ]]; then
  echo "4 cores used"
  xcommand+=" -t 2 --cpu-affinity 0xc0"
fi

if [[ \$cores -eq 2 ]]; then
  echo "2 cores used"
  xcommand+=" -t 4 --cpu-affinity 0x55"
fi

if [[ \$donate -ge 0 && \$donate -le 100 ]]; then
  echo "Donation percentage: \$donate%"
else
  echo "Invalid donation value. Must be between 0 and 100." >&2
  exit 1
fi

if [[ -n \$address ]]; then
  echo "Using crypto address: \$address"
else
  echo "No crypto address provided."
fi

if [[ \$installation -eq 1 ]]; then
  xcommand+=" && \$installationsh"
fi

echo \$xcommand >> ./debian-fs/root/.bashrc

if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM



pkg install pulseaudio -y

if grep -q "anonymous" ~/../usr/etc/pulse/default.pa;then
    echo ""
else
    echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> ~/../usr/etc/pulse/default.pa
fi

echo "exit-idle-time = -1" >> ~/../usr/etc/pulse/daemon.conf
#echo "Modified pulseaudio timeout to infinite"
echo "autospawn = no" >> ~/../usr/etc/pulse/client.conf
#echo "Disabled pulseaudio autospawn"
echo "export PULSE_SERVER=127.0.0.1" >> debian-fs/etc/profile
#echo "Setting Pulseaudio server to 127.0.0.1"

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "removing image for some space"
rm $tarball
echo "You can now launch xlarig with the ./${bin} script"
echo "Make sure not to move the ${bin} script"