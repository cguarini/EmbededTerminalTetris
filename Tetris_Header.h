/*********************************************************************/
/* Lab Exercise Twelve                                               */
/* Adjusts a servo to one of five positions [1, 5] using  mixed C    */
/* and assembly language.  Prompts user to enter a number from 1 to  */
/* 5, generates a voltage in the range (0, 3.3] V proportional to    */
/* the user's number, converts the voltage to a 10-bit number, and   */
/* set's the servo position [1, 5] based on the magnitude of the 10- */
/* bit digital value.                                                */
/* Name:  R. W. Melton                                               */
/* Date:  November 14, 2016                                          */
/* Class:  CMPE 250                                                  */
/* Section:  All sections                                            */
/*********************************************************************/
typedef int Int32;
typedef short int Int16;
typedef char Int8;
typedef unsigned int UInt32;
typedef unsigned short int UInt16;
typedef unsigned char UInt8;

/*Library Subroutines*/
void *memcpy(void *str1, const void *str2, unsigned int n);

/* assembly language subroutines */
char GetChar (void);
void GetStringSB (char String[], int StringBufferCapacity);
void Init_UART0_IRQ (void);
void PutChar (char Character);
void PutNumHex (UInt32);
void PutNumU (UInt8);
void PutStringSB (char String[], int StringBufferCapacity);
void nextLine(void);
void init_PIT_IRQ(void);
void init_LED(void);
void Enable_Red_LED(void);
void Enable_Green_LED(void);
void Disable_Red_LED(void);
void Disable_Green_LED(void);
