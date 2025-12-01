import argparse
import numpy as np
from PIL import Image


def srgb_to_linear(x):
    a = 0.055
    return np.where(x <= 0.04045, x / 12.92, ((x + a) / (1 + a)) ** 2.4)


def linear_to_srgb(x):
    a = 0.055
    return np.where(x <= 0.0031308, 12.92 * x, (1 + a) * (x ** (1 / 2.4)) - a)


def save_img(data, output_path):
    out_arr = np.clip(data * 255.0 + 0.5, 0, 255).astype(np.uint8)
    out_img = Image.fromarray(out_arr, mode="RGB")
    out_img.save(output_path)


def make_salt_and_pepper_noise(image, args):
    salt_prob = args.amount
    pepper_prob = args.amount
    out = np.copy(image)
    salt_pixels = np.random.rand(*image.shape[:-1]) < salt_prob
    out[salt_pixels] = 1
    pepper_pixels = np.random.rand(*image.shape[:-1]) < pepper_prob
    out[pepper_pixels] = 0
    return out


def make_iid_gaussian_noise(img, args):
    out = np.clip(img + np.random.normal(0, args.sigma, img.shape), 0.0, 1.0)
    return out


def make_corr_gaussian_noise(img, args, corr=0.8, seed=42):
    rng = np.random.default_rng(seed)
    lin = srgb_to_linear(img)
    sigma = args.sigma
    covar = (sigma**2) * np.array(
        [[1, corr, corr], [corr, 1, corr], [corr, corr, 1]], dtype=np.float32
    )
    h, w, _ = lin.shape
    noise = rng.multivariate_normal([0, 0, 0], covar, size=h * w).reshape(h, w, 3)
    noisy = np.clip(lin + noise, 0.0, 1.0)
    out = np.clip(linear_to_srgb(noisy), 0.0, 1.0)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("input", help="input image path")
    p.add_argument(
        "--output",
        default="image-noisy/",
        help="the directory of noisy images",
    )
    p.add_argument(
        "--amount",
        type=float,
        default=0.05,
        help="Fraction of pixels to corrupt, in [0,1] (default: 0.02)",
    )
    p.add_argument(
        "--mode",
        type=str,
        default="both",
        help="type of noise to add to the image",
    )
    p.add_argument(
        "--sigma",
        type=float,
        default=0.07,
        help="the std dev of the gaussian noise add to the image",
    )
    p.add_argument(
        "--release",
        dest="release",
        action="store_true",
        help="set in release mode to not shrink the image size",
    )

    args = p.parse_args()
    if args.output[-1] != "/":
        print("usage: --output <output directory>")
        exit(1)
    img = Image.open(args.input).convert("RGB")
    if not args.release:
        img = img.resize((img.size[0] // 2, img.size[1] // 2))
    img = np.array(img) / 255
    img = img.astype(np.float32)

    img_name = args.input.split("/")[-1]
    if args.mode == "salts":
        out = make_salt_and_pepper_noise(img, args)
        output_path = args.output + "salted_" + img_name
        save_img(out, output_path)
    elif args.mode == "iid_gaussian":
        out = make_iid_gaussian_noise(img, args)
        output_path = args.output + "iid_" + img_name
        save_img(out, output_path)
    elif args.mode == "corr_gausian":
        out = make_corr_gaussian_noise(img, args)
        output_path = args.output + "corr_" + img_name
        save_img(out, output_path)
    elif args.mode == "both":
        out = make_salt_and_pepper_noise(img, args)
        output_path = args.output + "salted_" + img_name
        save_img(out, output_path)

        out = make_iid_gaussian_noise(img, args)
        output_path = args.output + "iid_" + img_name
        save_img(out, output_path)

        out = make_corr_gaussian_noise(img, args)
        output_path = args.output + "corr_" + img_name
        save_img(out, output_path)
    else:
        print(f"error: invalid mode {args.mode}")
        exit(1)


if __name__ == "__main__":
    main()
