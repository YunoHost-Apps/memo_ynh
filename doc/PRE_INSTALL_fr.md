Ce paquet ne tourne que sur x86-64 et aarch64. memo est compilé avec bun, qui
ne publie pas de runtime pour armhf ni pour les machines 32 bits.

L'installation télécharge un binaire d'environ 90 Mo depuis codeberg.org, et
rien d'autre. Sur x86-64 c'est celui que votre processeur sait exécuter : le
rapide s'il a AVX2, le « baseline » sinon.
