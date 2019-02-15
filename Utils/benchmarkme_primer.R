library(benchmarkme)

res = benchmark_std(runs = 3)
upload_results(res)
plot(res)


get_ram()
get_cpu()
get_linear_algebra()
get_byte_compiler()
get_platform_info()
get_r_version()


library(compiler)
f <- function(n, x) for (i in 1:n) x = (1 + x)^(-1)
g <- cmpfun(f)

library(microbenchmark)
compare <- microbenchmark(f(1000, 1), g(1000, 1), times = 1000)
