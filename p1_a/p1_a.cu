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

__global__ void step_periodic(int * array,int *buffer,int rows, int cols){
  int tId = threadIdx.x + blockIdx.x * blockDim.x;

if(tId < rows*cols){
    int x = tId%(cols);
    int y = (int) tId/rows;

    int c_aux = x -1;
    if (c_aux < 0){
      c_aux = cols -1;
    }
    if (buffer[(y*rows + c_aux)*4 + 1] == 1 && buffer[(y*rows + c_aux)*4 + 3] == 1){
       array[tId*4] = 1;
    }else if (buffer[(y*rows + c_aux)*4] == 1 && buffer[(y*rows + c_aux) + 2] == 1){
      array[tId*4] = 0;
    }else if (buffer[(y*rows + c_aux)*4] == 1){
        array[tId*4] = 1;
    }else if (buffer[(y*rows + c_aux)*4] == 0){
      array[tId*4] = 0;
    }

    c_aux = x + 1;
    if (c_aux == cols){
      c_aux = 0;
    }

    if (buffer[(y*rows + c_aux)*4+1] == 1 && buffer[(y*rows + c_aux)*4 + 3] == 1){
       array[tId*4+2] = 1;
    }else if (buffer[(y*rows + c_aux)*4] == 1 && buffer[(y*rows + c_aux)*4 + 2] == 1){
      array[tId*4+2] = 0;
    }else if (buffer[(y*rows + c_aux)*4+ 2] == 1){
        array[tId*4+2] = 1;
    }else if (buffer[(y*rows + c_aux)*4+ 2] == 0){
      array[tId*4+2] = 0;
    }

    c_aux = (((y-1)%rows)+rows)%rows*cols;

    if (buffer[(c_aux + x)*4] == 1 && buffer[(c_aux + x)*4+2] == 1){
       array[tId*4+1] = 1;
    }else if (buffer[(c_aux + x)*4+1] == 1 && buffer[(c_aux + x)*4+3] == 1){
      array[tId*4+1] = 0;
    }else if (buffer[ (c_aux + x)*4 + 1 ] == 1){
      array[tId*4+1] = 1;
    }else if (buffer[ (c_aux + x)*4 + 1 ] == 0){
      array[tId*4+1] = 0;
    }

    c_aux = (((y+1)%rows)*cols);

    if (buffer[(c_aux + x)*4] == 1 && buffer[(c_aux + x)*4 + 2] == 1){
       array[tId*4+3] = 1;
    }else if (buffer[(c_aux + x)*4+1] == 1 && buffer[(c_aux + x)*4 + 3] == 1){
      array[tId*4+3] = 0;
    }else if (buffer[ (c_aux + x)*4 + 3 ] == 1){
      array[tId*4+3] = 1;
    }else if (buffer[ (c_aux + x)*4 +3] == 0){
      array[tId*4+3] = 0;
    }
  }
}

int main(int argc, char const *argv[])
{
  int rows, cols;
  int *array;
  int *d_array;
  int *d_buffer;
  readInput_aos("../initial.txt", &array, &rows, &cols);

  int n = (int)(rows*cols);
  int block_size = 256;
  int grid_size = (int) ceil((float) n/ block_size);

  cudaMalloc(&d_array ,4*rows * cols * sizeof(int));
  cudaMalloc(&d_buffer,4*rows*cols*sizeof(int));
  cudaMemcpy(d_array, array,4* rows * cols * sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_buffer, array,4* rows * cols * sizeof(int), cudaMemcpyHostToDevice);
  for(int k = 0; k < 1000; k++){
    step_periodic<<<grid_size, block_size>>>(d_array, d_buffer, rows, cols);
    cudaMemcpy(d_buffer,d_array,4*rows*cols * sizeof(int), cudaMemcpyDeviceToDevice);
  }
  cudaMemcpy(array, d_array, 4*rows * cols * sizeof(int), cudaMemcpyDeviceToHost);
  cudaFree(d_array);
  cudaFree(d_buffer);

  return(0);
}
