#include "reconstruct.cuh"
#include <opencv2/core.hpp> 
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>


 #define CHECK(call)\
{\
  const cudaError_t error=call;\
  if(error!=cudaSuccess)\
  {\
      printf("ERROR: %s:%d,",__FILE__,__LINE__);\
      printf("code:%d,reason:%s\n",error,cudaGetErrorString(error));\
      exit(1);\
  }\
}
 


__device__ float bilinear_interpolation(float x, float y, int map_width, float *mapping)
{

	int x1 = floor(x);
	int y1 = floor(y);
	int x2 = x1 + 1;
	int y2 = y1 + 1;

	//row-y,col-x

	if (x1 == 1919) {
		float out = mapping[y1 *map_width + x1];
		return out;
	}
	else {
		float fq11 = mapping[y1 *map_width + x1];
		float fq21 = mapping[y1 *map_width + x2];
		float fq12 = mapping[y2 *map_width + x1];
		float fq22 = mapping[y2 *map_width + x2];

		if (-2 == fq11 || -2 == fq21 || -2 == fq12 || -2 == fq22)
		{
			return -2;
		}

		float out = fq11 * (x2 - x) * (y2 - y) + fq21 * (x - x1) * (y2 - y) + fq12 * (x2 - x) * (y - y1) + fq22 * (x - x1) * (y - y1);

		return out;
	}
	 

}

__global__ void kernel_reconstruct_pointcloud_base_table(int width,int height,float * const xL_rotate_x,float * const xL_rotate_y,float * const single_pattern_mapping,float * const R_1,float b,
float * const confidence_map,float * const phase_x , float * const pointcloud,float * const depth)
{
    const unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	const unsigned int idy = blockIdx.y * blockDim.y + threadIdx.y;

  
	const unsigned int offset = idy * width + idx;

	if (idx < width && idy < height)
	{
		/****************************************************************************/
		//phase to position
		// float Xp = phase_x[offset] * d_dlp_width_ /d_max_phase_; 
		float Xp = (phase_x[offset] * 1280) /(2*CV_PI); 
        float Xcr = xL_rotate_x[offset];
        float Ycr = xL_rotate_y[offset];
 
 
        float Xpr = bilinear_interpolation(Xp, (Ycr + 1) * 2000, 2000, single_pattern_mapping);
        float delta_X = std::abs(Xcr - Xpr); 
        float Z = b / delta_X;
	
		float X_L = Z * Xcr * R_1[0] + Z * Ycr * R_1[1] + Z * R_1[2];
		float Y_L = Z * Xcr * R_1[3] + Z * Ycr * R_1[4] + Z * R_1[5];
		float Z_L = Z * Xcr * R_1[6] + Z * Ycr * R_1[7] + Z * R_1[8];
 
  
		// if(confidence_map[offset] > d_confidence_ && Z_L > d_min_z_ && Z_L< d_max_z_ && Xp > 0)
		if(confidence_map[offset] > 10 && Z_L > 10 && Z_L< 3000 && Xp > 0)
		{
		    pointcloud[3 * offset + 0] = X_L;
		    pointcloud[3 * offset + 1] = Y_L;
		    pointcloud[3 * offset + 2] = Z_L; 
			
		    depth[offset] = Z_L; 
		}
		else
		{
		    pointcloud[3 * offset + 0] = 0;
		    pointcloud[3 * offset + 1] = 0;
		    pointcloud[3 * offset + 2] = 0; 
			
		    depth[offset] = 0; 
		}

		
		if (-2 == Xcr || -2 == Ycr || -2 == Xpr)
		{
			pointcloud[3 * offset + 0] = 0;
		    pointcloud[3 * offset + 1] = 0;
		    pointcloud[3 * offset + 2] = 0; 
			
		    depth[offset] = 0; 
		}
  
		/******************************************************************/


	}
}

