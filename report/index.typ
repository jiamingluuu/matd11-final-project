// TODO: add citations
#import "@preview/unequivocal-ams:0.1.2": ams-article, theorem, proof

#show: ams-article.with(
  title: [Colorimetry and its application in image denoising: From Newton to Riemann’s Geometric modeling],
  abstract: [The ever-emerging devices bringing into trouble. In this paper, we performed a review on the development of colorimetry,and conducted experiments on the effectiveness of norm on image denoisng algorithms. The result shows
  // TODO: Complete the abstract section.
],
  authors: (
    (
      name: "Jiaming Lu",
    ),
  ),
)

#outline()
= Introduction
Color is one of the most important factors in human aesthetics. However, the diversity in computer hardware brings rendering unified colors on different monitors into trouble. Moreover, the difference in human perception of color inevitably complicates this issue. Color management, the process that ensures a consistent and accurate reproduction of color on different devices, has come into our vision, and has un-surprisingly become the cornerstone of modern computer graphics. In the later lecture, we are going to introduce color spaces and their applications in colorimetry, which is the science of measuring color. 

= Early stage of colorimetry: Newton's color wheel model
== Model definition
The history of color science can be traced back to ancient Greece, but it was until Issac Newton who was the first one purposed our first color model. Newton's model was color has seven principal colors, red, orange, yellow, green, blue, indigo, and violet, as an analogy to the seven tones of notes within an octave, distributed according to a certain portion of a circle with center $O$, called the _color whell_. As we travel around the circumference of the wheel, the _hue_ of the color changes, and as we go along the radius of the wheel, the _saturation_ of the color varies.

On mixing a compound color, which means a color contains multiple principal colors, we draw circles with a radius that is proportional to the intensity of each principal color, and compute the barycenter of the circles. The determined barycenter is the result of color mixing.

== Model deficiency
A model is an approximation to the real world's physics, it is always imperfection. Newton's model is, in fact, a coarse approximation for various reasons.

Firstly, it lacks supports from physics and biology. The definition of the seven principal colors is not derived from the human visual system; rather, it is guided by an analogy to music theory. As a consequence, the choice of "seven" -- and in particular the status of indigo -- is not scientifically canonical. More importantly, the whell implicitly suggests a closed cycle of hues, where the short-wavelength end and the long-wavelength end are connected by purple/magenta -- yet these colors do not correspond to a single wavelength on the spectrum, but arise from mixtures.

Moreover, the model of color mixing is coarse. It appears that the result of finding the barycenter of the small circles does not precisely match the result of color mixing in the real world. For instance, mixing the same amount of blue and red would be closer to the circumference compared with the barycenter, resulting in a more saturated color.

Finally, an incomplete coordinate system for color definition. Chroma and brightness are the top two important factors that are missing in Newton's model. On missing the brightness, or the luminance of  a colored object, we lose the contrast between objects that are in the same color: navy and light sky blue have a similar hue value, but they look completely different because the former is much darker than the latter.

= Projective geometry in modern colorimetry
== Color matching
The human visual system contains three types of cone cells in the eye retina that are sensitive to short-, medium- and long- wavelength lights. Their responses are often denoted by S, M and L, emphasizing that they are not the well-known tricolor channels, but rather three broad sensitiviy curves.

The spectrum of a light wave is, with no doubt, a continuous function that lives in an infinite-dimensional vector space. Losslessly expressing any continuous function in the discrete world of computer science is impractical, nor is it efficient to compute its interaction (like reflection and absorption of the light ray) with other materials. We therefore project the spectrum of light onto a three-dimensional space, with each component corresponding to the stimuli of corn cells that are sensitive to the short, medium and long wavelength lights. Or in formal speaking, given a light wave with spectral power distribution function $S(lambda)$, and the sensitive curve of each cone with respect to the short-, medium- and long-wavelength lights $ell_S (lambda), ell_M (lambda), ell_L (lambda)$, the SML coordinate is given by 

$
mat(S; M; L) = mat(integral S(lambda) ell_S (lambda) d x;integral S(lambda) ell_M (lambda) d x;integral S(lambda) ell_L (lambda) d x ).
$

From now on, we have stepped into the realm of modern color science. Before beginning our further discussion, I want to draw our attention to distinguish between two terminologies that may be ambiguous in our latter discussion: _brightness_ and _luminance_. Luminance is a physical quantity which characterizes the luminous intensity per unit area; it is a physical fact. Whereas brightness is a quantity used to describe a human’s visual perception of a visual object, it is measured by experiments. In color science, we are interested in brightness.

However, the SML coordinates are seldom used directly in practice. Instead, a more practical coordinate system was given by CIE (Commission Internationale de l’Éclairage) in 1931: the XYZ coordinate system. The spirit is similar, but a different definition on color matching function:

$
mat(X; Y; Z) = mat(integral S(lambda) overline(x)(lambda) d x;integral S(lambda) overline(y) (lambda) d x;integral S(lambda) overline(z) (lambda) d x ).
$

== The horeseshoe-shaped color
The appearance of XYZ color space has become a standard and is still widely used until nowadays. However, the primary issue regarding this coordinate system is that it interleaves the notion of brightness and chromaticity: if we scale the triple $(X, Y, Z)$ by a positive constant, the overall intensity changes, but the chromatic character of the color does not. To separate these two factors, CIE defines the _chromaticity coordinates_ as a normalization of XYZ:
$
x = X / (X + Y + Z), y = Y / (X + Y + Z).
$
Geometrically, this ia a projection of the positive YXZ cone onto the plane $X + Y + Z = 1$, so that the overall scale is factored out. Plotting $(x, y)$ produces the well-known chromaticity diagram. The curved boundary (the spectral locus) corresponds to monochromatic spectral lights, while the straight segment connecting its two ends corresponds to non-spectral purples.

= Non-Euclidiean properties of human perception to color
Although we often represent a color as a three-dimensional vector (RGB, XYZ, etc.), the _perceived_ difference between two colors is not well-modelled by an ordinary Euclidean distance. A typical example is the _MacAdam ellipses_: around a fixed chromaticity, the set of colors that look equally different from the center is an ellipse whose size and orientation change across the chromaticity diagram. Mathematically, such ellipses define a local quadratic form 

$ d Delta E^2 = d c^T g(c) d c, $
where $c$ is a color coordinate and $g$ is a symmetric positive definite matrix that depends on the location in color space, this is exactly a Riemannian metric on the color manifold.

= Application of color metrics in color denoising
By the influence of environment, transmission channel, and many other factors, images inevitably contain noise, leading to a drop on the image quality, consequently affecting the post-image-processing pipeline techniques such as feature extraction, segmentation, etc. The need for image denoise has therefore brought it to the table of academic research.
The problem of image denoising can be modelled as follows:
$ I_"noisy" = I_"clean" + n, $
where $I_"noisy", I_"clean"$ and $n$ represent the noisy observation, the clean image, and the additive noise on the image, respectively. The goal of a denoising algorithm is to recover $I_"clean"$ from the observed $I_"noisy"$ by using assumptions about the noise $n$ and the structure of natural images.

When the image has color, an additional design choice appears: in which color space and under which metric do we measure the similarity between pixels? If we use the standard Euclidean norm in RGB, we implicitly assume that the observer is equally sensitive to all linear directions in RGB space, which contradicts the non-Euclidean properties discussed above. Instead, we can choose a metric that is closer to human perception, such as a Euclidean norm in $L^* a^* b^*$ or even a locally defined Riemannian norm derived from color difference formulas like $Delta E_(94)$ or $Delta E_(2000)$.

== Bilateral filter
The bilateral filter is a classical edge-preserving smoothing operator widely used in image denoising. For each pixel $p$, the output of the bilateral filter can be written as:

$ I^("filtered")(p) = 1/W_p sum_(q in N(p)) exp(-(norm(p - q)^2)/(2 sigma_s^2)) exp(-(d(I(p), I(q))^2)/(2 sigma_r^2)) I(p), $
where
- $I^"filtered"$ is the filtered image;
- $I$ is the noisy image;
- $p$ is the coordinates of the pixel to be filtered;
- $N(p)$ is the window centered in $p$;
- $d$ is the metric of the filter to be chosen, which is Euclidean by default;
- $W_p$ is a normalization factor.

== Relation between noise distribution and norm selected for denoise
Due to differences in image formation, the statistical distribution of the noise $n$ may vary from one situation to another. Namely, in some cases the noise is well modelled as independent Gaussian noise on each color channel; in other cases, the channels are strongly correlated, or the noise has heavier tails or mixed distributions. The choice of norm (or metric) used for denoising is closely related to the assumed distribution of $n$.

From a probabilistic viewpoint, many denoising methods can be interpreted as maximum a posteriori (MAP) estimators. If we assume the noise is Gaussian with zero mean and covariance matrix $Sigma$, that is. if
$ n ~ cal(N(bold(0), Sigma)), $
then the MAP estimator $p(y | x)$, up to a constant, is given by
$ norm(I_"noisy" - I_"clean")^2_(Sigma^(-1)) = (I_"noisy" - I_"clean")^T Sigma^(-1) (I_"noisy" - I_"clean"). $
The matrix $Sigma^(-1)$ defines a Mahalanobis norm or, geometrically, a Riemannian metric on the color space.

The special case arises as we assume the covariance matrix is a diagonal matrix, implying the noise are independent on each channel, so the norm is reduced to a Euclidean $L^2$ norm. If $Sigma$ has non-zero off-diagonal entries, then the level sets of this norm are ellipsoids rather than spheres.

= Experiment method
To visually examine the effectiveness of norm selection on the result of image denoising, we conducted experiments by applying bilateral filter on images that has different additive noise.

== Implementation details
The bilateral filter was implemented in the Rust programming language, with `ndarray` to ensure high-performance floating point arithmetics, accompany with `rayon` features to ensure the parallelism. Meanwhile, given a clear image $I_"clean"$, we used Python scripts to add three types of noise (namely: salts, independent and identically distributed (i.i.d.) Gaussian, and multi-variant Gaussian) yielding consequent noisy images $I_"salt", I_"iid", I_"corr"$.

For each of the noisy image, we applied bilateral filter with Euclidean norm Mahalanobis norm.
// TODO: Add more descriptions here

== Results

== Discussions

== Further work

= Conclusion
