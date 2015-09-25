/***  ***/

#include <stdio.h>

int main(int argc, char *argv[]) {

	FILE *binFile;

  	int aux;
  	int i;

  	if (argc != 2 ) {
  		printf("Sintaxe: %s <bin_file> > <txt_file>\n",argv[0]);
  		return 1;
  	}

  	if ( !(binFile = fopen(argv[1],"rb")) ) {
  		printf("Error opening file '%s'.\n",argv[1]);
  		return 1;
  	}

#if 0
    /* Reads the iNES header but do not outputs to the txt file */
	for(i=0; i<16; i++)
        fgetc(binFile); // only for ROM conversions
#endif
        
	while (1)  {
    	aux = fgetc(binFile);
    	if (aux == EOF)
    		break;

  		printf("%.2X\n",aux);
  	}


	fclose(binFile);

  	return 0;
}
