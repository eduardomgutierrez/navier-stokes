uniform unsigned int rb_idx(uniform unsigned int x, uniform unsigned int y, uniform unsigned int dim) {
    assert(dim % 2 == 0);
    uniform unsigned int base = ((x % 2) ^ (y % 2)) * dim * (dim / 2);
    uniform unsigned int offset = (y / 2) + x * (dim / 2);
    return base + offset;
}

#define IX(x,y,n) (rb_idx((x),(y),(n+2)))

void inv_idx(uniform const int x, uniform unsigned int n)
{
    uniform unsigned int i;
    uniform unsigned int j;

    uniform int rojo = x < (n*n / 2);
    uniform int ipar;

    if(rojo)
    {
        i = x * 2/n;
        ipar = i %  3 != 0;
        j = (x % (n/2) * 2) + ipar;
    }
    else
    {
        i = (x - (n*n/ 2)) * 2/n;
        ipar = i % 2 == 0;
        j = ((x - (n*n/ 2)) % (n/2) * 2) + ipar;
    }

    print("I: % , J: %\n",i,j);

    return;
}

export enum boundary { NONE = 0,
               VERTICAL = 1,
               HORIZONTAL = 2 };

void set_bnd(uniform unsigned int n, uniform boundary b, uniform float x[])
{
    for (uniform unsigned int i = 1; i <= n; i++) {
        x[IX(0, i,n)] = b == VERTICAL ? -x[IX(1, i,n)] : x[IX(1, i,n)];
        x[IX(n + 1, i,n)] = b == VERTICAL ? -x[IX(n, i,n)] : x[IX(n, i,n)];
        x[IX(i, 0,n)] = b == HORIZONTAL ? -x[IX(i, 1,n)] : x[IX(i, 1,n)];
        x[IX(i, n + 1,n)] = b == HORIZONTAL ? -x[IX(i, n,n)] : x[IX(i, n,n)];
    }
    x[IX(0, 0,n)] = 0.5f * (x[IX(1, 0,n)] + x[IX(0, 1,n)]);
    x[IX(0, n + 1,n)] = 0.5f * (x[IX(1, n + 1,n)] + x[IX(0, n,n)]);
    x[IX(n + 1, 0,n)] = 0.5f * (x[IX(n, 0,n)] + x[IX(n + 1, 1,n)]);
    x[IX(n + 1, n + 1,n)] = 0.5f * (x[IX(n, n + 1,n)] + x[IX(n + 1, n,n)]);
}

export void lin_solve_vect(
    uniform unsigned int n,
    uniform boundary b,
    uniform float x[],
    const uniform float x0[],
    uniform float a,
    uniform float inv_c)
{

    uniform int offset = n*n/2;
    float acum, x_new;
// do {
//     acum = 0.0f;
    
    /// Rojos ; Impar - Impar
    for(uniform size_t i = 1; i < n-1; i+= 2)
    {
        uniform unsigned int base = (n * n / 2) + 1;
        foreach(idx = i * n/2 ...  (i+1) * n/2)
        {
            x_new = (x0[idx] 
                + a * (x[idx - (n/2 + 1) + base]
                + x[idx + (n/2 - 1)+ base]
                + x[idx - 1 + base]
                + x[idx + base])) * inv_c;
        // acum += min(abs(x[idx]-x0[idx]), abs((x[idx]-x0[idx]))/x0[idx]);
        // acum += abs(x_new-x[idx]);
        // acum += min(abs(x_new - x[idx]), abs((x_new-x[idx])/x[idx]));
        x[idx] = x_new;
        }
    }
    
    /// Rojos ; Par - Par
    for(uniform size_t i = 2; i < n-1; i+= 2)
    {
        uniform unsigned int base = (n * n / 2) - 1;
        foreach(idx = i * n/2 ...  (i+1) * n/2)
        {
            x_new = (x0[idx] 
                + a * (x[idx - (n/2 - 1) + base]
                + x[idx + (n/2 + 1)+ base]
                + x[idx + base]
                + x[idx + 1 + base])) * inv_c; // ete anda
        // acum += min(abs(x[idx]-x0[idx]), abs((x[idx]-x0[idx]))/x0[idx]);
        // acum += abs(x_new-x[idx])/x[idx];
        // acum += abs(x_new-x[idx]);
        // acum += min(abs(x_new - x[idx]), abs((x_new-x[idx])/x[idx]));
        x[idx] = x_new;        
        }
    }

    /// Negros ; Par - Impar
    for(uniform size_t i = 1; i < n-1; i+= 2)
    {
        uniform int base = -((n * n / 2) - 1);
        foreach(idx = offset + i * n/2 ...  offset + (i+1) * n/2)
        {
            x_new = (x0[idx] 
                + a * (x[idx - (n/2 + 1) + base]
                + x[idx + (n/2 - 1)+ base]
                + x[idx - 1 + base]
                + x[idx + base])) * inv_c;
        // acum += min(abs(x[idx]-x0[idx]), abs((x[idx]-x0[idx]))/x0[idx]);
        // acum += abs(x_new-x[idx])/x[idx];
        // acum += abs(x_new-x[idx]);
        // acum += min(abs(x_new - x[idx]), abs((x_new-x[idx])/x[idx]));
        x[idx] = x_new;
        }
    }

    /// Negros ; Impar - Par
    for(uniform size_t i = 2; i < n-1; i+= 2)
    {
        uniform int base = -((n * n / 2) + 1);
        foreach(idx = offset + i * n/2  ...  offset + (i+1) * n/2)
        {
            x_new = (x0[idx] 
                + a * (x[idx - (n/2 - 1) + base]
                + x[idx + (n/2 + 1)+ base]
                + x[idx + base]
                + x[idx + 1 + base])) * inv_c;                // este anda
        // acum += min(abs(x[idx]-x0[idx]), abs((x[idx]-x0[idx]))/x0[idx]);
        // acum += min(abs(x_new - x[idx]), abs((x_new-x[idx])/x[idx]));
        // acum += abs(x_new-x[idx])/x[idx];
        // acum += abs(x_new-x[idx]);
        x[idx] = x_new;
        }
    }
    set_bnd(n-2, b, x);
    // uniform float res = reduce_add(acum);
    // print("R %\n",res);
    // } while((reduce_add(acum) / n*n) > 1e-1f);
    
}