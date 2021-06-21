//
// solver.h
//


// #ifndef SOLVER_H_INCLUDED
// #define SOLVER_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

void dens_step(unsigned int n, float* x, float* x0, float* u, float* v, float diff, float dt);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
extern "C" {
#endif

void vel_step(unsigned int n, float* u, float* v, float* u0, float* v0, float visc, float dt);

#ifdef __cplusplus
}
#endif


// #endif /* SOLVER_H_INCLUDED */
