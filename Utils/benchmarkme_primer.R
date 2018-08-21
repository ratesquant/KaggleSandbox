library(benchmarkme)

res = benchmark_std()
upload_results(res)
plot(res)