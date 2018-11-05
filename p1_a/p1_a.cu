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

__global__ void step_periodic_Aos(int * array,int rows, int cols){
  extern __shared__ int buffer[];
  int tId = threadIdx.x + blockIdx.x * blockDim.x;
  if(threadIdx.x < 256){
    for(int i = threadIdx.x; i < rows*cols; i+=256 ){
      if (array[i*4+0] == 1 && array[i*4+2] == 1){
        if(array[i*4+1] == 0 && array[i*4+3] == 0){
          buffer[i*4+0] = 0;
          buffer[i*4+2] = 0;
          buffer[i*4+1] = 1;
          buffer[i*4+3] = 1;
        }
      }else if(array[i*4+1] == 1 && array[i*4+3] == 1){
        if(array[i*4+0] == 0 && array[i*4+2] == 0){
          buffer[i*4+1] = 0;
          buffer[i*4+3] = 0;
          buffer[i*4+0] = 1;
          buffer[i*4+2] = 1;
          }
        }else{
          buffer[i*4+1] = array[i*4+1];
          buffer[i*4+3] = array[i*4+3];
          buffer[i*4+0] = array[i*4+0];
          buffer[i*4+2] = array[i*4+2];
      }
    }
  }
  __syncthreads();

  //if(tId == 1){
  //  for(int i = 0; i < rows*cols*4;i++){
  //    printf("%d ", buffer[i]);
  //    printf(" ");
  //  if ((i+1)%4 == 0){
  //        printf("|");
  //    }
 // }
  //printf("\n");
//}
  if (tId < rows*cols){
    int x = tId%(cols);
    int y = (int) tId/rows;

    int c_aux = x -1;
    if (c_aux < 0){
      c_aux = cols -1;
    }
    if (buffer[(y*rows + c_aux)*4] == 1){
      array[tId*4] = 1;
    }else if (buffer[(y*rows + c_aux)*4] == 0){
      array[tId*4] = 0;
    }

    c_aux = x + 1;
    if (c_aux == cols){
      c_aux = 0;
    }
    if (buffer[(y*rows + c_aux)*4+2] == 1){
      array[tId*4+2] = 1;
    }else if (buffer[(y*rows + c_aux)*4+2] == 0){
      array[tId*4+2] = 0;
    }

    //top
    c_aux = y - 1;
    if (c_aux <0){
      c_aux = rows-1;
    }
    if (buffer[(c_aux*rows + x)*4 + 1] == 1){
      array[tId*4+1] = 1;
    }else if (buffer[(c_aux*rows + x)*4+1] == 0){
      array[tId*4+1] = 0;
    }

    //bottom
    c_aux = y + 1;
    if (c_aux == rows){
      c_aux = 0;
    }
    if (buffer[(c_aux*rows + x)*4 + 3] == 1){
      array[tId*4+3] = 1;
    }else if(buffer[(c_aux*rows + x)*4+3] == 0){
      array[tId*4+3] = 0;
    }
  }
}

int main(int argc, char const *argv[])
{
  int rows, cols;
  int *Aos;
  int *d_Aos;

  readInput_aos("../initial.txt", &Aos, &rows, &cols);

  int n = (int)(rows*cols);
  int block_size = 256;
  int grid_size = (int) ceil((float)n / block_size);

  cudaMalloc(&d_Aos, 4 * rows * cols * sizeof(int));
  cudaMemcpy(d_Aos, Aos, 4 * rows * cols * sizeof(int), cudaMemcpyHostToDevice);

  for(int k = 0; k < 1000; k++){
    step_periodic_Aos<<<grid_size, block_size,rows*cols*4>>>(d_Aos, rows, cols);
  }

  cudaMemcpy(Aos, d_Aos, 4 * rows * cols * sizeof(int), cudaMemcpyDeviceToHost);
  cudaFree(d_Aos);

return 0;

}