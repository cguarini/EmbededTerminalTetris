            TTL Program Title for Listing Header Goes Here
;****************************************************************
;Descriptive comment header goes here.
;(What does the program do?)
;Name:  <Your name here>
;Date:  <Date completed here>
;Class:  CMPE-250
;Section:  <Your lab section, day, and time here>
;---------------------------------------------------------------
;Keil Template for KL46 Assembly with Keil C startup
;R. W. Melton
;April 20, 2015
;****************************************************************
;Assembler directives
            THUMB
            GBLL  MIXED_ASM_C
MIXED_ASM_C SETL  {TRUE}
            OPT   64  ;Turn on listing macro expansions
;****************************************************************
;Include files
            GET  MKL46Z4.s     ;Included by start.s
            OPT  1   ;Turn on listing
;****************************************************************
;EQUates


;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
;Port A
PORT_PCR_SET_PTA1_UART0_RX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
PORT_PCR_SET_PTA2_UART0_TX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
;---------------------------------------------------------------
;SIM_SCGC4
;1->10:UART0 clock gate control (enabled)
;Use provided SIM_SCGC4_UART0_MASK
;---------------------------------------------------------------
;SIM_SCGC5
;1->09:Port A clock gate control (enabled)
;Use provided SIM_SCGC5_PORTA_MASK
;---------------------------------------------------------------
;SIM_SOPT2
;01=27-26:UART0SRC=UART0 clock source select
;         (PLLFLLSEL determines MCGFLLCLK' or MCGPLLCLK/2)
; 1=   16:PLLFLLSEL=PLL/FLL clock select (MCGPLLCLK/2)
SIM_SOPT2_UART0SRC_MCGPLLCLK  EQU  \
                                 (1 << SIM_SOPT2_UART0SRC_SHIFT)
SIM_SOPT2_UART0_MCGPLLCLK_DIV2 EQU \
    (SIM_SOPT2_UART0SRC_MCGPLLCLK :OR: SIM_SOPT2_PLLFLLSEL_MASK)
;---------------------------------------------------------------
;SIM_SOPT5
; 0->   16:UART0 open drain enable (disabled)
; 0->   02:UART0 receive data select (UART0_RX)
;00->01-00:UART0 transmit data select source (UART0_TX)
SIM_SOPT5_UART0_EXTERN_MASK_CLEAR  EQU  \
                               (SIM_SOPT5_UART0ODE_MASK :OR: \
                                SIM_SOPT5_UART0RXSRC_MASK :OR: \
                                SIM_SOPT5_UART0TXSRC_MASK)
;---------------------------------------------------------------
;UART0_BDH
;    0->  7:LIN break detect IE (disabled)
;    0->  6:RxD input active edge IE (disabled)
;    0->  5:Stop bit number select (1)
;00001->4-0:SBR[12:0] (UART0CLK / [9600 * (OSR + 1)]) 
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDH_9600  EQU  0x01
;---------------------------------------------------------------
;UART0_BDL
;0x38->7-0:SBR[7:0] (UART0CLK / [9600 * (OSR + 1)])
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDL_9600  EQU  0x38
;---------------------------------------------------------------
;UART0_C1
;0-->7:LOOPS=loops select (normal)
;0-->6:DOZEEN=doze enable (disabled)
;0-->5:RSRC=receiver source select (internal--no effect LOOPS=0)
;0-->4:M=9- or 8-bit mode select 
;        (1 start, 8 data [lsb first], 1 stop)
;0-->3:WAKE=receiver wakeup method select (idle)
;0-->2:IDLE=idle line type select (idle begins after start bit)
;0-->1:PE=parity enable (disabled)
;0-->0:PT=parity type (even parity--no effect PE=0)
UART0_C1_8N1  EQU  0x00
;---------------------------------------------------------------
;UART0_C2
;0-->7:TIE=transmit IE for TDRE (disabled)
;0-->6:TCIE=transmission complete IE for TC (disabled)
;0-->5:RIE=receiver IE for RDRF (disabled)
;0-->4:ILIE=idle line IE for IDLE (disabled)
;1-->3:TE=transmitter enable (enabled)
;1-->2:RE=receiver enable (enabled)
;0-->1:RWU=receiver wakeup control (normal)
;0-->0:SBK=send break (disabled, normal)
UART0_C2_T_R  EQU  (UART0_C2_TE_MASK :OR: UART0_C2_RE_MASK :OR: UART0_C2_RIE_MASK)
;---------------------------------------------------------------
;UART0_C3
;0-->7:R8T9=9th data bit for receiver (not used M=0)
;           10th data bit for transmitter (not used M10=0)
;0-->6:R9T8=9th data bit for transmitter (not used M=0)
;           10th data bit for receiver (not used M10=0)
;0-->5:TXDIR=UART_TX pin direction in single-wire mode
;            (no effect LOOPS=0)
;0-->4:TXINV=transmit data inversion (not inverted)
;0-->3:ORIE=overrun IE for OR (disabled)
;0-->2:NEIE=noise error IE for NF (disabled)
;0-->1:FEIE=framing error IE for FE (disabled)
;0-->0:PEIE=parity error IE for PF (disabled)
UART0_C3_NO_TXINV  EQU  0x00
;---------------------------------------------------------------
;UART0_C4
;    0-->  7:MAEN1=match address mode enable 1 (disabled)
;    0-->  6:MAEN2=match address mode enable 2 (disabled)
;    0-->  5:M10=10-bit mode select (not selected)
;01111-->4-0:OSR=over sampling ratio (16)
;               = 1 + OSR for 3 <= OSR <= 31
;               = 16 for 0 <= OSR <= 2 (invalid values)
UART0_C4_OSR_16           EQU  0x0F
UART0_C4_NO_MATCH_OSR_16  EQU  UART0_C4_OSR_16
;---------------------------------------------------------------
;UART0_C5
;  0-->  7:TDMAE=transmitter DMA enable (disabled)
;  0-->  6:Reserved; read-only; always 0
;  0-->  5:RDMAE=receiver full DMA enable (disabled)
;000-->4-2:Reserved; read-only; always 0
;  0-->  1:BOTHEDGE=both edge sampling (rising edge only)
;  0-->  0:RESYNCDIS=resynchronization disable (enabled)
UART0_C5_NO_DMA_SSR_SYNC  EQU  0x00
;---------------------------------------------------------------
;UART0_S1
;0-->7:TDRE=transmit data register empty flag; read-only
;0-->6:TC=transmission complete flag; read-only
;0-->5:RDRF=receive data register full flag; read-only
;1-->4:IDLE=idle line flag; write 1 to clear (clear)
;1-->3:OR=receiver overrun flag; write 1 to clear (clear)
;1-->2:NF=noise flag; write 1 to clear (clear)
;1-->1:FE=framing error flag; write 1 to clear (clear)
;1-->0:PF=parity error flag; write 1 to clear (clear)
UART0_S1_CLEAR_FLAGS  EQU  0x1F
;---------------------------------------------------------------
;UART0_S2
;1-->7:LBKDIF=LIN break detect interrupt flag (clear)
;             write 1 to clear
;1-->6:RXEDGIF=RxD pin active edge interrupt flag (clear)
;              write 1 to clear
;0-->5:(reserved); read-only; always 0
;0-->4:RXINV=receive data inversion (disabled)
;0-->3:RWUID=receive wake-up idle detect
;0-->2:BRK13=break character generation length (10)
;0-->1:LBKDE=LIN break detect enable (disabled)
;0-->0:RAF=receiver active flag; read-only
UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS  EQU  0xC0
;---------------------------------------------------------------
;---------------------------------------------------------------
;UART0_C4
; 0--> 7:MAEN1=match address mode enable 1 (disabled)
; 0--> 6:MAEN2=match address mode enable 2 (disabled)
; 0--> 5:M10=10-bit mode select (not selected)
;01111-->4-0:OSR=over sampling ratio (16)
; = 1 + OSR for 3 <= OSR <= 31
; = 16 for 0 <= OSR <= 2 (invalid values)
MAX_STRING	EQU 79
	;Management record structure field displacements
IN_PTR 		EQU 0
OUT_PTR		EQU 4
BUF_STRT	EQU 8
BUF_PAST	EQU 12
BUF_SIZE	EQU 16
NUM_ENQD	EQU 17

;Queue structure sizes
Q_BUF_SZ	EQU 300 ; room for 80 characters
Q_REC_SZ	EQU 18 ;Management record size
;---------------------------------------------------------------
;NVIC_ICER
;31-00:CLRENA=masks for HW IRQ sources;
;             read:   0 = unmasked;   1 = masked
;             write:  0 = no effect;  1 = mask
;12:UART0 IRQ mask
NVIC_ICER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_ICPR
;31-00:CLRPEND=pending status for HW IRQ sources;
;             read:   0 = not pending;  1 = pending
;             write:  0 = no effect;
;                     1 = change status to not pending
;12:UART0 IRQ pending status
NVIC_ICPR_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_IPR0-NVIC_IPR7
;2-bit priority:  00 = highest; 11 = lowest
UART0_IRQ_PRIORITY    EQU  3
NVIC_IPR_UART0_MASK   EQU (3 << UART0_PRI_POS)
NVIC_IPR_UART0_PRI_3  EQU (UART0_IRQ_PRIORITY << UART0_PRI_POS)
;---------------------------------------------------------------
;NVIC_ISER
;31-00:SETENA=masks for HW IRQ sources;
;             read:   0 = masked;     1 = unmasked
;             write:  0 = no effect;  1 = unmask
;12:UART0 IRQ mask
NVIC_ISER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
UART0_C2_T_RI   EQU  (UART0_C2_RIE_MASK :OR: UART0_C2_T_R)
UART0_C2_TI_RI  EQU  (UART0_C2_TIE_MASK :OR: UART0_C2_T_RI)
;---------------------------------------------------------------
;NVIC_ICER
;31-00:CLRENA=masks for HW IRQ sources;
;             read:   0 = unmasked;   1 = masked
;             write:  0 = no effect;  1 = mask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ICER_PIT_MASK    EQU  PIT_IRQ_MASK
;---------------------------------------------------------------
;NVIC_ICPR
;31-00:CLRPEND=pending status for HW IRQ sources;
;             read:   0 = not pending;  1 = pending
;             write:  0 = no effect;
;                     1 = change status to not pending
;22:PIT IRQ pending status
;12:UART0 IRQ pending status
NVIC_ICPR_PIT_MASK    EQU  PIT_IRQ_MASK
;---------------------------------------------------------------
;NVIC_IPR0-NVIC_IPR7
;2-bit priority:  00 = highest; 11 = lowest
;--PIT
PIT_IRQ_PRIORITY    EQU  0
NVIC_IPR_PIT_MASK   EQU  (3 << PIT_PRI_POS)
NVIC_IPR_PIT_PRI_0  EQU  (PIT_IRQ_PRIORITY << UART0_PRI_POS)
;--UART0
;---------------------------------------------------------------
;NVIC_ISER
;31-00:SETENA=masks for HW IRQ sources;
;             read:   0 = masked;     1 = unmasked
;             write:  0 = no effect;  1 = unmask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ISER_PIT_MASK    EQU  PIT_IRQ_MASK
;---------------------------------------------------------------
;PIT_LDVALn:  PIT load value register n
;31-00:TSV=timer start value (period in clock cycles - 1)
;Clock ticks for 0.01 s at 24 MHz count rate
;0.01 s * 24,000,000 Hz = 240,000
;TSV = 240,000 - 1
PIT_LDVAL_10ms  EQU  239999
;---------------------------------------------------------------
;PIT_MCR:  PIT module control register
;1-->    0:FRZ=freeze (continue'/stop in debug mode)
;0-->    1:MDIS=module disable (PIT section)
;               RTI timer not affected
;               must be enabled before any other PIT setup
PIT_MCR_EN_FRZ  EQU  PIT_MCR_FRZ_MASK
;---------------------------------------------------------------
;PIT_TCTRLn:  PIT timer control register n
;0-->   2:CHN=chain mode (enable)
;1-->   1:TIE=timer interrupt enable
;1-->   0:TEN=timer enable
PIT_TCTRL_CH_IE  EQU  (PIT_TCTRL_TEN_MASK :OR: PIT_TCTRL_TIE_MASK)
	
DAC0_STEPS EQU 4096
SERVO_POSITIONS EQU 5
one EQU 1
TPM_CnV_PWM_DUTY_2ms EQU 6000
TPM_CnV_PWM_DUTY_1ms EQU 2200 
PWM_2ms			 EQU TPM_CnV_PWM_DUTY_2ms
PWM_1ms 		EQU TPM_CnV_PWM_DUTY_1ms 
Addition_Value	EQU	24
	
POS_RED	EQU 29
POS_GREEN EQU 5
LED_RED_MASK EQU (1<<POS_RED)
LED_GREEN_MASK EQU (1<<POS_GREEN)
LED_PORTD_MASK EQU LED_GREEN_MASK
LED_PORTE_MASK EQU LED_RED_MASK
	
;PORT D
PTD5_MUX_GPIO EQU (1<<PORT_PCR_MUX_SHIFT)
SET_PTD5_GPIO EQU (PORT_PCR_ISF_MASK :OR: PTD5_MUX_GPIO)
;PORT E
PTE29_MUX_GPIO EQU (1<<PORT_PCR_MUX_SHIFT)
SET_PTE29_GPIO EQU (PORT_PCR_ISF_MASK :OR PTE29_MUX_GPIO)
;---------------------------------------------------------------
;Lab 10
;****************************************************************
;MACROs
;****************************************************************
;Program
;C source will contain main ()
;Only subroutines and ISRs in this assembly source
            AREA    MyCode,CODE,READONLY
            
			EXPORT  GetStringSB
			EXPORT  PutStringSB
			EXPORT  Init_UART0_IRQ
			EXPORT  AddIntMultiU
			EXPORT  PutNumHex
			EXPORT  PutNumU
			EXPORT  UART0_IRQHandler
			EXPORT  nextLine
			EXPORT  GetChar
			EXPORT   PutChar
            EXPORT init_LED
            EXPORT Enable_Red_LED
            EXPORT Enable_Green_LED
            EXPORT Disable_Red_LED
            EXPORT Disable_Green_LED
            EXPORT init_PIT_IRQ
            EXPORT PIT_IRQHandler
            EXPORT Count
            EXPORT RxQRecord
            EXPORT RunStopWatch
;>>>>> begin subroutine code <<<<<
;---------------------------------------
;>>>>> begin main program code <<<<<
;>>>>> end   main program code <<<<<
;>>>>> begin subroutine code <<<<<
nextLine 
	PUSH {LR}
		PUSH{R0}
		MOVS R0,#0x0D
		BL PutChar
		MOVS R0,#0x0A
		BL PutChar
		POP {R0}
	POP {PC}
Init_UART0_Polling PUSH {R0-R2}
	;Select MCGPLLCLK/2 as UART0 Clock source
			LDR R0,=SIM_SOPT2
			LDR R1,=SIM_SOPT2_UART0SRC_MASK
			LDR R2,[R0,#0]
			BICS R2,R2,R1
			LDR R1,=SIM_SOPT2_UART0_MCGPLLCLK_DIV2
			ORRS R2,R2,R1
			STR	R2,[R0,#0]
	;Enable external connection for UART0
			LDR R0,=SIM_SOPT5
			LDR R1,=SIM_SOPT5_UART0_EXTERN_MASK_CLEAR
			LDR R2,[R0,#0]
			BICS R2,R2,R1
			STR R2,[R0,#0]
	;Enable clock for UART0 module
			LDR R0,=SIM_SCGC4
			LDR R1,=SIM_SCGC4_UART0_MASK
			LDR R2,[R0,#0]
			ORRS R2,R2,R1
			STR R2,[R0,#0]
	;Enable Clock for Port A module
			LDR R0,=SIM_SCGC5
			LDR R1,=SIM_SCGC5_PORTA_MASK
			LDR	R2,[R0,#0]
			ORRS R2,R2,R1
			STR R2,[R0,#0]
	;Connect Port A Pin 1 (PTA1) to UART0 Rx (J1 Pin 02)
			LDR R0,=PORTA_PCR1
			LDR R1,=PORT_PCR_SET_PTA1_UART0_RX
			STR R1,[R0,#0]
	;Connect PORT A Pin 2 (PTA2) to UART0 Tx (J1 Pin 04)
			LDR R0, = PORTA_PCR2
			LDR R1,=PORT_PCR_SET_PTA2_UART0_TX
			STR	R1,[R0,#0]
	;----------------------------------------------------
	;Disable UART0 receiver and transmitter
			LDR R0,=UART0_BASE
			MOVS R1,#UART0_C2_T_R
			LDRB R2,[R0,#UART0_C2_OFFSET]
			BICS R2,R2,R1
			STRB R2,[R0,#UART0_C2_OFFSET]
	;Set UART0 for 9600 baud, 8N1 protocol
			MOVS R1,#UART0_BDH_9600
			STRB R1,[R0,#UART0_BDH_OFFSET]
			MOVS R1,#UART0_BDL_9600
			STRB R1,[R0,#UART0_BDL_OFFSET];UART_0_BDL0_OFFSET in template....
			MOVS R1,#UART0_C1_8N1
			STRB R1,[R0,#UART0_C1_OFFSET]
			MOVS R1,#UART0_C4_NO_MATCH_OSR_16
			STRB R1,[R0,#UART0_C4_OFFSET]
			MOVS R1,#UART0_C5_NO_DMA_SSR_SYNC
			STRB R1,[R0,#UART0_C5_OFFSET]
			MOVS R1,#UART0_S1_CLEAR_FLAGS
			STRB R1,[R0,#UART0_S1_OFFSET]
			MOVS R1,\
			     #UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS
			STRB R1,[R0,#UART0_S2_OFFSET]
	;Enable UART0 receiver and transmitter
			MOVS R1,#UART0_C2_T_R
			STRB R1,[R0,#UART0_C2_OFFSET]
	;END
	POP {R0-R2}
	BX LR
;-------------------------------------------------------
;Begin GetChar
;Uses register R0-R3
;Gets character from terminal keyboard to R0
;Returns R0: Character recieved
GetChar		PUSH {LR}
		PUSH {R1-R3}
GetCharLoop
			CPSID I;Mask Interupts
			LDR R1,=RxQRecord;R1<-Recieve queue record
			BL Dequeue;Dequeue character
			;R0<-Character from Dequeue
			CPSIE I;Unmask Interupts
			BCS GetCharLoop;Repeat until dequeue successful
		POP {R1-R3}
	
		POP {PC}

;Begin PutChar
;Uses Register R0-R3
;@Param R0: Character to put
;Displays the single character from R0 to terminal screen
PutChar		PUSH {LR}
			PUSH{R1-R3}
PutCharLoop
			;critical code
			LDR R1,=TxQRecord;R1<-Transmit Queue Record
			CPSID I;Mask Interupts
			BL Enqueue;Enqueue character in R0
			CPSIE I;Unmask interupts
			BCS PutCharLoop;If queue is unsuccessful, repeat loop
			BL enableTxInt
		POP {R1-R3}
	POP {PC}
			

;****************************************************************
;EQUates
;Characters
CR          EQU  0x0D
LF          EQU  0x0A
NULL        EQU  0x00
;---------------------------------------------------------------
GetStringSB
;**********************************************************************
;Get string in secure buffer:
;Receives each character in string from GetChar and adds NULL 
;termination, preventing buffer overrun for buffer size specified.  
;Input of CR (from pressing "Enter" key) terminates input.  
;Other than CR, does not handle any control codes of escape sequences.
;Calls:  GetChar
;        PutChar
;Input:  R0: Address of string buffer
;        R1: Capacity of string buffer
;Modifies:  PSR
;**********************************************************************
            PUSH  {R0-R3,LR}    ;save registers modified
;Register map
;R0:  current string character
;R1:  size of memory buffer (input parameter)
;R2:  current string index or character count
;R3:  address of string (from input parameter R0)
            CMP   R1,#0            ;if (buffer capacity) {
            BEQ   GetStringSBNull
            MOV   R3,R0            ;  base address of string
            MOVS  R2,#0            ;  character count
            SUBS  R1,R1,#1         ;  maximum characters
            BEQ   GetStringSBFull  ;  while (available buffer space) {
GetStringSBChar
            BL    GetChar          ;    receive character
GetStringSBCharInspect
            CMP   R0,#CR           ;    if CR
                                   ;      done 
            BEQ   GetStringSBTerminate
                                   ;    else {
            BL    PutChar          ;      echo character
            STRB  R0,[R3,R2]       ;      store in string
            ADDS  R2,R2,#1         ;      character count ++
            CMP   R2,R1            ;    }end else
            BLO   GetStringSBChar  ;  }end while (available buffer space)
GetStringSBFull                    ;  repeat { ;with no available space
            BL    GetChar          ;    receive character
            CMP   R0,#CR
            BNE   GetStringSBFull  ;  } until CR received
GetStringSBTerminate               ;}end if (buffer capacity)
            MOVS  R1,#NULL         ;terminate with NULL
            STRB  R1,[R3,R2]
GetStringSBDone
            BL    PutChar          ;echo CR
            MOVS  R0,#LF           ;print LF
            BL    PutChar
            POP   {R0-R3,PC}       ;restore registers and return
GetStringSBNull                    ;repeat {
            BL    GetChar          ;  receive character
            CMP   R0,#CR
            BNE   GetStringSBNull
                                   ;} until CR received
            B     GetStringSBDone
;---------------------------------------------------------------

	
;****************************************************************

;---------------------------------------------------------------
PutStringSB
;**********************************************************************
;PROVIDED BY R. W. Melton to Chris Guarini for CMPE-250 Fall 2016
;TERMS:  No credit for Lab Exercise Six
;Put string from secure buffer:
;Sends each character in null-terminated string to PutChar.
;Calls:  PutChar
;Input:  R0: Address of string buffer
;        R1: Capacity of string buffer
;Modifies:  PSR
;**********************************************************************
;Save registers
            PUSH   {R0-R2,LR}
;Register Map
;R0:  Current string character
;R1:  Capacity of string buffer (input parameter);
;     Address of first byte past string buffer
;R2:  Address of string buffer (from input parameter R0)
            CMP    R1,#0          ;if (buffer capacity) {
            BEQ    PutStringSBDone
            ADDS   R1,R1,R0       ;First address past buffer
            MOV    R2,R0          ;R0 needed for PutChar parameter
PutStringSBLoop                   ;repeat {
            LDRB   R0,[R2,#0]     ;  CurrentChar of string
            CMP    R0,#NULL       ;  if (CurrentChar != NULL) {
            BEQ    PutStringSBDone
            BL     PutChar        ;    Send current char to terminal
            ADDS   R2,R2,#1       ;    CurrentCharPtr++
            CMP    R2,R1
            BEQ    PutStringSBDone
            B      PutStringSBLoop
                                  ;} until ((CurrentChar == NULL)
                                  ;         || (Past end of buffer))
;Restore registers
PutStringSBDone
            POP    {R0-R2,PC}
;---------------------------------------------------------------

DIVU
	PUSH {R2-R4}
			MOVS R2,#0;counter
			;check for 0 case
			CMP R0,#0
			BNE CHECK2
			MOVS R0,#1
			LSRS R0,R0,#1
			B FIN
			
CHECK2		CMP R1,R0;if Dividend<Divisor
			BLT DIVFinish;finish
			;else R1<-(R1-R0)
			SUBS R1,R1,R0
			ADDS R2,R2,#1;counter++
			B CHECK2
			
DIVFinish
			MOVS R0,R2;R0<-quotient

FIN		POP {R2-R4};return
			BX LR


LengthStringSB
	PUSH {R0-R1}
		MOVS R2,#0
lenStrWhile
		LDRB R1,[R0,#0]
		CMP R1,#0
		BEQ endLenStrWhile
		ADDS R2,R2,#1
		ADDS R0,R0,#1
		B lenStrWhile
endLenStrWhile
	POP {R0-R1}
	BX LR
	
	
PutNumU
	PUSH {LR}
		PUSH {R0-R3}
		;initialize
			MOVS R3,#0;act as counter
			;check for 0 case
			;if 0, print 0
			CMP R0,#0
			BNE PutNumLoop;else begin loop
			ADDS R0,#48
			BL PutChar
			B  PNEnd
			
PutNumLoop	CMP R0,#0
			BEQ endPutNumLoop
			MOVS R1,R0;Dividend<-R0
			MOVS R0,#10;Divisor<-10
			BL DIVU
			ADDS R1,R1,#48
			PUSH {R1}
			ADDS R3,R3,#1
			B PutNumLoop
endPutNumLoop
			LDR R0,=PutNumV
PNL2		CMP R3,#0
			BEQ endPNL2
			POP {R1}
			STRB R1,[R0,#0]
			ADDS R0,R0,#1
			SUBS R3,R3,#1
			B PNL2
endPNL2		MOVS R1,#0
			STRB R1,[R0,#0]
			LDR R0,=PutNumV
			MOVS R1,#80
			BL PutStringSB
PNEnd	POP {R0-R3}
	POP {PC}
	
	
;-------------------------------------------------
;Lab 7
;-------------------------------------------------
			LTORG
InitQueue
;Creates a circular FIFO queue in memory
;@param R1= address of queue record structure
;		R0= address of queue buffer
;		R2= size of queue in character capacity
	PUSH {R0-R3}
		STR R0,[R1,#0]
		STR R0,[R1,#OUT_PTR]
		STR R0,[R1,#BUF_STRT]
		ADDS R0,R0,R2
		STR R0,[R1,#BUF_PAST]
		STRB R2,[R1,#BUF_SIZE]
		MOVS R0,#0
		STRB R0,[R1,#NUM_ENQD]
	POP {R0-R3}
	BX LR
	
;-----------------------------------------------
Dequeue
;Attempts to return a character from the queue
;If queue is not empty, will dequeue a single 
;character and return in R0 with C flag cleared
;otherwise returns C=1
;@param R1=queue record structure
;@returns R0=dequeued element
	PUSH {R1-R3}
		LDRB R2,[R1,#NUM_ENQD];Check number enqueued
		CMP R2,#0;if(num_enqd==o)
		BEQ dequeueError;branch to set C flag
		;decrement numberEnqueued
		SUBS R2,R2,#1;R2<-numberEnqueued--
		STRB R2,[R1,#NUM_ENQD];M[NumEnqueued]<--R2
		;Dequeue Element
		LDR R0,[R1,#OUT_PTR];puts dequeued element in R0
		LDRB R0,[R0,#0]
		LDR R2,[R1,#OUT_PTR]
		ADDS R2,R2,#1;increments the OUT_PTR address
		STR R2,[R1,#OUT_PTR];store out_ptr
		LDR R3,[R1,#BUF_PAST];R3<-BufferPast
		;Make queue circular
		CMP R2,R3;if(OUT_PTR<BufferPast)
		BLT dequeueSuccess
		LDR R2,[R1,#BUF_STRT];R2<-Buffer start
		STR R2,[R1,#OUT_PTR];OutPtr<-BufferStart
		B dequeueSuccess
dequeueError
		MOVS R2,#3;R2<-2_011
		LSRS R2,R2,#1;C=1 while Z=0
		B dequeueEnd
		
dequeueSuccess
		MOVS R2,#2;R2<-2_010
		LSRS R2,#1;C=0 while Z=0
		B dequeueEnd
		
dequeueEnd POP {R1-R3};restore used registers
		BX LR;branch out
;-----------------------------------------------------
Enqueue
;Enqueues character if queue is not full
;@param R1=Address to queue
;		R0=Element to enqueue
;@returns PSR C<-(0 if failed) || (1 if success)
	PUSH {R0-R3}
		LDRB R2,[R1,#NUM_ENQD];R2<-NumberEnqueued
		LDRB R3,[R1,#BUF_SIZE];R3<-Buffer Size
		CMP  R2,R3;if(NumberEnqueued>=BufferSize)//Queue is full
		BHS  queueError;Throw an error
		
		;else queue the objet
		LDR R2,[R1,#IN_PTR];R2<-IN_PTR
		STRB R0,[R2,#0];Queues element @IN_PTR
		ADDS R2,R2,#1;IN_PTR++
		STR R2,[R1,#IN_PTR];Stores IN_PTR++
		LDRB R3,[R1,#NUM_ENQD];R3<-NUM_ENQUEUED
		ADDS R3,R3,#1;NUM_ENQUEUED++
		STRB R3,[R1,#NUM_ENQD];Store num_enqd
		LDR  R3,[R1,#BUF_PAST]
		
		;if(IN_PTR>=BUF_PAST)
		CMP R2,R3;if(IN_PTR<BufferPast)
		BLT queueSuccess
		LDR R2,[R1,#BUF_STRT];R2<-Buffer start
		STR R2,[R1,#IN_PTR];OutPtr<-BufferStart
		
		B queueSuccess
queueError
		MOVS R2,#3;R2<-2_011
		LSRS R2,R2,#1;C=1 while Z=0
		B queueEnd
		
queueSuccess
		MOVS R2,#2;R2<-2_010
		LSRS R2,#1;C=0 while Z=0
		B queueEnd
		
queueEnd POP {R0-R3};restore used registers
		BX LR;branch out

PutNumHex
;Prints the unsigned word value in R0 to the terminal screen
;@param R0=word to print
	PUSH {LR}
	PUSH {R0-R3}
		MOVS R2,#28
		MOVS R3,#0
putHexLoop
		PUSH {R0}
		MOVS R1,R0
		LSLS R1,R1,R3
		LSRS R1,R1,#28
		ADDS R3,R3,#4
		CMP R1,#0xA
		BLT HexDec
		ADDS R1,R1,#55
		MOVS R0,R1
		BL PutChar
		POP {R0}
		B HexCheck
HexDec	
		ADDS R1,R1,#48
		MOVS R0,R1
		BL PutChar
		POP {R0}
HexCheck
		CMP R3,#32
		BNE putHexLoop
		POP {R0-R3}
		POP {PC}
		
;----------------------------------------------------
;LAB 8
;----------------------------------------------------
CopyStringSB
;Creates a null terminated string by copying the characters of another
;null terminated string
;@param: R0=address of original string
;		 R1=address of copy string
;		 R2=buffer capacity
	PUSH {R0-R3}
CopyStringLoop		
		CMP R2,#1;If(bufferCapacity==1)//so that a null can be added
		BEQ endStringLoop;end Loop
		LDRB R3,[R0,#0];load character
		CMP R3,#0;if(null)
		BEQ endStringLoop;end the loop
		SUBS R2,R2,#1;buffercapacity--
		STRB R3,[R1,#0];Store character in copy string
		ADDS R1,R1,#1;copyStringAddress++
		ADDS R0,R0,#1;OriginalAddress++
		B CopyStringLoop;loop back
		
endStringLoop
		MOVS R3,#0x0;R3<--NULL
		STRB R3,[R1,#0];Null terminate the string
	;end subroutine
	POP {R0-R3}
	BX LR
		
;--------------------------------------
FindStringCharSB
;Finds the first time a character appears in a null terminated string
;@param:	R0=Character to find
;			R1=Address of string
;			R2=Buffer capacity
;@returns:  R3=Position of character || 0 if not in string ??what if character is at 0 position??
	PUSH {R0,R2,R4}
	MOVS R3,#0
SearchStringLoop
		CMP R2,#0;If(bufferCapacity==0)
		BEQ endSearch;end loop
		LDRB R4,[R1,#0];load the character at the pointer
		CMP R4,#0x0;if(null)
		BEQ failedSearch;leave loop to failed state
		CMP R4,R0
		BEQ endSearch;leave loop to success state
		SUBS R2,R2,#1;BufferCapacity--
		ADDS R1,R1,#1;Next Character in string
		ADDS R3,R3,#1;Add to pointer
		B SearchStringLoop;loop back
		
failedSearch;Failed state, character not in string
		MOVS R3,#0x0;R3<-Null
		B endSearch

endSearch
	POP {R0,R2,R4}
	BX LR

ReverseStringSB
;Reverses the characters of a string
;@param: R0=Address of string to reverse
;@param; R1=Buffer Capacity
	PUSH {R0-R4}
	MOVS R3,#0;act as a counter
ReverseStringLoop
		CMP R1,#0x0;If(Buffercapacity==0)
		BEQ endReverseLoop; end loop
		MOVS R4,R0;Copy address to R4
		LDRB R2,[R0,R3];R2<--Character
		CMP  R2,#0x0;if(null)
		BEQ  endReverseLoop;end loop
		PUSH {R2};push character onto stack
		ADDS R3,R3,#1;counter++
		B ReverseStringLoop;loop back
endReverseLoop
		CMP R3,#0;When counter runs out
		BEQ endReverse;end loop
		POP {R2};pop stack onto R2
		SUBS R3,R3,#1;counter--
		STRB R2,[R4,#0];Store character in reverse order
		ADDS R4,R4,#1;Increment the address
		B endReverseLoop
endReverse
	POP {R0-R4}
	BX LR
;************************************************
;LAB 9*******************************************
;************************************************
UART0_ISR
UART0_IRQHandler
;2 conditions generate serial port interrupt
;RxInterrupt: RDRF is set, character recieved by UART0
;TxInterrupt: TDRE is set, UART0 ready to transmit character
	CPSID I
	PUSH {LR}
		PUSH{R0-R3}
			;R0<-UART0_C2
			LDR R0,=UART0_C2
			LDRB R0,[R0,#0]
			;IF TIE=1
			MOVS R1,#UART0_C2_TIE_MASK;R1<-10000000
			TST R0,R1;if TIE=0

			BEQ checkRx;check RxInteruupt
			
			;R0<-UART0_S1
			LDR R0,=UART0_S1
			LDRB R0,[R0,#0]
			;IF TDRE=1//TxInterrupt
			MOVS R1,#UART0_S1_TDRE_MASK;R1<-10000000
			TST R0,R1;If TDRE=0
			BEQ  checkRx
			;Dequeue character from TxQueue
			LDR R1,=TxQRecord
			BL Dequeue;R0<-Character from TxQ
			BCS dequeueUnsuc;if dequeue unsuccessful, disable TxInterrupt
			LDR R1,=UART0_D;else R1<-UART0_D
			STRB R0,[R1,#0];UART0_D<-Character from TxQueue
			
checkRx			
			LDR R0,=UART0_S1
			LDRB R0,[R0,#0]
			MOVS R1,#UART0_S1_RDRF_MASK;0x04
			TST R0,R1;if RDRF not set
			BEQ endUART0_ISR;end subroutine
			;R0<-UART0_D
			LDR R0,=UART0_D
			LDRB R0,[R0,#0]
			
			LDR R1,=RxQRecord;R1<-RxQ
			BL Enqueue;Enqueue data into RxQ
			;Character lost if RxQ full
			B endUART0_ISR
		
dequeueUnsuc
			BL disableTxInt
			B checkRx

endUART0_ISR	
		POP {R0-R3}
		CPSIE I
		POP {PC}

;-------------------------------------------------------------------
disableTxInt
;disables the TxInterrupt
	PUSH {R0-R2}
	LDR R0,=UART0_C2
	MOVS R1,#UART0_C2_T_RI
	STRB R1,[R0,#0];Store back into UART0_C2
	POP {R0-R2}
	BX LR
;-------------------------------------------------------------------
enableTxInt
;disables the TxInterrupt
	PUSH {R0-R2}
	LDR R0,=UART0_C2
	MOVS R1,#UART0_C2_TI_RI
	STRB R1,[R0,#0];Store back into UART0_C2
	POP {R0-R2}
	BX LR
;-------------------------------------------------------------------
enableRxInt
;enables the RxInterrupt
	PUSH {R0-R2,LR}
	LDR R0,=UART0_C2
	MOVS R1,#UART0_C2_T_RI
	STRB R1,[R0,#0];Store back into UART0_C2
	POP {R0-R2,PC}
	BX LR
;-------------------------------------------------------------------
Init_UART0_IRQ PUSH{LR}
			PUSH {R0-R3}
	;Select MCGPLLCLK/2 as UART0 Clock source
			LDR R0,=SIM_SOPT2
			LDR R1,=SIM_SOPT2_UART0SRC_MASK
			LDR R2,[R0,#0]
			BICS R2,R2,R1
			LDR R1,=SIM_SOPT2_UART0_MCGPLLCLK_DIV2
			ORRS R2,R2,R1
			STR	R2,[R0,#0]
	;Enable external connection for UART0
			LDR R0,=SIM_SOPT5
			LDR R1,=SIM_SOPT5_UART0_EXTERN_MASK_CLEAR
			LDR R2,[R0,#0]
			BICS R2,R2,R1
			STR R2,[R0,#0]
	;Enable clock for UART0 module
			LDR R0,=SIM_SCGC4
			LDR R1,=SIM_SCGC4_UART0_MASK
			LDR R2,[R0,#0]
			ORRS R2,R2,R1
			STR R2,[R0,#0]
	;Enable Clock for Port A module
			LDR R0,=SIM_SCGC5
			LDR R1,=SIM_SCGC5_PORTA_MASK
			LDR	R2,[R0,#0]
			ORRS R2,R2,R1
			STR R2,[R0,#0]
	;Connect Port A Pin 1 (PTA1) to UART0 Rx (J1 Pin 02)
			LDR R0,=PORTA_PCR1
			LDR R1,=PORT_PCR_SET_PTA1_UART0_RX
			STR R1,[R0,#0]
	;Connect PORT A Pin 2 (PTA2) to UART0 Tx (J1 Pin 04)
			LDR R0, = PORTA_PCR2
			LDR R1,=PORT_PCR_SET_PTA2_UART0_TX
			STR	R1,[R0,#0]
	;----------------------------------------------------
	;Disable UART0 receiver and transmitter
			LDR R0,=UART0_BASE
			MOVS R1,#UART0_C2_T_R
			LDRB R2,[R0,#UART0_C2_OFFSET]
			BICS R2,R2,R1
			STRB R2,[R0,#UART0_C2_OFFSET]
	;Set UART0 for 9600 baud, 8N1 protocol
			MOVS R1,#UART0_BDH_9600
			STRB R1,[R0,#UART0_BDH_OFFSET]
			MOVS R1,#UART0_BDL_9600
			STRB R1,[R0,#UART0_BDL_OFFSET];UART_0_BDL0_OFFSET in template....
			MOVS R1,#UART0_C1_8N1
			STRB R1,[R0,#UART0_C1_OFFSET]
			MOVS R1,#UART0_C4_NO_MATCH_OSR_16
			STRB R1,[R0,#UART0_C4_OFFSET]
			MOVS R1,#UART0_C5_NO_DMA_SSR_SYNC
			STRB R1,[R0,#UART0_C5_OFFSET]
			MOVS R1,#UART0_S1_CLEAR_FLAGS
			STRB R1,[R0,#UART0_S1_OFFSET]
			MOVS R1,\
			     #UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS
			STRB R1,[R0,#UART0_S2_OFFSET]
	;Enable UART0 receiver and transmitter
			MOVS R1,#UART0_C2_T_R
			STRB R1,[R0,#UART0_C2_OFFSET]
	;Initialize NVIC
			LDR R0,=UART0_IPR
			;LDR R1,=NVIC_IPR_UART0_MASK
			LDR R2,=NVIC_IPR_UART0_PRI_3
			LDR R3,[R0,#0]
			ORRS R3,R3,R2
			STR R3,[R0,#0]
			LDR R0,=NVIC_ICPR
			LDR R1,=NVIC_ICPR_UART0_MASK
			STR R1,[R0,#0]
			LDR R0,=NVIC_ISER
			LDR R1,=NVIC_ICPR_UART0_MASK
			STR R1,[R0,#0]
			
	;Create the transmit and recieve queues
			;Transmit Queue
			LDR R0,=TxQBuffer
			LDR R1,=TxQRecord
			MOVS R2,#80
			BL InitQueue
			;Recieve Queue
			LDR R0,=RxQBuffer
			LDR R1,=RxQRecord
			BL InitQueue
	;UART0_C2<-UART0_C2_T_RI
	BL enableRxInt
	;END
	POP {R0-R3}
	POP {PC}
;-------------------------------------------------------
PutNumUB
;@param R0: Unsigned byte value
;Prints unsigned byte value in R0 to terminal in decimal
	PUSH {LR}
		PUSH {R0}
			LSLS R0,#30;shift out everything except the byte
			LSRS R0,#30;shift the byte back to LSB
			BL PutNumU;use PutNumU to put R0 onto terminal
		POP {R0}
	POP {PC};return

;************************************************************
;LAB 10 Chris Guarini 11/1/16
;************************************************************
init_PIT_IRQ
;Initialize the PIT to generate an interrupt every .01s 
;from channel 0

;Enable clock for PIT module
			LDR R0,=SIM_SCGC6
			LDR R1,=SIM_SCGC6_PIT_MASK
			LDR R2,[R0,#0]
			ORRS R2,R2,R1
			STR	R2,[R0,#0]
;Diable Pit Timer 0
			LDR R0,=PIT_CH0_BASE
			LDR R1,=PIT_TCTRL_TEN_MASK
			LDR R2,[R0,#PIT_TCTRL_OFFSET]
			BICS R2,R2,R1
			STR R2,[R0,#PIT_TCTRL_OFFSET]
			;Set PIT interrupt priority
			LDR R0,=PIT_IPR
			LDR R1,=NVIC_IPR_PIT_PRI_0
			;LDR R2,=NVIC_IPR_PIT_PRI_0
			LDR R3,[R0,#0]
			BICS R3,R3,R1
			;ORRS R3,R3,R2
			STR R3,[R0,#0]
			;Clear any pending PIT interrupts
			LDR R0,=NVIC_ICPR
			LDR R1,=NVIC_ICPR_PIT_MASK
			STR R1,[R0,#0]
			;Unmask PIT interrupts
			LDR R0,=NVIC_ISER
			LDR R1,=NVIC_ISER_PIT_MASK
			STR R1,[R0,#0]
			;Enable Pit module
			LDR R0,=PIT_BASE
			LDR R1,=PIT_MCR_EN_FRZ
			STR R1,[R0,#PIT_MCR_OFFSET]
			;Set PIT timer 0 period for .01s
			LDR R0,=PIT_CH0_BASE
			LDR R1,=PIT_LDVAL_10ms
			STR R1,[R0,#PIT_LDVAL_OFFSET]
			;Enable PIT timer 0 interrupts
			LDR R1,=PIT_TCTRL_CH_IE
			STR R1,[R0,#PIT_TCTRL_OFFSET]
			
			BX LR;end subroutine
;------------------------------------------------------
PIT_ISR
PIT_IRQHandler
;ISR for the PIT module
;On a PIT interrupt, if the variable RunStopWatch is not zero,
;increments the variable Count; otherwise it leaves Count unchanged
;In either case, ISR clears interrupt before exiting
			CPSID I;mask interrupts
			;Check RunStopWatch==0
			LDR R0,=RunStopWatch;R0<-&RunStopWatch
			LDRB R0,[R0,#0];R0<-*RunStopWatch
			;If R0==0
			CMP R0,#0;R0==0
			BEQ endPIT;End ISR
			
			;else{
			;count++}
			LDR R0,=Count;R0<-&Count
			LDR R1,[R0,#0];R1<-*Count (word)
			ADDS R1,R1,#1;Count++
			STR R1,[R0,#0];Store it back
			;endElse
			
endPIT		;Clear interrupt condition
			LDR R0,=PIT_CH0_BASE
			MOVS R1,#1
			STR R1,[R0,#PIT_TFLG_OFFSET]
			;Exit ISR
			CPSIE I;unmask interupts
			BX LR

AddIntMultiU
;Adds n-word unsigned number in memory to another n-word unsigned
;number in memory, and stores the output in another place in memeory
;@param:	R2-Address of first number
;			R1-Address of second number
;			R3-n
;@output:	R0-Output unsigned number
		PUSH {R1-R6}
			;Set Carry to 0
			MOVS R6,#0
AddLoop 	;check if n=0
			CMP R3,#0
			BEQ endAddLoop;end loop if n=0
			;Load and iterate the input addresses
			LDM R1!,{R4}
			LDM R2!,{R5}
			;Add with carry
			ADDS R4,R4,R6
			ADDS R4,R4,R5
			;Store it and iterate output address
			STM  R0!,{R4}
			MRS R6,PSR;preserve PSR
			LSLS R6,R6,#2
			LSRS R6,R6,#30
			SUBS R3,R3,#1;n--
			B AddLoop
endAddLoop
		;end subroutine
		CMP R6,#0
		BNE AddOverflow
		MOVS R0,#0
		POP {R1-R6}
		BX LR
AddOverflow
		MOVS R0,#1
		POP {R1-R6}
		BX LR

;-------------------------------------------------
;Lab 13
;-------------------------------------------------

init_LED
;Initializes the LEDs to be used
		PUSH {R0-R3}
;Enable clock for Port D and E modules
		LDR R0,=SIM_SCGC5
		LDR R1,=(SIM_SCGC5_PORTD_MASK :OR: \
				SIM_SCGC5_PORTE_MASK)
		LDR R2,[R0,#0]
		ORRS R2,R2,R1
		STR R2,[R0,#0]

;Select PORT E Pin 29 for GPIO to red LED
		LDR R0,=PORTE_BASE
		LDR R1,=SET_PTE29_GPIO
		STR R1,[R0,#PORTE_PCR29_OFFSET]
;Select PORT D Pin 5 for GPIO to green LED
		LDR R0,=PORTD_BASE
		LDR R1,=SET_PTD5_GPIO
		STR R1,[R0,#PORTD_PCR5_OFFSET]
		
;Port DATA direction register (PDDR)
		LDR R0,=FGPIOD_BASE
		LDR R1,=LED_PORTD_MASK
		STR R1,[R0,#GPIO_PDDR_OFFSET]
		
		LDR R0,=FGPIOE_BASE
		LDR R1,=LED_PORTE_MASK
		STR R1,[R0,#GPIO_PDDR_OFFSET]
		
		POP {R0-R3}
		BX LR

Disable_Red_LED
;turns off red LED
		PUSH {R0-R1}
		LDR R0,=FGPIOE_BASE
		LDR R1,=LED_RED_MASK
		STR R1,[R0,#GPIO_PSOR_OFFSET]
		POP {R0-R1}
		BX LR
Disable_Green_LED
;turns off green LED
		PUSH {R0-R1}
		LDR R0,=FGPIOD_BASE
		LDR R1,=LED_GREEN_MASK
		STR R1,[R0,#GPIO_PSOR_OFFSET]
		POP {R0-R1}
		BX LR
Enable_Red_LED
;Turns on red LED
		PUSH {R0-R1}
		LDR R0,=FGPIOE_BASE
		LDR R1,=LED_RED_MASK
		STR R1,[R0,#GPIO_PCOR_OFFSET]
		POP {R0-R1}
		BX LR
Enable_Green_LED
;Turns on green LED
		PUSH {R0-R1}
		LDR R0,=FGPIOD_BASE
		LDR R1,=LED_GREEN_MASK
		STR R1,[R0,#GPIO_PCOR_OFFSET]
		POP {R0-R1}
		BX LR
		

;>>>>>   end subroutine code <<<<<
            ALIGN
;**********************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<

			ALIGN

;>>>>>   end constants here <<<<<
;**********************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
PutNumV		SPACE MAX_STRING
			ALIGN
;Queue structures
RxQBuffer	SPACE	Q_BUF_SZ
			ALIGN
RxQRecord	SPACE	Q_REC_SZ
			ALIGN
TxQBuffer	SPACE	Q_BUF_SZ
			ALIGN
TxQRecord	SPACE	Q_REC_SZ
			ALIGN
OpStr		SPACE   MAX_STRING
			ALIGN
QBuffer		SPACE 	Q_BUF_SZ
			ALIGN
QRecord		SPACE 	Q_REC_SZ
			ALIGN
RunStopWatch SPACE  8
			ALIGN
Count		SPACE  32
			ALIGN
NumOne		SPACE	Addition_Value
			ALIGN
NumTwo		SPACE	Addition_Value
			ALIGN
NumOut		SPACE	Addition_Value
			
;>>>>>   end variables here <<<<<
            END
