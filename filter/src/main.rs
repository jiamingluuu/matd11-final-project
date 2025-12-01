use anyhow::Result;
use clap::Parser;
use image::ExtendedColorType;
use ndarray::parallel::prelude::*;
use ndarray::{Array3, Axis};
use std::path::PathBuf;

const SIGMA: f32 = 0.05;
const CORR: f32 = 0.8;
const A: f32 = (1.0 / (SIGMA * SIGMA)) * (1.0 + CORR) / ((1.0 - CORR) * (1.0 + 2.0 * CORR));
const B: f32 = -(1.0 / (SIGMA * SIGMA)) * CORR / ((1.0 - CORR) * (1.0 + 2.0 * CORR));

#[derive(Parser, Debug)]
#[command(name = "bilateral_denoise")]
struct Args {
    #[arg(long)]
    input: String,

    #[arg(long)]
    output_dir: String,

    #[arg(long, default_value_t = 5)]
    r: i32,

    #[arg(long, default_value_t = 3.0)]
    sigma_s: f32,

    #[arg(long, default_value_t = 1.0)]
    sigma_r: f32,

    #[arg(long, default_value_t = 32)]
    tile: usize,
}

#[inline]
fn get_color_triplet(data: &Array3<f32>, x: usize, y: usize) -> [f32; 3] {
    [data[(y, x, 0)], data[(y, x, 1)], data[(y, x, 2)]]
}

fn build_kernel(r: i32, sigma_s: f32) -> Vec<(i32, i32, f32)> {
    let mut kernel = Vec::with_capacity((2 * r + 1).pow(2) as usize);
    for dx in -r..r {
        for dy in -r..r {
            let d2 = (dx * dx + dy * dy).pow(2);
            let ws = (-d2 as f32 / (2.0 * sigma_s * sigma_s)).exp();
            kernel.push((dx, dy, ws));
        }
    }
    kernel
}

fn load_image(input: &PathBuf) -> Result<Array3<f32>> {
    println!("{:?}", input);
    let img = image::open(input)?.to_rgb8();
    let dim = img.dimensions();
    let (w, h) = (dim.0 as usize, dim.1 as usize);
    let raw = img
        .into_raw()
        .into_iter()
        .map(|u| (u as f32) / 255.0)
        .collect::<Vec<_>>();
    Ok(Array3::from_shape_vec((h, w, 3), raw)?)
}

fn save_img(out: Array3<f32>, out_path: &PathBuf) -> Result<()> {
    println!("saving {:?}", out_path);
    let (h, w, _) = out.dim();
    let mut raw = vec![0u8; 3 * w * h];
    let mut i = 0;
    for y in 0..h {
        for x in 0..w {
            for c in 0..3 {
                let v = out[(y, x, c)].clamp(0.0, 1.0);
                raw[i] = (v * 255.0) as u8;
                i += 1;
            }
        }
    }
    image::save_buffer(out_path, &raw, w as u32, h as u32, ExtendedColorType::Rgb8)?;
    Ok(())
}

fn bilateral_filter_euclidean(args: &Args, data: &Array3<f32>) -> Array3<f32> {
    let (h, w, _) = data.dim();
    let wm1 = (w - 1) as i32;
    let hm1 = (h - 1) as i32;
    let kernel = build_kernel(args.r, args.sigma_s);
    let inv_2r2 = 1.0 / (2.0 * args.sigma_r * args.sigma_r);
    let mut out = Array3::<f32>::zeros((h, w, 3));
    out.axis_iter_mut(Axis(0))
        .into_par_iter()
        .enumerate()
        .for_each(|(y, mut out_row)| {
            for x in 0..w {
                let p = get_color_triplet(&data, x, y);
                let mut w_sum = 0.0f64;
                let mut sum = [0.0f64; 3];
                for (dx, dy, ws) in kernel.iter() {
                    let qx = (x as i32 + dx).clamp(0, wm1) as usize;
                    let qy = (y as i32 + dy).clamp(0, hm1) as usize;
                    let q = get_color_triplet(&data, qx, qy);

                    let dr = p[0] - q[0];
                    let dg = p[1] - q[1];
                    let db = p[2] - q[2];

                    let norm_sq = dr * dr + dg * dg + db * db;
                    let wr = (-norm_sq * inv_2r2).exp();
                    let wgt = (wr * ws) as f64;

                    sum[0] += wgt * (q[0] as f64);
                    sum[1] += wgt * (q[1] as f64);
                    sum[2] += wgt * (q[2] as f64);
                    w_sum += wgt;
                }
                let inv = 1.0 / w_sum;
                out_row[(x, 0)] = (sum[0] * inv) as f32;
                out_row[(x, 1)] = (sum[1] * inv) as f32;
                out_row[(x, 2)] = (sum[2] * inv) as f32;
            }
        });
    out
}

fn bilateral_filter_riemannian(args: &Args, data: &Array3<f32>) -> Array3<f32> {
    let (h, w, _) = data.dim();
    let wm1 = (w - 1) as i32;
    let hm1 = (h - 1) as i32;
    let kernel = build_kernel(args.r, args.sigma_s);
    let inv_2r2 = 1.0 / (2.0 * args.sigma_r * args.sigma_r);
    let mut out = Array3::<f32>::zeros((h, w, 3));
    out.axis_iter_mut(Axis(0))
        .into_par_iter()
        .enumerate()
        .for_each(|(y, mut out_row)| {
            for x in 0..w {
                let p = get_color_triplet(&data, x, y);
                let mut w_sum = 0.0f64;
                let mut sum = [0.0f64; 3];
                for (dx, dy, ws) in kernel.iter() {
                    let qx = (x as i32 + dx).clamp(0, wm1) as usize;
                    let qy = (y as i32 + dy).clamp(0, hm1) as usize;
                    let q = get_color_triplet(&data, qx, qy);

                    let dr = p[0] - q[0];
                    let dg = p[1] - q[1];
                    let db = p[2] - q[2];

                    let norm_sq = dr * dr + dg * dg + db * db;
                    let mixed = dr * dg + dr * db + dg * db;
                    let num = A * norm_sq + 2.0 * B * mixed;
                    let wr = (-num * inv_2r2).exp();
                    let wgt = (wr * ws) as f64;

                    sum[0] += wgt * (q[0] as f64);
                    sum[1] += wgt * (q[1] as f64);
                    sum[2] += wgt * (q[2] as f64);
                    w_sum += wgt;
                }
                let inv = 1.0 / w_sum;
                out_row[(x, 0)] = (sum[0] * inv) as f32;
                out_row[(x, 1)] = (sum[1] * inv) as f32;
                out_row[(x, 2)] = (sum[2] * inv) as f32;
            }
        });
    out
}

fn main() -> Result<()> {
    let args = Args::parse();
    let input = PathBuf::from(&args.input);
    let fname_raw = args.input.split("/").last().unwrap();

    let data = load_image(&input)?;
    let out = bilateral_filter_euclidean(&args, &data);
    let out_fname = format!("{}_{}", "euclidean_filtered", fname_raw);
    let out_path = PathBuf::from(format!("{}/{}", args.output_dir, out_fname));
    save_img(out, &out_path)?;

    let out = bilateral_filter_riemannian(&args, &data);
    let out_fname = format!("{}_{}", "riemannian_filtered", fname_raw);
    let out_path = PathBuf::from(format!("{}/{}", args.output_dir, out_fname));
    save_img(out, &out_path)?;

    Ok(())
}
