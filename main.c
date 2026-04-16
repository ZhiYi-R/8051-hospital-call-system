#include <reg52.h>

typedef unsigned char u8;
typedef unsigned int u16;

#define TRUE 1
#define BUTTON_ACTIVE_LEVEL 0U   /* 按键有效电平（低电平有效） */
#define BUZZER_ACTIVE_LEVEL 1U   /* 蜂鸣器有效电平（高电平有效） */

#define SCAN_INTERVAL_MS 10U     /* 按键扫描间隔（毫秒） */
#define DEBOUNCE_DELAY_MS 20U    /* 按键防抖延迟（毫秒） */
#define DEBOUNCE_TICKS (DEBOUNCE_DELAY_MS / SCAN_INTERVAL_MS)  /* 防抖计数阈值 */
#define BUZZER_DURATION_MS 1000U /* 蜂鸣器持续时间（毫秒） */
#define BUZZER_DURATION_TICKS (BUZZER_DURATION_MS / SCAN_INTERVAL_MS)  /* 蜂鸣器持续计数 */

/* 七段数码管段码表（共阴极）：D0-D6 对应 a-g 段 */
static const u8 SEGMENT_CODES[9] = {
    0x00, /* 空白 */
    0x06, /* 1 */
    0x5B, /* 2 */
    0x4F, /* 3 */
    0x66, /* 4 */
    0x6D, /* 5 */
    0x7D, /* 6 */
    0x07, /* 7 */
    0x7F  /* 8 */
};

static u16 buzzer_ticks_remaining = 0U;  /* 蜂鸣器剩余计数 */

/* 延迟 1 毫秒 */
static void delay_1ms(void) {
    volatile u8 i;

    for (i = 0U; i < 120U; ++i) {
    }
}

/* 延迟指定毫秒数 */
static void delay_ms(u16 ms) {
    while (ms > 0U) {
        delay_1ms();
        --ms;
    }
}

/* 在数码管上显示房间号 */
static void display_room(u8 room) {
    if (room <= 8U) {
        P0 = SEGMENT_CODES[room];
    }
}

/* 设置蜂鸣器状态 */
static void set_buzzer(u8 enabled) {
    P3_7 = enabled ? BUZZER_ACTIVE_LEVEL : !BUZZER_ACTIVE_LEVEL;
}

/* 触发呼叫：显示房间号并启动蜂鸣器 */
static void trigger_call(u8 room) {
    display_room(room);
    buzzer_ticks_remaining = BUZZER_DURATION_TICKS;
    set_buzzer(TRUE);
}

/* 蜂鸣器服务：管理蜂鸣器倒计时 */
static void service_buzzer(void) {
    if (buzzer_ticks_remaining > 0U) {
        --buzzer_ticks_remaining;
        set_buzzer(TRUE);
    } else {
        set_buzzer(!TRUE);
    }
}

/* 读取按键按下状态掩码 */
static u8 read_pressed_mask(void) {
    u8 key_bits = P2;

    if (BUTTON_ACTIVE_LEVEL == 0U) {
        key_bits = (u8)(~key_bits);
    }

    return key_bits;
}

/* 从按键掩码中获取第一个按下的房间号 */
static u8 get_first_room_from_mask(u8 key_bits) {
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

/* 初始化系统 */
static void init_system(void) {
    P2 = 0xFFU;           /* 按键端口上拉 */
    P0 = 0x00U;           /* 数码管清空 */
    set_buzzer(!TRUE);    /* 蜂鸣器关闭 */
}

int main(void) {
    u8 raw_mask = 0U;        /* 当前读取的原始按键状态 */
    u8 debounce_mask = 0U;   /* 防抖中的按键状态 */
    u8 stable_mask = 0U;     /* 已稳定的按键状态 */
    u8 released_mask;        /* 释放的按键掩码 */
    u8 debounce_ticks = 0U;  /* 防抖计数器 */

    init_system();

    while (TRUE) {
        raw_mask = read_pressed_mask();

        /* 防抖逻辑：连续相同状态达到阈值才确认 */
        if (raw_mask == debounce_mask) {
            if (debounce_ticks < DEBOUNCE_TICKS) {
                ++debounce_ticks;
            }

            /* 状态稳定且发生变化 */
            if ((debounce_ticks >= DEBOUNCE_TICKS) && (stable_mask != raw_mask)) {
                released_mask = (u8)(stable_mask & (u8)(~raw_mask));  /* 检测释放的按键 */
                stable_mask = raw_mask;

                /* 按键释放时触发呼叫 */
                if (released_mask != 0U) {
                    trigger_call(get_first_room_from_mask(released_mask));
                }
            }
        } else {
            /* 状态变化，重新开始防抖 */
            debounce_mask = raw_mask;
            debounce_ticks = 1U;
        }

        delay_ms(SCAN_INTERVAL_MS);
        service_buzzer();
    }
}
