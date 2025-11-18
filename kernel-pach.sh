#!/bin/bash
# android-kernel-unlock-patch.sh
# Kullanım: ./android-kernel-unlock-patch.sh [PATCH_NAME]

PATCH_NAME="${1:-kernel_security_patch.diff}"

RED="\e[1;31m"; GRN="\e[1;32m"; YLW="\e[1;33m"; CYN="\e[1;36m"; MAG="\e[1;35m"; RST="\e[0m"
ts(){ date +"%m-%d %H:%M:%S.%3N"; }
bar(){ for i in $(seq 1 $1); do printf "#"; sleep $2; done; echo; }

echo -e "${CYN}* Cihaz aranıyor...${RST}"
sleep 0.5

# Eğer ADB yoksa veya cihaz bağlı değilse varsayılan cihaz
if ! command -v adb >/dev/null; then
  BRAND="xiaomi"
  MODEL="Redmi Note 10 Pro"
else
  BRAND=$(adb shell getprop ro.product.brand 2>/dev/null | tr '[:upper:]' '[:lower:]')
  MODEL=$(adb shell getprop ro.product.model 2>/dev/null)
  BRAND=${BRAND:-xiaomi}
  MODEL=${MODEL:-Redmi Note 10 Pro}
fi

echo -e "${GRN}[OK]${RST} Cihaz: ${MAG}$BRAND${RST} / ${YLW}$MODEL${RST}"
sleep 0.4

echo -e "${CYN}* Bootloader moduna geçiliyor...${RST}"
sleep 0.6
echo "$(ts) adb reboot bootloader"
sleep 1

echo "$(ts) fastboot devices"
echo "acb1234efg    fastboot"
sleep 0.3

echo -e "${CYN}* Bootloader unlock başlatılıyor...${RST}"
sleep 0.5

case "$BRAND" in
  xiaomi)
    echo "$(ts) fastboot getvar product"
    echo "(bootloader) product: $MODEL"
    echo "$(ts) fastboot oem device-info"
    echo "(bootloader) Device unlocked: false"
    echo "$(ts) fastboot flashing unlock"
    echo "(bootloader) Unlock acknowledged"
    echo "(bootloader) Wiping data..."
    bar 20 0.04
    echo "(bootloader) Device unlocked: true"
    ;;
  samsung)
    echo "$(ts) fastboot flashing unlock"
    echo "(bootloader) OEM: ON"
    echo "(bootloader) Erasing userdata..."
    bar 18 0.04
    echo "OKAY"
    ;;
  oneplus)
    echo "$(ts) fastboot oem unlock"
    echo "(bootloader) Erasing..."
    bar 18 0.04
    echo "Unlock successful"
    ;;
  *)
    echo "$(ts) fastboot flashing unlock"
    bar 16 0.04
    echo "unlock success"
    ;;
esac

sleep 1
echo
echo -e "${CYN}* Kernel patch uygulanıyor: ${MAG}$PATCH_NAME${RST}"
sleep 0.5

PATCH_FILES=(
  "kernel/arch/arm64/mm/fault.c"
  "kernel/security/keys.c"
  "drivers/input/touchscreen/vendor.c"
  "kernel/fs/binder.c"
)

echo "$(ts) patch: loading $PATCH_NAME"
sleep 0.4

for f in "${PATCH_FILES[@]}"; do
  echo "$(ts) patch: applying to $f (+12 -4)"
  sleep 0.25
done

for i in 12 28 44 59 73 86 94 100; do
  printf "  -> patch apply: %d%%\r" "$i"
  sleep 0.25
done
echo
echo -e "${GRN}[OK] Patch uygulandı.${RST}"
sleep 0.4

echo -e "${CYN}* Modüller yeniden derleniyor...${RST}"
bar 30 0.02

MODULES=(ext4 usbcore binder wlan)
for m in "${MODULES[@]}"; do
  echo "$(ts) mod: compiling $m.ko"
  sleep 0.25
  echo "$(ts) mod: signing $m.ko (RSA2048)"
  sleep 0.25
done

echo -e "${GRN}[OK] Modüller hazır.${RST}"
sleep 0.4

echo -e "${CYN}* boot.img yeniden oluşturuluyor...${RST}"
bar 36 0.02

for blk in {0001..0028}; do
  printf "$(ts) bootimg: writing block %s (sha256:%08x)\n" "$blk" $((RANDOM*RANDOM))
  sleep 0.03
done
echo -e "${GRN}[OK] boot.img üretildi.${RST}"
sleep 0.4

echo -e "${CYN}* AVB doğrulama...${RST}"
echo "$(ts) avb: vbmeta verifying..."
sleep 0.4
echo "$(ts) avb: sha256 OK"
echo "$(ts) avb: footer verified"
sleep 0.3

echo -e "${CYN}* boot.img flash ediliyor...${RST}"
echo "$(ts) fastboot flash boot boot.img"

for blk in {0001..0024}; do
  printf "  -> writing block %s (sha256:%08x)\n" "$blk" $((RANDOM*RANDOM))
  sleep 0.03
done

echo -e "${GRN}OKAY${RST}"
sleep 0.3

echo "$(ts) fastboot set_active b"
echo "(bootloader) slot: b"
sleep 0.3

echo "$(ts) fastboot reboot"
echo -e "${GRN}Rebooting...${RST}"