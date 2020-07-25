

;*********************************************
;	Kernel.asm
;*********************************************

org 0x0						; offset to 0

bits 16						; real mode

							;loaded at linear address 0x10000

jmp main					; jump to main

;*************************************************;
;	Prints a string
;	DS=>SI: 0 terminated string
;************************************************;

Print:
	lodsb					; load next byte from string from SI to AL
	or			al, al		; Does AL=0?
	jz			PrintDone	; Yep, null terminator found-bail out
	mov			ah,	0eh		; Nope-Print the character
	int			10h
	jmp			Print		; Repeat until null terminator found
PrintDone:
	ret						; we are done, so return

;*************************************************;
;	ithu namada
;*************************************************;

cpuVendorID:
	mov 		al, 0x01
	int 		0x21

	mov 		eax,0
	cpuid							; call cpuid command
	mov 		[vendor_id],ebx		; load last string
	mov 		[vendor_id+4],edx	;load middle string
	mov 		[vendor_id+8],ecx	; load first string
	mov 		si, vendor_id		;print CPU vender ID
	call		Print
	mov 		al, 0x01
	int 		0x21
	ret

processorName:
	mov 		al, 0x01
	int 		0x21

	mov			 eax,0x80000002		
	cpuid
	mov  		[cpu_name], eax
	mov  		[cpu_name+4], ebx
	mov  		[cpu_name+8], ecx
	mov 		[cpu_name+12], edx

	mov 		eax,0x80000003
	cpuid
	mov 		[cpu_name+16],eax
	mov 		[cpu_name+20],ebx
	mov 		[cpu_name+24],ecx
	mov 		[cpu_name+28],edx

	mov 		eax,0x80000004
	cpuid     
	mov 		[cpu_name+32],eax
	mov 		[cpu_name+36],ebx
	mov 		[cpu_name+40],ecx
	mov 		[cpu_name+44],edx

	mov 		si, cpu_name          
	call		Print
	mov 		al, 0x01
	int 		0x21
	ret

noOfHardDrive:
	mov 		al, 0x01
    int 		0x21

	mov 		ax,0040h            ; look at 0040:0075 for a number
	mov 		es,ax               ;
	mov 		dl,[es:0075h]       ; move the number into DL register
	add			dl,30h				; add 48 to get ASCII value            
	mov 		al, dl
    mov 		ah, 0x0E            ; BIOS teletype acts on character 
    mov 		bh, 0x00
    mov 		bl, 0x07
    int 		0x10
	ret
	
noOfSerialPorts:
	mov 		al, 0x01
	int 		0x21

	mov 		ax, [es:0x10]
	shr 		ax, 9
	and 		ax, 0x0007
	add 		al, 30h
	mov 		ah, 0x0E            ; BIOS teletype acts on character
	mov 		bh, 0x00
	mov 		bl, 0x07
	int 		0x10
	ret
	
shutdown:
	mov 		ax, 0x1000
    mov 		ax, ss
    mov 		sp, 0xf000
    mov 		ax, 0x5307
    mov 		bx, 0x0001
    mov			cx, 0x0003
    int 		0x15    
	
reboot:
	jmp 		0xffff:0000h
	
clearScreen:
	pusha
	mov 		ah, 0x00
	mov 		al, 0x03  
	int 		0x10
	popa 
	ret
  
cpuInfo:
	mov 		si,cpu_info
	call		Print
	
	mov 		si,cpu_id
	call		Print
	call		cpuVendorID
	cli
	
	mov 		si,linefeed
	call 		Print
	
	mov 		si, cpu_brand
	call 		Print
	call		processorName
	cli
	
	mov 		si,linefeed
	call 		Print

	mov 		si,linefeed
	call 		Print
	mov 		si,linefeed
	call 		Print
	call		prom
	ret
	
hardInfo:
	mov 		si,hardware_info
	call		Print
	
	mov 		si,no_of_hard_drives
	call		Print
	call		noOfHardDrive
	cli
	
	mov 		si,linefeed
	call 		Print
	
	mov 		si, no_of_serial_ports
	call 		Print
	call		noOfSerialPorts
	cli
	
	mov 		si,linefeed
	call 		Print
	
	mov 		si,linefeed
	call 		Print
	mov 		si,linefeed
	call 		Print
	call		prom
	ret
	
invalid_input:
	mov 		si,linefeed
	call 		Print
	mov			si, invmsg0
	call			Print
	mov			si, inp
	call			Print
	mov			si, invmsg
	call			Print
	mov 		si,linefeed
	call 		Print
	mov 		si,linefeed
	call 		Print
	call		prom
	ret
	
prom:
	mov			si, prompt
	call		Print
	mov     	ah, 0x00
    int     	0x16   
	cmp			al,'r'
	je			reboot
	cmp			al,'s'
	je			shutdown
	cmp			al,'c'
	je			cpuInfo
	cmp			al,'h'
	je			hardInfo
	mov			[inp],al
	jmp			invalid_input
	ret
	
	
;*************************************************;
;	Second Stage Loader Entry Point
;************************************************;

main:
	cli					; clear interrupts
	push		cs		; Insure DS=CS
	pop			ds

	mov			si, Msg
	call		Print
	cli
	call		clearScreen
	mov			si, linefeed
	call		Print
	cli
	mov			si, osName
	call		Print
	cli
	mov			si, osVersion
	call		Print
	cli
	mov			si, linefeed
	call		Print
	cli
	mov			si, option1
	call		Print
	cli
	mov			si, option2
	call		Print
	cli
	mov			si, linefeed
	call		Print
	cli
	
	call		prom
    hlt
	

;*************************************************;
;	Data Section
;************************************************;
[SEGMENT .data]
Msg					db	"Preparing to load operating system...",13,10,0
osName				db	"Kicrosoft Kindows [Version 1.0.0000.000]",13,10,0
osVersion			db	"(c) 2021 Kicrosoft Corporation. All rights reserved.",13,10,0
option1				db	"Cpu_info      -c        Hardware_info -h",13,10,0
option2				db	"Shutdown      -s        Reboot        -r",13,10,0
cpu_info 			db "Cpu_info",13,10,0
hardware_info		db "Hardware_info",13,10,0
cpu_id				db	"CPU Vendor : ", 0
cpu_brand			dd	"CPU Name: ",0
no_of_hard_drives	db	"Number of hard drives: ",0
no_of_serial_ports	db	"Number of serial ports: ",0
prompt				db	"Kindows\Prompt>",0
linefeed 			db "       ",13, 10, 0
invmsg0				db	"'",0
invmsg				db	"' is not recognized as an internal or external command.",13,10,0

[SEGMENT .bss]
cpu_name			resb	64
vendor_id			resb	64
inp					resb	2


