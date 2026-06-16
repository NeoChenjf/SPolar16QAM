#include "mex.h"
#include "math.h"
#include <stdio.h>
#include <float.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
#include <string.h>
/* DBL_MAX*/
int approx_minstar;
int Stages;
int N;
double *base_arr;
double *complexity_p;
int P;
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    /*  input:info_bit_pattern,L,approx_minstar,
     * output:a_hat;
     * declare functions
     * llR size is N, bit size is N*2;   */
    double phi(double PM_iminus1,double L_i,int u_i);
    void update_llr(int row,int layer,int *bits,double *llrs,double *info_bit_pattern_p,double *d_tilde_p);
    void int_layer_copy(int* matrix1, int a,int b,int* matrix2);
    void double_layer_copy(double* matrix1, int a,int b,double* matrix2);
    int compar (const void *a, const void *b);
    /*uint_fast64_t get_time(void);*/
    /*declare variables */
    double *info_bit_pattern_p,*d_tilde_p,*a_hat_p;
    int L;
    mxArray *info_bit_pattern,*complexity,*d_tilde,*a_hat;
    /*
     * mxArray *out_llrs,*out_bits,*out_PM;
     * double *out_llrs_p,*out_bits_p,*out_PM_p;*/
    /* associate inputs */
    d_tilde= mxDuplicateArray(prhs[0]);
    /*     IF WE HAVE INFINITY AT D_TILDE, THEN CHANGE THIS TO DBL_MAX;*/
    
    info_bit_pattern= mxDuplicateArray(prhs[1]);
    N=(int)mxGetN(prhs[0]);
    L=(int)(*mxGetPr(prhs[2]));
    approx_minstar=(int)(*mxGetPr(prhs[3]));
    
    /*associate outputs*/
    
    complexity = plhs[0] = mxCreateDoubleMatrix(1,3,mxREAL);
    /*out_llrs = plhs[1] = mxCreateDoubleMatrix(N,L,mxREAL);
     * out_bits = plhs[2] = mxCreateDoubleMatrix(N,2*L,mxREAL);
     * out_PM = plhs[3] = mxCreateDoubleMatrix(1,L,mxREAL);
     */
    /*associate pointers*/
    info_bit_pattern_p= mxGetPr(info_bit_pattern);
    d_tilde_p= mxGetPr(d_tilde);
    complexity_p = mxGetPr(complexity);
    int i;
    for(i=0;i<3;i++){
        complexity_p[i]=0;
    }
    /*
     * out_llrs_p = mxGetPr(out_llrs);
     * out_bits_p = mxGetPr(out_bits);
     * out_PM_p=mxGetPr(out_PM);
     */
    /*do some changes for inputs:*/
    /*1.let DBL_MAX represents infinity: !_finite()*/
    int info_bit_pattern_length=0;
    for(i=0;i<N;i++){
        if(isinf(d_tilde_p[i])==1){
			 d_tilde_p[i]=DBL_MAX;
			 //mexPrintf("inf \n");
		}
           
        else if(isinf(d_tilde_p[i])==-1){
            d_tilde_p[i]=-DBL_MAX;
			//mexPrintf("-inf \n");
			}
        if(info_bit_pattern_p[i]==1)
            info_bit_pattern_length++;
    }
    
    /*do something
     * initilized bits,bits_updated,llrs,llrs_updated*/
    Stages=(int)log2(N)+1;
    /*int bits[N_max*4*L_max]={0},temp_bits[N_max*4*L_max]={0},PM_index[2*L_max]={0};*/
    int *bits = (int*) malloc (sizeof(int) *N*4*L);
    int *PM_index = (int*) malloc (sizeof(int) *2*L);
    /*double llrs[2*N_max*L_max]={0},PM[2*L_max]={0},temp_llrs[2*N_max*L_max]={0},temp_PM[2*L_max]={0};*/
    double *llrs = (double*) malloc (sizeof(double) *N*2*L);
    double *PM = (double*) malloc (sizeof(double) *2*L);
    /*double *temp_llrs = (double*) malloc (sizeof(double) *N*2*L);*/
    /*double *temp_PM = (double*) malloc (sizeof(double) *2*L */
    /*initilize*/
    for(i=0;i<4*N*L;i++){
        if(i<2*L){
            PM_index[i]=i;
            PM[i]=0;
        }
        if(i<2*N*L){
            llrs[i]=0;
        }
        bits[i]=0;
    }
    /*     SCL algorithm*/
    int l,j;
    int L_prime=1;
    /*uint_fast64_t aaa=get_time();*/
    
    
    for(i=0;i<N;i++){
        for(l=0;l<L_prime;l++){
            update_llr(i,PM_index[l],bits,llrs,info_bit_pattern_p,d_tilde_p);
            
        }
		 //mexPrintf("%d ",L_prime);
        // mexPrintf("%d ",PM_index[0]);
		 //mexPrintf("%f ",PM[0]);
		 //mexPrintf("%f ",llrs[N - 2 + N*0]);
		 //mexPrintf("%d \n", bits[i + N * 2 * 0]);
        if(info_bit_pattern_p[i]==0){/*Fronzen bit*/
            for(l=0;l<L_prime;l++)
                PM[PM_index[l]]= phi(PM[PM_index[l]], llrs[N-2+PM_index[l]*N], 0);
        }
        else{/*Information bit*/
            for(l=2*L_prime-1;l>=0;l--){
                
                if(l<L_prime){
                    PM[PM_index[l]]= phi(PM[PM_index[l]], llrs[N-2+PM_index[l]*N], 0);
                    bits[i+PM_index[l]*N*2] = 0;
					//mexPrintf("%d =0\n",i);
                }
                else{
                    PM[PM_index[l]]= phi(PM[PM_index[l-L_prime]], llrs[N-2+PM_index[l-L_prime]*N], 1);
                    int_layer_copy(bits,PM_index[l-L_prime],PM_index[l],bits);
                    double_layer_copy(llrs,PM_index[l-L_prime],PM_index[l],llrs);
                    bits[i+PM_index[l]*N*2] = 1;
					//mexPrintf("%d =1\n",i);
                }
            }
            L_prime*=2;
            if (L_prime > L){
                base_arr = PM;
                for(j=0;j<L_prime;j++){
                    PM_index[j]=j;
                }
                
                qsort(PM_index, L_prime, sizeof(int), compar);
                L_prime=L;
                
            }
			//for (j = 0; j<2 * L_prime; j++){
					//mexPrintf("PM=%f \n", PM[j]);
			//}
            
        }

    }
	base_arr = PM;
    for(j=L_prime;j<2*L_prime;j++){
        PM[PM_index[j]]=DBL_MAX/2;
    }
    for(j=0;j<2*L_prime;j++){
        PM_index[j]=j;
    }
    qsort(PM_index, 2*L_prime, sizeof(int), compar);
	int *b_hat = (int*) malloc (sizeof(int) *info_bit_pattern_length);
    /*output*/
    a_hat = plhs[1] = mxCreateDoubleMatrix(1,info_bit_pattern_length,mxREAL);
    a_hat_p = mxGetPr(a_hat);
	int index=0;
	for(i=0;i<N;i++){    
       if(info_bit_pattern_p[i]==1){
           b_hat[index]=bits[i+2*N*PM_index[0]];
            index++;
        }
            
    }
    for(i=0;i<info_bit_pattern_length;i++)
        a_hat_p[i]=(double)b_hat[i];
    
    /*free memory*/
    /*mxarray part*/
    free(bits);
    free(PM_index);
    free(llrs);
    free(PM);

    mxDestroyArray(info_bit_pattern);
    mxDestroyArray(d_tilde);

    /*pointer part*/

    /*     test for output*/
    
    /*for(i=0;i<L*N*2;i++)
     * {
     * if(i<L*N)
     * out_llrs_p[i]=llrs[i];
     * out_bits_p[i]=bits[i];
     * if (i<L)
     * out_PM_p[i]=PM[i];
     * }
     */
    return;
}

void update_llr(int row,int layer,int *bits,double *llrs,double *info_bit_pattern_p,double *d_tilde_p){
    double minstar(double a, double b);
    int offset;
    int i;
    int i_end;
    int binary=row;
    int stage=Stages-1;
    /*     bits part first:*/
    row--;
    int temp_row;
    int temp;
    if(row>=0){
        temp_row=2;
        temp=-1;
        while((row+1)%temp_row==0){
            temp_row*=2;
            temp++;
        }
        int k=0;
        while(k<=temp){
            offset=(int)pow(2,k);
            i=row/offset*offset;
            i_end=row/offset*offset+offset-1;
            while(i<=i_end){
                if(k==0){
                    bits[i-offset+N+N*2*layer]=(bits[i-offset+N*2*layer]+bits[i+N*2*layer])%2;
                    bits[i+N+N*2*layer]=bits[i+N*2*layer];
                    
                }
                else{
                    bits[i-offset+N+N*2*layer]=(bits[i-offset+N+N*2*layer]+bits[i+N+N*2*layer])%2;
                };
                i++;
            }
            k++;
        }
        
    }
    
    row++;
    temp_row=2;
    temp=0;
    if (row==0)
        temp=stage-1;
    else
        while(row%temp_row==0){
            temp_row*=2;
            temp++;
        }
    
    
    int place_offset=0;
    int previous_offset=0;
    int j=stage-1;
    
    int index;
    while(j>=0){
        offset=(int)pow(2,j);
        if(j<=temp){
            i=row/offset*offset;
            i_end=row/offset*offset+offset-1;
            index=0;
            while(i<=i_end){
                
                if(binary/(int)pow(2,j)==0){
                    if (place_offset==0)
					{
                        llrs[index+place_offset+N*layer]=minstar(d_tilde_p[i],d_tilde_p[i+offset]);
						//mexPrintf("(1 llrs[%2f]) ",d_tilde_p[i]);
						}
                    else{
                        llrs[index+place_offset+N*layer]=minstar(llrs[i%offset+place_offset-previous_offset+N*layer],llrs[i%offset+place_offset-previous_offset+offset+N*layer]);
						//mexPrintf("(2 llrs[%2f]) ",llrs[i%offset+place_offset-previous_offset+N*layer]);
						}
                    complexity_p[1]++;
                }
                
                if(binary/(int)pow(2,j)==1){
                    if (place_offset==0)
                        if(j==0){
                            llrs[index+place_offset+N*layer]=pow(-1,bits[i-offset+N*2*layer])*d_tilde_p[i-offset]+d_tilde_p[i];
							//mexPrintf("(3 bits[%d]llrs[%2f]) ",bits[i-offset+N*2*layer],d_tilde_p[i-offset]);
							}
                        else{
                            llrs[index+place_offset+N*layer]=pow(-1,bits[i-offset+N+N*2*layer])*d_tilde_p[i-offset]+d_tilde_p[i];
							//mexPrintf("(4 bits[%d]llrs[%2f]) ",bits[i-offset+N+N*2*layer],d_tilde_p[i-offset]);
						}
                    else
                        if(j==0){
                            llrs[index+place_offset+N*layer]=pow(-1,bits[i-offset+N*2*layer])*llrs[i%previous_offset+place_offset-previous_offset-offset+N*layer]+llrs[i%previous_offset+place_offset-previous_offset+N*layer];
							//mexPrintf("(5 bits[%d]llrs[%2f]) ",bits[i-offset+N*2*layer],llrs[i%previous_offset+place_offset-previous_offset-offset+N*layer]);
						}
						else{
                            llrs[index+place_offset+N*layer]=pow(-1,bits[i-offset+N+N*2*layer])*llrs[i%previous_offset+place_offset-previous_offset-offset+N*layer]+llrs[i%previous_offset+place_offset-previous_offset+N*layer];
							//mexPrintf("%d ", bits[i - offset + N + N * 2 * layer]);
							//mexPrintf("(%f) ", llrs[i%previous_offset + place_offset - previous_offset - offset + N*layer]);
							//mexPrintf("(%f) ", llrs[i%previous_offset + place_offset - previous_offset + N*layer]);
							// mexPrintf("(6 bits[%d]llrs[%2f]) ",bits[i-offset+N+N*2*layer],llrs[i%previous_offset+place_offset-previous_offset-offset+N*layer]);
						}
					complexity_p[0]++;
                    if (i==i_end)
                        binary-=(int)pow(2,j);
                    
                }
                //mexPrintf("%f \n", llrs[index + place_offset + N*layer]);
                i++;
                index++;
            }
        }else{
            if(binary/(int)pow(2,j)==1)
                binary-=(int)pow(2,j);
        }
        
        previous_offset=offset;
        place_offset+=offset;
        j--;
    }
    /*     final bit of each row.*/
    i--;
    if(info_bit_pattern_p[i]==1){
        if (llrs[N-2+N*layer]>=0){
            bits[i+N*2*layer]=0;
			//mexPrintf("update-%d =0\n",i);
        }
        else{
            bits[i+N*2*layer]=1;
			//mexPrintf("update-%d =1\n",i);
            
        }
        
    }
    
    return;
}
double minstar(double a, double b){
    double min(double a, double b);
    double sign(double a);
    double temp=sign(a)*sign(b)*min(fabs(a),fabs(b));
    if(approx_minstar==0&& fabs(a) <DBL_MAX && fabs(b) <DBL_MAX)
        temp=temp+log(1.0+exp(-(fabs(a+b))))-log(1.0+exp(-(fabs(a-b))));
    return temp;
    
    
}
double sign(double a){
    if(a>0)
        return 1.0;
    if(a<0)
        return -1.0;
    if(a==0)
        return 0.0;
}
double min(double a, double b){
    if (a>b)
        return b;
    else
        return a;
}
double phi(double PM_iminus1,double L_i,int u_i){
    double PM_i;
    /*
     * if (approx_minstar==1){
     * int L_i_int=-1;
     * PM_i=PM_iminus1;
     * if (L_i>0)
     * L_i_int=1;
     * else
     * L_i_int=0;
     * if (L_i_int==u_i){
     * PM_i = PM_i + fabs(L_i);
     * }
     * }else{
     * PM_i = PM_iminus1 + log(1.0+exp(-(1.0-2.0*(double)u_i)*L_i));
     *
     * }*/
    int L_i_int=-1;
    PM_i=PM_iminus1;
    if (L_i>0)
        L_i_int=1;
    else
        L_i_int=0;
    if (L_i_int==u_i){
        PM_i = PM_i + fabs(L_i);
    }
    if(approx_minstar==0&& fabs(L_i) <DBL_MAX )
        PM_i=PM_i+log(1.0+exp(-(fabs(L_i))));
    complexity_p[2]++;
	//mexPrintf("PM_i=%f\n",PM_i);
    return PM_i;
}
/*copy from 'a' layer to 'b' layer*/
void int_layer_copy(int* matrix1, int a,int b,int* matrix2){
    //int i;
    //for(i=0;i<N*2;i++)
    //{
    //    matrix2[i+b*N*2]=matrix1[i+a*N*2];
    //}
	memcpy(matrix2+b*N*2, matrix1+a*N*2,2*N*sizeof(int));
    return;
}
/*copy from 'a' layer to 'b' layer*/
void double_layer_copy(double* matrix1, int a,int b,double* matrix2){
    //int i;
    //for(i=0;i<N;i++)
    //{
    //    matrix2[i+b*N]=matrix1[i+a*N];
    //}
    //return;
	memcpy(matrix2+b*N, matrix1+a*N,N*sizeof(double));
}
int compar (const void *a, const void *b)
{
    int aa = *((int *) a), bb = *((int *) b);
    if (base_arr[aa] < base_arr[bb])
        return -1;
    if (base_arr[aa] == base_arr[bb])
        return 0;
    if (base_arr[aa] > base_arr[bb])
        return 1;
}


