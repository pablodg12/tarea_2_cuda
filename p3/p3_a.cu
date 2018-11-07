#include <stdio.h>
#include <math.h>

void readInput(const char *filename, int **Aos, int *rows, int *cols) {
  FILE *file;
  file = fopen(filename, "r");
  
  fscanf(file, "%d %d", rows, cols);
  int * A_F1 = (int *) malloc(*rows * (*cols)* (4) * sizeof(int));
  int * A_F2 = (int *) malloc(*rows * (*cols) * sizeof(int));
  for(int j = 0; j <  4; j++) {
    int counter = 0;
    for(int i = 0; i < *cols*(*rows); i++){
      fscanf(file, "%d ", &A_F1[counter +j]);
      counter = counter + 4;
      }
  }
  int counter = 0;
  for(int j = 0; j < *cols*(*rows);j++){
    A_F2[j] = A_F1[counter]*1 + A_F1[counter+1]*2 + A_F1[counter+2]*2*2 + A_F1[counter+3]*2*2*2;
    counter = counter +4;
  }
  *Aos = A_F2;
}

void printMatrix(int *A, int rows, int cols) {
    for(int i = 0; i < rows*cols; i++){
        printf("%i ", A[i]);
    }
    printf("\n");
};

__global__ void step_periodic(int * array,int *buffer,int rows, int cols){
  int tId = threadIdx.x + blockIdx.x * blockDim.x;
  if (tId < rows*cols){
    int c_aux;
    int reject = 1;
    int x = tId%(cols);
    int y = (int) tId/rows;
    int total = 0;


    c_aux = (x-1 < 0 ? cols-1 : x-1);
    reject = (x-1 < 0 ? 0:1);

    total = (reject ==1? (buffer[(y*cols + c_aux)]==1?(buffer[(y*cols + c_aux)] == 3?(buffer[(y*cols + c_aux)] == 10? (buffer[(y*cols + c_aux)] == 9?(buffer[(y*cols + c_aux)]==7?(buffer[(y*cols + c_aux)]==11?(buffer[(y*cols + c_aux)]==13?(buffer[(y*cols + c_aux)] == 15? total+1:0):0):0):0):0):0):0):0):0);
    total = (c_aux==0? (buffer[(y*cols + c_aux)]==4?(buffer[(y*cols + c_aux)] == 10?(buffer[(y*cols + c_aux)] == 6? (buffer[(y*cols + c_aux)] == 12?(buffer[(y*cols + c_aux)]==7?(buffer[(y*cols + c_aux)]==13?(buffer[(y*cols + c_aux)]==14?(buffer[(y*cols + c_aux)] == 15? total+1:0):0):0):0):0):0):0):0):0);

    c_aux = (x+1 == cols ? 0: x+1);
    reject = (x+1 == cols ? 0:1);

    total = (reject ==1? (buffer[(y*cols + c_aux)]==4?(buffer[(y*cols + c_aux)] == 10?(buffer[(y*cols + c_aux)] == 6? (buffer[(y*cols + c_aux)] == 12?(buffer[(y*cols + c_aux)]==7?(buffer[(y*cols + c_aux)]==13?(buffer[(y*cols + c_aux)]==14?(buffer[(y*cols + c_aux)] == 15? total+4:0):0):0):0):0):0):0):0):0);
    total = (c_aux==0? (buffer[(y*cols + c_aux)]==1?(buffer[(y*cols + c_aux)] == 3?(buffer[(y*cols + c_aux)] == 10? (buffer[(y*cols + c_aux)] == 9?(buffer[(y*cols + c_aux)]==7?(buffer[(y*cols + c_aux)]==11?(buffer[(y*cols + c_aux)]==13?(buffer[(y*cols + c_aux)] == 15? total+4:0):0):0):0):0):0):0):0):0);

    c_aux = (((y+1)%rows)*cols);
    reject = (y+1 == cols ? 0:1);

    total = (reject ==1? (buffer[(c_aux + x)]==2?(buffer[(c_aux + x)] == 3?(buffer[(c_aux + x)] == 6? (buffer[(c_aux + x)] == 5?(buffer[(c_aux + x)]==7?(buffer[(c_aux + x)]==11?(buffer[(c_aux + x)]==14?(buffer[(c_aux + x)] == 15? total+2:0):0):0):0):0):0):0):0):0);
    total = (c_aux==0? (buffer[(c_aux + x)]==8?(buffer[(c_aux + x)] == 12?(buffer[(c_aux + x)] == 5? (buffer[(c_aux + x)] == 9?(buffer[(c_aux + x)]==14?(buffer[(c_aux + x)]==13?(buffer[(c_aux + x)]==11?(buffer[(c_aux + x)] == 15? total+2:0):0):0):0):0):0):0):0):0);

    c_aux = (((y-1)%rows)+rows)%rows*cols;
    reject = (y-1 < 0 ? 0:1);


    total = (c_aux==0? (buffer[(c_aux + x)]==2?(buffer[(c_aux + x)] == 3?(buffer[(c_aux + x)] == 6? (buffer[(c_aux + x)] == 5?(buffer[(c_aux + x)]==7?(buffer[(c_aux + x)]==11?(buffer[(c_aux + x)]==14?(buffer[(c_aux + x)] == 15? total+2:0):0):0):0):0):0):0):0):0);
    total = (reject ==1? (buffer[(c_aux + x)]==8?(buffer[(c_aux + x)] == 12?(buffer[(c_aux + x)] == 5? (buffer[(c_aux + x)] == 9?(buffer[(c_aux + x)]==14?(buffer[(c_aux + x)]==13?(buffer[(c_aux + x)]==11?(buffer[(c_aux + x)] == 15? total+2:0):0):0):0):0):0):0):0):0);

    array[tId] = total;
  }
}
int main(int argc, char const *argv[])
{
  int rows, cols;
  int *array;
  int *d_array;
  int *d_buffer;
  readInput("../initial.txt", &array, &rows, &cols);

  int n = (int)(rows*cols);
  int block_size = 256;
  int grid_size = (int) ceil((float) n/ block_size);

  cudaMalloc(&d_array ,rows * cols * sizeof(int));
  cudaMalloc(&d_buffer,rows*cols*sizeof(int));
  cudaMemcpy(d_array, array, rows * cols * sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_buffer, array, rows * cols * sizeof(int), cudaMemcpyHostToDevice);
  for(int k = 0; k < 1000; k++){
    step_periodic<<<grid_size, block_size>>>(d_array, d_buffer, rows, cols);
    cudaMemcpy(d_buffer,d_array,rows*cols * sizeof(int), cudaMemcpyDeviceToDevice);
  }
  cudaMemcpy(array, d_array, rows * cols * sizeof(int), cudaMemcpyDeviceToHost);
  cudaFree(d_array);
  cudaFree(d_buffer);

  return(0);
}
