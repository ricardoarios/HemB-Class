knn.classif<-function(train.task, test.task, measure = list(acc), save.model=NULL, max.k=60){
  distances <- dist(train.task$env$data[, -ncol(train.task$env$data)], method = "euclidean") %>% as.matrix()
  
  best.acc = 1000
  best.k = 2
  best.out = c()
  label=train.task$env$data[, ncol(train.task$env$data)] %>% as.numeric()
  for(i in 2:max.k){
    out <- distMat.KernelKnn(distances, TEST_indices = test.task, y = label, k = i, 
                             regression = F, weights_function = NULL, threads = detectCores(),
                             Levels = unique(label)) %>% apply(., 1, which.max)
            

    current.acc<-measureACC(train.task$env$data[test.task, ncol(train.task$env$data)] %>% as.numeric(), out)
    if(best.acc > current.acc){
      best.k = i
      best.acc = current.acc
      best.out<-out
    }
  }
  cat("Best k: ", best.k, "\n")
  best.out<-as.character(best.out)
  best.out[which(best.out == "1")]<-levels(train.task$env$data[, ncol(train.task$env$data)])[1]
  best.out[which(best.out == "2")]<-levels(train.task$env$data[, ncol(train.task$env$data)])[2]
  invisible(best.out)
}  

