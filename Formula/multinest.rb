class Multinest < Formula
  desc "Efficient Bayesian inference with nested sampling"
  homepage "https://github.com/Astro-Lee/MultiNest"
  url "https://github.com/Astro-Lee/MultiNest/archive/refs/tags/v#{version}.tar.gz"
  # sha256 "" # 首次 release 后填

  depends_on "cmake"  => :build
  depends_on "gcc"    # gfortran
  depends_on "openblas"
  depends_on "open-mpi"

  def install
    cd "MultiNest_v3.12_CMake/multinest" do
      system "cmake", "-B", "build", *std_cmake_args
      system "cmake", "--build", "build", "--parallel", "1"
      system "cmake", "--install", "build"
    end
  end

  test do
    system "#{bin}/eggboxC"
  end
end
