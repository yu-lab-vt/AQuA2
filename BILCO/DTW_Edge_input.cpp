/* MyMEXFunction 
Maximum flow - component highest label push-relabel algorithm 
Specific for GTW problem 

INPUT：
ref: N x T matrix. Each row is one reference curve. 
tst: N x T matrix. Each row is one test curve.
Gij: nPair x 3 matrix. Each row is: [gID1,gID2,cap] represent gID1 and gID2 are neighbor. cap is smoothness.
*/

#include "mex.h"
#include <float.h>

/* global variables */
int T1;                      /* number of curve length */
int T2;
float **Dmatrix;          /* temporal result: shortest path from bottom-left */
float **distMatrix;
int **dirs;

void mexload(double *input){
    // distMatrix 
    float Cx;
    float Cy;
    float Cxy;
    float minV;
    int dir;
    distMatrix = new float*[T2];
    Dmatrix = new float*[T2];
    dirs = new int*[T2];
    for (int x = 0; x < T2; x++) {
        distMatrix[x] = new float[T1];
        Dmatrix[x] = new float[T1];
        dirs[x] = new int[T1];
        for (int y = 0; y < T1; y++) {
            distMatrix[x][y] = input[x + y*T2];
        }
    }

    Dmatrix[0][0] = 0;

    // first column
    for (int x=1;x<T2;x++){
        Dmatrix[x][0] = Dmatrix[x-1][0] + distMatrix[x][0];
        dirs[x][0] = 1;
    }

    // bottom row
    for (int y=1;y<T1;y++){
        Dmatrix[0][y] = Dmatrix[0][y-1] + distMatrix[0][y];
        dirs[0][y] = 3;
    }

    //following
    for (int y=1;y<T1;y++){
        for(int x=1;x<T2;x++){
            Cx = Dmatrix[x-1][y] + distMatrix[x][y];
            Cy =  Dmatrix[x][y-1] + distMatrix[x][y];
            Cxy = Dmatrix[x-1][y-1] + distMatrix[x][y];

            minV = Cy;
            dir = 3;
            if(Cxy<minV){
                dir = 2;
                minV = Cxy;
            }
            if(Cx<minV){
                dir = 1;
                minV = Cx;
            }
            Dmatrix[x][y] = minV;
            dirs[x][y] = dir;
        }
    }                               
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    T2 = mxGetM(prhs[0]);
    T1 = mxGetN(prhs[0]);

    // mexPrintf("%d %d\n",T1,T2);
    // load input, allocate memory, and release input data 
    mexload(mxGetPr(prhs[0]));

    plhs[0] = mxCreateDoubleMatrix(1, T1-1, mxREAL);
    double *tempCut = mxGetPr(plhs[0]);
    int x = T2-1;                           
    int y = T1-1;                           
    while (y>0)                        
    {                                       
        switch (dirs[x][y]){                
        case 1:                             
            x--;                            
            break;                         
        case 2:                             
            tempCut[--y] = x-0.5;           
            x--;                            
            break;                          
        case 3:                             
            tempCut[--y] = x;               
            break;                          
        default:                            
            printf("Wrong track error!");   
            break;                          
        }                                   
    }        
    
    for(x=0;x<T2;x++){
        delete[] distMatrix[x];
        delete[] Dmatrix[x];
        delete[] dirs[x];
    }
    delete[] distMatrix;
    delete[] Dmatrix;
    delete[] dirs;
    
    return;
};