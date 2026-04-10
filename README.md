# Raspberry Pi Docker Simulations

Dette repo indeholder flere Dockerfile-varianter til at simulere Raspberry Pi-lignende Linux-maskiner.

## Struktur

- `images/raspbian/`
- `images/debian/`
- `images/ubuntu/`

Hver mappe har 3 varianter:

- `Dockerfile.base`
- `Dockerfile.java`
- `Dockerfile.dotnet`

## Faste standarder i alle images

- Bruger: `pi`
- Password: `raspberry`
- Pakker: `vim`, `curl`, `wget`, `php-cli`, `tzdata`, `procps`, `net-tools`, `iproute2`, `openssh-server`
- Exposed ports: `22`, `80`, `8080`, `3306`

## Menu scripts

- Linux/macOS Bash: `scripts/docker-menu.sh`
- Windows Batch: `scripts/docker-menu.bat`

Begge scripts kan:

1. Bygge valgfri Dockerfile
2. Foreslaa tilfaldigt image-tag (kan overskrives)
3. Koere et bygget image
4. Spoerge om servernavn og saette container hostname
5. Mappe porte ud fra et prefix mellem `10-99`
6. Bruge `docker` hvis installeret, ellers `podman`
7. Valgfrit mounte en host sti til `/var/media`
8. Understoette Windows-stier i begge formater: `c:\users\cintix` og `c:/users/cintix`

## Port-mapping med prefix

Prefix + faste suffixes:

- `80` -> `${prefix}80`
- `8080` -> `${prefix}88`
- `22` -> `${prefix}22`
- `3306` -> `${prefix}33`

Eksempel med prefix `11`:

- `1189:80`
- `1188:8080`
- `1122:22`
- `1133:3306`

## Koer scripts

Linux/macOS:

```bash
./scripts/docker-menu.sh
```

Windows (cmd):

```bat
scripts\\docker-menu.bat
```

## Note om Raspbian

`images/raspbian` er lavet som en Raspbian-lignende simulation baseret paa Debian userspace, saa det er praktisk at bygge/koere i almindelige Docker-miljoer.
