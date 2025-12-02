'''
See LICENSE folder for this sample’s licensing information.

Abstract:
The tiny NeRF with HashEncoder.
'''

from render_utils import *
import matplotlib.pyplot as plt
from tensorflow.keras import layers
from tensorflow import keras
from tqdm import tqdm
import numpy as np
import imageio
import os
import tensorflow as tf

tf.random.set_seed(42)

import sys
sys.path.append(os.path.join(os.path.dirname(__file__), './hash_encoder/'))
from hash_encoder import HashEncoder

# Initialize global variables.
AUTO = tf.data.AUTOTUNE
BATCH_SIZE = 1
NUM_SAMPLES = 128
EPOCHS = 20

# Near and far planes for the Lego dataset.
NEAR = 2.0
FAR = 6.0

# Download the data if it doesn't already exist.
file_name = "tiny_nerf_data.npz"
url = "https://people.eecs.berkeley.edu/~bmild/nerf/tiny_nerf_data.npz"
if not os.path.exists(file_name):
    data = keras.utils.get_file(fname=file_name, origin=url)

data = np.load(data)
images = data["images"]

im_shape = images.shape
(num_images, H, W, _) = images.shape

(poses, focal) = (data["poses"], data["focal"])

# Plot a random image from the dataset for visualization.
# plt.imshow(images[np.random.randint(low=0, high=num_images)])
# plt.show()


def get_rays(height, width, focal, pose):
    """Computes origin point and direction vector of rays.
    Args:
        height: Height of the image.
        width: Width of the image.
        focal: The focal length between the images and the camera.
        pose: The pose matrix of the camera.
    Returns:
        Tuple of origin point and direction vector for rays.
    """
    # Build a meshgrid for the rays.
    i, j = tf.meshgrid(
        tf.range(width, dtype=tf.float32),
        tf.range(height, dtype=tf.float32),
        indexing="xy",
    )

    # Normalize the x axis coordinates.
    transformed_i = (i - width * 0.5) / focal

    # Normalize the y axis coordinates.
    transformed_j = (j - height * 0.5) / focal

    # Create the direction unit vectors.
    directions = tf.stack(
        [transformed_i, -transformed_j, -tf.ones_like(i)], axis=-1)

    # Get the camera matrix.
    camera_matrix = pose[:3, :3]
    height_width_focal = pose[:3, -1]

    # Get origins and directions for the rays.
    transformed_dirs = directions[..., None, :]
    camera_dirs = transformed_dirs * camera_matrix
    ray_directions = tf.reduce_sum(camera_dirs, axis=-1)
    ray_origins = tf.broadcast_to(height_width_focal, tf.shape(ray_directions))

    # Return the origins and directions.
    return (ray_origins, ray_directions)


def render_flat_rays(ray_origins, ray_directions, near, far, num_samples, rand=True):
    """Renders the rays and flattens it.
    Args:
        ray_origins: The origin points for rays.
        ray_directions: The direction unit vectors for the rays.
        near: The near bound of the volumetric scene.
        far: The far bound of the volumetric scene.
        num_samples: Number of sample points in a ray.
        rand: Choice for randomizing the sampling strategy.
    Returns:
       Tuple of flattened rays and sample points on each rays.
    """
    # Compute 3D query points.
    # Equation: r(t) = o+td -> Building the "t" here.
    t_vals = tf.linspace(near, far, num_samples)
    if rand:
        # Inject uniform noise into the sample space to make the sampling
        # continuous.
        shape = list(ray_origins.shape[:-1]) + [num_samples]
        noise = tf.random.uniform(shape=shape) * (far - near) / num_samples
        t_vals = t_vals + noise

    # Equation: r(t) = o + td -> Building the "r" here.
    rays = ray_origins[..., None, :] + (
        ray_directions[..., None, :] * t_vals[..., None]
    )
    rays_flat = tf.reshape(rays, [-1, 3])

    return (rays_flat, t_vals)


def map_fn(pose):
    """Maps individual pose to flattened rays and sample points.
    Args:
        pose: The pose matrix of the camera.
    Returns:
        Tuple of flattened rays and sample points corresponding to the
        camera pose.
    """
    (ray_origins, ray_directions) = get_rays(
        height=H, width=W, focal=focal, pose=pose)
    (rays_flat, t_vals) = render_flat_rays(
        ray_origins=ray_origins,
        ray_directions=ray_directions,
        near=NEAR,
        far=FAR,
        num_samples=NUM_SAMPLES,
        rand=True,
    )
    return (rays_flat, t_vals)


# Create the training split.
split_index = int(num_images * 0.8)

# Split the images into training and validation.
train_images = images[:split_index]
val_images = images[split_index:]

# Split the poses into training and validation.
train_poses = poses[:split_index]
val_poses = poses[split_index:]

# Make the training pipeline.
train_img_ds = tf.data.Dataset.from_tensor_slices(train_images)
train_pose_ds = tf.data.Dataset.from_tensor_slices(train_poses)
train_ray_ds = train_pose_ds.map(map_fn, num_parallel_calls=AUTO)
training_ds = tf.data.Dataset.zip((train_img_ds, train_ray_ds))
train_ds = (
    training_ds.shuffle(BATCH_SIZE)
    .batch(BATCH_SIZE, drop_remainder=True, num_parallel_calls=AUTO)
    .prefetch(AUTO)
)

# Make the validation pipeline.
val_img_ds = tf.data.Dataset.from_tensor_slices(val_images)
val_pose_ds = tf.data.Dataset.from_tensor_slices(val_poses)
val_ray_ds = val_pose_ds.map(map_fn, num_parallel_calls=AUTO)
validation_ds = tf.data.Dataset.zip((val_img_ds, val_ray_ds))
val_ds = (
    validation_ds.shuffle(BATCH_SIZE)
    .batch(BATCH_SIZE, drop_remainder=True, num_parallel_calls=AUTO)
    .prefetch(AUTO)
)


def render_rgb_depth(model, rays_flat, t_vals, rand=False, train=True):
    """Generates the RGB image and depth map from model prediction.
    Args:
        model: The MLP model that is trained to predict the rgb and
            volume density of the volumetric scene.
        rays_flat: The flattened rays that serve as the input to
            the NGP model.
        t_vals: The sample points for the rays.
        rand: Choice to randomize the sampling strategy.
        train: Whether the model is in the training or testing phase.
    Returns:
        Tuple of rgb image and depth map.
    """
    # Normalize the points to [0, 1] (ad-hoc for the Lego dataset).
    rays_flat_normalized = (rays_flat + 4.0) / 8.0

    # Get the predictions from the hash encoding.
    h = model.enc(tf.reshape(rays_flat_normalized, (-1, 3)))

    # Go through the sigma net.
    h = model.sigma_net(h)
    sigma_a = tf.nn.relu(h[..., 0])
    
    # Scaling up the sigma empirically fastens the geometry convergence.
    sigma_a *= 50.0
    geo_feat = h[..., 1:]

    # In this example code, view direction conditioning is not used.
    rgb = model.color_net(geo_feat)
    rgb = tf.sigmoid(rgb)

    # Some reshapes.
    sigma_a = tf.reshape(sigma_a, shape=(BATCH_SIZE, H, W, NUM_SAMPLES))
    rgb = tf.reshape(rgb, shape=(BATCH_SIZE, H, W, NUM_SAMPLES, 3))

    # Get the distance of adjacent intervals.
    delta = t_vals[..., 1:] - t_vals[..., :-1]
    
    # Make the delta shape = (num_samples).
    if rand:
        delta = tf.concat(
            [delta, tf.broadcast_to([0.0], shape=(BATCH_SIZE, H, W, 1))], axis=-1
        )
        alpha = 1.0 - tf.exp(-sigma_a * delta)
    else:
        delta = tf.concat(
            [delta, tf.broadcast_to([0.0], shape=(BATCH_SIZE, 1))], axis=-1
        )
        alpha = 1.0 - tf.exp(-sigma_a * delta[:, None, None, :])

    # Get transmittance.
    exp_term = 1.0 - alpha
    epsilon = 1e-10
    transmittance = tf.math.cumprod(
        exp_term + epsilon, axis=-1, exclusive=True)
    weights = alpha * transmittance
    rgb = tf.reduce_sum(weights[..., None] * rgb, axis=-2)

    if rand:
        depth_map = tf.reduce_sum(weights * t_vals, axis=-1)
    else:
        depth_map = tf.reduce_sum(weights * t_vals[:, None, None], axis=-1)

    # Mix the background color (assuming background is black).
    bg_color = 0 
    weights_sum = tf.reduce_sum(weights, axis=-1)
    rgb = rgb + tf.expand_dims((1.0 - weights_sum), -1) * bg_color

    return (rgb, depth_map)


def total_variation_and_sparsity(model, rand=True):
    original_shape = model.point_samples.shape

    grid_points = model.point_samples
    if rand:
        grid_points += (tf.random.uniform(shape=original_shape) -
                        0.5) / float(model.n_grid_samples)

    h = model.enc(tf.reshape(grid_points, (-1, 3)))

    h = model.sigma_net(h)
    sigma = tf.nn.relu(h[..., 0])

    geo_feat = h[..., 1:]

    rgb = model.color_net(geo_feat)
    rgb = tf.sigmoid(rgb)

    rgba = tf.concat([rgb, tf.expand_dims(sigma, -1)], axis=-1)

    # Some reshapes.
    rgba = tf.reshape(rgba, shape=(
        original_shape[0], original_shape[1], original_shape[2], -1))

    # Input tensor shape: [H, W, L, C].
    def compute_total_variation_3d(grid_n_unit):
        voxel_dif1 = tf.abs(
            grid_n_unit[:, :, :-1, :] - grid_n_unit[:, :, 1:, :])
        voxel_dif2 = tf.abs(
            grid_n_unit[:, :-1, :, :] - grid_n_unit[:, 1:, :, :])
        voxel_dif3 = tf.abs(
            grid_n_unit[:-1, :, :, :] - grid_n_unit[1:, :, :, :])
        tv = (tf.reduce_mean(voxel_dif1) + tf.reduce_mean(voxel_dif2) +
              tf.reduce_mean(voxel_dif3)) / 3.0
        return tv

    tv = compute_total_variation_3d(rgba)

    # Use Cauchy loss.
    sparsity = tf.reduce_mean(tf.math.log(1.0 + 2*sigma**2))

    return tv, sparsity


"""
## Training
The training step is implemented as part of a custom `keras.Model` subclass
so that you can make use of the `model.fit` functionality.
"""


class NGP(keras.Model):
    def __init__(self):
        super().__init__()

        # Input coordinate dimension.
        ngp_n_dim = 3  
        # Number of levels.
        ngp_levels = 4  
        # Number of feature channels per hash entry.
        ngp_feature = 2  
        # Hash encode call.
        self.enc = HashEncoder(n_dim=ngp_n_dim, n_levels=ngp_levels, n_feature=ngp_feature,
                               resolution_coarsest=32, log2_hashmap_size=19, resolution_finest=256)

        # The output feature length.
        ngp_output_channel = ngp_feature * ngp_levels

        # The geometry feature vector length for the color net.
        geometry_feat = 3  
        self.sigma_net = keras.Sequential(
            [
                keras.Input(shape=(ngp_output_channel,)),
                keras.layers.Dense(
                    geometry_feat + 1,  # +1 for the sigma value
                    use_bias=False,
                    activation=None,
                    name="sigma_net",
                    kernel_initializer=keras.initializers.HeUniform()
                ),
            ]
        )

        self.color_net = keras.Sequential(
            [
                keras.Input(shape=(geometry_feat,)),
                keras.layers.Dense(
                    3,
                    activation=None,
                    use_bias=False,
                    name="color_net",
                    kernel_initializer=keras.initializers.HeUniform()
                ),
            ]
        )

        # Generate point samples for computing total variation.
        self.n_grid_samples = 64
        xs, ys, zs = tf.meshgrid(
            tf.range(self.n_grid_samples, dtype=tf.int32),
            tf.range(self.n_grid_samples, dtype=tf.int32),
            tf.range(self.n_grid_samples, dtype=tf.int32),
            indexing="ij",
        )
        # Normalize to [0, 1].
        xs = tf.cast(xs, tf.float32) / float(self.n_grid_samples)
        ys = tf.cast(ys, tf.float32) / float(self.n_grid_samples)
        zs = tf.cast(zs, tf.float32) / float(self.n_grid_samples)

        self.point_samples = tf.concat(
            [tf.expand_dims(xs, -1), tf.expand_dims(ys, -1), tf.expand_dims(zs, -1)], -1)

    def compile(self, optimizer, loss_fn):
        super().compile()
        self.optimizer = optimizer
        self.loss_fn = loss_fn
        self.loss_tracker = keras.metrics.Mean(name="loss")
        self.psnr_metric = keras.metrics.Mean(name="psnr")

    def train_step(self, inputs):
        # Get the images and the rays.
        (images, rays) = inputs
        (rays_flat, t_vals) = rays

        with tf.GradientTape() as tape:
            # Get the predictions from the model.
            rgb, _ = render_rgb_depth(
                model=self, rays_flat=rays_flat, t_vals=t_vals, rand=True
            )

            # The render loss.
            loss_render = self.loss_fn(images, rgb)
            # The TV loss and sparsity loss.
            loss_tv, loss_sparsity = total_variation_and_sparsity(model=self)
            # Compute total loss.
            # loss = loss_render + loss_sparsity * 5e-2 + loss_tv * 1e-1
            loss = loss_render + loss_sparsity * 5e-2

        # Get the trainable variables.
        trainable_variables = self.trainable_variables

        # Get the gradients of the trainable variables with respect to the loss.
        gradients = tape.gradient(loss, trainable_variables)

        # Apply the grads and optimize the model.
        self.optimizer.apply_gradients(zip(gradients, trainable_variables))

        # Get the PSNR of the reconstructed images and the source images.
        psnr = tf.image.psnr(images, rgb, max_val=1.0)

        # Update the metrics.
        self.loss_tracker.update_state(loss)
        self.psnr_metric.update_state(psnr)
        return {"loss": self.loss_tracker.result(), "psnr": self.psnr_metric.result()}

    def test_step(self, inputs):
        # Get the images and the rays.
        (images, rays) = inputs
        (rays_flat, t_vals) = rays

        # Get the predictions from the model.
        rgb, _ = render_rgb_depth(
            model=self, rays_flat=rays_flat, t_vals=t_vals, rand=True
        )
        loss = self.loss_fn(images, rgb)

        # Get the PSNR of the reconstructed images and the source images.
        psnr = tf.image.psnr(images, rgb, max_val=1.0)

        # Update the metrics.
        self.loss_tracker.update_state(loss)
        self.psnr_metric.update_state(psnr)
        return {"loss": self.loss_tracker.result(), "psnr": self.psnr_metric.result()}

    @property
    def metrics(self):
        return [self.loss_tracker, self.psnr_metric]


test_imgs, test_rays = next(iter(train_ds))
test_rays_flat, test_t_vals = test_rays

loss_list = []

class TrainMonitor(keras.callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        loss = logs["loss"]
        loss_list.append(loss)
        test_recons_images, depth_maps = render_rgb_depth(
            model=self.model,
            rays_flat=test_rays_flat,
            t_vals=test_t_vals,
            rand=True,
            train=False,
        )
        # Plot the rgb, depth, and the loss plot.
        fig, ax = plt.subplots(nrows=1, ncols=4, figsize=(20, 5))
        ax[0].imshow(keras.preprocessing.image.array_to_img(
            train_images[0] * 255, scale=False))
        ax[0].set_title(f"Original Image: {epoch:03d}")

        ax[1].imshow(keras.preprocessing.image.array_to_img(
            test_recons_images[0] * 255, scale=False))
        ax[1].set_title(f"Predicted Image: {epoch:03d}")

        ax[2].imshow(keras.preprocessing.image.array_to_img(
            depth_maps[0, ..., None], scale=True))
        ax[2].set_title(f"Depth Map: {epoch:03d}")

        ax[3].plot(loss_list)
        ax[3].set_xticks(np.arange(0, EPOCHS + 1, 5.0))
        ax[3].set_title(f"Loss Plot: {epoch:03d}")

        fig.savefig(f"result_nerf_hash/nerf_{epoch:03d}.png")
        # plt.show()
        plt.close()


num_pos = H * W * NUM_SAMPLES

model = NGP()
lr_schedule = keras.optimizers.schedules.ExponentialDecay(
    initial_learning_rate=1e-2,
    decay_steps=1000,
    decay_rate=0.33)
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=lr_schedule, beta_1=0.9, beta_2=0.99, epsilon=1e-15, amsgrad=False), loss_fn=keras.losses.MeanSquaredError()
)

# Create a directory to save the images during training.
if not os.path.exists("result_nerf_hash"):
    os.makedirs("result_nerf_hash")

model.fit(
    train_ds,
    validation_data=val_ds,
    batch_size=BATCH_SIZE,
    epochs=EPOCHS,
    callbacks=[TrainMonitor()],
    steps_per_epoch=split_index // BATCH_SIZE,
)


create_gif("result_nerf_hash/*.png", "result_nerf_hash/training.gif")

# Get the trained NGP model and infer.
test_recons_images, depth_maps = render_rgb_depth(
    model=model,
    rays_flat=test_rays_flat,
    t_vals=test_t_vals,
    rand=True,
    train=False,
)

# Create subplots.
fig, axes = plt.subplots(nrows=5, ncols=3, figsize=(10, 20))

for ax, ori_img, recons_img, depth_map in zip(
    axes, test_imgs, test_recons_images, depth_maps
):
    ax[0].imshow(keras.preprocessing.image.array_to_img(ori_img))
    ax[0].set_title("Original")

    ax[1].imshow(keras.preprocessing.image.array_to_img(recons_img))
    ax[1].set_title("Reconstructed")

    ax[2].imshow(
        keras.preprocessing.image.array_to_img(depth_map[..., None]), cmap="inferno"
    )
    ax[2].set_title("Depth Map")

rgb_frames = []
batch_flat = []
batch_t = []

# Iterate over different theta value and generate scenes.
for index, theta in tqdm(enumerate(np.linspace(0.0, 360.0, 120, endpoint=False))):
    # Get the camera-to-world matrix.
    c2w = pose_spherical(theta, -30.0, 4.0)

    # Get rays and sample the points.
    ray_oris, ray_dirs = get_rays(H, W, focal, c2w)
    rays_flat, t_vals = render_flat_rays(
        ray_oris, ray_dirs, near=NEAR, far=FAR, num_samples=NUM_SAMPLES, rand=False
    )

    # Render the image.
    if index % BATCH_SIZE == 0 and index > 0:
        batched_flat = tf.stack(batch_flat, axis=0)
        batch_flat = [rays_flat]

        batched_t = tf.stack(batch_t, axis=0)
        batch_t = [t_vals]

        rgb, _ = render_rgb_depth(
            model, batched_flat, batched_t, rand=False, train=False
        )

        temp_rgb = [np.clip(255 * img, 0.0, 255.0).astype(np.uint8)
                    for img in rgb]

        rgb_frames = rgb_frames + temp_rgb
    else:
        batch_flat.append(rays_flat)
        batch_t.append(t_vals)

rgb_video = "result_nerf_hash/rgb_video.mp4"
imageio.mimwrite(rgb_video, rgb_frames, fps=30,
                 quality=7, macro_block_size=None)
