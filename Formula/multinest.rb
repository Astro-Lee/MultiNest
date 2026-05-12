class Multinest < Formula
  desc "Efficient Bayesian inference with nested sampling"
  homepage "https://github.com/Astro-Lee/MultiNest"
  url "https://github.com/Astro-Lee/MultiNest/archive/refs/tags/v3.12.tar.gz"
  sha256 "7651820cca09b53ab09f63451733f35f3fd26a057f220489372f74663ec378b4" # 首次 release 后填

  depends_on "cmake"  => :build
  depends_on "gcc"    # gfortran
  depends_on "openblas"
  depends_on "open-mpi"

  def install
    cd "MultiNest_v3.12_CMake/multinest" do
      system "cmake", "-B", "build", *std_cmake_args
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end
  end

  test do
    # 检查库文件和头文件是否存在
    assert_predicate lib/"libmultinest.dylib", :exist?
    assert_predicate include/"multinest.h", :exist?
  end
end
