# This is a Makefile to compile the custom op to a .so file.

TF_CFLAGS=$(shell python -c 'import tensorflow as tf; print(" ".join(tf.sysconfig.get_compile_flags()))')
TF_LFLAGS=$(shell python -c 'import tensorflow as tf; print(" ".join(tf.sysconfig.get_link_flags()))')

hashEncoderKernel:
	rm -f hash_encoder_kernel.so
	xcrun -sdk macosx metal -c hash_encoder_kernel.metal -o hash_encoder_kernel.air -ffast-math
	xcrun -sdk macosx metallib hash_encoder_kernel.air -o hash_encoder_kernel.metallib
	clang++ -x objective-c++ -std=c++14 -shared hash_encoder_kernel.cc mtl_hash_encoder_kernel.cc -o hash_encoder_kernel.so -fPIC $(TF_CFLAGS) $(TF_LFLAGS) -O3 -framework Foundation -undefined dynamic_lookup

clean:
	rm -f hash_encoder_kernel.so
	
