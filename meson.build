project('navier_stokes', 'c', default_options: [ 'warning_level=2' ])

cc = meson.get_compiler('c')

llikwid_dep = cc.find_library('likwid', required: true )


# hdf5_dep = cc.find_library('hdf5', dirs: '/usr/include/hdf5/serial/', required: true )

hddd = dependency('hdf5', language: 'c')

headless = executable('headless',
    [ 'headless.c', 'solver.c' ],
    # link_args: ['-I/home/federico/Escritorio/hdf5/HDF5-1.12.0-Darwin/HDF_Group/HDF5/1.12.0/include', 
    # '-L/home/federico/Escritorio/hdf5/HDF5-1.12.0-Darwin/HDF_Group/HDF5/1.12.0/lib', '-lhdf5', '-lm'],
    dependencies: [hddd, llikwid_dep]
)

gl_dep = cc.find_library('GL', required: false)
glu_dep = cc.find_library('GLU', required: false)
glut_dep = cc.find_library('glut', required: false)


demo = executable('demo',
     [ 'demo.c', 'solver.c' ],
     dependencies: [ gl_dep, glu_dep, glut_dep ],
     link_args: ['-I/${PAPI_DIR}/include', '-L/${PAPI_DIR}/lib', '-lpapi'],
 )
