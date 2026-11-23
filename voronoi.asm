; Voronoi Diagram Generator
; Uses VGA mode 13h (320x200 pixels, 256 colors)
; Builds a diagram from 50 random points

bits 16                     ; 16-bit code
org 100h                    ; COM file format, code starts at offset 100h

;-------------------------------------------------------------------------------
; Constants and Configuration
;-------------------------------------------------------------------------------
POINTS_COUNT    equ 50     ; Number of random points to generate
SCREEN_WIDTH    equ 320    ; Screen width in mode 13h
SCREEN_HEIGHT   equ 200    ; Screen height in mode 13h
VIDEO_SEGMENT   equ 0a000h ; Video memory segment for mode 13h
VGA_MODE        equ 13h    ; VGA video mode 320x200, 256 colors
BASE_COLOR      equ 30     ; Base color for the regions
POINT_COLOR     equ 0      ; Color for the points (black)

;-------------------------------------------------------------------------------
; Data Section
;-------------------------------------------------------------------------------
section .data
start:                      ; Program entry point
        finit               ; Initialize the math coprocessor
        call init_graphics_mode
        call generate_random_points
        call draw_voronoi
        call draw_points

wait_key:
        mov ah, 0
        int 16h

exit_program:
        mov ah, 4ch
        int 21h

;-------------------------------------------------------------------------------
; Drawing Functions
;-------------------------------------------------------------------------------
draw_voronoi:
        ; Draws the Voronoi diagram by coloring each pixel by its closest point
        ; For each pixel on the screen:
        ; 1. Find the closest point
        ; 2. Color the pixel from the index of that point
        ; Parameters:
        ;   al = color index
        ;   bx = y coordinate (0-199)
        ;   cx = x coordinate (0-319)
        mov al, 1              ; Start with color index 1
        mov cx, 0              ; Start at x = 0
        mov bx, 0              ; Start at y = 0
.next_pixel:
        call find_closest_point

        pusha
        add al, 30
        shl al, 1
        call set_pixel
        popa

        inc cx
        cmp cx, 320
        jne .next_pixel
        mov cx, 0
        inc bx
        cmp bx, 200
        jne .next_pixel
        ret

;-------------------------------------------------------------------------------
; Point Calculation
;-------------------------------------------------------------------------------
find_closest_point:
        ; Finds the point closest to the current pixel with the Euclidean distance
        ; Uses the floating-point unit (FPU) for the distance calculations
        ; Input:
        ;   bx = y coordinate of the current pixel
        ;   cx = x coordinate of the current pixel
        ; Output:
        ;   al = index of the closest point (1-based)
        mov al, 0                          ; Initialize the point index
        push bx
        push cx
        mov word [.cx], cx                 ; Store the current x coordinate
        mov word [.cy], bx                 ; Store the current y coordinate
        mov byte [.closest_index], 0       ; Initialize the closest point index
        mov word [.current_distance], 0ffffh; Set the current distance to the maximum
        mov word [.closest_distance], 0ffffh; Set the closest distance to the maximum
        mov cx, POINTS_COUNT               ; Set the loop counter to the number of points
        mov di, 0                          ; Initialize the point array index
.next:
        push cx

        fild word [ds:points + di + 2]     ; Load the y coordinate
        fild word [.cy]                    ; Load the current y coordinate
        fsub st0, st1
        fmul st0, st0

        fild word [ds:points + di]         ; Load the x coordinate
        fild word [.cx]                    ; Load the current x coordinate
        fsub st0, st1
        fmul st0, st0

        fadd st0, st2
        fsqrt

        fild word [.v100]                  ; Scale factor
        fmul st0, st1

        fistp word [.current_distance]
        ffree st0
        ffree st1
        ffree st2
        ffree st3

        mov cx, [.current_distance]
        mov bx, [.closest_distance]
        cmp cx, bx
        jnb .continue

.set_new_closest:
        mov [.closest_distance], cx
        mov [.closest_index], al

.continue:
        add di, 4
        pop cx
        inc al
        loop .next

        pop cx
        pop bx
        inc byte [.closest_index]
        mov al, [.closest_index]
        ret
.cx dw 0
.cy dw 0
.v100 dw 100
.closest_index db 0
.closest_distance dw 0
.current_distance dw 0

;-------------------------------------------------------------------------------
; Point Drawing
;-------------------------------------------------------------------------------
draw_points:
        ; Draws every point as a black 2x2 pixel square
        ; Each point is drawn in black (color 0) so it stays visible
        mov cx, POINTS_COUNT               ; Set the loop counter
        mov di, 0                          ; Initialize the point array index
.next:
        push cx
        mov al, 0
        mov cx, word [points + di]
        mov bx, word [points + di + 2]
        add di, 4

        pusha
        call set_pixel
        popa

        pusha
        inc cx
        call set_pixel
        popa

        pusha
        inc bx
        call set_pixel
        popa

        pusha
        inc bx
        inc cx
        call set_pixel
        popa

        pop cx
        loop .next
        ret

;-------------------------------------------------------------------------------
; Point Generation
;-------------------------------------------------------------------------------
generate_random_points:
        ; Generates random points inside the screen bounds
        ; Points are stored as (x,y) pairs in the point array
        ; x coordinates go from 0 to 319
        ; y coordinates go from 0 to 199
        mov cx, POINTS_COUNT               ; Set the loop counter
        mov di, 0                          ; Initialize the point array index
.next:
        push cx

        mov bx, 320
        call random_number
        mov word [points + di], dx
        add di, 2

        mov bx, 200
        call random_number
        mov word [points + di], dx
        add di, 2

        pop cx
        loop .next
        ret

;-------------------------------------------------------------------------------
; Utility Functions
;-------------------------------------------------------------------------------
random_number:
        ; Generates a pseudo-random number from the system time
        ; Input:
        ;   bx = maximum value (exclusive)
        ; Output:
        ;   dx = random number in the range [0, bx-1]
        mov ah, 0
        int 1ah                           ; Get the system time (cx:dx = clock ticks)
        push cx
        push dx

        mov ax, dx
        mul cx
        xor ax, [.seed]
        xor dx, dx
        div bx                            ; dx = division remainder

        pop bx
        pop cx
        add [.seed], bx
        add [.seed], cx
        ret
.seed dw 0

init_graphics_mode:
        ; Sets VGA mode 13h (320x200, 256 colors)
        ; Points the ES segment to video memory at A000:0000
        mov ax, 0a000h                     ; Video memory segment
        mov es, ax                         ; Set ES to the video segment
        mov ah, 0                          ; Function 0 - set video mode
        mov al, 13h                        ; Mode 13h - 320x200, 256 colors
        int 10h                           ; Call the BIOS video interrupt
        ret

set_pixel:
        ; Draws one pixel on the screen
        ; Input:
        ;   al = color (0-255)
        ;   bx = y coordinate (0-199)
        ;   cx = x coordinate (0-319)
        pusha                             ; Save all registers
        xor dx, dx                        ; Clear DX for the multiplication
        push ax                           ; Save the color
        mov ax, 320                       ; Screen width
        mul bx                            ; Compute y * 320
        add ax, cx                        ; Add the x offset
        mov bx, ax                        ; Move the offset to BX
        pop ax                            ; Restore the color
        mov byte [es:bx], al              ; Write the pixel to video memory
        popa                              ; Restore all registers
        ret

;-------------------------------------------------------------------------------
; BSS Section
;-------------------------------------------------------------------------------
section .bss
points resw POINTS_COUNT * 2               ; Array that stores the point coordinates
