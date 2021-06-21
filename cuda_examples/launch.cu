#include "helper_cuda.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <cuda.h>
#include <cstdint>

#define WIDTH 1200
#define HEIGHT 600

struct RGBA {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
};

template <typename T>
T div_ceil(T a, T b) {
    return (a + b - 1) / b;
}


// Un hilo por elemento sobre los W*H elementos de la matriz vistos en 1D
__global__ void kernel_1d(int width, int height, RGBA *rgba) {
    uint idx = blockDim.x * blockIdx.x + threadIdx.x;

    uint8_t blockColor = blockIdx.x * 255 / gridDim.x;
    uint8_t threadColor = threadIdx.x * 255 / blockDim.x;

    if (idx < width * height) {
        RGBA pixel = {blockColor, threadColor, 0u, 255u};
        rgba[idx] = pixel;
    }
}

static void launch_kernel_1d(int width, int height, RGBA *rgba, int block_size) {
    int n = width * height;
    dim3 block(block_size);
    dim3 grid(div_ceil(n, block_size));

    kernel_1d<<<grid, block>>>(width, height, rgba);
    checkCudaCall(cudaGetLastError());
    checkCudaCall(cudaDeviceSynchronize());
}


// 1D como el primero, pero cada hilo procesa N elementos consecutivos
__global__ void kernel_1d_n_items_seq(int width, int height, RGBA *rgba, int work) {

    uint8_t blockColor = blockIdx.x * 255 / gridDim.x;
    uint8_t threadColor = threadIdx.x * 255 / blockDim.x;

    int thread_from = work * (blockDim.x * blockIdx.x + threadIdx.x);
    int thread_to = min(work * (blockDim.x * blockIdx.x + threadIdx.x + 1), width * height);
    for (int idx = thread_from;
         idx < thread_to;
         ++idx)
    {
        RGBA pixel = {blockColor, threadColor, 0, 255u};
        rgba[idx] = pixel;
    }
}

static void launch_kernel_1d_n_items_seq(int width, int height, RGBA *rgba, int block_size, int work) {
    int n = width * height;
    dim3 block(block_size);
    dim3 grid(div_ceil(n, block_size * work));

    kernel_1d_n_items_seq<<<grid, block>>>(width, height, rgba, work);
    checkCudaCall(cudaGetLastError());
    checkCudaCall(cudaDeviceSynchronize());
}


// 1D como el primero, pero cada hilo procesa N elementos separados por el tamaño del bloque
__global__ void kernel_1d_n_items_block_stride(int width, int height, RGBA *rgba, int work) {

    uint8_t blockColor = blockIdx.x * 255 / gridDim.x;
    uint8_t threadColor = threadIdx.x * 255 / blockDim.x;

    int block_from = work * blockDim.x * blockIdx.x;
    int block_to = min(work * blockDim.x * (blockIdx.x + 1), width * height);
    for (int idx = block_from + threadIdx.x;
         idx < block_to;
         idx += blockDim.x)
    {
        RGBA pixel = {blockColor, threadColor, 0, 255u};
        rgba[idx] = pixel;
    }
}

static void launch_kernel_1d_n_items_block_stride(int width, int height, RGBA *rgba, int block_size, int work) {
    int n = width * height;
    dim3 block(block_size);
    dim3 grid(div_ceil(n, block_size * work));

    kernel_1d_n_items_block_stride<<<grid, block>>>(width, height, rgba, work);
    checkCudaCall(cudaGetLastError());
    checkCudaCall(cudaDeviceSynchronize());
}


// 1d como el primero, pero lanzamos una cantidad arbitraria de bloques y el grid completo avanza hasta terminar el arreglo
__global__ void kernel_1d_grid_stride(int width, int height, RGBA *rgba) {
    for (int idx = blockDim.x * blockIdx.x + threadIdx.x;
         idx < width * height;
         idx += gridDim.x * blockDim.x)
    {
        uint8_t blockColor = blockIdx.x * 255 / gridDim.x;
        uint8_t threadColor = threadIdx.x * 255 / blockDim.x;

        RGBA pixel = {blockColor, threadColor, 0, 255u};
        rgba[idx] = pixel;
    }
}

static void launch_kernel_1d_grid_stride(int width, int height, RGBA *rgba, int block_size, int num_blocks) {
    dim3 block(block_size);
    dim3 grid(num_blocks);

    kernel_1d_grid_stride<<<grid, block>>>(width, height, rgba);
    checkCudaCall(cudaGetLastError());
    checkCudaCall(cudaDeviceSynchronize());
}


// Bloques 2D dispuestos sobre la matriz vista en 2D, un elemento por hilo
__global__ void kernel_2d(int width, int height, RGBA *rgba) {
    int x = blockDim.x * blockIdx.x + threadIdx.x;
    int y = blockDim.y * blockIdx.y + threadIdx.y;

    uint8_t blockColorX = blockIdx.x * 255 / gridDim.x;
    uint8_t blockColorY = blockIdx.y * 255 / gridDim.y;

    int local_id = threadIdx.x + threadIdx.y * blockDim.x;
    uint8_t threadColor = local_id * 255 / (blockDim.x * blockDim.y);

    if ((x < width) && (y < height)) {
        RGBA pixel = {blockColorX, threadColor, blockColorY, 255u};
        rgba[y * WIDTH + x] = pixel;
    }
}

static void launch_kernel_2d(int width, int height, RGBA *rgba, int block_width, int block_height) {
    dim3 block(block_width, block_height);
    dim3 grid(div_ceil(width, block_width), div_ceil(height, block_height));

    kernel_2d<<<grid, block>>>(width, height, rgba);
    checkCudaCall(cudaGetLastError());
    checkCudaCall(cudaDeviceSynchronize());
}


int main() {
    RGBA *img;
    checkCudaCall(cudaMallocManaged(&img, WIDTH * HEIGHT * sizeof(RGBA)));

    checkCudaCall(cudaMemset(img, 0, WIDTH * HEIGHT * sizeof(RGBA)));
    launch_kernel_1d(WIDTH, HEIGHT, img, 1024);
    stbi_write_png("1d.png", WIDTH, HEIGHT, 4, img, sizeof(RGBA) * WIDTH);

    checkCudaCall(cudaMemset(img, 0, WIDTH * HEIGHT * sizeof(RGBA)));
    launch_kernel_1d_n_items_seq(WIDTH, HEIGHT, img, 1024, 4);
    stbi_write_png("1d_n_items_seq.png", WIDTH, HEIGHT, 4, img, sizeof(RGBA) * WIDTH);

    checkCudaCall(cudaMemset(img, 0, WIDTH * HEIGHT * sizeof(RGBA)));
    launch_kernel_1d_n_items_block_stride(WIDTH, HEIGHT, img, 1024, 4);
    stbi_write_png("1d_n_items_block.png", WIDTH, HEIGHT, 4, img, sizeof(RGBA) * WIDTH);

    checkCudaCall(cudaMemset(img, 0, WIDTH * HEIGHT * sizeof(RGBA)));
    launch_kernel_1d_grid_stride(WIDTH, HEIGHT, img, 1024, 200);
    stbi_write_png("1d_grid_stride.png", WIDTH, HEIGHT, 4, img, sizeof(RGBA) * WIDTH);

    checkCudaCall(cudaMemset(img, 0, WIDTH * HEIGHT * sizeof(RGBA)));
    launch_kernel_2d(WIDTH, HEIGHT, img, 32, 32);
    stbi_write_png("2d.png", WIDTH, HEIGHT, 4, img, sizeof(RGBA) * WIDTH);

    checkCudaCall(cudaFree(img));

    return 0;
}
