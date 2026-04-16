#include <reg52.h>

typedef unsigned char u8;
typedef unsigned int u16;

#define TRUE 1
#define BUTTON_ACTIVE_LEVEL 0U
#define BUZZER_ACTIVE_LEVEL 1U

#define SCAN_INTERVAL_MS 10U
#define DEBOUNCE_DELAY_MS 20U
#define BUZZER_DURATION_MS 1000U
#define BUZZER_DURATION_TICKS (BUZZER_DURATION_MS / SCAN_INTERVAL_MS)

/* D0-D6 is assumed to map to segments a-g of a common-cathode display. */
static const u8 SEGMENT_CODES[9] = {
    0x00, /* blank */
    0x06, /* 1 */
    0x5B, /* 2 */
    0x4F, /* 3 */
    0x66, /* 4 */
    0x6D, /* 5 */
    0x7D, /* 6 */
    0x07, /* 7 */
    0x7F  /* 8 */
};

static u16 buzzer_ticks_remaining = 0U;

static void delay_1ms(void) {
    volatile u8 i;

    for (i = 0U; i < 120U; ++i) {
    }
}

static void delay_ms(u16 ms) {
    while (ms > 0U) {
        delay_1ms();
        --ms;
    }
}

static void display_room(u8 room) {
    if (room <= 8U) {
        P0 = SEGMENT_CODES[room];
    }
}

static void set_buzzer(u8 enabled) {
    P3_7 = enabled ? BUZZER_ACTIVE_LEVEL : !BUZZER_ACTIVE_LEVEL;
}

static void trigger_call(u8 room) {
    display_room(room);
    buzzer_ticks_remaining = BUZZER_DURATION_TICKS;
    set_buzzer(TRUE);
}

static void service_buzzer(void) {
    if (buzzer_ticks_remaining > 0U) {
        --buzzer_ticks_remaining;
        set_buzzer(TRUE);
    } else {
        set_buzzer(!TRUE);
    }
}

static u8 read_pressed_room(void) {
    u8 key_bits = P2;

    if (BUTTON_ACTIVE_LEVEL == 0U) {
        key_bits = (u8)(~key_bits);
    }

    if ((key_bits & 0x01U) != 0U) {
        return 1U;
    }
    if ((key_bits & 0x02U) != 0U) {
        return 2U;
    }
    if ((key_bits & 0x04U) != 0U) {
        return 3U;
    }
    if ((key_bits & 0x08U) != 0U) {
        return 4U;
    }
    if ((key_bits & 0x10U) != 0U) {
        return 5U;
    }
    if ((key_bits & 0x20U) != 0U) {
        return 6U;
    }
    if ((key_bits & 0x40U) != 0U) {
        return 7U;
    }
    if ((key_bits & 0x80U) != 0U) {
        return 8U;
    }

    return 0U;
}

static void init_system(void) {
    P2 = 0xFFU;
    P0 = 0x00U;
    set_buzzer(!TRUE);
}

int main(void) {
    u8 pending_room = 0U;
    u8 current_room;

    init_system();

    while (TRUE) {
        current_room = read_pressed_room();

        if (pending_room == 0U) {
            if (current_room != 0U) {
                delay_ms(DEBOUNCE_DELAY_MS);
                if (read_pressed_room() == current_room) {
                    pending_room = current_room;
                }
            }
        } else if (current_room == 0U) {
            delay_ms(DEBOUNCE_DELAY_MS);
            if (read_pressed_room() == 0U) {
                trigger_call(pending_room);
                pending_room = 0U;
            }
        }

        delay_ms(SCAN_INTERVAL_MS);
        service_buzzer();
    }
}
