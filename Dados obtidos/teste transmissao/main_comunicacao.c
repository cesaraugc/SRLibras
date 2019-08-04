
/**************************************************

file: testeRS232.c
Le um número (0 a 255) do teclado, envia e recebe um byte correspondente ao dobro do valor

compile com: gcc testeRS232.c rs232.c -Wall -Wextra -o2 -o testeRS232

**************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#ifdef _WIN32
#include <Windows.h>
#else
#include <unistd.h>
#endif

#include "rs232.h"



int main()
{
  int i, n;
  int cport_nr1=8,        /* usar o número da COM - 1 */
      cport_nr2=9,        /* usar o número da COM - 1 */
      bdrate=115200;

  unsigned char buf[4096],num;

  char mode[]={'8','N','2',0};

  double total_time;
	clock_t start, end;

  if(RS232_OpenComport(cport_nr2, bdrate, mode))
  {
    printf("Can not open comport2\n");
//    return(0);
  }
  
  if(RS232_OpenComport(cport_nr1, bdrate, mode))
  {
    printf("Can not open comport1\n");
 //   return(0);
  }
  


	while(1){
		// Envia um byte digitado
		printf("Digite Num:");
		scanf("%d",&num);
		RS232_SendByte(cport_nr1,num);
		printf("Enviado: %d\n", num);

		Sleep(100);	
    
    start = clock();
	
		// recebe n bytes no buffer (maximo 4096)
		n = RS232_PollComport(cport_nr1, buf, 4096);

    end = clock();
    //calulate total time in seconds
    total_time = ((double) (end - start)) / CLOCKS_PER_SEC;
    printf("\nTime taken to receive a byte is: %f\n", total_time);
	
		printf("n=%d\n",n);
		
		for(i=0;i<n;i++)
			printf("buf[%d]=%d\n",i,buf[i]);

	}

  return(0);
}

