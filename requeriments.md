# dedup

Um detector de arquivos duplicados.

Mas não um clone do fdupes.

Algo tipo:

dup ~

Scanning...
██████████

Duplicate groups: 183

Group #12
    ~/Downloads/image.png
    ~/Desktop/image.png
    ~/Pictures/image.png

Saved:
    3.2GB

Depois:

dup delete
dup hardlink
dup symlink
dup move

Desafios interessantes:

hash incremental
cache
multithreading
banco sqlite
ignorar arquivos pequenos
comparar primeiro tamanho
depois hash parcial
depois hash completo

Aprende MUITA coisa.