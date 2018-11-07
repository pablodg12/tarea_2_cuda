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

__global__ void step_periodic(int * array,int *buffer,int rows, int cols){
  int tId = threadIdx.x + blockIdx.x * blockDim.x;
if(tId < rows*cols){
    int x = tId%(cols);
    int y = (int) tId/rows;

    int c_aux = x -1;
    if (c_aux < 0){
      c_aux = cols -1;
    }
    if (buffer[(y*cols + c_aux) + rows*cols] == 1 && buffer[(y*cols + c_aux) + 3*rows*cols] == 1){
       array[tId] = 1;
    }else if (buffer[(y*cols + c_aux)] == 1 && buffer[(y*cols + c_aux) + 2*rows*cols] == 1){
      array[tId] = 0;
    }else if (buffer[(y*cols + c_aux)] == 1){
        array[tId] = 1;
    }else if (buffer[(y*cols + c_aux)] == 0){
      array[tId] = 0;
    }

    c_aux = x + 1;
    if (c_aux == cols){
      c_aux = 0;
    }

    if (buffer[(y*cols + c_aux) + rows*cols] == 1 && buffer[(y*cols + c_aux) + 3*rows*cols] == 1){
       array[tId+2*rows*cols] = 1;
    }else if (buffer[(y*cols + c_aux)] == 1 && buffer[(y*cols + c_aux) + 2*rows*cols] == 1){
      array[tId+2*rows*cols] = 0;
    }else if (buffer[(y*cols + c_aux)+ 2*rows*cols] == 1){
        array[tId+2*rows*cols] = 1;
    }else if (buffer[(y*cols + c_aux)+ 2*rows*cols] == 0){
      array[tId+2*rows*cols] = 0;
    }
    c_aux = y - 1;
    if (c_aux <0){
      c_aux = rows-1;
    }

    c_aux = (((y-1)%rows)+rows)%rows*cols;

    if (buffer[(c_aux + x)] == 1 && buffer[(c_aux + x) + 2*rows*cols] == 1){
       array[tId+rows*cols] = 1;
    }else if (buffer[(c_aux + x)+rows*cols] == 1 && buffer[(c_aux + x) + 3*rows*cols] == 1){
      array[tId+rows*cols] = 0;
    }else if (buffer[ (c_aux + x) + rows*cols ] == 1){
      array[tId+rows*cols] = 1;
    }else if (buffer[ (c_aux + x) + rows*cols ] == 0){
      array[tId+rows*cols] = 0;
    }

    c_aux = (((y+1)%rows)*cols);

    if (buffer[(c_aux + x)] == 1 && buffer[(c_aux + x) + 2*rows*cols] == 1){
       array[tId+3*rows*cols] = 1;
    }else if (buffer[(c_aux + x)+rows*cols] == 1 && buffer[(c_aux + x) + 3*rows*cols] == 1){
      array[tId+3*rows*cols] = 0;
    }else if (buffer[ (c_aux + x) + 3*rows*cols ] == 1){
      array[tId+3*rows*cols] = 1;
    }else if (buffer[ (c_aux + x) + 3*rows*cols ] == 0){
      array[tId+3*rows*cols] = 0;
    }
  }
 }  
int main(int argc, char const *argv[])
{
  int rows, cols;
  int *array;
  int *d_array;
  int *d_buffer;
  readInput_soa("../initial.txt", &array, &rows, &cols);
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
