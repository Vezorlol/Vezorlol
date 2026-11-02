import Foundation

/// Эмодзи-заглушки коллекций (до подключения своей графики через GiftArtProvider).
public enum CollectionEmoji {
    public static func emoji(for id: String) -> String { table[id] ?? "🎁" }
    static let table: [String: String] = [
        "plush_pepe": "🐸", "algorithm_cup": "🏆", "heart_locket": "💖", "intelligence_cup": "🧠", "resistance_dog": "🐕",
        "durovs_cap": "🧢", "scared_cat": "🙀", "precious_peach": "🍑", "heroic_helmet": "⛑️", "loot_bag": "💰",
        "durovs_glasses": "🕶️", "astral_shard": "🔮", "nail_bracelet": "📿", "mighty_arm": "💪", "westside_sign": "🤟",
        "perfume_bottle": "🧴", "artisan_brick": "🧱", "mini_oscar": "🏅", "ion_gem": "💎", "gem_signet": "💍",
        "low_rider": "🚗", "magic_potion": "🧪", "swiss_watch": "⌚", "kissed_frog": "🐸", "sharp_tongue": "👅",
        "bonded_ring": "💍", "voodoo_doll": "🪆", "neko_helmet": "🐱", "genie_lamp": "🪔", "vintage_cigar": "🚬",
        "signet_ring": "💍", "toy_bear": "🧸", "diamond_ring": "💎", "electric_skull": "💀", "rare_bird": "🦜",
        "eternal_rose": "🌹", "khabibs_papakha": "🎩", "bling_binky": "🍼", "cupid_charm": "💘", "sky_stilettos": "👠",
        "lucky_locket": "🍀", "ufc_strike": "🥊", "trapped_heart": "💔", "ionic_dryer": "💨", "snoop_cigar": "🌿",
        "love_potion": "💕", "mad_pumpkin": "🎃", "flying_broom": "🧹", "crystal_ball": "🔮", "valentine_box": "💌",
        "skull_flower": "💐", "record_player": "📀", "love_candle": "🕯️", "sakura_flower": "🌸", "myth_mask": "🎭",
        "top_hat": "🎩", "sleigh_bell": "🔔", "jingle_bells": "🔔", "hanging_star": "⭐", "berry_box": "🍓",
        "jelly_bunny": "🐰", "joyful_bundle": "🎀", "bunny_muffin": "🧁", "fine_pen": "🖊️", "evil_eye": "🧿",
        "witch_hat": "🧙", "snow_mittens": "🧤", "jolly_chimp": "🐵", "surge_board": "🏄", "snow_globe": "🔮",
        "santa_hat": "🎅", "input_key": "🔑", "lush_bouquet": "💐", "spy_agaric": "🍄", "light_sword": "⚔️",
        "eternal_candle": "🕯️", "moon_pendant": "🌙", "desk_calendar": "📅", "bow_tie": "🎀", "faith_amulet": "🙏",
        "spring_basket": "🧺", "hex_pot": "🍲", "swag_bag": "👜", "snoop_dogg": "🐶", "pretty_posy": "🌷",
        "liberty_figure": "🗽", "homemade_cake": "🍰", "restless_jar": "🫙", "cookie_heart": "🍪", "money_pot": "🪴",
        "stellar_rocket": "🚀", "clover_pin": "☘️", "mousse_cake": "🍮", "ginger_cookie": "🍪", "jack_in_the_box": "🤡",
        "winter_wreath": "🎄", "party_sparkler": "🎇", "b_day_candle": "🎂", "holiday_drink": "🥤", "victory_medal": "🥇",
        "mood_pack": "😎", "spiced_wine": "🍷", "timeless_book": "📖", "hypno_lollipop": "🍭", "fresh_socks": "🧦",
        "star_notepad": "📓", "jester_hat": "🃏", "easter_egg": "🥚", "whip_cupcake": "🧁", "happy_brownie": "🍫",
        "pet_snake": "🐍", "big_year": "🗓️", "tama_gadget": "🕹️", "candy_cane": "🍬", "mirage_lamp": "💡",
        "xmas_stocking": "🧦", "instant_ramen": "🍜", "pool_float": "🛟", "lol_pop": "🍭", "vice_cream": "🍦",
        "lunar_snake": "🌙", "ice_cream": "🍨", "chill_flame": "🔥", "snake_box": "🐍"
    ]
}
