project('navier_stokes', 'cuda', default_options: [ 'buildtype=release', 'warning_level=1' ])

# cudac = meson.get_compiler('cuda')

# llikwid_dep = cc.find_library('likwid', required: true)

# hdf5 = dependency('hdf5', language: 'c')


cuda_comp = meson.get_compiler('cuda')
cuda = import('unstable-cuda')
nvcc_flags = cuda.nvcc_arch_flags(cuda_comp, '-ccbin clang-6.0')

headless = executable('headless', ['headless.cu', 'solver.cu'], cuda_args : nvcc_flags)
# , objects: 'lin_solve_ispc'

# gl_dep = cudac.find_library('GL', required: false)
# glu_dep = cudac.find_library('GLU', required: false)
# glut_dep = cudac.find_library('glut', required: false)

#  demo = executable('demo', ['demo.c', 'solver.c', 'solver.h'], objects: ['lin_solve_ispc'],
#        dependencies: [gl_dep, glu_dep, glut_dep])
