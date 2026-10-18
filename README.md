# miloOS

Минимальная консольная Linux-система для x86-64. Система собирается в Docker из
ядра Debian и статического BusyBox, упаковывается в initramfs и загрузочный ISO
с BIOS-GRUB.

## Требования

- Linux/macOS/Windows с установленным Docker Engine;
- доступ Docker к Debian package mirror;
- примерно 2 GB свободного места для образа сборщика и результата.

Команды сборки не используют `sudo`, не меняют пакеты хостовой ОС и не требуют
GitHub-токена.

## Сборка и проверка

```sh
make image       # build/miloOS.iso, build/vmlinuz, build/initramfs.gz
make check       # проверка ISO, ядра, gzip и содержимого initramfs
make smoke       # загрузка отдельного smoke-ISO в QEMU внутри Docker
```

`make smoke` запускает QEMU без KVM, поэтому он медленнее аппаратной
виртуализации. Успешный тест заканчивается сообщением `miloOS: smoke test OK`.

## Запуск вручную

```sh
docker run --rm -it \
  -v "$PWD/build:/images:ro" debian:13-slim \
  sh -c 'apt-get update -qq && apt-get install -y -qq qemu-system-x86 && \
         qemu-system-x86_64 -cdrom /images/miloOS.iso -m 256'
```

В VirtualBox консоль отображается прямо в окне VM. Для QEMU нужен графический
дисплей; для headless-проверки используйте `make smoke`.

## Ограничения текущего MVP

Образ предназначен для экспериментов и разработки: в нём нет сети, менеджера
пакетов, постоянного диска и графической оболочки. Следующий шаг — добавить
конфигурацию сети и монтирование диска после выбора целевого железа.

Ресурсы будущего графического интерфейса находятся в `assets/`: значок —
[`miloos-logo.svg`](assets/miloos-logo.svg), а обои рабочего стола —
[`miloos-wallpaper.svg`](assets/miloos-wallpaper.svg). Обои помещаются внутрь
ISO по пути `/usr/share/backgrounds/miloos-wallpaper.svg`, но текущая система
пока не отображает их без графической оболочки.

