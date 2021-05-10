## Installing the packages
## BiocManager::install("bwlewis/doRedis")
## BiocManager::install("Jiefei-Wang/DockerParallel")
## BiocManager::install("Jiefei-Wang/ECSFargateProvider")
## BiocManager::install("Jiefei-Wang/RedisBaseContainer")
## BiocManager::install("Jiefei-Wang/doRedisContainer")

## The package used in the example
## install.packages(boot)

## Select a region
aws.ecx::aws_list_regions()
aws.ecx::aws_set_region("us-east-1")

## Show credentials
aws.ecx::aws_get_credentials()
aws.ecx::aws_set_credentials()

## Create parallel cluster using
## ECS fargate service and r-base foreach doredis container
library(DockerParallel)
clusterPreset(cloudProvider = "ECSFargateProvider", container = "rbaseDoRedis")
cluster <- makeDockerCluster(workerNumber = 0L, workerCpu = 256, workerMemory = 512)
cluster$startCluster()

## A temporary work around for the performance issue
cluster@workerContainer$maxWorkerNum <- 1L

## Set the required package and the worker number
cluster$workerContainer$setRPackages("boot")
cluster$workerContainer$setSysPackages()


cluster$setWorkerNumber(1)

## Bootstrap 95% CI for R-Squared
library(boot)
## function to obtain R-Squared from the data
rsq <- function(formula, data, indices) {
    d <- data[indices,] # allows boot to select sample
    fit <- lm(formula, data=d)
    return(summary(fit)$r.square)
}
## bootstrapping with 10000 replications
# user  system elapsed
# 86.37    0.39   87.27
system.time({
    results <- boot(data=mtcars, statistic=rsq,
                    R=10000, formula=mpg~wt+disp)
    stats <- results$t
})
hist(stats, breaks = 100)


## use foreach to parallelize the bootstrap
library(foreach)
foreach::getDoParWorkers()
# user  system elapsed
# 0.00    0.06   22.52
system.time(
    stats <- foreach(x= 1:10, .combine = c)%dopar%{
        library(boot)
        results <- boot(data=mtcars, statistic=rsq,
                        R=1000, formula=mpg~wt+disp)
        results$t
    }
)
hist(stats, breaks = 100)
