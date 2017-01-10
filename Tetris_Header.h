
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
