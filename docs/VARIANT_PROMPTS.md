# Промпты вариантов улучшения (модели) — топ-6 коллекций

Остальные коллекции: `python tools/build_variant_prompts.py --only <id> ...` (id — из docs/COLLECTIONS.txt).

Для каждой коллекции: 1) в том же чате отправьте базовую картинку коллекции и напишите «это базовый дизайн», 2) вставьте промпт листа, 3) скачайте и выполните команду нарезки под ним.

## Plush Pepe (50 моделей)

### Plush Pepe — лист 1
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Plush Pepe". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Gucci Leap
2. Louis Vuittoad
3. Emerald Plush
4. Steel Frog
5. Midas Pepe
6. Magnate
7. Puppy Pug
8. Fifty Shades
9. Donatello
```
```
python tools/slice_sheet.py plush_pepe_v1.png --rows 3 plush_pepe__gucci_leap plush_pepe__louis_vuittoad plush_pepe__emerald_plush plush_pepe__steel_frog plush_pepe__midas_pepe plush_pepe__magnate plush_pepe__puppy_pug plush_pepe__fifty_shades plush_pepe__donatello
```

### Plush Pepe — лист 2
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Plush Pepe". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Cozy Galaxy
2. Ninja Mike
3. Toading...
4. Leonardo
5. Raphael
6. Kung Fu Pepe
7. Amalgam
8. Santa Pepe
9. X-Ray
```
```
python tools/slice_sheet.py plush_pepe_v2.png --rows 3 plush_pepe__cozy_galaxy plush_pepe__ninja_mike plush_pepe__toading plush_pepe__leonardo plush_pepe__raphael plush_pepe__kung_fu_pepe plush_pepe__amalgam plush_pepe__santa_pepe plush_pepe__x_ray
```

### Plush Pepe — лист 3
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Plush Pepe". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Emo Boi
2. Marble
3. Pink Galaxy
4. Princess
5. Frozen
6. Pink Latex
7. Sketchy
8. Red Pepple
9. Milano
```
```
python tools/slice_sheet.py plush_pepe_v3.png --rows 3 plush_pepe__emo_boi plush_pepe__marble plush_pepe__pink_galaxy plush_pepe__princess plush_pepe__frozen plush_pepe__pink_latex plush_pepe__sketchy plush_pepe__red_pepple plush_pepe__milano
```

### Plush Pepe — лист 4
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Plush Pepe". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Christmas
2. Two Face
3. Birmingham
4. Pepe La Rana
5. Barcelona
6. Stripes
7. Yellow Purp
8. Sunset
9. Bavaria
```
```
python tools/slice_sheet.py plush_pepe_v4.png --rows 3 plush_pepe__christmas plush_pepe__two_face plush_pepe__birmingham plush_pepe__pepe_la_rana plush_pepe__barcelona plush_pepe__stripes plush_pepe__yellow_purp plush_pepe__sunset plush_pepe__bavaria
```

### Plush Pepe — лист 5
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Plush Pepe". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Gummy Frog
2. Yellow Hug
3. Pumpkin
4. Hue Jester
5. Red Menace
6. Polka Dots
7. Poison Dart
8. Spectrum
9. Eggplant
```
```
python tools/slice_sheet.py plush_pepe_v5.png --rows 3 plush_pepe__gummy_frog plush_pepe__yellow_hug plush_pepe__pumpkin plush_pepe__hue_jester plush_pepe__red_menace plush_pepe__polka_dots plush_pepe__poison_dart plush_pepe__spectrum plush_pepe__eggplant
```

### Plush Pepe — лист 6
```
Create ONE image: a 3x2 grid sheet of 5 variants of the collectible "Plush Pepe". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Tropical
2. Pepemint
3. Aqua Plush
4. Hothead
5. Cold Heart
```
```
python tools/slice_sheet.py plush_pepe_v6.png --rows 2 plush_pepe__tropical plush_pepe__pepemint plush_pepe__aqua_plush plush_pepe__hothead plush_pepe__cold_heart
```

## Algorithm Cup (3 моделей)

### Algorithm Cup — лист 1
```
Create ONE image: a 3x1 grid sheet of 3 variants of the collectible "Algorithm Cup". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Gold
2. Silver
3. Bronze
```
```
python tools/slice_sheet.py algorithm_cup_v1.png --rows 1 algorithm_cup__gold algorithm_cup__silver algorithm_cup__bronze
```

## Heart Locket (60 моделей)

### Heart Locket — лист 1
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Heart Locket". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Neptune
2. Mirror
3. Turtles
4. Cirque
5. Uranus
6. White Wolf
7. Valentine
8. Tuxedo Mask
9. Golden
```
```
python tools/slice_sheet.py heart_locket_v1.png --rows 3 heart_locket__neptune heart_locket__mirror heart_locket__turtles heart_locket__cirque heart_locket__uranus heart_locket__white_wolf heart_locket__valentine heart_locket__tuxedo_mask heart_locket__golden
```

### Heart Locket — лист 2
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Heart Locket". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Great Wave
2. Queen Bee
3. Gem Shards
4. Lady Bug
5. Spider Web
6. Mecha Love
7. Stone Flower
8. Shaman
9. Synthwave
```
```
python tools/slice_sheet.py heart_locket_v2.png --rows 3 heart_locket__great_wave heart_locket__queen_bee heart_locket__gem_shards heart_locket__lady_bug heart_locket__spider_web heart_locket__mecha_love heart_locket__stone_flower heart_locket__shaman heart_locket__synthwave
```

### Heart Locket — лист 3
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Heart Locket". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Jupiter
2. Shield of Sun
3. Acorn Hunter
4. Matryoshka
5. Lunar Grail
6. Fairy Dust
7. Rebellion
8. Pluto
9. Saturn
```
```
python tools/slice_sheet.py heart_locket_v3.png --rows 3 heart_locket__jupiter heart_locket__shield_of_sun heart_locket__acorn_hunter heart_locket__matryoshka heart_locket__lunar_grail heart_locket__fairy_dust heart_locket__rebellion heart_locket__pluto heart_locket__saturn
```

### Heart Locket — лист 4
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Heart Locket". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Royal Heart
2. Ocean Star
3. Koi Pond
4. Sanctuary
5. Telegram
6. Casino Bugs
7. Mars
8. Venus
9. Mercury
```
```
python tools/slice_sheet.py heart_locket_v4.png --rows 3 heart_locket__royal_heart heart_locket__ocean_star heart_locket__koi_pond heart_locket__sanctuary heart_locket__telegram heart_locket__casino_bugs heart_locket__mars heart_locket__venus heart_locket__mercury
```

### Heart Locket — лист 5
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Heart Locket". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Sakura
2. Glam Furry
3. Soulkeeper
4. Angelic Pink
5. Heartwood
6. Luna
7. Toy Joy
8. Vampire
9. Reactor
```
```
python tools/slice_sheet.py heart_locket_v5.png --rows 3 heart_locket__sakura heart_locket__glam_furry heart_locket__soulkeeper heart_locket__angelic_pink heart_locket__heartwood heart_locket__luna heart_locket__toy_joy heart_locket__vampire heart_locket__reactor
```

### Heart Locket — лист 6
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Heart Locket". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Love Ring
2. Karaoke Bar
3. Trapped Heart
4. Compass
5. Waffle Maker
6. Emocore
7. Satoru
8. Black Hole
9. Hell Rise
```
```
python tools/slice_sheet.py heart_locket_v6.png --rows 3 heart_locket__love_ring heart_locket__karaoke_bar heart_locket__trapped_heart heart_locket__compass heart_locket__waffle_maker heart_locket__emocore heart_locket__satoru heart_locket__black_hole heart_locket__hell_rise
```

### Heart Locket — лист 7
```
Create ONE image: a 3x2 grid sheet of 6 variants of the collectible "Heart Locket". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Royal Flush
2. Comic Book
3. Nightclub
4. Azure Gem
5. Pepperoni
6. Disco
```
```
python tools/slice_sheet.py heart_locket_v7.png --rows 2 heart_locket__royal_flush heart_locket__comic_book heart_locket__nightclub heart_locket__azure_gem heart_locket__pepperoni heart_locket__disco
```

## Intelligence Cup (3 моделей)

### Intelligence Cup — лист 1
```
Create ONE image: a 3x1 grid sheet of 3 variants of the collectible "Intelligence Cup". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Gold
2. Silver
3. Bronze
```
```
python tools/slice_sheet.py intelligence_cup_v1.png --rows 1 intelligence_cup__gold intelligence_cup__silver intelligence_cup__bronze
```

## Resistance Dog (96 моделей)

### Resistance Dog — лист 1
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Imposter
2. Chosen One
3. Mastermind
4. Loki
5. Cosa Nostra
6. Chinese Dragon
7. Encrypted
8. Salvador
9. Kamina
```
```
python tools/slice_sheet.py resistance_dog_v1.png --rows 3 resistance_dog__imposter resistance_dog__chosen_one resistance_dog__mastermind resistance_dog__loki resistance_dog__cosa_nostra resistance_dog__chinese_dragon resistance_dog__encrypted resistance_dog__salvador resistance_dog__kamina
```

### Resistance Dog — лист 2
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Adamant
2. Ken Dog
3. Rambo
4. Dominant
5. ACAB
6. Silverhand
7. Airbender
8. VPN
9. Che Guevara
```
```
python tools/slice_sheet.py resistance_dog_v2.png --rows 3 resistance_dog__adamant resistance_dog__ken_dog resistance_dog__rambo resistance_dog__dominant resistance_dog__acab resistance_dog__silverhand resistance_dog__airbender resistance_dog__vpn resistance_dog__che_guevara
```

### Resistance Dog — лист 3
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Kratos
2. Zorro
3. Anonymous
4. Asterix
5. Fighter
6. Plush Pepe
7. Squid Guard
8. Guerrilla
9. The Watcher
```
```
python tools/slice_sheet.py resistance_dog_v3.png --rows 3 resistance_dog__kratos resistance_dog__zorro resistance_dog__anonymous resistance_dog__asterix resistance_dog__fighter resistance_dog__plush_pepe resistance_dog__squid_guard resistance_dog__guerrilla resistance_dog__the_watcher
```

### Resistance Dog — лист 4
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Genius
2. Blackbird
3. Take Flight
4. Aviator
5. Future Savior
6. Eight Mile
7. Peacekeeper
8. Plague Doctor
9. Valhalla
```
```
python tools/slice_sheet.py resistance_dog_v4.png --rows 3 resistance_dog__genius resistance_dog__blackbird resistance_dog__take_flight resistance_dog__aviator resistance_dog__future_savior resistance_dog__eight_mile resistance_dog__peacekeeper resistance_dog__plague_doctor resistance_dog__valhalla
```

### Resistance Dog — лист 5
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Titan Slayer
2. Assassin
3. Hologram
4. Rorschach
5. Stencil
6. Lightpaw
7. Dark Raven
8. Dogfather
9. Arrakis
```
```
python tools/slice_sheet.py resistance_dog_v5.png --rows 3 resistance_dog__titan_slayer resistance_dog__assassin resistance_dog__hologram resistance_dog__rorschach resistance_dog__stencil resistance_dog__lightpaw resistance_dog__dark_raven resistance_dog__dogfather resistance_dog__arrakis
```

### Resistance Dog — лист 6
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Creeper
2. Cocoon
3. Spartacus
4. Road Devil
5. Frankenstein
6. Renegade
7. Turtle Ninja
8. Shiny Armor
9. Nishikigoi
```
```
python tools/slice_sheet.py resistance_dog_v6.png --rows 3 resistance_dog__creeper resistance_dog__cocoon resistance_dog__spartacus resistance_dog__road_devil resistance_dog__frankenstein resistance_dog__renegade resistance_dog__turtle_ninja resistance_dog__shiny_armor resistance_dog__nishikigoi
```

### Resistance Dog — лист 7
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Pharaoh
2. Tiger
3. Proxy Server
4. Sheikh
5. Prometheus
6. Supernova
7. Samurai Onna
8. Reforged
9. Cyber Pilot
```
```
python tools/slice_sheet.py resistance_dog_v7.png --rows 3 resistance_dog__pharaoh resistance_dog__tiger resistance_dog__proxy_server resistance_dog__sheikh resistance_dog__prometheus resistance_dog__supernova resistance_dog__samurai_onna resistance_dog__reforged resistance_dog__cyber_pilot
```

### Resistance Dog — лист 8
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Cyberpunk
2. Rawhide
3. Legionnaire
4. Hacker
5. Mad Dog
6. Dracula
7. Solid Oak
8. Agent D
9. Dropout
```
```
python tools/slice_sheet.py resistance_dog_v8.png --rows 3 resistance_dog__cyberpunk resistance_dog__rawhide resistance_dog__legionnaire resistance_dog__hacker resistance_dog__mad_dog resistance_dog__dracula resistance_dog__solid_oak resistance_dog__agent_d resistance_dog__dropout
```

### Resistance Dog — лист 9
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. To The Moon
2. Crypto Spirit
3. Streamer
4. Squire
5. Digital Rain
6. Prophet
7. Gopnik
8. Netrunner
9. Uncontrolled
```
```
python tools/slice_sheet.py resistance_dog_v9.png --rows 3 resistance_dog__to_the_moon resistance_dog__crypto_spirit resistance_dog__streamer resistance_dog__squire resistance_dog__digital_rain resistance_dog__prophet resistance_dog__gopnik resistance_dog__netrunner resistance_dog__uncontrolled
```

### Resistance Dog — лист 10
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Breaker
2. Vandal
3. Caesar
4. Bruce Lee
5. Ghost Rider
6. Shinobi
7. Privateer
8. Desert Camo
9. French Rebel
```
```
python tools/slice_sheet.py resistance_dog_v10.png --rows 3 resistance_dog__breaker resistance_dog__vandal resistance_dog__caesar resistance_dog__bruce_lee resistance_dog__ghost_rider resistance_dog__shinobi resistance_dog__privateer resistance_dog__desert_camo resistance_dog__french_rebel
```

### Resistance Dog — лист 11
```
Create ONE image: a 3x2 grid sheet of 6 variants of the collectible "Resistance Dog". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Raincoat
2. Geisha
3. Wolf Shaman
4. Leader
5. Ultras
6. Druid
```
```
python tools/slice_sheet.py resistance_dog_v11.png --rows 2 resistance_dog__raincoat resistance_dog__geisha resistance_dog__wolf_shaman resistance_dog__leader resistance_dog__ultras resistance_dog__druid
```

## Durov's Cap (55 моделей)

### Durov's Cap — лист 1
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Durov's Cap". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Asterix
2. RGB Glitch
3. Artwork
4. Cartoon
5. Fun Time
6. Cotton Candy
7. Jetspin
8. Tron
9. Neon
```
```
python tools/slice_sheet.py durovs_cap_v1.png --rows 3 durovs_cap__asterix durovs_cap__rgb_glitch durovs_cap__artwork durovs_cap__cartoon durovs_cap__fun_time durovs_cap__cotton_candy durovs_cap__jetspin durovs_cap__tron durovs_cap__neon
```

### Durov's Cap — лист 2
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Durov's Cap". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Snowfall
2. Toxic Guy
3. Honey Bee
4. Falcon
5. Captain
6. Voltage
7. Redrum
8. Classic
9. Autumn
```
```
python tools/slice_sheet.py durovs_cap_v2.png --rows 3 durovs_cap__snowfall durovs_cap__toxic_guy durovs_cap__honey_bee durovs_cap__falcon durovs_cap__captain durovs_cap__voltage durovs_cap__redrum durovs_cap__classic durovs_cap__autumn
```

### Durov's Cap — лист 3
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Durov's Cap". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Duskwave
2. Bluebird
3. Sea Sunset
4. Shadow
5. Duck Tales
6. Frosthorn
7. Krueger
8. Pokemon
9. Chicago Bulls
```
```
python tools/slice_sheet.py durovs_cap_v3.png --rows 3 durovs_cap__duskwave durovs_cap__bluebird durovs_cap__sea_sunset durovs_cap__shadow durovs_cap__duck_tales durovs_cap__frosthorn durovs_cap__krueger durovs_cap__pokemon durovs_cap__chicago_bulls
```

### Durov's Cap — лист 4
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Durov's Cap". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Sky High
2. Apple Slice
3. Corkwood
4. Nightshade
5. Dipper
6. Frosted Brew
7. Candy Shade
8. Goldrose
9. Jade
```
```
python tools/slice_sheet.py durovs_cap_v4.png --rows 3 durovs_cap__sky_high durovs_cap__apple_slice durovs_cap__corkwood durovs_cap__nightshade durovs_cap__dipper durovs_cap__frosted_brew durovs_cap__candy_shade durovs_cap__goldrose durovs_cap__jade
```

### Durov's Cap — лист 5
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Durov's Cap". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Sunrise
2. Ashen
3. Shadeux
4. Mossy
5. Ivory
6. Freshwave
7. Bog Moss
8. Aurora
9. Villager
```
```
python tools/slice_sheet.py durovs_cap_v5.png --rows 3 durovs_cap__sunrise durovs_cap__ashen durovs_cap__shadeux durovs_cap__mossy durovs_cap__ivory durovs_cap__freshwave durovs_cap__bog_moss durovs_cap__aurora durovs_cap__villager
```

### Durov's Cap — лист 6
```
Create ONE image: a 3x3 grid sheet of 9 variants of the collectible "Durov's Cap". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Creamsicle
2. Bordeaux
3. Pink Pop
4. Seabreeze
5. Negative
6. Patriot
7. Pinkie Cap
8. Sepium
9. Night Ivy
```
```
python tools/slice_sheet.py durovs_cap_v6.png --rows 3 durovs_cap__creamsicle durovs_cap__bordeaux durovs_cap__pink_pop durovs_cap__seabreeze durovs_cap__negative durovs_cap__patriot durovs_cap__pinkie_cap durovs_cap__sepium durovs_cap__night_ivy
```

### Durov's Cap — лист 7
```
Create ONE image: a 3x1 grid sheet of 1 variants of the collectible "Durov's Cap". Same glossy 3D toy-like style as the base design of this collection: soft studio lighting, subtle rim light, rounded friendly shapes, rich saturated colors, tiny sparkles. ORIGINAL artwork, no text, no logos. The SAME object and the SAME pose in every cell, only the variant changes (colors, outfit, material, small themed details that match the variant name). Plain flat white background.
Variant names, left-to-right, top-to-bottom:
1. Macintosh
```
```
python tools/slice_sheet.py durovs_cap_v7.png --rows 1 durovs_cap__macintosh
```
