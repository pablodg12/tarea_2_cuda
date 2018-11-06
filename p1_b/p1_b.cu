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
  extern __shared__ int buffer[];
  int tId = threadIdx.x + blockIdx.x * blockDim.x;
  if(threadIdx.x < 256){
    for(int i = threadIdx.x; i < rows*cols; i+=256 ){
      if (array[i] == 1 && array[i + 2*rows*cols] == 1){
        if(array[i + rows*cols] == 0 && array[i+rows*cols*3] == 0){
          buffer[i] = 0;
          buffer[i + 2*rows*cols] = 0;
          buffer[i + rows*cols] = 1;
          buffer[i+rows*cols*3] = 1;
        }
      }else if (array[i + rows*cols] == 1 && array[i+rows*cols*3] == 1){
        if(array[i] == 0 && array[i + 2*rows*cols] == 0){
          buffer[i + rows*cols] = 0;
          buffer[i+rows*cols*3] = 0;
          buffer[i] = 1;
          buffer[i + 2*rows*cols] = 1;
        }
      }else{
          buffer[i + rows*cols] = array[i + rows*cols];
          buffer[i+rows*cols*3] = array[i+rows*cols*3];
          buffer[i]  = array[i];
          buffer[i + 2*rows*cols] = array[i+2*rows*cols];
      }
    }
  }
  __syncthreads();

  //if(tId == 1){
   // for(int i = 0; i < rows*cols*4;i++){
   //   printf("%d ", buffer[i]);
   //   printf(" ");
   //   if ((i+1)%9 == 0){
  //        printf("|");
  //      }
 // }
//  printf("\n");
//}

if(tId < rows*cols){
    int x = tId%(cols);
    int y = (int) tId/rows;


    int c_aux = x -1;
    if (c_aux < 0){
      c_aux = cols -1;
    }
    if (buffer[(y*rows + c_aux)] == 1){
        array[tId] = 1;
    }else if (buffer[(y*rows + c_aux)] == 0){
      array[tId] = 0;
    }
    c_aux = x + 1;
    if (c_aux == cols){
      c_aux = 0;
    }
    if (buffer[(y*rows + c_aux) + 2*rows*cols ] == 1){
      array[tId+ 2*rows*cols] = 1;
    }else if (buffer[(y*rows + c_aux) + 2*rows*cols ] == 0){
      array[tId+ 2*rows*cols] = 0;
    }
    c_aux = y - 1;
    if (c_aux <0){
      c_aux = rows-1;
    }
    if (buffer[ (c_aux*rows + x) + rows*cols ] == 1){
      array[tId + rows*cols] = 1;
    }else if (buffer[ (c_aux*rows + x) + rows*cols ] == 0){
      array[tId + rows*cols] = 0;
    }
    c_aux = y + 1;
    if (c_aux == rows){
      c_aux = 0;
    }
    if (buffer[ (c_aux*rows + x)+ 3*rows*cols ] == 1){
      array[tId+ 3*rows*cols] = 1;
    }else if (buffer[ (c_aux*rows + x) + 3*rows*cols ] == 0){
      array[tId + 3*rows*cols] = 0;
    }
  }
}


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
    step_periodic_Soa<<<grid_size, block_size,rows*cols*4>>>(d_Soa, rows, cols);
  }

  cudaMemcpy(Soa, d_Soa, 4 * rows * cols * sizeof(int), cudaMemcpyDeviceToHost);
  cudaFree(d_Soa);


return 0;

}

