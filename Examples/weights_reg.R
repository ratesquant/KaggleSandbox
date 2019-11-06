n = 10000

set.seed(12345)

x1 = runif(n)
x2 = runif(n)

w1 = pmin(x1, x2)
w2 = pmax(x1, x2) - w1
w3 = 1 - w1 - w2

df = data.table(w1, w2, w3)
df[, eff_size := 1/(w1*w1 + w2*w2 + w3*w3)]
df[, value := w1 + w2*2 + w3*3]

dfs =df[sample.int(nrow(df), 10),]

res = ldply(seq(nrow(dfs)), function(i){ 
  
  mw1 = dfs[['w1']][i]
  mw2 = dfs[['w2']][i]
  mw3 = dfs[['w3']][i]
  
  p1 = mw1/(1+mw1)
  p2 = mw2/(1+mw2)
  p3 = mw3/(1+mw3)
  
  res = ldply(c(0, 1e-4, 1e-3, 1e-2, seq(100)/10, 1e6), function(d){
    w1 = (p1 + d) / (1 - p1 + d)
    w2 = (p2 + d) / (1 - p2 + d)
    w3= (p3 + d) / (1 - p3 + d)
    ws = w1 + w2 + w3
    return (data.frame(d, w1 = w1/ws, w2 = w2/ws, w3 = w3/ws, i = i))
  })
  return(res)
  })
setDT(res)
res[, eff_size := 1/(w1*w1 + w2*w2 + w3*w3)]
res[, value := w1 + w2*2 + w3*3]

df_reg = ldply(c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 1.0), function(d){ 
  temp = copy(df)
  
  temp[, w1:=(w1/(1+w1) +d) /(1 - w1/(1+w1) + d)]
  temp[, w2:=(w2/(1+w2) +d) /(1 - w2/(1+w2) + d)]
  temp[, w3:=(w3/(1+w3) +d) /(1 - w3/(1+w3) + d)]
  temp[, ws:= w1 + w2+w3]
  temp[, w1:=w1/ws]
  temp[, w2:=w2/ws]
  temp[, w3:=w3/ws]
  temp[, d:=d]
  return (temp)
  })
setDT(df_reg)
df_reg[, eff_size := 1/(w1*w1 + w2*w2 + w3*w3)]
df_reg[, value := w1 + w2*2 + w3*3]

ggplot(df_reg, aes(w1, w2, color = eff_size)) + geom_point() + scale_color_custom('jet', discrete = FALSE) + 
  geom_vline(xintercept = 1/3, linetype = 'dashed') + geom_hline(yintercept = 1/3, linetype = 'dashed') + 
  coord_fixed(ratio = 1) + facet_wrap(~d)


ggplot(df, aes(w1, w2, color = eff_size)) + geom_point() + scale_color_custom('jet', discrete = FALSE) + 
  geom_vline(xintercept = 1/3, linetype = 'dashed') + geom_hline(yintercept = 1/3, linetype = 'dashed') + 
  geom_line(data = res, aes(w1, w2, group = i), color = 'black') + geom_point(data = res[d==0,], aes(w1, w2, group = i), color = 'black') + coord_fixed(ratio = 1)

ggplot(res, aes(w1, w2, group = i)) + geom_line() + geom_point()+ coord_fixed(ratio = 1)
ggplot(res, aes(eff_size, value, group = i)) + geom_line() 


ggplot(df, aes(w1, w2, color = value)) + geom_point() + scale_color_custom('jet', discrete = FALSE) + coord_fixed(ratio = 1) + 
  geom_vline(xintercept = 1/3, linetype = 'dashed') + geom_hline(yintercept = 1/3, linetype = 'dashed')
