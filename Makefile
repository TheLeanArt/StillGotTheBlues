# Super Game Boy Sound Mixer
#
# Copyright (c) 2025 Dmitry Shechtman


VER = 0.1.0
NAME = sgb_$(VER)
TITLE = STILLGOTTHEBLUES

TARGET = $(NAME).gb
SYM = $(NAME).sym

RGBASMFLAGS  = -I inc -I art
RGBLINKFLAGS = -n $(SYM)
RGBFIXFLAGS  = -v -m MBC1 -p 0xFF -t $(TITLE) --sgb-compatible --old-licensee 0x33

OBJS = \
	src/main.o \
	src/sound.o \
	src/update.o \
	src/handlers.o \
	src/trans.o \
	src/shake.o \
	src/password.o \
	src/sgb.o \
	src/joypad.o \
	src/a.o \
	src/b.o \
	src/tiles.o \
	src/intro/intro_main.o \
	src/intro/intro_drop.o \
	src/intro/intro_lut.o \

INC = \
	inc/hardware.inc \
	inc/defs.inc \
	inc/common.inc \
	inc/macros.inc \
	inc/sound.inc \
	inc/update.inc \
	inc/handlers.inc \
	inc/trans.inc \
	inc/charmap.inc \
	inc/intro.inc \

1BPP = \
	art/borders.1bpp \
	art/circles.1bpp \
	art/digits.1bpp \
	art/alpha.1bpp \
	art/logo2.1bpp \

2BPP = \
	art/sel_hex.2bpp \
	art/sel_quad.2bpp \
	art/sel_dir.2bpp \
	art/sel_width.2bpp \
	art/sel_check.2bpp \
	art/obj_labels.2bpp \
	art/arrows.2bpp \
	art/pushb_hex.2bpp \
	art/pushb_quad.2bpp \
	art/pushb_dir.2bpp \
	art/pushb_width.2bpp \
	art/pushb_check.2bpp \
	art/labels.2bpp \
	art/dis_hex.2bpp \
	art/dis_quad.2bpp \
	art/dis_dir.2bpp \
	art/dis_width.2bpp \
	art/dis_check.2bpp \

TILEMAPS = \
	art/circles.tilemap \
	art/sel_quad.tilemap \
	art/pushb_quad.tilemap \
	art/dis_quad.tilemap \

INTRO_1BPP = \
	art/intro/intro_not.1bpp \
	art/intro/intro_top.1bpp \
	art/intro/intro_by.1bpp \
	art/intro/intro_reg.1bpp \
	art/intro/intro_n0.1bpp \
	art/intro/intro_i.1bpp \
	art/intro/intro_n.1bpp \
	art/intro/intro_t.1bpp \
	art/intro/intro_e.1bpp \
	art/intro/intro_d.1bpp \
	art/intro/intro_o.1bpp \

all: $(TARGET)

clean:
	rm -f $(1BPP) $(2BPP) $(TILEMAPS) $(INTRO_1BPP) $(OBJS) $(TARGET) $(SYM)

$(TARGET): $(OBJS)
	rgblink $(RGBLINKFLAGS) $^ -o $@ 
	rgbfix  $(RGBFIXFLAGS) $@

src/tiles.o: src/tiles.asm $(INC) $(1BPP) $(2BPP)

src/intro/intro_main.o: src/intro/intro_main.asm $(INC) $(INTRO_1BPP)
	rgbasm $(RGBASMFLAGS) -I art/intro $< -o $@

%.o: %.asm $(INC)
	rgbasm $(RGBASMFLAGS) $< -o $@

art/circles.1bpp: art/circles.png
	rgbgfx -u -d 1 -T -b 0x20 $< -o $@

art/digits.1bpp: art/digits.png
	rgbgfx -Z -d 1 $< -o $@

art/intro/%.1bpp: art/intro/%.png
	rgbgfx -Z -d 1 $< -o $@

%.1bpp: %.png
	rgbgfx -d 1 $< -o $@
	
art/%_quad.2bpp: art/%_quad.png
	rgbgfx -u -c gbc:art/gbc.pal -T -b 0x50 $< -o $@

art/%_width.2bpp: art/%_width.png
	rgbgfx -u -c gbc:art/gbc.pal $< -o $@

%.2bpp: %.png
	rgbgfx -c gbc:art/gbc.pal $< -o $@
