# Přidávání tile scén

- Každý tile je `.tscn` uložený přímo v této složce. Generátor složku načte při startu hry; není potřeba upravovat seznam v kódu.
- Root tile scény musí být `Node2D` se skriptem `res://scripts/world_tile.gd`.
- `tile_width` i `tile_height` nastav na `720`.
- `platform_rects` je `PackedVector4Array`; každá čtveřice znamená `x, y, šířka, výška` platformy v rámci tile.
- Pro bezpečné navázání mezi patry nech spodní platformu přibližně na `y=650` a horní na `y=30`. Jejich x pozice a rozměry mohou být podle tile vlastní.

V projektu je připravená scéna `tile_blue.tscn` jako šablona.
