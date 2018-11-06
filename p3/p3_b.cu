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

__global__ void step_periodic(int * array,int rows, int cols){
  extern __shared__ int buffer[];
  int tId = threadIdx.x + blockIdx.x * blockDim.x;
  if(threadIdx.x < 256){
    for(int i = threadIdx.x; i < rows*cols; i+=256 ){
      int x = i%(cols);
      int y = (int) i/rows;
      buffer[i] = (array[i] == 10)*(x!=0)*(x!=cols-1)*(y != 0)*(y!= rows-1)*5 + (array[i] == 5)*(x!=0)*(x!=cols-1)*(y != 0)*(y!= rows-1)*10 + array[i]*(array[i] != 10)*(array[i] != 5);
    }
  }
   __syncthreads();

  if (tId < rows*cols){
    int reject;
    int x = tId%(cols);
    int y = (int) tId/rows;
    int total = 0;
	  int c_aux;
    c_aux = (x-1)*(x-1 > 0) + (cols-1)*(x-1 < 0);
    reject = (1)*(x-1 > 0) + (0)*(x-1 < 0);
    if (reject ==1 &&buffer[(y*rows + c_aux)] == 1 || buffer[(y*rows + c_aux)] == 3 || buffer[(y*rows + c_aux)] == 5 || 
        buffer[(y*rows + c_aux)] == 9 || buffer[(y*rows + c_aux)] == 7 || buffer[(y*rows + c_aux)] == 11 || 
        buffer[(y*rows + c_aux)] == 13 || buffer[(y*rows + c_aux)] == 15){
      total = total + 1;
    }else if(c_aux == 0){
    		if (buffer[(y*rows + c_aux)] == 4 || buffer[(y*rows + c_aux)] == 5 || buffer[(y*rows + c_aux)] == 6 || 
        buffer[(y*rows + c_aux)] == 12 || buffer[(y*rows + c_aux)] == 7 || buffer[(y*rows + c_aux)] == 13 || 
        buffer[(y*rows + c_aux)] == 14 || buffer[(y*rows + c_aux)] == 15){
    		total = total + 1;	
    		}
    	}else {
      total = total + 0;
    }

    c_aux = (0)*(x+1 == cols) + (x+1)*(x+1 != cols);
    reject = (0)*(x+1 == cols) + (1)*(x+1 != cols);

    if (reject ==1 &&buffer[(y*rows + c_aux)] == 4 || buffer[(y*rows + c_aux)] == 5 || buffer[(y*rows + c_aux)] == 6 || 
        buffer[(y*rows + c_aux)] == 12 || buffer[(y*rows + c_aux)] == 7 || buffer[(y*rows + c_aux)] == 13 || 
        buffer[(y*rows + c_aux)] == 14 || buffer[(y*rows + c_aux)] == 15){
      total = total + 4;
    }else if(c_aux == cols-1){
    		if (buffer[(y*rows + c_aux)] == 1 || buffer[(y*rows + c_aux)] == 3 || buffer[(y*rows + c_aux)] == 5 || 
        buffer[(y*rows + c_aux)] == 9 || buffer[(y*rows + c_aux)] == 7 || buffer[(y*rows + c_aux)] == 11 || 
        buffer[(y*rows + c_aux)] == 13 || buffer[(y*rows + c_aux)] == 15){
    		total = total + 4;	
    		}
    	}else {
      total = total + 0;
    }


    c_aux = (0)*(y+1 == rows) + (y+1)*(y+1 != rows);
    reject = (0)*(y+1 == rows) + (1)*(y+1 != rows);

    if (reject ==1 &&buffer[(c_aux*rows + x)] == 2 || buffer[(c_aux*rows + x)] == 3 || buffer[(c_aux*rows + x)] == 6 || 
        buffer[(c_aux*rows + x)] == 10 || buffer[(c_aux*rows + x)] == 7 || buffer[(c_aux*rows + x)] == 11 || 
        buffer[(c_aux*rows + x)] == 14 || buffer[(c_aux*rows + x)] == 15){
      total = total + 2;
    }else if(c_aux == cols-1){
    		if (buffer[(c_aux*rows + x)] == 8 || buffer[(c_aux*rows + x)] == 12 || buffer[(c_aux*rows + x)] == 10 || 
        buffer[(c_aux*rows + x)] == 9 || buffer[(c_aux*rows + x)] == 14 || buffer[(c_aux*rows + x)] == 13 || 
        buffer[(c_aux*rows + x)] == 11 || buffer[(c_aux*rows + x)] == 15){
    		total = total + 2;	
    		}
    	}else {
      total = total + 0;
    }

    c_aux = (rows-1)*(y-1 <0) + (y-1)*(y-1 > 0);
    reject = (0)*(y-1 <0) + (1)*(y-1 > 0);

    if (reject ==1 && buffer[(c_aux*rows + x)] == 8 || buffer[(c_aux*rows + x)] == 12 || buffer[(c_aux*rows + x)] == 10 || 
        buffer[(c_aux*rows + x)] == 9 || buffer[(c_aux*rows + x)] == 14 || buffer[(c_aux*rows + x)] == 13 || 
        buffer[(c_aux*rows + x)] == 11 || buffer[(c_aux*rows + x)] == 15){
        total = total + 8;
    }else if(c_aux == 0){
    		if (buffer[(c_aux*rows + x)] == 2 || buffer[(c_aux*rows + x)] == 3 || buffer[(c_aux*rows + x)] == 6 || 
        buffer[(c_aux*rows + x)] == 10 || buffer[(c_aux*rows + x)] == 7 || buffer[(c_aux*rows + x)] == 11 || 
        buffer[(c_aux*rows + x)] == 14 || buffer[(c_aux*rows + x)] == 15 ){
    		total = total + 8;	
    		}
    	}else{
      total = total + 0;
    }

    array[tId] = total;    
  }
  /* if(tId == 1){
    for(int i = 0; i < rows*cols;i++){
      printf("%d ", array[i]);
      if((i+1)%3==0){
      	printf("\n");
      }
    }
    printf("\n");
  }
  */
}

int main(int argc, char const *argv[])
{
  int rows, cols;
  int *array;
  int *d_array;

  readInput("../initial.txt", &array, &rows, &cols);
  //printMatrix(array,rows,cols);

  int n = (int)(rows*cols);
  int block_size = 256;
  int grid_size = (int) ceil((float)n / block_size);

  cudaMalloc(&d_array ,rows * cols * sizeof(int));
  cudaMemcpy(d_array, array, rows * cols * sizeof(int), cudaMemcpyHostToDevice);
  for(int k = 0; k < 1000; k++){
    step_periodic<<<grid_size, block_size,rows*cols>>>(d_array, rows, cols);
  }
  cudaMemcpy(array, d_array, rows * cols * sizeof(int), cudaMemcpyDeviceToHost);
  cudaFree(d_array);

  return(0);
}
