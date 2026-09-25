/*
 * tempsens0.asm
 *
 *  Created: 01.12.2011 13:51:29
 *   Author: user
 */ 

 .device ATtiny861A
 .include	"F:\DIMA\chip\TempSens\tempsens0\tempsens0\tn861Adef.inc"
 .include	"F:\DIMA\chip\TempSens\tempsens0\tempsens0\mem_map.inc"
 
 


 .org	0x000
 rjmp	start
 
  .org		0x0001	; External Interrupt 0
  reti
  .org		0x0002	; Pin Change Interrupt
  reti
  .org		0x0003	; Timer/Counter1 Compare Match 1A
  reti
  .org		0x0004	; Timer/Counter1 Compare Match 1B
  reti
  .org		0x0005	; Timer/Counter1 Overflow
 rjmp	t1_int
  .org		0x0006	; Timer/Counter0 Overflow
rjmp	 timer0
  .org		0x0008	; USI Overflow
  reti
  .org		0x0009	; EEPROM Ready
  reti
  .org		0x000a	; Analog Comparator
  reti
  .org		0x000b	; ADC Conversion Complete
rjmp	adc_conv ;reti
  .org		0x000c	; Watchdog Time-Out
rjmp	Watchdog
  .org		0x000d	; External Interrupt 1
rjmp	extint1
  .org		0x000e	; Timer/Counter0 Compare Match A
  reti
  .org		0x000f	; Timer/Counter0 Compare Match B
  reti
  .org		0x0010	; Timer/Counter1
 reti
  .org		0x0011	; Timer/Counter1 Compare Match D
  reti
  .org		0x0012	; Timer/Counter1 Fault Protection
  reti



 start:

; 


;--------------------------------------- registr---------------
.def	mc16uL	=r16		;multiplicand low byte
.def	mc16uH	=r17		;multiplicand high byte
.def	mp16uL	=r18		;multiplier low byte
.def	mp16uH	=r19		;multiplier high byte
.def	m16u0	=r18		;result byte 0 (LSB)
.def	m16u1	=r19		;result byte 1
.def	m16u2	=r20		;result byte 2
.def	m16u3	=r23		;result byte 3 (MSB)
.def	mcnt16u	=r22		;loop counter

.def	count_h1_temp =r17
.def	count_h2_temp =r18
.def	const =r10
.def	const_et =r11
.def	water_sel =r12 ; 0x2 =OFF 0x3=ON

.def	cili_t_cels	=r13
	
.def	desjati_cels =r15
	
.def	code_water_test =r14


	

.def	mc8u	=r16		;multiplicand
.def	mp8u	=r17		;multiplier
.def	m8uL	=r17		;result Low byte
.def	m8uH	=r18		;result High byte
.def	mcnt8u	=r20		;loop counter


.def	t_beep = r2
.def	f_beep = r3;

.def	flash = r4

.def	t0_table_step = r5

.def	menu_step =r6

.def	timer1sec =r7

.def	const_t_up =r8
.def	const_t_down =r9
 
 
.def	 TEMP = R16
.def	h1_seg = r18
.def	h2_seg = r19
.def	h3_seg = r20
.def	flags = r21 
					;7 0 - adc stop
					;6	0 - adc key end
					;5	0 - adc tsens end
					;4	0 - adc water end
					;3	0 - key timeout
					;2	0 - menu
					;1	0 - beep
					;0	1 - fareng

 .def	 sreg_copy = R22
 .def	 sym = R23
 .def	key_time_press =r24
 .def	keyboard_code =r25



 ;-----------------------------------------SPL---------------------------------------------------------------------
ldi	temp,0x2 ;stack hig
out	sph,temp

ldi	temp,0x5f ;stack low
out	spl,temp

;------------------------------------------OSCCAL------------------------------------------------------------------
ldi	temp,0x7e; 8f
out	osccal,temp

; ----------------------------CLKPR - Clock Prescale Register----------------------------------------
ldi	temp,0x80
out	clkpr,temp
nop
ldi	temp,0x00 ;f8/1=8MHz
out	clkpr,temp






 ;start_ring:



	.equ	restartwdt =0x4e ;0X48 16 msec, 0x49=32msec ,int en ;0X4D 500mSec; 0x4e=1sec
	;4c=0.25sec

	ldi	flags,0x78
	ldi	key_time_press,0x60;pause press key!!!!!!!!!!!!!!!!!!!

	ldi	r16,0x8;!!!!!!!!!!!!!!!!!!!!!
	mov	code_water_test,r16;!!!!!!!!!!!!!!!!!!!!!!!

	clr	menu_step

	clr	t0_table_step

;-------------------------------porta--------------------------------------------------------------------


	;clr	temp
	;out	porta,temp
	;ldi	temp,0xfb
	;out	ddra,temp



;------------------------------portb--------------------------------------------------------------------
	ldi	temp,0x07
	out	portb,temp
;-------------------------AD_CONVERTER-------------------------------------------------------------

ldi	temp,0x06; 0x05off / 0x8d - adc en int en/ 0xcd start adc/
out	adcsra,temp




ldi	temp,0x02	;0x02 ref=vcc adc2-keyb/  0x47 ref=1,1v adc7 tempsensor
out	admux,temp

;


ldi	temp,0x00;!!!
out	adcsrb,temp

;ldi	temp,0x00
out	didr0,temp
;out	didr1,temp




rcall	sleep_dis


		;-------------------------------ram erase--------------------------------------------------------------
;clr	temp


clr   r27            ; Clear X high byte
ldi   r26,$60        ; Set X low byte to $60
next_mem:
st    X,temp         ; Store r0 in data space loc. $60(X post inc)
inc	r26	
cpi	r26,$e0
breq	erase_end
rjmp	next_mem

erase_end:

	ldi	temp,0xff;time out menu
	sts	wait_menu_out_time_hi,temp
	nop
	sts	wait_menu_out_time_lo,temp
	nop


	ldi	temp,0x1e
	sts	beep_pause,temp; beep pause off
	nop

	ldi	temp,0xff
	sts	code_battery,temp
	nop

	ldi	temp,0x5f
	sts	key_povtor,temp
	nop

	clr	temp
	sts	const_post_alarm,temp
	nop

		;----------------------------EXTERNAL_INTERRUPT--MCUCR sleep mode----------------------------------------

ldi	temp,0x00 ;int1 dis/ int0 dis /intpin dis
out	gimsk,temp




	   ;-----------------------------TIMER_COUNTER_0/1----------------------------------------------------------
;ldi	temp,0x00 
out	tccr0a,temp

ldi	temp,0x10
out	didr1,temp


ldi	temp,0x10
out	tccr0b,temp	;t0 halt


ldi	temp,0x0b;4mhz/8  
out	tccr0b,temp	 

ldi	temp,0x86
out	timsk,temp ;int t0 en; int t1 en; ocie1d compere int en

;-----------------------------------------ANALOG_COMPARATOR--------------------------------------------------------
ldi	temp,0x80
out	acsra,temp
;--------------------------------------WATCHDOG---------------------------------------------------
rcall	wdt_on



;------------------------------------TIMER_COUNTER_1----------------------------------------------------------
ldi	temp,0x07; fclk 8MHz/64=12500
out	tccr1b,temp




;---------------set default ------------------------------------------

	rcall	set_default
 	

;--------------------------------------------------------------------------
;load beep tik!!!!!!!!!!!!!!!!----
	ldi	temp,0xfd; pik
	mov	t_beep,temp
	ldi	temp,0xb0;1.5khz???2.5
	mov	f_beep,temp

	sbi	ddrb,5




	rcall	start_test



sei
rjmp	cycle



;---------------------------cycle------------------------------------------
cycle:

	lds	temp,counter_power_off
	nop
	cpi	temp,0xff
	breq	power_off_start




	rjmp	next_cycles

power_off_start:
	rcall	wdt_off
	;adc/ad/bod - off
	rjmp	sleeping1

next_cycles:
	cpi	flags,0x02; 0x00!!!!!!
	brlo	sleeping1;breq !!!!!!!!!!



	sbrc	flags,7 
	rjmp	cycle

	sbrc	flags,6
	rjmp	goo_adc_start

	sbrc	flags,5
	rjmp	goo_adc_start

	sbrc	flags,4
	rjmp	goo_adc_start

	

	rjmp	cycle

;start ADC
goo_adc_start:

	in	temp,admux
	cpi	temp,0x00
	breq	nostartadc


	cpi	temp,0x87
	breq	adc_temp000001

	rjmp	not_noice


adc_temp000001:
	

; power off segment
	cbi	ddra,0
	cbi	ddra,1
	cbi	ddrb,3
	cbi	ddra,3
	cbi	ddra,4
	cbi	ddra,5
	cbi	ddra,6


;------adc_temp----------------


	sbr	flags,0x80
				

	ldi	temp,0x8e;/singl/  int on/ adc on/prescaler=64 /f=125kHz
	out	adcsra,temp

	ldi	temp,0x68 ;int0 and int1 low / sleep adc noice mode
	out	MCUCR,temp


	sleep


	rjmp	cycle

not_noice:

	sbr	flags,0x80

	ldi	temp,0x8e;/singl/  int on/ adc on/prescaler=64 /f=125kHz
	out	adcsra,temp

;	ldi	temp,0x20 ;int0 and int1 low / sleep adc idle mode
;	out	MCUCR,temp

	ldi	temp,0xce ;/singl/  int on/ adc on/prescaler=64/ +start 0xce /f=125kHz
	out	adcsra,temp

	;ldi	temp,0x68 ;int0 and int1 low / sleep adc noice mode
	;out	MCUCR,temp


nostartadc:
	rjmp	cycle

;-------------------------sleeping1--------
sleeping1:

	ldi	temp,0xda ;t0 res
	out	tcnt0l,temp

	ldi	temp,0x00 ;t1 res
	out	tcnt1,temp

	ldi	temp,0xf
	out	prr,temp;t0 t1 adc usi - off

	;cli

	sbi	portb,2
	sbi	portb,1
	sbi	portb,0

	rcall	sleep_en

	ldi	temp,0x00 
	out	admux,temp


;	in	temp,mcucr
;	sbr	temp,0x84
;	out	mcucr,temp;bods 1    bodse 1
;	cbr	temp,0x4 
;	out	mcucr,temp;bodse 0


ldi	temp,(1<<bods)|(1<<pud)|(1<<se)|(1<<sm1)|(0<<sm0)|(1<<bodse)|(0<<isc01)|(0<<isc00)
out	mcucr,temp

ldi	temp,(1<<bods)|(1<<pud)|(1<<se)|(1<<sm1)|(0<<sm0)|(0<<bodse)|(0<<isc01)|(0<<isc00)
out	mcucr,temp
	;sei

	sleep

	ldi	temp,0x0
	out	prr,temp;t0 t1 adc usi - on

	rjmp	cycle

;==============================pp beep===========================
alr_long_beep1500:	
	ldi	temp,0xff;long time
	mov	t_beep,temp
	ldi	temp,0xd5;1.5khz
	mov	f_beep,temp
rcall	verf_beep_pause
	;sbr	flags,0x2;block sleep
	;sbi	ddrb,5
	ret

alr_shot_beep1500:
	ldi	temp,0xf7;shot time
	mov	t_beep,temp
	ldi	temp,0xd5;1.5khz
	mov	f_beep,temp
rcall	verf_beep_pause
	;sbr	flags,0x2;block sleep
	;sbi	ddrb,5
	ret

alr_long_beep600_neg:
	ldi	temp,0xff; long time
	mov	t_beep,temp
	ldi	temp,0x95;600hz
	mov	f_beep,temp
rcall	verf_beep_pause
	;sbr	flags,0x2;block sleep
	;sbi	ddrb,5
	ret

alr_shot_beep600_neg:
	ldi	temp,0xf7; shot time
	mov	t_beep,temp
	ldi	temp,0x95;600hz
	mov	f_beep,temp
rcall	verf_beep_pause
	;sbr	flags,0x2;block sleep
	;sbi	ddrb,5
	ret

alr_water_beep_start:
	ldi	temp,0x98;e9; time 0.5sec
	mov	t_beep,temp
	ldi	temp,0xc0;1000hz
	mov	f_beep,temp
rcall	verf_beep_pause
	;sbi	ddrb,5
	;sbr	flags,0x2;block sleep
	ret


verf_beep_pause:

	;---------beep pause---------------
	lds	temp,beep_pause;beep pause
	cpi	temp,0x1e; 30sec
	breq	not_beep_pause
	inc	temp
	sts	beep_pause,temp;1e
	nop
	clr	temp
	sts	beep_alr_count,temp
	nop
	sts	beep_var,temp
	nop
	ret
;	cbi	ddrb,5
;	cbr	flags,0x2;unblock sleep
;	ldi	temp,0xfe; stop beep time
;	mov	t_beep,temp

not_beep_pause:
	sbi	ddrb,5
	sbr	flags,0x2;block sleep
	ret
;=====================================================================


;------------------------------Watchdog---------------------------------
Watchdog:
push	temp
push	r17
push	sreg_copy
in	sreg_copy,sreg

	wdr
	ldi	temp,restartwdt ;0X48 16 msec ,int en ;0X4D 500mSec
	out	WDTCR,temp
	wdr


	ldi	temp,0x00 ;int1 dis/ int0 dis /intpin dis!!!!!!!!!
	out	gimsk,temp

;rcall	conv_adc_to_mV	;+	conv_mv_dec7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




;----------------------beep water sensor--------
	ldi	temp,0x02
	cp	water_sel,temp
	breq	not_water_beep

	lds	r17,const_water
	nop

	ldi	temp,0x64;corr sens +100 !!!!!!!!!!!!!!
	add	r17,temp;

	lds	temp,code_waterhi
	nop

	cp	temp,r17
	brlo	water_beep_start

	rjmp	not_water_beep

water_beep_start:

	lds	temp,const_post_alarm
	nop
	sts	beep_alr_count,temp
	nop
	ldi	temp,0x5
	sts	beep_var,temp
	nop

	rcall	alr_water_beep_start

	rjmp	end_beep_all

not_water_beep:

;-----------beep tem---------------
	ldi	temp,0x01
	cp	const_t_up,temp
	brlo	not_beep_1500

;==============================================23/10/2012
	lds	temp,delta_t
	nop
	cpi	temp,0x64
	brsh	neg_delta_1500
;==========================================================

;--------
	lds	temp,delta_t
	nop
	add	temp,const_t_up

	cp	cili_t_cels,temp 
	brlo	not_beep_1500_delta
	rjmp	long_beep1500


long_beep1500:

	lds	temp,const_post_alarm
	nop
	sts	beep_alr_count,temp
	nop
	ldi	temp,0x1
	sts	beep_var,temp
	nop

	rcall	alr_long_beep1500


	rjmp	end_beep_all

;----------
not_beep_1500_delta:

	cp	cili_t_cels,const_t_up 
	brlo	not_beep_1500
	rjmp	shot_beep1500


shot_beep1500:	

	lds	temp,const_post_alarm
	nop
	sts	beep_alr_count,temp
	nop
	ldi	temp,0x2
	sts	beep_var,temp
	nop
	
	rcall	alr_shot_beep1500

	rjmp	end_beep_all

;==============================================23/10/2012
neg_delta_1500:
	cp	cili_t_cels,const_t_up 
	brsh	long_beep1500

	lds	temp,delta_t
	nop
	neg	temp

	push	r18
	mov	r18,const_t_up
	sub	r18,temp
	mov	temp,r18
	pop	r18
	cp	cili_t_cels,temp
	brsh	shot_beep1500

;============================================================
not_beep_1500:



;beep_600----------------------------

	ldi	temp,0x01
	cp const_t_down,temp ; on/off beep low temperature
	brlo	not_beep001_01
	rjmp	next0000112

not_beep001_01:
	rjmp	not_beep_600 ;not_beep001

next0000112:
;==============================================23/10/2012
	lds	temp,delta_t
	nop
	cpi	temp,0x64
	brsh	neg_delta_600_0
	rjmp	pozitive_delta_600

neg_delta_600_0:
	rjmp	neg_delta_600
;============================================================

pozitive_delta_600:
push	r17
	mov	r17,cili_t_cels ; okruglenie cili grad
	ldi	temp,0x01
	cp	desjati_cels,temp
	brlo	not_inc_00001
	inc	r17
not_inc_00001:

	cp	const_t_down,r17 ; low temperature in zone beep 
	brlo	not_beep0001
	
	rjmp	alarm_zone	

not_beep0001:
	pop	r17
	rjmp	not_beep_600

	;---zone alarm down tem.
alarm_zone:
push	r18

	lds	temp,delta_t
	mov	r18,const_t_down
	cp	r18,temp
	brlo	not_sub_001
	sub	r18,temp
	rjmp	next_a_001
not_sub_001:
	ldi	r18,0x00
	cp	r18,r17
	brsh	shot_beep600

next_a_001:
	cp	r18,r17
	brsh	long_beep600
	rjmp	shot_beep600


;---------------------
long_beep600:
	
	pop	r18
	pop	r17

long_beep600_neg:

	lds	temp,const_post_alarm
	nop
	sts	beep_alr_count,temp
	nop
	ldi	temp,0x3
	sts	beep_var,temp
	nop

	rcall	alr_long_beep600_neg

	rjmp	end_beep_all
;---------------------
shot_beep600:	

	pop	r18
	pop	r17
		
shot_beep600_neg:

	lds	temp,const_post_alarm
	nop
	sts	beep_alr_count,temp
	nop
	ldi	temp,0x4
	sts	beep_var,temp
	nop

	rcall	alr_shot_beep600_neg

	rjmp	end_beep_all

;-------------------------

;==============================================29/11/2012
neg_delta_600:

	mov	temp,desjati_cels
	cpi	temp,0x01
	brlo	nul_decjati_cels

	mov	temp,cili_t_cels
	inc	temp
	rjmp	compare001

nul_decjati_cels:
	mov	temp,cili_t_cels
	rjmp	compare001

compare001:
	cp	const_t_down,temp
	brsh	long_beep600_neg


	push	r18
	push	r17

	mov	r18,const_t_down
	lds	r17,delta_t
	neg	r17
	add	r18,r17
	cp	r18,temp
	brsh	long_b_neg

	pop	r17
	pop	r18
	rjmp	not_beep_600

long_b_neg:
	
	pop	r17
	pop	r18
	
	rjmp	shot_beep600_neg

;===========================================================

not_beep_600:







;-----------------------post alr-------
	lds	temp,beep_alr_count
	nop
	cpi	temp,0x0
	breq	not_alr_beep
	dec	temp
	sts	beep_alr_count,temp
	nop
	lds	temp,beep_var
	nop

	cpi	temp,0x1
	breq	l1500
	cpi	temp,0x2
	breq	s1500
	cpi	temp,0x3
	breq	l600
	cpi	temp,0x4
	breq	s600
	cpi	temp,0x5
	breq	w1000

	rjmp	not_alr_beep

l1500:
	rcall	alr_long_beep1500
	rjmp	end_alr_beep
s1500:
	rcall	alr_shot_beep1500
	rjmp	end_alr_beep
l600:
	rcall	alr_long_beep600_neg
	rjmp	end_alr_beep
s600:
	rcall	alr_shot_beep600_neg
	rjmp	end_alr_beep
w1000:
	rcall	alr_water_beep_start
	rjmp	end_alr_beep


not_alr_beep:

	cbi	ddrb,5
	cbr	flags,0x2;unblock sleep
	ldi	temp,0xfe; stop beep time
	mov	t_beep,temp

	ldi	temp,0x1e
	sts	beep_pause,temp;stop beep pause
	nop

	clr	temp
	sts	beep_var,temp
	nop
;-------------------------------

end_alr_beep:

end_beep_all:



;battery!!-------------------
	lds	temp,code_battery
	nop
	cpi	temp,0x6d
	brsh	battery_good
	;beep
	ldi	temp,0xf0;e9; time 0.1sec
	mov	t_beep,temp
	ldi	temp,0xe0;2000hz
	mov	f_beep,temp

	sbi	ddrb,5
	sbr	flags,0x2;block sleep

battery_good:


;------------flags--------------


	sbr	flags,0x20 ;set bit 5(tem)
	

	sbrc	flags,3;flip t0 tab
	rjmp	not_flip_0002

	ldi	temp,0x08;!!!!!!!!!17.04.12 flip
	mov	t0_table_step,temp


not_flip_0002:


	out	sreg,sreg_copy
	pop	sreg_copy
	pop	r17	
	pop	temp

	reti


;------------------------------int timer0-----------------------------------
timer0:

	push	temp
	push	sreg_copy
	in	sreg_copy,sreg


	SBRC	flags,1
	rjmp	not_speed_up
	SBRC	flags,2
	rjmp	not_speed_up
	SBRC	flags,3
	rjmp	not_speed_up

	ldi	temp,0xfc;0xfc-max!!!; ; 125000/11=11363Hz/14=811Hz led
	out	tcnt0l,temp

	rjmp	speed_up


not_speed_up:

	ldi	temp,0xda ; 125000/38=3250Hz/14=232Hz led
	out	tcnt0l,temp

speed_up:

	;rjmp	t0_table_start;!!!!!!test


;----------------wait 3 sec / water test/


push	r17
push	r18

	lds	r17,wait3s_hi
	nop

	cpi	r17,0xa8
	breq	stop_wait3s

	cpi	r17,0xfe;
	breq	stop_beep_power_on
	rjmp	next_test_0004

stop_beep_power_on:
	ldi	temp,0xfe;stop beep
	mov	t_beep,temp
	cbi	ddrb,5

next_test_0004:

	mov	temp,code_water_test
	cpi	temp,0x01
	brlo	not_error_water
	rjmp	error_water

not_error_water:
	cpi	r17,0xe3
	breq	stop_wait3s_0001
	rjmp	error_water


stop_wait3s_0001:
	ldi	r17,0xa8
	sts	wait3s_hi,r17
	rjmp	stop_wait3s


error_water:
	wdr
	cpi	r17,0xfe
	breq	keyscan_eng_start

	cpi	r17,0xf7
	breq	analize_key

	cpi	r17,0xf6
	breq	waterscan_start

	cpi	r17,0xed
	breq	water_analyze



	rjmp	next_wait3s_001


analize_key:
	
	cpi	keyboard_code,0x43  ;4sw 0x27; secret menu 
	breq	sens_menu_start

	rjmp	next_wait3s_001

sens_menu_start:
	;ldi	keyboard_code,0xa0; key clr
	ldi	temp,0x2f
	mov	menu_step,temp; jamp sensitive menu

;load beep tik!!!!!!!!!!!!!!!!----
	ldi	temp,0xf0; tik
	mov	t_beep,temp
	ldi	temp,0x90;1.5khz
	mov	f_beep,temp

	sbi	ddrb,5

	rjmp	next_wait3s_001


keyscan_eng_start:

	ldi	temp,0x22;adc2 vref=vcc adlar=1
	out	admux,temp
	ldi	temp,0x0
	out	adcsrb,temp

	rjmp	next_wait3s_001

waterscan_start:
	cbi	ddrb,5;beep off

	wdr

	sbi	portb,0
	cbi	portb,1
	sbi	portb,2

	sbi	ddrb,3


	ldi	temp,0xa9;adc9 vref=2.5v adlar=1
	out	admux,temp
	ldi	temp,0x10
	out	adcsrb,temp	
	rjmp	next_wait3s_001



stop_wait3s:
	rjmp	stop_wait3s_01;jamp exit test


water_analyze:
	wdr
	sbi	portb,0
	sbi	portb,1
	cbi	portb,2

	lds	temp,code_waterhi
	nop
	;
	cpi	temp,0x64;<100
	brlo	korotkoe
	cpi	temp,0xc9;<201
	brlo	mokrij
	cpi	temp,0xdd;>=221
	brsh	obriv
	clr	temp
	mov	code_water_test,temp; write code error =0


	cbi	porta,0;0
	cbi	porta,1
	cbi	portb,3
	cbi	porta,3
	cbi	porta,4
	cbi	porta,5
	sbi	porta,6
	sbi	porta,7


	rjmp	test_end
	
korotkoe:

	sbi	porta,0;1
	cbi	porta,1
	cbi	portb,3
	sbi	porta,3
	sbi	porta,4
	sbi	porta,5
	sbi	porta,6
	sbi	porta,7

	ldi	temp,0x1
	rjmp	write_code_error

mokrij:

	cbi	porta,0;2
	cbi	porta,1
	sbi	portb,3
	cbi	porta,3
	cbi	porta,4
	sbi	porta,5
	cbi	porta,6
	sbi	porta,7


	ldi	temp,0x2
	rjmp	write_code_error

obriv:

	cbi	porta,0;3
	cbi	porta,1
	cbi	portb,3
	cbi	porta,3
	sbi	porta,4
	sbi	porta,5
	cbi	porta,6
	sbi	porta,7


	ldi	temp,0x3
	rjmp	write_code_error

write_code_error:
	mov	code_water_test,temp

	ldi	temp,0x2
	mov	water_sel,temp; water sensor off
	

	ldi	temp,0x98;e9; time 0.5sec
	mov	t_beep,temp
	ldi	temp,0xc0;1000hz
	mov	f_beep,temp
	sbi	ddrb,5


test_end:

	rjmp	next_wait3s_001


next_wait3s_001:
	;ldi	keyboard_code,0xa0; key clr
	lds	r18,wait3s_lo
	clr	temp
	subi	r18,0x01
	sbc	r17,temp
	sts	wait3s_lo,r18
	nop
	sts	wait3s_hi,r17
	nop

pop	r18
pop	r17

	rjmp	end_t0
	
;----------------------------------------
stop_wait3s_01:


pop	r18
pop	r17

	rjmp	t0_table_start
	
;--------------------------------------t0_table---

t0_table:
.dw	 led_h1_s, key_scan_s, flash_to4ka,  menu_s, led_h3_s, power_off_s, timer_outkey_s, timer_1sec_s

.dw	displey_s, led_h2_s, tem_scan_s, water_scan_s,  timer_beep_s, reset_t0_table
	;8                                   b                              d    



t0_table_start:


	push	r20
	push	r21

	mov	R20,t0_table_step

	LSL	R20	; Сдвигом влево умножаем содержимое R20 на два.
			
 
	LDI	ZL, low(t0_table*2)	; Загружаем адрес нашей таблицы. Компилятор сам посчитает
	LDI	ZH, High(t0_table*2)	; Умножение и запишет уже результат.Старший и младший байты.
 
	CLR	R21		; Сбрасываем регистр R21 - нам нужен ноль.
	ADD	ZL, R20		; Складываем младший байт адреса. Если возникнет переполнение
	ADC	ZH, R21		; То вылезет флаг переноса. Вторая команда складывает
				; с учетом переноса. Поскольку у нас R21=0, то по сути
				; мы прибавляем только флаг переноса. 				
				 
 
	LPM	R20,Z+		; Загрузили в R20 адрес из таблицы
	LPM	R21,Z		; Старший и младший байт
 
 
	MOVW	 ZH:ZL,r21:r20		; забросили адрес в Z 

	pop	r21
	pop	r20

	IJMP

power_off_s:;---------------------------

	lds	temp,dev_log; dev logik /8
	nop
	inc	temp
	sts	dev_log,temp
	nop
	sbrs	temp,3
	rjmp	not_inc_counter_power_off

	clr	temp
	sts	dev_log,temp
	nop


	lds	temp,counter_power_off
	nop

	cpi	temp,0x96
	brlo	not_power_off_s	

	cpi	temp,0xff
	breq	not_inc_counter_power_off

	inc	temp

	cpi	temp,0xfe
	breq	save_flash_start

save_counter_power_off:

	sts	counter_power_off,temp
	nop
	rjmp	not_inc_counter_power_off

save_flash_start:

	rcall	save_set_flash;!!!!!!!!!!

	rjmp	save_counter_power_off

not_inc_counter_power_off:
	
not_power_off_s:

	inc	t0_table_step
	rjmp	end_t0



flash_to4ka:;----------------
	lds	temp,counter_power_off
	nop
	cpi	temp,0x96
	brsh	flash_dark

	inc	flash

	ldi	temp,0x93;147
	cp	flash,temp
	breq	flash_dark

	ldi	temp,0xdc;220
	cp	flash,temp
	breq	flash_light
	rjmp	nop_s
flash_dark:
	cbi	ddra,7
	rjmp	nop_s
flash_light:
	clr	flash
	sbi	ddra,7
	

nop_s:;------------------
inc	t0_table_step
rjmp	end_t0


led_h1_s:;----------------
	sbi	ddrb,0

	sbi	portb,1
	sbi	portb,2

	mov	temp,h1_seg
	rcall	seg_copy

	cbi	portb,0
	
	inc	t0_table_step
	rjmp	end_t0



key_scan_s:;-----------------
	sbrc	flags,7;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	rjmp	not_key_scan_s
	
	;sbrs	flags,3;key timeout en
	sbrs	flags,6;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
	rjmp	not_key_scan_s

	rcall	keyscan_pp



not_key_scan_s:

	inc	t0_table_step
	rjmp	end_t0


menu_s:;-------------------------
rcall	menu

inc	t0_table_step
rjmp	end_t0


led_h2_s:;----------------------------------
	
	sbi	ddrb,1

	sbi	portb,2
	sbi	portb,0

	mov	temp,h2_seg
	rcall	seg_copy

	cbi	portb,1

	inc	t0_table_step
	rjmp	end_t0



tem_scan_s:;-------------------------


	sbrc	flags,7;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	rjmp	not_tem_scan_s
	sbrc	flags,5
	rcall tsensscan_pp
not_tem_scan_s:
	;sbrs	flags,6	;	flip
	;rjmp	flip_tab_001

	inc	t0_table_step
	rjmp	end_t0

flip_tab_001:
	ldi	temp,0x8
	mov	t0_table_step,temp
	rjmp	end_t0

timer_1sec_s:;----------------------
	ldi	temp,0x5a;	; timer 05-1sec!!!
	cp	timer1sec,temp
	breq	endtimer1sec
	inc	timer1sec
endtimer1sec:

	inc	t0_table_step
	rjmp	end_t0



timer_beep_s:;----------------------

;sbr	flags,0x2;------- block sleep 

	ldi	temp,0xff
	cp	t_beep,temp
	breq	long_beep

	dec	temp

	cp	t_beep,temp ;0xfe
	breq	stop_beep

	inc	t_beep
	rjmp	long_beep

stop_beep:
	cbr	flags,0x2;------unblock sleep 
	cbi	ddrb,5
	
long_beep:
	inc	t0_table_step
	rjmp	end_t0






timer_outkey_s:;----------------30.12.12--------
	push	r16
	push	r17
	push	r19
	push	r20


	lds	r17,t_out_key2
	nop
	lds	r19,t_out_key3
	nop
;----------------verify
	lds	r16,timeout_key_lo
	nop	
	lds	r20,timeout_key_hi
	nop

	cp	r19,r20
	breq	next_s_00002
	rjmp	next_s_00001

next_s_00002:
	cp	r17,r16
	breq	timeout_ok
	rjmp	next_s_00001

;------------------

next_s_00001:

	lds	r16,t_out_key1
	nop
	
	cpi	r16,0xea;!!!!!corr time ms
	breq	next1

	inc	r16

	sts	t_out_key1,r16
	nop	

	rjmp	endtout

next1:
	clr	r16

	sts	t_out_key1,r16
	nop

	ldi	r16,0x01
	add	r17,r16
	clr	r16
	adc	r19,r16

	sts	t_out_key3,r19
	nop
	sts	t_out_key2,r17
	nop

	rjmp	endtout

;-----------------------

timeout_ok:

	cbr	flags,8 ;clear 3bit flags key timeout

	sbrs	flags,2;menu=0
	cbr	flags,0x40;block key scan
	
endtout:

	pop	r20
	pop	r19
	pop	r17
	pop	r16

	inc	t0_table_step
	rjmp	end_t0
	
led_h3_s:;-------------------------------
	;cbi	ddrb,6	;water sens konder. unlock 

	sbi	ddrb,2

	sbi	portb,1
	sbi	portb,0

	mov	temp,h3_seg
	rcall	seg_copy

	cbi	portb,2

	inc	t0_table_step
	rjmp	end_t0




water_scan_s:;-----------------------
	sbrc	flags,7;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	rjmp	not_water_scan_s
	sbrc	flags,4
	rcall water_scan_pp
not_water_scan_s:

	inc	t0_table_step
	rjmp	end_t0
	



displey_s:;-----------------------------------------------


	mov	temp,menu_step
	cpi	temp,0x00
	breq	tem_out_disp
	rjmp	menu_out_disp


tem_out_disp:					;-----------tem_displ
	cbr	flags,0x4; unblock sleep


	lds	temp,counter_power_off;power off
	nop
	cpi	temp,0x96
	brsh	blank_power_off



	sbrc	flags,3; key time 15sec
	rjmp	not_end_press_key_wait11

	
blank_power_off:
	ldi	temp,blank		; blank displ/ beep en/ sleep dis

	sts	tem_seg_h1,temp
	nop
	sts	tem_seg_h2,temp
	nop
	sts	tem_seg_h3,temp
	rjmp	next_disp00001

not_end_press_key_wait11:

;---------------

	lds	temp,code_battery;battery displ.
	nop
	cpi	temp,0x6d
	brsh	batgood0001	


	ldi	sym,0x12
	rcall	symvol
	mov	h1_seg,r0

	ldi	sym,0x13
	rcall	symvol
	mov	h2_seg,r0

	ldi	sym,0x11
	rcall	symvol
	mov	h3_seg,r0

	rjmp	jampend001

batgood0001:
next_disp00001:


push	r22

;-------h1
	lds	sym,tem_seg_h1
	rcall	symvol
	mov	h1_seg,r0
;-------h1 end


;----------h2
	lds	sym,tem_seg_h2
	rcall	symvol
	mov	temp,r0


	sbrs	flags,3
	rjmp	not_to4ka_tem_h2

	mov	r22,cili_t_cels
	cpi	r22,0x64
	brsh	not_to4ka_tem_h2
	sbrc	flags,0;farengeyt rjmp	not_to4ka_tem_h2!!!!!!!!!!!!!!
	rjmp	not_to4ka_tem_h2
	
	cbr	temp,0x80;to4ka
not_to4ka_tem_h2:
	mov	h2_seg,temp
;----------h2 end

;---------h3
	lds	sym,tem_seg_h3
	rcall	symvol
	mov	temp,r0


	sbrs	flags,3
	rjmp	not_to4ka_tem_h3

	mov	r22,cili_t_cels

	sbrc	flags,0;  farengeyt rjmp	to4ka_tem_h3!!!!!!!!!!!!!!
	rjmp	to4ka_tem_h3

	cpi	r22,0x64

	brlo	not_to4ka_tem_h3
to4ka_tem_h3:		
	cbr	temp,0x80;to4ka

not_to4ka_tem_h3:

	mov	h3_seg,temp
;---------h3 end



pop	r22

jampend001:
	rjmp	next00001

menu_out_disp:					;-------------menu_displ
	sbr	flags,0x4; block sleep

	lds	sym,menu_seg_h1
	rcall	symvol
	mov	h1_seg,r0

	lds	sym,menu_seg_h2
	rcall	symvol
	mov	h2_seg,r0

	lds	sym,menu_seg_h3
	rcall	symvol
	
	mov	temp,r0
	sbrc	flags,3
	rjmp	not_to4ka
	cbr	temp,0x80;to4ka
not_to4ka:
	mov	h3_seg,temp

next00001:
	inc	t0_table_step



	rjmp	end_t0



reset_t0_table:;------------------
;flip-------------------
;	sbrs	flags,6	
;	rjmp	flip_h2_1

;	rjmp not_flip_h2_1

;flip_h2_1:
	;sbrs	flags,5;tem
	;rjmp	flip_to_water

;	ldi	temp,0x08
;	mov	t0_table_step,temp
;	rjmp	end_t0

;flip_to_water:
;	ldi	temp,0x0b
;	mov	t0_table_step,temp
;	rjmp	end_t0

;not_flip_h2_1:
;--------------------------
	clr	t0_table_step

	rjmp	end_t0


end_t0:
	out	sreg,sreg_copy
	pop	sreg_copy	
	pop	temp
	
	reti



;-------------------------------ext int1------------------------------------
extint1:
wdr
push	temp
push	sreg_copy
in	sreg_copy,sreg

rcall	sleep_dis


	clr	temp	;reset timeout_key


	sts	t_out_key3,temp
	nop
	sts	t_out_key2,temp
	nop
	sts	t_out_key1,temp
	nop


	ldi	keyboard_code,0xa0;!!!!!!!!!!

	;ldi	flags,0x78	; flags reset
	;cbr	flags,0xff; 
	sbr	flags,0x28;	00101000

	clr	t0_table_step;!!!!!!!!!!!!!!!!!!!

	ldi	key_time_press,0x60;pause press key!!!!!!!!!!!!!!!!!!!


	lds	temp,counter_power_off; probuzdenie
	nop
	cpi	temp,0xff
	breq	ring
	rjmp	end_int1


ring:
	
;------?
	rcall	read_eeprom

	rcall	wdt_on
	
	rcall	start_test


end_int1:
	clr	temp
	sts	counter_power_off,temp

out	sreg,sreg_copy
pop	sreg_copy	
pop	temp
	reti


;----------------------------seg copy pp---------------------------------------

seg_copy:

push	sreg_copy
in	sreg_copy,sreg

;cbr	temp,0x4 ; !!!!! not pullup porta 2
out	porta,temp

sbrc	temp,2
rjmp	sbib2
cbi	portb,3
rjmp	endb2
sbib2:
sbi	portb,3
endb2:



out	sreg,sreg_copy
pop	sreg_copy	

ret

;-----------------------------------wdt_on pp--------------------------------------

wdt_on:
push	temp
push	sreg_copy
in	sreg_copy,sreg

	wdr
	ldi	temp,0x0d
	out	WDTCR,temp

	ldi	temp,restartwdt ;0X48 16 msec ,int en ;0X4d 500mSec
	out	WDTCR,temp
	wdr

out	sreg,sreg_copy
pop	sreg_copy
pop	temp
ret
;-----------------------------------wdt_off pp-------------------------------------

wdt_off:
push	temp
push	sreg_copy
in	sreg_copy,sreg
cli

wdr
	; Clear WDRF in MCUSR
ldi temp, (0<<WDRF)
out MCUSR, temp
	; Write logical one to WDCE and WDE
	; Keep old prescaler setting to prevent unintentional Watchdog Reset
in  temp, WDTCSR
ori temp, (1<<WDCE)|(1<<WDE)
out WDTCSR, temp
	; Turn off WDT
ldi temp, (0<<WDE)
out WDTCSR, temp
sei
nop
nop
out	sreg,sreg_copy
pop	sreg_copy
pop	temp
ret



;---------------------------------------keyscan pp--------------------------------
keyscan_pp:
push	temp
push	sreg_copy
in	sreg_copy,sreg

	;sbr	flags,0x40

	;sbrs	flags,6
	;rjmp	not_scan_pp

	ldi	temp,0x22;adc2 vref=vcc adlar=1
	out	admux,temp

	ldi	temp,0x0
	out	adcsrb,temp

	;ldi	temp,0x8e;/singl/  int on/ adc on/prescaler=64 /f=125kHz
	;out	adcsra,temp

	rjmp	end_scan_pp


;----------------------------------------tsensscan pp---------------------------
tsensscan_pp:
push	temp
push	sreg_copy
in	sreg_copy,sreg


	sbrs	flags,5
	rjmp	not_scan_pp	



	ldi	temp,0x87;adc7 vref=1.1v
	out	admux,temp
	ldi	temp,0x0
	out	adcsrb,temp
	;ldi	temp,0x8e;/singl/  int on/ adc on/prescaler=64 /f=125kHz
	;out	adcsra,temp
	

	rjmp	end_scan_pp


;------------------------------------------water_scan pp----------------------------
water_scan_pp:
push	temp
push	sreg_copy
in	sreg_copy,sreg


	sbrs	flags,4
	rjmp	not_scan_pp

	ldi	temp,0xa9;adc9 vref=2.5v adlar=1
	out	admux,temp
	ldi	temp,0x10
	out	adcsrb,temp
	;ldi	temp,0x8e;/singl/  int on/ adc on/prescaler=64 /f=125kHz
	;out	adcsra,temp

	rjmp	end_scan_pp



;------end_scan_pp--
not_scan_pp:
	

end_scan_pp:
out	sreg,sreg_copy
pop	sreg_copy
pop	temp
ret



;-----------------------------  adc_conv int--------------------------------------
adc_conv:

	push	temp
	push	sreg_copy
	in	sreg_copy,sreg
	
	lds	temp,counter_power_off
	nop
	cpi	temp,0x96
	brlo	next_adcc111
	rjmp	end_adcc

	next_adcc111:
;	wdr

	in	temp,admux

	cpi	temp,0x22
	breq	s_adc_key00
	cpi	temp,0x87
	breq	s_adc_temp00
	cpi	temp,0xa9
	breq	s_adc_water00
	cpi	temp,0xa2;adc2 vref=2,5v adlar=1 battery test
	breq	s_adc_battery00
	rjmp	end_adcc

s_adc_battery00:
;	in	temp,adcl
	in	temp,adch
;	ldi	temp,0x6f;!!!!!!!!!!!!!!!!!!test!
	sts	code_battery,temp
	nop

	cbr	flags,0x20;stop adc_tem + battery test

	sbr	flags,0x10 ;set bit 4(tem) waterscan en

	clr	temp
	sts	counter_adc,temp
	nop
	sts	code_templo_temp,temp
	nop
	sts	code_temphi_temp,temp
	nop

	ldi	temp,0x00
	out	admux,temp

	rjmp	end_adcc


s_adc_key00:
	rjmp	s_adc_key

s_adc_temp00:
;----------------------------
; power on segment
	sbi	ddra,0
	sbi	ddra,1
	sbi	ddrb,3
	sbi	ddra,3
	sbi	ddra,4
	sbi	ddra,5
	sbi	ddra,6
;----------------------------
	rjmp	s_adc_temp


s_adc_water00:
	rjmp	s_adc_water
	

s_adc_water:



	in	temp,adcl
	sts	code_waterlo,temp
	nop
	in	temp,adch
	;ldi	temp,0x8f;!!!!!!!!!!!!!!!!!!!!!!test
	sts	code_waterhi,temp
		
	nop
	cbr	flags,0x10
	;--------------------flags
	sbrc	flags,3;key time out
	rjmp	set_flags1; set keyb

	sbrc	flags,2;menu
	rjmp	set_flags1; set keyb

	sbrc	flags,1;beep
	rjmp	set_flags1; set keyb


	rjmp	set_flags2

set_flags1:
	sbr	flags,0x40 ;set bit 6
	rjmp	end_setflags


set_flags2:
	
	cbr	flags,0x40 ;unset bit 6 keyb
	rjmp	end_setflags

end_setflags:

	;-------------------


	rjmp	end_adcc


s_adc_temp:

push	r18
	push	r19
	push	r28
	push	r29



	in	r28,adcl
	in	r29,adch

;	ldi	r28,0x0;!!!!!!!!!!!!!!!!!!!!!!test
;	ldi	r29,0x1;!!!!!!!!!!!!!!!!!!!!!!!test


	lds	temp,corr0_temp
	nop

	cpi	r29,0x1
	brsh	corr_0_tem
	cp	r28,temp
	brsh	corr_0_tem
	clr	r28
	clr	r29

	rjmp	not_corr_0_tem

	;corr 0--------------------------
corr_0_tem:

	clr	r17
	sub   r28, temp ; Вычесть младший байт
	sbc   r29, r17

	;--------------------------------
not_corr_0_tem:

	lds	r18,code_templo_temp
	nop
	lds	r19,code_temphi_temp
	nop

	add	r18,r28
	adc	r19,r29

	lds	temp,counter_adc
	cpi	temp,0x3
	breq	end_counter_adc
	inc	temp
	sts	counter_adc,temp
	nop
	rjmp	next_counter_adc


end_counter_adc:

	;battery
;	cbr	flags,0x20;stop adc_tem

;	sbr	flags,0x10 ;set bit 4(tem) waterscan en

	
	sts	code_templo,r18
	nop
	sts	code_temphi,r19
	nop


	clr	temp
	sts	counter_adc,temp
	nop
	sts	code_templo_temp,temp
	nop
	sts	code_temphi_temp,temp
	nop

;battery
	ldi	temp,0xa2;adc2 vref=2,5v adlar=1
	out	admux,temp
	ldi	temp,0x10
	out	adcsrb,temp


	rjmp	exit_adc_tem

next_counter_adc:
	sts	code_templo_temp,r18
	nop
	sts	code_temphi_temp,r19
	nop

exit_adc_tem:

	pop	r29
	pop	r28
	pop	r19
	pop	r18

	rjmp	end_adcc


s_adc_key:

	lds	temp,key_pause_activ; pause keyboard
	nop
	cpi	temp,0x01
	brlo	next_adc_key00001

	rjmp	end_adcc

next_adc_key00001:

	;in	temp,adcl
	;sts	code_keylo,temp
	;nop
	in	temp,adch
	;ldi	temp,0xa0;!!!!!!!!!!!!!!!!!!!!!!test
	sts	code_keyhi,temp
	nop
	;cbr	flags,0x40

	;--------------------keyboard----------------
	lds	temp,code_keyhi
	nop
	
	cpi	temp,0x95
	brlo	key_activ

	clr	key_time_press

	ldi	keyboard_code,0xa0;!!!!!!

;----------------------------------23.12.12---
	ldi	temp,0x5f

	sts	key_povtor,temp
	nop
;---------------------------------------------	
	rjmp	end_adcc


key_activ:

	clr	temp
	sts	t_out_key1,temp
	nop
	sts	t_out_key2,temp
	nop
	sts	t_out_key3,temp
	nop
	sbrc	flags,3
	rjmp	not_reser_flags3
	sbr	flags,8
	ldi	key_time_press,0x60;pause press key
	;ldi	key_time_press,0x1;pause press key

	mov	temp,menu_step
	cpi	temp,0x00
	breq not_menu0002
	subi	temp,0x1	; menu back -1 step 
	mov	menu_step,temp
	ldi	key_time_press,0x60;pause press key!!!!!!!!!!!!!!!!!!!

not_menu0002:

not_reser_flags3:

	inc key_time_press




	cpi	key_time_press,0x08	;time  wait press
	breq	key_time_press_end 
;----------------------------------------------23.12.12---------------
	push	r18

	lds	r18,key_povtor
	nop

	cp	key_time_press,r18;0x5f;povtor  key
	breq	reset_key_time_press ;breq

	pop	r18
	
	rjmp	end_adcc

reset_key_time_press:


	cpi	r18,0x09
	breq	not_dec_key_povtor

;	push	r18
;	clr	r18
;	cp	menu_step,r18
;	breq	not_dec_key_povtor
;	pop	r18
	
	dec	r18
	dec	r18
	dec	r18
	dec	r18
	dec	r18
	dec	r18

	cpi	r18,0x0a
	brsh	next1000100
	ldi	r18,0x09
next1000100:

	sts	key_povtor,r18
	nop

not_dec_key_povtor:

	pop	r18

	clr	key_time_press
	rjmp	end_adcc

key_time_press_end:



	;clr	key_time_press;!!

	
	;---------------------------key select---------------
	lds	temp,code_keyhi
	nop
	cpi	temp,0x7d
	brlo	not_enter
	ldi	keyboard_code,0x82;enter
	rjmp	end_adcc_tik

not_enter:
	cpi	temp,0x71
	brlo	not_up
	ldi	keyboard_code,0x75;up

	ldi	temp,0x01
	cp	menu_step,temp
	brsh	not_far_cels_sw1

	ldi	temp,0x1
	eor	flags,temp
	;sbr	flags,1

not_far_cels_sw1:

	rjmp	end_adcc_tik

not_up:
	cpi	temp,0x65
	brlo	not_down
	ldi	keyboard_code,0x6a;down

	ldi	temp,0x01
	cp	menu_step,temp
	brsh	not_far_cels_sw2

	ldi	temp,0x1
	eor	flags,temp
	;cbr	flags,1

not_far_cels_sw2:

	rjmp	end_adcc_tik

not_down:
	cpi	temp,0x5c;0x5a
	brlo	not_back
	ldi	keyboard_code,0x5e;back


	lds	temp,wait3s_hi;block beep tik test mode
	cpi	temp,0xa9
	brsh	end_adcc


;------------beep pause



;cp	cili_t_cels,const_t_up 
;	brsh	start_pause_beep002

;cp	cili_t_cels,const_t_down
;	brlo	start_pause_beep002

;lds	r17,const_water
;	nop
;	lds	temp,code_waterhi
;	nop
;	cp	temp,r17
;	brlo	start_pause_beep002

;		rjmp	end_adcc_tik


;start_pause_beep002:
	;sbrs	flags,1
	;rjmp	not_pause_beep001

	ldi	temp,0x01;
	cp	menu_step,temp; no beep pause in menu
	brsh	not_pause_beep001;


	lds	temp,beep_pause;not duble beep pause
	cpi	temp,0x1e
	brlo	not_pause_beep001


;cbr	flags,0x2;unblock sleep
;sbr	flags,0x2;block sleep

	clr	temp
	sts	beep_pause,temp;beep pause start


not_pause_beep001:
;------------

	rjmp	end_adcc_tik


not_back:



	cpi	temp,0x45;0x30 4sw/  0x5f 2sw
	brlo	loop001
	ldi	keyboard_code,0xa0;!!!!!!!!!!!!!

	rjmp	end_adcc

loop001:
	cpi	temp,0x43;0x26 ;4sw
	brsh	sens_menu
	ldi	keyboard_code,0xa0;!!!!!!!!!!!!!	

;	;load beep error!!!!!!!!!!!!!!!!----
;	ldi	temp,0xe0; 
;	mov	t_beep,temp
;	ldi	temp,0xe0;2.5khz
;	mov	f_beep,temp

;	sbi	ddrb,5
	;--------------------------------------------

	rjmp	end_adcc

sens_menu:

	ldi	keyboard_code,0x43;0x27 2sw


	rjmp	end_adcc


end_adcc_tik:

	lds	temp,wait3s_hi;block beep tik test mode
	cpi	temp,0xa9
	brsh	end_adcc


;load beep tik!!!!!!!!!!!!!!!!----
	ldi	temp,0xfe; tik
	mov	t_beep,temp
	ldi	temp,0x90;1.5khz
	mov	f_beep,temp

	sbi	ddrb,5

end_adcc:

	
	lds	temp,dev_log; dev logik /4
	nop
	sbrs	temp,2
	rjmp	not_power_off_call

	rcall	power_off;!!!!

not_power_off_call:

	cbr	flags,0x80


	in	temp,admux
	cpi	temp,0xa2
	breq	end_0000001
		
	ldi	temp,0x00;battery
	out	admux,temp
	ldi	temp,0x06;adc 0x03off 
	out	adcsra,temp


end_0000001:
	out	sreg,sreg_copy
	pop	sreg_copy
	pop	temp

	reti





;-------------------------------------------sleep_en-------------------------

sleep_en:
push	temp
push	sreg_copy
in	sreg_copy,sreg

;	ports_sleep---
	clr	temp
	out	ddra,temp
	
	cbi	ddrb,0
	cbi	ddrb,1
	cbi	ddrb,2
	cbi	ddrb,3;!!!!!!!!!!!!!!!!!!!!
;----------------------

ldi	temp,0x80 ;int1 en/ int0 dis /intpin dis
out	gimsk,temp

ldi	temp,0x06; 0x03 adc off 
out	adcsra,temp

ldi	temp,0x70;0x70 ;int0 and int1 low / sleep power down/ pull dis 0x70
out	MCUCR,temp

out	sreg,sreg_copy
pop	sreg_copy
pop	temp
ret
;--------------------------------------sleep_dis--------------------------------
sleep_dis:
push	temp
push	sreg_copy
in	sreg_copy,sreg

ldi	temp,0x50 ;int0 and int1 low / sleep off /pull dis 0x50
out	MCUCR,temp

ldi	temp,0x00 ;int1 dis/ int0 dis /intpin dis
out	gimsk,temp

;	ports_wakeup----
	ldi	temp,0xfb
	out	ddra,temp


	sbi	ddrb,0
	sbi	ddrb,1
	sbi	ddrb,2
	sbi	ddrb,3;!!!!!!!!!!!!!!


;-----------------------

	ldi	temp,0x1e
	sts	beep_pause,temp;beep pause end


out	sreg,sreg_copy
pop	sreg_copy
pop	temp
ret


;--===================ADC*Vref========= MUX 16X16_pp===========================================


;***************************************************************************
;*
;* "mpy16u" - 16x16 Bit Unsigned Multiplication
;*
;* This subroutine multiplies the two 16-bit register variables 
;* mp16uH:mp16uL and mc16uH:mc16uL.
;* The result is placed in m16u3:m16u2:m16u1:m16u0.
;*  
;* Number of words	:14 + return
;* Number of cycles	:153 + return
;* Low registers used	:None
;* High registers used  :7 (mp16uL,mp16uH,mc16uL/m16u0,mc16uH/m16u1,m16u2,
;*                          m16u3,mcnt16u)	
;*
;***************************************************************************

;***** Subroutine Register Variables

;.def	mc16uL	=r16		;multiplicand low byte
;.def	mc16uH	=r17		;multiplicand high byte
;.def	mp16uL	=r18		;multiplier low byte
;.def	mp16uH	=r19		;multiplier high byte
;.def	m16u0	=r18		;result byte 0 (LSB)
;.def	m16u1	=r19		;result byte 1
;.def	m16u2	=r20		;result byte 2
;.def	m16u3	=r23		;result byte 3 (MSB)
;.def	mcnt16u	=r22		;loop counter


conv_adc_to_mV:

push	r16
push	r17
push	r18
push	r19
push	r20
push	r23;!!!
push	r24
push	sreg_copy
in	sreg_copy,sreg
push	r22



lds	mc16uL,code_templo
lds	mc16uH,code_temphi
;nop



lds	mp16uL,const_v_ref_lo;   ;0x35 Vref=1077mV / 0x4c Vref=1100mV
lds	mp16uH,const_v_ref_hi



	clr	m16u3		;clear 2 highest bytes of result
	clr	m16u2
	ldi	mcnt16u,16	;init loop counter
	lsr	mp16uH
	ror	mp16uL

m16u_1:	brcc	noad8		;if bit 0 of multiplier set
	add	m16u2,mc16uL	;add multiplicand Low to byte 2 of res
	adc	m16u3,mc16uH	;add multiplicand high to byte 3 of res
noad8:	ror	m16u3		;shift right result byte 3
	ror	m16u2		;rotate right result byte 2
	ror	m16u1		;rotate result byte 1 and multiplier High
	ror	m16u0		;rotate result byte 0 and multiplier Low
	dec	mcnt16u		;decrement loop counter
	brne	m16u_1		;if not done, loop more

	;mov	lo_tem,m16u0
	;mov	hi_tem,m16u1



;div 4
	lsr	m16u2
	ror	m16u1
	ror	m16u0

	lsr	m16u2
	ror	m16u1
	ror	m16u0



;div 4 (interpoly)
	lsr	m16u2
	ror	m16u1

	lsr	m16u2
	ror	m16u1

	;lsr	m16u2
	;ror	m16u1


	sts	mv_templo,m16u1
	nop

	sts	mv_temphi,m16u2
	nop
	



;----------------------conv_mv_dec7-------

.def	hi_tem =r16
.def	lo_tem =r17
.def	cili_t =r18
.def	drobni_t =r19
.def	seg1	=r23
.def	seg2	=r24


	lds	lo_tem,mv_templo
	nop
	lds	hi_tem,mv_temphi
	nop
	

	clr	cili_t
	clr	drobni_t
	clr	seg1
	clr	seg2



	cpi	lo_tem,0xc8
	brsh	dvisti
	cpi	lo_tem,0x64
	brsh	sto
	cpi	lo_tem,0x32
	brsh	polsta
	rjmp	start_lo_t


dvisti:
	ldi	r22,0xc8
	sub	lo_tem,r22
	ldi	r22,0x14
	add	cili_t,r22
	rjmp	start_lo_t


sto:
	ldi	r22,0x64
	sub	lo_tem,r22
	ldi	r22,0x0a
	add	cili_t,r22
	rjmp	start_lo_t


polsta:
	ldi	r22,0x32
	sub	lo_tem,r22
	ldi	r22,0x05
	add	cili_t,r22
	rjmp	start_lo_t



start_lo_t:	
	cpi	lo_tem,0xa
	brlo	end_lo_t
	subi	lo_tem,0xa
	inc	cili_t
	rjmp	start_lo_t
end_lo_t:
	add	drobni_t,lo_tem
	cpi	drobni_t,0xA
	brlo	drobni_t_end
	subi	drobni_t,0xA
	inc	cili_t
drobni_t_end:
	cpi	hi_tem,0x1
	brlo	hi_t_end
	dec	hi_tem

	;ldi	lo_tem,0xff

	ldi	lo_tem,0x6

	ldi	r22,0x19
	add	cili_t,r22

	rjmp	start_lo_t


hi_t_end:

                                                                           
;---------------------------------------


	mov	cili_t_cels,cili_t	;gradus celsija -cili! (reg=cili_t_cels)
	mov	desjati_cels,drobni_t ;gradus celsija -desjati (reg=desjati_cels)


;-----------------conv_dec7_to_segm---



	sbrs	flags,0
	rjmp	not_fareng_0002

	lds	cili_t,fareng_tem;fareng
	ldi	drobni_t,blank

not_fareng_0002:
;----------------
	cpi	cili_t,0x64
	brlo	low_100_grd_cels

back_100:
	cpi	cili_t,0x64
	brlo	not_100_grd_cels
	subi	cili_t,0x64
	inc	seg1
	rjmp	back_100
not_100_grd_cels:
	cpi	cili_t,0xa
	brlo	not_10_grd_cels
	subi	cili_t,0xa
	inc	seg2
	rjmp	not_100_grd_cels
not_10_grd_cels:

	sts	tem_seg_h1,seg1
	nop
	sts	tem_seg_h2,seg2
	nop
	sts	tem_seg_h3,cili_t;zalyshok vid cili > 100grd

	rjmp	end_pp_grad

;----------------
low_100_grd_cels:

	sts	tem_seg_h3,drobni_t
	nop

back_cili_t:
	cpi	cili_t,0xa
	brlo	cili_t_end
	inc	seg1
	subi	cili_t,0xa
	rjmp	back_cili_t

cili_t_end:

	sbrc	flags,0
	rjmp	fareng_seg_r

	sts	tem_seg_h2,cili_t
	nop           
	sts	tem_seg_h1,seg1
	nop
	rjmp	end_pp_grad

fareng_seg_r:

	sts	tem_seg_h1,drobni_t;fareng
	nop
	sts	tem_seg_h2,seg1
	nop
	sts	tem_seg_h3,cili_t
	nop
	
;---------------------------------
end_pp_grad:


;	cbr	flags,0x80;!!!!!!!!!!!!!!!!!!!!


pop	r22

out	sreg,sreg_copy
pop	sreg_copy

pop	r24
pop	r23
pop	r20
pop	r19
pop	r18
pop	r17
pop	r16

	ret

;--------------------tab_corr_tem--------------------------------------------------

;tab_corr_tem:
;.db	0, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 20, 21, 22, 24, 24, 25
 ;  0  1  2  3  4  5  6  7  8    9  10  11  12  13  14  15  16  17  18  19  20  21                                  
 ;  0  5  10 15 20 25 30 35 40  45  50  55  60  65  70  75  80  85  90  95  100 105                                       

;=====================================sym_table:============================


sym_table:


.DB	0XC0, 0Xf9, 0Xa4, 0Xb0, 0X99, 0X92, 0X82, 0Xf8, 0X80, 0X90, 0xff, 0x89, 0xcf, 0xc7, 0x86, 0x8e, 0xc8, 0xaf, 0xc6, 0x8b, 0xbf, 0x88, 0xa3, 0Xab
;    0,    1,    2,    3,    4,     5,    6,    7,   8,    9,   blank, H,    I,     L,   E,    F,    n,    r,     C,    h   minus  A    o_sm  n_sm

  
.equ	blank	= 0x0a
.equ	sym_H	= 0xb
.equ	sym_I	= 0xc
.equ	sym_L	= 0xd
.equ	sym_O	= 0x0
.equ	sym_S	= 0x5
.equ	sym_E	= 0xe
.equ	sym_F	= 0xf
.equ	sym_n	= 0x10
.equ	sym_r	= 0x11
.equ	sym_C	= 0x12
.equ	sym_h_	= 0x13
.equ	sym_minus	= 0x14
.equ	sym_A	=0x15
.equ	sym_o_small	=0x16
.equ	sym_n_small	=0x17


;----------------------------------------SYMVOL-------------------------------
SYMVOL:
PUSH	TEMP
push	sreg_copy
in	sreg_copy,sreg

clr	temp

	LDI	ZL, LOW (2*sym_table)
	LDI	ZH, HIGH(2*sym_table)
	 
	    ; Найти нужный символ
	ADD	ZL, SYM
	adc	ZH,temp
	 
	    ; Загрузить данные символа в R0
	LPM

out	sreg,sreg_copy
pop	sreg_copy
POP TEMP
RET
;--------------------------t1_int------------------------------------------
t1_int:

	push	sreg_copy
	in	sreg_copy,sreg


	out	tcnt1,f_beep; f= 12500/41 = 3048hz


	sbic	portb,5
	rjmp	pb5_off

	rcall	conv_adc_to_mV	;+	conv_mv_dec7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	sbi	portb,5
	rjmp	pb5_end

pb5_off:
	cbi	portb,5

	rcall	farengeyt_pp;!!!!!!!!!!
	
pb5_end:

end_t1_int:

	out	sreg,sreg_copy
	pop	sreg_copy

	reti




;---------------------menu---------------------------------------------------------------------
menu_t1:
.dw	start_menu, disp_hi, start_time_1sec, wait_end_time_1sec, copy_const_const_t_up, disp_out, menu_wait_key_code
.dw	save_const_t_up, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp;d12

.dw disp_lo, start_time_1sec, wait_end_time_1sec, copy_const_const_t_lo, disp_out, menu_wait_key_code
.dw save_const_t_down, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp;d23
;----------
.dw disp_si, start_time_1sec, wait_end_time_1sec, copy_const_delta_t, disp_out, menu_wait_key_code;1D (d29)
.dw save_const_delta_t, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp
;------------
.dw disp_se, start_time_1sec, wait_end_time_1sec, copy_const_water_sel, disp_out_water_sel, menu_wait_key_code
.dw save_const_water_sel, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp;d45

.dw	end_step_menu;2E (d46)

.dw disp_sec_blank, start_time_1sec

.dw disp_sec, start_time_1sec, wait_end_time_1sec, copy_const_water_sens, disp_out, menu_wait_key_code ;d54 
.dw save_const_water_sens, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp

.dw disp_cr0, start_time_1sec, wait_end_time_1sec, copy_const_corr_0, disp_out, menu_wait_key_code ;d65
.dw save_const_corr_0, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp

.dw disp_abs, start_time_1sec, wait_end_time_1sec, copy_const_corr_abs, disp_out, menu_wait_key_code;d76
.dw save_const_corr_abs, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp

.dw disp_time, start_time_1sec, wait_end_time_1sec, copy_const_time, disp_out_1, menu_wait_key_code;d87
.dw save_const_time, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp

.dw disp_postalarm, start_time_1sec, wait_end_time_1sec, copy_const_postalarm, disp_out, menu_wait_key_code;d98 11.09.13
.dw save_const_postalarm, blank_disp, start_time_1sec, wait_end_time_1sec, led_disp


.dw	end_step_menu1 ;end
;-------------------------------------------------



menu:
push	r19
push	r18
push	r17
PUSH	TEMP
push	sreg_copy
in	sreg_copy,sreg



mov	temp,menu_step
	cpi	temp,0x00
	breq	wait_enter
	rjmp	m_start

wait_enter:
	
	cpi	keyboard_code,0x82
	breq	m_start
	rjmp	end_menu

m_start:
	push	r20
	push	r21

	mov	R20,temp

	LSL	R20	; Сдвигом влево умножаем содержимое R20 на два.
			
 
	LDI	ZL, low(menu_t1*2)	; Загружаем адрес нашей таблицы. Компилятор сам посчитает
	LDI	ZH, High(menu_t1*2)	; Умножение и запишет уже результат.Старший и младший байты.
 
	CLR	R21		; Сбрасываем регистр R21 - нам нужен ноль.
	ADD	ZL, R20		; Складываем младший байт адреса. Если возникнет переполнение
	ADC	ZH, R21		; То вылезет флаг переноса. Вторая команда складывает
				; с учетом переноса. Поскольку у нас R21=0, то по сути
				; мы прибавляем только флаг переноса. 				
				 
 
	LPM	R20,Z+		; Загрузили в R20 адрес из таблицы
	LPM	R21,Z		; Старший и младший байт
 
 
	MOVW	 ZH:ZL,r21:r20		; забросили адрес в Z 

  pop	r21
  pop	r20

	IJMP	
	;-------------------------------------------

disp_postalarm:
	inc	temp;counter menu
	ldi	r17,sym_A
	sts	menu_seg_h1,r17

	ldi	r18,sym_L
	sts	menu_seg_h2,r18

	ldi	r17,sym_r
	sts	menu_seg_h3,r17

	clr	keyboard_code
	rjmp	end_menu
;-------------------
copy_const_postalarm:
	inc	temp

	lds	const_et,const_post_alarm
	nop
	mov	const,const_et

	rjmp	end_menu
;-------------------
save_const_postalarm:
	inc	temp;counter menu

	sts	const_post_alarm,const
	nop

	rjmp	end_menu
		
;-------------------------------------------



	;--------------------------------------
disp_time:
	inc	temp;counter menu
	ldi	r17,sym_C
	sts	menu_seg_h1,r17

	ldi	r18,sym_o_small
	sts	menu_seg_h2,r18

	ldi	r17,sym_n_small
	sts	menu_seg_h3,r17

	clr	keyboard_code
	rjmp	end_menu
;-------------------
copy_const_time:
	inc	temp;counter menu

	lds	const,timeout_key_lo
	nop
	sts	var_timeout_key_lo,const
	nop
	lds	const,timeout_key_hi
	nop
	sts	var_timeout_key_hi,const
	nop
	
	rjmp	end_menu
;-------------------

save_const_time:
	inc	temp;counter menu

	lds	const,var_timeout_key_lo
	nop
	sts	timeout_key_lo,const
	nop
	lds	const,var_timeout_key_hi
	nop
	sts	timeout_key_hi,const
	nop
	
	rjmp	end_menu
		
;-------------------------------------------


disp_abs:	
	inc	temp;counter menu
	ldi	r17,sym_C
	sts	menu_seg_h1,r17

	ldi	r18,sym_r
	sts	menu_seg_h2,r18

	ldi	r17,sym_A
	sts	menu_seg_h3,r17

	clr	keyboard_code
	rjmp	end_menu
;-------------------
copy_const_corr_abs:	
	lds	const_et,corr_abs;dubl_const
	nop
	mov	const,const_et
	inc	temp;counter menu
	rjmp	end_menu
;-------------------
save_const_corr_abs:
	inc	temp;counter menu
	sts	corr_abs,const
	nop
	rjmp	end_menu
		
	;-------------------------------------------
disp_cr0:
	inc	temp;counter menu
	ldi	r17,sym_C
	sts	menu_seg_h1,r17

	ldi	r18,sym_r
	sts	menu_seg_h2,r18

	ldi	r17,0x00
	sts	menu_seg_h3,r17

	clr	keyboard_code
	rjmp	end_menu
;-------------------
copy_const_corr_0:
	lds	const_et,corr0_menu;dubl_const
	nop
	mov	const,const_et
	inc	temp;counter menu
	rjmp	end_menu
;-------------------
save_const_corr_0:
	inc	temp;counter menu
	sts	corr0_menu,const
	nop
	rjmp	end_menu

	;------------------------------------------
disp_si:
	inc	temp;counter menu
	ldi	r17,sym_S
	sts	menu_seg_h1,r17

	ldi	r18,sym_I
	sts	menu_seg_h2,r18

	ldi	r17,blank
	sts	menu_seg_h3,r17

	clr	keyboard_code
	rjmp	end_menu

	;--------------

copy_const_delta_t:
	lds	const_et,delta_t;dubl_const
	nop
	mov	const,const_et
	inc	temp;counter menu
	rjmp	end_menu

save_const_delta_t:
	inc	temp;counter menu
	sts	delta_t,const
	nop
	rjmp	end_menu
	;---------------------------------------

disp_sec_blank:
	inc	temp;counter menu

	ldi	r18,blank

	sts	menu_seg_h1,r18
	nop
	sts	menu_seg_h2,r18
	nop
	sts	menu_seg_h3,r18

	clr	keyboard_code

	rjmp	end_menu

disp_sec:;--------------
	inc	temp;counter menu

	ldi	r17,sym_S
	sts	menu_seg_h1,r17

	ldi	r18,sym_E
	sts	menu_seg_h2,r18

	ldi	r17,sym_n
	sts	menu_seg_h3,r17

	clr	keyboard_code

	rjmp	end_menu
;--------------------------

copy_const_water_sens:


	lds	const_et,const_water;dubl_const
	mov	const,const_et
	inc	temp
	rjmp	end_menu



save_const_water_sens:

	inc	temp
	sts	const_water,const
	rjmp	end_menu


start_menu:


	inc	temp
	rjmp	end_menu


disp_hi:
inc	temp;counter menu

ldi	r17,sym_H
sts	menu_seg_h1,r17

ldi	r18,sym_I
sts	menu_seg_h2,r18

ldi	r17,blank
sts	menu_seg_h3,r17

clr	keyboard_code

	rjmp	end_menu


start_time_1sec:
	ldi	r17,0x1
	sts	key_pause_activ,r17;pause keyboard on

	inc	temp;counter menu
	clr	r17
	mov	timer1sec,r17
	rjmp	end_menu


wait_end_time_1sec:;----------------------------------
	mov	r17,timer1sec
	cpi	r17,0x5a
	brsh	next_menu001
	rjmp	end_menu
next_menu001:
	clr	r17
	sts	key_pause_activ,r17;pause keyboard off

	inc	temp;counter menu
	rjmp	end_menu

copy_const_const_t_up:;----------------------------
	mov	const_et,const_t_up;dubl_const
	mov	const,const_t_up
	inc	temp
	rjmp	end_menu


disp_out_1:;--------------time 999 sec---------------23.12.12------------
	inc	temp;counter menu


	lds	r17,var_timeout_key_hi;---------------hi
	nop

	push	r19;h1
	push	r20;h2
	push	r23;h3

v_t_k_hi:

	cpi	r17,0x01
	brlo	set_displ000
	cpi	r17,0x01
	breq	set_displ001
	cpi	r17,0x02
	breq	set_displ002
	cpi	r17,0x03
	breq	set_displ003

	rjmp	v_t_k_lo


set_displ000:

	;ldi	r17,0x0
;	sts	menu_seg_h1,r17
;	nop
;	sts	menu_seg_h2,r17
;	nop
;	sts	menu_seg_h3,r17
;	nop

	ldi	r19,0x00
	ldi	r20,0x00
	ldi	r23,0x00


	rjmp	v_t_k_lo



set_displ001:

	ldi	r19,0x02
	ldi	r20,0x05
	ldi	r23,0x06

	rjmp	v_t_k_lo

set_displ002:

	ldi	r19,0x05
	ldi	r20,0x01
	ldi	r23,0x02
	
	rjmp	v_t_k_lo

set_displ003:

	ldi	r19,0x07
	ldi	r20,0x06
	ldi	r23,0x08

	rjmp	v_t_k_lo

v_t_k_lo:

	;-------------------------------------lo-

	lds	r17,var_timeout_key_lo
	nop


	clr	r18

menu_seg1_999:

	cpi	r17,0x64
	brlo	menu_seg2_999

	subi	r17,0x64

	inc	r18

	rjmp	menu_seg1_999

menu_seg2_999:
	
	add	r19,r18; h1 + r18


	clr	r18

menu_seg2_999_loop:

	cpi	r17,0x0a
	brlo	menu_seg3_999
	subi	r17,0x0a

	inc	r18

	rjmp	menu_seg2_999_loop



menu_seg3_999:


	add	r20,r18 ; h2 + r18

	cpi	r20,0x0a
	brsh	over1_0x0a	

	rjmp	next_menu_seg3_999

over1_0x0a:

	subi	r20,0x0a
	inc	r19 ;h1 +1

next_menu_seg3_999:

	add	r23,r17 ; h3 + r17
	cpi	r23,0x0a
	brsh	over2_0x0a
	
	rjmp	save_menu_seg123


	
over2_0x0a:

	subi	r23,0x0a;h3

	inc	r20;h2

	cpi	r20,0x0a
	brsh	over3_0x0a

	rjmp	save_menu_seg123

over3_0x0a:
	subi	r20,0x0a
	inc	r19
	
	rjmp	save_menu_seg123


save_menu_seg123:

	sts	menu_seg_h1,r19

	sts	menu_seg_h2,r20

	sts	menu_seg_h3,r23



	pop	r23
	pop	r20
	pop	r19

	
	rjmp	end_menu



	

disp_out:;------------------------------------------

	inc	temp;counter menu

	ldi	r17,0x0a ;  ===================17.10.2012   blank
	sts	menu_seg_h1,r17
	nop
	ldi	r17,0x00
	sts	menu_seg_h2,r17
	nop
	sts	menu_seg_h3,r17
	nop

	mov	r17,const



;===================================17.10.2012============================
	cpi	r17,0x65
	brlo	menu_seg1

	ldi	r18,sym_minus
	sts	menu_seg_h1,r18
	nop

	neg	r17; !!!
	rjmp	menu_seg2


;=========================================================================
menu_seg1:
	clr	r18

menu_seg1_1:
	cpi	r17,0x64
	brlo	menu_seg2


	

;const_100:

	subi	r17,0x64

	;lds	r18,menu_seg_h1
	;nop
	inc	r18
	
	sts	menu_seg_h1,r18

	rjmp	menu_seg1_1

menu_seg2:
	cpi	r17,0x0a
	brlo	menu_seg3
	subi	r17,0x0a

	lds	r18,menu_seg_h2
	nop
	inc	r18
	sts	menu_seg_h2,r18
	nop
	rjmp	menu_seg2
menu_seg3:
	sts	menu_seg_h3,r17
	nop
	rjmp	end_menu




menu_wait_key_code:;---------------------------------

	sbrc	flags,3	; time key out - blank displ
	rjmp	not_blank_displ1

	ldi	r17,blank
	sts	menu_seg_h1,r17
	nop
	sts	menu_seg_h2,r17
	nop
	sts	menu_seg_h3,r17

	;counter menu timeout, to end menu------------------
	push	r17
	push	r16


	lds	r17,wait_menu_out_time_hi
	lds	r16,wait_menu_out_time_lo
	nop

	subi	r16,0x1
	sbci	r17,0x0

	cpi	r17,0xe2;~30sec!!!
	breq	menu_out
	rjmp	save_wait_count


menu_out:
	pop	r16;!!!!

	clr	r16;!!!!clr menu step

	push	r16;!!!


	ser	r16
	ser	r17

	rjmp	save_wait_count


save_wait_count:
	sts	wait_menu_out_time_hi,r17
	sts	wait_menu_out_time_lo,r16
	nop

	pop	r16
	pop	r17

	;--------------------------------------------------

	rjmp	end_menu


not_blank_displ1:


	cpi	keyboard_code,0x82
	breq	enter_menu_01
	cpi	keyboard_code,0x75
	breq	up_menu_01
	cpi	keyboard_code,0x6a
	breq	down_menu_01
	cpi	keyboard_code,0x5e
	breq	back_menu_01

	rjmp	end_menu


enter_menu_01:
	rjmp	enter_menu

up_menu_01:
	rjmp	up_menu

down_menu_01:
	rjmp	down_menu

back_menu_01:
	rjmp	back_menu




enter_menu:;---------
	clr	keyboard_code


;------------------------------25.12.12---------------
	push	r17
	ldi	r17,0x56
	cp	menu_step,r17
	breq	menu_enter_time
	pop	r17
;-----------------------------------------------------------

	cp	const_et,const
	breq	next_step
	inc	temp

	rjmp	end_menu

next_step:
	ldi	r18,0x6 ;
	add	temp,r18;

	rjmp	end_menu


;------------------------------29.12.12---------------
menu_enter_time:
	pop	r17

	push	r17
	push	r19
	push	r20

	lds	r19,var_timeout_key_lo
	lds	r20,timeout_key_lo
	nop

	cp	r19,r20
	breq	verif_000001

	rjmp	next_00000200

verif_000001:
	lds	r19,var_timeout_key_hi
	lds	r20,timeout_key_hi
	nop

	cp	r19,r20
	breq	next_00000201

next_00000200:

	inc	temp

	pop	r20
	pop	r19
	pop	r17

	rjmp	end_menu

next_00000201:

	pop	r20
	pop	r19
	pop	r17

	ldi	r18,0x6 ;
	add	temp,r18;

	rjmp	end_menu


;---------------------------------------------------

up_menu:;--------------
			;--------------------------------



push	r17
	ldi	r17,0x1c
	cp	menu_step,r17
	breq	menu_up_si

	ldi	r17,0x4b
	cp	menu_step,r17
	breq	menu_up_corr_a

	ldi	r17,0x40
	cp	menu_step,r17
	breq	menu_up_corr_0


	ldi	r17,0x56
	cp	menu_step,r17
	breq	menu_up_time

	ldi	r17,0x61 ;menu step postalarm
	cp	menu_step,r17
	breq	menu_step_postalr

	pop	r17

	rjmp not_menu_up_si


menu_step_postalr:

	pop	r17

	mov	r19,const
	cpi	r19,0x3c ; +60
	breq	skip_inc
	rjmp	inc_const_up001



menu_up_time:

	pop	r17
;-----------------------------------29.12.12
	push	r17
	push	r19
	push	r20

	ldi	r17,0x01

	lds	r19,var_timeout_key_lo
	lds	r20,var_timeout_key_hi

	cpi	r19,0xe7
	breq	verif_hi

	rjmp	next_00001111

verif_hi:
	cpi	r20,0x03
	breq	next_0000111

next_00001111:

	add	r19,r17

	clr	r17
	adc	r20,r17

	sts	var_timeout_key_hi,r20
	sts	var_timeout_key_lo,r19

next_0000111:	
		

	pop	r20
	pop	r19
	pop	r17
;--------------------------------------
	clr	keyboard_code
	
	subi	temp,0x1
	rjmp	end_menu

menu_up_corr_0:

	pop	r17


	mov	r19,const
	cpi	r19,0x0a ; +10
	breq	skip_inc
	rjmp	inc_const_up001


menu_up_corr_a:	
	pop	r17


	mov	r19,const
	cpi	r19,0x0f ; +15
	breq	skip_inc
	rjmp	inc_const_up001


menu_up_si:
	pop	r17
	
	mov	r19,const
	cpi	r19,0x63
	breq	skip_inc
	rjmp	inc_const_up001


not_menu_up_si:
			;---------------------------------



	mov	r19,const
	cpi	r19,0x64	;up 100 grd. cels.
	breq	skip_inc

inc_const_up001:

	inc	const
skip_inc:
	clr	keyboard_code
	
	subi	temp,0x1
	rjmp	end_menu
down_menu:;-------------

;========================================17.10.2012====================
push	r17
	ldi	r17,0x1c
	cp	menu_step,r17
	breq	menu_down_si

	ldi	r17,0x4b
	cp	menu_step,r17
	breq	menu_down_corr_a

	ldi	r17,0x40
	cp	menu_step,r17
	breq	menu_down_corr_0

	ldi	r17,0x56
	cp	menu_step,r17
	breq	menu_down_time

pop	r17
	rjmp not_menu_down_si


menu_down_time:
	pop	r17

;-----------------------------------29.12.12
	push	r17
	push	r19
	push	r20

	ldi	r17,0x01

	lds	r19,var_timeout_key_lo
	lds	r20,var_timeout_key_hi

	cpi	r19,0x02
	brsh	next_000100
	cpi	r20,0x00
	breq	next_000101


next_000100:
	sub	r19,r17

	clr	r17
	sbc	r20,r17

	sts	var_timeout_key_hi,r20
	sts	var_timeout_key_lo,r19

next_000101:		

	pop	r20
	pop	r19
	pop	r17
;--------------------------------------

	clr	keyboard_code
	subi	temp,0x1
	rjmp	end_menu


menu_down_corr_0:
pop	r17

	mov	r19,const
	cpi	r19,0xf6 ;  -10
	breq	skip_dec
	rjmp	dec_const_down001



menu_down_corr_a:
pop	r17

	mov	r19,const
	cpi	r19,0xf1 ;  -15
	breq	skip_dec
	rjmp	dec_const_down001
	

	
menu_down_si:
pop	r17

	mov	r19,const
	cpi	r19,0x9d ;  -99
	breq	skip_dec
	rjmp	dec_const_down001

not_menu_down_si:

	mov	r19,const
	cpi	r19,0x01
	brlo	skip_dec

dec_const_down001:
;=======================================================================
	dec	const

skip_dec:
	clr	keyboard_code
	subi	temp,0x1
	rjmp	end_menu


back_menu:;------------------------------------------------
	clr	keyboard_code

	ldi	key_time_press,0x60;pause key!!!!!!!!!!!!!


	;------------------------------25.12.12---------------
	push	r17
	ldi	r17,0x56
	cp	menu_step,r17
	breq	menu_back_time
	pop	r17
;-----------------------------------------------------------


	cp	const_et,const
	breq	exit_menu

	subi	temp,0x02

	rjmp	end_menu

;------------------------------29.12.12---------------
menu_back_time:
	pop	r17
	
	push	r17
	push	r19
	push	r20

	lds	r19,var_timeout_key_lo
	lds	r20,timeout_key_lo
	nop

	cp	r19,r20
	breq	verif_000002

	rjmp	next_00000300

verif_000002:
	lds	r19,var_timeout_key_hi
	lds	r20,timeout_key_hi
	nop
	cp	r19,r20
	breq	next_00000301


next_00000300:

	subi	temp,0x02

	pop	r20
	pop	r19
	pop	r17

	rjmp	end_menu

next_00000301:
	pop	r20
	pop	r19
	pop	r17

	rjmp	exit_menu

;-----------------------------------------------------------

exit_menu:

	ldi	temp,0x1e	
	sts	beep_pause,temp;beep pause stop

	

	clr	temp
	rjmp	end_menu

save_const_t_up:;------------------

	inc	temp
	mov	const_t_up,const
	rjmp	end_menu


save_const_t_down:

	inc	temp
	mov	const_t_down,const
	rjmp	end_menu



disp_lo:;---------------------------

inc	temp;counter menu

ldi	r17,sym_L
sts	menu_seg_h1,r17

ldi	r18,0x0
sts	menu_seg_h2,r18

ldi	r17,blank
sts	menu_seg_h3,r17

clr	keyboard_code

	rjmp	end_menu

copy_const_const_t_lo:;--------------------------------
	mov	const_et,const_t_down;dubl_const
	mov	const,const_t_down
	inc	temp
	rjmp	end_menu
	

disp_se:;---------------------------------

inc	temp;counter menu

ldi	r17,0x5
sts	menu_seg_h1,r17

ldi	r18,sym_E
sts	menu_seg_h2,r18

ldi	r17,blank
sts	menu_seg_h3,r17

clr	keyboard_code

	rjmp	end_menu

copy_const_water_sel:;----------------------------
	inc	temp;counter menu

	mov	const_et,water_sel;dubl_const
	mov	const,water_sel

	rjmp	end_menu


disp_out_water_sel:;---------------------------------
	inc	temp
	mov	r17,const
	clr	keyboard_code

	cpi	r17,0x01
	breq	plus_r17

	cpi	r17,0x04
	breq	minus_r17

	rjmp	end_cor

plus_r17:
	inc	r17
	inc	r17;!!!!!!!!!! koljco
	rjmp	end_cor_w
minus_r17:
	dec	r17
	dec	r17;!!!!!!!!!! koljco
	rjmp	end_cor_w

end_cor_w:
	mov	const,r17

end_cor:
	push	r16
	ldi	r16,0x1
	cp	code_water_test,r16
	brsh	error_w_sensor
	pop	r16

	cpi	r17,0x3
	breq	water_sel_on
	cpi	r17,0x2
	breq	water_sel_off


error_w_sensor:
	pop	r16

	ldi	r17,0x2
	mov	const,r17; w sens = off

	ldi	r17,sym_E
	sts	menu_seg_h1,r17

	ldi	r18,0x0
	sts	menu_seg_h2,r18

	mov	r17,code_water_test
	sts	menu_seg_h3,r17

	rjmp	end_menu

water_sel_on:

	ldi	r17,0x0
	sts	menu_seg_h1,r17

	ldi	r18,sym_n
	sts	menu_seg_h2,r18

	ldi	r17,blank
	sts	menu_seg_h3,r17

	rjmp	end_menu

water_sel_off:

	ldi	r17,0x0
	sts	menu_seg_h1,r17

	ldi	r18,sym_F
	sts	menu_seg_h2,r18

	ldi	r17,sym_F
	sts	menu_seg_h3,r17

	rjmp	end_menu


save_const_water_sel:;----------------------------------
	inc	temp
	mov	water_sel,const
	
	rjmp	end_menu


blank_disp:;---------------------------------------------
	inc	temp

	ldi	r17,blank
	sts	menu_seg_h1,r17
	nop
	sts	menu_seg_h2,r17
	nop
	sts	menu_seg_h3,r17

	rjmp	end_menu

led_disp:;----------------------------------------------
	subi	temp,0x07

	rjmp	end_menu


end_step_menu:;-----------------------------------------
	
	ldi	temp,0x1e	
	sts	beep_pause,temp;beep pause stop

	ldi	key_time_press,0x60;pause key!!!!!!!!!!!!!

	ldi	temp,0x01 ;loop of menu  -------------------------------03.12.12
;	clr	temp
	rjmp	end_menu

end_step_menu1:;-----------------------------------------
	
	ldi	temp,0x1e	
	sts	beep_pause,temp;beep pause stop

	ldi	key_time_press,0x60;pause key!!!!!!!!!!!!!

	ldi	temp,0x30;loop  of secret menu  -------------------------------03.12.12
;	clr	temp
	rjmp	end_menu

end_menu:;---------------------------------------------
	mov	menu_step,temp	;!!!!!!!!!


out	sreg,sreg_copy
pop	sreg_copy
POP TEMP
pop	r17
pop	r18
pop	r19


ret
;-------------menu end----------------------------------------------------------------------


;--------------------power off -----------

power_off:

PUSH	TEMP
push	sreg_copy
in	sreg_copy,sreg


	mov	temp,menu_step
	cpi	temp,0x01
	brsh	not_power_off

	lds	temp,counter_power_off
	nop
	cpi	temp,0x96
	brsh	power_off_end

	cpi	keyboard_code,0x5e
	breq	power_off_counter

	rjmp	not_power_off

power_off_counter:
	
	inc	temp
	sts	counter_power_off,temp
	nop
	rjmp	power_off_end

not_power_off:
	clr	temp
	sts	counter_power_off,temp

power_off_end:



out	sreg,sreg_copy
pop	sreg_copy
POP TEMP

ret

;-----------------------------

;---------------------------farengeyt_pp-------------------------------------
farengeyt_pp:
	
	push	r16
	push	r17
	push	r18
	push	r19
	push	r20
	push	r23
	push	r22
	push	sreg_copy
	in	sreg_copy,sreg


	.def	desjt =r17
	.def	desjaty =r18
	.def	cili_c_lo =R19
	.def	cili_c_hi =R20	
	

	mov	cili_c_lo,cili_t_cels
	mov	desjaty,desjati_cels 

	clr	temp
	clr	cili_c_hi

backdes001:
	cpi	temp,0x8
	breq	stopadd_a
	ADD	desjaty,desjati_cels
	inc	temp
	rjmp	backdes001


stopadd_a:	
	clr	desjt	

div_10:
	cpi	desjaty,0xa
	brlo	enddiv10
	subi	desjaty,0xa
	inc	desjt
	rjmp	div_10

enddiv10:
;mux8
	mov	temp,cili_c_lo

	lsl	cili_c_lo
	rol	cili_c_hi
	lsl	cili_c_lo
	rol	cili_c_hi
	lsl	cili_c_lo
	rol	cili_c_hi

	add	cili_c_lo,temp
	brcc	end_mux9;!!!!!!!!!!!!
	inc	cili_c_hi

end_mux9:


	add	cili_c_lo,desjt
	brcc	end_cil_add_des;!!!!!!!!!!!!
	inc	cili_c_hi

end_cil_add_des:

;------------div 5---------------------


	clr	temp ;rezultat
	clr	r17


	cpi	cili_c_lo,0xC8
	brlo	back_lo_000
	subi	cili_c_lo,0xc8
	ldi	r23,0x28
	add	temp,r23
	rjmp	back_lo_001

back_lo_000:

	cpi	cili_c_lo,0x64
	brlo	back_lo_001
	subi	cili_c_lo,0x64
	ldi	r23,0x14
	add	temp,r23


back_lo_001:
	cpi	cili_c_lo,0x5
	brlo	low5
	subi	cili_c_lo,0x5
	inc	temp
	rjmp	back_lo_001

low5:
	add	r17,cili_c_lo
back_low5_1:
	cpi	r17,0x5
	brlo	next_hi_0001
	subi	r17,0x5
	inc	temp
	rjmp	back_low5_1

next_hi_0001:
	cpi	cili_c_hi,0x01
	brlo	far_end
	subi	cili_c_hi,0x01

	;ldi	m16u0,0xff
	ldi	r23,0x33
	ldi	cili_c_lo,0x1

	add	temp,r23
	rjmp	back_lo_001


far_end:
	cpi	cili_c_lo,0x1a; OKRUGL
	brlo	not_add_1
	
	INC	TEMP

not_add_1:

	ldi	r17,0x20
	add	temp,r17 ;+32

	sts	fareng_tem,temp

	out	sreg,sreg_copy
	pop	sreg_copy
	pop	r22
	pop	r23
	pop	r20
	pop	r19
	pop	r18
	pop	r17
	pop	r16


	ret




;--------------------------------write flash--------------------------------------------

save_set_flash:

	wdr



	push	r16
	push	r17
	push	r18
	push	r19
	push	sreg_copy
	in	sreg_copy,sreg

	lds	temp,code_battery
	nop
	cpi	temp,0x6d
	brlo	not_save_glob
	rjmp	save_flash_glob

not_save_glob:
	rjmp	not_save_flash
save_flash_glob:

	
EEPROM_write:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x05 ;tem up!!!!!!!!!!!!!
	out EEARL, r17
; Write data (r19) to data register
	out EEDR, const_t_up
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE

	EEPROM_write_001:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_001
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x06 ;tem down!!!!!!!!!!!
	out EEARL, r17
; Write data (r19) to data register
	out EEDR, const_t_down
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE

ldi	temp,0x01
cp	code_water_test,temp ; not save water_sel (error water)
brsh	not_save_water_sel		

EEPROM_write_002:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_002
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x04	;water se!!!!!!
	out EEARL, r17
; Write data (r19) to data register
	out EEDR, water_sel
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE

not_save_water_sel:;!!!


EEPROM_write_003:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_003
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x02	;sensitive!!!!!!!!!!!
	out EEARL, r17
; Write data (r19) to data register
	lds	r19,const_water
	nop
	out EEDR, r19
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE


EEPROM_write_004:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_004
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x07	;si delta_t
	out EEARL, r17
; Write data (r19) to data register
	lds	r19,delta_t
	nop
	out EEDR, r19
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE




	EEPROM_write_corr_0:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_corr_0
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x08 ;corr_0
	out EEARL, r17
; Write data (r19) to data register
	lds	r19,corr0_menu
	nop
	out EEDR, r19
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE





	EEPROM_write_corr_a:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_corr_a
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x09 ;corr_a
	out EEARL, r17
; Write data (r19) to data register 
	lds	r19,corr_abs
	nop
	out EEDR, r19
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE

;----------------------29.12.12----------

	EEPROM_write_timeout_key_lo:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_timeout_key_lo
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x0a ;timeout_key_lo
	out EEARL, r17
; Write data (r19) to data register 
	lds	r19,timeout_key_lo
	nop
	out EEDR, r19
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE


		EEPROM_write_timeout_key_hi:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_timeout_key_hi
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x0b ;timeout_key_hi
	out EEARL, r17
; Write data (r19) to data register 
	lds	r19,timeout_key_hi
	nop
	out EEDR, r19
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE

EEPROM_write_const_post_alarm:
; Wait for completion of previous write
	sbic EECR,EEPE
	rjmp EEPROM_write_const_post_alarm
; Set Programming mode
	ldi r16, (0<<EEPM1)|(0<<EEPM0)
	out EECR, r16
; Set up address (r18:r17) in address register
	clr	r18
	out EEARH, r18
	ldi	r17,0x0c	;sensitive!!!!!!!!!!!
	out EEARL, r17
; Write data (r19) to data register
	lds	r19,const_post_alarm
	nop
	out EEDR, r19
; Write logical one to EEMPE
	sbi EECR,EEMPE
; Start eeprom write by setting EEPE
	sbi EECR,EEPE

not_save_flash:


	out	sreg,sreg_copy
	pop	sreg_copy
	pop	r19
	pop	r18
	pop	r17
	pop	r16

	ret
;-------------------------------------------------------------------------------


;--------------------------------------------------------set_default-------------------
set_default:
	push	sreg_copy
	in	sreg_copy,sreg



	rcall	read_eeprom

	clr	temp
	;sts	corr0_menu,temp

	mov	const_t_down,temp;const t down =0(off)
	
	ldi	temp,0x28;const t up =40 grad.
	mov	const_t_up,temp

	;sts	const_water,temp;sensitive water =0x28(40)
	;nop

	ldi	temp,0x03
	mov	water_sel,temp



; ;--Vref read eeprom-------------
;	clr	temp
;	out	eearh,temp

;	out	eearl,temp
;	sbi EECR,EERE
;	in	temp,eedr
;	;ldi	temp,0x04;!!!!!!!!!!!!!test
;	sts	const_v_ref_hi,temp


;	ldi	temp,0x01
;	out	eearl,temp
;	sbi EECR,EERE
;	in	temp,eedr
;	;ldi	temp,0x30;!!!!!!!!!!!!!test
;	sts	const_v_ref_lo,temp

;-----;const corr0 ADC----------------
;	ldi	temp,0x03
;	out	eearl,temp
;	sbi EECR,EERE
;	in	temp,eedr
;	ldi	temp,0x09;!!!!!!!!!!!!!test

;	sts	corr0_temp,temp
;	nop
;----------------------------------------
	out	sreg,sreg_copy
	pop	sreg_copy

	ret
;------------------------------------------------------------------------



;-----------------------------------------awakening and read EEPROM ------------------------------------------------
read_eeprom:
	push	sreg_copy
	in	sreg_copy,sreg

	push	temp


;---------const_post_alarm  -
	ldi	temp,0x0c
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr

	sts	const_post_alarm,temp
	nop

;-----const time out key

	ldi	temp,0x0a
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr

	sts	timeout_key_lo,temp
	nop

	ldi	temp,0x0b
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr

	sts	timeout_key_hi,temp
	nop


	
;-----;const corr_abs
	ldi	temp,0x09
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr

	sts	corr_abs,temp
	nop
;-----------------------



;----------Vref read----
	clr	temp
	out	eearh,temp

	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
	;ldi	temp,0x04;!!!!!!!!!!!!!test
	sts	const_v_ref_hi,temp


	ldi	temp,0x01
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
	;ldi	temp,0x30;!!!!!!!!!!!!!test

push	r17
	lds	r17,corr_abs ;
	nop
	cpi	r17,0x0f
	brlo	positive_corr_abs
	neg	r17
	sub	temp,r17
	rjmp	end_corr_abs

positive_corr_abs:

	add	temp,r17
end_corr_abs:

pop	r17


	sts	const_v_ref_lo,temp
	nop
;---------------------

;--;sensitive water sensor
	ldi	temp,0x02
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
;	ldi	temp,0x2;!!!!!!!!!!!!!test
	sts	const_water,temp
	nop
;--------------------



;-----;const corr0 menu
	ldi	temp,0x08
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr

	sts	corr0_menu,temp
	nop
;-----------------------


;-----;const corr0 ADC
	ldi	temp,0x03
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
;	ldi	temp,0x09;!!!!!!!!!!!!!test

push	r17
	lds	r17,corr0_menu ;
	nop
	cpi	r17,0x0f
	brlo	positive_corr_0
	neg	r17
	add	temp,r17
	rjmp	end_corr_0

positive_corr_0:

	sub	temp,r17
end_corr_0:

pop	r17

	sts	corr0_temp,temp

	nop
;-----------------

;-------water_sel-------
	ldi	temp,0x04
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
	mov	water_sel,temp
;--------------------

;-------tem_up-------
	ldi	temp,0x05
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
	mov	const_t_up,temp
;--------------------

;-------tem_down-------
	ldi	temp,0x06
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
	mov	const_t_down,temp
;--------------------

;-------delta_t-------
	ldi	temp,0x07
	out	eearl,temp
	sbi EECR,EERE
	in	temp,eedr
	sts	delta_t,temp
	nop
;--------------------
	pop	temp
	
	out	sreg,sreg_copy
	pop	sreg_copy

	ret
;--------------------------------------------------------------------------------------------



start_test : ;start test PP--------------------
	push	temp

	ldi	temp,0xff

	sts	wait3s_lo,temp
	nop
	sts	wait3s_hi,temp
	nop

 
	cbi	portb,0;displ wait3s test
	sbi	portb,1
	sbi	portb,2

	sbi	ddra,6

	sbi	porta,0
	sbi	porta,1
	sbi	portb,3
	sbi	porta,3
	sbi	porta,4
	sbi	porta,5
	cbi	porta,6
	sbi	porta,7


	pop	temp
	ret
;--------------------------------------------------------------------





;file EEPROM tempsens0.eep--------------------------------
.ESEG 

.db	0x04, 0x51; Vref = 1105mV(Up=3.3V) 
.db	0x28	;sensitivity water sensor    
.db	0x0a	;corr0 ADC
.db	0x03	;water sel
.db	0x28	;temperature up
.db	0x00	;temperature down
.db	0x00	;si delta_t
.db	0x00	;corr0_menu
.db	0x00	;corr_abs
.db	0x05	;const lo time out key
.db	0x00	;const hi time out key
.db	0x00	;const_post_alarm  adrres 0x0c
;--------------------------------------------

