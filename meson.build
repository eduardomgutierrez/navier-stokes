project('navier_stokes', 'c', default_options: [ 'warning_level=2' ])

cc = meson.get_compiler('c')

hdf5_dep = cc.find_library('hdf5', required: true )

headless = executable('headless',
    [ 'headless.c', 'solver.c' ],
    c_args : ['-O3', '-ffast-math', '-march=native'],
    dependencies: [ hdf5_dep  ])

gl_dep = cc.find_library('GL', required: false)
glu_dep = cc.find_library('GLU', required: false)
glut_dep = cc.find_library('glut', required: false)

demo = executable('demo',
    [ 'demo.c', 'solver.c' ],
    c_args : ['-O3', '-ffast-math', '-march=native' ],
    dependencies: [ gl_dep, glu_dep, glut_dep ]
)
