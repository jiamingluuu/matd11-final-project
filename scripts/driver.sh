#! /bin/sh
set -eu

# setup the python dependency
uv sync

project_root=`pwd`
venv_py="$project_root/.venv/bin/python"
clean_image_dir="$project_root/image-clean"
noisy_image_dir="$project_root/image-noisy"
denoised_image_dir="$project_root/image-denoised"
filter_manifest="$project_root/filter/Cargo.toml"

if [ ! -d "$noisy_image_dir" ]; then
  mkdir "$noisy_image_dir"
fi

if [ ! -d "$denoised_image_dir" ]; then 
  mkdir "$denoised_image_dir"
fi

echo -n "==> Adding noise"
for image in "$clean_image_dir"/*; do
    "$venv_py" scripts/add_noise.py "$image" \
      --output "$noisy_image_dir/" \
      --sigma 0.05
done


echo -n "==> Applying filter"
for image in "$noisy_image_dir"/*; do
  cargo run \
    --quite \
    --manifest-path "$filter_manifest" \
    --release \
    -- \
    --input "$image" \
    --output-dir "$denoised_image_dir" \
    --sigma-r 1.5
done
