# Memo pour YunoHost

[![Installer Memo avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=memo)

*[Read this readme in english.](./README.md)*

> *Ce package vous permet d'installer Memo rapidement et simplement sur un serveur YunoHost.
> Si vous n'avez pas YunoHost, consultez [ce guide](https://yunohost.org/install) pour savoir comment l'installer.*

## Vue d'ensemble

Memo est un tableau de post-it sur lequel plusieurs personnes écrivent en même
temps. Déplacez une note, tapez dedans, regardez-la bouger sur l'écran des
autres. Il s'inspire de scrumblr, et garde chaque tableau dans un seul fichier
SQLite : aucun serveur de base de données à faire tourner à côté.

Un tableau contient deux choses. Des notes, les carrés colorés habituels, et
des wikicards, des cartes à deux faces construites depuis une page de wiki :
une question au recto, une réponse au verso. Les colonnes se renomment, se
réordonnent et se redimensionnent, les cartes se filtrent, et le tableau
entier se déplace et se zoome comme une carte.

**Version incluse :** 0.9.0~ynh1

## Ce que fait ce paquet

- Lance memo sous systemd avec son propre utilisateur, derrière nginx, sur un port choisi par YunoHost
- Range tous les tableaux dans `/home/yunohost.app/memo/memo.sqlite`, hors du répertoire d'installation : une mise à jour ne s'en approche jamais et une suppression sans `--purge` les laisse en place
- Relie memo au portail YunoHost : les gens arrivent déjà connectés sous leur nom YunoHost et ne voient pas de second formulaire de connexion
- Donne la page d'administration de memo au compte nommé à l'installation
- S'installe à la racine d'un domaine ou dans un sous-répertoire, et passe de l'un à l'autre avec `yunohost app changeurl`

Voir [la documentation d'administration](./doc/ADMIN_fr.md) pour l'emplacement
des fichiers, le câblage de l'authentification unique, et quoi vérifier quand
elle ne marche pas.

## Notes de packaging

memo tourne sur [Bun](https://bun.sh), que Debian ne package pas et pour lequel
YunoHost n'a pas de ressource, contrairement à `ynh_nodejs_install` pour Node.
Bun est donc récupéré comme n'importe quel autre asset. Le manifeste déclare le
zip de release comme seconde source avec une somme de contrôle par
architecture, et le script d'installation le dépose dans
`$install_dir/bin/bun` :

```toml
[resources.sources.bun]
amd64.url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.2/bun-linux-x64-baseline.zip"
amd64.sha256 = "..."
arm64.url = "https://github.com/oven-sh/bun/releases/download/bun-v1.4.2/bun-linux-aarch64.zip"
arm64.sha256 = "..."
```

Deux conséquences à connaître. Le paquet ne fonctionne que sur x86-64 et
aarch64, seules architectures Linux pour lesquelles bun publie des binaires. Et
personne ne met ce runtime à jour à votre place : le bot d'autoupdate de
YunoHost suit les sources de l'app, pas l'interpréteur en dessous.
`dev/update-bun.sh` repointe les deux architectures depuis l'API GitHub, et
`dev/update-source.sh` repointe memo lui-même.

L'asset amd64 est la version *baseline*, volontairement. La version normale
exige AVX2, donc un processeur de 2013 ou plus récent, et sur une machine plus
ancienne elle meurt sur un signal sans rien expliquer.

La source est épinglée sur le tag `v0.9.0`, et `autoupdate.strategy` vaut
`latest_forgejo_tag` : le bot suit les nouveaux tags sur Codeberg. Épingler un
tag plutôt qu'une branche est ce qui fait tenir la somme de contrôle, Codeberg
servant les mêmes octets pour l'archive d'un tag à chaque fois, là où une
archive de branche change sous elle.

## Documentations et ressources

- Dépôt de code officiel de l'app : <https://codeberg.org/mrflos/memo>
- Documentation YunoHost pour cette app : <https://codeberg.org/mrflos/memo#readme>

## Informations pour les développeurs

Pour essayer la branche testing :

```bash
sudo yunohost app install https://github.com/YunoHost-Apps/memo_ynh/tree/testing --debug
# ou
sudo yunohost app upgrade memo -u https://github.com/YunoHost-Apps/memo_ynh/tree/testing --debug
```

**Plus d'infos sur le packaging d'applications :** <https://yunohost.org/packaging_apps>
