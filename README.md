# archlinux

1. boot from ISO

2. connect network(wifi)
```bash
iwctl
device list
station wlan0 get-networks
station wlan0 connect SSID 
```
3. get my script
```bash
curl https://wuyanghao.github.io/archlinux/install.sh > install.sh
```
4. run my script(just need choose a disk)
```bash
bash install.sh
```
