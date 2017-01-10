/*********************************************************************/
/* Terminal Tetris for FRDM-KL46Z microcontroller. Tetris game that  */
/*	can be played in the terminal									 */
/* Name:  Chris Guarini                                              */
/* Date:  1/10/2017		                                             */
/*-------------------------------------------------------------------*/
/* Template:  R. W. Melton                                           */
/*            November 14, 2016                                      */
/*********************************************************************/

#include "MKL46Z4.h"
#include "Tetris_Header.h"

#define FALSE      (0)
#define TRUE       (1)

#define MAX_STRING (79)
#define Q_REC_SZ (18)
#define NUM_ENQD (17)

/*ASCII INTERFACE*/
	/*blocks*/
#define emptyBlock ('-')
#define placedBlock ('8')
#define movingBlock ('#')
	/*board*/
#define boardSize (rows*cols)
#define rows (8)
#define cols (8)/*MUST BE EVEN*/

/*Map of the board*/
/*
(0,0)(0,1)(0,j)
(1,0)(1,1)(1,j)
(i,0)(i,1)(i,j)
*/

/*Prompts*/
char initialPrompt[MAX_STRING]="Tetris";
char GameOverPrompt[MAX_STRING]="GAME OVER";
char ScorePrompt[MAX_STRING]="Your Score: ";
char playAgainPrompt[MAX_STRING]="Press any key to play again.";

/*Score*/
int Score;
/*PIT Timer variables*/
extern int Count;
extern char RunStopWatch;
/*UART0 Recieve Queue*/
extern char RxQRecord[Q_REC_SZ];

/*Variables that determine what block type and what position
the player controlled block is in
blockType: 0=line, 1=L, 2=J, 3=S, 4=Z, 5=Square,6=T 
position: 0=original, 1=90 degree rotation, 2=180 rotation, 3=270 rotation*/
unsigned char blockType,position;

/*Block creation based on tetrominoes*/
/*line, L, J, S, Z, Square,T*/
void createLine(char map[rows][cols]){
	/*----####----*/
	/*------------*/
	map[0][cols/2]=movingBlock;
	map[0][cols/2+1]=movingBlock;
	map[0][cols/2-1]=movingBlock;
	map[0][cols/2-2]=movingBlock;
}

void createL(char map[rows][cols]){
	/*----###----*/
	/*----#-------*/
	map[0][cols/2]=movingBlock;
	map[0][cols/2+1]=movingBlock;
	map[0][cols/2-1]=movingBlock;
	map[1][cols/2-1]=movingBlock;
}
void createJ(char map[rows][cols]){
	/*-----###----*/
	/*-------#----*/
	map[0][cols/2]=movingBlock;
	map[0][cols/2+1]=movingBlock;
	map[0][cols/2-1]=movingBlock;
	map[1][cols/2+1]=movingBlock;
}

void createZ(char map[rows][cols]){
	/*----##------*/
	/*-----##-----*/
	map[0][cols/2]=movingBlock;
	map[1][cols/2]=movingBlock;
	map[0][cols/2-1]=movingBlock;
	map[1][cols/2+1]=movingBlock;
}

void createS(char map[rows][cols]){
	/*-----##-----*/
	/*----##------*/
	map[1][cols/2]=movingBlock;
	map[0][cols/2]=movingBlock;
	map[1][cols/2-1]=movingBlock;
	map[0][cols/2+1]=movingBlock;
}

void createSquare(char map[rows][cols]){
	/*-----##-----*/
	/*-----##-----*/
	map[0][cols/2]=movingBlock;
	map[1][cols/2]=movingBlock;
	map[0][cols/2+1]=movingBlock;
	map[1][cols/2+1]=movingBlock;

}

void createT(char map[rows][cols]){
	/*----###-----*/
	/*-----#------*/
	map[0][cols/2]=movingBlock;
	map[1][cols/2]=movingBlock;
	map[0][cols/2-1]=movingBlock;
	map[0][cols/2+1]=movingBlock;
}
void clearmovingBlocks(char map[rows][cols]){
	int i,j;
	/*iterate through the map from bottom up*/
	for( i=rows;i>=0;i--){
		/*left to right*/
		for( j=0;j<cols;j++){
			/*Check if coordinate is a player controlled block*/
			if (map[i][j]==movingBlock){
				map[i][j]=emptyBlock;/*delete player controlled block*/
			}
		}
	}
}

/*Rotates the line shape
map=gameboard
i,j=coordinates (i,j) of bottom leftmost player controlled block
position: 0=horizontal, 1=vertical*/
void rotateLine(char map[rows][cols], int i, int j){
	/*POSITION 0  */
	/*----####----*/
	/*------------*/
	/*check if horizontal or vertical*/
	if(position==0 && i>2){/*not enough space, do not rotate*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-2][j]!=placedBlock && map[i-3][j]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-2][j]=movingBlock;
			map[i-3][j]=movingBlock;
			position=1;
		}
	}
	else if(position==1&&j<cols-3){
		if(map[i][j]!=placedBlock && map[i][j+1]!=placedBlock && map[i][j+2]!=placedBlock && map[i][j+3]!=placedBlock){
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i][j+1]=movingBlock;
			map[i][j+2]=movingBlock;
			map[i][j+3]=movingBlock;
			position=0;
		}
	}
}

/*Rotates the L shape
map=gameboard
i,j=coordinates (i,j) of bottom leftmost player controlled block
4 positions*/
void rotateL(char map[rows][cols], int i, int j){
	/*POSITION 0  */
	/*----###-----*/
	/*----#-------*/
	/*check position*/
	if(position==0 && i>1 && j>0){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-2][j]!=placedBlock && map[i-2][j-1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-2][j]=movingBlock;
			map[i-2][j-1]=movingBlock;
			position=1;
		}
	}
	else if(position==1 && i>0 && j<cols-3){/*not enough space, dont rotate*/
		if(map[i-1][j]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i-1][j+2]!=placedBlock && map[i][j+2]!=placedBlock){
			clearmovingBlocks(map);
			map[i-1][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i-1][j+2]=movingBlock;
			map[i][j+2]=movingBlock;
			position=2;
		}
	}
	else if(position==2 && i>1 && j<cols){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-2][j]!=placedBlock && map[i][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-2][j]=movingBlock;
			map[i][j+1]=movingBlock;
			position=3;
		}
	}
	else if(position==3 && i>1 && j<cols-3){/*do not rotate if blocks would go off map*/
		if(map[i-1][j]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i-1][j+2]!=placedBlock && map[i][j]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i-1][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i-1][j+2]=movingBlock;
			map[i][j]=movingBlock;
			position=0;
		}
	}
}

/*Rotates the J shape
map=gameboard
i,j=coordinates (i,j) of bottom leftmost player controlled block
4 positions*/
void rotateJ(char map[rows][cols], int i, int j){
	/*POSITION 0  */
	/*-----###----*/
	/*-------#----*/
	/*check position*/
	if(position==0 && i>1 && j<cols){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i-2][j+1]!=placedBlock && map[i][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i-2][j+1]=movingBlock;
			map[i][j+1]=movingBlock;
			position=1;
		}
	}
	else if(position==1 && i>0 && j<cols-3){/*not enough space, dont rotate*/
		if(map[i][j]!=placedBlock && map[i][j+1]!=placedBlock && map[i][j+2]!=placedBlock && map[i+1][j]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i][j+1]=movingBlock;
			map[i][j+2]=movingBlock;
			map[i-1][j]=movingBlock;
			position=2;
		}
	}
	else if(position==2 && i>1 && j<cols){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-2][j]!=placedBlock && map[i-2][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-2][j]=movingBlock;
			map[i-2][j+1]=movingBlock;
			position=3;
		}
	}
	else if(position==3 && i>1 && j<cols-3){/*do not rotate if blocks would go off map*/
		if(map[i-1][j]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i-1][j+2]!=placedBlock && map[i][j+2]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i-1][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i-1][j+2]=movingBlock;
			map[i][j+2]=movingBlock;
			position=0;
		}
	}
}

/*Rotates the S shape
map=gameboard
i,j=coordinates (i,j) of bottom leftmost player controlled block
Only 2 positions, 0 and 1*/
void rotateS(char map[rows][cols], int i, int j){
	/*POSITION 0  */
	/*-----##-----*/
	/*----##------*/
	/*check position*/
	if(position==0 && i>1 && j<cols){/*do not rotate if blocks would go off map*/
		if(map[i-1][j]!=placedBlock && map[i-2][j]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i-1][j]=movingBlock;
			map[i-2][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i][j+1]=movingBlock;
			position=1;
		}
	}
	else if(position==1 && i>0 && j<cols-2){/*not enough space, dont rotate*/
		if(map[i-1][j+2]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i][j+1]!=placedBlock && map[i][j]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i-1][j+2]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i][j+1]=movingBlock;
			map[i][j]=movingBlock;
			position=0;
		}
	}
}

/*Rotates the Z shape
map=gameboard
i,j=coordinates (i,j) of bottom leftmost player controlled block
Only 2 positions, 0 and 1*/
void rotateZ(char map[rows][cols], int i, int j){
	/*POSITION 0  */
	/*----##------*/
	/*-----##-----*/
	/*check position*/
	if(position==0 && i>1 && j<cols){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i-2][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i-2][j+1]=movingBlock;
			position=1;
		}
	}
	else if(position==1 && i>0 && j<cols && j>0){/*not enough space, dont rotate*/
		if(map[i][j]!=placedBlock && map[i][j+1]!=placedBlock && map[i-1][j]!=placedBlock && map[i-1][j-1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i][j+1]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-1][j-1]=movingBlock;
			position=0;
		}
	}
}

/*Rotates the T shape
map=gameboard
i,j=coordinates (i,j) of bottom leftmost player controlled block
4 positions*/
void rotateT(char map[rows][cols], int i, int j){
	/*POSITION 0  */
	/*----###-----*/
	/*-----#------*/
	/*check position*/
	if(position==0 && i>1 && j>0){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-2][j]!=placedBlock && map[i-2][j-1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-2][j]=movingBlock;
			map[i-1][j-1]=movingBlock;
			position=1;
		}
	}
	else if(position==1 && i>0 && j<cols-3){/*not enough space, dont rotate*/
		if(map[i-1][j]!=placedBlock && map[i-1][j+1]!=placedBlock && map[i-1][j+2]!=placedBlock && map[i][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i-1][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			map[i-1][j+2]=movingBlock;
			map[i][j+1]=movingBlock;
			position=2;
		}
	}
	else if(position==2 && i>1 && j<cols){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-2][j]!=placedBlock && map[i-1][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-2][j]=movingBlock;
			map[i-1][j+1]=movingBlock;
			position=3;
		}
	}
	else if(position==3 && i>1 && j<cols && j>0){/*do not rotate if blocks would go off map*/
		if(map[i][j]!=placedBlock && map[i-1][j]!=placedBlock && map[i-1][j-1]!=placedBlock && map[i-1][j+1]!=placedBlock){
			/*no placed blocks are in the way of the rotation*/
			clearmovingBlocks(map);
			map[i][j]=movingBlock;
			map[i-1][j]=movingBlock;
			map[i-1][j-1]=movingBlock;
			map[i-1][j+1]=movingBlock;
			position=0;
		}
	}
}



/*Rotates the player controlled block clockwise 90 degrees*/
void rotateBlock(char map[rows][cols]){
	int i;
	int j;
	/*iterate through the map from bottom up*/
	for( i=rows;i>=0;i--){
		/*left to right*/
		for( j=0;j<cols;j++){
			/*Check if coordinate is a player controlled block*/
			if (map[i][j]==movingBlock){
				goto foundPlayerBlock; /*break nested loops*/
			}
		}
	}
	foundPlayerBlock:
	/*blockType: 0=line, 1=L, 2=J, 3=S, 4=Z, 5=Square,6=T */
	switch(blockType){
			case 0:
				rotateLine(map,i,j);
				break;
			case 1:
				rotateL(map,i,j);
				break;
			case 2:
				rotateJ(map,i,j);
				break;
			case 3:
				rotateS(map,i,j);
				break;
			case 4:
				rotateZ(map,i,j);
				break;
			case 5:
				/*Square:
				same in every position*/
				break;
			case 6:
				rotateT(map,i,j);
				break;
		}
}

/*Create a random block from a pseudorandom number generated from the PIT*/
void RandomBlock(char map[rows][cols]){
  /*Uses the 2 MSB of Count to get a random number between 0 and 7*/
	unsigned int Before, After, RandNum;
	GetRandom:
		if( Count!=0){
			Before=Count;
		}
		else{
		Before=0xFFFF;
		}
		/*go from 32 bits to 3 bits*/
		/*Number from 0-7*/
		RandNum=Before & 0x00000007;
		blockType=RandNum;
		position=0;
		switch(RandNum){
			/*line, L, J, S, Z, Square,T*/
			case 0:
				createLine(map);
				break;
			case 1:
				createL(map);
				break;
			case 2:
				createJ(map);
				break;
			case 3:
				createS(map);
				break;
			case 4:
				createZ(map);
				break;
			case 5:
				createSquare(map);
				break;
			case 6:
				createT(map);
				break;
			case 7:
				/*only 7 options, reroll*/
				goto GetRandom;
				break;
		}
		
	}
	/*Checks to see if a key has been pressed*/
	/*Use GetChar() afterwards, otherwise the queue can fill eventually*/
	int keyPressed(void){
		/*Checks the RxQRecord to see if there are any characters enqueued*/
		if(RxQRecord[NUM_ENQD]!=0){//if character is enqueued
			return 1;/*return true*/
		}
		else{//character not enqueued
			return 0;/*return false*/
		}
	}
	/* Cycles the red and green LEDS every second
		one off while the other is on*/
void cycleLEDS(void){
	int cycle;
  int cycleTimer;
	while(1){
			/*Cycle LEDs*/
			/*Cycle the LEDS every second*/
			if((cycleTimer+100)<Count){
					cycleTimer=Count;
					cycle=(Count%2);
					if(cycle==1){
						 /*cycle to red*/
							Enable_Red_LED();
							Disable_Green_LED();
					}
					if (cycle==0){
							/*cycle to green*/
							Enable_Green_LED();
							Disable_Red_LED();
					}
			}
			if(keyPressed()){
				break;
			}
			
	}
}



	
	/*Creates an empty map to use as the game board*/
void createMap(char map[rows][cols]){
		int i;
		int j;
		/*iterate through the map from top down left to right*/
		for( i=0;i<rows;i++){
			for( j=0;j<cols;j++){
				/*set all blocks to emptyBlock*/
				map[i][j]=emptyBlock;
			}
		}
	}
	
/*Prints the board onto the terminal*/	
void printMap(char map[rows][cols]){
	int i;
	int j;
	/*iterate through the map from top down left to right*/
	for( i=0;i<rows;i++){
		for( j=0;j<cols;j++){
			PutChar(map[i][j]);
		}
		nextLine();
	}
}

/*Clears the terminal by moving to new page
	and then prints the game board again*/
void refreshScreen(char map[rows][cols]){
	PutChar(0xC);
	printMap(map);
}

/* Triggered when player controlled block hits either bottom, or another block.
	Turn player controlled blocks into a placed blocks.
	Checks game over condition. If any block in top row, game over is triggered.
Returns: 0 if game over, else returns 1.*/
int hit(char map[rows][cols]){
		int i;
		int j;
		/*iterate through the map from bottom up*/
		for( i=rows;i>=0;i--){
			for( j=0;j<cols;j++){
				/*Check if coordinate is a player controlled block*/
				if (map[i][j]==movingBlock){
					map[i][j]=placedBlock;
				}
			}
		}
		/*check top row to see if game over*/
		for(j=0;j<cols;j++){
			if(map[0][j]==placedBlock){
				return 0;
			}
		}
		return 1;
		
	}

int moveLeft(char map[rows][cols]){
	int i;
	int j;
	char savedMap[rows][cols];
		/*save current map, incase of hit*/
		memcpy(savedMap,map,boardSize);
		/*iterate through the map from bottom up*/
		for( i=rows;i>=0;i--){
			for( j=0;j<cols;j++){
				/*Check if coordinate is a player controlled block*/
				if (map[i][j]==movingBlock){
					if(j==0){
						/*at leftmost position*/
						memcpy(map,savedMap,boardSize);
						goto leftFailed;
					}
					else if(map[i][j-1]==placedBlock){
						/*placed block to the left*/
						memcpy(map,savedMap,boardSize);
						goto leftFailed;
					}
					else{
						/*free to move left*/
						map[i][j-1]=movingBlock;
						map[i][j]=emptyBlock;
					}
				}
			}
		}
		leftFailed:
		return 1;
}

int moveRight(char map[rows][cols]){
	int i;
	int j;
	char savedMap[rows][cols];
		/*save current map, incase of hit*/
		memcpy(savedMap,map,boardSize);
		/*iterate through the map from bottom up*/
		for( i=rows;i>=0;i--){
			for( j=cols;j>=0;j--){
				/*Check if coordinate is a player controlled block*/
				if (map[i][j]==movingBlock){
					if(j==cols-1){
						/*at rightmost position*/
						memcpy(map,savedMap,boardSize);
						goto rightFailed;
					}
					else if(map[i][j+1]==placedBlock){
						/*placed block to the right*/
						memcpy(map,savedMap,boardSize);
						goto rightFailed;
					}
					else{
						/*free to move right*/
						map[i][j+1]=movingBlock;
						map[i][j]=emptyBlock;
					}
				}
			}
		}
		rightFailed:
		return 1;
}
	
	/*moves the player controlled block down one space*/
int progress(char map[rows][cols]){
		int i;
		int j;
		char savedMap[rows][cols];
		/*save current map, incase of hit*/
		memcpy(savedMap,map,boardSize);
		/*iterate through the map from bottom up*/
		for( i=rows;i>=0;i--){
			for( j=0;j<cols;j++){
				/*Check if coordinate is a player controlled block*/
				if (map[i][j]==movingBlock){
					if(i==rows-1){
						/*at bottom of board*/
						if(hit(savedMap)==1){
							RandomBlock(savedMap);
							memcpy(map,savedMap,boardSize);
							return 1;
						}
						else{
							/*Game Over*/
							return 0;
						}
					}
					else if(map[i+1][j]==placedBlock){
						/*hit a placed block*/
						if(hit(savedMap)==1){
							RandomBlock(savedMap);
							memcpy(map,savedMap,boardSize);
							return 1;
						}
						else{
							return 0;
						}
					}
					else{
						/*free to move*/
						map[i+1][j]=movingBlock;
						map[i][j]=emptyBlock;
					}
				}
			}
		}
		return 1;
	}

/*Checks if rows are complete and if so removes them
	and drops all other rows*/
void checkCompletetion(char map[rows][cols]){
	int i;
	int j;
	int inRow;/*counter for number of blocks*/
	for(i=0;i<rows;i++){
		/*iterate through the board from top down*/
		inRow=0;/*reset counter every row*/
		for(j=0;j<cols;j++){
			/*left to right*/
			if(map[i][j]==placedBlock){
				/*count every placed block in row*/
				inRow++;
			}
		}
		if(inRow==cols){
			/*if entire row is filled*/
			for(i=i;i>=0;i--){
				/*iterate through board from that row up*/
				for(j=0;j<cols;j++){
					/*left to right*/
					/*replace blocks with the block above*/
					if(map[i-1][j]==emptyBlock||map[i-1][j]==placedBlock){
						map[i][j]=map[i-1][j];
					}
					else if(map[i-1][j]==movingBlock & map[i][j]!=movingBlock){
						map[i][j]=emptyBlock;
					}
					if(i==0 & map[i][j]!=movingBlock){
						/*if top row, replace with empty blocks unless player controlled block*/
						map[i][j]=emptyBlock;
					}
				}
			}
			/*recursive call incase there are multiple filled rows at once*/
			Score+=cols;
			checkCompletetion(map);
		}
	}
}

int main (void) {
    
	/*declare local variables*/
	char map[rows][cols];	
	int refreshTimer,over;
	char input;
	
	
    /*Initialize UART0, PIT and LEDS*/
  __asm("CPSID   I");  /* mask interrupts */
    /*perform initializations*/
    init_PIT_IRQ();
    Init_UART0_IRQ();
    init_LED();
  __asm("CPSIE   I");/*unmask interrupts*/
    
    /*Start running the stop watch*/
    RunStopWatch=1;
    /*game loop*/   
		while(TRUE){
			PutStringSB(initialPrompt,MAX_STRING);
			nextLine();
			createMap(map);
			printMap(map);
			GetChar();
			RandomBlock(map);
			refreshScreen(map);
			Score=0;/*Reset Score*/
			refreshTimer=Count+200;
			while(1){
			/* Round Loop*/
				/*Check for key press*/
				if(keyPressed()){
					/*if key was pressed*/
						input=GetChar();
						if(input=='a'||input=='A'){
							/*if input was LEFT*/
							moveLeft(map);
							refreshScreen(map);
						}
						else if(input=='d'||input=='D'){
							/*if input was RIGHT*/
							moveRight(map);
							refreshScreen(map);
						}
						else if(input =='w'||input=='W'){
							/*Input was ROTATE*/
							rotateBlock(map);
							refreshScreen(map);
						}
				}
				else if(Count>refreshTimer){
					/*Progress game and refresh screen every 125ms*/
					refreshTimer=Count+125;
					over=progress(map);
					if(over==0){
						/*Game over, break out of round loop*/
						break;
					}
					refreshScreen(map);
				}
				
				checkCompletetion(map);
			
			}
			/*Game over Prompts*/
			PutStringSB(GameOverPrompt,MAX_STRING);
			nextLine();
			PutStringSB(ScorePrompt,MAX_STRING);
			PutNumU(Score);
			nextLine();
			PutStringSB(playAgainPrompt,MAX_STRING);
			/*cycle LEDS until key is pressed*/
			cycleLEDS();
			GetChar();/*clear keypress out of RxQueue*/
		}

	

  

  for (;;) { /* do forever */
  } /* do forever */

  return (0);
} /* main */
