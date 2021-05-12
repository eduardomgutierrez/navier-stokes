// static uniform unsigned int rb_idx(uniform unsigned int x,uniform unsigned int y,uniform unsigned int dim) {

// #define N 64
// #define IX(i,j) rb_idx(i,j,N+2)

// static unsigned int rb_idx(unsigned int x,unsigned int y,uniform unsigned int dim) {
    
//     assert(dim % 2 == 0);
    
//     unsigned int base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
    
//     #ifdef RBC
//     // Por columnas
//     unsigned int offset = (x / 2) + y * (dim / 2);
//     #else
//     // Por filas
//     unsigned int offset = (y / 2) + x * (dim / 2);
//     #endif
    
//     return base + offset;
// }

// void inv_idx(
//     const int x,
//     uniform unsigned int n,
//     unsigned int &i,
//     unsigned int &j)
// {
//     // int brd = (n*n / 2);
//     int rojo = x < (n*n / 2);
    
//     unsigned int idx_n = rojo ? x : x - (n*n/ 2);
//     i = idx_n * 2/n;

//     // *j = (idx_n % (n/2) * 2) + (rojo ? ((i % 2) != 0) : ((i % 2) == 0));
//     if(rojo){
//         j = (idx_n % (n/2) * 2) + (i % 2) != 0;
//     } else {
//         j = (idx_n % (n/2) * 2) + (i % 2) == 0;
//     }

//     return;
// }

// unsigned int i_ix(const unsigned int x, uniform unsigned int n){
//     int rojo = x < (n*n / 2);
    
//     unsigned int idx_n = rojo ? x : x - (n*n/ 2);

//     return idx_n * 2/n;
// }

// unsigned int j_ix(const unsigned int x, uniform unsigned int n){
//     unsigned int i = i_ix(x,n);


//     int rojo = x < (n*n / 2);

//     unsigned int idx_n = rojo ? x : x - (n*n/ 2);

//     unsigned int j;
//     if(rojo){
//         j = (idx_n % (n/2) * 2) + (i % 2) != 0;
//     } else {
//         j = (idx_n % (n/2) * 2) + (i % 2) == 0;
//     }

//     return j;
// }

// 

export void lin_solve_vect(
    const uniform unsigned int n,
    uniform float x[],
    const uniform float x0[],
    uniform float a,
    uniform float inv_c)
{

    uniform int offset = n*n/2;

    // Impar - Impar
    for(uniform size_t i = 1; i < n-1; i+= 2)
    {
        uniform unsigned int base = (n * n / 2) + 1;
        foreach(idx = i * n/2 ...  (i+1) * n/2 -1)
        {
            x[idx] = (x0[idx] 
                + a * (x[idx - (n/2 + 1) + base]
                + x[idx + (n/2 - 1)+ base]
                + x[idx - 1 + base]
                + x[idx + base])) * inv_c;
        }
    }

    // // Par - Par
    for(uniform size_t i = 2; i < n-1; i+= 2)
    {
        uniform unsigned int base = (n * n / 2) - 1;
        foreach(idx = i * n/2 + 1 ...  (i+1) * n/2)
        {
            x[idx] = (x0[idx] 
                + a * (x[idx - (n/2 - 1) + base]
                + x[idx + (n/2 + 1)+ base]
                + x[idx + base]
                + x[idx - 1 + base])) * inv_c;
        }
    }

    // Par - Impar
     for(uniform size_t i = 1; i < n-1; i+= 2)
    {
        uniform int base = -((n * n / 2) - 1);
        foreach(idx = offset + i * n/2 ...  (i+1) * n/2 -1)
        {
            x[idx] = (x0[idx] 
                + a * (x[idx - (n/2 + 1) + base]
                + x[idx + (n/2 - 1)+ base]
                + x[idx - 1 + base]
                + x[idx + base])) * inv_c;
        }
    }

    // Impar - Par
    for(uniform size_t i = 2; i < n-1; i+= 2)
    {
        uniform int base = -((n * n / 2) + 1);
        foreach(idx = offset + i * n/2 + 1 ...  (i+1) * n/2)
        {
            x[idx] = (x0[idx] 
                + a * (x[idx - (n/2 - 1) + base]
                + x[idx + (n/2 + 1)+ base]
                + x[idx + base]
                + x[idx - 1 + base])) * inv_c;
        }
    }
    
    // foreach(idx = n/2 ... (n*n / 2))
    // {
    //     int base;
    //     // Impar - Impar
        
    //     base = (n * n / 2) + 1;
    //         x[idx] = (x0[idx] 
    //             + a * (x[idx - (n/2 + 1) + base]
    //             + x[idx + (n/2 - 1)+ base]
    //             + x[idx - 1 + base]
    //             + x[idx + base]) * inv_c;
    //     // Par - Par        
    
    //     base = (n * n / 2) - 1;
    //         x[idx] = (x0[idx] 
    //             + a * (x[idx - (n/2 - 1) + base]
    //             + x[idx + (n/2 + 1)+ base]
    //             + x[idx + base]
    //             + x[idx - 1 + base]) * inv_c;

    //     count++;
    // }

    // foreach(idx = (n*n / 2) ... n*n)
    // {
    //     inv_idx(idx, n, i, j); 
        
    //     // if(i > 0 && i < n-1 && j > 0 && j < n-1){
    //         x[idx] = (x0[idx] 
    //             + a * (x[IX(i - 1, j)]
    //             + x[IX(i + 1, j)]
    //             + x[IX(i, j - 1)]
    //             + x[IX(i, j + 1)])) * inv_c;
    //     // }
    // }
}