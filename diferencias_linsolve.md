asdf.msd
// x[idx] = (x0[idx] 
//   + a * (x[idx - (n/2 + 1) + base]
//   + x[idx + (n/2 - 1)+ base]
//   + x[idx - 1 + base]
//   + x[idx + base])) * inv_c;

// x[idx] = (x0[idx] 
//   + a * (x[idx - (n/2 - 1) + base]
//   + x[idx + (n/2 + 1)+ base]
//   + x[idx + base]
//   + x[idx + 1 + base])) * inv_c;

//  x[idx] = (x0[idx] 
//   + a * (x[idx - (n/2 + 1) + base]
//   + x[idx + (n/2 - 1)+ base]
//   + x[idx - 1 + base]
//   + x[idx + base])) * inv_c;

//  x[idx] = (x0[idx] 
//   + a * (x[idx - (n/2 - 1) + base]
//   + x[idx + (n/2 + 1)+ base]
//   + x[idx + base]
//   + x[idx + 1 + base])) * inv_c;