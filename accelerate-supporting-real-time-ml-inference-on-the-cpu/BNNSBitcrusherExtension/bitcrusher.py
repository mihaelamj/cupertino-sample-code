import coremltools as ct
from coremltools.converters.mil import Builder as mb
from coremltools.converters.mil.mil import (
    get_new_symbol
)

@mb.program(input_specs=[mb.TensorSpec(shape=(get_new_symbol(),1,1)),
                         mb.TensorSpec(shape=(1,1,1)),
                         mb.TensorSpec(shape=(1,1,1)),
                         mb.TensorSpec(shape=(1,1,1)) ])
def prog(src, resolution, saturationGain, dryWet):

    # saturation

    dst = mb.mul(
        x=src,
        y=saturationGain
    )

    dst = mb.tanh(
        x=dst
    )

    # quantization

    dst = mb.mul(
        x=dst,
        y=resolution
    )
    
    dst = mb.round(
        x=dst
    )
    
    dst = mb.real_div(
        x=dst,
        y=resolution
    )
    
    # mix
    
    dst = mb.mul(
        x=dst,
        y=dryWet
    )
    
    dryWet = mb.sub(
        x=1.0,
        y=dryWet
    )
    
    src = mb.mul(
        x=src,
        y=dryWet
    )
        
    dst = mb.add(
        x=dst,
        y=src
    )
    
    return dst
    

input_shape_vector = ct.Shape(shape=(ct.RangeDim(lower_bound=1, upper_bound=1024, default=256), 1, 1))
input_shape_scalar = ct.Shape(shape=(1, 1, 1))

model = ct.convert(prog,
                   convert_to="mlprogram",
                   source="milinternal",
                   compute_precision=ct.precision.FLOAT32,
                   inputs=[ct.TensorType(shape=input_shape_vector, name="src"),
                           ct.TensorType(shape=input_shape_scalar, name="resolution"),
                           ct.TensorType(shape=input_shape_scalar, name="saturationGain"),
                           ct.TensorType(shape=input_shape_scalar, name="dryWet")])

spec = model.get_spec()
ct.utils.rename_feature(spec, 'add_0', 'dst')
model = ct.models.MLModel(spec, weights_dir=model.weights_dir) 

model.save("bitcrusher.mlpackage")
