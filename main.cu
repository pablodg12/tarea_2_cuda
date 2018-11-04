#include <stdio.h>
#include <math.h>

void printMatrix(const int *A, int rows, int cols) {
    for(int i = 0; i < rows*cols*4; i++){
        printf("%d ", A[i]);   
        printf(" ");
        if ((i+1)%4 == 0){
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

void readInput_aos(const char *filename, int **Aos, int *rows, int *cols) {
  FILE *file;
  file = fopen(filename, "r");
  fscanf(file, "%d %d", rows, cols);
  int * A_F1 = (int *) malloc(*rows * (*cols)* (4) * sizeof(int));
  for(int j = 0; j <  4; j++) {
    int counter = 0;
    for(int i = 0; i < *cols*(*rows); i++){
      fscanf(file, "%d ", &A_F1[counter +j]);
      counter = counter + 4;
      }
  }
  fclose(file);
  *Aos = A_F1;
}

//Periodic boundaries condition Array of Structures

__global__ void step_periodic_Aos(int * array,int rows, int cols){
  int tId = threadIdx.x + blockIdx.x * blockDim.x;
  if (tId < rows*cols){
    int x = tId%(cols);
    int y = (int) tId/rows;

    //Colission

    if (array[tId*4+0] == 1 && array[tId*4+2] == 1){
      if(array[tId*4+1] == 0 && array[tId*4+3] == 0){
        array[tId*4+0] = 0;
        array[tId*4+2] = 0;
        array[tId*4+1] = 1;
        array[tId*4+3] = 1;
      }
    }
    if (array[tId*4+1] == 1 && array[tId*4+3] == 1){
      if(array[tId*4+0] == 0 && array[tId*4+2] == 0){
        array[tId*4+1] = 0;
        array[tId*4+3] = 0;
        array[tId*4+0] = 1;
        array[tId*4+2] = 1;
      }
    }

    //streaming 

    //right
    int c_aux = x + 1;
    if (c_aux == cols){
      c_aux = 0;
    }
    if (array[tId*4] == 1){
      array[(y*rows + c_aux)*4] = array[tId*4]*2;
    }

    //left
    c_aux = x - 1;
    if (c_aux < 0){
      c_aux = cols -1;
    }
    if (array[tId*4+2] == 1){
      array[(y*rows + c_aux)*4 + 2] = array[tId*4+2]*2;
    }

    //top
    c_aux = y + 1;
    if (c_aux == rows){
      c_aux = 0;
    }
    if (array[tId*4+1] == 1){
      array[(c_aux*rows + x)*4 + 1] = array[tId*4+1]*2;
    }

    //bottom
    c_aux = y + 1;
    if (c_aux < 0){
      c_aux = rows-1;
    }
    if (array[tId*4+3] == 1){
      array[(c_aux*rows + x)*4 + 3] = array[tId*4+3]*2;
    }

    //Correction
    for(int i = 0; i < 4; i++){
      if(array[tId*4+i] == 1){
        array[tId*4+i] = 0;
      }
      if(array[tId*4+i] == 2){
        array[tId*4+i] = 1;
      }
    };
  }
};  

int main(int argc, char const *argv[])
{
  int rows, cols;
  int *Aos, *Soa;
  int *d_Aos, *d_Soa;

  readInput_aos("initial.txt", &Aos, &rows, &cols);
  readInput_soa("initial.txt", &Soa, &rows, &cols);

  //printMatrix(Aos,rows,cols);

  int n = (int)(rows*cols);
  int block_size = 256;
  int grid_size = (int) ceil((float)n / block_size);

  cudaMalloc(&d_Aos, 4 * rows * cols * sizeof(int));
  cudaMalloc(&d_Soa, 4 * rows * cols * sizeof(int));

  cudaMemcpy(d_Aos, Aos, 4 * rows * cols * sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_Soa, Soa, 4 * rows * cols * sizeof(int), cudaMemcpyHostToDevice);

  for(int k = 0; k < 1000; k++){
    step_periodic_Aos<<<grid_size, block_size>>>(d_Aos, rows, cols);
  }

  cudaMemcpy(Aos, d_Aos, 4 * rows * cols * sizeof(int), cudaMemcpyDeviceToHost);
  cudaMemcpy(Soa, d_Soa, 4 * rows * cols * sizeof(int), cudaMemcpyDeviceToHost);

  cudaFree(d_Aos);
  cudaFree(d_Soa);
  //printf("----- \n");
  //printMatrix(Aos,rows,cols);


  //printMatrix(Aos,rows,cols);
  //printf("----- \n");
  //printMatrix(Soa,rows,cols);

return 0;

}