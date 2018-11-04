#include <stdio.h>
#include <math.h>

void printMatrix(const int *A, int rows, int cols) {
    for(int i = 0; i < rows*cols*4; i++){
        printf("%d ", A[i]);   
        printf(" ");
        if ((i+1)%9 == 0){
          printf("|");
        }
    }
    printf("\n");
};

void readInput_soa(const char *filename, int **Soa,  int *rows, int *cols) {
  FILE *file;
  file = fopen(filename, "r");
  fscanf(file, "%d %d", rows, cols);
  int * A_F0 = (int *) malloc(*rows * (*cols)* (4) * sizeof(int));
  for(int i = 0; i < *rows*(*cols)*(4); i++) { 
    fscanf(file, "%d ", &A_F0[i]); 
  }
  fclose(file);
  *Soa = A_F0;
};

__global__ void step_periodic_Soa(int * array,int rows, int cols){
  int tId = threadIdx.x + blockIdx.x * blockDim.x;
  if (tId < rows*cols){

    int x = tId%(cols);
    int y = (int) tId/rows;

    //Colission
    if (array[tId] == 1 && array[tId + 2*rows*cols] == 1){
      if(array[tId + rows*cols] == 0 && array[tId+rows*cols*3] == 0){
        array[tId] = 0;
        array[tId + 2*rows*cols] = 0;
        array[tId + rows*cols] = 1;
        array[tId+rows*cols*3] = 1;
      }
    }
    if (array[tId + rows*cols] == 1 && array[tId+rows*cols*3] == 1){
      if(array[tId] == 0 && array[tId + 2*rows*cols] == 0){
        array[tId + rows*cols] = 0;
        array[tId+rows*cols*3] = 0;
        array[tId] = 1;
        array[tId + 2*rows*cols] = 1;
      }
    }
    //streaming

    //right
    int c_aux = x + 1; 
    if (c_aux == cols){
        c_aux = 0;
      }
    if (array[tId] == 1){
        array[(y*rows + c_aux)] = array[tId]*2;
    }
    //left
    c_aux = x - 1;
    if (c_aux < 0){
      c_aux = cols -1;
    }
    if (array[tId+ 2*rows*cols] == 1){
      array[(y*rows + c_aux) + 2*rows*cols] = array[tId+ 2*rows*cols]*2;
    }

    //top
    c_aux = y + 1;
    if (c_aux == rows){
      c_aux = 0;
    }
    if (array[tId + rows*cols] == 1){
      array[(c_aux*rows + x) + + rows*cols] = array[tId+ rows*cols]*2;
    }

    //bottom
    c_aux = y + 1;
    if (c_aux < 0){
      c_aux = rows-1;
    }
    if (array[tId+ 3*rows*cols] == 1){
      array[(c_aux*rows + x)+ 3*rows*cols] = array[tId+ 3*rows*cols]*2;
    }

    //Correction
    if(array[tId] == 1){
      array[tId] = 0;
    }
    if(array[tId] == 2){
      array[tId] = 1;
    }
    if(array[tId+ rows*cols] == 1){
      array[tId+ rows*cols] = 0;
    }
    if(array[tId+ rows*cols] == 2){
      array[tId+ rows*cols] = 1;
    }
    if(array[tId+ 2*rows*cols] == 1){
      array[tId+ 2*rows*cols] = 0;
    }
    if(array[tId+ 2*rows*cols] == 2){
      array[tId+ 2*rows*cols] = 1;
    }
    if(array[tId+ 3*rows*cols] == 1){
      array[tId+ 3*rows*cols] = 0;
    }
    if(array[tId+ 3*rows*cols] == 2){
      array[tId+ 3*rows*cols] = 1;
    }

  }
};

int main(int argc, char const *argv[])
{
  int rows, cols;
  int *Soa;
  int *d_Soa;

  readInput_soa("../initial.txt", &Soa, &rows, &cols);

  //printMatrix(Soa,rows,cols);

  int n = (int)(rows*cols);
  int block_size = 256;
  int grid_size = (int) ceil((float)n / block_size);

  cudaMalloc(&d_Soa, 4 * rows * cols * sizeof(int));
  cudaMemcpy(d_Soa, Soa, 4 * rows * cols * sizeof(int), cudaMemcpyHostToDevice);

  for(int k = 0; k < 1000; k++){
    step_periodic_Soa<<<grid_size, block_size>>>(d_Soa, rows, cols);
  }

  cudaMemcpy(Soa, d_Soa, 4 * rows * cols * sizeof(int), cudaMemcpyDeviceToHost);
  cudaFree(d_Soa);


return 0;

}

